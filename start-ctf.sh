#!/usr/bin/env bash
set -euo pipefail

# Host-side launcher for a new/resumed challenge.
# - creates challenge dir + note scaffolding
# - validates/starts VPN and optional BloodHound
# - starts the Exegol instance with expected defaults

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || printf '%s' "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd)"

BASE_DIR="${BASE_DIR:-/home/kali/Necronomicon/ctf}"
DEFAULT_VPN="${DEFAULT_VPN:-${BASE_DIR}/htb_s9.ovpn}"
LIN_TEMPLATE="${LIN_TEMPLATE:-${SCRIPT_DIR}/ctf.lin.md}"
WIN_TEMPLATE="${WIN_TEMPLATE:-${SCRIPT_DIR}/ctf.win.md}"
AGENTS_TEMPLATE="${AGENTS_TEMPLATE:-${SCRIPT_DIR}/ctf-agents.md}"
EXEGOL_IMAGE="${EXEGOL_IMAGE:-nightly0112}"

MODE="lin"
VPN_PATH="$DEFAULT_VPN"
BH_MODE="yes"
CHALLENGE=""

# Preserve original CLI args for notes logging.
ORIG_ARGS=("$@")

usage() {
  cat <<EOF
Usage: ${SCRIPT_PATH} [options] <CHALLENGE_NAME>

Options:
  -n, --name NAME       Challenge name (can also be given positionally)
  -m, --mode MODE       lin | win | all   (default: lin)
  -v, --vpn PATH        OpenVPN config path (default: $DEFAULT_VPN)
      --no-bloodhound   Do not start BloodHound containers
  -h, --help            Show this help

Examples:
  ${SCRIPT_PATH} test123.htb --no-bloodhound
  ${SCRIPT_PATH} -m all -v $BASE_DIR/htb_academy.ovpn htbacademy.htb
  ${SCRIPT_PATH} -m win -v $BASE_DIR/htb_s9.ovpn overwatch.htb
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--name) CHALLENGE="$2"; shift 2 ;;
      -m|--mode) MODE="$2"; shift 2 ;;
      -v|--vpn)  VPN_PATH="$2"; shift 2 ;;
      --no-bloodhound) BH_MODE="no"; shift ;;
      -h|--help) usage; exit 0 ;;
      *)
        if [[ -z "$CHALLENGE" ]]; then
          CHALLENGE="$1"; shift
        else
          echo "Unknown argument: $1" >&2
          usage
          exit 1
        fi
        ;;
    esac
  done

  if [[ -z "$CHALLENGE" ]]; then
    echo "ERROR: challenge name required"
    usage
    exit 1
  fi

  case "$MODE" in
    lin|win|all) : ;;
    *) echo "ERROR: invalid mode '$MODE' (use lin|win|all)"; exit 1 ;;
  esac

  return 0
}

sanity_checks() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "ERROR: must run as root (for exegol/openvpn/docker)" >&2
    exit 1
  fi

  if [[ ! -f "$VPN_PATH" ]]; then
    echo "ERROR: VPN config not found: $VPN_PATH" >&2
    exit 1
  fi
}

init_challenge_dir() {
  CTF="$CHALLENGE"
  CTF_DIR="${BASE_DIR}/${CTF}"
  MD="${CTF_DIR}/${CTF}.md"
  SCRATCH="${CTF_DIR}/s.md"

  if [[ -d "$CTF_DIR" ]]; then
    echo "[*] Resuming challenge directory: $CTF_DIR"
  else
    echo "[*] Creating challenge directory: $CTF_DIR"
  fi

  mkdir -p "$CTF_DIR"
  cd "$CTF_DIR"
  touch "$MD"
  touch "$SCRATCH"

  local editor_user
  editor_user="${SUDO_USER:-kali}"
  if id "$editor_user" >/dev/null 2>&1; then
    chown -R "$editor_user:$editor_user" "$CTF_DIR" 2>/dev/null || true
  fi
}

init_scratch_templates() {
  [[ -s "$SCRATCH" ]] && return 0
  append_if_exists() {
    local src="$1" dst="$2"
    [[ -f "$src" ]] || return 0
    cat "$src" >> "$dst"
  }
  case "$MODE" in
    lin)
      append_if_exists "$LIN_TEMPLATE" "$SCRATCH"
      ;;
    win)
      append_if_exists "$WIN_TEMPLATE" "$SCRATCH"
      ;;
    all)
      append_if_exists "$LIN_TEMPLATE" "$SCRATCH"
      append_if_exists "$WIN_TEMPLATE" "$SCRATCH"
      ;;
  esac
}

write_agents_md() {
  if [[ -f "$AGENTS_TEMPLATE" ]]; then
    cp "$AGENTS_TEMPLATE" "$CTF_DIR"/AGENTS.md
  else
    echo "[!] AGENTS template not found at $AGENTS_TEMPLATE, skipping AGENTS.md copy." >&2
  fi
}

write_notes_bootstrap_once() {
  local marker script_name cmd_str
  marker="<!-- start-ctf-bootstrap -->"
  script_name="$SCRIPT_PATH"
  cmd_str="$(printf '%q ' "$script_name" "${ORIG_ARGS[@]}")"

  if ! grep -Fq "$marker" "$MD" 2>/dev/null; then
    {
      echo "$marker"
      echo '```sh'
      echo
      echo "$cmd_str"
      echo
      echo "/opt/my-resources/bin/ctf.sh --target TARGET_IP"
      echo
      echo "export INTERFACE=VPN_INTERFACE ATTACKER_IP=VPN_IP"
      echo
      echo "/opt/my-resources/bin/hostnamer.sh TARGET_IP CHALLENGE_SLUG"
      echo
      echo '```'
      echo '```js'
      echo
    } >> "$MD"
  fi
}

get_running_vpn_configs() {
  pgrep -a openvpn 2>/dev/null | awk '
    {
      for (i = 2; i <= NF; i++) {
        if ($i ~ /\.ovpn$/) {
          print $i
        }
      }
    }
  ' | sort -u
}

vpn_for_config_running() {
  local cfg="$1"
  get_running_vpn_configs | grep -Fxq "$cfg"
}

start_vpn_if_needed() {
  local running_cfgs ans
  running_cfgs="$(get_running_vpn_configs || true)"

  if [[ -z "$running_cfgs" ]]; then
    echo "[*] No OpenVPN (.ovpn) processes detected. Starting OpenVPN ($VPN_PATH)..."
    openvpn "$VPN_PATH" > /tmp/openvpn.log 2>&1 &
    return 0
  fi

  if vpn_for_config_running "$VPN_PATH"; then
    echo "[*] OpenVPN already running with config: $VPN_PATH"
    return 0
  fi

  echo "[!] Found OpenVPN process(es) using different config(s):"
  echo "$running_cfgs"
  echo "[!] You requested: $VPN_PATH"
  echo "Start another OpenVPN with this config? [y/N]"
  read -r ans || true
  ans="${ans:-N}"
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    echo "[*] Starting additional OpenVPN ($VPN_PATH)..."
    openvpn "$VPN_PATH" > /tmp/openvpn.log 2>&1 &
  else
    echo "[!] Not starting VPN. You may already be on a different lab/tenant."
  fi
}

start_bloodhound_if_enabled() {
  [[ "$BH_MODE" == "yes" ]] || return 0
  if [[ -x /opt/bloodhound/bloodhound-cli ]]; then
    echo "[*] Starting BloodHound containers..."
    /opt/bloodhound/bloodhound-cli containers start || \
      echo "[!] BloodHound start failed (check /opt/bloodhound/bloodhound-cli)." >&2
  else
    echo "[!] BloodHound CLI not found at /opt/bloodhound/bloodhound-cli, skipping." >&2
  fi
}

start_exegol() {
  echo "[*] Starting Exegol instance '$CTF'..."
  exec exegol start "$CTF" "$EXEGOL_IMAGE" -fs -cwd --network host --privileged --device /dev/net/tun --device /dev/fuse --accept-eula
}

main() {
  parse_args "$@"
  sanity_checks
  init_challenge_dir
  init_scratch_templates
  write_agents_md
  write_notes_bootstrap_once
  start_vpn_if_needed
  start_bloodhound_if_enabled
  start_exegol
}

main "$@"
