---
name: fat-pickup
description: >-
   UPON EXPLICIT REQUEST ONLY. Stand up in a fresh context window from a handoff document that a
   predecessor wrote with `fat-handoff`, during a transition the human is managing. Not for
   resuming ordinary sessions.
---

This SKILL is explicitly used only in immediate handoffs: ignore git/disk TOCTOU, you may lean towards trusting the recency of your predecessor/successor.

NOTE: This SKILL is new; mention (in chat) if anything chafes (particularly, enumerate the number of turns involved in your in-chat reply - if you had to take multiple turns to construct/consume the handoff.)

# Picking up

Run the command the human gave you, then do what it prints.

In the pickup document, a read followed by a `<result>` block has already been read for you; don't issue it again.

A read marked `[when] <circumstance>` is made only if that circumstance arises. Claims in the handoff's own prose are ~SUSPECT at most; verify them before relying on them.
