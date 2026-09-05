# verify-first

A Claude Code plugin that stops an AI agent from overclaiming — asserting something is novel without checking, citing a fact it never verified, inflating a benchmark's success rate, or shipping a conclusion it never tried to break.

It's two things working together, not just a document:

1. **A Skill** (`skills/verify-first/SKILL.md`) — a five-stage protocol adapted directly from standard academic research training: check prior art before committing to a claim, stay current with sources as the work evolves (not just once at the start), understand existing approaches before building your own, verify results against outside reality instead of just your own pipeline, and actively challenge your own conclusion before presenting it. This is guidance — an influence on behavior, the same way a person can know a rule and still not follow it under pressure.
2. **A `Stop` hook** (`scripts/check-overclaiming.sh`) — a deterministic backstop for the one narrow slice of this problem that's actually mechanically checkable: it scans the response about to be sent for red-flag phrases ("nobody has done this," "100% accurate," "proven to work," and similar) and blocks with feedback if nothing that looks like a search or registry check happened nearby. It can't verify a claim is *true*, only that a search was *attempted* near where a strong one was made.

Every failure mode here is a real, generalized incident, not a hypothetical — including one case where an agent designed and named a tool before discovering an actively maintained competitor with 595 stars, one where a reported "95% success rate" turned out to be roughly 30/40 once each result was actually checked, and an honest account of a same-day attempt to quantify this skill's own effect that came back a flat null — see [`references/case-studies.md`](skills/verify-first/references/case-studies.md) for what that test could and couldn't show.

## Install

**Claude Code plugin marketplace** (installs the skill AND the hook together):

```
/plugin marketplace add steven10812122/verify-first
/plugin install verify-first@verify-first
```

**Or copy just the skill** into your own project (works with any Agent-Skills-compatible tool, not just Claude Code — but you won't get the hook this way):

```bash
npx skills add steven10812122/verify-first
```

## What's in here

- [`.claude-plugin/plugin.json`](.claude-plugin/plugin.json) / [`marketplace.json`](.claude-plugin/marketplace.json) — plugin manifest, so this repo installs as one plugin bundling the skill and the hook.
- [`skills/verify-first/SKILL.md`](skills/verify-first/SKILL.md) — the skill definition: the five-stage protocol and a short pre-flight checklist.
- [`skills/verify-first/references/verification-checklist.md`](skills/verify-first/references/verification-checklist.md) — the full checklist, split by claim type (novelty, citations, benchmarks, judging others' work, shipping).
- [`skills/verify-first/references/case-studies.md`](skills/verify-first/references/case-studies.md) — the real incidents behind each rule, one case where the discipline caught a real problem before it shipped, and the honest null result from trying to quantify the skill's own effect.
- [`hooks/hooks.json`](hooks/hooks.json) + [`scripts/check-overclaiming.sh`](scripts/check-overclaiming.sh) — the deterministic `Stop`-hook backstop, with its own test suite (`test/check-overclaiming.test.js`).

## Why this exists

This came out of an actual, long agent session building several small tools, where the same failure mode kept recurring in different disguises: assume novelty instead of checking it, trust a citation instead of confirming it, count a weak match as a win. The fix that actually worked wasn't a general instruction to "be more careful" — it was borrowing the concrete discipline a research advisor already drills into every new graduate student, writing it down as something an agent can actually follow step by step, and backing the parts of it that are mechanically checkable with an actual enforcement hook instead of relying on the written guidance alone.

## Development

```bash
npm install
npm run validate   # runs the official skills-ref validator against skills/verify-first
npm test           # runs the hook's own regression tests
```

## License

MIT — see [LICENSE](LICENSE).
