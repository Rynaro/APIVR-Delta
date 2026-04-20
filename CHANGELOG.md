# Changelog

All notable changes to APIVR-Δ are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)  
Versioning: [Semantic Versioning](https://semver.org/)

---

## [Unreleased] — EIIS-1.0 conformance

### Added
- `agent.md` — condensed always-loaded entry point (≤1000 tokens) with installed-path references
- `apivr.md` — full methodology reference and navigation index
- `CLAUDE.md` — Claude Code load-order and consumer usage guide
- `INSTALL.md` — human cross-host installation guide
- `DESIGN-RATIONALE.md` — research-to-decision mapping
- `install.sh` — idempotent installer implementing EIIS §2 interface contract
- `hosts/claude-code.md`, `hosts/copilot.md`, `hosts/cursor.md`, `hosts/opencode.md` — per-host wiring docs
- `evals/canary-missions.md` — five smoke missions covering all phases
- `schemas/install.manifest.v1.json` — JSON Schema draft 2020-12 for install manifest
- `.github/copilot-instructions.md` — Copilot primary entry

### Patched
- `AGENTS.md` — added EIIS §5 YAML frontmatter (name, version, methodology, role, handoffs)

---

## [3.0.0] — 2025-04-17

Initial public release of APIVR-Δ v3.0.

### Added
- Complete APIVR-Δ cycle: Analyze → Plan → Implement → Verify → Delta/Reflect
- Complexity Router (Trivial / Standard / Complex / Uncertain tiers)
- On-demand skill loading (four skill files: apivr-methodology, context-engineering, failure-recovery, memory-management)
- Test-anchored development: test expectations generated before implementation
- Structured failure recovery with failure classification taxonomy
- Structured memory: task-log, pattern-registry, failure-catalog, delta-history, session-handoff
- Progressive disclosure via context-engineering skill
- Architect/Editor separation for Complex-tier tasks
- Escalation protocol with resume context
- Three output templates: Discovery Report, Execution Plan, Reflect Entry
- Academic paper documenting methodology (`docs/PAPER.md`) with 40 cited references

### Changed (from v2.x)
- Context management: added repo mapping, progressive disclosure, budget tracking
- Skill loading: from monolithic to on-demand per phase
- Test strategy: from post-implementation to pre-implementation anchoring
- Failure recovery: from basic retry to classified taxonomy with loop detection
- Memory: from flat file to structured schema with consolidation
- Complexity routing: added Trivial/Standard/Complex/Uncertain router

---

## [2.x] — Prior versions

Not tracked in this changelog.
