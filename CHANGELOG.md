# Changelog

All notable changes to APIVR-Δ are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)  
Versioning: [Semantic Versioning](https://semver.org/)

---

## [3.0.5] - 2026-04-26 — Re-vendor EIIS v1.1 schema (codex enum)

### Fixed
- `schemas/install.manifest.v1.json` re-vendored from EIIS v1.1 — the previously bundled copy lacked `codex` in the `hosts_wired` enum, causing the EIIS conformance checker's M14 (JSON Schema validation) to fail when a validator (`ajv` / `python -m jsonschema`) was on PATH. Pure schema fix; no install.sh behaviour change.
- `examples/install.manifest.json` corrected `mode: rewritten` → `mode: overwritten` to match the EIIS v1.1 enum.

## [3.0.4] — 2026-04-24

### Added
- `EIIS_VERSION` file declaring conformance to EIIS v1.1 (resolves drift D-6).
- OpenAI Codex host wiring (EIIS v1.1 §4.5):
  - `--hosts codex` and `--hosts all` now provision Codex artefacts.
  - `detect_hosts` recognises `.codex/` directories and root `AGENTS.md`-only
    projects as Codex signals.
  - Per-Eidolon Codex subagent file emitted at `.codex/agents/apivr.md` with
    EIIS-conformant YAML frontmatter (`name: apivr`, `description:` covering
    APIVR-Δ's brownfield-implementation role) and a body that mirrors the
    existing Claude Code agent prompt.
  - Marker-bounded `<!-- eidolon:apivr start --> … <!-- eidolon:apivr end -->`
    block written to root `AGENTS.md` whenever `codex` is wired (EIIS §4.1.0
    co-ownership of `AGENTS.md` between `copilot` and `codex`).
  - `install.manifest.json` records `"codex"` in `hosts_wired` and lists
    `AGENTS.md` and `.codex/agents/apivr.md` under `files_written` (§4.5.5.1).
- `examples/install.manifest.json` fixture so the EIIS conformance checker
  can validate manifest shape statically (resolves M0 advisory).

### References
- <https://developers.openai.com/codex/guides/agents-md>
- <https://developers.openai.com/codex/subagents>
- Tracks `Rynaro/eidolons#21` (OpenAI Codex host support).

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
