---
name: apivr-esl-hop
description: "ESL lifecycle hop — when the cortex routes a non-trivial change to APIVR-Δ in an ESL-enabled project (tonberry MCP available), APIVR-Δ owns the in_progress (implement) hop as the MAKER: declare has_code, run the A→P→I→V→Δ/R cycle, and hand off to a CHECKER on V-phase success (never self-verify). Absent tonberry → run the standard cycle unchanged (ESL opt-in)."
metadata:
  methodology: APIVR-Δ
  phase: V-Verify
---

# APIVR-Δ — ESL Lifecycle Hop

Use this skill in an **ESL-enabled project** (`mcp__tonberry__*` tools available)
when the cortex routes a non-trivial change to you. You own the **implement**
hop of the Eidolons Spec Lifecycle (ESL): you are the **MAKER** at the
`in_progress` stage (`change.json.maker == apivr`).

For the full lifecycle, stage definitions, and role bindings, see the nexus
cortex `methodology/cortex/esl-protocol.md`.

## When to use

Load automatically when the cortex hands you a change in an ESL-enabled
project (`mcp__tonberry__*` tools present) and the change is non-trivial
(right-sized above Kupo/no-spec). Do not use in projects without tonberry —
run your standard A→P→I→V→Δ/R cycle unchanged instead (graceful skip, below).

## Your hop

1. **transition** — call
   `mcp__tonberry__transition --change_id <id> --to_status in_progress --has_code true`.
   Declare `has_code` (it persists by default in tonberry v0.4.0). This advances
   the change from `specify` (SPECTRA's hop, or Kupo's no-spec micro-change for
   a trivial change) into your implement window.
2. **implement** — run your normal **A → P → I → V → Δ/R** cycle
   (`skills/methodology/SKILL.md`) against the spec in the change folder. The
   change's `acceptance_checks` are your test anchors (I-4, anti-overfit;
   derived from the spec, never reverse-engineered from a candidate
   implementation — see Plan-phase Step 1: Test Anchor Generation). Route by
   complexity as usual; TRANCE G4 (`skills/parallel-tracks/SKILL.md`) applies
   unchanged when gated.
3. **hand off to the CHECKER** — on Verify-phase success, you do **NOT**
   self-verify to `verified`. Hand off via ECL **PROPOSE**: **Kupo** for
   localized (≤2-file), named-verifier-backed outcomes (the existing
   `apivr-to-kupo` edge — see `contracts/apivr-to-kupo.yaml`), else **VIGIL**
   or a named external verifier for broader changes. Emit your normal ECL
   envelope (`apivr-completion-report` → success/checker-handoff path;
   `repair-failed-report` → escalation path on the 3-failure threshold — see
   `skills/methodology/SKILL.md` "ECL emit on Implement-phase exit" / "ECL emit on
   3-failure escalation"). Both envelopes carry `ise.assertion_grade:
   "self-attested"` — your own V-phase is self-review, not external
   validation; the checker's fresh-context pass is what actually advances the
   lifecycle. You do **not** advance the change to `verified` yourself.

## Invariants

- **maker(apivr) ≠ checker(kupo/vigil)** — you NEVER self-verify. This is
  mechanically enforced by tonberry's **C4** constraint (`maker_distinct_from_checker`,
  MUST-level: checker identity distinct from `change.json.maker`); **C8**
  (advisory, SHOULD-level) checks that a fresh-context verification attestation
  backs the `verified` transition. Your job ends at green + handoff.
- **Tonberry composes the change record; you provide the implementation +
  signals.** You set `has_code` and produce the implementation; tonberry
  writes the `change.json` status transitions.
- **boundary-respect, evidence-based, escalate-early** — your standard P0
  invariants hold unchanged inside the hop (no out-of-scope edits, no
  speculation, 3-failure-same-category = STOP).
- **Graceful skip** — if `mcp__tonberry__*` tools are unavailable, run your
  standard cycle unchanged and **never hard-fail**. ESL is opt-in; APIVR-Δ is
  EIIS-standalone-conformant and works without tonberry.

---

*APIVR-Δ — ESL Lifecycle Hop (the MAKER at `in_progress`; maker ≠ checker)*
