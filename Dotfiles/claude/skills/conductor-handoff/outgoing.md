# Handing off

Your window may be nearly spent; put what's left into the handoff. Write it from what is already in your context, without reading or running anything to prepare, in one final write if you can.

The successor gets your context two ways: reads you dictate of durable material (design documents, ledgers, specs, code), and the handoff's own prose. The prose is for what isn't durable: work in flight, unsettled questions, leanings the human hasn't acked, and anything the project's practice keeps out of what it saves or that isn't worth saving. Carrying that forward is much of the point.

Give each piece of context one deliberate home. Don't restate what a ledger or a dictated read already says; add only what it can't hold.

If you've been keeping a running ledger, bring it up to date the way you've been using it; being asked for a handoff authorizes that. If you haven't, read `mining-context.md` first.

Order matters, and it's yours to choose. The successor's context starts with the human's own prompt, then holds your handoff top to bottom, each dictated read landing where you put it. Attention is strongest at the start and end, weakest in the middle, and the end's hold fades as the work moves on. So, roughly: what stays important all session first; what matters least in the middle; what matters for the work in flight after that; and last, what will go stale soonest, such as what you were just doing and what the human last asked.

Dictate each read as a read call, with why it matters. Skills the successor needs are reads of their files.

In your own prose, mark claims about facts, goals or rulings ~SUSPECT at most. Leave file contents and git state to the reads.

Finish by giving the human this command, with this skill's directory and your two paths filled in: first where the successor's pickup document will be written, then your handoff.

```sh
node "<this skill's directory>/expand-handoff.mts" "<dir>/r31-world-relations-naming-sitting.pickup.md" < "<dir>/r31-world-relations-naming-sitting.handoff.md"
```
