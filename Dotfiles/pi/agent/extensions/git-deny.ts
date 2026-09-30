import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"
import { spawnSync } from "node:child_process"
import { homedir } from "node:os"
import { join } from "node:path"

// One policy for every harness: Claude Code's PreToolUse hook script, fed the same JSON shape.
const hook = join(homedir(), ".claude", "hooks", "git-deny.mjs")

export default function (pi: ExtensionAPI) {
   pi.on("tool_call", async (event, ctx) => {
      if (event.toolName !== "bash" && event.toolName !== "powershell") return undefined
      const command = event.input.command as string
      const r = spawnSync(process.execPath, [hook], {
         cwd: ctx.cwd,
         input: JSON.stringify({ tool_input: { command } }),
         encoding: "utf8",
      })
      if (r.status === 2) return { block: true, reason: r.stderr.trim() }
      if (r.status !== 0) ctx.ui.notify(`git-deny hook failed (exit ${r.status}); command not checked`, "warning")
      return undefined
   })
}
