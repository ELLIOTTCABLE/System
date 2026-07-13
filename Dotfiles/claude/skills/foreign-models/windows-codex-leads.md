# Windows Codex sandbox — failure leads & immediate fixes

Read this only when a **Codex WRITE** dispatch on **native Windows** misbehaves:
`CreateProcessWithLogonW failed: 267` (or `5`), `Access is denied`, the cwd collapses to `C:\`, or
codex "runs" but writes nothing. Does **not** apply to read-only review lanes, or to macOS / Linux /
WSL2 — the bug is native-Windows + elevated-sandbox + write only.

**Do not rabbit-hole.** The cause is known and the fix is one line. Apply the fix or pick a
path-forward below. If something here is stale and you must dig, hand this doc to a subagent and let
it debug — don't spend top-level reasoning re-deriving what's already recorded.

## Immediate fix (the 90% case)

The elevated Windows sandbox runs every model command as local users `CodexSandboxOffline` /
`CodexSandboxOnline`; they need an explicit ACL on the workspace folder. Codex auto-grants this for
most repos but **not** for worktrees under some trees (observed: the `System` dotfiles repo). Grant it
yourself before dispatching:

```sh
# Git Bash: MSYS_NO_PATHCONV=1 stops it mangling the /grant flag into a path.
MSYS_NO_PATHCONV=1 icacls "<worktree-abs-path>" \
  /grant "CodexSandboxOffline:(OI)(CI)(M)" \
  /grant "CodexSandboxOnline:(OI)(CI)(M)"
```

`(OI)(CI)(M)` = modify, inherited by all children. Idempotent — re-running is harmless. Grant the
**users**, not the `CodexSandboxUsers` group (group-grant does not work; verified). Then dispatch
codex with `-s workspace-write` and cwd = that worktree.

## Paths forward (pick one; don't loop)

1. **icacls pre-grant** (above) — proven, keeps the real sandbox. Codex stays git-blind inside a
   linked worktree (the gitdir sits outside the sandbox), so the **conductor owns git** (diff/commit).
2. **WSL2** — dispatch codex via `wsl.exe`; the Linux sandbox runs as you, no cross-user-profile ACL
   problem, and git works. Cleanest if codex is installed in WSL. (Unverified here.)
3. **`-s danger-full-access`** — no OS sandbox; runs as you, so everything (project-root cwd, git,
   under-root worktrees) works. Isolation becomes behavioral (worktree + `ai/` branch). Human ok only.

## If the immediate fix doesn't apply

- `icacls` says `No mapping between account names...` → the sandbox users don't exist, i.e. the
  elevated sandbox was never set up on this machine. Check with `codex doctor` and
  `Get-LocalUser CodexSandbox*`. Setup is an elevated one-time step (`codex-windows-sandbox-setup.exe`,
  invoked by codex, needs admin once). Or set `sandbox = "unelevated"` under `[windows]` in
  `~/.codex/config.toml`, or just take path-forward 2 or 3.
- A **read-only** dispatch fails → that's the older git-repo-root cwd rule, not this; see SKILL/INSTALL.

## What's already known (so a debugging subagent skips the probe series)

- Mechanism: `[windows] sandbox = "elevated"` → commands spawned via `CreateProcessWithLogonW` as
  `CodexSandbox{Offline,Online}` → those users need a workspace ACL.
- Proven: manual user-grant on a dir under `System` makes codex-write succeed; group-grant does not;
  read-only codex is unaffected in `System`.
- Boundary: codex auto-grants for `Sync/Code/Dorc` (its ACEs are present there) and for fresh dirs
  outside `System`; it does **not** for worktrees under `System`. **Not** a size/worktree-count issue
  (Dorc is huge — ~100 worktrees — and works). The exact reason the auto-grant skips `System` is
  unresolved and not worth chasing; the manual grant is the fix.
- Captured on codex-cli **0.144.1**, Windows 11. Version-sensitive — if codex reworked the sandbox,
  re-confirm the user names and mechanism (`codex doctor`; compare `icacls` on a working repo like
  `Sync/Code/Dorc` against a failing worktree) before trusting the above.

Keep this doc lean: if you find a cleaner fix, replace the immediate-fix block — don't append a log.
