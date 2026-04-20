# GitHub Copilot — APIVR-Δ methodology

> Primary custom-instructions entry for GitHub Copilot. The authoritative
> rule set is `AGENTS.md` at repo root (open standard, loaded by Cursor and
> OpenCode too). This file is a minimal pointer for Copilot hosts that do
> not yet honor AGENTS.md.

## What APIVR-Δ is

APIVR-Δ is a structured agentic coding methodology for evidence-grounded feature
implementation in brownfield codebases. It provides a five-phase cycle, on-demand
skill loading, test-anchored development, complexity routing, and structured failure
recovery — making AI coding assistants reliable partners rather than ad-hoc scribes.

## Non-negotiable rules

1. **Internal First** — Search existing code BEFORE external dependencies. Priority: USE → EXTEND → WRAP → CREATE.
2. **Evidence-Based** — Ground every decision in artifacts: tests, lint output, traces. No speculation.
3. **Boundary Respect** — Never modify files outside declared scope without explicit approval.
4. **Test-Anchored** — Generate expected test cases BEFORE writing implementation code.
5. **Escalate Early** — 3 failed attempts at the same category = STOP. No heroics.

## Phase pipeline

| Phase | Artifact | Skill file |
|---|---|---|
| **A** Analyze | Discovery Report | `skills/context-engineering.md` |
| **P** Plan | Execution Plan with scored strategies | `skills/apivr-methodology.md` |
| **I** Implement | Code changes + new tests | — |
| **V** Verify | Pass/Fail evidence (linter, tests, build) | `skills/failure-recovery.md` |
| **Δ** Delta | Normalization suggestions (output only) | — |
| **R** Reflect | Classified failure + fix or escalation | `skills/failure-recovery.md` |

## Cycle

```
A ──▶ P ──▶ I ──▶ V ──┬──▶ Δ (success)
                      └──▶ R ──▶ retry or ESCALATE
```

## Full spec

`AGENTS.md` — entry point (always loaded)  
`apivr.md` — full methodology reference  
`skills/apivr-methodology.md` — complete cycle definition
