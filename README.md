# verify-first

A Claude Agent Skill that stops an AI agent from overclaiming — asserting something is novel without checking, citing a fact it never verified, inflating a benchmark's success rate, or shipping a conclusion it never tried to break.

It isn't a vague "be careful" reminder. It's a five-stage protocol adapted directly from standard academic research training: check prior art before committing to a claim, stay current with sources as the work evolves (not just once at the start), understand existing approaches before building your own, verify results against outside reality instead of just your own pipeline, and actively challenge your own conclusion before presenting it.

Every failure mode in this skill is a real, generalized incident — not a hypothetical — including one case where the agent designed and named a tool before discovering an actively maintained competitor with 595 stars, and one where a reported "95% success rate" turned out to be roughly 30/40 once each result was actually checked instead of counted. See [`references/case-studies.md`](references/case-studies.md).

## Install

**Claude Code plugin marketplace:**

```
/plugin marketplace add steven10812122/verify-first
/plugin install verify-first@verify-first
```

**Or copy the files directly** into your own project's skills directory (works with any Agent-Skills-compatible tool, not just Claude Code):

```bash
npx skills add steven10812122/verify-first
```

## What's in here

- [`SKILL.md`](SKILL.md) — the skill definition: the five-stage protocol and a short pre-flight checklist.
- [`references/verification-checklist.md`](references/verification-checklist.md) — the full checklist, split by claim type (novelty, citations, benchmarks, judging others' work, shipping).
- [`references/case-studies.md`](references/case-studies.md) — the real incidents behind each rule, including one case where the discipline was followed correctly and caught a real problem before it shipped.

## Why this exists

This came out of an actual, long agent session building several small tools, where the same failure mode kept recurring in different disguises: assume novelty instead of checking it, trust a citation instead of confirming it, count a weak match as a win. The fix that actually worked wasn't a general instruction to "be more careful" — it was borrowing the concrete discipline a research advisor already drills into every new graduate student, and writing it down as something an agent can actually follow step by step.

## License

MIT — see [LICENSE](LICENSE).
