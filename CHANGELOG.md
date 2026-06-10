# Changelog

All notable changes to APIVR-Δ are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)  
Versioning: [Semantic Versioning](https://semver.org/)

---

## [Unreleased]

---

## [3.7.0] — 2026-06-10 — Version-stamp hygiene + canonical skill template

### Changed
- Version stamps swept to 3.7.0 across all canonical homes: `install.sh` `EIDOLON_VERSION`, `AGENTS.md` frontmatter `version:`, `SPEC.md` header and §7/§8 self-references, `README.md` title (unversioned; version now in a single explicit badge line).
- `AGENTS.md`: `methodology_version:` removed per D1 (drift surface; nothing reads it); cycle heading unversioned (`## APIVR-Δ Cycle`).
- `agent.md`: cycle heading unversioned (`## APIVR-Δ Cycle`).
- All 6 skills (`context-engineering`, `failure-recovery`, `memory-management`, `methodology`, `parallel-tracks`, `verify-incoming`) normalized to canonical D2 frontmatter: `name` + `description` (single physical line) + `metadata: {methodology, phase}`; `methodology_version` removed.
- All skills now have a `## When to use` section (minimal addition; bodies preserved verbatim).
- `skills/methodology.md`: H1 unversioned (`# APIVR-Δ Methodology`); footer unversioned.
- Trace event version placeholders in `skills/verify-incoming.md`: `apivr@3.4` → `apivr@<version>` per D1 (no release-version strings in skill bodies).
- `templates/*.envelope.json` (3 files): `from.version` `3.1.0` → `3.7.0`.
- `templates/inbound/*.fixture.json` (4 files): `to.version` `3.1.0` → `3.7.0`.
- `tests/helpers.bash`: default eidolon_version `3.1.0` → `3.7.0`; fixture `to.version` updated.
- `tests/install.bats`: header comment + test name + grep target `3.5.0` → `3.7.0`.
- `tests/emit-completion-report.bats`: fixture version `3.1.0` → `3.7.0`.
- `tests/verify-incoming.bats`: `methodology_version: "3.4"` assertion re-targeted to `metadata.methodology: APIVR-Δ` (D2 contract change).
- All 8 schemas: `$id` URLs `/v3.1.0/` → `/v3.7.0/`.
- `examples/install.manifest.json`: version `3.3.0` → `3.7.0`; added missing `parallel-tracks` skill entry + `tracks-merge-report.md` template entry (EIIS I5 compliance).

### Fixed (content)
- `SPEC.md §8`, `CLAUDE.md`, and `skills/context-engineering.md`: verify-incoming posture was described as "opt-in, warn-only — payload is always processed" — corrected to **blocking** (matching the shipped skill and ECL §6.2.2). ECL version numbers in same sentences left verbatim (ecosystem-coordinated V3 item).

### Not changed (out of scope)
- `install.sh:8 ECL_VERSION_VAL="1.0"`, `ECL_VERSION` file, envelope_version values, "ECL v1.0" prose in `agent.md`/`CLAUDE.md` — ecosystem-coordinated V3 item, deliberately untouched.

---

## [3.6.0] — 2026-06-05 — Blocking symmetric verify-incoming gate (ECL §6.2.2)

### Changed
- `skills/verify-incoming.md` replaced (warn-only → **blocking, symmetric**):
  ECL §6.2.2 compliance. The skill now mandates REFUSE on any integrity or
  contract failure; the payload is **never** processed without a prior
  `verify_pass`. The orchestrator runs the mechanical SHA-256 gate
  (`eidolons verify-envelope --block`) and records the trace event before
  dispatching APIVR-Δ; the receiver enforces the result using only `Read`.
  `methodology_version` bumped from `3.1` → `3.4` (aligns with newest skill).
- `tests/verify-incoming.bats` rewritten to assert the blocking posture:
  old warn-only assertions removed; new assertions verify REFUSE semantics,
  `decision: refused` in trace events, absence of "payload is always
  processed" / "warn-only" language, and install-run manifest coverage.

---

## [3.5.0] — 2026-06-03 — Parallel multi-track mode (TRANCE G4)

### Added
- `skills/parallel-tracks.md` (new flat skill, `apivr-parallel-tracks`):
  operationalizes the TRANCE G4 form — parallel multi-track implementation in
  **mandatory** git-worktree isolation, max 5 clean-context tracks (cortex C1),
  a per-track verifier cascade reusing the existing `apivr-completion-report`
  envelope, a non-fungible per-track ≤3 reflection budget (D5 / trance-matrix
  R3+R4), explicit stop conditions, and a single-threaded merge/aggregation
  step. **TRANCE-gated, never default**; single-track A→P→I→V→Δ/R stays the
  default.
- `templates/tracks-merge-report.md`: aggregation artifact for the merge step
  (per-track verdicts, merge order, conflicts resolved, post-merge pass^k suite
  result, blocked-track disposition). Markdown template, **not** a new ECL kind
  — preserves the closed 10-performative set.
- `SPEC.md §9` "Parallel Multi-Track Mode (TRANCE G4)" + §9.1 verification
  hardening, and new Architectural Invariant **I-8** (parallel WRITE requires
  worktree isolation; merge is single-threaded under continuous parent context).
- `evals/canary-missions.md`: new `parallel-tracks` DSL mission.

### Changed
- `skills/methodology.md`: P-PLAN test-anchoring hardened against overfitting
  (anchors from acceptance criteria + existing patterns, never reverse-engineered
  from a candidate impl; capture-live-before-parsing gate); V-VERIFY adds a
  pass^k reliability-under-repetition gate that marks non-deterministic tracks
  flaky/BLOCKED rather than advancing. Skills Index lists `parallel-tracks`
  (via SPEC.md §9).
- `skills/failure-recovery.md`: Retry Decision Matrix + Loop Detection extended
  for multi-track mode — per-track budget non-fungibility, cross-track
  `INTEGRATION_ERROR` classification, and VIGIL escalation via the existing
  `repair-failed-report` contract.
- `DESIGN-RATIONALE.md`: Decision 7 (parallel multi-track = worktree-isolated,
  bounded, TRANCE-gated) with research→decision mapping (R1-01 / R4-08 / R1-02 /
  R3-06 / R6-F08); the "Multi-agent orchestration" non-decision is **amended**
  (single-track remains the default) rather than removed. Notes the
  host-interpreted / nexus-R1 runtime cap explicitly.
- `install.sh`: registers `parallel-tracks` (wire_skill + add_fw + add_skill)
  and `tracks-merge-report.md` (add_fw) so the canonical-inventory sweep
  whitelists them.
- `tests/install.bats`: existence assertions for the new skill and template.
- Release-version stamps normalized to `3.5.0` (fixing pre-existing drift):
  `install.sh` `EIDOLON_VERSION` `3.4.0` → `3.5.0`; `SPEC.md` version header
  and §7/§8 self-references `3.4.0` → `3.5.0`; `AGENTS.md` frontmatter
  `version` / `methodology_version` `3.1.0` → `3.5.0`. Corrected the stale
  `tests/install.bats` `EIDOLON_VERSION` assertion (header comment, test name,
  and grep) from `3.2.0` to `3.5.0` so the gate matches `install.sh`. ECL
  (`2.0`), EIIS (`1.4`), JSON-Schema (`1.0`/`1.5.0`), and canary DSL versions
  are deliberately untouched.

> Scope note: the verifier cascade described here is host-interpreted
> methodology, not a mechanical runtime. The autonomous edit-run-test loop
> remains nexus gap R1 and is out of scope for this repo.

## [3.4.0] — 2026-06-02 — CRYSTALIUM memory pipeline

### Added
- `skills/memory-management.md` rewritten: CRYSTALIUM-primary / local-file-fallback
  model. When `mcp__crystalium__*` tools are available, all memory routes through
  CRYSTALIUM (`recall`, `commit`, `ingest`, `plan_checkpoint`, `plan_replan`,
  `skill_invoke`, `session_end`). Local `agents/memories/*.md` Reflexion files
  are the standalone fallback (EIIS conformance). Never both in the same session.
  `provenance.author_agent` is `"apivr"` on all direct commits.
- `skills/methodology.md` — phase hooks wired:
  - **A-ANALYZE Step 1**: `mcp__crystalium__recall(layers=[semantic,episodic,procedural], k=8)`;
    local-file path when absent.
  - **P-PLAN** (phase output): `mcp__crystalium__plan_checkpoint(plan_id, state=<plan snapshot>)`;
    `plan_replan` on mid-cycle abort/replan.
  - **I-IMPLEMENT** (before build): `mcp__crystalium__skill_invoke` if procedural
    entry recalled; `commit(layer=procedural)` for new verified skills.
  - **V-VERIFY** / I-exit: `mcp__crystalium__ingest(envelope, payload)` for the
    `apivr-completion-report` ECL envelope — records handoff at T1.
  - **Δ/R — Post-task**: `commit(layer=episodic)` outcome + `commit(layer=semantic)`
    failures + `commit(layer=procedural)` patterns; `session_end()` → Dream.
- `skills/verify-incoming.md` — recall related context before processing an
  inbound handoff; ingest the received envelope after `verify_pass`.
- `skills/failure-recovery.md` — failure-catalog writes route to
  `commit(layer=semantic)` when CRYSTALIUM present; cross-reference to
  memory-management.md for routing decision.
- `agent.md` — memory pre-flight note at mission intake (CRYSTALIUM recall →
  local-file fallback); pointer to full protocol in memory-management.md.
- `SPEC.md §7` — "Memory Protocol (CRYSTALIUM)" section: primary/fallback model,
  full phase-hook table, graceful-skip contract, Dream, pointer to cortex
  memory-protocol.md.
- `evals/canary-missions.md` — new `memory-round-trip` mission: asserts recall at
  Analyze, plan_checkpoint at Plan, ingest at Verify (author_agent=apivr, T1),
  Reflect commits + session_end, and CRYSTALIUM-absent → local-file fallback.

### Changed
- `install.sh`: `EIDOLON_VERSION` bumped `3.3.1` → `3.4.0` (MINOR — additive
  memory pipeline; ECL_VERSION/EIIS_VERSION unchanged).
- `SPEC.md`: version footer updated to `3.4.0`; Memory table updated to show
  CRYSTALIUM equivalent for each local file; I-6 invariant updated to
  reference CRYSTALIUM-primary.
- Methodology version in skill frontmatter: `memory-management.md` → `3.4`.

### Compliance
- Graceful-skip contract: every CRYSTALIUM call is silently skipped when
  `mcp__crystalium__*` unavailable. EIIS standalone conformance preserved.
- ECL_VERSION (2.0) and EIIS_VERSION (1.4) unchanged.
- Bash 3.2 floor preserved in `install.sh` (no new shell features introduced).

## [3.3.1] — 2026-05-27

- Patch: migrate evals/canary-missions.md to nexus v1.13.0 DSL format (smoke-default + plan-routing missions). Legacy free-form catalog preserved.

## [3.3.0] — 2026-05-26 — EIIS v1.4 canonical inventory conformance

### Changed
- Declares EIIS v1.4 conformance (`EIIS_VERSION = 1.4`).
- `.claude/agents/apivr.md` heredoc rewritten per EIIS v1.4 §4.2.6: references
  both `./.eidolons/apivr/agent.md` (P0 rules) and `./.eidolons/apivr/SPEC.md`
  (full spec); legacy `apivr.md` reference removed; adds `model: sonnet`.
- `agent.md` role in `files_written[]` changed: `entry-point` → `agent-profile`
  (EIIS v1.4 §1.8.6).
- `ECL_VERSION` role in `files_written[]` changed: `other` → `ecl-version`
  (EIIS v1.4 §3.7.1).

### Added
- `canonical_inventory_sweep()` helper in `install.sh`: manifest-driven sweep
  removes any file under `<target>/` not in the current `files_written[]` allow-set
  (EIIS v1.4 §6.X). Called after all writes, before manifest finalisation.
  Belt-and-braces with the existing early `cleanup_legacy_v1_2` call.
- `FILES_WRITTEN_PATHS` indexed array in `install.sh` (bash 3.2 compatible):
  tracks target-relative paths written this run for use by the sweep.
- `schemas/install.manifest.v1.json` is now explicitly tracked in `files_written[]`
  with `role: "other"` (was written to disk but not recorded in previous versions).
- Manifest field `canonical_inventory_strict: true` (EIIS v1.4 §2.3).
- Schema: `role` enum extended with `"agent-profile"` and `"ecl-version"` values.
- Schema: `canonical_inventory_strict` optional boolean field added.

### Compliance
- `EIIS_VERSION` bumped from `1.3` to `1.4`.

## [3.2.1] — 2026-05-26

### Fixed
- `install.sh` now sweeps legacy v1.2-era artefacts on upgrade: removes stale
  `<TARGET>/apivr.md` and any `<TARGET>/skills/{context-engineering,failure-recovery,memory-management,methodology,verify-incoming}/`
  subdir trees left behind by pre-v1.3 installs. Fresh installs are unaffected
  (every guard short-circuits on a clean target).

## [3.2.0] — 2026-05-25 — EIIS v1.3 install layout normalization

### Changed
- BREAKING: full-spec destination renamed `apivr.md` → `SPEC.md` (EIIS v1.3 §1.8). Source file also renamed.
- BREAKING: skills layout flattened from `skills/<skill>/SKILL.md` (subdir) to `skills/<skill>.md` (flat). Vendor copies at `.claude/skills/apivr-<skill>/SKILL.md` unchanged.
- Skill slug `apivr-methodology` source corrected to `methodology.md` (vendor path `apivr-methodology/SKILL.md` unchanged for host compatibility).
- `install.sh`: `EIDOLON_VERSION` bumped `3.1.2` → `3.2.0` (MINOR — layout breaking change).
- `agent.md`: skill path `apivr-methodology.md` → `methodology.md`; `verify-incoming/SKILL.md` → `verify-incoming.md`; spec ref `apivr.md` → `SPEC.md`.
- `CLAUDE.md`: updated load order to reflect renamed files.

### Fixed
- Manifest entries for skills now record the on-disk paths with correct SHA-256 (was recording flat paths that did not exist, producing `00000000` SHAs — FINDING-A02/GAP-2).
- `agent.md` skill path references now resolve to actual installed files.

### Added
- Manifest now includes `spec_file` field (`.eidolons/apivr/SPEC.md`) per EIIS v1.3 §1.8.
- Manifest now includes `skills[]` array with dual-write records per EIIS v1.3 §4.2.4.
- `EIDOLON_SLUG` variable in `install.sh` for `wire_skill` helper.

### Compliance
- `EIIS_VERSION` bumped from `1.1` to `1.3`.

## [3.1.2] — 2026-05-13 — declare ECL v2.0 conformance

### Changed
- `ECL_VERSION` file: `1.2` → `2.0`. Targets ECL v2.0 spec
  (`Rynaro/eidolons-ecl@v2.0.0`, spec/ecl-2.0.md introduces ISE trust hierarchy).
  Declaration-only patch bump; no behaviour change.
- `AGENTS.md` frontmatter: `comm.envelope_version` `"1.2"` → `"2.0"`.
- `install.sh`: `EIDOLON_VERSION` `3.1.1` → `3.1.2` (PATCH bump —
  declaration-only change; no behaviour change, no schema change,
  no envelope-shape change).

### Notes
- APIVR-Δ emit envelopes remain byte-compatible with ECL v2.0 (backward-
  compatible per ECL §7.3 — 12-month window through 2027-05-13).
- Companion patches: ATLAS v1.5.2 ✓ merged; SPECTRA v4.3.2 ✓ in flight;
  IDG, FORGE, VIGIL follow. All six Eidolons bump per ECL v2.0.0 publication.

## [3.1.1] — 2026-05-12 — Declare ECL v1.2 conformance

### Changed
- `ECL_VERSION` file: `1.0` → `1.2`. Targets the latest ECL spec
  (`Rynaro/eidolons-ecl@v1.2.0`); APIVR-Δ's emit envelopes remain
  byte-compatible (v1.2 is backward-compatible with v1.0 per ECL §1.1.1).
- `AGENTS.md` frontmatter: `comm.envelope_version` `"1.0"` → `"1.2"`.
- `install.sh`: `EIDOLON_VERSION` `3.1.0` → `3.1.1` (PATCH bump —
  declaration-only change; no behaviour change).

### Notes
- No envelope-format changes. v1.0 envelopes already emitted by older
  APIVR-Δ releases are valid under v1.2 conformance.
- The `repair-failed-report` envelope (apivr → vigil) is `trust_level=high`
  per `apivr-to-vigil.yaml`. Worked-example smoke tests should use
  `--integrity-method hmac-sha256` + `ECL_HMAC_KEY` per ECL v1.1 gate
  I-5 SHOULD recommendation. The apivr-vigil escalation worked example
  in `eidolons-ecl@v1.1.0` already migrated to HMAC.
- `verify-incoming` continues to accept `sha256` envelopes from upstream
  (ATLAS, SPECTRA, VIGIL, FORGE) without warn-mode failure — warn-only
  semantics preserved.

## [3.1.0] - 2026-05-08 — ECL v1.0 emission adoption

### Added
- `ECL_VERSION` declaring conformance to ECL v1.0 (`Rynaro/eidolons-ecl@v1.0.0`).
- Vendored profile schemas for the three emit kinds and four inbound kinds:
  - `schemas/_base-profile.v1.json` (vendored unchanged)
  - `schemas/apivr-completion-report-profile.v1.json` (emit, to IDG)
  - `schemas/repair-failed-report-profile.v1.json` (emit, to VIGIL on 3-failure escalation)
  - `schemas/scout-report-profile.v1.json`, `schemas/spec-profile.v1.json`, `schemas/root-cause-report-profile.v1.json`, `schemas/reasoning-report-profile.v1.json` (inbound verification)
- Vendored envelope schema `schemas/ecl-envelope.v1.json` with the performative enum **inlined** at both call sites (matches ATLAS v1.5.0 precedent).
- Three emit envelope templates under `templates/`: `apivr-completion-report.envelope.json` (PROPOSE → IDG), `repair-failed-report.envelope.json` (ESCALATE → VIGIL, `assumptions[0]="trigger: 3-failure-same-category"`), `reasoning-request.envelope.json` (REQUEST → FORGE).
- Four inbound smoke fixtures under `templates/inbound/` for the verify-incoming bats suite.
- New skill `skills/verify-incoming/SKILL.md` — prompt-only validation pipeline (schema → integrity → contract match) with **warn-only** failure semantics.
- Bats test suite under `tests/`: `helpers.bash`, `install.bats`, `emit-completion-report.bats`, `emit-repair-failed-report.bats`, `emit-reasoning-request.bats`, `verify-incoming.bats`. APIVR-Δ ships its first test coverage.
- Manifest `comm` block at `install.manifest.json` carrying `envelope_version`, `emits`, and `verifies_incoming`. Schema hand-extended (optional, `additionalProperties: false`).
- Architectural invariant **I-7 ECL emit at hand-off boundaries** in `apivr.md` §1.
- New `apivr.md` §7 — ECL Compatibility (emit kinds × phase × profile schema, inbound verification table, compatibility window).
- `agent.md`: skill-loading row for verify-incoming + ECL section under Memory.
- `AGENTS.md`: frontmatter `comm.envelope_version`, `comm.emits`, `comm.verifies_incoming`.
- `DESIGN-RATIONALE.md`: ECL adoption section recording resolutions for [DECISION-1] (reasoning-request uses base profile only), [DECISION-2] (bats framework), [DECISION-3] (EIIS v1.2 bump deferred to a separate PR), [DECISION-4] (verify-incoming is prompt-only). Future work F1–F6 captured.
- `.github/workflows/release.yml` — adopts the eidolons-nexus release-integrity contract by calling the reusable `Rynaro/eidolons/.github/workflows/eidolon-release-template.yml@main` template. Triggered via `workflow_dispatch` with a SemVer `version` input; the template tags `vX.Y.Z`, builds a source archive, computes `archive_sha256`, generates a GitHub artifact attestation, and publishes a GitHub Release whose `release-manifest.json` is consumed by the nexus's `Roster Intake` workflow. `manifest_sha256` will be `null` for this Eidolon (no `install.manifest.json` is committed at the repo root) — verification reduces to commit + tree + archive + attestation.

### Changed
- `EIDOLON_VERSION` 3.0.5 → 3.1.0 (additive minor — ECL emission is opt-in per ECL §0).
- `apivr.md` Version footer 3.0.0 → 3.1.0.
- `install.sh` ships the eight new schemas, three emit templates, four inbound fixtures, and the verify-incoming skill; declares `ECL_VERSION_VAL="1.0"`; emits `comm.{envelope_version,emits,verifies_incoming}` into `install.manifest.json`.

### Compliance
- `jq empty schemas/*.json` clean.
- `shellcheck -x -S error install.sh` clean.
- Bash 3.2 floor preserved (no `declare -A`, `${var,,}`, `readarray`, `&>>` introduced).
- Idempotent re-install: manifest byte-identical modulo `installed_at`.

### References
- ECL v1.0 spec: `Rynaro/eidolons-ecl@v1.0.0` (`spec/ecl-1.0.md`).
- ATLAS v1.5.0 reference adoption: `Rynaro/ATLAS@31c68f0` (PR #24).
- Hand-off contracts referenced: `apivr-to-{idg,vigil,forge}.yaml`, `{atlas,spectra,vigil,forge}-to-apivr.yaml`.

### Known follow-ups
- VIGIL and FORGE have not yet adopted ECL — emit envelopes to those Eidolons are one-way until they do (tracked as F1, F2 in DESIGN-RATIONALE).
- EIIS v1.2 floor bump bundled in a separate `chore/eiis-1.2-conformance` PR (F3).
- A dedicated `reasoning-request` profile may be promoted in ECL v1.1 (F5).

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

## [pre-3.0.0] — EIIS-1.0 conformance (historical, pre-release)

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
