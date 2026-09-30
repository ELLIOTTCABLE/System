# Why pi offers only `max` thinking for `opencode-go/kimi-k3`

Investigated 2026-09-24. Read-only; no config changed.

## Causal chain

1. models.dev `providers/opencode-go/models/kimi-k3.toml` declares
   `[[reasoning_options]] type="effort" values=["max"]`. Written 2026-07-16
   (launch day, when Moonshot's own docs said "K3 currently supports max only;
   low and high will be supported later"). A `toggle` option was removed the
   next morning. Never updated since; last touch 2026-07-31 was unrelated.
   Same staleness on `providers/opencode/models/kimi-k3.toml` (Zen, non-Go).
2. models.dev `providers/moonshotai/models/kimi-k3.toml` *was* updated on
   2026-07-17 (commit f6ac2f0, "add Kimi K3 low/high effort options"). So the
   direct-Moonshot entry has `[low, high, max]`; the OpenCode Go entry does not.
3. pi's generator (`earendil-works/pi` `packages/ai/scripts/generate-models.ts`
   → `models-dev-reasoning-options.ts`, `getEffortThinkingLevelMap`) treats
   models.dev effort values as verified truth: every pi level not in the list
   becomes `null`, and `off` becomes `null` unless `"none"` is listed. Result
   for opencode-go/kimi-k3:
   `{off:null, minimal:null, low:null, medium:null, high:null, xhigh:null, max:"max"}`.
4. pi 0.84.3 bundles *no* `opencode-go` models. The whole provider comes from
   `https://pi.dev/api/models/providers/opencode-go`, fetched every 4h with
   ETag, cached in `~/.pi/agent/models-store.json`. Live catalogue on
   2026-09-24 has the same ETag as the local cache; upstream still ships the
   max-only map.
5. pi-ai `getSupportedThinkingLevels` (`models.js`) drops any level mapped to
   `null`, and requires an explicit mapping for `xhigh`/`max`. → `["max"]`.
   `pi-effort` extension just wraps that function; not the cause.

## Ground truth on the API

- Moonshot platform docs (platform.kimi.ai, use-thinking-models): K3
  `reasoning_effort` accepts `low` / `high` / `max`, default `max`; thinking
  cannot be disabled via `thinking.type`.
- Kimi Code docs (kimi.com/code/docs models page): K3 default is `high` there;
  `none` maps to thinking-disabled by routing to K2.8 Preview.
- Whether OpenCode Go's Zen gateway forwards `reasoning_effort: low|high` to
  Moonshot is UNVERIFIED. No first-party statement found. OpenCode issue
  #38429 asked for exactly this and was auto-closed stale (2026-09-23).

## Local fix candidate (not applied)

`~/.pi/agent/models.json` → `providers.opencode-go.modelOverrides.kimi-k3.thinkingLevelMap = {low:"low", high:"high"}`.
Overrides merge over the remote overlay (`provider-composer.js` `getModels`,
`applyModelOverride` spreads override map over model map), so string values
beat the catalogue's nulls. pi would then send `reasoning_effort: "low"` via
the generic openai-completions branch. Needs an end-to-end probe first.

## Upstream fix candidates

- models.dev PR: `providers/opencode-go/models/kimi-k3.toml` (and `opencode/`)
  `values = ["low", "high", "max"]` — only if Zen is confirmed to forward it.
- pi.dev catalogue regenerates from models.dev automatically; no pi change needed.

## Status 2026-09-24

- Correction: pi 0.84.3 *does* bundle opencode-go data
  (`pi-ai/dist/providers/data/opencode-go.json`, keyed by API type, not in
  `models.js`). Same max-only map; the remote overlay replaces it by id.
- Local override applied to `Dotfiles/pi/agent/models.json`
  (`opencode-go.modelOverrides.kimi-k3.thinkingLevelMap = {low, high}`).
  Picked up in the live pi session on Windows. Whether Zen honours
  `reasoning_effort: low` end-to-end is being tested interactively.
- Direct probe of `https://opencode.ai/zen/go/v1/chat/completions` from a
  script returns 400 `MissingSessionID` without an `x-opencode-session`
  header; pi sets one via `sessionAffinityFormat`. Keep that in mind for any
  future out-of-pi probe.
