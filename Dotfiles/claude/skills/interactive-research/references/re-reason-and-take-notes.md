# Re-reason and take notes — make sense of this front, then decide

> You've just gathered and graded fresh sources on this front. Switch back to analyst: reason over what they mean, record it durably, show the human — then decide whether to loop or finish. (Notes-log format and certainty markers are in `SKILL.md`.)

1. **Reason and record.** Into this turn's notes file (`new-turn.sh`), lift one-line findings to the top and extract verbatim citations with certainty markers. Actively try to *falsify* the front's emerging thesis, not just confirm it — disconfirming evidence is the point (adversarial subagents are especially useful). Where a new source overturns an earlier finding, append a forward-pointing correction; never silently overwrite.

2. **Present to the human.** Surface what this front established and any **real fork** that needs their judgment — a tradeoff to weigh, an ambiguity that changes direction, a finding that invalidates the plan. Treat it as pair-programming: you're strong at breadth and synthesis, weaker at noticing the subtly-important detail or the right direction, so use your human. Often you can keep moving without interrupting; on a real fork, pause. When you've collected a solid amount, "here's what I'm finding, are we headed the right way?" is rarely wrong.

3. **Loop or finish:**
   - More fronts remain, *or* this front isn't exhausted, *or* fresh angles keep surfacing load-bearing material → back to **`references/narrow-and-regrade.md`** for the next gather-and-grade pass. (This is the loop: gather → reason → gather → reason.)
   - The frontier has narrowed and fresh searches stop turning up load-bearing material — *everything seems explored to the limits of value-return*, or the human is satisfied → **`references/final-synthesis-and-conclusion.md`**.

Close every turn with `validate.sh` (see *Tooling* in `SKILL.md`) — a non-zero exit means a citation didn't resolve to a registered source; fix each before handing off. Warnings don't fail the gate; weigh them.
