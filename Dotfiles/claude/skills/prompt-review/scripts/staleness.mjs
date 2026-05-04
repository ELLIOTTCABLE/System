#!/usr/bin/env node
// Print prompt-review criteria staleness.
//
// Reads `criteria-as-of:` from ../SKILL.md, compares to today, prints one of:
//    FRESH (N days since YYYY-MM-DD)
//    AGING (N days since YYYY-MM-DD)
//    STALE (N days since YYYY-MM-DD)
//
// Invoked from SKILL.md via Claude Code's `!`<command>`` injection so the
// loaded skill content carries a deterministic staleness verdict, rather than
// asking the agent to do date arithmetic itself (a reliability hazard).

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const skillMd = resolve(here, "..", "SKILL.md");

let text;
try {
   text = readFileSync(skillMd, "utf8");
} catch (e) {
   console.error(`UNKNOWN: cannot read ${skillMd}: ${e.message}`);
   process.exit(1);
}

const match = text.match(/criteria-as-of:\s*(\d{4}-\d{2}-\d{2})/);
if (!match) {
   console.error("UNKNOWN: no `criteria-as-of:` date found in SKILL.md");
   process.exit(1);
}

const criteriaDate = match[1];
// Compare at UTC-midnight to avoid TZ drift biasing the day count.
const criteriaMs = Date.parse(`${criteriaDate}T00:00:00Z`);
const todayUtc = new Date();
const todayMs = Date.UTC(
   todayUtc.getUTCFullYear(),
   todayUtc.getUTCMonth(),
   todayUtc.getUTCDate(),
);
const days = Math.floor((todayMs - criteriaMs) / 86_400_000);

const verdict = days > 180 ? "STALE" : days > 90 ? "AGING" : "FRESH";
console.log(`${verdict} (${days} days since ${criteriaDate})`);
