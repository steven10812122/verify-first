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

if [ -z "$LAST_MSG" ]; then
  exit 0
fi

RED_FLAGS='nobody (has )?(done|built|made|created) this|no one (has )?(done|built|made|created) this|has(n.t| not) been done before|first of its kind|first-of-its-kind|completely (novel|original|unique)|genuinely unique|guaranteed to work|100% (accurate|correct)|proven to (work|be effective)|no prior art|never been done before|this is (completely |totally )?unique'

MATCHED="$(printf '%s' "$LAST_MSG" | grep -oiE "$RED_FLAGS" | head -1 || true)"

if [ -z "$MATCHED" ]; then
  exit 0
fi

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  # Can't check for evidence at all -- an environment quirk, not proof
  # evidence is missing. Fail open rather than block on an unrelated issue.
  exit 0
fi

RECENT=""
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  RECENT="$(tail -c 20000 "$TRANSCRIPT_PATH" 2>/dev/null || true)"
fi

EVIDENCE_PATTERN='WebSearch|WebFetch|npm view|npm search|npm-view|gh search|gh api repos|registry.npmjs.org|pypi.org|crates.io'

if printf '%s' "$RECENT" | grep -qiE "$EVIDENCE_PATTERN"; then
  exit 0
fi

echo "verify-first hook: the response includes \"$MATCHED\", a claim that implies checked novelty/certainty, but no search or registry-check tool call (WebSearch, npm/PyPI/crates lookup, gh search/api) is visible nearby in this session. Before finishing: either actually verify this claim, or soften the wording to reflect what was actually checked (e.g. \"I didn't find an exact match in a quick search\" rather than \"nobody has done this\")." >&2
exit 2
