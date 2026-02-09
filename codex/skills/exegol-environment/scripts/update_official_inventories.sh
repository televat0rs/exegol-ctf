#!/usr/bin/env bash
set -euo pipefail

out_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../references" && pwd)"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1" >&2; exit 1; }
}

need_cmd curl

curl -fsSL -o "${out_dir}/installed_tools_latest_nightly_amd64.csv" "https://docs.exegol.com/installed_tools/lists/latest_nightly_amd64.csv"
curl -fsSL -o "${out_dir}/exegol_resources_list.csv" "https://docs.exegol.com/exegol_resources/resources_list.csv"

echo "Updated:"
echo "- ${out_dir}/installed_tools_latest_nightly_amd64.csv"
echo "- ${out_dir}/exegol_resources_list.csv"
