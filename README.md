# APIVR-Δ v3.0 — Agentic Coding Methodology

Evidence-grounded, test-anchored, context-aware feature implementation for brownfield codebases.

## What is this?

A complete agent instruction system for AI coding assistants (GitHub Copilot Agent, Claude Code, Cursor, Windsurf, or any LLM-based coding tool). It provides structured methodology, on-demand skills, templates, and persistent memory to make AI agents reliable partners for feature implementation in existing codebases.

## Research Paper

See [`docs/PAPER.md`](docs/PAPER.md) for the full academic paper documenting the methodology's design rationale, evidence base, five schools of thought analysis, and 40 cited references from the research literature.

## Architecture

```
agents/
├── AGENTS.md                          # Entry point (~2K tokens, always loaded)
├── README.md                          # This file
├── docs/
│   └── PAPER.md                       # Academic paper with full evidence base
├── skills/                            # Loaded on-demand per phase
│   ├── apivr-methodology.md           # Full APIVR-Δ cycle definition
│   ├── context-engineering.md         # Repo mapping, hierarchical localization
│   ├── failure-recovery.md            # Failure classification, debugging protocol
│   └── memory-management.md           # Episodic memory, session handoff
├── templates/                         # Structured output formats
│   ├── discovery-report.md            # Analyze phase output
│   ├── execution-plan.md              # Plan phase output
│   └── reflect-entry.md               # Reflect phase output
└── memories/                          # Persistent cross-session state
    ├── task-log.md                    # Completed tasks + outcomes
    ├── pattern-registry.md            # Discovered reusable assets
    ├── failure-catalog.md             # Root causes + prevention
    ├── delta-history.md               # Improvement suggestions
    └── session-handoff.md             # Incomplete work checkpoint
```

### Design Principles

**Minimal entry point**: AGENTS.md is ~2K tokens. Agents load it first and pull in skills only when needed. This preserves context budget for actual code.

**On-demand skill loading**: Skills are loaded per-phase, not upfront. An agent working on implementation doesn't need the failure recovery taxonomy in context — it loads that only when verification fails.

**Structured memory**: Memory files have defined schemas, size caps, and consolidation rules. This prevents unbounded growth that degrades performance over time.

**Progressive disclosure**: The context engineering skill teaches agents to discover codebase information incrementally (directory → structure → interface → implementation) rather than front-loading everything.

## Installation

### GitHub Copilot Agent Mode

Copy the `agents/` directory to your repository root:

```bash
cp -r agents/ /path/to/your/repo/agents/
```

Copilot will discover `AGENTS.md` automatically. Ensure your `.github/copilot-instructions.md` references it:

```markdown
For feature implementation tasks, follow the methodology in `agents/AGENTS.md`.
```

### Claude Code

Copy the `agents/` directory and reference from `CLAUDE.md`:

```markdown
## Agent Methodology
For feature implementation, follow `agents/AGENTS.md`.
Load skills from `agents/skills/` as needed per phase.
```

### Cursor

Reference from `.cursor/rules/` or `.cursorrules`:

```markdown
When implementing features, follow the APIVR-Δ methodology in `agents/AGENTS.md`.
```

### Windsurf

Reference from `.windsurfrules`:

```markdown
For feature implementation tasks, load and follow `agents/AGENTS.md`.
```

### Generic / Other Tools

Any tool that reads markdown instruction files can use this system. Point your tool's instruction mechanism at `agents/AGENTS.md` as the entry point.

## Customization

### Asset Discovery Paths

The methodology references standard paths (e.g., `app/models/DOMAIN/`). Update these in `skills/apivr-methodology.md` → "Asset Discovery" section to match your project structure:

```markdown
| Asset Type | Search Pattern | Purpose |
|------------|---------------|---------|
| Domain models | src/domain/DOMAIN/ | Your path here |
| ... | ... | ... |
```

### Scoring Dimensions

The default scoring matrix (Risk, Effort, Alignment, Maintainability) covers most cases. Add domain-specific dimensions in the Plan phase section of `skills/apivr-methodology.md` if needed.

### Memory Location

Default: `agents/memories/`. If you want memory shared across repos or stored outside the repo (e.g., for privacy), update all references in AGENTS.md and skills files.

### Complexity Router

Adjust the complexity thresholds in AGENTS.md to match your team's definition of "trivial" vs "complex."

## Key Differences from v2.x

| Aspect | v2.x | v3.0 |
|--------|------|------|
| Context management | None | Repo mapping, progressive disclosure, budget tracking |
| Skill loading | Everything in one file | On-demand per phase |
| Test strategy | Tests after implementation | Test anchors BEFORE implementation |
| Failure recovery | Basic retry | Classified taxonomy, targeted fixes, loop detection |
| Memory | Single flat file | Structured schema with consolidation |
| Complexity routing | None | Trivial/Standard/Complex/Uncertain router |
| Architect/Editor | None | Separation for Complex-tier tasks |
| Escalation | Ad-hoc | Structured format with resume context |

## Research Foundation

See [`docs/PAPER.md`](docs/PAPER.md) for the full evidence base with 40 cited references. Key influences:

- **AlphaCodium** (Ridnik et al., 2024): Flow engineering over prompt engineering
- **SWE-Agent** (Yang et al., NeurIPS 2024): Agent-Computer Interface design
- **LATS** (Zhou et al., ICML 2024): Tree search with environmental feedback
- **Reflexion** (Shinn et al., NeurIPS 2023): Episodic verbal self-reflection
- **Aider**: Architect/editor separation, repo mapping via tree-sitter
- **Agentless** (Xia et al., 2024): Hierarchical localization
- **AgentDebug** (Stanford/UIUC, 2025): Failure classification taxonomy
- **LDB** (ACL 2024): Block-by-block verification
- **Claude Code**: Simple agent loop, regex-over-vector-search
- **RoutingGen** (2025): Adaptive complexity routing

Plus community patterns from GitHub AGENTS.md analysis (2,500+ repos), Anthropic's context engineering guide, Spotify's background agent work, and extensive practitioner discourse.

## License

Use freely. Attribution appreciated but not required.
