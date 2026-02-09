---
name: burp-mcp
description: Operational playbook for using Burp Suite via MCP tools during CTFs and pentests with minimal context bloat. Use for proxy history triage, endpoint/parameter indexing, sending/validating requests (Repeater-style), scanner issue review, and WebSocket history analysis.
---

# Burp MCP

## Non-negotiables (speed + context hygiene)

- Default to **scope → sample → index → verify**.
- Prefer **artifact-first**: active editor (one message) beats mining lots of history when possible.
- Use **iterative coverage**: start small, but expand proxy history when signal is low or coverage isn’t stable.
- Keep output **index-shaped**: metadata + why-it-matters, not raw bodies.
- Extract **metadata first**, body last: method, host, path, query param *keys*, status, redirect `Location`, `Content-Type`, cookies, auth headers.
- When building URLs/hosts, prefer exported targeting vars from `/workspace/AGENTS.md` (e.g. `$TARGET`, `$DOMAIN`) instead of placeholders.

### Default “coverage protocol” (not a hard limit)

- Start: `count: 10`, `offset: 0` (scoped to one host).
- Expand in chunks: `+10` then `+20` as needed, regenerating the endpoint index each time.
- If you need to pull **>50** items or include bodies, pause and confirm intent (to avoid accidental context blowups).

## Tool selection (what to call first)

- For a specific request/response: user clicks it in Burp → `mcp__burp__get_active_editor_contents`.
- For “what endpoints did we hit?”: `mcp__burp__get_proxy_http_history_regex` scoped to one host.
- For re-validation: `mcp__burp__send_http1_request` / `mcp__burp__send_http2_request`.
- For “any obvious issues?”: `mcp__burp__get_scanner_issues` (then verify individually).
- For WebSockets: `mcp__burp__get_proxy_websocket_history_regex`.

## Artifacts (endpoint index + evidence log)

Maintain one lightweight Markdown file per target host so we don’t re-triage the same leads.

- Location: `/workspace/tmp/burp-mcp/`
- Filename: `<target_slug>.md` where `target_slug` is the `Host` header value with `:` replaced by `_` (e.g. `10.10.10.10_8080.md`).
- Update rules:
  - Before pulling more history, read/update this file so progress stays consistent across turns.
  - Update the file whenever you discover a new endpoint/parameter, auth state, or confirm a behavior.
  - Keep chat output compact; put detailed notes/evidence in the file.
  - Don’t delete/rename prior notes; add new evidence and clearly mark what is confirmed.

Suggested structure (keep it short):
- Scope: host/port, base URL(s)
- Auth state: cookies/JWT present? role/user assumptions?
- Endpoint index: method/path/params/status/signals
- Confirmed behaviors: what is proven true
- Evidence: repeater tab names + 1-line “why”
- Next probes: specific, one request each

## Workflow (CTF/pentest loop)

### 1) Scope to the target

- Constrain to one host (and port if needed) using `mcp__burp__get_proxy_http_history_regex`.
- If you don’t know the host yet: run a tiny “discover host” query, then immediately re-scope.
- See `references/regex.md` for safe scoping patterns.

### 2) Build an endpoint/parameter index (no bodies)

From the sample, summarize a compact table:
- `METHOD` `HOST` `PATH` `STATUS`
- `PARAMS` (keys only; note JSON keys only if already visible in headers/short excerpts)
- `SIGNALS` (redirects, `Set-Cookie`, auth headers, unusual `Content-Type`, error patterns)

Stop paging once the endpoint list stops changing.

### 3) Hunt signals (regex) and expand coverage (paging)

Run focused regex queries to find “interesting things” quickly:
- Auth/cookies/redirects (`Authorization`, `WWW-Authenticate`, `Set-Cookie`, `Location`)
- “Danger” parameters (`file`, `path`, `url`, `redirect`, `next`, `return`, `id`, etc.)
- File-ish artifacts (`.zip`, `.bak`, `.old`, `.swp`, `.sql`, `.log`, etc.)
- API surfaces (`/api`, `/graphql`, `/swagger`, `/openapi`, `/docs`)

If signal is low, expand history coverage using the coverage protocol above and keep updating the endpoint index until it stabilizes (or you’ve found 2–3 viable leads to verify).

### 4) Verify with one request at a time

- Use `mcp__burp__send_http1_request` / `mcp__burp__send_http2_request`.
- Prefer `HEAD` where safe; otherwise `GET`.
- Inspect status + headers first; only read body if needed.
- One hypothesis per request (change one thing, observe one thing).
- When you suspect a vuln class, validate with **one small change** per request.
- Ask before high-impact actions (uploads/exploitation/persistence). Simple validation requests are OK.

### 4a) Evidence workflow (Repeater tabs)

Every time a lead is **confirmed** (not just “interesting”), preserve it and log why:

- Create a Repeater tab with `mcp__burp__create_repeater_tab`.
- Use a consistent `tabName`: `ctf:<host> <vector> <path>` (example: `ctf:10.10.10.10_8080 sqli /search`).
- Add a 1-line entry to the endpoint index file under “Evidence”:
  - `TAB: <tabName> — <why it matters / what it proves>`

### 5) Output discipline (what to report back)

Default output:
- 5–15 line endpoint/param index (no bodies)
- 3–8 “interesting finds” (exact path + why it matters)
- 3–5 next probes (each probe = one specific request)

## Minimal-diff validation (quick checks)

:

- Open redirect: change only the redirect parameter to an external URL; confirm via `Location` header.
- SSRF: change only the URL parameter to a controlled/known URL (or internal IP in a lab); look for timing/status/different errors.
- LFI/RFI: change only the file/path parameter; test traversal patterns and safe file reads (e.g. `/etc/passwd`-style on Linux targets).
- SQLi: change only one parameter; test a boolean flip and watch for stable response differences.
- Authz/IDOR: change only the object identifier (`id`, `uid`, path segment); confirm via status/content deltas without changing auth.

## Notes / gotchas

- Burp MCP history items can be large; keep analysis index-shaped and pull only what you need for the next decision.

## References

- Generic regex patterns and queries: `references/regex.md`
