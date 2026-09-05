---
name: verify-first
description: Use this skill whenever you are about to claim something is novel or hasn't been done before, cite a fact or source, report benchmark or test results, evaluate or critique someone else's work, or make any claim about real-world data or behavior. It gives a concrete pre-flight verification protocol, adapted from standard academic research training, to stop overclaiming, fabricated citations, inflated success numbers, and unfounded novelty claims before they happen.
license: MIT
metadata:
  author: steven10812122
  version: 0.1.0
---

# Verify First

## Why this exists

Left unchecked, an AI agent overclaims in the same handful of ways, over and over: it asserts something is novel because it doesn't personally recall seeing it, not because it checked; it states a fact or number from training data as settled when it was never verified against a real source; it reports a benchmark as a success by counting weak or partial matches as wins; and it ships a conclusion without ever trying to break it first.

This isn't a new problem invented for AI. It's exactly what a research advisor spends a new graduate student's first year drilling out of them. This skill operationalizes that same discipline — adapted from real academic research training, not invented for this document — as a concrete protocol, not a vague reminder to "be careful."

## The five-stage cycle

### 1. Check prior art before committing to a claim or a direction

Before starting a project, proposing an approach, or asserting something is new: go find out if it already exists. This is the literature review a research advisor requires before a topic is even approved — not a courtesy, a gate.

- **Do**: search the actual, relevant registries for the domain — package registries (npm, PyPI) and GitHub search for engineering claims; real literature search for factual/scientific claims. Check the exact name and close variants, and read what the closest existing match actually does, not just whether a name is taken.
- **Don't**: conclude "I haven't seen this before" from training-data familiarity and treat that as verification. Training-data recall is not a literature search.
- See `references/case-studies.md` ("The aislop incident" and "The socialify incident") for two real, costly examples of skipping this step.

### 2. Stay engaged with current sources throughout, not just once at the start

A single check at the beginning is not the same as staying current. Research training expects you to keep reading recent papers as the project evolves, because the field moves while you work. The engineering analogue: re-check when the scope or claim changes, not just when the project starts.

- **Do**: re-verify novelty/facts when you pivot direction, not only at the original kickoff. A finding from step 1 can go stale the moment the plan changes.
- **Don't**: treat one early search as a permanent clearance for everything you build afterward.

### 3. Understand existing approaches deeply before building your own

Before designing a solution, study how prior work actually solved the adjacent problem — not to copy it, but so your own design is informed by what's already been tried and why it worked or didn't.

- **Do**: read the actual approach/methodology of the closest prior art you found in step 1, not just its existence or star count.
- **Don't**: dismiss or ignore prior art just because it's "less exciting" than your own idea — understand it first.

### 4. Verify results against external reality, not just your own pipeline

An experiment or benchmark that only checks itself against itself proves nothing. Research training requires bringing outside sources back in at the verification stage — checking your result against the literature, not just declaring victory because your own code produced a number.

- **Do**: count a result as "correct" only when it is actually, specifically correct against ground truth — not "produced some output," not "didn't crash." When citing a fact, confirm the exact claim against a real primary or well-attributed secondary source before using it, and mark anything unverified as unverified rather than presenting it as settled.
- **Don't** inflate a success rate by counting partial, adjacent, or merely-present results as full matches. Report the honest number, including the failures, in the same breath as the success.
- See `references/case-studies.md` ("The 95% that was actually 30/40") for a real example of this exact inflation, caught and corrected.

### 5. Actively challenge your own conclusion before presenting it

Throughout — not just at the end — ask what would prove this wrong, and go check it, rather than waiting for someone else to find the hole.

- **Do**: before presenting a result, spend real effort trying to break it — the longest/weirdest/most adversarial real input you can find, not just the input you built the feature around.
- **Don't**: treat "it worked on my test case" as equivalent to "it works." Your own test case is exactly the one case you already knew would pass.
- See `references/case-studies.md` ("The kebab-case title overflow") for a real bug that a self-adversarial check would have caught before a user's real data did.

## Pre-flight checklist

Before making any claim covered above, run through `references/verification-checklist.md`. Short version:

- [ ] Did I search real sources for this, or just recall training data?
- [ ] Is the exact number/quote/claim confirmed against a real source, not approximated from memory?
- [ ] Does my "success" count only mean genuinely, specifically correct — not "produced output"?
- [ ] Have I disclosed the failures/limitations in the same breath as the successes?
- [ ] Have I tried to break this with a real adversarial case, not just the happy path?

## References

- `references/case-studies.md` — real, specific incidents (generalized from an actual extended session) illustrating each failure mode above and what verification would have caught.
- `references/verification-checklist.md` — the full checklist, split by claim type (novelty claims, citations, benchmark/test reporting, judging someone else's work).
