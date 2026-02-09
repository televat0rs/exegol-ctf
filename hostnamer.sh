#!/usr/bin/env bash
set -euo pipefail

# Host mapping helper for resets and pivots.
# - rewrites the target IP row in /etc/hosts
# - removes stale dotted-name mappings from other rows
# - optionally persists DOMAIN/DC_HOST/DC_IP to profile.sh

ETC_HOSTS="${ETC_HOSTS:-/etc/hosts}"
PROFILE="${PROFILE:-/opt/tools/Exegol-history/profile.sh}"

MODE_DOMAIN="no"     # enabled by -d
MODE_DC="no"         # enabled by -dc (also enables -d)

die() { echo "[hostnamer] $*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage:
  hostnamer.sh <ip> <name> [name...]
  hostnamer.sh <ip> <any.fqdn> -d
  hostnamer.sh <ip> <dc.fqdn> -dc

Behavior:
  - Replaces the existing /etc/hosts line for <ip> (if any) with the names you provide.
  - Removes any of the provided *FQDNs* (names containing a dot) from other IP lines to avoid stale mappings
    after box resets / IP changes.
  - Prints `export ...` lines for the current shell (copy/paste).
  - With -d: infers DOMAIN from the fqdn and persists it to profile.sh.
  - With -dc: sets DC_HOST/DC_IP (and also DOMAIN) and persists them to profile.sh.

Flags:
  -d                   Update DOMAIN (infer from fqdn)
  -dc                  Update DC_HOST/DC_IP and DOMAIN
  -h, --help           Show help
EOF
}

is_ipv4() {
  local ip="$1"
  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  IFS=. read -r a b c d <<<"$ip"
  [[ "$a" -le 255 && "$b" -le 255 && "$c" -le 255 && "$d" -le 255 ]]
}

infer_domain() {
  # host.fqdn -> fqdn suffix; bare domain stays unchanged.
  local fqdn="$1"
  [[ "$fqdn" == *.* ]] || return 1
  local candidate
  candidate="${fqdn#*.}"
  if [[ "$candidate" == *.* ]]; then
    printf '%s' "$candidate"
  else
    printf '%s' "$fqdn"
  fi
}

set_prof_export() {
  local prof="$1" var="$2" val="$3" line tmp
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
  if ! { cat "$tmp" > "$prof"; } 2>/dev/null; then
    rm -f "$tmp"
    return 1
  fi
  rm -f "$tmp"
}

persist_profile() {
  local domain="$1" dc_host="$2" dc_ip="$3"
  [[ -w "$PROFILE" ]] || return 0

  cp -a "$PROFILE" "${PROFILE}.bak.$(date +%s)" 2>/dev/null || true
  [[ -n "$domain" ]] && set_prof_export "$PROFILE" DOMAIN "$domain" || true
  [[ -n "$dc_host" ]] && set_prof_export "$PROFILE" DC_HOST "$dc_host" || true
  [[ -n "$dc_ip" ]] && set_prof_export "$PROFILE" DC_IP "$dc_ip" || true
}

replace_hosts_ip_line() {
  local ip="$1"; shift
  local -a names=("$@")

  [[ -w "$ETC_HOSTS" ]] || die "hosts file not writable: $ETC_HOSTS (run as root?)"

  cp -a "$ETC_HOSTS" "${ETC_HOSTS}.bak.$(date +%s)" 2>/dev/null || true
  local tmp
  tmp="$(mktemp -p /tmp hosts.XXXXXX)"

  # Remove dotted names from other IP rows, case-insensitively.
  rm_str=""
  for n in "${names[@]}"; do
    [[ "$n" == *.* ]] || continue
    rm_str+="${n} "
  done

  awk -v ip="$ip" -v rm_str="$rm_str" -v new_names="${names[*]}" '
    function add_rm(name) {
      if (name == "") return
      rm[tolower(name)] = 1
    }
    BEGIN {
      nrm = split(rm_str, arr, /[[:space:]]+/)
      for (i = 1; i <= nrm; i++) add_rm(arr[i])
    }
    /^[[:space:]]*#/ || NF==0 { print; next }
    {
      # Replace the target IP row with the new names list.
      if ($1 == ip) next

      # Preserve inline comments on surviving rows.
      comment = ""
      hash = index($0, "#")
      if (hash > 0) comment = substr($0, hash)

      out = $1
      kept = 0
      for (i = 2; i <= NF; i++) {
        if ($i ~ /^#/) break
        if (tolower($i) in rm) continue
        out = out " " $i
        kept = 1
      }
      if (kept) {
        if (comment != "" && out !~ /#/) out = out " " comment
        print out
      }
      next
    }
    END {
      print ip "\t" new_names
    }
  ' "$ETC_HOSTS" > "$tmp"

  cat "$tmp" > "$ETC_HOSTS"
  rm -f "$tmp"
}

print_exports() {
  local ip="$1" domain="$2" dc_host="$3" dc_ip="$4"
  printf "export TARGET='%s' IP='%s'\n" "$ip" "$ip"
  [[ "$MODE_DOMAIN" == "yes" ]] && [[ -n "$domain" ]] && printf "export DOMAIN='%s'\n" "$domain"
  if [[ "$MODE_DC" == "yes" ]]; then
    [[ -n "$dc_host" ]] && printf "export DC_HOST='%s'\n" "$dc_host"
    [[ -n "$dc_ip" ]] && printf "export DC_IP='%s'\n" "$dc_ip"
  fi
}

main() {
  pos=()
  for a in "$@"; do
    case "$a" in
      -d) MODE_DOMAIN="yes" ;;
      -dc) MODE_DC="yes"; MODE_DOMAIN="yes" ;;
      -h|--help) usage; exit 0 ;;
      -*)
        die "unknown flag: $a"
        ;;
      *)
        pos+=("$a")
        ;;
    esac
  done

  [[ ${#pos[@]} -ge 2 ]] || { usage; exit 1; }

  ip="${pos[0]}"
  is_ipv4 "$ip" || die "invalid IPv4: $ip"
  names=("${pos[@]:1}")

  domain=""
  dc_host=""
  dc_ip=""

  if [[ "$MODE_DC" == "yes" ]]; then
    dc_host="${names[0]}"
    [[ "$dc_host" == *.* ]] || die "-dc requires a DC FQDN, got: $dc_host"
    short="${dc_host%%.*}"
    names=("$short" "$dc_host" "${names[@]:1}")
    dc_ip="$ip"
    domain="$(infer_domain "$dc_host" || true)"
  elif [[ "$MODE_DOMAIN" == "yes" ]]; then
    fqdn="${names[0]}"
    [[ "$fqdn" == *.* ]] || die "-d requires a FQDN, got: $fqdn"
    domain="$(infer_domain "$fqdn" || true)"
  fi

  # Case-insensitive de-dupe; preserve first spelling/order.
  declare -A seen=()
  deduped=()
  for n in "${names[@]}"; do
    local key
    [[ -n "$n" ]] || continue
    key="$(printf '%s' "$n" | tr '[:upper:]' '[:lower:]')"
    if [[ -z "${seen[$key]+x}" ]]; then
      deduped+=("$n")
      seen["$key"]=1
    fi
  done
  names=("${deduped[@]}")
  [[ ${#names[@]} -gt 0 ]] || die "no names provided"

  replace_hosts_ip_line "$ip" "${names[@]}"
  [[ "$MODE_DOMAIN" == "yes" ]] && persist_profile "$domain" "$dc_host" "$dc_ip"
  print_exports "$ip" "$domain" "$dc_host" "$dc_ip"
}

main "$@"
