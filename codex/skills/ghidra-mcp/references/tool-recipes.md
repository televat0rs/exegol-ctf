# Tool Recipes

Use this as a fast parameter guide for common ReVa MCP calls.

## Program and project

- `get-current-program`
  - Use first in assistant mode to verify scope.
- `list-project-files`
  - Use when multiple binaries are loaded or path is unclear.
- `import-file`
  - Use in headless mode to bring a new binary into the project.

## Survey calls (triage)

- `get-memory-blocks`
  - Find executable/writable section anomalies quickly.
- `get-strings-count` -> `get-strings`
  - Page strings in chunks of 100-200.
- `get-symbols-count` / `get-symbols`
  - Use `includeExternal=true` to surface imported APIs.
- `get-function-count` / `get-functions`
  - Compare named vs total to estimate stripped state.

## Deep analysis calls

- `get-decompilation`
  - Start with:
    - `limit=30-60`
    - `offset=1` then paginate
    - `includeIncomingReferences=true`
    - `includeReferenceContext=true`
- `find-cross-references`
  - Use `direction="to"` for "who uses this"
  - Use `direction="from"` for "what this touches"
  - Keep `includeContext=true`
- `search-decompilation`
  - Use for quick global pivots (API names, constants, pattern snippets).
- `search-strings-regex`
  - Use for URL/IP/crypto/input markers before deep function dives.
- `get-data` / `read-memory`
  - Use for tables, constants, structs, and encoded blobs.

## Database improvement calls

- `rename-variables`
  - Rename only when behavior is evidenced.
- `change-variable-datatypes`
  - Use operation/API usage to justify type changes.
- `set-function-prototype`
  - Lock in parameter and return intent once stable.
- `apply-data-type` / `apply-structure`
  - Apply when repeated field access patterns are clear.
- `set-decompilation-comment` / `set-comment`
  - Capture why, not what.
- `set-bookmark`
  - Suggested categories: `Analysis`, `TODO`, `Evidence`, `Assumption`.
- `checkin-program`
  - Use after a meaningful set of naming/type updates.

## Practical defaults

- Decompilation windows: 30-60 lines per call.
- Strings/functions pages: 100-200 rows.
- Xref context lines: low single digits unless signal is weak.
- Investigate one hypothesis at a time; avoid parallel branch churn.
