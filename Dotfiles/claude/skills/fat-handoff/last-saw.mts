// Whether files a successor already read have changed in git since; see ledger.md § 8.
import { execFileSync } from "node:child_process"
import { existsSync, realpathSync } from "node:fs"
import { dirname, join, relative, sep } from "node:path"

const TIME = /^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?)?\s*(Z|[+-]\d{2}:?\d{2})?$/i

// strict on purpose: git's approxidate reads garbage as now, the unsafe direction
export function parseTime(text: string): number | undefined {
   const match = TIME.exec(text.trim())
   if (!match) return undefined
   const [, year, month, day, hour = "00", minute = "00", second = "00", zone] = match
   const iso = `${year}-${month}-${day}T${hour}:${minute}:${second}`
   // Date rolls 2026-02-31 over into March rather than refusing it
   const asUtc = Date.parse(`${iso}Z`)
   if (Number.isNaN(asUtc) || new Date(asUtc).toISOString().slice(0, 19) !== iso) return undefined
   if (zone === undefined) return Date.parse(iso)
   return Date.parse(zone.toUpperCase() === "Z" ? `${iso}Z` : `${iso}${zone.slice(0, 3)}:${zone.slice(-2)}`)
}

function git(top: string, args: string[]): string | undefined {
   try {
      const options = { encoding: "utf8" as const, timeout: 30_000, stdio: "pipe" as const }
      return execFileSync("git", ["-C", top, "--literal-pathspecs", ...args], options)
   } catch {
      return undefined
   }
}

function repoOf(file: string): string | undefined {
   for (let dir = dirname(file); ; dir = dirname(dir)) {
      if (existsSync(join(dir, ".git"))) return dir
      if (dirname(dir) === dir) return undefined
   }
}

// a commit if it names one in any of the files' repos, else a time: each repo's last commit by then
export function unchangedSince(lastSaw: string, files: string[], warnings: string[]): Set<string> {
   const repos = new Map<string, Map<string, string[]>>() // top -> repo-relative path -> files as given
   for (const file of new Set(files)) {
      let real: string
      try {
         real = realpathSync.native(file)
      } catch {
         continue
      }
      const top = repoOf(real)
      if (!top) continue
      const path = relative(top, real).split(sep).join("/")
      const paths = repos.get(top) ?? repos.set(top, new Map()).get(top)!
      paths.set(path, [...(paths.get(path) ?? []), file])
   }

   const firstLine = (output: string | undefined) => output?.trim().split("\n")[0] || undefined
   const anchors = new Map<string, string | undefined>()
   if (!lastSaw.startsWith("-"))
      for (const top of repos.keys()) anchors.set(top, firstLine(git(top, ["rev-parse", "--verify", "--quiet", `${lastSaw}^{commit}`])))
   if (![...anchors.values()].some(Boolean)) {
      const time = parseTime(lastSaw)
      for (const top of repos.keys())
         anchors.set(top, time === undefined ? undefined : firstLine(git(top, ["rev-list", "-1", `--before=@${Math.floor(time / 1000)}`, "HEAD"])))
   }
   if (![...anchors.values()].some(Boolean)) {
      warnings.push(`--last-saw ${lastSaw} names no commit or time in the batch's repos; nothing is marked unchanged`)
      return new Set()
   }

   const unchanged = new Set<string>()
   for (const [top, paths] of repos) {
      const anchor = anchors.get(top)
      if (!anchor) continue
      const listed = (output: string | undefined) => output?.split("\0").filter(Boolean)
      const tracked = listed(git(top, ["ls-files", "-z", "--", ...paths.keys()]))
      if (!tracked?.length) continue
      // vs the working tree, so uncommitted edits count; git's own filters handle line endings
      const changed = listed(git(top, ["diff", "--name-only", "-z", anchor, "--", ...tracked]))
      if (!changed) continue
      for (const path of tracked) if (!changed.includes(path)) for (const file of paths.get(path) ?? []) unchanged.add(file)
   }
   return unchanged
}
