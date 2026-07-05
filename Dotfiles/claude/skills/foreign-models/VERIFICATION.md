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
  `powershell.exe -Command "Get-Content -Raw probe.txt"` → `exit_code 0`, **no sandbox-decline**. So the
  read-only-sandbox read-decline bug does NOT affect 0.142.5; the `-c sandbox_permissions` workaround is
  not needed on this build.
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

- RESOLVED (was a -GUESS): codex 0.142.5's native-Windows read-only sandbox **reads files fine** — T5
  ran a real read under `sandbox_policy:read-only`, no decline. The read-decline bug does not reproduce.
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
