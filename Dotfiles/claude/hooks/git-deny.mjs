#!/usr/bin/env node
// PreToolUse hook: block mutative git ops reserved for the user.
//
// settings.json prefilters with `if: "Bash(*git*)"` so $-free commands
// without "git" substring skip the spawn entirely. $-containing commands
// false-positive that matcher (upstream bug anthropics/claude-code#48722)
// and fall through here for proper JSON-aware extraction + pattern matching.
// Mirrors the PowerShell-side dispatcher in settings.json for parity.
//
// Upstream bug:
//    <https://github.com/anthropics/claude-code/issues/48722> "PreToolUse 'if: Bash(foo*)' falsely matches Bash commands containing $()"
//
// 2026-07-19 relaxation (user-directed): in AUTONOMOUS MODE (ai/* branch, a
// worktree-* branch under .claude/worktrees/, or a .claude-commit sentinel),
// branch-scoped reflog-recoverable surgery (rebase, merge, reset --hard, safe
// branch-delete) is permitted — the user reviews-and-rebases AI branches anyway.
// Irrecoverable or repo-global ops stay blocked everywhere: push (global law),
// stash drop/clear (the stash stack is SHARED across worktrees and sessions),
// clean -f (untracked files have no reflog), filter-branch/filter-repo,
// update-ref, tag deletion, and branch -D (force-delete kills the reflog).


import { readFileSync, existsSync } from "node:fs"
import { execSync } from "node:child_process"

const input = JSON.parse(readFileSync(0, "utf8"))
const cmd = input?.tool_input?.command ?? ""

const deny = (reason) => {
   process.stderr.write(`Blocked: ${reason}\n`)
   process.exit(2)
}

const sh = (args) => {
   try {
      return execSync(`git ${args}`, {
         encoding: "utf8",
         stdio: ["ignore", "pipe", "ignore"],
      }).trim()
   } catch {
      return ""
   }
}

const isAutonomous = () => {
   const root = sh("rev-parse --show-toplevel")
   const branch = sh("branch --show-current")
   if (root && existsSync(`${root}/.claude-commit`)) return true
   if (/^ai\//.test(branch)) return true
   // Claude worktrees are autonomous like ai/*, but require BOTH the dedicated
   // `worktree-*` branch AND a `.claude/worktrees/` path — neither signal alone suffices.
   if (/^worktree-/.test(branch) && root.includes("/.claude/worktrees/")) return true
   return false
}

const alwaysDeny = [
   [
      /\bgit\s+push\b/,
      "git push reserved for the user; remote state is not Claude-managed.",
   ],
   [
      /\bgit\s+stash\s+drop\b/,
      "git stash drop loses stashed work (the stash stack is shared across worktrees). Reserved for the user.",
   ],
   [
      /\bgit\s+stash\s+clear\b/,
      "git stash clear loses all stashed work (the stash stack is shared across worktrees). Reserved for the user.",
   ],
   [
      /\bgit\s+clean\s+-[a-zA-Z]*f/,
      "git clean -f discards untracked files (no reflog can recover them). Reserved for the user.",
   ],
   [
      /\bgit\s+branch\s+-D\b/,
      "git branch -D force-deletes branches and their reflogs. Reserved for the user.",
   ],
   [/\bgit\s+tag\s+-d\b/, "git tag -d reserved for the user (tags are repo-global)."],
   [
      /\bgit\s+tag\s+--delete\b/,
      "git tag --delete reserved for the user (tags are repo-global).",
   ],
   [
      /\bgit\s+filter-branch\b/,
      "git filter-branch rewrites repo-wide history. Reserved for the user.",
   ],
   [
      /\bgit\s+filter-repo\b/,
      "git filter-repo rewrites repo-wide history. Reserved for the user.",
   ],
   [/\bgit\s+update-ref\b/, "git update-ref is raw ref surgery. Reserved for the user."],
]

const interactiveOnlyDeny = [
   [
      /\bgit\s+rebase\b/,
      "git rebase reserved for the user outside autonomous mode (ai/* branch, worktree, or .claude-commit sentinel).",
   ],
   [/\bgit\s+merge\b/, "git merge reserved for the user outside autonomous mode."],
   [
      /\bgit\s+reset\s+--hard\b/,
      "git reset --hard discards working state. Reserved for the user outside autonomous mode.",
   ],
   [
      /\bgit\s+branch\s+(-d|--delete)\b/,
      "git branch deletion reserved for the user outside autonomous mode.",
   ],
]

for (const [pattern, reason] of alwaysDeny) {
   if (pattern.test(cmd)) deny(reason)
}

const touchesInteractiveOnly = interactiveOnlyDeny.some(([pattern]) => pattern.test(cmd))
const needsCommitGate = /\bgit\s+commit\b/.test(cmd)

if ((touchesInteractiveOnly || needsCommitGate) && !isAutonomous()) {
   for (const [pattern, reason] of interactiveOnlyDeny) {
      if (pattern.test(cmd)) deny(reason)
   }
   if (needsCommitGate) {
      const branch = sh("branch --show-current")
      deny(
         `git commit on '${branch}' (autonomous mode requires an ai/* branch, a worktree-* branch under .claude/worktrees/, or a .claude-commit sentinel). Produce the message and let the user run the commit.`,
      )
   }
}

process.exit(0)
