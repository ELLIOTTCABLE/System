import assert from "node:assert/strict"
import { execFileSync } from "node:child_process"
import { mkdtempSync, realpathSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
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

// commits `files` at `date`, returning the commit's full SHA
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

   for (const lastSaw of ["no-such-commit", "done Monday 11:57", "2025-12-31 23:59"]) {
      const warnings: string[] = []
      assert.equal(unchangedSince(lastSaw, files, warnings).size, 0, lastSaw)
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

test("times are taken only in strict forms, local unless zoned, never guessed", () => {
   assert.equal(parseTime("2026-10-05T17:30:00Z"), Date.UTC(2026, 9, 5, 17, 30))
   assert.equal(parseTime("2026-10-05T17:30+02:00"), Date.UTC(2026, 9, 5, 15, 30))
   assert.equal(parseTime("2026-10-05 17:30"), new Date(2026, 9, 5, 17, 30).getTime())
   assert.equal(parseTime("2026-10-05"), new Date(2026, 9, 5).getTime())
   for (const text of ["2026-02-31 10:00", "2026-10-05 24:00", "Monday 11:57", "yesterday", "bd5554e8"])
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
