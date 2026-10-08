// Whether files a successor already read have changed in git since; see ledger.md § 8.
import { execFileSync } from "node:child_process"
import { existsSync, realpathSync } from "node:fs"
import { dirname, join, relative, sep } from "node:path"

const ISO_TIME = /^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?)?\s*(Z|[+-]\d{2}:?\d{2})?$/i
const WEEKDAYS = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
const MONTHS = ["january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december"]
const UNIT_MS: Record<string, number> = { h: 3_600_000, m: 60_000, s: 1_000 }

// strict on purpose: git's approxidate reads garbage as now, the unsafe direction
export function parseTime(text: string, now = new Date()): number | undefined {
   return parseIsoTime(text) ?? parseStamp(text, now)
}

function parseIsoTime(text: string): number | undefined {
   const match = ISO_TIME.exec(text.trim())
   if (!match) return undefined
   const [, year, month, day, hour = "00", minute = "00", second = "00", zone] = match
   const iso = `${year}-${month}-${day}T${hour}:${minute}:${second}`
   // Date rolls 2026-02-31 over into March rather than refusing it
   const asUtc = Date.parse(`${iso}Z`)
   if (Number.isNaN(asUtc) || new Date(asUtc).toISOString().slice(0, 19) !== iso) return undefined
   if (zone === undefined) return Date.parse(iso)
   return Date.parse(zone.toUpperCase() === "Z" ? `${iso}Z` : `${iso}${zone.slice(0, 3)}:${zone.slice(-2)}`)
}

function named(names: string[], word: string): number {
   return names.findIndex((name) => word === name || word === name.slice(0, 3))
}

// Claude Code's pasted turn stamps, e.g. "✻ Baked for 33s · done Monday 11:57": "done" ends the turn
// that read, so its length comes off and the minute is floored, keeping the anchor no later than the reads.
// The verb is random, so only the middot marks a duration
function parseStamp(text: string, now: Date): number | undefined {
   const stamp = text.trim().toLowerCase()
   const middot = stamp.indexOf("·")
   const duration = middot < 0 ? undefined : /(?:^|\s)((?:\d+\s*[hms]\s*)+)$/.exec(stamp.slice(0, middot))
   if (middot >= 0 && !duration) return undefined
   const rest = stamp.slice(middot + 1).trim().replace(/^done\s+/, "")
   const clock = /(?:^|\s)(\d{1,2}):(\d{2})(?:\s*([ap]m))?$/.exec(rest)
   if (!clock) return undefined
   const [, clockHour, minute, meridiem] = clock
   if (+minute > 59 || (meridiem ? +clockHour < 1 || +clockHour > 12 : +clockHour > 23)) return undefined
   const hour = meridiem ? (+clockHour % 12) + (meridiem === "pm" ? 12 : 0) : +clockHour
   const at = (year: number, month: number, date: number) => new Date(year, month, date, hour, +minute)
   const daysAgo = (days: number) => at(now.getFullYear(), now.getMonth(), now.getDate() - days)

   const day = rest.slice(0, clock.index).trim().replace(/,$/, "")
   const weekday = named(WEEKDAYS, day)
   const [, monthFirst, dateAfter] = /^([a-z]+)\s+(\d{1,2})$/.exec(day) ?? []
   const [, dateFirst, monthAfter] = /^(\d{1,2})\s+([a-z]+)$/.exec(day) ?? []
   const month = named(MONTHS, monthFirst ?? monthAfter ?? "")
   let when: Date | undefined
   if (day === "") {
      when = daysAgo(0)
      if (when > now) when = daysAgo(1)
   } else if (weekday >= 0) {
      const back = (now.getDay() - weekday + 7) % 7
      when = daysAgo(back)
      if (when > now) when = daysAgo(back + 7)
   } else if (month >= 0) {
      // a guess: how the UI stamps turns over a week old is unknown
      for (let year = now.getFullYear(); !when && year > now.getFullYear() - 8; year--) {
         const candidate = at(year, month, +(dateAfter ?? dateFirst))
         if (candidate.getMonth() === month && candidate <= now) when = candidate
      }
   }
   if (!when) return undefined
   const durationMs = [...(duration?.[1] ?? "").matchAll(/(\d+)\s*([hms])/g)].reduce((sum, [, n, unit]) => sum + +n * UNIT_MS[unit], 0)
   return Math.floor((when.getTime() - durationMs) / 60_000) * 60_000
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

const pad = (n: number) => String(n).padStart(2, "0")
const DAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

export function localMinute(date: Date): string {
   return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`
}

export function rightNow(now: Date, cwd: string): string {
   const offset = -now.getTimezoneOffset()
   const zone = `UTC${offset < 0 ? "-" : "+"}${pad(Math.floor(Math.abs(offset) / 60))}:${pad(Math.abs(offset) % 60)}`
   const date = `${DAY_NAMES[now.getDay()]} ${localMinute(now)} ${zone}`
   const [sha, branch] = git(cwd, ["rev-parse", "HEAD", "--abbrev-ref", "HEAD"])?.trim().split("\n") ?? []
   if (!sha) return `(Right now: ${date}.)`
   const onBranch = branch && branch !== "HEAD" ? ` (${branch})` : ""
   return `(Right now: ${date}, HEAD at ${sha.slice(0, 8)}${onBranch}.)`
}

// a commit if it names one in any of the files' repos, else a time: each repo's last commit by then.
// Unchanged files map to their anchor's label; undefined if `lastSaw` names neither anywhere.
export function unchangedSince(lastSaw: string, files: string[], warnings: string[]): Map<string, string> | undefined {
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
   const time = [...anchors.values()].some(Boolean) ? undefined : parseTime(lastSaw)
   const minute = time === undefined ? undefined : Math.floor(time / 60_000) * 60_000
   if (minute !== undefined)
      for (const top of repos.keys()) anchors.set(top, firstLine(git(top, ["rev-list", "-1", `--before=@${minute / 1000}`, "HEAD"])))
   if (![...anchors.values()].some(Boolean)) {
      warnings.push(
         minute === undefined
            ? `--last-saw ${lastSaw} is neither a commit in the batch's repos nor a time this tool reads; nothing is marked unchanged`
            : `--last-saw ${lastSaw} resolves to ${localMinute(new Date(minute))}, but no repo in the batch has a commit at or before then; nothing is marked unchanged`,
      )
      return undefined
   }

   const unchanged = new Map<string, string>()
   for (const [top, paths] of repos) {
      const anchor = anchors.get(top)
      if (!anchor) continue
      const since = minute === undefined ? anchor.slice(0, 8) : localMinute(new Date(minute))
      const listed = (output: string | undefined) => output?.split("\0").filter(Boolean)
      const tracked = listed(git(top, ["ls-files", "-z", "--", ...paths.keys()]))
      if (!tracked?.length) continue
      // vs the working tree, so uncommitted edits count; git's own filters handle line endings
      const changed = listed(git(top, ["diff", "--name-only", "-z", anchor, "--", ...tracked]))
      if (!changed) continue
      for (const path of tracked) if (!changed.includes(path)) for (const file of paths.get(path) ?? []) unchanged.set(file, since)
   }
   return unchanged
}
