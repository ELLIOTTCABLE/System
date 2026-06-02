# Phase 1..N — work the fronts

> Load this once the human has responded to your Phase-0 `plan.md`. The stance, source-grading, and the notes-log format live in the root `SKILL.md`, already in your context.

Per front, run the loop: **search → read in full → extract verbatim into the turn's notes file with a graded citation + certainty marker → verify → search again with a sharper question.** Iterate; never search-once-and-conclude. Multiple angles per front, and actively try to *falsify* the emerging thesis, not just confirm it — disconfirming evidence is the point. (Adversarial subagents are especially useful here.)

Rabbit-hole discipline: continuously ask *does this still serve the converging goal?* Even when the goal was unknown at the start it crystallises as you narrow, so use that emerging thesis as the filter. On hitting a tangent, an apparent bug, or an interesting-but-orthogonal question: write it to `quarantine.md` (and flag a genuinely important one to the human in the moment), then return to the front. Capturing is not chasing.

For the most part, continuously reason about when to involve the human. Definitely pause for the human on a real fork — a tradeoff to weigh, an ambiguity that changes direction, a finding that invalidates the plan. Often, though, you can keep moving; you needn't interrupt as much for non-decisions.

That said, the *purpose* of this Skill is human-in-the-loop; so it's not unreasonable to err on the side of "hey, here's what I've been finding, do you have any thoughts, are we headed in the right direction?" when you've collected a solid amount of information. Work together, treat it as pair-programming; just try and make sure your machine-turn is maximally machine-beneficial: you're good at breadth and synthesis, but less-good at noting subtly important details or direction-finding. Keep it moving or use-your-human, apply judgement.

## Tooling (SE-first, your stack)

Reach across complementary sources — each surfaces what the others miss, some may be unavailable in some environments (note and move on, work-around, don't fully stop research immediately when something is missing, do your best, but note any concerns and blockers during the first-round-return):

- **mcp-server-fetch**, not the builtin-Fetch() — full-content reading of any URL with no summariser; this is how individual sources actually enter the loop
- **Kagi** (`kagi-ken`) — general and forum/discussion search; `site:reddit.com <q>` is your Reddit path, since the native API is walled
- **github** MCP / `gh` CLI — issues, PRs, change history, and *hard signal* (stars, commit depth, recency, maintainer) when judging whether a project is trustworthy
- **Exa** (advanced) — neural/semantic search; phrase the query as a *description of the ideal page*, not keywords

More niche, less 'repeat-on-a-hot-loop' than the above:

- **octocode** — cross-repo code research: real implementations, not blog paraphrases of them, cross-provider (GH/GitLab/etc)
- **Context7** — pinned-version library/API docs; it won't fire on its own, so invoke it explicitly when the question is "how does library X actually behave in version Y", but always only for summaries and direction-finding; the canonical source-of-truth must remain the *actual docs* via *actual fetch*

Grade each source, when cited/linked, per the **Source-grading** rubric in the root `SKILL.md`. For software questions the source of truth is the **code, docs, issue tracker, spec, changelog, whitepaper** — not a listicle.

When a claim matters, check it against the actual source-code and live/relevant/in-use version-number; and reproduce against code where feasible.

## Close every turn with the validator

Before a turn reaches the human, your **final act** is to run `validate.sh` (see *Tooling* in `SKILL.md`):

```bash
bash ~/.claude/skills/interactive-research/scripts/validate.sh .claude/research/<topic>
```

A non-zero exit means a citation didn't resolve to a registered source — fix each before handing off. Warnings don't fail the gate; weigh them. A clean exit, warnings weighed, signals the turn is ready for review.

When the evidence is sufficient — the frontier has narrowed and fresh searches stop turning up load-bearing material — read `references/phase-z.md` and write the conclusion.
