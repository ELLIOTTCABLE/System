---
name: foreign-models
description: >-
   Dispatch a foreign (non-Anthropic) model — OpenAI Codex/GPT-5.5, Google Antigravity (Gemini
   lineage), or DeepSeek V4-Pro — as a read-only subagent to get an outside-lineage second opinion on
   a plan, design, argument, or diff. Use when you (the conductor) want cross-model / cross-lineage
   adversarial review, a "foreign subagent", a genuinely independent red-team from a different model
   family, or a correlated-blind-spot check that same-lineage Claude subagents cannot give. Also the
   dispatch layer the adversarial-crosscheck skill's optional foreign lane routes through. The
   conductor consumes the raw foreign output and adjudicates it; it is never shown to the human verbatim.
---

# foreign-models

Spawn a model from another lineage to review something, capture its raw report to scratch, and
adjudicate it yourself. The point is decorrelation: a GPT/Gemini/DeepSeek reviewer fails in
different places than a Claude reviewer, so it catches faults your own lineage is blind to. That
only holds if you keep its output at arm's length — see the purity protocol below.

Prerequisite: per-machine setup is done (`INSTALL.md`). If a binary is missing, its dispatch fails
loudly; do not attempt to install anything.

## The three dispatches (verbatim, with why each flag)

**Packet-as-file contract (churn-critical).** Write the packet to a FILE in `$SCRATCH` yourself —
with your Write tool, never via shell heredocs/echo (shell expansion corrupts `$`, backticks, and
quoting in packet text; piecing packets together from heredoc fragments has burned 10+ minutes per
dispatch). Hand the shims the file PATH, not inline text. Keep `$SCRATCH` pointed at this session's
scratchpad dir. Prefer the matching subagent (`codex-reviewer`, `antigravity-reviewer`,
`deepseek-reviewer`) so the shim handles capture and failure notes.

**Shim model rule (cost-critical).** The reviewer subagents are pure relays — they must run on a
CHEAP model, never yours. The agent defs pin `model: sonnet`; keep that pin. If you ever dispatch
ad-hoc (a raw Agent call, your own wrapper def), pass an explicit cheap `model` yourself: an unpinned
subagent silently inherits the CONDUCTOR'S model, and on a frontier-class conductor that multiplies
every packet and raw report by frontier pricing — this exact omission once burned a week of plan
quota in minutes.

The raw calls are:

**Codex / GPT-5.5**
```sh
cd <git-repo-root-containing-artifacts> && codex exec --json -o "$SCRATCH/codex-report.md" - < "$PACKET_FILE"
```
- `exec` — non-interactive; no TUI. Uses the saved `codex login` (per-token on a funded OpenAI API
  account by default here — see INSTALL.md's two-lane note).
- CWD RULE (native Windows, verified): the read-only sandbox trusts only a cwd that is ITSELF a
  git-repo root — from there reads work; from a non-repo dir ALL reads are denied even with
  `--skip-git-repo-check` (it suppresses the check, it does not grant trust). Loose artifacts: copy
  into a scratch `git init`+commit repo and say so in the packet.
- STDIN RULE: pass the packet via `- <` stdin, never argv — multi-line argv dies at the mise batch
  shim on Windows before codex launches.
- `--json` — JSONL event stream on stdout (audit/progress for you).
- `-o <file>` — clean final message to the file (also still printed); read the file, not the stream.
- Read-only sandbox is the DEFAULT — do not pass `--sandbox`/`--full-auto`/`--dangerously-*`.
- Threaded follow-up: `codex exec resume --last "$FOLLOWUP"`.

**Antigravity (Gemini lineage)**
```sh
antigravity -p "$PACKET" --print-timeout 300s </dev/null > "$SCRATCH/antigravity-report.txt"
```
- `-p` — print mode: single-shot, PLAIN TEXT on stdout (no JSON mode exists). The file IS the report.
- `--print-timeout 300s` — value is a Go duration and MUST carry a unit (`300s`/`5m`); a bare integer
  is a usage error.
- No `--dangerously-skip-permissions`. Print mode cannot approve tool prompts, so it CANNOT read
  files, explore a repo, or reliably call MCP tools — a tool-driving packet hangs to the timeout.
  The packet MUST be self-contained: inline the artifact, no file references, no "go search".
- Free tier defaults to Gemini Flash; `--model "Gemini 3.1 Pro (High)"` is accepted (may downgrade).

**DeepSeek V4-Pro**
```sh
ds-review < "$PACKET_FILE" > "$SCRATCH/deepseek-report.json"
```
- Packet on STDIN from the file (the packet-as-file contract; the wrapper reads argv-or-stdin, and
  stdin has no ARG_MAX ceiling and never re-expands `$` in the packet). The wrapper runs a nested
  Claude Code against DeepSeek's Anthropic endpoint, model pinned to `deepseek-v4-pro` (DeepSeek maps
  claude-sonnet/haiku* and any unknown name to the weaker v4-flash, so the pin is load-bearing), an
  isolated bare profile, and an explicit read-only toolset (`Read,Grep,Glob` + the two kagi tools;
  mutating/egress/escalation tools denied by name). Reads are scoped to the working-dir subtree —
  allow-listing the tools does NOT grant out-of-workspace paths (verified this round) — so cd to the
  artifacts' ROOT. The report is `.result` in the JSON envelope.

## Purity protocol (the one rule that makes this worth doing)

1. Every raw foreign report lands in a scratch file (above). Read it back to adjudicate.
2. NEVER quote raw foreign output wholesale to the human, and never paste it into a durable doc
   as-is. You are the anchor point: foreign text informs *your* assessment, it does not become the
   assessment. (Same reason the crosscheck skill hands passes to the *user* to reconcile — an
   un-adjudicated hostile pass manufactures plausible faults as readily as a flatterer invents
   praise.)
3. Label provenance on anything that survives into your adjudicated result: model + lineage, e.g.
   "(flagged by DeepSeek V4-Pro, foreign lineage; I judge this real)" or "(Codex raised this; likely
   over-flagged — see below)". The human must always be able to tell foreign-sourced claims from
   your own.
4. Spend adjudication effort on the UNVERIFIED bucket first. If you required a grounding ledger (see
   "Constructing the packet"), the reviewer's self-declared unverified claims are where wrong findings
   concentrate — validated twice in live-fire (both DeepSeek's misses, and antigravity's ungrounded
   "sure" false-positives, sat there). VERIFIED claims it actually checked are cheaper to accept.

## Dispatch in background and in parallel

These are slow, network-bound, independent calls. Run them concurrently across lineages — dispatch
the subagents in the background (or the raw calls with `&` and `wait`) rather than serially. A
three-lineage review should cost about one call's wall-time, not three. Collect all reports, then
adjudicate together.

## Constructing the packet

- **Disowned, third-person adversarial framing.** "A colleague I distrust produced the following;
  find where it breaks down." Attribute the artifact to a distrusted third party and strip its
  first-person optimism — the reviewer must not absorb the author's confidence.
- **Self-contained by default.** Inline the artifact text in the packet. DeepSeek reads files in its
  working-dir subtree (cd to the artifacts root); Codex reads only from a git-repo-root cwd;
  antigravity (headless) reads nothing — so for a portable packet, never rely on file references. If
  you want a reviewer to web-search, say so explicitly (Kagi is available — see MCP parity), but only
  Codex and DeepSeek can act on it headlessly.
- **Report everything, with grades.** Instruct the reviewer to surface every concern with a
  per-finding **confidence** (how sure it is) and **severity** (how much it matters), and to state
  plainly where a criticism does NOT hold. When uncertain, default toward refutation — an
  unsupported "this is fine" is worse for you than an over-cautious flag you can dismiss.
- **Require a grounding ledger.** Tell the reviewer to split its findings into VERIFIED (checked
  against the artifact or a source it actually read) vs UNVERIFIED (asserted from priors), and to mark
  which per finding. This is the single best triage signal you get — wrong findings cluster in the
  unverified bucket (spend your scrutiny there, purity protocol #4).
- **Review artifacts in situ.** Point the reviewer at the files where they actually live; do not copy
  them elsewhere first. A relocated path manufactures false positives (a codex "wrong config path"
  finding was purely an artifact of reviewing a moved copy). If relocation is unavoidable — e.g. codex
  needs a git-repo root — say so explicitly in the packet.
- Bracket hard constraints verbatim (versions, APIs, paths, acceptance criteria); inverting a spec
  breaks the task rather than surfacing bias.

## MCP parity (read-only web search on every lane)

Every foreign lane carries the **kagi-ken** MCP server (Kagi web search + summarizer, read-only), so
a reviewer can check a claim against current sources. Rule: **only read-only MCP servers** on foreign
lanes — never expose a mutating tool to an un-adjudicated foreign model. Configuration is per-machine
(INSTALL.md); the shared Kagi credential lives in one canonical file, and every lane's MCP entry is
secret-free (command+args only).

- **Codex** — kagi-ken in `~/.codex/config.toml` with `default_tools_approval_mode = "approve"` (a
  read-only allow-list, not sandbox escalation). Works headless: verified `kagi_search_fetch`.
- **DeepSeek** — `ds-review` passes `--mcp-config`/`--strict-mcp-config` + `--allowedTools` for the
  two kagi tools. Works headless: verified.
- **Antigravity** — kagi-ken configured and works in the interactive CLI, but headless print mode
  does NOT reliably invoke it (the print harness gates/omits tool calls). Do NOT ask an antigravity
  packet to search; treat that lane as search-less.

To add another read-only server later, replicate the same secret-free entry into all three lanes.

## Calibration (weight findings by known model character)

- **Precision ranking (live-fire, n=1 each — indicative, not settled): Codex/GPT-5.5 > DeepSeek/V4-Pro
  > Antigravity/Flash.** Tracks cost (~$1+ ≫ ~cents ≫ $0) and social priors. Codex twice refused to
  fabricate — reported it couldn't read the artifact rather than inventing findings (a reviewer virtue).
  Weight a lone antigravity flag lightest, a lone codex flag heaviest — but still verify (codex's one
  live-fire miss was context-induced, not random).
- **Codex / GPT-5.5** — over-flags severity; treat its "critical"s as "worth checking", not settled.
- **Antigravity (free tier = Gemini Flash)** — strongest at big-picture / plan / architecture
  critique; weakest as an implementer. It runs Flash-tier by default, so weight it BELOW Codex/GPT-5.5
  on rigor — a cheap breadth angle, not a peer reviewer. Aim it at design soundness, not line-level
  code. (An optional per-token `GEMINI_API_KEY` lane reaches real Gemini 3.x Pro — see below.)
- **DeepSeek V4-Pro** — near-frontier, not peer-frontier; a useful cheap third angle, not a Claude
  substitute.
- **Agreement across models is weak evidence.** Lineages share correlated blind spots (shared
  training data, shared benchmark-chasing). Convergence is a mild signal, not proof; a fault all
  three miss can still be real — and in live-fire, antigravity missed a real read-only-posture gap
  that both codex and deepseek caught, so even three-way overlap on adjacent concerns proved nothing.
  Do not let unanimity end your own scrutiny.

## Failure modes

- **Auth expiry** — Codex: re-run `codex login`. Antigravity: re-run `antigravity` once interactively
  (Google OAuth). DeepSeek: check the key / balance at platform.deepseek.com (or the 1Password lane).
- **Antigravity free-tier daily quota** — ≈20 agent req/day (undocumented, ~5h refresh); a quota
  message. Wait for reset or fall back to another lineage.
- **Codex per-token quota** — the funded OpenAI API account is drained per-token; a `Quota exceeded`
  event means it needs credit (billing, human-gated). Not a rate window.
- **DeepSeek op-read auth timeout** — if `ds-review` uses the 1Password lane and the desktop app's
  re-auth prompt is missed, `op read` returns empty and the nested Claude reports "Not logged in"
  (surfaced as `is_error`). Re-run and answer the prompt, or export `DEEPSEEK_API_KEY` to skip op.
- **Native-Windows Codex sandbox scoping** — reads are trusted only from a git-repo-root cwd (see
  CWD RULE above); denials from a non-repo or out-of-workspace context are expected behavior, not a
  bug. Last-resort read-scope widening (never broader escalation):
  `-c 'sandbox_permissions=["disk-full-read-access"]'`.

## Fallbacks

- **No harness needed** — for a self-contained artifact you can skip the CLI entirely and send a plain
  API packet to any of these providers, then read the response back into your adjudication. Use this
  when the reviewer needs no file access, only the pasted artifact.
- **Optional Gemini-Pro lane** — gemini-cli still accepts a paid `GEMINI_API_KEY` (AI Studio) after
  Google's June 2026 consumer-OAuth sunset — API-key auth was explicitly unaffected (only the free
  OAuth tier died). It bills per-token and needs a restricted / new-style "auth" key (unrestricted
  `AIza` keys are rejected as of 2026-06-19). Not installed here (no key); add `@google/gemini-cli` +
  `GEMINI_API_KEY` if you want real Gemini 3.x Pro quality above antigravity's free Flash.
