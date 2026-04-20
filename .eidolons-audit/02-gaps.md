# EIIS v1.0 Audit — Phase 2: GAP ANALYSIS
**Eidolon**: apivr  
**Date**: 2026-04-20

---

## Gap Table

| Gap ID | File | Class | Severity | Reason | Proposed Action |
|---|---|---|---|---|---|
| GAP-01 | `install.sh` | CREATE | blocker | §2 install contract requires this file; absent entirely | Create from template, adapted for APIVR-Δ |
| GAP-02 | `AGENTS.md` (frontmatter) | PATCH | blocker | §5 requires YAML frontmatter with name/version/methodology/role/handoffs; file exists but starts bare | Prepend frontmatter block |
| GAP-03 | `agent.md` | CREATE | blocker | §1 requires always-loaded entry ≤1000 tokens; absent; AGENTS.md (745 tokens) currently serves this role | Create as condensed always-loaded entry mirroring AGENTS.md structure |
| GAP-04 | `.github/copilot-instructions.md` | CREATE | major | §1 requires Copilot primary entry; `.github/` dir absent | Create dir + file pointing to AGENTS.md |
| GAP-05 | `CLAUDE.md` | CREATE | major | §1 requires Claude Code pointer; absent | Create from template with load-order and consumer usage |
| GAP-06 | `apivr.md` | CREATE | major | §1 requires `<EIDOLON>.md` full methodology; absent; `skills/apivr-methodology.md` is nearest equivalent but in wrong location/name | Create as full-methodology file; reference skills/apivr-methodology.md for implementation depth |
| GAP-07 | `INSTALL.md` | CREATE | major | §1 requires human cross-host install guide | Create from consumer instructions already in README.md |
| GAP-08 | `hosts/claude-code.md` | CREATE | major | §1 requires per-host wiring docs; `hosts/` absent | Create hosts/ dir + file |
| GAP-09 | `hosts/copilot.md` | CREATE | major | §1 requires per-host wiring docs | Create file |
| GAP-10 | `hosts/cursor.md` | CREATE | major | §1 requires per-host wiring docs | Create file |
| GAP-11 | `hosts/opencode.md` | CREATE | major | §1 requires per-host wiring docs | Create file |
| GAP-12 | `evals/canary-missions.md` | CREATE | major | §1 requires at least one smoke mission; `evals/` absent | Create with one smoke mission per phase |
| GAP-13 | `schemas/install.manifest.v1.json` | CREATE | major | §3 schema must be committed to repo at this path | Create JSON Schema draft 2020-12 per spec |
| GAP-14 | `CHANGELOG.md` | CREATE | minor | §1 requires keep-a-changelog format; absent | Create with initial entry for v3.0.0 |
| GAP-15 | `DESIGN-RATIONALE.md` | CREATE | minor | §1 requires research→decision mapping; `docs/PAPER.md` covers research but is not the required file | Create pointing to docs/PAPER.md and summarizing key decisions |
| GAP-16 | `skills/<phase>/SKILL.md` structure | FLAG | minor | §1 requires `skills/<phase>/SKILL.md` (≥1); current structure is flat (`skills/*.md`); restructuring would break existing consumer setups | Flag for human decision — do not restructure |

---

## Classification Notes

**GAP-03 (agent.md)**: Current `AGENTS.md` at 745 tokens is within the ≤1000 budget. The new `agent.md` should mirror or reference `AGENTS.md` content rather than duplicate it. Consumers should load `agent.md`; hosts auto-discover `AGENTS.md`. These serve complementary purposes.

**GAP-06 (apivr.md)**: `skills/apivr-methodology.md` (full cycle definition) is the authoritative methodology spec but is in the wrong location per §1. The new `apivr.md` will reference `skills/apivr-methodology.md` and other skill files rather than duplicate them, preserving the on-demand loading design.

**GAP-16 (skills structure)**: The flat `skills/` layout is a deliberate design choice (four skills mapped to phases/triggers rather than named after phases). Reorganizing would require renaming files and updating all cross-references in AGENTS.md and consumer setups — this is a methodology structural decision, not an install-surface change. Flagged.

**docs/PAPER.md**: This is a methodology file (academic paper). Not touched per rule §3.

---

## Total Gaps: 16
- Blockers: 3 (GAP-01, GAP-02, GAP-03)
- Majors: 10 (GAP-04 through GAP-13)
- Minors: 2 (GAP-14, GAP-15)
- Flags: 1 (GAP-16)
