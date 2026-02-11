#!/usr/bin/env bash
set -euo pipefail

# This script will be executed on the first startup of each new container with the "my-resources" feature enabled.
# Arbitrary code can be added in this file, in order to customize Exegol (dependency installation, configuration file copy, etc).
# It is strongly advised **not** to overwrite the configuration files provided by exegol (e.g. /root/.zshrc, /opt/.exegol_aliases, ...), official updates will not be applied otherwise.
#
# Exegol also features a set of supported customization a user can make.
# The /opt/supported_setups.md file lists the supported configurations that can be made easily.

npm install -g @openai/codex
ln -s /opt/my-resources/setup/.codex /root/
pip install mcp-proxy

useradd -m -G root kali
ln -s /opt/my-resources/setup/BurpSuitePro /home/kali/
ln -s /opt/my-resources/setup/.BurpSuite /home/kali/
ln -s /opt/my-resources/setup/.java /home/kali/

# Conditional: proxychains defaults may vary.
if grep -q '^socks4' /etc/proxychains.conf; then
  sed -i 's/^socks4/socks5/' /etc/proxychains.conf
fi
