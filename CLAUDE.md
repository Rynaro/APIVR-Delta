# Claude Code — APIVR-Δ

Load order for this repository:

1. `agent.md` — entry point, always loaded (≤1000 tokens)
2. `apivr.md` — full methodology reference
3. `skills/apivr-methodology.md` — complete cycle definition (load during Plan phase)
4. `skills/context-engineering.md` — repo mapping and progressive disclosure (load during Analyze)
5. `skills/failure-recovery.md` — failure taxonomy and recovery protocol (load on first failure)
6. `skills/memory-management.md` — episodic memory protocol (load at session start/end)
7. `skills/verify-incoming/SKILL.md` — opt-in ECL envelope verification (load when reading an upstream artefact with a sibling `.envelope.json`)
8. `templates/discovery-report.md` — Analyze phase output skeleton (load during Analyze)
9. `templates/execution-plan.md` — Plan phase output skeleton (load during Plan)
10. `templates/reflect-entry.md` — Reflect phase output skeleton (load on failure)

## ECL v1.0

This Eidolon targets ECL v1.0 (see `ECL_VERSION`). Three emit kinds:

- `apivr-completion-report` (to IDG, Implement-phase exit, `templates/apivr-completion-report.envelope.json`)
- `repair-failed-report` (to VIGIL, Reflect-phase 3-failure escalation, `templates/repair-failed-report.envelope.json`)
- `reasoning-request` (to FORGE, Plan-phase consultation, `templates/reasoning-request.envelope.json`)

Inbound envelope verification is opt-in and warn-only — see `skills/verify-incoming/SKILL.md`.

## Consumer project usage

After installing this Eidolon into a consumer project, Claude Code finds the installed agent at `.eidolons/apivr/agent.md`.

To install:

```bash
bash install.sh --hosts claude-code --target ./.eidolons/apivr
```

Claude Code will load `.eidolons/apivr/agent.md` via the `@` pointer added to the consumer's `CLAUDE.md`.

See `INSTALL.md` for full installation instructions and `hosts/claude-code.md` for Claude Code-specific wiring details.
