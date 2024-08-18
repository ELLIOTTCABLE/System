#!/usr/bin/env -S npx tsx
import "zx/globals"

import nunjucks from "nunjucks"
import fs from "fs-extra"

let tpath = "templates"

let templates = fs.readdirSync(tpath)

const nenv = nunjucks.configure(tpath, {
   autoescape: false,
   throwOnUndefined: true,
   noCache: true,
   // avoid conflicts with Anki's default template syntax
   tags: {
      variableStart: "<$",
      variableEnd: "$>",
   },
})

async function process_card(root, dirent) {
   console.log(dirent.name)
}

async function process_note_type(root, dirent: fs.Dirent) {
   console.log(`Note type: ${dirent.name}`)
   const dir = await fs.promises.opendir(path.join(root, "Note Types", dirent.name))
   for await (const dirent of dir) {
      process_card(root, dirent)
   }
}

const troot = path.join(".", tpath)
const note_types = await fs.promises.opendir(path.join(troot, "Note Types"))
for await (const note_type_dirent of note_types) {
   process_note_type(troot, note_type_dirent)
}

// const result = nenv.renderString("Hello <$ name $>!", { name: "World" })

// console.log(result)
