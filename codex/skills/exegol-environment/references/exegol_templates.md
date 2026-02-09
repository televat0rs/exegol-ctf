# Exegol command templates (history + aliases)

Exegol provides a “seeded” library of useful commands and shortcuts.

## Recommended usage (CTF)

- Prefer `/root/.zsh_history` for “what we actually tried”.
- Prefer `/opt/.exegol_history` for “clean seeded examples”.
- Use `/opt/.exegol_aliases` to discover Exegol wrappers/shortcuts.

## Seeded history (raw commands)

- Source: `/opt/.exegol_history`
- Benefit: plain commands (no Zsh extended-history timestamps).

Search examples:

- `rg -i "<query>" /opt/.exegol_history`

## Live shell history (extended format)

- Source: `/root/.zsh_history`
- Format: Zsh “extended history” lines like `: 1768291676:0;<command>`

Commands-only view:

- `sed -E 's/^:[^;]*;//' /root/.zsh_history | rg -i "<query>"`

To reduce noise, split `/root/.zsh_history` at the “YOUR COMMANDS BELOW” marker:

- Seeded examples only (before marker): `sed -E 's/^:[^;]*;//' /root/.zsh_history | awk '($0 ~ /YOUR COMMANDS BELOW/){exit} {print}'`
- Our commands only (after marker): `sed -E 's/^:[^;]*;//' /root/.zsh_history | awk 'found{print} /YOUR COMMANDS BELOW/{found=1; next}'`

If the marker is missing, treat the whole file as “our commands”.

If you’re in an interactive Exegol shell, there may be a `history-dump` alias that prints only commands after the marker.

## Aliases & wrappers

- Source: `/opt/.exegol_aliases`
- Search: `rg -i "<query>" /opt/.exegol_aliases`

## Shell bootstrap (why aliases/tools differ)

- Source: `/opt/.exegol_shells_rc`
- Purpose: sets up `PATH`, loads `/opt/.exegol_aliases`, and may prepend `/opt/my-resources/bin` (which can shadow tool names).

Tip:
- When you see variables in templates (e.g. `$TARGET`, `$DOMAIN`), prefer using your session’s exported vars; see `/workspace/AGENTS.md` for the current challenge’s targeting context.
