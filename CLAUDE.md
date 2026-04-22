# Claude Code — APIVR-Δ

Load order for this repository:

1. `agent.md` — entry point, always loaded (≤1000 tokens)
2. `apivr.md` — full methodology reference
3. `skills/apivr-methodology.md` — complete cycle definition (load during Plan phase)
4. `skills/context-engineering.md` — repo mapping and progressive disclosure (load during Analyze)
5. `skills/failure-recovery.md` — failure taxonomy and recovery protocol (load on first failure)
6. `skills/memory-management.md` — episodic memory protocol (load at session start/end)
7. `templates/discovery-report.md` — Analyze phase output skeleton (load during Analyze)
8. `templates/execution-plan.md` — Plan phase output skeleton (load during Plan)
9. `templates/reflect-entry.md` — Reflect phase output skeleton (load on failure)

## Consumer project usage

After installing this Eidolon into a consumer project, Claude Code finds the installed agent at `.eidolons/apivr/agent.md`.

To install:

```bash
bash install.sh --hosts claude-code --target ./.eidolons/apivr
```

Claude Code will load `.eidolons/apivr/agent.md` via the `@` pointer added to the consumer's `CLAUDE.md`.

See `INSTALL.md` for full installation instructions and `hosts/claude-code.md` for Claude Code-specific wiring details.
