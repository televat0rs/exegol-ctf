#!/usr/bin/env bash
set -euo pipefail

# Container-side challenge bootstrap.
# - derives target/domain/session context
# - patches notes/agent placeholders and profile exports
# - delegates /etc/hosts updates to hostnamer.sh
# - builds the tmux workspace used during the box

# Resolve default challenge/domain from container hostname.
_default_domain="$(echo "${HOSTNAME:-}" | sed -n 's/^exegol-//p')"
[[ -z "$_default_domain" ]] && _default_domain="ctf.local"

TARGET="${TARGET:-}"
DOMAIN="${DOMAIN:-$_default_domain}"
CHALLENGE_SLUG="${CHALLENGE_SLUG:-}"
INTERFACE="tun0"
SCANS_DIR="${SCANS_DIR:-}"
RECON_DIR="${RECON_DIR:-}"
SCANS_ROOT="${SCANS_ROOT:-/workspace/results}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]
  -t, --target IP        Target host/IP (required)
  -d, --domain NAME      Domain (default: from HOSTNAME sans 'exegol-')
  -h, --help             Show help
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--target) TARGET="$2"; shift 2 ;;
      -d|--domain) DOMAIN="$2"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *) echo "Unknown arg: $1"; usage; exit 1 ;;
    esac
  done

  if [[ -z "$TARGET" ]]; then
    echo "ERROR: --target is required"
    exit 1
  fi

  [[ -z "$CHALLENGE_SLUG" ]] && CHALLENGE_SLUG="$DOMAIN"

  return 0
}

set_attacker_ip() {
  local tun_ip
  tun_ip="$(ip -o -4 addr show "$INTERFACE" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 || true)"
  ATTACKER_IP="${tun_ip:-127.0.0.1}"
  if [[ -z "${tun_ip:-}" ]]; then
    echo "[!] VPN ($INTERFACE) not active. Press Enter to continue, any other key to abort."
    read -r resp || true
    if [[ -n "${resp:-}" ]]; then
      echo "Aborting."
      exit 1
    fi
  fi

  return 0
}

fix_kali_gid() {
  local current_1000_group
  current_1000_group="$(getent group 1000 | cut -d: -f1 || true)"
  if [[ -n "$current_1000_group" && "$current_1000_group" != "kali" ]]; then
    echo "[!] GID 1000 currently owned by group '$current_1000_group', moving it to 1002 for 'kali'" >&2
    groupmod -g 1002 "$current_1000_group" || echo "[!] Failed to move group '$current_1000_group' to 1002" >&2
  fi

  if [[ "$(getent group kali | cut -d: -f3 || true)" != "1000" ]]; then
    groupmod -g 1000 kali || echo "[!] Failed to set group 'kali' to GID 1000" >&2
  fi

  if [[ "$(id -g kali 2>/dev/null || echo)" != "1000" ]]; then
    usermod -g 1000 kali || echo "[!] Failed to set user 'kali' primary GID to 1000" >&2
  fi
}

fix_workspace_perms() {
  chown -R :kali /workspace
  chmod -R g+rwX /workspace
  chmod g+s /workspace
}

derive_context() {
  if [[ -z "$SCANS_DIR" ]]; then
    SCANS_DIR="${SCANS_ROOT}/${CHALLENGE_SLUG}/scans"
  fi
  [[ -z "$RECON_DIR" ]] && RECON_DIR="$SCANS_DIR"

  DC_IP="${DC_IP:-$TARGET}"
  IP="${IP:-$TARGET}"

  export TARGET DOMAIN CHALLENGE_SLUG ATTACKER_IP INTERFACE SCANS_ROOT SCANS_DIR RECON_DIR DC_IP IP HOSTNAME
}

sed_escape_repl() {
  printf '%s' "$1" | sed -e 's/[&|\\]/\\&/g'
}

prepare_replacement_values() {
  SED_VPN_IP="$(sed_escape_repl "$ATTACKER_IP")"
  SED_DOMAIN="$(sed_escape_repl "$DOMAIN")"
  SED_CHALLENGE_SLUG="$(sed_escape_repl "$CHALLENGE_SLUG")"
  SED_TARGET="$(sed_escape_repl "$TARGET")"
  SED_INTERFACE="$(sed_escape_repl "$INTERFACE")"
  SED_SCANS_ROOT="$(sed_escape_repl "$SCANS_ROOT")"
  SED_SCANS_DIR="$(sed_escape_repl "$SCANS_DIR")"
}

replace_placeholders() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  [[ -w "$file" ]] || return 0

  sed -i \
    -e "s|VPN_IP|${SED_VPN_IP}|g" \
    -e "s|CHALLENGE_SLUG|${SED_CHALLENGE_SLUG}|g" \
    -e "s|DOMAIN_SLUG|${SED_DOMAIN}|g" \
    -e "s|TARGET_IP|${SED_TARGET}|g" \
    -e "s|VPN_INTERFACE|${SED_INTERFACE}|g" \
    -e "s|SCANS_ROOT|${SED_SCANS_ROOT}|g" \
    -e "s|SCANS_DIR|${SED_SCANS_DIR}|g" \
    "$file"
}

notes_and_scratch_paths() {
  ws="/workspace"; mkdir -p "$ws"
  mkdir -p "$ws/tmp/$CHALLENGE_SLUG" "$ws/tmp/burp-mcp"
  md="$ws/${CHALLENGE_SLUG}.md"
  s="$ws/s.md"

  state_md="$ws/tmp/$CHALLENGE_SLUG/${TARGET//:/_}.md"
  touch "$state_md" 2>/dev/null || true
}

update_hosts_update_ip() {
  local script_dir hostnamer
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  hostnamer="${HOSTNAMER:-$script_dir/hostnamer.sh}"
  [[ -x "$hostnamer" ]] || hostnamer="/opt/my-resources/bin/hostnamer.sh"

  if [[ -x "$hostnamer" ]]; then
    "$hostnamer" "$TARGET" "$DOMAIN" >/dev/null
    return 0
  fi

  echo "[!] hostnamer.sh not found/executable; skipping /etc/hosts update." >&2
}

patch_profile() {
  local prof="/opt/tools/Exegol-history/profile.sh"
  [[ -w "$prof" ]] || return 0

  cp -a "$prof" "${prof}.bak.$(date +%s)" 2>/dev/null || true

  set_prof_export() {
    local var="$1" val="$2" line tmp
    line="export ${var}='${val}'"
    tmp="$(mktemp -p /tmp profile.XXXXXX)"

    awk -v var="$var" -v line="$line" '
      BEGIN { found=0 }
      {
        if ($0 ~ "^[[:space:]]*#?export[[:space:]]+" var "=") { print line; found=1; next }
        print
      }
      END { if (!found) { print ""; print line } }
    ' "$prof" > "$tmp"

    cat "$tmp" > "$prof" 2>/dev/null || true
    rm -f "$tmp"
  }

  set_prof_export INTERFACE   "$INTERFACE"
  set_prof_export DOMAIN      "$DOMAIN"
  set_prof_export CHALLENGE_SLUG "$CHALLENGE_SLUG"
  set_prof_export TARGET      "$TARGET"
  set_prof_export DC_IP       "$TARGET"
  set_prof_export IP          "$TARGET"
  set_prof_export ATTACKER_IP "$ATTACKER_IP"

  if ! grep -q 'umask 0002' "$prof"; then
    printf "\numask 0002\n" >> "$prof"
  fi
}

main() {
  parse_args "$@"
  set_attacker_ip
  fix_kali_gid
  fix_workspace_perms
  derive_context
  prepare_replacement_values

  notes_and_scratch_paths
  update_hosts_update_ip

  replace_placeholders "$md"
  replace_placeholders "$s"
  replace_placeholders "$ws/AGENTS.md"
  patch_profile
}

main "$@"

# tmux workspace
TMUX_SESSION="${TMUX_SESSION:-$(date +%H-%M)}"
if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
  tmux attach-session -t "$TMUX_SESSION"
  exit 0
fi

tmux new-session -d -s "$TMUX_SESSION" -x- -y-

# window: config
tmux rename-window -t "$TMUX_SESSION:0" "config"
sleep 1
tmux split-window -h -l 127 -t "$TMUX_SESSION:config.0"
sleep 1
tmux split-window -v -l 60 -t "$TMUX_SESSION:config.0"
sleep 1
tmux split-window -v -l 60 -t "$TMUX_SESSION:config.2"
sleep 1
tmux send-keys -t "$TMUX_SESSION:config.0" "cd /opt/resources && http-server 6789" C-m
tmux send-keys -t "$TMUX_SESSION:config.1" "cd /opt/resources && l /opt/resources/windows && l /opt/resources/linux" C-m
tmux send-keys -t "$TMUX_SESSION:config.2" "sudo -u kali /home/kali/BurpSuitePro/BurpSuitePro --config-file=/home/kali/.BurpSuite/ProjectConfigPro.json --user-config-file=/home/kali/.BurpSuite/UserConfigPro.json --project-file=/home/kali/$HOSTNAME.burp" C-m
tmux send-keys -t "$TMUX_SESSION:config.3" "tail /etc/hosts" C-m
tmux send-keys -t "$TMUX_SESSION:config.3" "vi /etc/hosts"

# window: recon
tmux new-window -t "$TMUX_SESSION" -n recon
sleep 1
tmux split-window -h -l 66 -t "$TMUX_SESSION:recon.0"
sleep 1
tmux send-keys -t "$TMUX_SESSION:recon.0" "autorecon --only-scans-dir --no-port-dirs --dirbuster.threads 99 --dirbuster.wordlist /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-small.txt --subdomain-enum.threads 99 --subdomain-enum.wordlist /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt --vhost-enum.threads 99 --vhost-enum.wordlist /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -vvv $DOMAIN" C-m
sleep 1
tmux send-keys -t "$TMUX_SESSION:recon.1" 'tree -h /workspace/results; grep -RH "\.$DOMAIN" /workspace/results; grep -RH "\@$DOMAIN" /workspace/results'

# window: main ops
tmux new-window -t "$TMUX_SESSION"
sleep 1
tmux split-window -h -l 72 -t "$TMUX_SESSION:2.0"
sleep 1
tmux split-window -v -l 6 -t "$TMUX_SESSION:2.0"
sleep 1
tmux split-window -v -l 6 -t "$TMUX_SESSION:2.2"
sleep 1
tmux send-keys -t "$TMUX_SESSION:2.0" "#export HTTP_PROXY=http://127.0.0.1:8080 HTTPS_PROXY=http://127.0.0.1:8080 http_proxy=http://127.0.0.1:8080 https_proxy=http://127.0.0.1:8080" C-m
tmux send-keys -t "$TMUX_SESSION:2.1" "rlwrap nc -lvnp 1337" C-m
tmux send-keys -t "$TMUX_SESSION:2.2" "#export HTTP_PROXY=http://127.0.0.1:8080 HTTPS_PROXY=http://127.0.0.1:8080 http_proxy=http://127.0.0.1:8080 https_proxy=http://127.0.0.1:8080" C-m
tmux send-keys -t "$TMUX_SESSION:2.3" "http-put-server 80" C-m

# window: codex
tmux new-window -t "$TMUX_SESSION" -n codex
sleep 1
tmux send-keys -t "$TMUX_SESSION:codex.0" "codex" C-m

# focus recon output pane
tmux select-window -t "$TMUX_SESSION:recon"
tmux select-pane -t "$TMUX_SESSION:recon.1"

# attach session
tmux attach-session -t "$TMUX_SESSION"
