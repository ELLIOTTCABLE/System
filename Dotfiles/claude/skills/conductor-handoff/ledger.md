# conductor-handoff ledger

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
3. A partial read of such a file is inlined as a slice, never read for real, because a real one would suppress the full load. The harness still loads the whole file if the successor works in that directory. A slice too large to inline is widened to the whole file. On Dorc this kept a 71-line slice of `spike/AGENTS.md` from becoming the whole 1,476-line file.
4. Where inlining would skip instruction files the harness loads on a real read, the fewest reads covering them all are kept real.

Dependencies `yaml`, `ignore` and `braces` are declared in `System/package.json`. All three were already installed through zx, so `bun install` only needs to record them in `bun.lock`.

Open or unverified:

- ~SUSPECT the `AGENTS.md` hook also treats an earlier *partial* read as loaded. That's untested; the tool assumes so and inlines slices anyway.
- Imports in project files that resolve outside the launch directory need a one-time approval whose state the tool can't see. It treats them as not loaded, so explicit reads of them are kept.
- Partial reads tagged `[when]` stay as written, because the handoff text is never edited. If one fires later, it can still suppress the full load.
- Path-scoped rules from managed settings are not modelled.

Commits: `0d95fb7`, `a618928`.
