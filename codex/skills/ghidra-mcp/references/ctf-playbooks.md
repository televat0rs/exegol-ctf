# CTF Playbooks

Use one track at a time based on the strongest signal from triage.

## Track 1: Rev / Crackme

Goal: derive accepted input or bypass validator.

1. Find input surface (`scanf`, `fgets`, `read`, argv usage).
2. Trace input to validator with xrefs.
3. Identify transform step(s): xor/rotate/table/loop/hash/encrypt.
4. Locate compare site and expected target bytes/value.
5. Decide strategy:
   - reverse transform
   - solve constraints externally
   - patch/bypass branch for proof

Success looks like:

- You can explain input -> transform -> compare path with addresses.
- You can generate accepted input or prove a bypass path.

If stuck:

- Pivot from transform function to constants/tables (`read-memory`).
- Re-run with cleaner types/names before deeper logic interpretation.

## Track 2: Crypto-in-Binary

Goal: identify crypto behavior and recover key/plaintext/flag path.

1. Search strings/symbols for crypto indicators.
2. Confirm algorithm by evidence:
   - known constants
   - round counts
   - API calls/imports
3. Trace key origin:
   - hardcoded data
   - derived from input/time/device/env
4. Validate operation mode and reversibility.
5. Reproduce minimal routine externally when faster than full static proving.

Success looks like:

- Algorithm or custom scheme is justified with concrete artifacts.
- Key source is identified or bounded.
- You can decrypt/derive/forge target data.

If stuck:

- Treat as custom transform and model behavior directly from code.
- Hunt decode-before-use points instead of encode sites.

## Track 3: Pwn Prep (Static RE Support)

Goal: produce exploit-ready primitives and offsets from static analysis.

1. Enumerate attacker-controlled inputs and size constraints.
2. Identify unsafe operations (`strcpy`, `sprintf`, unbounded `read`, format use).
3. Map vulnerable buffer adjacency (stack/heap/global).
4. Mark control/data targets:
   - return address
   - function pointers/vtables
   - security flags/counters
5. Document assumptions and what must be validated dynamically.

Success looks like:

- Clear candidate primitive (`overflow`, `format`, `uaf`, etc.) with location.
- Required runtime confirmations are explicit (offsets, canary, leaks, PIE/ASLR impact).

If stuck:

- Switch to "read primitive first" search (information leak path).
- De-prioritize exotic chains; prove one primitive end-to-end.

## Reporting Template (recommended)

- `Finding`: one-line claim
- `Evidence`: function/address + snippet summary
- `Confidence`: high/medium/low
- `Next probe`: exact tool call or external check
- `Fail branch`: immediate alternative if probe fails
