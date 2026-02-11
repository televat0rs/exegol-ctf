---
name: ghidra-mcp
description: Operational playbook for reverse engineering in Ghidra via ReVa MCP during CTFs. Use for binary triage, function/dataflow investigation, decompilation and cross-reference analysis, crypto/key extraction, and exploit-surface mapping for pwn-style challenges.
---

# Ghidra MCP

## Non-negotiables (speed + signal)

- Default to **triage -> hypothesis -> focused depth loop**.
- Keep output **evidence-first**: address, function, claim, confidence.
- Improve the database as you go: rename, retype, comment, bookmark.
- Pull small slices first (20-80 lines/rows), then paginate only when needed.
- One hypothesis per probe; avoid broad "analyze everything" passes.

## Tool naming

- ReVa tools are often exposed as `mcp__ReVa__<tool-name>`.
- Tool names below use canonical names (for example `get-decompilation`, `find-cross-references`).
- If your MCP client wraps names differently, map them once and keep using that mapping.

## Artifact discipline

Keep one lightweight state file per binary:

- Location: `/workspace/tmp/ghidra-mcp/`
- Filename: `<binary_slug>.md` where `binary_slug` is project file name with `/` and `:` replaced by `_`
- Keep it short: scope, key findings, renamed symbols, open questions, next 3-5 probes

## Core workflow

### 1) Scope and program selection

- Confirm active program with `get-current-program`.
- If unclear, use `list-project-files` and pick one target.
- Record architecture/format and challenge goal in the state file.

### 2) Fast triage (breadth, not depth)

- `get-memory-blocks` for section layout and odd permissions.
- `get-strings-count` + paged `get-strings` for high-signal strings.
- `get-symbols-count`/`get-symbols` (`includeExternal=true`) for API surface.
- `get-function-count`/`get-functions` to assess stripped vs named coverage.
- Build 2-3 hypotheses before deep diving.

### 3) Focused depth loop (repeat)

- **Read**: `get-decompilation` (`limit` small, include refs/context), `find-cross-references`.
- **Improve**: `rename-variables`, `change-variable-datatypes`, `set-function-prototype`, `set-comment`.
- **Verify**: re-run `get-decompilation`; confirm readability and behavior improved.
- **Track**: `set-bookmark` (`Analysis`, `TODO`, `Evidence`) for handoff continuity.
- Re-check on-task every 3-5 calls: "Does this answer the challenge objective?"

### 4) CTF solve tracks

- **Rev/general**: trace input -> transform -> compare path, then derive or bypass.
- **Crypto-in-binary**: identify algorithm/pattern, trace key origin, test invertibility.
- **Pwn prep**: map attacker-controlled input, unsafe copies/format usage, control data adjacency.

Detailed probes live in `references/ctf-playbooks.md`.

### 5) Reporting contract

Return:

- Confirmed findings with addresses/functions
- Confidence per claim (high/medium/low)
- Next 3-5 minimal probes (one hypothesis each)
- "Success looks like" for each probe and fallback branch

## Guardrails

- Do not infer algorithm names without concrete indicators (constants, rounds, API calls).
- Do not bulk-pull thousands of rows (strings/functions/xrefs) when paged sampling is enough.
- Do not claim exploitability from one smell; show data/control path evidence.

## References

- Tool call patterns and parameter defaults: `references/tool-recipes.md`
- CTF-focused solve tracks (rev/crypto/pwn): `references/ctf-playbooks.md`
