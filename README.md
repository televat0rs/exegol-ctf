# exegol-ctf

CTF Scaffolding for Cultists.

## Components

- `start-ctf.sh`
  - host-side launcher
  - prepares challenge dir + note seed
  - validates/starts VPN and optional BloodHound
  - starts Exegol
- `ctf.sh`
  - container-side bootstrap
  - patches placeholders, writes profile exports
  - calls `hostnamer.sh` for host mapping
  - builds tmux workspace
- `hostnamer.sh`
  - rewrites target IP row in `/etc/hosts`
  - removes stale dotted-name mappings on other rows
  - persists `DOMAIN`/`DC_HOST`/`DC_IP` when requested
- `load_user_setup.sh`
  - first-start Exegol customization hook from `my-resources`
- `ctf-agents.md`
  - Codex AGENTS.md template used in challenge
- `ctf.lin.md` / `ctf.win.md`
  - scratch templates for Linux/Windows flows
- `codex/config.toml`
  - shared Codex runtime config baseline
- `codex/skills/`
  - bundled Codex skills (`exegol-environment`, `burp-mcp`, system skills)

## One-Time Host Setup

- copy runtime scripts into Exegol `my-resources`
- seed Codex config + skills into mounted setup path
- create persistent dirs for Burp/Java/Codex
- append bind mounts for persistence across container rebuilds

```bash
cp "$PWD/ctf.sh" /root/.exegol/my-resources/bin/ctf.sh
cp "$PWD/hostnamer.sh" /root/.exegol/my-resources/bin/hostnamer.sh
cp "$PWD/load_user_setup.sh" /root/.exegol/my-resources/setup/load_user_setup.sh

cp "$PWD/codex/config.toml" /home/kali/.codex/config.toml
cp -a "$PWD/codex/skills" /home/kali/.codex/

mkdir -p /root/.exegol/my-resources/setup/BurpSuitePro
mkdir -p /root/.exegol/my-resources/setup/.BurpSuite
mkdir -p /root/.exegol/my-resources/setup/.java
mkdir -p /root/.exegol/my-resources/setup/.codex

grep -q '/root/.exegol/my-resources/setup/.codex' /etc/fstab || cat <<'EOF_FSTAB' | sudo tee -a /etc/fstab
/home/kali/BurpSuitePro /root/.exegol/my-resources/setup/BurpSuitePro none bind 0 0
/home/kali/.BurpSuite /root/.exegol/my-resources/setup/.BurpSuite none bind 0 0
/home/kali/.java /root/.exegol/my-resources/setup/.java none bind 0 0
/home/kali/.codex /root/.exegol/my-resources/setup/.codex none bind 0 0
EOF_FSTAB
sudo mount -a
```

## Challenge Flow

Host:

```bash
/home/kali/Necronomicon/exegol-ctf/start-ctf.sh -m lin -v "/home/kali/Necronomicon/ctf/htb_s10.ovpn" pterodactyl.htb
```

Inside Exegol:

```bash
/opt/my-resources/bin/ctf.sh --target 10.129.10.10
```

Host updates during reset/pivot:

```bash
/opt/my-resources/bin/hostnamer.sh 10.129.2.132 challenge.htb app.challenge.htb
/opt/my-resources/bin/hostnamer.sh 172.16.10.5 DC01.internal.local -dc
```

## Codex skills

- `exegol-environment`: Exegol paths, tools, inventories, services
- `burp-mcp`: Burp MCP triage/index/verify workflow

## `start-ctf.sh` Overrides

- `BASE_DIR` (default: `/home/kali/Necronomicon/ctf`)
- `DEFAULT_VPN` (default: `${BASE_DIR}/htb_s9.ovpn`)
- `LIN_TEMPLATE` (default: `${SCRIPT_DIR}/ctf.lin.md`)
- `WIN_TEMPLATE` (default: `${SCRIPT_DIR}/ctf.win.md`)
- `AGENTS_TEMPLATE` (default: `${SCRIPT_DIR}/ctf-agents.md`)
- `EXEGOL_IMAGE` (default: `nightly0112`)
