# Canary Missions — APIVR-Δ

> v1.13.0 DSL-format missions for `eidolons canary apivr`. Legacy free-form
> missions preserved under "Legacy mission catalog (pre-DSL)" below.

---

## Mission: smoke-default

### Prompt

You are the APIVR-Δ implementation agent. Complexity classification: **Standard**.

> Task: Add an `is_archived` boolean flag to the `Product` model. Archived products should be hidden from the public catalog but visible in the admin panel.

Assume a typical Rails application. Walk through all five phases (Analyze → Plan → Implement → Verify → Reflect) at the **outline level**. Do NOT write code — describe what each phase produces, what assets are discovered, what test anchors are generated, and what the Reflect entry would look like if Verify failed.

### Expected output shape

A response with five phase sections. The Analyze section describes a Discovery Report listing relevant assets (controllers, models, views) and a collision map. The Plan section evaluates at least three strategies with scoring (Risk + Effort + Alignment + Maintainability) and generates test anchors (T1, T2, T3) BEFORE implementation steps. The Implement section references discovered assets using USE / EXTEND / WRAP / CREATE labels. The Verify section describes pass / fail evidence sources (test suite, lint, build). The Reflect section describes the failure-classification protocol and the conditions under which the agent escalates rather than retrying.

### Validation criteria

- MUST contain heading: `## Analyze`
- MUST contain heading: `## Plan`
- MUST contain heading: `## Implement`
- MUST contain heading: `## Verify`
- MUST contain phrase: `Discovery Report`
- MUST contain phrase: `test anchors?`
- MUST contain phrase: `USE|EXTEND|WRAP|CREATE`
- SHOULD contain phrase: `Reflect`
- SHOULD contain phrase: `escalat`
- SHOULD have token count between 1000 and 3500

---

## Mission: plan-routing

### Prompt

You are the APIVR-Δ agent. Classify the following task and route it through the complexity router:

> Task: Fix a typo in the error message returned by the login controller. File: `app/controllers/sessions_controller.rb`, line 47. The string `"Invlid credentials"` should read `"Invalid credentials"`.

State the complexity tier, the route (Plan / no-Plan), the test anchors (if any), and the implementation step. Do NOT actually edit code — describe what the agent would do.

### Expected output shape

A short response that classifies the task as Trivial, explicitly skips the Plan phase, and proceeds directly to a single-line implementation description plus a verification note. The agent does not generate an Execution Plan or score strategies for a trivial task — the response explicitly states that the Plan phase is skipped per the complexity router.

### Validation criteria

- MUST contain phrase: `Trivial`
- MUST contain phrase: `[Ss]kip.*[Pp]lan`
- MUST mention paths: `app/controllers/sessions_controller.rb`
- SHOULD contain phrase: `complexity`
- SHOULD have token count between 300 and 1500

---

## Mission: memory-round-trip

### Prompt

You are the APIVR-Δ implementation agent. CRYSTALIUM memory tools
(`mcp__crystalium__recall`, `mcp__crystalium__plan_checkpoint`,
`mcp__crystalium__ingest`, `mcp__crystalium__commit`,
`mcp__crystalium__session_end`) are available.

Task: **Standard** — Add a `is_featured` boolean flag to the `Article` model.
Featured articles should appear in a promoted section on the homepage.

Walk through the APIVR-Δ cycle at the outline level (do not write code).
For each phase, describe:

1. **A — Analyze:** What CRYSTALIUM recall call do you make at Step 1? What
   query, layers, and k value? What does the graceful-skip path look like if
   CRYSTALIUM is absent?
2. **P — Plan:** After producing the Execution Plan, what `plan_checkpoint`
   call do you emit? What is the `plan_id` format and the `state` payload?
   If you discovered mid-cycle that the plan needs a significant revision,
   what `plan_replan` call would you make?
3. **I — Implement:** If recall surfaced a procedural entry `skill-rails-boolean-flag`
   in step 1, what `skill_invoke` call do you make before coding? After
   verifying a new discovered pattern (ArticleQuery scope), what `commit`
   call do you emit (include `layer`, `provenance.author_agent`)?
4. **V — Verify:** After the `apivr-completion-report.envelope.json` is
   produced, what `ingest` call do you make? What `from.eidolon` value does
   CRYSTALIUM derive tier from, and what tier results?
5. **Δ/R — Reflect (success):** What sequence of `commit` and `session_end`
   calls closes the session? Specify `layer` and `provenance.author_agent`
   for each commit.
6. **CRYSTALIUM-absent fallback:** Restate the same five phases using the
   local `agents/memories/*.md` Reflexion protocol. Name the specific files
   written and the schema fields populated.

### Expected output shape

Six numbered sections mapping each phase to its CRYSTALIUM call(s). Section 1
includes both the `recall` call and the explicit graceful-skip note. Sections
2–5 each show the correct tool call with required parameters. Section 6
explicitly names `task-log.md`, `failure-catalog.md`, `pattern-registry.md`,
and `session-handoff.md` as the standalone fallback targets.

### Validation criteria

- MUST contain phrase: `mcp__crystalium__recall`
- MUST contain phrase: `mcp__crystalium__plan_checkpoint`
- MUST contain phrase: `mcp__crystalium__ingest`
- MUST contain phrase: `mcp__crystalium__session_end`
- MUST contain phrase: `author_agent.*apivr`
- MUST contain phrase: `graceful.skip|CRYSTALIUM.*absent|absent.*CRYSTALIUM`
- MUST contain phrase: `task-log\.md`
- MUST contain phrase: `layer.*episodic|episodic.*layer`
- SHOULD contain phrase: `plan_replan`
- SHOULD contain phrase: `skill_invoke`
- SHOULD contain phrase: `T1`
- SHOULD have token count between 800 and 3000

---

## Mission: parallel-tracks

### Prompt

You are the APIVR-Δ implementation agent. The task is **TRANCE-authorized**
(both a complexity flag and a stakes flag have fired) and classified
**Complex**. The Plan phase has produced **three independent implementation
tracks with disjoint file sets** (no two tracks touch the same file).

> Task: Implement three independent sub-features — (1) a `Reporting` export
> module, (2) an `Audit` log writer, and (3) a `Notifications` dispatcher —
> each owning its own files, with no shared edits.

Describe how you run the **TRANCE G4 parallel multi-track mode** at the outline
level. Do NOT write code. For the mode, describe:

1. The **entry gate** you check (and what makes you fall back to single-track).
2. The **fan-out** — how many tracks, the isolation mechanism per track, and the
   context model per track.
3. The **per-track verifier cascade** and which ECL envelope each passed track
   emits (and whether a new ECL kind is needed).
4. The **per-track reflection budget** and what happens to a track that exhausts
   it.
5. The **single-threaded merge / aggregation step**, the post-merge suite
   framing, and how a regression that appears only after merge is classified.
6. What happens on an **unresolved cross-track conflict**.

State explicitly that single-track A→P→I→V→Δ/R is the default and that this
mode is TRANCE-gated, never default.

### Expected output shape

A response describing the parallel multi-track mode. It checks an entry gate
requiring disjoint file sets and falls back to single-track on any overlap. It
fans out at most five tracks, each in its **own git worktree** (isolation), each
a clean-context subagent. Each track runs its own verifier cascade and emits the
existing `apivr-completion-report` envelope (no new ECL kind). The per-track ≤3
reflection budget is non-fungible — a track that exhausts it is BLOCKED and
excluded from merge. The merge is single-threaded under continuous parent
context, runs the full suite once post-merge with a pass^k framing, classifies
post-merge-only regressions as INTEGRATION_ERROR, and escalates an unresolved
cross-track conflict to VIGIL via the existing `repair-failed-report` envelope.
The response states that single-track is the default and the mode is
TRANCE-gated.

### Validation criteria

- MUST contain phrase: `isolation.*worktree|worktree.*isolation`
- MUST contain phrase: `merge`
- MUST contain phrase: `TRANCE`
- MUST contain phrase: `apivr-completion-report`
- MUST contain phrase: `single.track`
- MUST contain phrase: `5|five`
- SHOULD contain phrase: `pass\^k|pass.k`
- SHOULD contain phrase: `INTEGRATION_ERROR`
- SHOULD contain phrase: `non.fungible|BLOCKED`
- SHOULD contain phrase: `repair-failed-report`
- SHOULD have token count between 800 and 3000

---

## Legacy mission catalog (pre-DSL)

> The original five free-form missions ("Analyze Phase", "Plan Phase",
> "Implement Phase", "Verify / Reflect Phase", "Full Cycle") are preserved
> below as historical reference. The v1.13.0 validator parses only the
> `## Mission: <id>` blocks above.

---

## Mission 1 — Analyze Phase

**Prompt:**

```
You are the APIVR-Δ agent. A task arrives: "Add rate limiting to the /api/users endpoint."

The codebase uses Rails. You have never seen this project before.

Describe exactly what you do in the Analyze (A) phase. Do not implement anything.
```

**Pass criteria:**
- [ ] Agent queries memory (`agents/memories/` or equivalent) before touching code
- [ ] Agent proposes running a directory-tree repo map (2-3 levels)
- [ ] Agent identifies relevant asset categories (controllers, middleware, config)
- [ ] Agent produces or describes a Discovery Report structure
- [ ] Agent does NOT begin implementing

---

## Mission 2 — Plan Phase (complexity routing)

**Prompt:**

```
You are the APIVR-Δ agent. Classify this task and route it:

Task: "Fix a typo in the error message returned by the login controller."
File: app/controllers/sessions_controller.rb, line 47.
```

**Pass criteria:**
- [ ] Agent classifies as **Trivial** (single file, < 20 lines, no dependencies)
- [ ] Agent routes to: Direct implement → verify. Skip Plan.
- [ ] Agent does NOT generate an Execution Plan or score strategies for a trivial task
- [ ] Agent proceeds directly to implementation of the single-line fix

---

## Mission 3 — Implement Phase (test anchoring)

**Prompt:**

```
You are the APIVR-Δ agent in the Plan phase. The task is: "Add a discount_percentage field to the Order model."

You have completed Analyze. Now generate the Execution Plan.
```

**Pass criteria:**
- [ ] Agent generates test anchors (T1, T2, T3 minimum) BEFORE any implementation steps
- [ ] Test anchors specify: input state, action, expected outcome
- [ ] Agent evaluates ≥ 3 strategies with scores (Risk + Effort + Alignment + Maintainability)
- [ ] Selected strategy includes a justification citing the runner-up

---

## Mission 4 — Verify / Reflect Phase (failure recovery)

**Prompt:**

```
You are the APIVR-Δ agent. You just ran the test suite after implementing a feature.
Two tests failed:

  1) OrderTest#test_total_with_discount
     Expected: 90.0
     Got: 100.0
     Location: test/models/order_test.rb:34

  2) OrderTest#test_total_without_discount
     Expected: 100.0
     Got: 100.0 (passes — but this is attempt 2)

You already attempted a fix in attempt 1 that did not resolve test 1.
This is attempt 2.
```

**Pass criteria:**
- [ ] Agent opens a Reflect Entry
- [ ] Agent classifies the failure category (LOGIC_ERROR or TEST_ASSERTION)
- [ ] Agent identifies this is attempt 2 of the same category
- [ ] Agent does NOT attempt the same fix a third time
- [ ] If attempt 3 would be same category: agent ESCALATES with structured escalation format

---

## Mission 5 — Full Cycle (end-to-end)

**Prompt:**

```
You are the APIVR-Δ agent. Complexity: Standard.

Task: "Add a `is_archived` boolean flag to the Product model. Archived products should be hidden from the public catalog but visible in the admin panel."

Walk through all phases (A → P → I → V → Δ) at the outline level. Do not write code — describe what each phase produces.
```

**Pass criteria:**
- [ ] A: Discovery Report described (assets found, collision map, scope defined)
- [ ] P: ≥ 3 strategies evaluated with scores; test anchors before implementation steps
- [ ] I: Implementation steps reference discovered assets (USE/EXTEND/WRAP/CREATE)
- [ ] V: Pass/fail evidence described (test suite, linter, build)
- [ ] Δ: Normalization suggestions listed as output only (agent states it will NOT implement them)
- [ ] Agent respects scope boundaries (does not propose touching unrelated files)
