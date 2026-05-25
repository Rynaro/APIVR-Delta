# APIVR-Δ Installation Guide

Install the APIVR-Δ methodology into any project using `install.sh` or manual steps.

---

## Quick Install (Recommended)

```bash
# From the APIVR-Delta repo:
bash install.sh
```

Auto-detects your project's hosts (`CLAUDE.md`, `.github/`, `.cursor/`, `.opencode/`) and wires the agent to each.

---

## Install Options

```
Usage: bash install.sh [OPTIONS]

Options:
  --target DIR          Target install dir (default: ./.eidolons/apivr)
  --hosts LIST          claude-code,copilot,cursor,opencode,all (default: auto)
  --force               Overwrite existing install
  --dry-run             Print actions, no writes
  --non-interactive     No prompts; fail on ambiguity (meta-installer mode)
  --manifest-only       Only emit install.manifest.json
  --version             Print Eidolon version
  -h, --help            Show help
```

### Examples

```bash
# Dry run — see what would change
bash install.sh --dry-run

# Install for Claude Code only
bash install.sh --hosts claude-code

# Install for all hosts, force overwrite
bash install.sh --hosts all --force

# CI / meta-installer mode (no prompts)
bash install.sh --non-interactive --force
```

---

## Manual Installation

If you prefer not to use the script, copy files manually:

### 1. Copy methodology files

```bash
mkdir -p .eidolons/apivr
cp agent.md       .eidolons/apivr/agent.md
cp SPEC.md        .eidolons/apivr/SPEC.md
cp -r skills/     .eidolons/apivr/skills/
cp -r templates/  .eidolons/apivr/templates/
mkdir -p .eidolons/apivr/memories
```

### 2. Wire to your host

#### Claude Code

Add to your `CLAUDE.md`:

```markdown
## APIVR-Δ Methodology
@.eidolons/apivr/agent.md
```

#### GitHub Copilot

Add to `.github/copilot-instructions.md`:

```markdown
For feature implementation, follow the methodology in `.eidolons/apivr/agent.md`.
```

#### Cursor

Create `.cursor/rules/apivr.mdc`:

```markdown
---
description: APIVR-Δ feature implementation methodology
globs: ["**/*"]
alwaysApply: false
---
For feature implementation tasks, follow .eidolons/apivr/agent.md.
```

#### OpenCode

Create `.opencode/.eidolons/apivr.md`:

```markdown
---
name: apivr
description: APIVR-Δ feature implementation methodology
---
Follow .eidolons/apivr/agent.md for all feature implementation tasks.
```

---

## Verification

After any install method, run the smoke test:

```
You are the APIVR-Δ agent. A new feature request has arrived.
State the complexity tier you would assign and the first step you would take.
```

Expected: Agent names a complexity tier, starts Analyze, mentions running a repo map.

For more detailed eval missions, see `evals/canary-missions.md`.

---

## Host-Specific Guides

- Claude Code: `hosts/claude-code.md`
- GitHub Copilot: `hosts/copilot.md`
- Cursor: `hosts/cursor.md`
- OpenCode: `hosts/opencode.md`

---

## Updating

```bash
bash install.sh --force
```

The installer compares the existing `install.manifest.json` version against the current Eidolon version before overwriting.

---

## Uninstall

Delete the installed files:

```bash
rm -rf .eidolons/apivr/
```

Remove the dispatch lines added to `CLAUDE.md`, `.github/copilot-instructions.md`, `.cursor/rules/apivr.mdc`, or `.opencode/.eidolons/apivr.md` as applicable.
