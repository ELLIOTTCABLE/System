# VERIFICATION

Test machine: Windows 11, MINGW64 (Git Bash) — `uname`: `MINGW64_NT-10.0-26200 ... Msys`.
`sh` = `/bin/sh` (bash in POSIX mode). Date: 2026-07-05. All three primary lanes exercised end-to-end
this round (codex saved-login, antigravity print mode, DeepSeek via ds-review), plus the kagi-ken MCP
lane on each.

## Binaries on THIS machine (`command -v`)

| Binary | Present? | Notes |
|---|---|---|
| `claude` | yes | mise-installed 2.1.201 |
| `node` / `npm` / `npx` | yes | Node 25.x |
| `codex` | yes | mise npm backend, `codex-cli 0.142.5` |
| `antigravity` / `agy` | yes | mise aqua backend, `1.0.16` |
| `op` | yes | 1Password CLI 2.32.1 (desktop-app integration) |
| `gemini` / `qwen` / `deepseek` | NO | gemini lane superseded; deepseek reached via `ds-review` |

## Test matrix

| # | What | Result |
|---|---|---|
| T1 | `sh -n` all wrappers | PASS — ds-review, codex-review, foreign-mcp.json all parse/validate clean, LF-only. |
| T2 | ds-review fail-loud on no key + no op | PASS — guard fires before any network. |
| T3 | ds-review command construction + profile isolation | PASS (hermetic shim test, prior round). |
| T5 | **codex saved-login smoke (native Windows)** | **PASS** — exit 0, nonce round-tripped, model gpt-5.5, read-only sandbox executed a read. See below. |
| T6 | **antigravity print-mode smoke** | **PASS (with a packet-only finding)** — auth + plain-text output OK; headless tool use does NOT work. See below. |
| T7 | **DeepSeek via ds-review, end-to-end** | **PASS** — DS-OK + probe.txt read both returned; env-and-op auth paths both work. See below. |
| M1 | **codex kagi-ken MCP probe** | **PASS** — `kagi_search_fetch` executed, real result. |
| M2 | **DeepSeek kagi-ken MCP probe** | **PASS** — tool ran, real result. |
| M3 | **antigravity kagi-ken MCP probe** | **FAIL headless / interactive-works** — see below. |
| R3 | gemini `GEMINI_API_KEY` still valid? (research) | ALIVE — API-key auth unaffected by the OAuth sunset. See below. |

### T5 — codex saved-login smoke (native Windows, 2026-07-05)

From a throwaway `git init` dir with a random nonce in `probe.txt`:
```
codex exec --json -o report.md "Read the file probe.txt … reply with exactly its contents" </dev/null
```
Exit 0. `report.md` = the exact nonce. The JSONL and the session rollout show:
- **Model `gpt-5.5`** (provider openai), context window 258400 — the saved `codex login` (API-key
  sign-in on a funded throwaway API account; **per-token billing, no ChatGPT plan**).
- **`sandbox_policy: {"type":"read-only"}`, `approval_policy: "never"`** applied to the turn — the exact
  native-Windows condition the old read-decline bug describes. Codex executed
  `powershell.exe -Command "Get-Content -Raw probe.txt"` → `exit_code 0`, **no sandbox-decline**.
- **OVER-CLAIM, corrected in Round 2 (below).** This proved only that codex reads files *from a
  git-repo-root cwd, in-repo* — the probe ran inside a throwaway `git init` dir, reading a file in that
  same dir. It did NOT prove the sandbox reads files unconditionally. Round-2 live-fire established the
  real rule: codex's read trust is keyed to "cwd IS a git-repo root"; a non-repo cwd (even with
  `--skip-git-repo-check`) or an out-of-workspace path from a repo cwd is denied. The old *blanket*
  read-decline bug does not reproduce; the trust rule does. `-c sandbox_permissions` remains the
  last-resort widening, not routinely needed.
- Usage: input 24868 (cached 6912), output 117, reasoning 0 → ≈ a few cents (exact tokens; gpt-5.5 rate
  is a -GUESS).
- `config.toml` carries `[windows] sandbox = "elevated"`, but the effective per-turn policy logged was
  `read-only` — not a confounder; the read succeeded under a genuine read-only policy.

### T6 — antigravity print-mode smoke (6 requests total; free-tier budget respected)

- **Auth + basic function:** `antigravity -p "Reply with exactly: AG-OK" --print-timeout 120s` → exit 0,
  ~4s, plain-text `AG-OK` on stdout, stderr empty. Confirms Google-OAuth login works and output is
  PLAIN TEXT (no `--json`/`--output-format` in `--help`; no JSON mode).
- **Flag gotcha:** `--print-timeout` takes a **Go duration** (default `5m0s`); a bare integer (`120`) is
  rejected as a usage error (exit 2, ~1s, no request spent). Must be `120s`/`5m`.
- **Tool use (no bypass flag):** `-p "Read probe.txt …"` from the probe dir → **exit 1, hung the full
  122s to `--print-timeout`**, output `Error: timeout waiting for response`, nonce ABSENT. Print mode
  cannot complete tool loops non-interactively (it dispatched a search, returned a placeholder, then
  timed out). → **The antigravity lane is packet-only: self-contained packets, no file/repo access.**
- **Model selection:** `antigravity models` lists Gemini 3.5 Flash (Low/Med/High), Gemini 3.1 Pro
  (Low/High), Claude Sonnet 4.6, Claude Opus 4.6, GPT-OSS 120B. `--model "Gemini 3.1 Pro (High)"` is
  accepted (exit 0). Default (unspecified) is Flash-tier. -GUESS whether the free tier truly serves Pro
  compute vs silently downgrading — a trivial prompt can't tell.

### T7 — DeepSeek via ds-review, end-to-end (2026-07-05)

ds-review rewritten to resolve the key from `$DEEPSEEK_API_KEY` else `op read` (inline in `exec env`, key
never to disk/stdout/log; `env` load-bearing per the T5b leak), and to load the read-only kagi MCP via
`--mcp-config ~/.claude/bin/foreign-mcp.json --strict-mcp-config --allowedTools <kagi tools>`.

- **DS-OK (op-read branch):** `ds-review "Reply with exactly: DS-OK"` → exit 0, `is_error:false`,
  `.result == "DS-OK"`. The op-read → DeepSeek-auth path (previously UNTESTED) works end-to-end.
- **probe.txt read:** exit 0, `is_error:false`, nonce round-tripped, `num_turns:2` — DeepSeek V4-Pro
  drove Claude Code's read-only Read tool. Nested read-only tool use confirmed on the DeepSeek endpoint.
- **Cost caveat:** the envelope's `total_cost_usd` (~$0.13–0.24) and model id (`claude-opus-4-8[1m]`) are
  Claude Code's own Anthropic-priced labels — the request hit DeepSeek, so real cost is ~1–2¢/call. The
  ~26–46K input tokens are Claude Code's system-prompt overhead, not the packet.
- **op-read fragility:** one run failed with `op read: error initializing client: authorization timeout`
  (a missed 1Password desktop re-auth) → empty key → nested "Not logged in" (`is_error`, $0, no network).
  Non-silent; re-run or export `DEEPSEEK_API_KEY`. Each op-branch call triggers a Windows Hello prompt —
  the usability cost of keeping the key off disk.

### M1–M3 — kagi-ken MCP parity probes

Token model: kagi-ken-mcp reads `KAGI_SESSION_TOKEN` else `~/.kagi_session_token`; the token already
lived ONLY in that canonical file (87 bytes, pre-existing) — nothing was migrated, and all three lane
configs are secret-free (command+args only). The user's own Claude Code entry was already secret-free
(`env:{}`).

- **M1 codex — PASS.** With `[mcp_servers.kagi-ken] default_tools_approval_mode = "approve"` in
  config.toml, plain `codex exec` ran `kagi_search_fetch` (JSONL: `mcp_tool_call … status:completed,
  result≠null`) and answered "Dario Amodei / SUCCESS". (Under the default `approval_policy: never`,
  MCP elicitations are auto-rejected → "user cancelled MCP tool call"; the per-server `approve` mode is
  the non-escalation fix.)
- **M2 DeepSeek — PASS.** After adding `--allowedTools "mcp__kagi-ken__kagi_search_fetch,…"`, ds-review
  returned "Dario Amodei / SUCCESS", `is_error:false`. (Without the allow-list it reported "Awaiting
  your permission to use mcp__kagi-ken__kagi_search_fetch" — the headless permission gate.)
- **M3 antigravity — FAIL headless, works interactively.** Config at `~/.gemini/config/mcp_config.json`
  IS loaded (antigravity cached the tools at `~/.gemini/antigravity-cli/mcp/kagi-ken/` and `settings.json`
  allows `mcp(kagi-ken/kagi_search_fetch)`), but headless `-p` never executes it: the log
  (`toolPermission=request-review`) shows the model flailing — trying to read `mcp_config.json`, then to
  write/run `call_mcp.py` / `run_kagi.js` — both `invalid tool call`, then a **parametric** answer (no
  `kagi_search_fetch` execution in the log). Reproduced from the untrusted scratch dir AND from the
  trusted `Sync/Code/Dorc` workspace with both tools freshly allow-listed → **not a directory-trust
  issue; a print-mode harness gap in 1.0.16.** The human confirms MCP works in the interactive `agy`
  CLI. So kagi-ken stays configured for antigravity's interactive use; the headless reviewer is
  search-less.

### R3 — does gemini-cli still accept `GEMINI_API_KEY` after the OAuth sunset?

**ALIVE.** The 2026-06-18 sunset was consumer-OAuth-scoped. Google's own transition post (gemini-cli
discussion #28017, Jun 18 2026): "Gemini CLI will stop serving requests for Google AI Pro, Google AI
Ultra, and free tier individual accounts. Enterprise users with Gemini Code Assist licenses **and API
key authentication remain completely unaffected**." Corroborated (botmonster, Jun 2026): "You can still
run Gemini CLI by feeding it a paid Gemini API key." The dead path is OAuth "Sign in with Google"
(issue #28229, Jul 1 2026: `IneligibleTierError`, reporter had no `GEMINI_API_KEY`). Caveats: it's a
paid per-token lane (no free tier), and as of 2026-06-19 the Gemini API rejects unrestricted `AIza`
standard keys — use a restricted / new-style `AQ` "auth" key (AI Studio now creates these by default);
all standard keys sunset ~2026-09. Documented as an optional lane; not installed (user holds no key).

## -GUESS / assumptions the reviewer should re-check

- CORRECTED (Round 2, was a wrongly-"RESOLVED" -GUESS): codex 0.142.5's native-Windows read-only sandbox
  reads files **only from a git-repo-root cwd, in-repo** — T5's clean read ran inside a `git init` dir,
  which masked the scoping. Live-fire (§Round 2) showed a non-repo cwd or out-of-workspace path denies
  reads. The old *blanket* read-decline bug does not reproduce; the trust rule (repo-root cwd) does.
- RESOLVED: codex reads the saved `~/.codex/auth.json` login for `codex exec` (per-token, funded API
  account). `CODEX_API_KEY` is the env-var override the op-key wrapper uses.
- RESOLVED: antigravity print-mode exit codes / behavior — now observed (exit 0 clean, exit 1 on
  tool-timeout; `--print-timeout` needs a duration unit).
- FINDING: antigravity headless `-p` cannot run tools (built-in OR MCP) without
  `--dangerously-skip-permissions` (forbidden) — packet-only. Root cause -GUESS: the print harness
  doesn't register MCP tools as callable (model resorts to writing scripts), independent of workspace
  trust. Interactive CLI is unaffected (human-verified).
- -GUESS free-tier antigravity `--model "Gemini 3.1 Pro (High)"` is accepted but may downgrade to Flash
  server-side — a trivial prompt can't distinguish.
- CAVEAT: ds-review's `total_cost_usd` is Anthropic-priced, not DeepSeek's real (far lower) bill.
- CAVEAT: the op-read branch depends on the 1Password desktop app staying authorized; an `authorization
  timeout` yields an empty key → nested "Not logged in". Export `DEEPSEEK_API_KEY` to avoid the prompt.
- ~SUSPECT the `--disallowedTools "Edit,Write,Bash"` denial holds while Read/Grep/Glob stay usable — T7
  exercised Read successfully, so at least Read is unprompted; Edit/Write/Bash denial not adversarially
  tested this round.
- Codex model/effort is config-file driven (`~/.codex/config.toml`, currently `gpt-5.5`); the artifacts
  don't set it (the human tunes it). Not a guess.

## Round 2 — hardening fixes (branch `ai/foreign-models-r2`, 2026-07-05)

Applied after a three-lineage live-fire review of the installed wrappers. Each fix notes HOW it was
checked: **static** (`sh -n` / JSON lint), **live** (a real dispatch this round), or **reasoned**
(argued, not independently exercised). Internal checks are process evidence, not proof — the wrappers
still want real-world battle-testing before anything here is treated as settled.

| Fix | Change | Checked |
|---|---|---|
| 1 | ds-review child `CLAUDE_CONFIG_DIR` from `FOREIGN_CLAUDE_CONFIG_DIR` (dedicated override), never the caller's own | static; reasoned |
| 2 | ds/codex-review resolve the key by shell export, never on argv (kills the transient `env VAR=$key` process-table window); + non-empty guard | static; live (op→export path ran, `is_error:false`) |
| 3 | ds-review pipes the prompt to nested `claude -p` via stdin, not argv | **live** — probe 2 nonce round-tripped through a stdin prompt |
| 4 | ds-review pins `ANTHROPIC_MODEL=deepseek-v4-pro` (+ small/fast=`deepseek-v4-flash`); DeepSeek maps claude-sonnet/haiku* and any unknown name → the weaker v4-flash | **live** — probe 2 succeeded with the explicit id (DeepSeek accepted it) + DeepSeek Anthropic-API docs |
| 5 | ds-review `--allowedTools` adds `Read,Grep,Glob` | **live — premise corrected, see note below** |
| 6 | codex stdin form `codex exec - < packet` (agent def + codex-review wrapper) | live (codex stdin probe) |
| 7 | codex git-repo-root cwd trust rule mirrored into SKILL/INSTALL; T5 over-claim corrected | doc; evidence below |
| 8 | ds-review explicit `--disallowedTools Edit,Write,Bash,NotebookEdit,WebFetch,WebSearch,Task` (was auto-deny-by-accident) | static; reasoned (not adversarially forced) |
| 9 | foreign-mcp.json pins kagi-ken to commit `83e1c5b` (= release 1.3.0) instead of the default branch | static (JSON lint); SHA via `gh` |
| 10 | ds-review `env -u` the inherited `ANTHROPIC_*` / `CLAUDE_CODE_USE_*` auth/model/endpoint vars; proxy vars deliberately kept | static; reasoned |
| 11 | `model: sonnet` pinned in all 3 agent defs; shim-model-rule callouts in SKILL + INSTALL | static (present); incident below |
| 12 | packet-as-file contract on all 3 shims (Write-tool materialization, NEVER heredoc/echo; deepseek+codex stdin-from-file, antigravity `"$(cat)"` + ~25KB argv guard) | static (defs read as runbooks); incident below; composes with fix-3 |

### fix-5 — premise falsified, then corrected (important)

The queued premise was "allow-list `Read,Grep,Glob` so in-repo exploration works without CWD luck."
Live-fire falsified it: allow-listing a *tool* does not grant *out-of-workspace file paths*.
- **Probe 1** — cwd = the r2 worktree, packet asks the nested claude to Read an absolute path OUTSIDE
  that tree (a scratch file under `%TEMP%`). Result: `is_error:false`, `num_turns:2`, but
  `.result` = *"I need you to approve the read permission for that file path… pending your approval"*
  — the read was NOT granted despite `Read` being allow-listed.
- **Probe 2** — cwd = the scratch dir itself, packet asks to Read `./nonce.txt` (in-cwd). Result:
  `is_error:false`, `.result` = the exact nonce. The read works when the file is in the cwd subtree.
→ Corrected everywhere: the read tools are allow-listed (explicit read-only surface), but path access
stays scoped to the working-directory subtree. Dispatch from the artifacts' ROOT (the whole subtree is
readable — that satisfies in-repo exploration); a file outside it must be inlined, or the dir added via
`--add-dir` on a raw call. Both ds probes also exercised fix-2 (op→export key) and fix-3 (stdin prompt)
end-to-end; probe 2 exercised fix-4 (dispatch succeeded under the `deepseek-v4-pro` pin). Envelope cost
labels ~$0.24 each are Anthropic-priced; real DeepSeek cost ≈2¢/probe (~46K in / ~190 out at v4-pro
rates).

### codex trust-rule evidence (3 attempts — corrects T5's over-claim)

- **attempt 3** — cwd IS a git-repo root: all reads clean, zero denials, no escalation flags.
- **attempt 2** — non-repo cwd + `--skip-git-repo-check`: ALL reads denied + `CreateProcessWithLogonW`
  err 267 — the flag suppresses the front-door check but grants no sandbox trust.
- **attempt 1** — out-of-workspace read from a repo cwd: denied.
→ Convention: dispatch codex FROM a git-repo root containing the artifacts. Relocate loose files into a
scratch `git init`+commit repo and SAY SO in the packet — a relocated path manufactured codex's one
false-positive finding this round (the packet-fidelity rule now in SKILL.md).

**Round-2 stdin probe (fix-6, re-confirms the read):** `codex exec --json -o report - < packet` from a
fresh scratch git-repo root, tiny packet asking it to Read `seed.txt` → exit 0, `report` = the exact
file contents, ~25.4K in / 128 out (≈ a few cents at GPT-5.5 rates). Confirms stdin packet delivery and
the repo-root read together, on codex 0.142.5.

### fix-11 incident — why the shim model pin exists (cost-critical)

A parallel session dispatched the reviewer shims with NO `model:` frontmatter. Claude Code resolves a
subagent's model as: the def's frontmatter `model`, else the **conductor's** model by inheritance. On a
frontier-class conductor the unpinned shims inherited frontier pricing for every packet AND every raw
report — "a week of plan quota in minutes." It went unnoticed because the conductor here had been
passing an explicit cheap per-call override, which masked the missing pin. Fix: `model: sonnet` in each
def, plus a shim-model-rule callout in SKILL.md (dispatch section) and INSTALL.md (setup) so any ad-hoc
or new-lane dispatch pins a cheap model too.

### fix-12 incident — heredoc churn on packet materialization

A parallel session's shim dispatches churned 10+ minutes each on assembling the packet. Mechanism: the
defs (`tools: Bash, Read`, no Write) and SKILL.md told conductors/shims to handle packet TEXT ("write
to a shell variable or heredoc first"), so the sonnet shims converged on stitching packets from
multiple heredoc fragments — which repeatedly corrupted on `$`-signs, backticks, and quoting in the
packet body. Fix (conductor hotfix, carried here): all three defs gain `tools: … Write` and a
packet-as-file contract — the conductor Writes the packet to a file and hands over the PATH; the shim
NEVER reconstructs packet text through the shell. Dispatch is then pure redirection: deepseek and codex
read the file on stdin (`ds-review < pkt`, `codex exec - < pkt` — composes with fix-3's stdin work),
antigravity lifts it with `"$(cat pkt)"` (command-substitution output is not re-expanded, so `$`
survives) under a ~25KB argv-ceiling guard (antigravity has no stdin mode). This round's own probes
already used the file/stdin path (`printf … | ds-review`, `codex exec - < packet.md`) and round-tripped
clean. Note: `ds-review` deliberately keeps only the argv-or-stdin interface — no `-f <file>` flag —
since `< file` already covers the contract and keeps the wrapper minimal.
