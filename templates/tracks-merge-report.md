# Tracks Merge Report (TRANCE G4)

> Aggregation artifact emitted by the **single-threaded merge step** of the
> Parallel Multi-Track Mode (`skills/parallel-tracks.md`). It aggregates the
> per-track `apivr-completion-report` envelopes — it is a Markdown report, NOT
> a new ECL kind (the closed 10-performative set is preserved).

**Task**: [task title]
**Date**: [date]
**TRANCE authorization**: [complexity flag + stakes flag that fired — cortex C6]
**Track count**: [N] / 5 (hard cap 5)
**Isolation**: worktree (mandatory — never the shared tree)

---

## Per-Track Results

| Track | Worktree path | File set | Verdict | Completion envelope | Retries used /3 |
|-------|---------------|----------|---------|---------------------|-----------------|
| T-1 | [path] | [files owned] | PASS \| BLOCKED | [apivr-completion-report ref \| —] | [n]/3 |
| T-2 | [path] | [files owned] | PASS \| BLOCKED | [ref \| —] | [n]/3 |
| ... | | | | | |

> A track is **BLOCKED** when it exhausted its non-fungible ≤3 same-category
> reflection budget, breached another track's file boundary, or was flagged
> flaky by the pass^k gate. BLOCKED tracks are **excluded from the merge** and
> never silently re-driven.

---

## Merge Order

Dependency-sorted order in which PASSED tracks were merged (single-threaded,
under continuous parent context):

1. [T-x — reason it precedes the next]
2. [T-y]
3. ...

---

## Conflicts Resolved

| Conflict | Tracks | Files | Resolution |
|----------|--------|-------|------------|
| [desc] | [T-x ↔ T-y] | [file] | [how resolved] |

> Unresolved cross-track conflict → escalate to VIGIL via the existing
> `repair-failed-report.envelope.json` (`performative=ESCALATE`,
> `to.eidolon=vigil`). No new ECL kind.

---

## Post-Merge Full-Suite Result

Run **ONCE** after merge (not per-track), with the pass^k reliability gate:

- **Command**: [exact regression command]
- **Result**: PASS | FAIL
- **pass^k note**: [k repeats run; any non-deterministic result → flaky → the
  offending change is BLOCKED, not merged]
- **Cross-track regressions** (passed per-track, failed post-merge): classified
  `INTEGRATION_ERROR` and routed to the merge-step reflection — NOT back into a
  track.

---

## Blocked-Track Disposition

| Track | Reason BLOCKED | Escalation ref |
|-------|----------------|----------------|
| [T-z] | [budget exhausted \| boundary breach \| flaky] | [repair-failed-report ref \| none] |

---

## Outcome

**Merge outcome**: MERGED_CLEAN | MERGED_WITH_INTEGRATION_FIX | ESCALATED

**Tracks merged**: [count] / [N]   **Tracks blocked**: [count] / [N]

> Scope note: the per-track verifier cascade and merge described here are
> host-interpreted methodology, not a mechanical runtime (nexus gap R1).
