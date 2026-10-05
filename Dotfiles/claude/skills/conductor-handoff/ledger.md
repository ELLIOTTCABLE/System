# conductor-handoff ledger

## 1. Research and design, before any code

_(Open. To be filled in by the pre-code session.)_

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
