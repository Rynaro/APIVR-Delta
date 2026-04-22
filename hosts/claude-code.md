# Wiring APIVR-Δ into Claude Code

## 1. Install

Run from the APIVR-Delta repo root (or wherever you cloned it):

```bash
bash install.sh --hosts claude-code --target ./.eidolons/apivr
```

Or install alongside all detected hosts automatically:

```bash
bash install.sh
```

## 2. Config

The installer appends this pointer to your project's `CLAUDE.md` (creating it if absent):

```markdown
## APIVR-Δ Methodology

@.eidolons/apivr/agent.md
```

Claude Code will load `.eidolons/apivr/agent.md` at session start. Skills load on demand:

| Trigger | Load |
|---|---|
| Starting Analyze phase | `@.eidolons/apivr/skills/context-engineering.md` |
| Planning or scoring strategies | `@.eidolons/apivr/skills/apivr-methodology.md` |
| Test failure, lint error, build break | `@.eidolons/apivr/skills/failure-recovery.md` |
| Session start/end, repeated pattern | `@.eidolons/apivr/skills/memory-management.md` |

## 3. Verify

After install, open a session and run this smoke test:

```
You are acting as the APIVR-Δ agent. A new feature request has arrived.
State the complexity tier you would assign and the first step you would take.
```

Expected: Agent identifies complexity tier (Trivial/Standard/Complex/Uncertain), starts Analyze phase, mentions running a repo map before touching any file.

## 4. Troubleshooting

**Agent ignores methodology**: Confirm `CLAUDE.md` contains the `@.eidolons/apivr/agent.md` line. Run `bash install.sh --force` to re-write.

**Skills not loading**: Check that `.eidolons/apivr/skills/` was copied. Re-run install with `--dry-run` to confirm file list.

**Token budget warning**: `agent.md` must stay ≤1000 tokens. Run `wc -w .eidolons/apivr/agent.md` and divide by 0.75. If over, open an issue.
