# verify-first

[![validate](https://github.com/steven10812122/verify-first/actions/workflows/validate.yml/badge.svg)](https://github.com/steven10812122/verify-first/actions/workflows/validate.yml) [![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

> Stops an AI agent from overclaiming — asserting something is novel without checking, citing a fact it never verified, inflating a benchmark's success rate, or shipping a conclusion it never tried to break.

A portable [Agent Skill](https://agentskills.io/specification): any agent that speaks the standard can load it, and the [Skills CLI](https://skills.sh) installs it with one command on whichever of its 77+ supported agents you pick. Claude Code and Codex additionally get native plugin packaging; Claude Code's package also carries a `Stop` hook that mechanically enforces the one narrow slice of this that's actually checkable — no equivalent hook has been built or tested for Codex or any other platform, and that's stated plainly under Install, not glossed over.

## Why this exists

Not a claim about AI in the abstract — a real, documented pattern from one long agent session building several small tools, where the same failure kept recurring in different disguises:

- **An agent designed and named a code-quality-scanning tool, picked a name, and was about to start building it — before a routine `npm view` check turned up an actively maintained competitor with 595 GitHub stars** and a feature set already more complete than the planned MVP. The earlier "has anyone done this?" pass had relied on general web search and training-data recall, which found nothing, because a real, successful project can exist without ever being written about anywhere a search would surface it.
- **A benchmark was reported as "95% matched."** The number counted any non-null extraction as a match — including cases where the pipeline had confidently extracted an entire paragraph of unrelated boilerplate instead of the intended figure. Checked by hand, one field at a time, the real number was close to 30 out of 40.
- **A same-day attempt to measure whether this very skill changes behavior came back a flat null** across 12 trials, and that result is written up honestly in the case studies below rather than left out. It doesn't mean the skill does nothing — it means an isolated, single-question test can't reproduce the long-session momentum that caused the real incidents above, and that's a real, stated limit of this project, not a hidden one.

Full write-ups, including one case where the discipline was followed correctly and caught a real problem before it shipped, are in [`skills/verify-first/references/case-studies.md`](skills/verify-first/references/case-studies.md).

**Related work:** [Telos-evals/anti-hallucination](https://github.com/Telos-evals/anti-hallucination) is a real, existing Claude Code skill covering adjacent ground (fabrication, stale recall, paraphrase drift, unhedged confidence, with a graded CLEAN/YELLOW/RED audit mode) — found on a later, differently-phrased re-check, not the original search. It doesn't cover novelty/prior-art checking specifically or ship a deterministic hook, but its audit mechanic is worth knowing about.

## The five-stage protocol

Adapted directly from standard academic research training, not invented for this document: check prior art before committing to a claim → stay current with sources as the work evolves, not just once at the start → understand existing approaches deeply before building your own → verify results against outside reality, not just your own pipeline → actively challenge your own conclusion before presenting it. Full detail in [`skills/verify-first/SKILL.md`](skills/verify-first/SKILL.md); the checklist split by claim type (novelty, citations, benchmarks, judging someone else's work) is in [`references/verification-checklist.md`](skills/verify-first/references/verification-checklist.md).

A skill file is guidance, not enforcement — Claude Code's own documentation says a loaded skill can stay fully present in context while the model simply chooses another approach under pressure. That's why the Claude Code package also ships a deterministic `Stop` hook (`scripts/check-overclaiming.sh`, with its own test suite) that scans the response about to be sent for red-flag phrases and blocks with feedback if nothing that looks like a search or registry check happened nearby. It can't verify a claim is *true* — only that a search was *attempted*. It runs entirely on your own machine and makes no network calls of its own.

## Install

### Any agent (Skills CLI, 77+ agents)

```bash
npx skills add steven10812122/verify-first -g     # -g = user scope; the default is project
npx skills update verify-first -g                 # update
npx skills remove verify-first -g                 # uninstall
```

Installs the skill on every agent the [Skills CLI](https://skills.sh) supports — Cursor, Cline, Windsurf, Copilot, OpenCode, goose, and more. This path gives you the guidance only, not the Claude Code `Stop` hook below. Runtime behavior outside Claude Code has not been exercised by us; the skill is plain Markdown under the Agent Skills standard, so file an issue if your agent trips on it.

### Claude Code (skill + Stop hook)

```
/plugin marketplace add steven10812122/verify-first
/plugin install verify-first@verify-first
```

This is the only path that installs the enforcement hook alongside the skill.

### Codex (native, skill only — no hook)

`.codex-plugin/plugin.json` points Codex at the same `skills/` folder Claude Code and the Skills CLI use — no forked content. This has **not** been installed and exercised end to end by us; it follows the same manifest shape a comparable, already-adopted multi-agent skill uses, but is otherwise unverified. File an issue if it doesn't load.

## What's in here

- [`.claude-plugin/`](.claude-plugin) — Claude Code plugin + marketplace manifest.
- [`.codex-plugin/plugin.json`](.codex-plugin/plugin.json) — Codex native packaging, pointing at the same skill folder.
- [`skills/verify-first/`](skills/verify-first) — the one canonical `SKILL.md` plus its `references/`, shared by every install path above.
- [`hooks/hooks.json`](hooks/hooks.json) + [`scripts/check-overclaiming.sh`](scripts/check-overclaiming.sh) — the Claude-Code-specific `Stop` hook, with its own test suite (`test/check-overclaiming.test.js`).

## Development

```bash
npm install
npm run validate        # official skills-ref validator (CI-safe, no Claude Code CLI needed)
npm run validate:plugin # official `claude plugin validate` (requires the Claude Code CLI locally)
npm test                 # the hook's own regression tests
```

## License

MIT — see [LICENSE](LICENSE).
