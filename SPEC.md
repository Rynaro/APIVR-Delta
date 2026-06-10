# APIVR-Δ — Full Methodology Reference

Evidence-grounded, test-anchored, context-aware feature implementation for brownfield codebases.

**Version**: 3.7.1  
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
| Parallel multi-track (G4) | `skills/parallel-tracks.md` | TRANCE-authorized AND Plan yields disjoint-file tracks (see §9) |

---

## Templates Index

| Template | File | Phase |
|---|---|---|
| Discovery Report | `templates/discovery-report.md` | A — Analyze |
| Execution Plan | `templates/execution-plan.md` | P — Plan |
| Reflect Entry | `templates/reflect-entry.md` | R — Reflect |
| Tracks Merge Report | `templates/tracks-merge-report.md` | Merge (G4, §9) |

---

## Memory

APIVR-Δ uses CRYSTALIUM as the primary backing store (see §7). The local
`memories/` files below are the **standalone fallback** for sessions where
CRYSTALIUM is not installed. Never write to both in the same session.

| File | Purpose | CRYSTALIUM equivalent |
|---|---|---|
| `memories/task-log.md` | Completed tasks + outcomes | `commit(layer=episodic)` |
| `memories/pattern-registry.md` | Discovered reusable assets | `commit(layer=procedural)` |
| `memories/failure-catalog.md` | Root causes + prevention | `commit(layer=semantic)` |
| `memories/delta-history.md` | Improvement suggestions | `commit(layer=semantic)` |
| `memories/session-handoff.md` | Incomplete work checkpoint | `plan_checkpoint(state=...)` |

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
| **I-6** | Memory-first: recall via CRYSTALIUM (or local memories/ fallback) at start of every task |
| **I-7** | **ECL emit at hand-off boundaries**: Implement-phase exit MUST produce a `apivr-completion-report` envelope sidecar (to IDG). Reflect-phase escalation on 3-failure threshold MUST produce a `repair-failed-report` envelope (to VIGIL). Plan-phase FORGE consultation MUST produce a `reasoning-request` envelope. Templates at `templates/*.envelope.json`. |
| **I-8** | **Parallel WRITE requires worktree isolation** (TRANCE G4, §9): APIVR-Δ never fans out into a shared tree; each track runs in its own git worktree; max 5 tracks; the per-track reflection budget is non-fungible; and the merge is single-threaded under continuous parent context. Single-track A→P→I→V→Δ/R stays the default — this mode is TRANCE-gated + entry-gated, never default. |

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

## §7 Memory Protocol (CRYSTALIUM)

APIVR-Δ v3.7.1 integrates CRYSTALIUM as the **primary backing store**, with the
local `agents/memories/*.md` Reflexion files as the **standalone fallback** for
when CRYSTALIUM is not installed.

### Model

**CRYSTALIUM-primary / local-fallback.** When `mcp__crystalium__*` tools are
available, all memory reads and writes route through CRYSTALIUM. When absent,
the local Reflexion protocol (`agents/memories/`) is used unchanged. Never
write to both in the same session.

**Trust tier:** T1 (set process-wide via `CRYSTALIUM_CALLER_TIER=T1`).
`provenance.author_agent` MUST be `"apivr"` on every direct `commit` call.

### Phase hooks

| Phase | Hook | Call |
|-------|------|------|
| **A — Analyze** (Step 1) | Memory recall | `recall(layers=[semantic,episodic,procedural], k=8)` |
| **P — Plan** (phase output) | Plan checkpoint | `plan_checkpoint(plan_id, state=<plan snapshot>)` |
| **P — Plan** (mid-cycle abort/replan) | Plan replan | `plan_replan(from_checkpoint_id, new_plan={diff,supersedes_id})` |
| **I — Implement** (before build) | Skill reuse | `skill_invoke(skill_id)` if procedural entry recalled |
| **I — Implement** (new verified pattern) | Procedural commit | `commit(layer=procedural, provenance={author_agent:"apivr"})` |
| **V — Verify** / I-exit | Completion report persist | `ingest(envelope=<apivr-completion-report.envelope.json>, payload)` |
| **Δ/R — Reflect** | Task outcome | `commit(layer=episodic)` outcome + `commit(layer=semantic)` failures + `commit(layer=procedural)` patterns |
| **Δ/R — Reflect** (end) | Session end | `session_end()` → triggers Dream consolidation |
| **verify-incoming** (on receive) | Inbound recall + ingest | `recall(...)` before processing; `ingest(received envelope)` after `verify_pass` |
| **failure-recovery** (R phase) | Failure catalog | `commit(layer=semantic)` root cause/prevention |

### Graceful-skip contract

Every CRYSTALIUM call is wrapped in a graceful-skip: if `mcp__crystalium__*` is
unavailable, fall through to the local-file path silently. Never hard-fail. APIVR-Δ
remains EIIS-standalone-conformant.

### Dream consolidation

`session_end()` triggers Dream asynchronously. Dream handles episodic→semantic
promotion, dedup, and pruning. Do NOT hand-consolidate when CRYSTALIUM is present.

### Reference

Full layer × tier matrix, `plan_checkpoint`/`plan_replan` semantics, and Dream
knobs: `methodology/cortex/memory-protocol.md` (nexus repo). Skill detail:
`skills/memory-management.md`.

---

## §8 ECL Compatibility

APIVR-Δ v3.7.1 targets **ECL v2.0** (see `ECL_VERSION` at the repo root).

### Emit kinds

| Kind | Phase | Recipient | Performative | Profile schema |
|---|---|---|---|---|
| `apivr-completion-report` | Implement (exit) | IDG | PROPOSE | `schemas/apivr-completion-report-profile.v1.json` |
| `repair-failed-report` | Reflect (3-failure threshold) | VIGIL | ESCALATE | `schemas/repair-failed-report-profile.v1.json` |
| `reasoning-request` | Plan (FORGE consultation) | FORGE | REQUEST | `schemas/_base-profile.v1.json` (base only) |

### Inbound verification (blocking, symmetric)

When an upstream artefact arrives with a sibling `.envelope.json`, load `skills/verify-incoming.md` to validate schema, integrity, and contract match. Failures are **blocking** — the payload is NOT processed without a prior `verify_pass`. See ECL §6.2.2.

| Kind | From | Contract |
|---|---|---|
| `scout-report` | ATLAS | `atlas-to-apivr.yaml` |
| `spec` | SPECTRA | `spectra-to-apivr.yaml` |
| `root-cause-report` | VIGIL | `vigil-to-apivr.yaml` |
| `reasoning-report` | FORGE | `forge-to-apivr.yaml` |

### Compatibility window

APIVR-Δ v3.7.1 accepts ECL envelopes matching `^2\.0(\.\d+)?$`. Receivers on VIGIL and FORGE are not yet ECL-adopters; emit is one-way until those Eidolons adopt (see `DESIGN-RATIONALE.md` §Future work).

---

## §9 Parallel Multi-Track Mode (TRANCE G4)

Authoritative description of the TRANCE G4 form. Full procedure: `skills/parallel-tracks.md`.

**Single-track is the default.** The standard A→P→I→V→Δ/R cycle runs for every task. This mode activates ONLY under TRANCE authorization (a complexity flag AND a stakes flag, cortex C6) AND the entry gate below. It is **never** the default — it adds parallelism, not a fresh budget (trance-matrix R3) and not reflection past the published caps (trance-matrix R4). Absent TRANCE gating, APIVR-Δ runs exactly as today.

### Entry gate (refuse unless ALL hold)

| # | Condition |
|---|---|
| G-1 | TRANCE-authorized (complexity flag AND stakes flag, cortex C6). |
| G-2 | Complexity = Complex (4+ files, cross-domain). |
| G-3 | The Plan phase produced N implementation tracks with **disjoint file sets**, verified against the collision map. |
| G-4 | Tracks do NOT share files. Any overlap → the precondition FAILS → fall back to single-track. |

### Mode (bounded)

1. **Fan-out:** max **5** tracks (cortex C1); each in its **own git worktree** (`isolation: worktree` is MANDATORY — never the shared tree, invariant **I-8**); each a clean-context subagent (prevents trajectory contamination); perspective-diverse only where it helps (quality dominates diversity).
2. **Per-track verifier cascade:** each track runs its own Verify (lint → test-anchors → regression) with the anti-overfit and pass^k gates; on pass it emits its existing **`apivr-completion-report`** envelope. **No new ECL kind** — the closed 10-performative set is preserved.
3. **Non-fungible reflection budget:** the ≤3 same-category budget (I-5 / D5 / trance-matrix R4) is **per-worktree**; a track may not borrow another track's retries; a budget-exhausted track is marked **BLOCKED**, excluded from merge, and never silently re-driven.
4. **Stop conditions:** all tracks Verify-pass or Verify-blocked; hard cap 5 tracks; per-track ≤3 retries; no track expands scope into another track's file set (I-3).
5. **Aggregation / merge (single-threaded, mandatory):** dependency-ordered merge of PASSED worktrees under continuous parent context (the write boundary stays single-threaded); run the FULL regression suite **once** post-merge with the pass^k gate; classify cross-track breaks as `INTEGRATION_ERROR`; emit `templates/tracks-merge-report.md`. Unresolved cross-track conflict → escalate to VIGIL via the existing **`repair-failed-report`** envelope (no new kind, no new schema).

### Runtime cap (honest)

The per-track verifier cascade and merge here are **host-interpreted methodology**, not a mechanical runtime. APIVR-Δ does not auto-run the cascade; the parent/host orchestrator executes worktree spin-up + cleanup, the per-track verifier invocations, and the merge. The autonomous edit-run-test loop remains **nexus gap R1** and is out of scope for this repo.

### §9.1 Verification hardening (anti-overfit + pass^k)

The Plan and Verify phases are hardened against the field's named contamination/overfitting failures (see `skills/methodology.md`):

- **Anti-overfit test anchoring** (P-PLAN): test anchors derive from the acceptance criteria + EXISTING test patterns, never reverse-engineered from a candidate implementation (Decision 3 — agents over-fit implementations to tests written in hindsight).
- **Capture-live-first** (P-PLAN): when a track parses external CLI stdout/stderr or serde-renamed IPC, the verbatim live capture MUST be staged as the fixture BEFORE the parser is written (fabricated fixtures pass vacuously).
- **Reliability-under-repetition / pass^k** (V-VERIFY): the post-merge suite (and any test the host can run) is framed pass^k — a track that passes once but is non-deterministic across repeats is **flaky → BLOCKED**, not merged (mirrors the nexus "second install is idempotent" discipline).
