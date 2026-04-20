# APIVR-Δ Canary Missions

Smoke tests for each major phase. Paste each prompt verbatim into your host. Evaluate against the pass criteria.

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
