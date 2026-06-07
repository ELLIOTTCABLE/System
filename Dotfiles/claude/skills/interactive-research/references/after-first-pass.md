# After the first pass — now make sense of what you gathered

> Load this once your first gather-and-grade round (`SKILL.md`) has produced a solid graded source-base in `sources.json`. **Here the job changes, and there's a larger shape the gathering phase didn't need you to know:**

This is a **broad-to-narrow research process** — terraform-style plan/apply for investigation. You cast the wide net; from here you narrow toward a defensible **answer the human can act on**. You were a gatherer; you are now an analyst. Everything you reason about from here is grounded in sources you have *actually read and graded* — never a search snippet. (The source-grading rubric, notes-log format, and tooling all live in `SKILL.md`, already in your context.)

1. **Synthesise the graded sources into the first notes file** (`new-turn.sh`). Lift one-line findings to the top; extract verbatim citations with certainty markers per the notes-log format. *Now* reason over what the sources mean and how relevant each is to the user's question — the interpretation you withheld while gathering.

2. **Judge the shape of the answer:**
   - **Single-answer** (no real tradeoff frontier; the graded evidence already converges)? Skip the loop — read `references/final-synthesis-and-conclusion.md` and write `conclusion.md` now. Don't perform research theatre on a settled question.
   - **Genuine variance** (competing options on a pareto frontier, tradeoffs only the human can weigh, scope ambiguity)? Write **`plan.md`** — the problem-space map and strategy: the landscape, the genuine options/hypotheses, the axes the decision turns on, what's ambiguous, and your read on the shape of the answer — and propose the research fronts.

3. **The gate (only when there's variance).** Present `plan.md` plus a short in-conversation summary; invite correction. The human may reframe the question, kill a front, add a constraint, or reprioritise — the highest-leverage touchpoint, because they're adjudicating *how* to research before you spend the effort. They'll annotate the file or reply in-thread; re-read to pick up their corrections before proceeding.

Once the human has responded to `plan.md` — and unless the question is now obviously, trivially answered — read **`references/narrow-and-regrade.md`** to work the first front.

Close with `validate.sh` (see *Tooling* in `SKILL.md`) — every bracketed `[slug]` must resolve to a registered source.
