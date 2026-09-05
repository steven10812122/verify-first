# Case studies

Real incidents, generalized from an actual extended agent session, not hypotheticals. Each one is a failure that verification would have caught, plus one case where the discipline was followed and it worked.

## The aislop incident (stage 1: check prior art before committing)

An agent was asked to design a tool that scans AI-generated code for quality problems (duplication, dead code, unsafe patterns) and produces a shareable score. It designed the concept, picked a name, and was about to start implementation — at which point a routine `npm view <name>` check (done almost as an afterthought) turned up an actively maintained competitor with 595 GitHub stars, an organization behind it, commits from hours earlier, and a feature set considerably more complete than the planned MVP.

**What went wrong:** the agent's earlier "has anyone done this?" pass had relied on general web search and training-data recall, which found nothing — because a real, successful, hours-old-commit project can exist without ever having been written about anywhere a web search would surface it. General search and training recall are not a substitute for checking the actual registry where such a project would be listed.

**What verification looked like once applied:** checking the exact candidate name (and close variants) directly against the real package registry and GitHub search, as the *first* step of evaluating any new idea — not a courtesy check after the design was already done.

## The socialify incident (stage 1 and 2: prior art, and re-checking after a pivot)

Later in the same lineage of work, a different tool (a GitHub-repo-to-image generator) was reframed midway through — its selling point was changed from "fun to share" to "fixes a real, common gap: most repos never set a custom social-preview image." That specific reframing was proposed and partly built without a fresh prior-art check, because the *underlying tool concept* had already been checked earlier in the project.

**What went wrong:** the novelty check that had been done covered the original framing, not the new one. When a project's core claim or positioning changes, that is a new claim requiring its own check — an old "we looked and found nothing" does not carry over to a different claim just because it's the same codebase. A follow-up check found a 2,212-star, actively maintained, MLH-Fellowship-backed project that was *already the recommended tool* for exactly that specific positioning, complete with a hosted API and CLI.

**What verification looked like once applied:** treating the pivot itself as a new claim needing a new check, not assuming the earlier clearance still applied.

## The 95% that was actually 30/40 (stage 4: verify against reality, not your own pipeline)

An agent ran a matching engine against real financial filings and reported "95% matched" as a headline result. The number was computed by counting any non-null extraction as a "match" — including cases where the engine had confidently extracted an entire paragraph of unrelated legal boilerplate instead of the intended figure.

**What went wrong:** the metric measured "did the pipeline produce something," not "was the output actually, specifically correct." These are very different questions, and only the second one is what "95% matched" implies to a reader.

**What verification looked like once applied:** manually checking each result against the real, correct value rather than trusting the automated non-null count. The honest number was close to 30 correct out of 40, not 95%. Both the successes and the specific failure pattern (the same phrase appearing many times across a document, with the wrong instance selected) were reported together, not just the corrected headline number in isolation.

## The kebab-case title overflow (stage 5: challenge your own conclusion before presenting it)

A canvas-based title-rendering feature was built, tested against several short project names, and shipped as working. It broke the first time a user tried it on their own real, long, hyphenated project name — the text overflowed off both edges of the canvas, because the wrapping logic only knew how to break on spaces, and the title had none.

**What went wrong:** every internal test case had been a short or naturally-spaced name, because those were the cases that came to mind while building the feature. None of them adversarially stress-tested the feature's actual weak point.

**What verification looked like once applied:** after the bug was found, a regression test was added using the exact real input that broke it, and a systematic pass was made to find other untested extremes (very high numbers, empty lists, zero-length inputs) before those were reported as handled, rather than after a user found each one individually.

## Where the discipline worked: the reweighted evidence pass

Before shipping a set of "why this meeting might not need to happen" rules, each rule's justification (drawn from commonly-repeated claims about meeting size, agendas, and productivity) was checked against real research rather than cited from memory. The check found that the two most commonly *repeated* claims (meeting size and lack-of-agenda effects) had only weak support in a systematic evidence review, while a less-repeated factor (meeting frequency) had the strongest real support. The rules were reweighted to match the actual evidence strength rather than how popular each claim was — the opposite of what shipping from memory would have produced.

## The honest limit of this skill: a same-day quantification attempt found nothing, and that's an honest result, not a failure to hide

After drafting this skill, an attempt was made to measure whether it actually changes behavior: twelve independent, fresh agent runs were split across two scenarios (evaluating a project idea's novelty; reporting a benchmark's accuracy from data engineered to contain three plausible-looking wrong answers), half with this skill's content injected as instructions, half without. The result was a flat null: every condition behaved identically — 6/6 searched before answering the novelty question, and 6/6 reported the true, un-inflated accuracy on the benchmark question, skill or no skill.

**What this does and doesn't mean:** it does not mean the skill has no effect. The real incidents this skill is built from (above) didn't happen in clean, isolated, single-question tests like this one — they happened deep inside a long session, under momentum, after time was already sunk into a direction, with many other things competing for attention. A short isolated test has no sunk cost and no momentum to overcome, so it can't distinguish "the skill helped" from "nothing needed to overcome here in the first place." The honest conclusion is narrower than either "it works" or "it's not needed": in easy, isolated conditions, the model's default behavior was already sufficient, and this test could not speak to the harder condition (long-session momentum) that the skill actually targets, because reproducing that condition in a same-day test is itself an unsolved problem.

This also surfaced a real, documented limit worth stating plainly: Claude Code's own documentation confirms that a loaded skill's content can remain fully present in context while the model simply chooses a different approach under pressure — a natural-language skill is an influence on behavior, not an enforcement mechanism. That's the direct motivation for this plugin also shipping a `Stop` hook (`scripts/check-overclaiming.sh`) that mechanically checks for a narrow set of red-flag claim phrases against whether a search-like tool call happened nearby — a deterministic backstop for the one slice of this problem that's actually mechanically checkable, not a replacement for the broader judgment-based guidance above.
