---
name: fat-handoff
description: >-
   UPON EXPLICIT REQUEST ONLY. Hand an agent's working context to a successor in a fresh
   context window, during a transition the human is managing: the outgoing agent writes a
   handoff document, and the incoming one stands up from it. Not for routine summaries or
   compaction.
---

This SKILL is explicitly used only in immediate handoffs: ignore git/disk TOCTOU, you may lean towards trusting the recency of your predecessor/successor.

- If you are handing off, read `outgoing.md` in this skill's directory.
- If you are picking up from a handoff, read `incoming.md`.

In a handoff, a read marked `[when] <circumstance>` is made only if that circumstance arises. Claims in the handoff's own prose are ~SUSPECT at most; the successor verifies them before relying on them.

NOTE: This SKILL is new; mention (in chat) if anything chafes (particularly, enumerate the number of turns involved in your in-chat reply - if you had to take multiple turns to construct/consume the handoff.)
