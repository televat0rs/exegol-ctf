# Exegol container paths & conventions (practical)

## High-signal paths

- Workspace: `/workspace`
- Official “latest nightly” tools list snapshot: `exegol-environment/references/installed_tools_latest_nightly_amd64.csv`
- Tools directory (many git checkouts/venvs): `/opt/tools/`
- Shared resources (payload helpers, Win tools, linPEAS, etc.): `/opt/resources/`
- Wordlists: `/opt/lists/` (symlinked to `/usr/share/wordlists/`)
- Hashcat rules: `/opt/rules/` (also `/usr/share/hashcat/rules/`)
- User customizations volume: `/opt/my-resources/` (if enabled)

## Shell integration you can leverage

- Exegol adds `/opt/tools/bin` to `PATH` (plus other tool-specific PATHs).
- Exegol-provided aliases live in `/opt/.exegol_aliases`.
- Shell bootstrap is in `/opt/.exegol_shells_rc`.
- Seeded command templates live in `/opt/.exegol_history` (see `exegol-environment/references/exegol_templates.md`).
- Live shell history (extended format) is in `/root/.zsh_history`.
  - Note: `/opt/.exegol_shells_rc` may prepend `/opt/my-resources/bin` (if present), which can shadow tool names.

Notable behaviors:
- `systemctl` is intentionally disabled inside the container; use `service ...`.
- A convenience `ws` alias typically jumps to `/workspace` (when running interactive shells that source Exegol rc).

## Where to look for bundled resources (examples)

- Linux: `/opt/resources/linux/`
- Windows: `/opt/resources/windows/`
- Webshells: `/opt/resources/webshells/`
- Encrypted disks tooling: `/opt/resources/encrypted_disks/`
