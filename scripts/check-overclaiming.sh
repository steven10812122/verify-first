#!/bin/bash
# Stop hook: mechanically flags red-flag overclaiming language in the
# response Claude is about to finish with, if there's no visible sign of
# a verification action (search/registry check) nearby in the transcript.
#
# This exists because the soft, natural-language guidance in SKILL.md is
# an influence on behavior, not a guarantee -- Claude Code's own docs say
# so explicitly: a skill can still be "in context" while the model simply
# chooses another approach under pressure. This script is the
# deterministic backstop for the one narrow slice of that problem that's
# actually mechanically checkable: specific claim phrases, checked against
# whether a search-like tool call happened recently. It cannot verify
# whether a claim is actually TRUE -- only that a search was *attempted*
# near a place a strong claim was made. Fails open (exit 0) on any error,
# since blocking incorrectly is worse than missing a case.

set -e
INPUT="$(cat)"

LAST_MSG="$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get("last_assistant_message", "") or "")
except Exception:
    print("")
' 2>/dev/null || true)"

TRANSCRIPT_PATH="$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get("transcript_path", "") or "")
except Exception:
    print("")
' 2>/dev/null || true)"

# The official docs' own example JSON shows transcript_path as
# "~/.claude/projects/.../thread.jsonl". A shell variable's contents are
# never tilde-expanded by `[ -f ... ]` the way a literal `~` in source code
# would be, so if that leading "~" is ever the literal value (rather than
# just documentation shorthand for a real absolute path), the file-exists
# check below would always fail, silently disabling the evidence check on
# every single call. This costs nothing to guard against either way.
case "$TRANSCRIPT_PATH" in
  "~"/*) TRANSCRIPT_PATH="${HOME}${TRANSCRIPT_PATH#\~}" ;;
esac

STOP_HOOK_ACTIVE="$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    print("true" if data.get("stop_hook_active") else "false")
except Exception:
    print("false")
' 2>/dev/null || echo "false")"

# stop_hook_active is true when this Stop event is itself a re-run caused by
# a previous Stop hook blocking the turn. Blocking again here risks an
# infinite block-rewrite-block loop on a claim that genuinely can't be
# verified in this environment (e.g. no network access) -- so this hook
# only ever blocks once per stop cycle, then lets the turn end.
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

if [ -z "$LAST_MSG" ]; then
  exit 0
fi

# English overclaiming phrases.
RED_FLAGS_EN='nobody (has )?(done|built|made|created) this|no one (has )?(done|built|made|created) this|has(n.t| not) been done before|first of its kind|first-of-its-kind|completely (novel|original|unique)|genuinely unique|guaranteed to work|100% (accurate|correct)|proven to (work|be effective)|no prior art|never been done before|this is (completely |totally )?unique'

# Chinese overclaiming phrases (traditional + simplified variants). A fixed
# phrase list is never complete across languages, but this closes the most
# glaring gap: the English-only list above is blind to any Chinese response,
# regardless of whether the underlying claim was actually verified.
#
# Found by testing each sub-phrase individually rather than trusting the
# handful already spot-checked: three of these mixed a traditional character
# in one part of a sub-pattern with no simplified counterpart, so an
# otherwise-covered phrase silently failed to match once one specific
# character in it was simplified -- "沒有人開發過" matched, but the fully
# simplified "没有人开发过" didn't, because only the ending "過" was
# checked for, not "过"; same issue for "保證" missing "保证", and "查無"
# missing "查无".
RED_FLAGS_ZH='(沒|没)(有)?人(做|寫|写|建立|開發|开发)(過|过)|前所未有|史上首(創|创)|史上第一(個|个)|完全(原創|原创|獨創|独创|獨一無二|独一无二)|(百分之百|100 ?%)(準確|准确|正確|正确)|(保證|保证)(絕對|绝对)?(有效|成功|可行)|已?(證實|证实)(有效|可行)|(查無|查无|沒有|没有)前例|這是全新的|这是全新的'

# Citation-shaped text: "(Smith et al., 1998)" / "According to Smith (1998)"
# / a Chinese "in a <year> paper/study" construction, with the year kept
# close to the research word so it doesn't match an unrelated year and an
# unrelated research word that both happen to appear somewhere in a longer
# message. These aren't overclaiming phrases by themselves -- a verified
# citation looks identical to a fabricated one -- but paired with no nearby
# verification evidence, they're exactly the shape of the citation-
# fabrication failure mode, so they get the same treatment.
#
# A bare "ProperNoun (Year)" pattern was tried first and dropped: it matched
# ordinary sentences with no citation involved at all ("Tesla (2020)
# delivered record production", "Project Phoenix (2024) shipped on time"),
# which would have blocked completely unrelated claims. Requiring either the
# parenthetical "(Name, Year)" citation format, or an explicit attribution
# word ("according to", "as reported by", "per", "citing") before the bare
# form, keeps the common academic-citation phrasings while clearing those
# false positives.
CITATION_SHAPED='\([A-Z][a-zA-Z]+(,? et al\.?)?,? (19|20)[0-9]{2}\)|(according to|as reported by|per|citing) [A-Z][a-zA-Z]+( et al\.?)? \((19|20)[0-9]{2}\)|(19|20)[0-9]{2}年.{0,6}(研究|論文|文獻|论文|文献)|(研究|論文|文獻|论文|文献).{0,6}(19|20)[0-9]{2}年'

RED_FLAGS="${RED_FLAGS_EN}|${RED_FLAGS_ZH}|${CITATION_SHAPED}"

MATCHED="$(printf '%s' "$LAST_MSG" | grep -oiE "$RED_FLAGS" | head -1 || true)"

if [ -z "$MATCHED" ]; then
  exit 0
fi

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  # Can't check for evidence at all -- an environment quirk, not proof
  # evidence is missing. Fail open rather than block on an unrelated issue.
  exit 0
fi

# Tool-name evidence requires the actual transcript JSON shape of a real
# tool call (`"name": "WebSearch"` inside a tool_use block), not just the
# bare word. A bare-word check would count "I did a WebSearch and confirmed
# this" as evidence even when no tool was ever actually invoked -- the
# model narrating a search it never ran, which is exactly the kind of
# unverified claim this whole hook exists to catch.
TOOL_EVIDENCE_PATTERN='"name":[[:space:]]*"(WebSearch|WebFetch)"'

# Command-content evidence: these are much harder to plausibly narrate
# without actually running them (an invented `npm view <realistic-name>`
# in prose reads as strange rather than natural), so a substring match is
# an acceptable, lower-precision check here. Still a known, smaller version
# of the same loophole -- not fully closed, just narrower.
COMMAND_EVIDENCE_PATTERN='npm view|npm search|npm-view|gh search|gh api repos|registry\.npmjs\.org|pypi\.org|crates\.io|scholar\.google|semanticscholar|arxiv\.org|doi\.org|jstor\.org|sciencedirect|researchgate'

# Scan the whole transcript, not just a byte-count tail. An earlier version
# used `tail -c 20000`, which could push a real WebSearch/WebFetch call out
# of the checked window whenever enough tool output (e.g. long search
# results) came after it in the same turn -- a false block on a claim that
# had, in fact, just been verified. grep on a full transcript file is cheap
# enough that truncating for performance isn't worth that false positive.
if grep -qE "$TOOL_EVIDENCE_PATTERN" "$TRANSCRIPT_PATH" 2>/dev/null || grep -qiE "$COMMAND_EVIDENCE_PATTERN" "$TRANSCRIPT_PATH" 2>/dev/null; then
  exit 0
fi

echo "verify-first hook: the response includes \"$MATCHED\", a claim that implies checked novelty/certainty, but no search or registry-check tool call (WebSearch, npm/PyPI/crates lookup, gh search/api) is visible nearby in this session. Before finishing: either actually verify this claim, or soften the wording to reflect what was actually checked (e.g. \"I didn't find an exact match in a quick search\" rather than \"nobody has done this\")." >&2
exit 2
