# verify-first

[![validate](https://github.com/steven10812122/verify-first/actions/workflows/validate.yml/badge.svg)](https://github.com/steven10812122/verify-first/actions/workflows/validate.yml) [![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

> Stops an AI agent from overclaiming — asserting something is novel without checking, citing a fact it never verified, inflating a benchmark's success rate, or shipping a conclusion it never tried to break.

A portable [Agent Skill](https://agentskills.io/specification): any agent that speaks the standard can load it, and the [Skills CLI](https://skills.sh) installs it with one command on whichever of its 77+ supported agents you pick. Claude Code, Codex, Grok Build, and Antigravity additionally get native plugin packaging. Claude Code's package also ships a `Stop` hook that mechanically enforces the one narrow slice of this that's actually checkable — see Install for exactly which platforms that covers.

## Why this exists

A real, documented pattern from an actual agent session, not a claim about AI in the abstract: the same failure kept recurring in different disguises — asserting novelty without checking a registry first, reporting a benchmark's success rate by counting weak or partial matches as wins, and shipping a feature without adversarially testing its actual weak point.

Full incident write-ups — including one case where the discipline caught a real problem before it shipped, an honest account of a same-day attempt to quantify this skill's own effect that came back a flat null, and a note on a comparable existing tool found on a later, more careful search — are in [`references/case-studies.md`](skills/verify-first/references/case-studies.md).

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

This is the only path that installs the enforcement hook alongside the skill. This is also the only platform where the whole install-and-run path has been exercised by us.

### Codex, Grok Build, Antigravity (native, skill only — no hook)

Each has a thin manifest (`.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json`, root `plugin.json`) pointing at the same `skills/` folder Claude Code and the Skills CLI use — no forked content. **None of these three have been installed and exercised end to end by us**; they follow a manifest shape a comparable, already-adopted multi-agent skill uses, but are otherwise unverified. File an issue if one doesn't load.

## What's in here

- [`.claude-plugin/`](.claude-plugin) — Claude Code plugin + marketplace manifest.
- `.codex-plugin/`, `.agents/plugins/marketplace.json`, root `plugin.json` — native packaging for Codex, Grok Build, and Antigravity.
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
