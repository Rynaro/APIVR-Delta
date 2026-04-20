# APIVR-Δ — Full Methodology Reference

Evidence-grounded, test-anchored, context-aware feature implementation for brownfield codebases.

**Version**: 3.0.0  
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
| Full cycle definition | `skills/apivr-methodology.md` | Planning, scoring strategies |
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
