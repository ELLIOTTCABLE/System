# Handing off

Your window may be nearly spent; put what's left into the handoff. Write it from what is already in your context, without reading or running anything to prepare, in one final write if you can.

The successor gets your context two ways: reads you dictate of durable material (design documents, ledgers, specs, code), and the handoff's own prose. The prose is for what isn't durable: work in flight, unsettled questions, leanings the human hasn't acked, and anything the project's practice keeps out of what it saves or that isn't worth saving. Carrying that forward is much of the point.

Give each piece of context one-or-more deliberate home. Don't restate what a ledger or a dictated read already says; add only what it can't hold. If a piece of information/context contains both components that are best kept durable by project praxis *and* components that shouldn't be made durable, it's reasonable to mildly duplicate, though (i.e. ledgering on a topic *and* elaborating on the in-flight/incomplete/chat-local-human-opinions nitty-gritty) in the new non-durable handoff.)

1. If you've been keeping a running ledger: bring it up to date the way you've been using it; being asked for a handoff authorizes that.
2. Else, if you have no appropriate, LLM-focused, running, durable home for your context: read `mining-context.md` now; and follow those instructions. Your context will *all* be in your temporary handoff.

In the handoff, mark claims about facts, goals or rulings ~SUSPECT at most. (For durables, follow project praxis.) Leave file contents to the read-calls; don't manually inline, this tool will handle that.

## Ordering content

The successor's context starts with the human's own prompt, possibly with some auto-loaded SKILLs the human manually dictated; then the handoff-loading command. The immediate next turn (the invocation) will result in your handoff top to bottom, each dictated read landing where you put it.

(The associated script in this skill will *unfold* your handoff: read-calls will be, as appropriate, possibly inlined, or dictated-as-reads to the successor, *before your other text*. That means "hello\nread(somefile.md)\nworld" will result in 'hello' at the start of the agent's context-window; but 'world' *after* the entire contents of somefile.md. This is true whether or not it is inlined; this SKILL's tool maintains the ordering carefully.)

Attention is consistently strongest at the start (and temporarily at the end); and weakest in the middle. The end's hold fades as the work moves on, the start's does not. So, roughly:

1. first: what stays important all session;
2. in the middle: whatever matters least (but you still feel is worth non-conditional inclusion);
3. then: whatever context/reads matter for the work *currently* in flight, but whose importance will wane as work moves on to something new;
4. and last: whatever will go stale soonest, such as what you were just doing and what the human last asked.

Dictate each read as exactly your harness's file-read call. You may include a specific range or not, as you see fit. You may include multiple read-calls with different line ranges at different parts of the handoff. You may include information about why it matters if you want, but that will usually be excessive; it's likely to be obvious from context. (i.e. a common pattern for simple handoffs will be an short initial block of critical prose/context; a simple block of harness-read-calls for relevant files; and then a rundown of what's in-flight and recent.) Skills the successor needs are reads of their SKILL files.

Finish by giving the human this command, with this skill's directory and your two paths filled in: first where the successor's pickup document will be written, then your handoff. You will not run the command, the successor will.

```sh
node "<this skill's directory>/expand-handoff.mts" "handoff.out.md" <"<dir>/r31-world-relations-naming-sitting.handoff.md"
```
