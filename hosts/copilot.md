# Wiring APIVR-Δ into GitHub Copilot

## 1. Install

```bash
bash install.sh --hosts copilot --target ./.eidolons/apivr
```

This copies methodology files to `.eidolons/apivr/` and appends an APIVR-Δ section to your project's `.github/copilot-instructions.md` (creating it if absent).

## 2. Config

The installer writes or appends to `.github/copilot-instructions.md`:

```markdown
## APIVR-Δ Feature Implementation

For feature implementation tasks, follow the methodology in `.eidolons/apivr/agent.md`.

Non-negotiable rules:
- Internal First: USE → EXTEND → WRAP → CREATE
- Test-Anchored: Generate test expectations before implementation
- Escalate Early: 3 failures at same category = STOP
```

Copilot Agent Mode will also auto-discover `AGENTS.md` at repo root (open standard).

## 3. Verify

In Copilot Chat or Agent Mode, run:

```
Describe the APIVR-Δ cycle and name the output artifact for the Analyze phase.
```

Expected: Agent names `A→P→I→V→Δ/R`, states Discovery Report as the Analyze artifact.

## 4. Troubleshooting

**Copilot doesn't follow methodology**: Confirm `.github/copilot-instructions.md` exists and references `.eidolons/apivr/agent.md`. Copilot Agent Mode respects this file; Copilot Chat may need the instruction repeated in the prompt.

**AGENTS.md not picked up**: Ensure `AGENTS.md` is at the repository root (not nested). Copilot auto-discovery reads the root `AGENTS.md` when using Agent Mode with AGENTS.md support enabled.
