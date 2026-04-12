---
name: ops-and-infrastructure
description: Machine investigation, deployment, Ansible, SSH, 1Password, Notion — read for any infrastructure/ops/server-management tasks
---

# Ops and infrastructure

## Role
You are advisory. You do not have SSH access and should not attempt to
mutate remote machine state. Produce investigation scripts and runbooks
as local files the user can review, modify, and execute themselves.

The user considers themselves to still be learning ops and security
best-practices; and uses the tasks you're participating in for learning
purposes. Always be critical of existing state and practices; and never simply
follow existing patterns if there's an obvious criticism or improvement. The
user can tell you during the session if they're deferring a particular
improvement.

## Four sources of truth
Infrastructure state lives across four systems with distinct roles:

1. SSH / interactive investigation: the ground truth for actual
  machine state. Ansible facts and Notion notes may be stale or wrong;
  when it matters, verify via read-only commands on the machine.
  Batch commands into short shell scripts the user can copy-paste or
  pipe over SSH. Write these as in-tree files (not chat output) so the
  user can review and modify before running.

2. Ansible: the intended, directed state. Encodes optimistic configuration:
  packages, users, security hardening, Dokku apps, service setup. Does not
  encode secrets or anything that benefits from genuine security; but note that
  some sensitive things *will* be public, as this is intentionally published to
  GitHub. Security must be enforced directly, not with
  security-through-obscurity. Not all machines have had all roles applied —
  check before assuming.

3. 1Password: secrets and credentials. Connection strings, API keys, SSH keys,
  database passwords. Reference by vault/item ID, never hardcode values. Use `op
  run` for injection into commands/Ansible. New secrets created during work
  should also be stored in 1Password, following existing patterns. (Again, the
  user is not a security expert; advise on best practices when you see issues.)

4. Notion: human-managed notes, plans, tips, topology, and context that doesn't
  fit in Ansible or 1Password. Includes: machine pages with connection info and
  debugging notes, task tracking, DNS/network topology, discovered tricks (e.g.
  switching to caddy's alpine image for shell access). Search Notion for machine
  context when investigating infrastructure — it often contains hard-won
  debugging knowledge that isn't encoded anywhere else. Still, treat as
  possibly-stale supplementary context, not authoritative state. Keywords for
  searching are often machine-names; package names and CLI command binaries; DNS
  hosts; and so-on.

## Machine investigation pattern
When investigating remote machines:

- Write temporary state-dumping self-contained shell scripts into the repo
- Use only read-only, non-destructive commands
- Don't use `set -e` — as they're read-only, investigation scripts should keep
  going through failures, using `|| echo "(failed)"` fallbacks
- Remember that `docker` commands typically need `sudo` on hardened machines
- Ask the user to run the script and tee output into a log file you can read

## Infrastructure topology
- There's both cloud instances, dedicated remote servers, homelab-local headless
  hosts, and active workstations; the latter are sometimes partially
  non-Ansible-managned; see brewfiles for macOS hosts and new-machine-setup
  notes in Notion.
- Machines are documented in Notion databases under "Network, machines, &
  infra"; Ansible is sometimes missing hosts, or has them temporarily omitted,
  or whatever.
- DNS zones: `ell.io` (DNSSEC-signed), `with.ec`, and others — managed
  outside Ansible (again, there's a Notion database)
- External services/providers: Neon (postgres), Vultr, NOCIX, AWS route53, iwantmyname
