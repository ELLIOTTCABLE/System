import assert from "node:assert/strict"
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs"
import { homedir, tmpdir } from "node:os"
import { dirname, join, resolve } from "node:path"
import { test } from "node:test"
import { fileKey, importsOf, rulePatterns, STEERING, steeringModel } from "./steering.mts"

function project(files: Record<string, string>): string {
   const root = mkdtempSync(join(tmpdir(), "steering-"))
   for (const [path, text] of Object.entries(files)) {
      mkdirSync(dirname(join(root, path)), { recursive: true })
      writeFileSync(join(root, path), text)
   }
   return root
}

const key = (root: string, path: string) => fileKey(join(root, path))
const noPiConfig = { PI_CODING_AGENT_DIR: join(tmpdir(), "steering-no-pi-config") }

test("imports are taken from prose, not code or comments", () => {
   const text = "@AGENTS.md `@span.md`\n```\n@fenced.md\n```\n<!-- @comment.md -->\nsee @./docs/a\\ b.md#part and @~/x.md\n"

   assert.deepEqual(importsOf(resolve("/r", "CLAUDE.md"), text), [
      resolve("/r", "AGENTS.md"),
      resolve("/r", "docs", "a b.md"),
      join(homedir(), "x.md"),
   ])
})

test("a rule's paths frontmatter becomes patterns; no paths, '**' alone, or bad YAML means everywhere", () => {
   assert.deepEqual(rulePatterns('---\npaths: "src/**/*.{ts,tsx}, lib/**"\n---\nbody'), ["src/**/*.ts", "src/**/*.tsx", "lib"])
   assert.deepEqual(rulePatterns("---\npaths:\n  - docs/*.md\n---\nbody"), ["docs/*.md"])
   assert.equal(rulePatterns("no frontmatter"), undefined)
   assert.equal(rulePatterns("---\npaths: '**'\n---\nbody"), undefined)
   assert.equal(rulePatterns("---\npaths: [unclosed\n---\nbody"), undefined)
})

test("Claude Code loads CLAUDE files at launch with their imports, and AGENTS.md only through an import", () => {
   const root = project({ "CLAUDE.md": "@AGENTS.md\n", "AGENTS.md": "agents\n", "README.md": "readme\n" })
   const { launch } = steeringModel(STEERING.claude, root)

   assert.ok(launch.has(key(root, "CLAUDE.md")))
   assert.ok(launch.has(key(root, "AGENTS.md")))
   assert.ok(!launch.has(key(root, "README.md")))
})

test("Claude Code reads AGENTS.md itself where no CLAUDE file exists, at launch and on reads", () => {
   const root = project({ "AGENTS.md": "agents\n", "sub/AGENTS.md": "sub agents\n", "sub/x.md": "x\n" })
   const model = steeringModel(STEERING.claude, root)

   assert.ok(model.launch.has(key(root, "AGENTS.md")))
   assert.deepEqual(model.onRead(join(root, "sub", "x.md")), [key(root, "sub/AGENTS.md")])
})

test("a Claude Code read loads every nested directory's CLAUDE files, rules and imports down to the file", () => {
   const root = project({
      "CLAUDE.md": "root\n",
      "sub/CLAUDE.md": "@NOTES.md\n",
      "sub/NOTES.md": "notes\n",
      "sub/.claude/rules/r.md": "sub rule\n",
      "sub/deep/y.md": "y\n",
      ".claude/rules/always.md": "always\n",
      ".claude/rules/lib.md": "---\npaths: lib/**\n---\nlib rule\n",
      "lib/q.md": "q\n",
   })
   const model = steeringModel(STEERING.claude, root)

   assert.ok(model.launch.has(key(root, ".claude/rules/always.md")))
   assert.ok(!model.launch.has(key(root, ".claude/rules/lib.md")))
   assert.deepEqual(new Set(model.onRead(join(root, "sub", "deep", "y.md"))), new Set([
      key(root, "sub/NOTES.md"),
      key(root, "sub/CLAUDE.md"),
      key(root, "sub/.claude/rules/r.md"),
   ]))
   assert.deepEqual(model.onRead(join(root, "lib", "q.md")), [key(root, ".claude/rules/lib.md")])
   assert.ok(model.loadable(join(root, "sub", "NOTES.md")))
   assert.ok(model.loadable(join(root, ".claude", "rules", "lib.md")))
   assert.ok(!model.loadable(join(root, "sub", "deep", "y.md")))
})

test("pi loads one file per directory at launch, the first of its names, and nothing on reads", () => {
   const root = project({ "AGENTS.md": "agents\n", "CLAUDE.md": "claude\n", "sub/AGENTS.md": "sub\n", "sub/x.md": "x\n" })
   const model = steeringModel(STEERING.pi, root, noPiConfig)

   assert.ok(model.launch.has(key(root, "AGENTS.md")))
   assert.ok(!model.launch.has(key(root, "CLAUDE.md")))
   assert.deepEqual(model.onRead(join(root, "sub", "x.md")), [])
   assert.ok(!model.loadable(join(root, "sub", "AGENTS.md")))
})

test("from a worktree nested in its main repo, Claude Code skips the main repo's checked-in files and pi its shadowed one", () => {
   const root = project({
      ".git/worktrees/wt/commondir": "../..\n",
      "CLAUDE.md": "main checked in\n",
      "CLAUDE.local.md": "main local\n",
      "AGENTS.md": "main agents\n",
      ".claude/worktrees/wt/CLAUDE.md": "worktree checked in\n",
      ".claude/worktrees/wt/AGENTS.md": "worktree agents\n",
   })
   const worktree = join(root, ".claude", "worktrees", "wt")
   writeFileSync(join(worktree, ".git"), `gitdir: ${join(root, ".git", "worktrees", "wt")}\n`)

   const claude = steeringModel(STEERING.claude, worktree)
   assert.ok(claude.launch.has(key(root, ".claude/worktrees/wt/CLAUDE.md")))
   assert.ok(claude.launch.has(key(root, "CLAUDE.local.md")))
   assert.ok(!claude.launch.has(key(root, "CLAUDE.md")))

   const pi = steeringModel(STEERING.pi, worktree, noPiConfig)
   assert.ok(pi.launch.has(key(root, ".claude/worktrees/wt/AGENTS.md")))
   assert.ok(!pi.launch.has(key(root, "AGENTS.md")))
})
