---
name: shell-scripting-and-automation
description: Writing and modifying scripts; read for any shell/bash/zx/node.js/ansible/Makefile-type tasks
---

# Shell scripting and automation preferences

## Instructions
"Scripting" (single-file, task-focused automation; as opposed to multi-file software with architecture, coherent goals, and collaborators) is one of the few exceptions to my general programming priorities - in particular, my preference for 'simplicity' and readability. As much of my scripting is for my-eyes-only, or isn't meant to be modified/maintained over time by a team, I prefer terse shell-scripts that rely heavily on builtin shell-features and deep knowledge of shell behaviour, even if that makes them harder to read for a casual reader. If you don't understand something in a shell-script, please ask me about it; and feel free to generate 'clever' code (ensuring that you explain to me in detail what's going on in your changes if they're non-obvious, so I don't miss them; including word-splitting, parameter expansion, and the like.)

Recently, I've started to lean towards the `zx` Node.js-based scripting environment for autmation tasks in my own projects, over the traditional POSIX-sh or makefiles. Where present/available, write automation/scripts in `.zx.mjs` files instead of `.sh` files; but don't be afraid to fall back to POSIX-sh for portability or when clearly already the project-local preference.

For modifying (or where appropriate, generating) shell-script, see ./POSIX-SHELL.md. Else, refer to ./ZX-NODEJS.md for instructions.
