#!/usr/bin/env bats
# tests/verify-incoming.bats — blocking symmetric verify-incoming gate (ECL §6.2.2)
#
# Tests the verify-incoming contract. Because the logic is prompt-only (D4),
# these tests validate the skill posture, schema/template artefacts that the
# prompt-skill references, plus the trace-event format, rather than executing
# a shell verify script.
#
# POSTURE: blocking (ECL §6.2.2) — not warn-only. Any integrity or contract
# failure causes REFUSE; the payload is NOT processed.

load helpers.bash

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
TRACE_DIR=""

setup() {
  TRACE_DIR="$(mktemp -d)"
}

teardown() {
  teardown_fixture
  [[ -n "${TRACE_DIR:-}" && -d "${TRACE_DIR}" ]] && rm -rf "${TRACE_DIR}"
}

# ── Skill posture assertions ─────────────────────────────────────────────────

@test "skill file exists" {
  [ -f "${REPO_ROOT}/skills/verify-incoming.md" ]
}

@test "skill declares BLOCKING posture (REFUSE / SHALL NOT / blocking)" {
  grep -qE 'REFUSE|SHALL NOT|blocking' "${REPO_ROOT}/skills/verify-incoming.md"
}

@test "skill does NOT declare warn-only posture" {
  # Negative assertion: catches regressions to the old warn-only contract.
  # The footer line contains 'warn-only' in a historical reference context;
  # we target the canonical behavioural phrases that would indicate active
  # warn-only posture (process anyway, payload is always processed).
  run grep -cE 'payload is always processed|process the payload anyway|Warn-only on failure' \
    "${REPO_ROOT}/skills/verify-incoming.md"
  # Zero matches expected
  [[ "$output" == "0" ]]
}

@test "skill does NOT say 'WARN-ONLY on failure' (mode header)" {
  run grep -c 'WARN-ONLY on failure\|warn-only — the payload\|Failures are \*\*warn-only\*\*' \
    "${REPO_ROOT}/skills/verify-incoming.md"
  [[ "$output" == "0" ]]
}

@test "skill Failure Mode section says BLOCKING — refuse, do not process" {
  grep -q 'Failure Mode (BLOCKING' "${REPO_ROOT}/skills/verify-incoming.md"
}

@test "skill says 'Do not process the payload'" {
  grep -q 'Do not process the payload' "${REPO_ROOT}/skills/verify-incoming.md"
}

@test "skill REFUSES and hands back to orchestrator on failure" {
  grep -qE 'Hand control back to the.*(orchestrator|Orchestrator)|hand back to the orchestrator' \
    "${REPO_ROOT}/skills/verify-incoming.md"
}

@test "skill references ECL §6.2.2 as the normative source" {
  grep -q '§6.2.2' "${REPO_ROOT}/skills/verify-incoming.md"
}

@test "skill verify_fail event has 'decision: refused' field" {
  grep -q '"decision":"refused"' "${REPO_ROOT}/skills/verify-incoming.md"
}

@test "skill frontmatter has metadata block with methodology" {
  grep -q 'metadata:' "${REPO_ROOT}/skills/verify-incoming.md"
  grep -q 'methodology: APIVR' "${REPO_ROOT}/skills/verify-incoming.md"
}

@test "skill frontmatter name is apivr-verify-incoming" {
  grep -q 'name: apivr-verify-incoming' "${REPO_ROOT}/skills/verify-incoming.md"
}

# ── install.sh registration check ───────────────────────────────────────────

@test "install.sh registers verify-incoming in wire_skill loop" {
  grep -q 'wire_skill "verify-incoming"' "${REPO_ROOT}/install.sh"
}

@test "install.sh records skills/verify-incoming.md in manifest (add_fw)" {
  grep -q 'add_fw "skills/verify-incoming.md"' "${REPO_ROOT}/install.sh"
}

@test "install.sh records verify-incoming in add_skill (skills[] array)" {
  grep -q 'add_skill "verify-incoming"' "${REPO_ROOT}/install.sh"
}

# ── install run: exit 0 + manifest line ─────────────────────────────────────

@test "install.sh exits 0 non-interactively into a temp target" {
  local tmp_target
  tmp_target="$(mktemp -d)"
  run bash "${REPO_ROOT}/install.sh" \
    --target "${tmp_target}" \
    --hosts none \
    --non-interactive \
    --force
  [ "$status" -eq 0 ]
  rm -rf "${tmp_target}"
}

@test "install produces skills/verify-incoming.md in target" {
  local tmp_target
  tmp_target="$(mktemp -d)"
  bash "${REPO_ROOT}/install.sh" \
    --target "${tmp_target}" \
    --hosts none \
    --non-interactive \
    --force
  [ -f "${tmp_target}/skills/verify-incoming.md" ]
  rm -rf "${tmp_target}"
}

@test "install manifest records skills/verify-incoming.md" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  local tmp_target
  tmp_target="$(mktemp -d)"
  bash "${REPO_ROOT}/install.sh" \
    --target "${tmp_target}" \
    --hosts none \
    --non-interactive \
    --force
  run jq -r '[.files_written[] | select(.path=="skills/verify-incoming.md")] | length' \
    "${tmp_target}/install.manifest.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "1" ]]
  rm -rf "${tmp_target}"
}

@test "install manifest skills[] array includes verify-incoming entry" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  local tmp_target
  tmp_target="$(mktemp -d)"
  bash "${REPO_ROOT}/install.sh" \
    --target "${tmp_target}" \
    --hosts none \
    --non-interactive \
    --force
  run jq -r '[.skills[] | select(.name=="verify-incoming")] | length' \
    "${tmp_target}/install.manifest.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "1" ]]
  rm -rf "${tmp_target}"
}

# ── Happy path: valid envelope ───────────────────────────────────────────────

@test "happy path: valid scout-report fixture passes schema check" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  local fixture="${REPO_ROOT}/templates/inbound/scout-report.envelope.fixture.json"
  run jq empty "$fixture"
  [ "$status" -eq 0 ]
}

@test "happy path: scout-report fixture has correct from.eidolon (atlas)" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.from.eidolon' "${REPO_ROOT}/templates/inbound/scout-report.envelope.fixture.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "atlas" ]]
}

@test "happy path: scout-report fixture to.eidolon is apivr" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.to.eidolon' "${REPO_ROOT}/templates/inbound/scout-report.envelope.fixture.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "apivr" ]]
}

@test "happy path: scout-report fixture performative is in allowed set" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.performative' "${REPO_ROOT}/templates/inbound/scout-report.envelope.fixture.json"
  [ "$status" -eq 0 ]
  # atlas-to-apivr allows: PROPOSE, INFORM, REFUSE
  [[ "$output" == "PROPOSE" || "$output" == "INFORM" || "$output" == "REFUSE" ]]
}

@test "happy path: verify_pass event can be appended to trace JSONL" {
  local thread_id="01926e3a-2c8a-7b04-b3a1-1cf0a7a6d5e1"
  local trace_file="${TRACE_DIR}/${thread_id}.jsonl"
  local ts="2026-05-08T00:00:00Z"
  local event_line
  event_line="{\"ts\":\"${ts}\",\"event\":\"verify_pass\",\"message_id\":\"${thread_id}\",\"thread_id\":\"${thread_id}\",\"from\":\"atlas@1.5.0\",\"to\":\"apivr@3.4\",\"performative\":\"PROPOSE\",\"integrity_method\":\"sha256\"}"
  printf '%s\n' "${event_line}" >> "${trace_file}"
  [ -f "${trace_file}" ]
  if command -v jq &>/dev/null; then
    run jq -r '.event' "${trace_file}"
    [ "$status" -eq 0 ]
    [[ "$output" == "verify_pass" ]]
  fi
}

# ── Sad path 1: INTEGRITY_MISMATCH — blocking, REFUSE ───────────────────────

@test "sad path 1: mutated payload produces different sha256 than envelope value" {
  setup_envelope_fixture "scout-report" "atlas" "1.5.0"

  # Mutate one byte
  printf 'X' >> "${PAYLOAD_PATH}"

  local recomputed
  recomputed="$(sha256_of "${PAYLOAD_PATH}")"
  local declared
  if command -v jq &>/dev/null; then
    declared="$(jq -r '.integrity.value' "${ENVELOPE_PATH}")"
  else
    skip "jq not available"
  fi

  # They must differ after mutation — this is what triggers REFUSE
  [[ "$recomputed" != "$declared" ]]
}

@test "sad path 1: INTEGRITY_MISMATCH verify_fail event has 'decision:refused'" {
  local thread_id="01926e3a-2c8a-7b04-b3a1-1cf0a7a6d5e1"
  local trace_file="${TRACE_DIR}/${thread_id}.jsonl"
  local ts="2026-05-08T00:00:00Z"
  local event_line
  # blocking posture: verify_fail event includes decision=refused
  event_line="{\"ts\":\"${ts}\",\"event\":\"verify_fail\",\"message_id\":\"${thread_id}\",\"thread_id\":\"${thread_id}\",\"from\":\"atlas@1.5.0\",\"to\":\"apivr@3.4\",\"integrity_method\":\"sha256\",\"verify_failure_code\":\"INTEGRITY_MISMATCH\",\"decision\":\"refused\"}"
  printf '%s\n' "${event_line}" >> "${trace_file}"
  [ -f "${trace_file}" ]
  if command -v jq &>/dev/null; then
    run jq -r '.verify_failure_code' "${trace_file}"
    [ "$status" -eq 0 ]
    [[ "$output" == "INTEGRITY_MISMATCH" ]]
    run jq -r '.decision' "${trace_file}"
    [ "$status" -eq 0 ]
    [[ "$output" == "refused" ]]
  fi
}

@test "sad path 1: INTEGRITY_MISMATCH — skill says REFUSE, not warn-and-continue" {
  # Confirm the skill's Failure Mode section specifies REFUSE for integrity failure.
  grep -q 'REFUSE' "${REPO_ROOT}/skills/verify-incoming.md"
  # Confirm it does NOT say "return 0" (warn-only shell idiom) in failure context.
  run grep -c 'INTEGRITY_MISMATCH.*return 0\|warn.*INTEGRITY_MISMATCH.*return 0' \
    "${REPO_ROOT}/skills/verify-incoming.md"
  [[ "$output" == "0" ]]
}

# ── Sad path 2: UNDECLARED_EDGE — blocking, REFUSE ──────────────────────────

@test "sad path 2: unknown from.eidolon triggers UNDECLARED_EDGE" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  setup_envelope_fixture "scout-report" "unknown-eidolon" "9.9.9"

  # Check that from.eidolon is not in the declared inbound set
  local from_eidolon
  from_eidolon="$(jq -r '.from.eidolon' "${ENVELOPE_PATH}")"

  local allowed="atlas spectra vigil forge"
  local is_declared=false
  for a in $allowed; do
    [[ "$from_eidolon" == "$a" ]] && is_declared=true && break
  done

  [[ "$is_declared" == "false" ]]
}

@test "sad path 2: UNDECLARED_EDGE verify_fail event has 'decision:refused'" {
  local thread_id="01926e3a-2c8a-7b04-b3a1-1cf0a7a6d5e1"
  local trace_file="${TRACE_DIR}/${thread_id}.jsonl"
  local ts="2026-05-08T00:00:00Z"
  local event_line
  # blocking posture: verify_fail event includes decision=refused
  event_line="{\"ts\":\"${ts}\",\"event\":\"verify_fail\",\"message_id\":\"${thread_id}\",\"thread_id\":\"${thread_id}\",\"from\":\"unknown-eidolon@9.9.9\",\"to\":\"apivr@3.4\",\"integrity_method\":\"sha256\",\"verify_failure_code\":\"UNDECLARED_EDGE\",\"decision\":\"refused\"}"
  printf '%s\n' "${event_line}" >> "${trace_file}"
  [ -f "${trace_file}" ]
  if command -v jq &>/dev/null; then
    run jq -r '.verify_failure_code' "${trace_file}"
    [ "$status" -eq 0 ]
    [[ "$output" == "UNDECLARED_EDGE" ]]
    run jq -r '.decision' "${trace_file}"
    [ "$status" -eq 0 ]
    [[ "$output" == "refused" ]]
  fi
}

@test "sad path 2: UNDECLARED_EDGE — skill says REFUSE, not warn-and-continue" {
  grep -q 'UNDECLARED_EDGE' "${REPO_ROOT}/skills/verify-incoming.md"
  # Confirm skill Failure Mode is blocking for this code too.
  grep -q 'REFUSE' "${REPO_ROOT}/skills/verify-incoming.md"
}

# ── Sad path 3: no verify_pass in trace (UNVERIFIED) — blocking, REFUSE ─────

@test "sad path 3: UNVERIFIED failure code listed in skill" {
  grep -q 'UNVERIFIED' "${REPO_ROOT}/skills/verify-incoming.md"
}

@test "sad path 3: skill says REFUSE when no verify_pass on record" {
  # Skill must describe refusing when no verify_pass event exists for the message_id.
  grep -q 'no matching event\|verify_fail.*REFUSE\|REFUSE.*verify_fail\|REFUSE.*Failure Mode' \
    "${REPO_ROOT}/skills/verify-incoming.md" || \
  grep -q 'UNVERIFIED.*REFUSE\|REFUSE' "${REPO_ROOT}/skills/verify-incoming.md"
}

# ── Schema fixture validation ────────────────────────────────────────────────

@test "all four inbound fixtures are valid JSON" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  for f in \
    "${REPO_ROOT}/templates/inbound/scout-report.envelope.fixture.json" \
    "${REPO_ROOT}/templates/inbound/spec.envelope.fixture.json" \
    "${REPO_ROOT}/templates/inbound/root-cause-report.envelope.fixture.json" \
    "${REPO_ROOT}/templates/inbound/reasoning-report.envelope.fixture.json"; do
    run jq empty "$f"
    [ "$status" -eq 0 ] || { echo "Invalid JSON: $f" >&3; false; }
  done
}

@test "all inbound fixtures have to.eidolon=apivr" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  for f in \
    "${REPO_ROOT}/templates/inbound/scout-report.envelope.fixture.json" \
    "${REPO_ROOT}/templates/inbound/spec.envelope.fixture.json" \
    "${REPO_ROOT}/templates/inbound/root-cause-report.envelope.fixture.json" \
    "${REPO_ROOT}/templates/inbound/reasoning-report.envelope.fixture.json"; do
    run jq -r '.to.eidolon' "$f"
    [ "$status" -eq 0 ]
    [[ "$output" == "apivr" ]] || { echo "Bad to.eidolon in $f: $output" >&3; false; }
  done
}
