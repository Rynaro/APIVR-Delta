# APIVR-Δ — Full Methodology Reference

Evidence-grounded, test-anchored, context-aware feature implementation for brownfield codebases.

**Version**: 3.1.0  
**Entry point**: `agent.md` (always-loaded, ≤1000 tokens)

---

## Cycle

```
A ──▶ P ──▶ I ──▶ V ──┬──▶ Δ (success)
                      └──▶ R ──▶ retry or ESCALATE
```

| Phase | Name | Purpose |
|---|---|---|
| **A** | Analyze | Map codebase, discover assets, define scope |
| **P** | Plan | Score strategies, anchor tests, choose path |
| **I** | Implement | Execute selected strategy |
| **V** | Verify | Run linter, tests, build — collect evidence |
| **Δ** | Delta | Produce normalization suggestions (output only) |
| **R** | Reflect | Classify failure, apply targeted fix or escalate |

---

## Skills Index

Load on-demand. Do NOT front-load all skills.

| Skill | File | When to Load |
|---|---|---|
| Full cycle definition | `skills/methodology.md` | Planning, scoring strategies |
| Context engineering | `skills/context-engineering.md` | Starting Analyze phase |
| Failure recovery | `skills/failure-recovery.md` | Test failure, lint error, build break |
| Memory management | `skills/memory-management.md` | Session start, session end, repeated pattern |

---

## Templates Index

| Template | File | Phase |
|---|---|---|
| Discovery Report | `templates/discovery-report.md` | A — Analyze |
| Execution Plan | `templates/execution-plan.md` | P — Plan |
| Reflect Entry | `templates/reflect-entry.md` | R — Reflect |

---

## Memory

Persistent cross-session state lives in `memories/` (created by the agent, not installed):

| File | Purpose |
|---|---|
| `memories/task-log.md` | Completed tasks + outcomes |
| `memories/pattern-registry.md` | Discovered reusable assets |
| `memories/failure-catalog.md` | Root causes + prevention |
| `memories/delta-history.md` | Improvement suggestions |
| `memories/session-handoff.md` | Incomplete work checkpoint |

---

## Complexity Router

| Tier | Signal | Route |
|---|---|---|
| Trivial | Single file, < 20 lines, no dependencies | Direct implement → verify. Skip Plan. |
| Standard | 1–3 files, known patterns, clear scope | Full APIVR-Δ, 3 strategies minimum |
| Complex | 4+ files, cross-domain, architectural decisions | Full APIVR-Δ + test anchoring + architect/editor split |
| Uncertain | Ambiguous requirements, unknown codebase areas | ESCALATE before Analyze |

---

## Architectural Invariants

| # | Invariant |
|---|---|
| **I-1** | Internal First: USE → EXTEND → WRAP → CREATE |
| **I-2** | Evidence-Based: artifacts over speculation |
| **I-3** | Boundary Respect: explicit approval before scope expansion |
| **I-4** | Test-Anchored: test expectations generated before implementation |
| **I-5** | Escalate Early: 3 failures at same category = STOP |
| **I-6** | Memory-first: query memories/ at start of every task |
| **I-7** | **ECL emit at hand-off boundaries**: Implement-phase exit MUST produce a `apivr-completion-report` envelope sidecar (to IDG). Reflect-phase escalation on 3-failure threshold MUST produce a `repair-failed-report` envelope (to VIGIL). Plan-phase FORGE consultation MUST produce a `reasoning-request` envelope. Templates at `templates/*.envelope.json`. |

## Core Principles

1. **Internal First** — USE → EXTEND → WRAP → CREATE
2. **Evidence-Based** — Artifacts over speculation
3. **Boundary Respect** — Explicit approval before scope expansion
4. **Test-Anchored** — Test expectations generated before implementation
5. **Escalate Early** — 3 failures at same category = STOP

---

## Research Basis

See `docs/PAPER.md` for the full academic paper with 40 cited references, five schools of thought analysis, and design decision rationale.

Key influences: AlphaCodium (flow engineering), SWE-Agent (agent-computer interface), LATS (tree search), Reflexion (episodic reflection), Aider (architect/editor separation), Agentless (hierarchical localization), AgentDebug (failure taxonomy), Claude Code (simple agent loop).

---

## §7 ECL Compatibility

APIVR-Δ v3.1.0 targets **ECL v1.0** (see `ECL_VERSION` at the repo root).

### Emit kinds

| Kind | Phase | Recipient | Performative | Profile schema |
|---|---|---|---|---|
| `apivr-completion-report` | Implement (exit) | IDG | PROPOSE | `schemas/apivr-completion-report-profile.v1.json` |
| `repair-failed-report` | Reflect (3-failure threshold) | VIGIL | ESCALATE | `schemas/repair-failed-report-profile.v1.json` |
| `reasoning-request` | Plan (FORGE consultation) | FORGE | REQUEST | `schemas/_base-profile.v1.json` (base only) |

### Inbound verification (opt-in, warn-only)

When an upstream artefact arrives with a sibling `.envelope.json`, load `skills/verify-incoming.md` to validate schema, integrity, and contract match. Failures are warn-only — payload is always processed.

| Kind | From | Contract |
|---|---|---|
| `scout-report` | ATLAS | `atlas-to-apivr.yaml` |
| `spec` | SPECTRA | `spectra-to-apivr.yaml` |
| `root-cause-report` | VIGIL | `vigil-to-apivr.yaml` |
| `reasoning-report` | FORGE | `forge-to-apivr.yaml` |

### Compatibility window

APIVR-Δ v3.1.0 accepts ECL envelopes matching `^1\.0(\.\d+)?$`. Receivers on VIGIL and FORGE are not yet ECL-adopters; emit is one-way until those Eidolons adopt (see `DESIGN-RATIONALE.md` §Future work).
