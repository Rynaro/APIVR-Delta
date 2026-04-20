# EIIS v1.0 Audit — Phase 3: PLAN
**Eidolon**: apivr  
**Date**: 2026-04-20

---

## 1. Summary

The APIVR-Δ v3.0 repo currently has a solid methodology core (AGENTS.md, four skill files, three templates, and the academic paper) but is missing the entire EIIS install surface. There is no `install.sh`, no `agent.md`, no host wiring docs, no eval missions, no manifest schema, and no CLAUDE.md or Copilot entry. After this conformance pass, the repo will have a complete EIIS-1.0 install surface: a scriptable installer, per-host dispatch wiring, a committed manifest schema, and all required root marker files. The Eidolon's methodology content (AGENTS.md, skills/, templates/, docs/PAPER.md) will not be modified — only supplemented. The flat `skills/` structure is flagged for human review and left as-is.

---

## 2. File Change List

### GAP-01 — CREATE `install.sh`

Full bash installer implementing the §2 interface contract. It will:
- Parse all required flags: `--target`, `--hosts`, `--force`, `--dry-run`, `--non-interactive`, `--manifest-only`, `--version`, `-h/--help`
- Default target: `./agents/apivr`
- Auto-detect hosts by checking for `.claude`/`CLAUDE.md`, `.github/`, `.cursor`/`.cursorrules`, `.opencode/`
- Copy these files to `<target>/`: `agent.md`, `apivr.md`, `skills/`, `templates/`
- Create dispatch files per detected/requested host:
  - `claude-code`: append `@agents/apivr/agent.md` pointer to consumer `CLAUDE.md`
  - `copilot`: append section to consumer `AGENTS.md` (or `.github/copilot-instructions.md`)
  - `cursor`: create `.cursor/rules/apivr.mdc`
  - `opencode`: create `.opencode/agents/apivr.md`
- Write `<target>/install.manifest.json` matching the §3 schema
- Measure `agent.md` token count and print it
- Print smoke-test verification prompt at the end
- Idempotent: detect existing manifest, compare versions, prompt or fail per mode

### GAP-02 — PATCH `AGENTS.md`

Prepend §5 YAML frontmatter block to the top of the file:
```yaml
---
name: apivr
version: 3.0.0
methodology: APIVR-Δ
methodology_version: 3.0.0
role: feature-implementation — Evidence-grounded feature implementation for brownfield codebases
handoffs:
  upstream:   []
  downstream: []
---
```
All existing content preserved verbatim after the frontmatter.

### GAP-03 — CREATE `agent.md`

The always-loaded entry point (condensed, ≤1000 tokens). Will mirror the current AGENTS.md structure — Identity, Cycle, Complexity Router, Core Principles, Skill Loading table, and Guardrails — but written as a standalone file that references the other files by their installed paths (`agents/apivr/skills/...`, `agents/apivr/templates/...`). Target: ~550 words (~733 tokens), leaving headroom below the 1000-token budget.

### GAP-04 — CREATE `.github/copilot-instructions.md`

Standard pointer file for GitHub Copilot. Summarizes APIVR-Δ role, lists the P0 non-negotiable rules, shows the phase pipeline table, and points at `AGENTS.md` and `apivr.md` for the full spec.

### GAP-05 — CREATE `CLAUDE.md`

Standard load-order file for Claude Code. Lists: `agent.md`, `apivr.md`, phase skills, template files. Includes consumer project usage section explaining `bash install.sh`.

### GAP-06 — CREATE `apivr.md`

Full methodology reference file. Will be a structured document that:
- States APIVR-Δ identity and version
- Cross-references `skills/apivr-methodology.md` as the implementation-depth spec
- Provides a navigable index of all skills and templates
- Does NOT duplicate skill content (preserves on-demand loading design)

### GAP-07 — CREATE `INSTALL.md`

Human cross-host install guide. Lifts the "Installation" section from README.md and expands it with step-by-step instructions for each host, covering: script install, manual install, and verification smoke test. Does not modify README.md.

### GAP-08–11 — CREATE `hosts/claude-code.md`, `hosts/copilot.md`, `hosts/cursor.md`, `hosts/opencode.md`

Per-host wiring docs following the minimal skeleton from the spec: Install section, Config section, Verify section, Troubleshooting section. Adapted for each host's specific config mechanism:
- `claude-code`: `CLAUDE.md` pointer + `@agents/apivr/agent.md`
- `copilot`: `.github/copilot-instructions.md` + AGENTS.md auto-discovery
- `cursor`: `.cursor/rules/apivr.mdc` or `.cursorrules` append
- `opencode`: `.opencode/agents/apivr.md`

### GAP-12 — CREATE `evals/canary-missions.md`

At least one smoke mission per major phase (Analyze, Plan, Implement, Verify). Each mission: a concrete prompt that exercises the phase, expected outputs (not results — just structure), and a pass/fail criterion. Will be written as prompts a human or CI can paste verbatim.

### GAP-13 — CREATE `schemas/install.manifest.v1.json`

Verbatim JSON Schema draft 2020-12 from the EIIS §3 spec. No customization needed.

### GAP-14 — CREATE `CHANGELOG.md`

Keep-a-Changelog format. Initial content: `## [3.0.0]` section documenting the v3.0 release (lifted from README key differences table), followed by `## [Unreleased] — EIIS-1.0 conformance` section added at execution time.

### GAP-15 — CREATE `DESIGN-RATIONALE.md`

Research-to-decision mapping. Will reference `docs/PAPER.md` as the deep-dive evidence base and extract the key decision rationale (why APIVR-Δ structure, why on-demand skill loading, why test-anchored, why complexity routing) as a top-level readable document.

### GAP-16 — FLAG (no action)

`skills/<phase>/SKILL.md` structure. Current flat layout (`skills/apivr-methodology.md` etc.) is a deliberate design pattern preserved from v3.0. Restructuring would rename files and break all cross-references. **No change.** Human must decide if reorganization is warranted.

---

## 3. Risk Register

| Risk | Likelihood | Mitigation |
|---|---|---|
| `install.sh` host detection logic doesn't match consumer's actual layout | Medium | Script uses safe `[[ -d ... ]]` guards; dry-run mode lets consumer verify before committing |
| `agent.md` token budget exceeded if future methodology growth is copied in | Low | Content written to ~550 words; budget measured and printed by installer; `--non-interactive` exits 4 if over |
| `apivr.md` accidentally duplicates methodology content that then drifts | Low | File is a navigation index + cross-reference only; no methodology rules embedded |
| AGENTS.md frontmatter prepend corrupts host auto-discovery | Low | YAML frontmatter is the standard pattern for AGENTS.md open standard; verified post-write |
| Flat skills/ structure causes GAP-16 to be flagged but ignored long-term | Medium | Flag surfaced in audit log; human decision required; not a blocker for install contract |

---

## 4. Token Budget Estimate

| File | Current tokens | After change | Notes |
|---|---|---|---|
| `agent.md` (new) | 0 | ~733 | ≤1000 budget; within limit |
| `AGENTS.md` (patched) | 745 | ~760 | Frontmatter adds ~15 tokens |
| Consumer always-loaded budget | 0 | ~733 | Just agent.md loaded always; skills on-demand |

---

## 5. Rejected Alternatives

**Alternative A: Rewrite AGENTS.md as agent.md**  
Considered renaming the existing `AGENTS.md` to `agent.md` and creating a new minimal `AGENTS.md` pointer. Rejected because: (1) `AGENTS.md` is the open-standard host auto-discovery filename — renaming breaks Copilot/Cursor/OpenCode detection; (2) consumers already referencing `AGENTS.md` would break.

**Alternative B: Create agent.md as a one-line pointer (`@AGENTS.md`)**  
Considered making `agent.md` a single-line `@include` pointing at `AGENTS.md`. Rejected because: (1) not all hosts honor `@include` syntax; (2) the EIIS spec expects `agent.md` to be a standalone always-loaded file; (3) consumer installs copy `agent.md` to a different directory, so a relative pointer would break.

**Alternative C: Reorganize skills/ into `skills/<phase>/SKILL.md`**  
Considered reorganizing the flat skills directory to match the EIIS required structure. Rejected because: this would rename four content files that are cross-referenced in AGENTS.md, README.md, and consumer setups — pure methodology restructuring, out of scope for an install-surface conformance pass.

---

## 6. Execution Order

1. `schemas/` dir → `schemas/install.manifest.v1.json`
2. `.github/` dir → `.github/copilot-instructions.md`
3. `hosts/` dir → 4 host files
4. `evals/` dir → `evals/canary-missions.md`
5. Root: `agent.md`, `apivr.md`, `CLAUDE.md`, `INSTALL.md`, `CHANGELOG.md`, `DESIGN-RATIONALE.md`
6. Patch: `AGENTS.md` (prepend frontmatter)
7. Root: `install.sh` (longest file, last to avoid blocking other creates)
8. Update `CHANGELOG.md` with EIIS-1.0 conformance entry
