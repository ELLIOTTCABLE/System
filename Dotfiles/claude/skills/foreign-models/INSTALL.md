# foreign-models — dispatch outside-lineage reviewers from Claude Code

Lets the conductor spawn non-Anthropic models (OpenAI Codex/GPT-5.5, Google Antigravity/Gemini
lineage, DeepSeek V4-Pro) as read-only review subagents for adversarial cross-lineage review. The
conductor captures each raw report to scratch and adjudicates it; foreign output is never shown to
the human verbatim. Behaviour lives in the `foreign-models` skill; this file is install/setup only.

## Per-machine setup (one time, human-run)

1. Install codex. On a mise-managed machine use the **npm** backend — the default aqua backend ships
   codex as an undecompressed `.zst` on Windows (registered but no runnable binary, no shim):
   ```sh
   mise use -g npm:@openai/codex      # or, without mise:  npm install -g @openai/codex
   ```
2. Authenticate codex — `codex login`. Two lanes share this saved login:
   - **Saved-login lane (default, used by the agents):** `codex login` with an API-key sign-in persists
     the key to `~/.codex/auth.json`; `codex exec` then bills **per-token** on that funded OpenAI **API**
     account. This is the lane in use here (a small funded throwaway account). An unfunded account
     returns `Quota exceeded`.
   - **op-key lane (alternate, `bin/codex-review`):** reads the same key from 1Password per-run and
     injects it via `CODEX_API_KEY`, keeping it off disk — for CI / env-explicit contexts.
   - **ChatGPT-plan lane:** if you ever `codex login` with a ChatGPT subscription instead, usage draws
     on plan quota rather than per-token. Available, unused here.
3. Install antigravity (the gemini-cli successor) and authenticate — one-time interactive Google OAuth:
   ```sh
   mise use -g antigravity-cli        # binaries: antigravity / agy (1.0.16 verified)
   antigravity                        # choose "1. Google OAuth"; personal account = free tier
   ```
   Auth is cached in the system keyring; free tier ≈20 agent req/day. Print mode (`-p`) is what the
   dispatch uses — see the platform matrix for its packet-only constraint.
4. DeepSeek uses no CLI — it runs through the already-installed Claude Code via `bin/ds-review`, which
   resolves `DEEPSEEK_API_KEY` from the shell env if set, else reads it from 1Password at runtime (a
   small funded account). Get a key at platform.deepseek.com if provisioning a new machine.
5. Create the isolated foreign-Claude profile — it stays empty on purpose (that emptiness is what
   keeps your personal skills/MCP/settings out of the DeepSeek-backed nested instance):
   ```sh
   mkdir -p ~/.config/foreign-claude
   ```

> **Status note — Gemini lane (2026):** Google discontinued the individual gemini-cli OAuth lane
> server-side on 2026-06-18 (the `IneligibleTierError`/"This client is no longer supported… migrate to
> the Antigravity suite"). Successor is **antigravity-cli** (installed above). Its `-p`/`--print` mode
> emits PLAIN TEXT (no `--json`), and headless print mode cannot run tools (see matrix), so the
> antigravity-reviewer takes stdout as the raw answer and sends only self-contained packets. A paid
> `GEMINI_API_KEY` (AI Studio) lane to real Gemini 3.x Pro still works (API-key auth was explicitly
> *unaffected* by the sunset) — see the optional lane below.

## Where the artifacts go (live-install destinations)

| Artifact | Destination |
|---|---|
| `skills/foreign-models/` | `~/.claude/skills/foreign-models/` |
| `agents/*.md` | `~/.claude/agents/` |
| `bin/ds-review` | `~/.claude/bin/ds-review` (`chmod +x`; agents call it by absolute `$HOME/.claude/bin/` path) |
| `bin/codex-review` | `~/.claude/bin/codex-review` (`chmod +x`; needs `op` + `codex`) |
| `bin/foreign-mcp.json` | `~/.claude/bin/foreign-mcp.json` (kagi-only MCP config ds-review passes to the nested Claude) |

The agent defs reference the wrappers by absolute `$HOME/.claude/bin/<wrapper>` path, so no PATH or
shell-rc changes are needed.

### `bin/codex-review` (op-key alternate lane)

`codex-review "<prompt>"` (or a packet piped on stdin) reads the OpenAI key inline from 1Password
(`op read`), runs `codex exec --json`, and writes ONLY the clean final message to a report file. The
JSONL event stream (token usage, errors) goes to stdout; the report path is announced on stderr. Set
`CODEX_REPORT=/path` to control where the clean message lands (default: an `mktemp` file whose path is
printed). The key is never written to disk or echoed.

## MCP parity — read-only web search on every lane

Every foreign lane carries the **kagi-ken** MCP server (Kagi search + summarizer, read-only). Rule:
**only read-only MCP servers** on foreign lanes. The design keeps secrets out of dotfiles:

- **One canonical token file.** kagi-ken-mcp reads its Kagi session token from `KAGI_SESSION_TOKEN`
  else `~/.kagi_session_token`. The token lives ONLY in `~/.kagi_session_token` (per-machine
  provisioning: paste the token from kagi.com → Settings → Session Link into `~/.kagi_session_token`).
  Every lane inherits it from there.
- **Every MCP entry is secret-free** — command + args only, no embedded token:
  - **Codex:** `~/.codex/config.toml` → `[mcp_servers.kagi-ken]` with `default_tools_approval_mode =
    "approve"` (a read-only allow-list; not sandbox escalation). *Verified headless.*
  - **DeepSeek:** `~/.claude/bin/foreign-mcp.json` (kagi-only); ds-review passes `--mcp-config` +
    `--strict-mcp-config` + `--allowedTools` for the two kagi tools. *Verified headless.*
  - **Antigravity:** `~/.gemini/config/mcp_config.json`. Works in the interactive CLI; headless print
    mode does NOT reliably invoke it (print harness gap — the model flails instead of calling the
    tool), so the antigravity reviewer is treated as search-less.

To add another read-only server later, replicate the same secret-free entry into all three lanes.
(The user's own Claude Code kagi-ken entry is already secret-free — same token file — so no change is
needed there; whether to simplify anything else in personal dotfiles is the human's call.)

## Platform matrix

| Platform | Status |
|---|---|
| macOS | OK |
| WSL2 | OK — but antigravity's keyring may not persist (reauth loop reported); native Windows Credential Manager persists. |
| native Windows | (a) `codex exec` read-only sandbox **reads files fine** on codex 0.142.5 (verified 2026-07-05 — the old read-decline bug does not reproduce; no `-c sandbox_permissions` workaround needed). (b) `ds-review`/`codex-review` and the sh wrappers need Git Bash — not cmd/PowerShell. (c) install codex via mise's **npm** backend, not aqua. (d) antigravity `-p` prints plain text and can't run tools headlessly — send self-contained packets only. |

## Cost & quota

- **Codex / GPT-5.5** — saved-login lane bills **per-token** on the funded OpenAI **API** account (no
  ChatGPT plan here). A trivial file-read turn ran ~25K input / ~120 output tokens (≈ a few cents at
  GPT-5-class rates). `Quota exceeded` = the account needs credit.
- **Antigravity (free tier)** — ≈20 agent req/day on a ~5h refresh, cut from ~250/day at launch and
  "not guaranteed" by Google. Default model is Gemini Flash-tier.
- **DeepSeek V4-Pro** — pay-as-you-go, ~cents per review (V4-Pro $0.435 in / $0.87 out per MTok, cache
  hits far cheaper). Note: Claude Code's `total_cost_usd` in the ds-review envelope is Anthropic-priced
  and does NOT reflect the real (far lower) DeepSeek bill.

## Optional lane — real Gemini 3.x Pro via `GEMINI_API_KEY`

gemini-cli still accepts a paid AI-Studio `GEMINI_API_KEY` after the 2026-06-18 consumer-OAuth sunset:
Google's own notice says API-key auth "remain[s] completely unaffected" (only the free OAuth tier
died). It bills per-token and needs a **restricted / new-style "auth" key** — unrestricted `AIza`
standard keys are rejected as of 2026-06-19, and all standard keys sunset ~2026-09. Not installed here
(no key). To add: `mise use -g npm:@google/gemini-cli`, set `GEMINI_API_KEY`, and add a
`gemini-reviewer` shim (headless `gemini -p "$PACKET" --output-format json`, report is `.response`).
This is the lane to Gemini-Pro rigor above antigravity's free Flash.
