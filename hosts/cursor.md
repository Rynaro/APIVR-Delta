# Wiring APIVR-Δ into Cursor

## 1. Install

```bash
bash install.sh --hosts cursor --target ./agents/apivr
```

This copies methodology files to `agents/apivr/` and creates `.cursor/rules/apivr.mdc`.

## 2. Config

The installer creates `.cursor/rules/apivr.mdc`:

```markdown
---
description: APIVR-Δ feature implementation methodology
globs: ["**/*"]
alwaysApply: false
---

For feature implementation tasks, follow the APIVR-Δ methodology.

Entry point: `agents/apivr/agent.md`
Full spec:   `agents/apivr/apivr.md`

Cycle: A (Analyze) → P (Plan) → I (Implement) → V (Verify) → Δ (Delta) / R (Reflect)

Non-negotiable:
- Internal First: USE → EXTEND → WRAP → CREATE
- Test-Anchored: Generate test cases BEFORE implementation
- Escalate Early: 3 failures at same category = STOP
```

Cursor will include this rule when the agent is invoked via `@apivr` or when the rule matches.

## 3. Verify

In Cursor's AI panel, type:

```
@apivr I need to add a new endpoint. What's the first step?
```

Expected: Agent routes to Analyze phase, proposes running a repo map before touching any file.

## 4. Troubleshooting

**Rule not applied**: Confirm `.cursor/rules/apivr.mdc` exists. In Cursor settings, check that custom rules are enabled. Try setting `alwaysApply: true` temporarily.

**Legacy `.cursorrules`**: If your project uses a root `.cursorrules` file instead of `.cursor/rules/`, re-run: `bash install.sh --hosts cursor`. The installer will append to `.cursorrules` if `.cursor/` does not exist.
