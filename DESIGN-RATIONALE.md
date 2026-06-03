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

## Decision 7: Parallel multi-track mode is worktree-isolated, bounded, and TRANCE-gated

**Research basis**: Multi-agent evidence is asymmetric — parallelism helps the
*read*/explore phase but hurts *write* unless writes are strictly isolated
(R1-01), and sub-agent isolation that is safe for read is dangerous for write
without separation (R4-08). The orchestrator-worker sweet spot caps fan-out at
~5 (R1-02 / cortex C1). Quality dominates diversity-for-its-own-sake, so tracks
are perspective-diverse only where the sub-features genuinely differ — not
N-identical (R3-06). And a single green run is not reliability: pass^k collapse
means a result that holds at k=1 can degrade at k>1 (R6-F08), so the post-merge
suite is framed pass^k. Project memory confirms the failure mode directly:
fanning out multiple agents on one working tree clobbers branches
(`feedback_parallel_agents_same_repo`).

**Decision**: Operationalize the TRANCE G4 form (`skills/parallel-tracks.md`,
SPEC.md §9) as a bounded protocol — entry gate (disjoint file sets + Complex +
TRANCE), max 5 tracks each in its **own git worktree** (`isolation: worktree`
MANDATORY, invariant I-8), clean-context subagents, a per-track verifier
cascade reusing the existing `apivr-completion-report` envelope, a
**non-fungible** per-track ≤3 reflection budget, explicit stop conditions, and a
**single-threaded merge** under continuous parent context (the write boundary
stays single-threaded even though the fan-out was parallel). The merge emits
`tracks-merge-report.md`; an unresolved cross-track conflict escalates to VIGIL
via the existing `repair-failed-report` envelope (no new ECL kind).

**Alternatives considered**: (a) shared-tree fan-out — rejected, it clobbers the
working tree and is project-memory-confirmed harmful; isolation must be a
worktree. (b) Unbounded multi-agent orchestration — rejected; the "Multi-agent
orchestration" non-decision below is **amended, not removed**: single-track
A→P→I→V→Δ/R remains the default, and this mode is TRANCE-gated + entry-gated,
never default.

**Runtime cap (explicit)**: the verifier cascade and merge described here are
**host-interpreted** methodology; the worktree spin-up/cleanup and per-track
verifier invocations are executed by the parent orchestrator. Mechanical
execution of the cascade is **nexus gap R1** (the missing autonomous
edit-run-test loop) and is out of scope for this repo. This is the dominant,
honestly-unmovable score cap from inside APIVR-Δ.

---

---

## ECL adoption — emit + verify-incoming (v3.1.0)

### Why three emit kinds

APIVR-Δ is the highest-volume hand-off node in the Eidolons pipeline. It receives from ATLAS, SPECTRA, VIGIL, and FORGE, and emits to IDG (completion), VIGIL (escalation), and FORGE (consultation). ECL adoption makes these hand-offs machine-checkable: the `apivr-completion-report` envelope tells IDG exactly what was done and verifies payload integrity; the `repair-failed-report` envelope ensures VIGIL receives the 3-failure context with the correct escalation performative and assumption; the `reasoning-request` envelope lets FORGE know the question was generated in the Plan phase by APIVR-Δ.

### [DECISION-1] reasoning-request uses base profile only

The `apivr-to-forge.yaml` contract explicitly sets `schema_ref: ../schemas/per-eidolon/_base-profile.v1.json`. FORGE owns the body shape of consultation requests; APIVR-Δ only needs to satisfy the base frontmatter contract. A dedicated per-Eidolon `reasoning-request` profile is a v1.1 concern (tracked as follow-up F5).

### [DECISION-2] bats test framework

APIVR-Δ had zero test coverage before v3.1.0. The canonical Eidolons test framework is `bats` (used by the nexus, ATLAS v1.5.0, and VIGIL). Rather than introduce a novel framework, we adopt bats and create `tests/` from scratch. The bats suite covers emit conformance, schema round-trips, and the verify-incoming contract. See `tests/` for all files.

### [DECISION-3] EIIS v1.2 bump in a separate PR

Bundling the EIIS v1.2 floor change with the ECL emission PR introduces two axes of change in a single merge. The release workflow at `.github/workflows/release.yml` keeps `eiis-version: "1.1"` for this PR. A separate `chore/eiis-1.2-conformance` PR will bump the EIIS floor and re-vendor the schema. This follows the single-responsibility principle for release notes and roster intake.

### [DECISION-4] verify-incoming is prompt-only

ATLAS v1.5.0 shipped all envelope helpers as prompt-only instructions in `skills/synthesize/SKILL.md`. APIVR-Δ follows the same pattern: `skills/verify-incoming/SKILL.md` describes the validation pipeline in prose for the host LLM to execute. A `bin/verify-incoming.sh` shell helper would require bash runtime assumptions and external tool dependencies (jq) that are not universally available. If the bats suite reveals the prompt-only contract is too loose (e.g., systematic integrity check bypasses), promote to a shell helper in v3.2.0. Tracked as F6.

### Why verify-incoming is warn-only

ECL §0 declares adoption opt-in at v1.0. APIVR-Δ is a receiver, not an authority: refusing a payload because the upstream Eidolon sent a malformed envelope would break the pipeline for users who have not yet adopted ECL. Warn-only posture (log `verify_fail`, emit stderr warning, continue) maximises interoperability during the ECL rollout period. The spec notes this diverges from ECL §6.2.2 ("SHALL NOT process on mismatch") — this is an intentional opt-in degradation documented here per ECL §7.4 drift register.

### Future work

- **F1 — VIGIL adopts ECL v1.0**: Until VIGIL adopts, `repair-failed-report` envelopes are emit-only. VIGIL v1.0.3 has not adopted ECL.
- **F2 — FORGE adopts ECL v1.0**: Until FORGE adopts, `reasoning-request` envelopes are emit-only and `reasoning-report` inbound verification relies on fixtures only. FORGE v1.2.1 has not adopted ECL.
- **F3 — EIIS v1.2 conformance**: Tracked as `chore/eiis-1.2-conformance` PR.
- **F5 — reasoning-request dedicated profile**: ECL v1.1 candidate.
- **F6 — promote verify-incoming to shell helper**: Only if bats evidence demands it.

---

## Non-decisions (deliberately out of scope)

- **Vector search for memory**: Regex/keyword search over structured files is sufficient for project-scale memory and avoids infrastructure dependencies (Claude Code observation).
- **Multi-agent orchestration**: APIVR-Δ is designed as a single-agent methodology; orchestration is a consumer concern. **Amended (Decision 7):** the single-track cycle remains the default, but under TRANCE authorization + a disjoint-file-set entry gate, APIVR-Δ MAY fan out into a bounded (≤5), worktree-isolated parallel multi-track mode whose merge is single-threaded under continuous parent context (SPEC.md §9). This is parallelism, not unbounded multi-agent orchestration, and it is never the default.
- **Language/framework specifics**: Asset discovery paths and test commands are parameterized for consumer customization rather than embedded.
