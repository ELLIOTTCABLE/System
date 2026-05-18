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

import { readFileSync, existsSync } from "node:fs"
import { execSync } from "node:child_process"

const input = JSON.parse(readFileSync(0, "utf8"))
const cmd = input?.tool_input?.command ?? ""

const deny = (reason) => {
   process.stderr.write(`Blocked: ${reason}\n`)
   process.exit(2)
}

const denials = [
   [
      /\bgit\s+push\b/,
      "git push reserved for the user; remote state is not Claude-managed.",
   ],
   [
      /\bgit\s+rebase\b/,
      "git rebase reserved for the user. The user does the review-and-rebase pass on AI commits.",
   ],
   [/\bgit\s+merge\b/, "git merge reserved for the user."],
   [
      /\bgit\s+reset\s+--hard\b/,
      "git reset --hard discards working state. Reserved for the user.",
   ],
   [
      /\bgit\s+clean\s+-[a-zA-Z]*f/,
      "git clean -f discards untracked files. Reserved for the user.",
   ],
   [
      /\bgit\s+branch\s+-D\b/,
      "git branch -D force-deletes branches. Reserved for the user.",
   ],
   [/\bgit\s+branch\s+-d\b/, "git branch -d deletes branches. Reserved for the user."],
   [/\bgit\s+branch\s+--delete\b/, "git branch --delete reserved for the user."],
   [
      /\bgit\s+stash\s+drop\b/,
      "git stash drop loses stashed work. Reserved for the user.",
   ],
   [
      /\bgit\s+stash\s+clear\b/,
      "git stash clear loses all stashed work. Reserved for the user.",
   ],
   [/\bgit\s+tag\s+-d\b/, "git tag -d reserved for the user."],
   [/\bgit\s+tag\s+--delete\b/, "git tag --delete reserved for the user."],
   [
      /\bgit\s+filter-branch\b/,
      "git filter-branch rewrites history. Reserved for the user.",
   ],
   [/\bgit\s+filter-repo\b/, "git filter-repo rewrites history. Reserved for the user."],
   [/\bgit\s+update-ref\b/, "git update-ref reserved for the user."],
]

for (const [pattern, reason] of denials) {
   if (pattern.test(cmd)) deny(reason)
}

if (/\bgit\s+commit\b/.test(cmd)) {
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
   const root = sh("rev-parse --show-toplevel")
   const branch = sh("branch --show-current")
   if (root && existsSync(`${root}/.claude-commit`)) process.exit(0)
   if (/^ai\//.test(branch)) process.exit(0)
   deny(
      `git commit on '${branch}' (autonomous mode requires an ai/* branch or .claude-commit sentinel at the repo root). Produce the message and let the user run the commit.`,
   )
}

process.exit(0)
