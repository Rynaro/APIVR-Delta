# APIVR-Δ Design Rationale

Research-to-decision mapping for APIVR-Δ v3.0. For the full evidence base with 40 cited references and five schools-of-thought analysis, see [`docs/PAPER.md`](docs/PAPER.md).

---

## Decision 1: Five-phase cycle (A→P→I→V→Δ/R)

**Research basis**: AlphaCodium (Ridnik et al., 2024) demonstrated that iterative code flow outperforms single-pass prompting. LATS (Zhou et al., ICML 2024) showed tree search with environmental feedback improves solution quality.

**Decision**: Structure agent work as a discrete phase sequence with explicit artifacts per phase, preventing the common failure mode of agents that implement before understanding the problem.

**Alternative considered**: Linear two-phase (plan/execute). Rejected: no mechanism for failure recovery or post-implementation learning.

---

## Decision 2: On-demand skill loading

**Research basis**: Anthropic's context engineering guide and practitioner work on Claude Code's simple agent loop show that context quality (not model size) is the primary performance constraint. Front-loading all instructions degrades performance.

**Decision**: Four skill files loaded per-phase rather than a single monolithic instruction file. An agent implementing code does not need the failure recovery taxonomy in context — it loads that skill only when verification fails.

**Alternative considered**: Single large instruction file. Rejected: exceeds practical context budgets, degrades reasoning quality in unrelated phases.

---

## Decision 3: Test anchoring before implementation

**Research basis**: LDB (ACL 2024) block-by-block verification; SWE-Agent (Yang et al., NeurIPS 2024) agent-computer interface work showing that test feedback loops are the primary signal for correctness.

**Decision**: Plan phase must produce test anchors (input state, action, expected outcome) before any implementation step is written. This forces scope clarification and prevents "implement and hope" patterns.

**Alternative considered**: Tests after implementation. Rejected: agents consistently over-fit implementations to pass tests they wrote in hindsight.

---

## Decision 4: Complexity routing

**Research basis**: RoutingGen (2025) adaptive complexity routing; practitioner analysis of GitHub AGENTS.md patterns across 2,500+ repos showing that agent instructions must match task complexity or degrade for both trivial and complex cases.

**Decision**: Four-tier router (Trivial/Standard/Complex/Uncertain) with explicit routing rules. Trivial tasks skip Plan; Uncertain tasks escalate before Analyze; Complex tasks add architect/editor separation.

**Alternative considered**: Single universal flow. Rejected: over-constrains trivial tasks (slows throughput), under-constrains complex tasks (misses architectural decisions).

---

## Decision 5: Structured memory with schema

**Research basis**: Reflexion (Shinn et al., NeurIPS 2023) episodic verbal self-reflection; Agentless (Xia et al., 2024) hierarchical localization showing that past-task recall reduces redundant discovery work.

**Decision**: Five memory files with defined schemas, size caps, and consolidation rules. Structure prevents unbounded growth that degrades retrieval quality over time.

**Alternative considered**: Single flat memory file. Rejected: no schema → no consolidation → unbounded growth → performance degradation over long-running projects.

---

## Decision 6: Escalation at 3 failures (same category)

**Research basis**: AgentDebug (Stanford/UIUC, 2025) failure classification taxonomy showing that agents retry the same failing approach 87% of the time without classification, leading to infinite loops.

**Decision**: Explicit category-aware loop detection. After 3 attempts at the same failure category, the agent must STOP and escalate with a structured escalation document (problem summary, attempts made, resume context). No heroics.

**Alternative considered**: Unlimited retries with exponential backoff. Rejected: no upper bound on cost; classification-agnostic retries do not converge.

---

## Non-decisions (deliberately out of scope)

- **Vector search for memory**: Regex/keyword search over structured files is sufficient for project-scale memory and avoids infrastructure dependencies (Claude Code observation).
- **Multi-agent orchestration**: APIVR-Δ is designed as a single-agent methodology; orchestration is a consumer concern.
- **Language/framework specifics**: Asset discovery paths and test commands are parameterized for consumer customization rather than embedded.
