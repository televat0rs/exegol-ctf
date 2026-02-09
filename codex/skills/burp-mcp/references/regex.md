## Burp MCP regex snippets (generic)

Use these with `mcp__burp__get_proxy_http_history_regex`.

Tips:
- Add multiline mode `(?m)` when matching headers (`^Header:`).
- Start broad, then tighten: host → method/path → signals.

### Scope by host

- Exact `Host` header (fill in your target): `(?m)^Host: TARGET_HOST(?::TARGET_PORT)?$`
- Any `Host` header (quick target discovery): `(?m)^Host: .+$`
- HTTP/2 authority (sometimes present): `(?m)^:authority: .+$`

### Request line / path filtering

- Request line: `(?m)^(GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS)\\s+/`
- Likely “admin/debug” surfaces: `(?i)\\s/(admin|debug|console|actuator|metrics|health|status|manage)(/|\\s)`
- Docs/API surfaces: `(?i)\\s/(api|graphql|swagger|openapi|docs)(/|\\s)`
- Secrets/metadata files: `(?i)\\s/(\\.env|\\.git/|\\.svn/|server-status|phpinfo\\.php)(\\s|$)`

### Directory indexing signals

- Generic: `(?i)index of\\s*/|autoindex|directory listing`
- Nginx autoindex: `(?i)autoindex\\s+on`

### Artifact/flag hunting

- Flags: `(?i)\\bflag\\b|flag\\.txt|ctf\\{|HTB\\{|THM\\{|picoCTF\\{`
- Backup/artifacts: `(?i)\\.(bak|old|backup|zip|tar|gz|tgz|7z|swp|sql|log)(\\b|$)`

### Parameter hunting

- Common “danger” keys: `(?i)[?&](file|path|page|template|url|uri|dest|redirect|next|return|continue|callback|target|host|domain)=`
- SSRF-ish values: `(?i)[?&](url|uri|dest|redirect|next|callback)=https?%3a%2f%2f|https?://`
- Traversal-ish values: `(?i)[?&](file|path|page|template)=.*(\\.\\./|%2e%2e%2f|%2e%2e%5c)`
- Numeric IDs: `(?i)[?&](id|uid|user_id|account|doc|post|page)=\\d+`

### Response header signals

- Redirects: `(?m)^Location: `
- Set-Cookie: `(?m)^Set-Cookie: `
- Auth: `(?m)^(Authorization|WWW-Authenticate): `
- Content-Type: `(?m)^Content-Type: `

### Error / disclosure signals

- Stack traces / exceptions: `(?i)stack trace|traceback|exception|fatal error|undefined (variable|index)|sql syntax`
