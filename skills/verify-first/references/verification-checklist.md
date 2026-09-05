# Verification checklist

Run the section that matches what you're about to say. If more than one applies, run all of them.

## Before claiming something is novel / hasn't been done before

- [ ] Searched the actual registry for the domain (npm/PyPI/crates.io for packages, GitHub search for projects, real literature search for factual/scientific claims) — not just recalled from training data.
- [ ] Checked the exact candidate name AND close variants/synonyms, not just one phrasing.
- [ ] For any close match found, actually read what it does (README, feature list) rather than judging novelty by name alone.
- [ ] If a pivot changed the core claim or positioning partway through, treated that as a NEW claim needing its own fresh check — an earlier clearance for a different claim does not carry over.

## Before citing a fact, statistic, or source

- [ ] The exact number/quote is confirmed against a real, findable primary or well-attributed secondary source — not approximated from memory.
- [ ] If the source could not be independently confirmed (e.g., a specific digit inside a paper that couldn't be directly verified), this is disclosed explicitly as unverified rather than stated as settled fact.
- [ ] Checked for a more rigorous or more recent source before defaulting to whatever is most commonly repeated — popularity of a claim is not evidence for it.
- [ ] Noted any real counter-evidence or caveats found during the search, not just the evidence that supports the point being made.

## Before reporting benchmark, test, or experiment results

- [ ] "Correct" means genuinely, specifically correct against ground truth — not "produced output," not "didn't error," not "partially overlapped."
- [ ] The honest number is reported, including failures, in the same breath as successes — not a headline success rate with failures buried or omitted.
- [ ] Failure cases were examined individually for a pattern, not just tallied as a count.
- [ ] If real-world data was used, it's real, not self-generated — synthetic data is fine for testing known logic against a known ground truth, but not for claiming real-world validity.

## Before evaluating, scoring, or critiquing someone else's work

- [ ] Every flagged issue traces back to a specific, checkable measurement or a cited source — not a subjective opinion presented as fact.
- [ ] The methodology is transparent enough that the person being evaluated could reproduce the exact number themselves.
- [ ] Every criticism is paired with a concrete, actionable way to address it.
- [ ] Legitimate exceptions or nuance (cases where the flagged pattern is actually a reasonable choice) are acknowledged, not blanket-treated as a defect.

## Before shipping a conclusion or a finished feature

- [ ] Actively tried to break it with the most adversarial real-shaped input available — not just the input the feature was designed around.
- [ ] Checked the actual extremes: empty/zero, very large, very long, malformed — not just the typical middle case.
- [ ] If a user or external source already found a break, added it as a permanent regression check, not just a one-off fix.
