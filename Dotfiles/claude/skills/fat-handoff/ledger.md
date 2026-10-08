# fat-handoff ledger

Named `conductor-handoff` until 2026-10-06. The human renamed it so it reads as a handoff for any agent, not just a conductor. The sections below keep the old wording, as written at the time.

## 1. Research and design, before any code (2026-10-05)

Session `e6152f07…` (renamed `skill-conductor-handoff-2`). The goal is a repeatable way for a conductor nearing ~850k to make its own state durable. It should be far more detailed than built-in compaction, and written by the same model while its context is still cached. It formalizes the human's existing practice: stand-ups of ~200–300k (up to ~500k) of core design documents and ledgers, and an outgoing conductor that writes its successor a reading list of exact `Read()` ranges.

Built-in compaction, per leaked `compact.ts` (~v2.1.88, March 2026) and Piebald's prompt extractions (to v2.1.289). Either may have drifted since.

- It is the same model, not a weaker one: a forked agent on `mainLoopModel` that shares the main prompt cache and thinking config.
- It gets one turn with no tools ("Tool calls will be REJECTED") and fires near 95% full. The fallback path caps output at 20k tokens (`COMPACT_MAX_OUTPUT_TOKENS`).
- Afterwards it re-attaches at most 5 recent files at 5k tokens each (50k budget), plus up to 25k of skills.
- The prompt asks for "All user messages", but rulings come out paraphrased. One measurement, from an AI-run account: 54k → 2.5k tokens.

Prior art. Every handoff skill found aims small; none builds a ranged reading list for a large stand-up.

- `REMvisual/claude-handoff` is the closest. Worth taking: chunked chronological mining against lost-in-the-middle, a write-then-reread gap pass, and a required user-feedback section. Its parent-chain and stale-reference checks are currency checks, which are ruled out below.
- `semikolon/ccdistill` deterministically distills a session JSONL, keeping human and assistant text and dropping tool output.
- `anh-chu/claude-handoff-skills` records the predecessor's session file in the handoff.
- `mattpocock/skills` (handoff):
  - reference artifacts by path rather than copying them;
  - "a belief written as a fact becomes a false premise."
- `parcadei/Continuous-Claude-v3` uses `path:L-L` references rather than snippets. Its YAML handoffs are tiny, the opposite aim.
- Anthropic's context-engineering post: maximize recall first, then precision.

Human rulings:

- There are two modes.
  - Already keeping a ledger in git:
    - The ledger must not be filled in after the fact.
    - (A) Confirm the last ledger entry is written and committed.
    - (B) Write a temporary handoff holding only what didn't, or shouldn't, go into durable ledgers.
    - (C) Write the file list.
  - Not keeping a ledger: the handoff carries more.
  - Whether ledgering becomes its own skill is undecided.
- No defence against staleness or TOCTOU. The skill runs only during a live transition that the human manages, and no handoff files are kept afterwards.
- Certainty cap. In anything not going into durables, claims about facts, goals or rulings are ~SUSPECT at most, for the successor to verify before relying on them. File contents and git state go unmentioned.
- Link the predecessor's session file. The human keeps them, since they `/branch` and `/rename` heavily and work on one machine.
- `at10249`'s canary rule (every reply must open with the human's name) is rejected. A pattern repeated throughout the context tends to repeat in the output, so a word-level tripwire is unsound. A logic-based check might not be.
- Stand-up order:
  1. Core design documents, right after the prompt, so goals and limits stay at high attention.
  2. The dictated reads.
  3. The handoff, last, since it is only recently important.
- Carrying every human message is left open; the human is torn. Design sessions run about 2:1 model-to-human text, against about 25–50:1 for coding, so a 500k design session holds too much human text to dump.
- A deterministic outside tool fattens the handoff. It inlines a range's current contents wherever that beats the successor's read call. The human's prior: worth it up to ~30 lines.
- Lower priority: point each read at the moment in the transcript where the predecessor read or wrote it.
- `SKILL.md` and its description stay harness-general. The implementation may start Claude-Code-only.

Stand-up measured on Dorc session `730ea7c3…`. The reading list was `_tmp-world-relations-naming-sitting-reading-list.md`, made by Dorc's `.tmp/reading-list/expand.sh`, the prototype for §2.

- The stand-up took 7 requests: the three pages in one batch, two skill loads, four rounds of the remaining reads, then the reply.
- One round plus the reply would have sufficed. Asked why, that session blamed two things, neither a prompt or setting:
  - it read "BEFORE READING" literally;
  - its own chunking habit.
- Results landed in this order, which motivated §2's interleaved batch:
  1. every inlined item, from all of START, MIDDLE and END;
  2. the skill text;
  3. START's long reads;
  4. END's long reads.
- The first real Read under `specs/` injected `specs/CLAUDE.md` and `specs/AGENTS.md` (`nested_memory`). Content inlined from `specs/` into the pages, read earlier, did not trigger it. §2 rules only on inlining those two files themselves. Not recorded: whether inlining from a subdirectory needs one real Read there to pull in its conventions.
- A `silent_turn_reminder` ("The user hasn't heard from you…") fired after ~42 s of silent reads and drew a status line from the model. Fewer requests avoid it.

Superseded pre-code cost analysis:

- Priced relative to one uncached input token: output 5, one-hour cache write 2, cache read 0.1.
- It concluded:
  - inline every mandatory range;
  - inline a conditional range only when `(1−p)·T·(2 + 0.1·N) < p·(250 + 0.1·C)`. Here `T` is the range's tokens, `p` the chance its trigger fires, `N` the requests left and `C` the context size when it would be read.
- §2 made context use, not price, the objective.

Proposed for the SKILL, not ruled on:

- A residue checklist for (B):
  - in-flight reasoning on the open question;
  - leanings not yet put to the human;
  - deferred threads;
  - the human's apparent priorities and frustrations;
  - framings dropped without a ledger entry;
  - agents or worktrees still out;
  - the next thing the conductor was about to say.
- Carry rulings as short verbatim quotes. The tool would resolve each against the transcript and flag any it can't find verbatim. That makes Dorc's `[TYPED]` checkable, and lets the successor verify each ~SUSPECT claim with one call.
- A tool-side lint that rejects `+SURE` in the handoff.
- The successor deletes the handoff as its last stand-up step. Nothing is lost, because both sessions' transcripts hold it.

Noted, not pursued, because transitions are human-managed: automatic triggering. Options were a SessionStart hook (`source: compact`) returning `additionalContext` (from josangel.com's handoff post), or an external listener using Claude Code's channels to inject a turn near the limit.

## 2. `expand-handoff.mts`, the deterministic helper (2026-10-05)

The incoming conductor's stand-up is two turns. Turn one runs `node <abs>/expand-handoff.mts <pickup-path> < <handoff>`. Turn two issues the reads the tool printed to stdout, verbatim, all in one turn. Tests: `node --test expand-handoff.test.mts`.

Human rulings that shaped it:

- The tool writes the pickup document itself. Stdout carries `Read all these in a single turn:` and the batch; stderr carries only warnings and a one-line summary. There is no tool-injected prompting beyond that one line.
- The handoff's text is never edited. The only change is inserting `<result>` blocks after inlined reads, below each read's indented annotation lines. Merged or re-cut calls appear only in the batch, and the document keeps the calls as written. A few stale or mis-sized `Read()` lines are harmless; fixing models' surrounding text is not worth trying.
- The batch interleaves pickup pages with the reads not inlined, in document order, so results land in document order. Without that, inlining hoists everything inlined above every issued read.
- Conditional reads are marked only by explicit `[when]` / `[p=…]` tags.
  - Mistaking a mandatory read for a conditional one leaves the successor reasoning from a partial foundation. The reverse mistake only wastes context.
  - Conditional reads are never batched. One is inlined only if that lowers expected context use, because context window, not price, is the scarce resource.
  - They are never re-cut. They fire after the rewind point, so they are open to TOCTOU and cheap anyway.
- Non-conditional reads are made correct at run time.
  - Unbounded or oversized reads are cut to fit the harness's per-read cap.
  - Runs of nearby reads of the same file are merged, then re-cut, when that's cheaper.
  - Repeats already covered are dropped.
  - Models may therefore emit plain unbounded reads.
- `CLAUDE.md` and `AGENTS.md` are never inlined, since the harness injects them itself. There are no currency or TOCTOU checks.

Cost model (tunables are at the top of the script):

- Mandatory reads carry their content either way. Inlining adds a second set of line numbers when the page is read; issuing adds a call, paid as output and then carried.
- Breakeven is about 20–40 lines on Claude Code at the default horizon. pi doesn't number lines, so it inlines whatever fits.
- Merged reads are always issued, because a merge's own call line would outweigh the result wrapper it saves.
- Measured on a Dorc stand-up (session `730ea7c3…`): cache writes about 75% of cost, cache reads across requests about 15%, output about 10%. The number of requests matters; inlining barely does.

Environment:

- **Harness formats are mirrored.** Claude Code returns `N<TAB>line`. pi returns raw lines plus its own `[N more lines…]` notice. Page calls copy the handoff's call syntax.
- **Harness and model are detected from the environment.** pi exports `PI_SESSION_ID` and `PI_MODEL`. For Claude Code, the tool checks `CLAUDECODE` and reads the newest `message.model` from `~/.claude/projects/*/<CLAUDE_CODE_SESSION_ID>.jsonl`. The running tool call is already logged when the command starts; this was verified.
- **Prices** come from pi's `~/.pi/agent/models-store.json`. Those are 5-minute cache-write prices; Anthropic's 1-hour TTL costs 1.6× more.
- **Paths:**
  - Windows↔WSL translation goes through `wslpath` (`wsl.exe -e wslpath` from Windows), cached, and is skipped where there's no WSL.
  - Printed paths are in the harness's form, with `--paths` for cross-side runs.
  - All four Windows/WSL harness × tool combinations are verified. macOS is untested.
- **CLI** parsing is Node's built-in `util.parseArgs`. Minimist (including zx's `argv`) and commander were rejected: the built-in is strict and needs no install.
- **Runtime:** the `.mts` runs on Node type stripping (≥ 22.18 / 23.6); the `.mts` extension avoids a module-type warning from `System/package.json`. Nothing type-checks it, because `@types/node` isn't installed.

Caller-side pitfalls, for the SKILL to handle:

- Git Bash rewrites POSIX-looking arguments to `node.exe`; `MSYS_NO_PATHCONV` turns that off.
- Running `node.exe` from WSL needs the script path converted with `wslpath -w`.

Open or unverified:

- ~SUSPECT Claude Code honors an explicit `limit` above 2000 lines. The tool caps at 2000 regardless.
- ~SUSPECT Edit refuses files that weren't actually Read, so inlined content wouldn't count. Punted by ruling.
- The Claude Code read budget (60k characters against a 25k-token cap) is conservative. It splits some reads Claude Code would take whole.
- Not built:
  - pointing each read at the moment in the predecessor's transcript where it was read or written
  - linking the predecessor's session file, which is now cheap via `CLAUDE_CODE_SESSION_ID` / `PI_SESSION_FILE`

Commits: `6bd9ab9` through `5d188ea` on System `main`.

## 3. Instruction files the harness loads by itself (2026-10-06)

`steering.mts` models what each harness loads into context with no read from the model. The per-harness profiles at its top hold the names, recursion and import settings. `expand-handoff` uses the model to avoid both double loads, since steering files are long and dense, and lost invariants.

Claude Code, as verified on 2.1.291 against its docs (code.claude.com/docs/en/memory), its leaked March source (`claudemd.ts`, `attachments.ts`) and live headless runs:

- **At launch**, it loads:
  - the managed `CLAUDE.md`
  - `~/.claude/CLAUDE.md` and `~/.claude/rules`
  - `CLAUDE.md`, `.claude/CLAUDE.md`, `CLAUDE.local.md` and unconditional `.claude/rules/**/*.md` in every directory from the filesystem root down to the launch directory
- **On a read** of a file below the launch directory, it loads the same names, plus rules whose `paths` match, for every directory strictly between the launch directory and the file. Ancestors contribute only matching path-scoped rules. Rules match gitignore-style (the `ignore` package), relative to the folder containing `.claude`, with braces expanded and a trailing `/**` dropped.
- **`@` imports** are expanded:
  - from prose only, outside code and comments
  - relative to the importing file, up to depth 5
  - text extensions only
  - nested files skip imports that resolve outside the launch directory
- **`AGENTS.md`** is read directly (2.1.277+), in default mode only when no `CLAUDE*` file exists at or above the launch directory; `~/.claude/CLAUDE.md` doesn't count. Nested ones arrive through a `PostToolUse` hook. Dorc instead uses `CLAUDE.md` = `@AGENTS.md`.
- **Dedupe:**
  - The harness skips any file already in its read-file cache, so an explicit whole read in the same batch prevents a double load (verified).
  - **A partial read also enters that cache, suppressing the harness's full load for good** (verified).
- **Worktrees:** from a worktree nested inside its main repo, the main repo's checked-in files are skipped and its `CLAUDE.local.md` is kept.
- **`claudeMdExcludes`** settings apply.

pi, from its `resource-loader.ts`: at launch it loads one file per directory, the first that exists of `AGENTS.override.md`, `AGENTS.md`, `AGENTS.MD`, `CLAUDE.md`, `CLAUDE.MD`. It does so in the agent directory and from the launch directory upward, skipping a main-repo file shadowed by a nested worktree's own copy. It has no imports and loads nothing on reads.

What `expand-handoff` does with the model:

1. A read of a file the harness loaded at launch is skipped. That covers case 1 of the request: an explicit whole read takes the file out of the at-risk set.
2. A file the harness may load by itself is never inlined. Otherwise a later real read would load it a second time.
3. Ranges on such a file are ignored: the read loads the whole file, keeping whatever `[when]` or mandatory status the outgoing agent gave it.
   - The human's reasoning: the outgoing agent couldn't control the harness either. Without this tool, "read only the first paragraph" would still be followed by the harness loading the whole file once the successor works in that directory.
   - Putting instructions where the harness loads them is the project's own intent, and a model shouldn't override it.
   - A real partial read would also suppress the full load for good.
   - A `[when]` read can't be widened without editing the handoff text, so it's left as written with a warning to read the whole file if it fires.
   - Superseded: `a618928` briefly inlined slices instead, which the human rejected (`5982a64`). On Dorc this now reads all 1,476 lines of `spike/AGENTS.md` where the handoff asked for 71.
4. Where inlining would skip instruction files the harness loads on a real read, the fewest reads covering them all are kept real.

Dependencies `yaml`, `ignore` and `braces` are declared in `System/package.json`. All three were already installed through zx, so `bun install` only needs to record them in `bun.lock`.

Open or unverified:

- ~SUSPECT the `AGENTS.md` hook also treats an earlier *partial* read as loaded. That's untested; it doesn't matter, since ranges are now dropped.
- Imports in project files that resolve outside the launch directory need a one-time approval whose state the tool can't see. It treats them as not loaded, so explicit reads of them are kept.
- Path-scoped rules from managed settings are not modelled.

Commits: `0d95fb7`, `a618928`, `5982a64`.

## 4. The SKILL's prose (2026-10-06)

Human rulings for `SKILL.md` and its sibling files:

- **Invocation.** The human usually asks for skills in prose ("…then proceed into the handoff skill") rather than opening with `/name`.
  - Tested on Claude Code 2.1.292: `disable-model-invocation: true` is a hard block, not steering.
  - The skill drops out of the model's list. A forced Skill call errors, telling the model to ask the human to type `/name`.
  - So it isn't used. The description carries the request-only steering.
- **Layout.** A near-empty `SKILL.md` holds only what both sides share and routes to `outgoing.md` or `incoming.md`, so neither side spends attention on the other's text.
- **Mining the session for context** is only for outgoing conductors that haven't been ledgering. Ledgering exists to manage window attention as the work goes.
  - It gets its own file, chained from `outgoing.md`.
  - Alternatively the outgoing side splits into ledgering and plain variants; undecided.
  - `[TYPED]` / `[ACKED]` belong to ledgering practice, so they appear only in that file.
- **Ledgering stays soft**; there's no global ledgering skill yet. If a ledger is running, invoking this skill authorizes bringing it up to date the way it has been used. The handoff doesn't repeat it.
- **Durable versus not** gets one paragraph. Part of the point is carrying forward what isn't authorized, or isn't important enough, to make durable: work in flight, unsettled questions, things the human hasn't acked, anything the project's own practice keeps out of what it saves.
- **Naming.** The document is "the handoff". "Residue" only ever meant the part that couldn't be made durable.
- **Headline: reference, don't copy.** Each piece of context gets one deliberate home. Don't restate what a ledger or a dictated read already says. Add to it only where there's something it can't hold.
- **Ordering.** The prose says that ordering matters and leaves the choice to the outgoing conductor. The shape, from first to last:
  1. Steering that stays important for the whole session. Mostly the human's own prompt, which they write and tune.
  2. Material that stays important, at the top of the U.
  3. The least important material, in the middle.
  4. Material important only for the work in flight, at the bottom.
  5. Short-lived steering, last: what was just being done, what the human last asked.
- **Read-line format is not specified.** The tool keeps every read line, inserts results after it, and should cope with whatever a model writes (e.g. `Read(doc.md) # why`).
  - +SURE from its parser: a call is recognized only at the start of a line, optionally bulleted or in backticks. A call mid-sentence is missed.
  - If that matters, fixing it is the code's job, not the prose's.
- **The outgoing conductor never reads or runs the tool.** By then its window may be down to 20–50k, and most of that should go into the handoff, ideally as one final write. Its only contact with the tool is one command for the human to copy, with its filenames filled in.
- **Filenames** are the outgoing conductor's choice, with no steering. Examples use long descriptive names, never `handoff.md`.
- **No successor prompt.** The human writes their own prompt, possibly naming skills of their own. The top of the handoff is what follows that prompt. The tool's one printed line ("Read all these in a single turn:") is the only other steering.
- **Invocation documentation stays light:** one example code block. `--help` is a last resort; don't steer toward it.
- **Punted:**
  - Prior-session data. The tool will add it.
  - Successor skills. For now they're plain reads of their files. Open idea: load skills in a separate turn so each arrives with its supplements.
- **The first draft is minimal.** Anything questionable is left out; this section records it for later.

## 5. First live run (2026-10-06)

The run happened at the tail of Dorc session `730ea7c3…`. Only the outgoing side ran. It wrote `_tmp-314a-handoff.md`, 197 lines, about 3k tokens.

**Outgoing requests.** Three requests at about 880k of context: read `outgoing.md`, one Write, then the command.

- Human ruling: the extra routing request matters on the outgoing side, not the incoming. One more ~900k cache read isn't ruinous, but it is waste.
- To test: can a skill invocation in Claude Code or pi go straight to a sibling file, with no agent turn in between?
- If not, the skill may split in two, `fat-handoff` and something like `fat-pickup`, so the outgoing agent reads only one `SKILL.md`. The human dislikes that option.

**Cold cache.** `/fat-handoff` came 80 minutes after the previous turn, so the 1-hour cache had expired.

- The first request re-wrote 866,848 tokens: about 1.7M input-token equivalents, roughly 2.8× the whole original stand-up.
- Writing the handoff itself took one request and 7.7k output tokens.

**Fidelity:**

- All ten `[TYPED]` quotes were checked against the human's 50 messages. Nine are verbatim; one is cut short mid-sentence with a period added, otherwise word for word.
- The agent wrote its own tag legend into the handoff header, since only `outgoing.md` defines the tags.
- Where its edits had shifted line numbers, it gave grep anchors instead. Idea: the tool could turn anchor text into a current range at stand-up.

**Trial expansion** (into a temp dir): "inlined 0 of 13 reads; split 1 too large for one read; 4 page(s), about 3k tokens". It found two bugs:

- All five `[when]` reads were batched as mandatory. Each tag sat on a bullet line, with the reads on that bullet's indented continuation lines, outside the tool's annotation scope.
  - That's about 118k characters (~30k tokens), landing just before the handoff's closing section.
  - It includes an 82k-character census split into two reads, though conditional reads are never to be split.
- The command's `<` redirect is a parse error in Windows PowerShell 5.1, and that session ran its shell commands through PowerShell.

Human ruling: fix both. The tool takes explicit `--in` and `--out` flags, with no positional arguments and no stdin, so the command needs no explanation.

**Punted while the human experiments:**

- **The foundation may be thin.** The handoff's mandatory reads total about 43k tokens. They re-dictate none of the ~250k foundation the session was stood up on; the original reading list survives only as a 40-line conditional read.
- **Skills may load twice.** The handoff says "Load these skills before working" and also dictates reads of their `SKILL.md` files. ~SUSPECT the successor would load them twice.
- **Drift and staleness.** The human added a line to `SKILL.md` (`72ba9f5`) saying handoffs are immediate: ignore git and disk TOCTOU, and lean toward trusting the other side's recency. This answers the agent's notes about line-number drift.

**Data for carrying every human message:** in this design session the human typed about 52k characters (~13k tokens) over 50 messages, against about 170k characters of visible assistant text, roughly 1:3.3. Carrying every message verbatim would cost about 13k tokens.

## 6. Tool fixes, routing test, and the split (2026-10-06)

**Tool fixes**, done by a builder subagent in commits `0af1fd0` through `8eadb85`. The suite passes 48 of 48.

- **Reach of a tag.** A tag still applies through its read's own line and the indented lines under it. It now also applies to every later read in the same block:
  - A tag on a bullet reaches that bullet's deeper-indented lines.
  - A tag on a plain line reaches the lines after it at its indent or deeper.
  - A blank line, an ATX heading, a sibling bullet or a dedent ends the reach.
  - A heading never makes a read conditional, even with a bracket tag in it.
  - A read's own lines never tag another read.
  - Inlined `<result>` blocks are skipped over, so running the tool again on its own output gives the same result.
  - `[inline]` and `[no-inline]` reach the same way. The nearest tag of each kind wins.
- **Flags.** Required `--in` and `--out` replace the positional argument and stdin. Either path form is accepted.
- **Re-run on the 314a handoff:** "inlined 0 of 13 reads; 3 page(s)". The five `[when]` reads are gone from the batch, and the census is no longer split.
- **Open risks the builder flagged.** The first two make a read conditional by mistake, the costly direction:
  - An indented tag line directly under a read attaches to that read, not to the next one.
  - A legend paragraph mentioning `[when]` tags a read on the very next line. Possible fix: ignore tags inside backticks.
  - Calls that don't start their line are still not recognized.
  - Each tab counts as one column of indent.

**Routing test** (subagent, Claude Code 2.1.292, 20 headless runs; pi from source at 0.84.3, 1.0.0 and 1.0.4).

- **Claude Code** can route on an argument at no extra request. The skill body line `@${CLAUDE_SKILL_DIR}/$0.md` attaches the chosen file in the same step as the skill text. +SURE for project and plugin skills.
  - Typed command: 1 request instead of 2. Model-invoked with `args`: 2 requests instead of 3.
  - With no argument, `$0` stays literal and the file is silently missing.
  - Shell injection (`` !`cat …` ``) is unsafe: the argument is pasted raw into the shell command. It is also brittle: it needs Bash, it is blocked outside the working directory, and any failure aborts the whole skill load.
- **pi** expands `/skill:name args` with no substitution and no includes. A model-invoked skill is a plain `read` of `SKILL.md`. Getting another file in with zero extra requests would need an extension (an `input` hook).

**Human ruling: split the skill.**

- The human briefly considered routing on the argument: an empty `$0` for outgoing, `incoming` for picking up. They chose to split instead, because they use pi too, and a split is bullet-proof and tab-completes.
- `fat-handoff` is authoritative and holds the outgoing instructions in its `SKILL.md`, so the outgoing agent's only read is that one file. It also keeps the tool, the tests and this ledger: the outgoing agent has its own skill directory in hand when it prints the command.
- `fat-pickup` holds the incoming instructions.
- Both `SKILL.md` files open with the same shared section, everything before the first `#` heading. The human keeps the two copies in sync by hand.
- `fat-pickup/README.md` is a relative symlink to `fat-handoff/README.md`, which is empty for now. It was created as a native Windows symlink (`MSYS=winsymlinks:nativestrict`) and recorded as mode 120000 with target `../fat-handoff/README.md`. It passed the portable-symlink pre-commit guard and resolves from WSL.
- `outgoing.md` and `incoming.md` are gone. `mining-context.md` stays in `fat-handoff` as its one conditional read.
- Commits: `e82ce42`, `9fcde3f`, `8692ef4`.

## 7. Tags narrowed to the call's own line; second run (2026-10-06)

Human ruling: the rule that tags reach beyond their read is rescinded, because a misplaced tag turns a mandatory read conditional. A tag now counts only on the read call's own line, after the call. A tag anywhere else is prose, and the read stays mandatory. This applies to `[when]`, `[p=…]`, `[inline]` and `[no-inline]`, and it is narrower than the original rule: the indented annotation lines below a read no longer carry tags. They still decide where an inlined `<result>` goes.

- The builder reverted §6's tag-reach work as one labelled revert, then narrowed in separate commits: `e487d72`, `ec8b785`, `8f6b094`, `e99830d`. The suite passes 44 of 44.
- On the 314a handoff, its five bullet-line `[when]` reads are mandatory again. The tool's output matches the original pre-fix summary and batch.
- §6's description of how far a tag reaches is superseded. Its `--in`/`--out` part stands.
- Not yet in the prose: neither `SKILL.md` says a tag must sit on the call's own line. Only the example shows it.

Human ruling: no shared tag legend for now. Whether to explain the claim tags is left to the handoff agent.

Second run: a rewind, then a fresh `/fat-handoff` under the split skill. It wrote `.tmp/r31-world-relations-naming-sitting.handoff.md`, 151 lines.

- **Two requests:** the Write, then the reply. The split removed the routing read.
- **The example shaped the output:**
  - Every `[when]` sits on the same line as its read.
  - The filename is the example command's placeholder, copied, and the file's title was its path. The human then dropped the example's path-title (`492b871`).
  - It still didn't copy the example's order: it put the ledger near the top, as permanent material.
- **What it carried:**
  - It restated ledgered conduct "because they govern every action".
  - It included both resumable subagent IDs.
  - It quoted the whole remit as `[TYPED]`.
  - It dropped the "Load these skills" line.
  - The mandatory reads total about 38k tokens, the same thin-foundation question as run 1.
- **Cache miss despite the timing.** It came 51 minutes after run 1, inside the 1-hour window, yet still re-wrote 865,746 tokens; only the ~19k system prompt was a cache hit.
  - ~SUSPECT: after a rewind, the only live cache entries end inside the abandoned branch, not at the point rewound to.
  - If so, each rewind-and-reinvoke on a long session costs a full re-write: about 1.7M input-token equivalents at ~880k.

## 8. Pages break at prose; Claude Code's re-read dedup; `--last-saw` (2026-10-06)

**Pages break at prose** (`46d904d`, `b88b77b`, `3979732`; 47 of 47 tests pass).

- Two reads share a page, or two reads of the same file merge, only if everything between them is blank lines, read calls (`[when]` lines included) or a read's indented annotation.
- Any other text, or an inlined `<result>`, starts a new page.
- `MERGE_GAP_TOKENS` is gone, and no new size heuristic replaced it.
- On run 3 this gives 6 pages, where it gave 3. Line 24's ledger lead-in and line 28's "Background" heading now land after the reads above them.
- Now pinned by a test: the pickup equals the handoff once its `<result>` blocks are removed, and the pages cover the whole file with no gaps or overlaps.
- Human ruling: the read lines, `[when]` lines and prose must stay visible, in position and as written, in the pages the successor reads. The stdout batch may rewrite calls.

**Third run.** The `fat-pickup` happened in a rewound and resumed fork (`aed06c03`), back at the end of the original stand-up. It re-read the stand-up's foundation documents in full, about 60–70k tokens of duplicates. The human interrupted it. The human then added a stdout line (`a3f1bf1`) saying a partly rewound agent may omit reads unlikely to have changed. With that, a later test skipped most of the duplicates.

**Claude Code's re-read dedup** (a research subagent; the 2.1.292 binary, the 2.1.88 source, the changelog, issues, and five headless runs).

- Since 2.1.86, a re-read can return a stub instead of content: "Wasted call — file unchanged since your last Read. Refer to that earlier tool_result instead." +SURE. It does so only if all of these hold:
  - the offset and limit exactly match the cached read;
  - the file's mtime exactly matches the cached timestamp;
  - the cached entry came from a Read, not an Edit or Write.
- The cache keeps one entry per path; the last read wins.
- ~SUSPECT the cache is still an LRU of about 100 entries, as in 2.1.88.
- When the cache is rebuilt or cleared:
  - **Resume:** rebuilt from the transcript, using message timestamps rather than mtimes, so the first re-read of every file comes back full. `/branch` and `--fork-session` behave like resume.
  - **Rewind:** drops the paths touched in the discarded turns (2.1.260).
  - **Compaction:** clears the cache and re-attaches a few files.
- The doubled reads in run 3 were therefore expected: the process changed from 2.1.289 to 2.1.292 between the rewind and the pickup.
- No setting keeps the dedup across these events, and no issue is filed about duplicates coming back in full.
- Nested `CLAUDE.md`/`AGENTS.md` loading checks the same cache and also compares content. None were re-injected. The 15k `instructions` attachment after the rewind was the Dorc `MEMORY.md`, which had changed since the stand-up.

**Decision: `--last-saw <sha|datetime>`.** The harness's dedup can't be relied on, so deduplication moves to us.

- **Rejected:** looking reads up in the session transcript. It is exact even across rewind and branch trees, but fragile across teleport, pi, other machines and compaction.
- **Rejected:** dates the agent sees. It sees only the session date, and that date is rebuilt on resume, so it can be newer than its reads.
- **The anchor:** a commit SHA visible above the reads in the agent's window. It predates those reads, so it can only be too old, which is safe. The human may instead put a datetime they can see in the harness into their prompt.
- **Annotate, never drop.** The tool knows whether a file changed; only the agent knows what is in its window.
  - The tool appends `# unchanged (same content as at <sha|datetime>)` to batch reads of tracked files that are unchanged since the anchor.
  - The agent skips those it can see above.
  - Untracked and ignored files go unannotated. The human cares less about them, since the heavy, stable documents are all committed.
- **Implementation preference:** a git library if it's tractable, and if not, a few batched git CLI calls, without mechanizing many shell calls. The human will tune the stdout steering line.
- Context: `core.autocrlf=input` in System and Dorc; their working trees are LF.

## 9. `--last-saw` as built (2026-10-06/07)

Commits `618ddb4` through `0508820`; the code is in `last-saw.mts`. The full test command is now `node --test expand-handoff.test.mts steering.test.mts last-saw.test.mts`, and 62 of 62 tests pass.

**Mechanism.** The tool calls the git CLI, three or four calls per repo. A library was rejected because isomorphic-git compares raw blobs without git's line-ending filters, and it would add a dependency.

- Each file is assigned to a repo by resolving symlinks and walking up to the nearest `.git`.
- A file counts as unchanged when `git diff --name-only <anchor> -- <tracked>` leaves it out. That diff runs against the working tree, so uncommitted edits count as changes.
- Untracked and ignored files are never marked. Neither are files in a repo where the anchor doesn't resolve.

**Anchors.** The tool first tries the value as a commit in each of the batch's repos. Otherwise it is a time, and each repo uses its last commit at or before that time, by committer date.

- **Strict parsing.** git's approxidate is not used, because it reads junk as "now", which is the unsafe direction.
- **Accepted times:**
  - ISO 8601, or `YYYY-MM-DD[ HH:MM[:SS]]`, in local time unless a zone is given;
  - Claude Code turn stamps as the human pastes them, e.g. `Worked for 3m 44s · done Monday 11:57` or `done 18:58`;
  - month-day forms such as `Oct 1 11:57`. These are a guess: nobody knows how the UI stamps turns older than a week.
- **Resolution:** a stamp resolves to the most recent past moment that matches it.
- **Safety:** "done" marks the end of the turn that did the reads. The tool subtracts the `Worked for` duration, and every time anchor is floored to the minute.

**Output.** The pickup document is unchanged; it is still the handoff plus `<result>` blocks.

- **Batch lines:** each matching read gets `# unchanged (same content as at <x>)`. Here `<x>` is the resolved commit's 8-character SHA, or the resolved time as `YYYY-MM-DD HH:MM`, as the human ruled.
- **Line A:** after the human's two steering lines comes `(Reads marked "unchanged" have the same content now as at your --last-saw <input as given>.)`. It is printed only if the anchor resolved in at least one repo, so its claim is never false.
- **Line B:** `(Right now: <Ddd YYYY-MM-DD HH:MM UTC±hh:mm>, HEAD at <sha8> (<branch>).)`, for the repo containing the working directory.
  - It is printed on every run, with or without the flag. That is the conductor's reading of the human's "for other reasons", and the human may flip it.
  - If HEAD is detached, the branch is left out; outside a repo, the HEAD clause is left out.

**Run 3 on 2026-10-07:**

- The stamp `Worked for 3m 44s · done Monday 11:57` resolved to 2026-10-05 11:53. The commit used is `bd5554e8` in Dorc and `f595c90` in System. It marked 14 reads.
- `bd5554e8` marked 12; the two System skill files are marked only under a time anchor.
- Note 315 dropped out of both counts because Dorc's `491b6c52` capitalized model terms.

**Open:**

- **Daylight-saving gap.** A stamp inside the hour skipped when the clocks go forward is shifted an hour later, which is unsafe, on one day a year.
- **Dirty-then-reverted files.** A file read with uncommitted edits and later reverted is marked unchanged, though the agent saw the edited version.
- **Line B covers only the working directory's repo.**
- **Nothing tells a successor to add `--last-saw`.** It's added only when the human puts a stamp in their prompt or steering tells the successor to append one.

## 10. Turn stamps keyed on the middot; `[when]` reads unmarked (2026-10-08)

**The bug.** A pickup's `--last-saw "Brewed for 1m 58s · done Monday 12:34"` warned and marked nothing. The parser accepted only the literal prefix `Worked for`, but Claude Code picks a random past-tense verb ("Brewed", "Baked", "Cogitated"), and the human may also paste the leading `✻` glyph.

**Human ruling:** key on the middot (`·`, U+00B7), not on the verb or on "for".

**The fix** (commits `f54fcee`, `1c8c806`, `8a1b79c`, `9323cb6`; 64 of 64 tests pass):

- **Parsing:** when a `·` is present, the text before it must end in a duration of h/m/s tokens; anything before that duration is ignored. If no duration is there, the value is rejected.
  - The text after the `·` parses as before, and stamps with no `·` are unchanged.
  - This supersedes §9's "subtracts the `Worked for` duration".
- **No longer accepted:** a stamp with no middot, or with some other separator such as `•` or mojibake. These now get the first warning below, which fails safe.
- **The single warning is now two:**
  - the value is neither a commit in the batch's repos nor a time the tool reads;
  - the value is a time, shown resolved, but no repo has a commit at or before it.
- **Verified:** `✻ Baked for 33s · done Monday 12:34` resolved to 2026-10-05 12:33 and marked 14 reads. Git Bash passes `✻` and `·` through intact.
- **Minor open points:**
  - The second warning also fires when no batch file is in any repo, which reads as though repos were checked.
  - One test's fixed instants would fail in UTC−11 or UTC−12.

**The pickup agent reported a gap:** `[when]` reads get no "unchanged" markers. Several were already in its window from 10-05 (312d, 311t, 312cg, 26Ob, 28Q, 312f, 311u). This is by design so far: markers are only appended to stdout batch lines, and `[when]` reads are never batched.

- **Option 1, recommended by the conductor:** insert a marker line under each unchanged `[when]` read in the pickup, where an inlined `<result>` would go.
  - It sits next to the trigger the agent consults later.
  - It widens the invariant to "the handoff plus `<result>` blocks plus marker lines", still insertion only.
- **Option 2:** a single stdout line listing the conditional reads that are unchanged.
  - The pickup stays exactly the handoff plus results.
  - The marker sits far from the trigger.
- **Awaiting the human's ruling.**
