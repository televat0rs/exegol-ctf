# CTF Agent Instructions

## Goal
Provide guidance to help me solve the latest Hack The Box challenge machine.

## Local playbooks
- Exegol container reference (tools/paths/services): `/root/.codex/skills/exegol-environment/SKILL.md`
- Web/Burp workflow (MCP-driven triage + verification): `/root/.codex/skills/burp-mcp/SKILL.md`
- Reverse engineering workflow (ReVa/Ghidra MCP): `/root/.codex/skills/ghidra-mcp/SKILL.md`

## Targeting context
- Challenge slug: `CHALLENGE_SLUG`
- Domain/vhost (may change): `DOMAIN_SLUG`
- Target: `TARGET_IP`
- Attacker VPN: `VPN_IP` (`VPN_INTERFACE`)
- Recon root: `SCANS_ROOT`
- Primary scans dir: `SCANS_DIR`
- If you’re unsure which scans dir is current, use: `ls -dt /workspace/results/*/scans 2>/dev/null | head`

## Where to look first
- Notes/progress: `/workspace/CHALLENGE_SLUG.md`
- Tool output (scans, recon): `SCANS_ROOT` (start with `SCANS_DIR` if it exists)
- Scratch space for long/raw output: `/workspace/tmp/`

## Running notes (recommended)
Keep one lightweight “state” file per target so we don’t lose context between turns.

- Location: `/workspace/tmp/CHALLENGE_SLUG/`
- Filename: `TARGET_IP.md` (if IPv6, replace `:` with `_`)
- Keep it short: confirmed facts, creds/tokens, open ports/services, interesting paths/endpoints, what we tried, and 3–5 next probes.

## Working rules
- Keep chat output compact (findings + next commands). Write large raw output to the scratch space `/workspace/tmp/`.
- Don’t edit/overwrite/delete/rename existing artifacts unless I ask.
- Ask before target-changing actions (exploitation, uploads, persistence) or any write outside `/workspace/tmp/`.
- Avoid placeholders like `user:password` in commands; prefer these exported vars when available: `$INTERFACE $DOMAIN $TARGET $DC_IP $IP $ATTACKER_IP $HOSTNAME`.
- If you see `mktemp … /root/.pyenv/shims/tmp.XXXXXXXXXX` or `pyenv: cannot rehash … isn’t writable`, treat it as harmless stderr noise unless the command fails or output must be clean; then rerun that command non-login.

## Command history (optional)
Use this to get **examples of command usage** (seeded) and see **what we already tried** (our commands).

- Examples (seeded exegol templates): `rg -i "<tool|technique>" /opt/.exegol_history`
- Attempts (our real commands): `sed -E 's/^:[^;]*;//' /root/.zsh_history | awk 'found{print} /YOUR COMMANDS BELOW/{found=1; next}' | rg -i "<tool|technique>"`
- Aliases/wrappers: `rg -i "<tool|technique>" /opt/.exegol_aliases`

## When stuck
Use the running notes as the source of truth, and mine all relevant artifacts in the /workspace before proposing new steps:

- Primary state: `/workspace/tmp/CHALLENGE_SLUG/TARGET_IP.md` and `/workspace/CHALLENGE_SLUG.md`
- Recon/output artifacts: newest files in `/workspace/results/` and `/workspace/tmp/`
- Autorecon metadata (if present): `SCANS_DIR/_errors.log`, `SCANS_DIR/_commands.log`, `SCANS_DIR/_manual_commands.txt`
- Burp context: read newest `/workspace/tmp/burp-mcp/*.md` (or `ls -lt /workspace/tmp/burp-mcp/ | head`)
- What we already tried (commands): use the “Attempts” history query above (filter by tool/technique/host/path)

Then provide:

- 2–3 hypotheses (each tied to one observable signal)
- 3–5 minimal next commands/requests (1 hypothesis per probe)
- “What success looks like” for each probe + the next branch if it fails
