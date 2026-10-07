import assert from "node:assert/strict"
import { execFileSync, spawnSync } from "node:child_process"
import { mkdtempSync, realpathSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { fileURLToPath } from "node:url"
import { test } from "node:test"
import { expand } from "./expand-handoff.mts"
import { parseTime, unchangedSince } from "./last-saw.mts"

const numberedLines = (count: number) => Array.from({ length: count }, (_, i) => `line ${i + 1}`).join("\n") + "\n"

function git(root: string, args: string[], date?: string): string {
   const identity = ["-c", "user.name=test", "-c", "user.email=test@example.com", "-c", "commit.gpgsign=false"]
   const env = date ? { ...process.env, GIT_AUTHOR_DATE: date, GIT_COMMITTER_DATE: date } : process.env
   return execFileSync("git", ["-C", root, ...identity, "-c", "core.autocrlf=false", ...args], { encoding: "utf8", stdio: "pipe", env }).trim()
}

function repo(): string {
   const root = realpathSync.native(mkdtempSync(join(tmpdir(), "last-saw-")))
   git(root, ["init", "--quiet"])
   return root
}

function commit(root: string, files: Record<string, string>, date: string): string {
   for (const [name, text] of Object.entries(files)) writeFileSync(join(root, name), text)
   git(root, ["add", "--", ...Object.keys(files)])
   git(root, ["commit", "--quiet", "-m", "fixture"], date)
   return git(root, ["rev-parse", "HEAD"])
}

test("a commit marks tracked files unchanged since it; committed, uncommitted and untracked changes stay unmarked", () => {
   const root = repo()
   const anchor = commit(root, { "same.md": "a\n", "committed.md": "a\n", "dirty.md": "a\n" }, "2026-01-01T10:00:00Z")
   commit(root, { "committed.md": "b\n" }, "2026-01-02T10:00:00Z")
   writeFileSync(join(root, "dirty.md"), "b\n")
   writeFileSync(join(root, "untracked.md"), "a\n")
   const files = ["same.md", "committed.md", "dirty.md", "untracked.md"].map((name) => join(root, name))
   const warnings: string[] = []

   assert.deepEqual([...unchangedSince(anchor.slice(0, 8), files, warnings)], [join(root, "same.md")])
   assert.deepEqual(warnings, [])
})

test("a time picks the last commit by then", () => {
   const root = repo()
   commit(root, { "a.md": "1\n", "b.md": "1\n" }, "2026-01-01T10:00:00Z")
   commit(root, { "b.md": "2\n" }, "2026-01-03T10:00:00Z")
   const files = [join(root, "a.md"), join(root, "b.md")]

   assert.deepEqual([...unchangedSince("2026-01-02T10:00:00Z", files, [])], [join(root, "a.md")])
   assert.deepEqual([...unchangedSince("2026-01-02 10:00", files, [])], [join(root, "a.md")])
   assert.deepEqual([...unchangedSince("2026-01-04", files, [])], files)
})

test("a value naming no commit and no time, or a time before any commit, warns once and marks nothing", () => {
   const root = repo()
   commit(root, { "a.md": "1\n" }, "2026-01-01T10:00:00Z")
   const files = [join(root, "a.md")]

   for (const lastSaw of ["no-such-commit", "done someday 11:57", "2025-12-31 23:59"]) {
      const warnings: string[] = []
      assert.equal(unchangedSince(lastSaw, files, warnings), undefined, lastSaw)
      assert.equal(warnings.length, 1, lastSaw)
      assert.match(warnings[0], /names no commit or time/)
   }
})

test("a commit from one repo marks nothing in another", () => {
   const first = repo()
   const second = repo()
   const anchor = commit(first, { "a.md": "1\n" }, "2026-01-01T10:00:00Z")
   commit(second, { "b.md": "1\n" }, "2026-01-01T10:00:00Z")
   const files = [join(first, "a.md"), join(second, "b.md")]

   assert.deepEqual([...unchangedSince(anchor, files, [])], [join(first, "a.md")])
})

test("ISO times are taken strictly, local unless zoned, never guessed", () => {
   assert.equal(parseTime("2026-10-05T17:30:00Z"), Date.UTC(2026, 9, 5, 17, 30))
   assert.equal(parseTime("2026-10-05T17:30+02:00"), Date.UTC(2026, 9, 5, 15, 30))
   assert.equal(parseTime("2026-10-05 17:30"), new Date(2026, 9, 5, 17, 30).getTime())
   assert.equal(parseTime("2026-10-05"), new Date(2026, 9, 5).getTime())
   for (const text of ["2026-02-31 10:00", "2026-10-05 24:00", "yesterday", "bd5554e8"])
      assert.equal(parseTime(text), undefined, text)
})

test("--last-saw suffixes batch reads of unchanged files, every piece of a split one, but never pages", () => {
   const root = repo()
   const anchor = commit(root, { "same.md": numberedLines(300), "huge.md": numberedLines(3000), "edited.md": numberedLines(300) }, "2026-01-01T10:00:00Z")
   writeFileSync(join(root, "edited.md"), numberedLines(301))
   const pickup = join(root, "pickup.md")
   const handoff = [
      "Intro.",
      `Read(file_path="${join(root, "same.md")}", offset=10, limit=200)`,
      `Read(file_path="${join(root, "huge.md")}")`,
      `Read(file_path="${join(root, "edited.md")}")`,
   ].join("\n") + "\n"
   const { output, batch, unchanged } = expand(handoff, { pickupPath: pickup, lastSaw: anchor.slice(0, 8) })

   const note = ` # unchanged (same content as at ${anchor.slice(0, 8)})`
   assert.equal(output, handoff)
   assert.equal(unchanged, 3)
   assert.deepEqual(batch, [
      `Read(file_path="${pickup}", offset=1, limit=4)`,
      `Read(file_path="${join(root, "same.md")}", offset=10, limit=200)${note}`,
      `Read(file_path="${join(root, "huge.md")}", offset=1, limit=2000)${note}`,
      `Read(file_path="${join(root, "huge.md")}", offset=2001, limit=1000)${note}`,
      `Read(file_path="${join(root, "edited.md")}")`,
   ])
})

test("--last-saw marks nothing when run on the other side of Windows/WSL from the harness", () => {
   const root = repo()
   const anchor = commit(root, { "same.md": numberedLines(300) }, "2026-01-01T10:00:00Z")
   const otherSide = process.platform === "win32" ? "posix" : "windows"
   const handoff = `Read(file_path="${join(root, "same.md")}")\n`
   const { batch, warnings } = expand(handoff, { pickupPath: join(root, "pickup.md"), lastSaw: anchor, paths: otherSide })

   assert.ok(batch.every((call) => !call.includes("# unchanged")))
   assert.ok(warnings.some((warning) => /--last-saw needs this run on the harness's side/.test(warning)))
})

// Tuesday 2026-10-06, 14:00 local
const now = new Date(2026, 9, 6, 14, 0)
const local = (month: number, date: number, hour: number, minute: number) => new Date(2026, month - 1, date, hour, minute).getTime()

test("a bare time stamp is today's if already past, else yesterday's", () => {
   assert.equal(parseTime("done 11:57", now), local(10, 6, 11, 57))
   assert.equal(parseTime("done 18:58", now), local(10, 5, 18, 58))
   assert.equal(parseTime("11:57 am", now), local(10, 6, 11, 57))
   assert.equal(parseTime("done 6:58 pm", now), local(10, 5, 18, 58))
})

test("a weekday stamp is the latest such day already past, last week's if today's is still ahead", () => {
   assert.equal(parseTime("done Monday 11:57", now), local(10, 5, 11, 57))
   assert.equal(parseTime("done Tuesday 11:57", now), local(10, 6, 11, 57))
   assert.equal(parseTime("done Tuesday 18:58", now), local(9, 29, 18, 58))
   assert.equal(parseTime("done Wed 09:00", now), local(9, 30, 9, 0))
})

test("the turn length pasted with a stamp comes off it, floored to the minute", () => {
   assert.equal(parseTime("Worked for 3m 44s · done Monday 11:57", now), local(10, 5, 11, 53))
   assert.equal(parseTime("Worked for 1h 2m · done 11:57", now), local(10, 6, 10, 55))
   assert.equal(parseTime("Worked for 45s · done 11:57", now), local(10, 6, 11, 56))
})

test("a month-day stamp is the latest such day already past", () => {
   assert.equal(parseTime("done Oct 5, 11:57", now), local(10, 5, 11, 57))
   assert.equal(parseTime("5 October 11:57", now), local(10, 5, 11, 57))
   assert.equal(parseTime("Dec 25 09:00", now), new Date(2025, 11, 25, 9, 0).getTime())
})

test("stamps that don't read unambiguously are refused", () => {
   for (const text of [
      "done someday 11:57",
      "Worked for a while · done 11:57",
      "done 11:60",
      "done 25:00",
      "done 13:05 pm",
      "done 0:30 am",
      "done Feb 30 10:00",
      "done Monday",
      "done",
   ])
      assert.equal(parseTime(text, now), undefined, text)
})

test("stdout says reads were checked only when --last-saw resolves", () => {
   const script = fileURLToPath(new URL("./expand-handoff.mts", import.meta.url))
   const hermetic = Object.fromEntries(Object.entries(process.env).filter(([key]) => !/^(PI_|CLAUDE)/.test(key)))
   const root = repo()
   const anchor = commit(root, { "same.md": numberedLines(300) }, "2026-01-01T10:00:00Z")
   const handoffPath = join(root, "handoff.md")
   writeFileSync(handoffPath, `Read(file_path="${join(root, "same.md")}")\n`)
   const run = (...extra: string[]) =>
      spawnSync(process.execPath, [script, "--in", handoffPath, "--out", join(root, "pickup.md"), ...extra], { encoding: "utf8", env: hermetic })
   const checked = `(files checked for recency, and annotated if they haven't changed since ${anchor.slice(0, 8)}.)`

   const resolved = run("--last-saw", anchor.slice(0, 8)).stdout.trimEnd().split("\n")
   assert.equal(resolved.at(-3), checked)
   assert.match(resolved.at(-2)!, /pickup\.md", offset=1, limit=1\)$/)
   assert.ok(!run().stdout.includes("files checked for recency"))
   assert.ok(!run("--last-saw", "no-such-commit").stdout.includes("files checked for recency"))
})
