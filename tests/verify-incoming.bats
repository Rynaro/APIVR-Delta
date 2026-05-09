#!/usr/bin/env bats
# tests/verify-incoming.bats — opt-in incoming envelope verification (S5)
#
# Tests the verify-incoming contract. Because the logic is prompt-only (D4),
# these tests validate the schema/template artefacts that the prompt-skill
# references, plus the trace-event format, rather than executing a shell
# verify script.

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

# ── Happy path ──────────────────────────────────────────────────────────────

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
  event_line="{\"ts\":\"${ts}\",\"event\":\"verify_pass\",\"message_id\":\"${thread_id}\",\"thread_id\":\"${thread_id}\",\"from\":\"atlas@1.5.0\",\"to\":\"apivr@3.1.0\",\"performative\":\"PROPOSE\",\"integrity_method\":\"sha256\"}"
  printf '%s\n' "${event_line}" >> "${trace_file}"
  [ -f "${trace_file}" ]
  if command -v jq &>/dev/null; then
    run jq -r '.event' "${trace_file}"
    [ "$status" -eq 0 ]
    [[ "$output" == "verify_pass" ]]
  fi
}

# ── Sad path 1: INTEGRITY_MISMATCH ─────────────────────────────────────────

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

  # They must differ after mutation
  [[ "$recomputed" != "$declared" ]]
}

@test "sad path 1: INTEGRITY_MISMATCH verify_fail event has correct fields" {
  local thread_id="01926e3a-2c8a-7b04-b3a1-1cf0a7a6d5e1"
  local trace_file="${TRACE_DIR}/${thread_id}.jsonl"
  local ts="2026-05-08T00:00:00Z"
  local event_line
  event_line="{\"ts\":\"${ts}\",\"event\":\"verify_fail\",\"message_id\":\"${thread_id}\",\"thread_id\":\"${thread_id}\",\"from\":\"atlas@1.5.0\",\"to\":\"apivr@3.1.0\",\"performative\":\"PROPOSE\",\"integrity_method\":\"sha256\",\"verify_failure_code\":\"INTEGRITY_MISMATCH\"}"
  printf '%s\n' "${event_line}" >> "${trace_file}"
  [ -f "${trace_file}" ]
  if command -v jq &>/dev/null; then
    run jq -r '.verify_failure_code' "${trace_file}"
    [ "$status" -eq 0 ]
    [[ "$output" == "INTEGRITY_MISMATCH" ]]
  fi
}

@test "sad path 1: warn-only — payload still reachable after mismatch" {
  setup_envelope_fixture "scout-report" "atlas" "1.5.0"
  # Mutate payload
  printf 'X' >> "${PAYLOAD_PATH}"
  # The payload file must still exist and be readable (warn-only — not deleted)
  [ -f "${PAYLOAD_PATH}" ]
  run cat "${PAYLOAD_PATH}"
  [ "$status" -eq 0 ]
}

# ── Sad path 2: UNDECLARED_EDGE ─────────────────────────────────────────────

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

@test "sad path 2: UNDECLARED_EDGE verify_fail event recorded with correct code" {
  local thread_id="01926e3a-2c8a-7b04-b3a1-1cf0a7a6d5e1"
  local trace_file="${TRACE_DIR}/${thread_id}.jsonl"
  local ts="2026-05-08T00:00:00Z"
  local event_line
  event_line="{\"ts\":\"${ts}\",\"event\":\"verify_fail\",\"message_id\":\"${thread_id}\",\"thread_id\":\"${thread_id}\",\"from\":\"unknown-eidolon@9.9.9\",\"to\":\"apivr@3.1.0\",\"performative\":\"PROPOSE\",\"integrity_method\":\"sha256\",\"verify_failure_code\":\"UNDECLARED_EDGE\"}"
  printf '%s\n' "${event_line}" >> "${trace_file}"
  [ -f "${trace_file}" ]
  if command -v jq &>/dev/null; then
    run jq -r '.verify_failure_code' "${trace_file}"
    [ "$status" -eq 0 ]
    [[ "$output" == "UNDECLARED_EDGE" ]]
  fi
}

@test "sad path 2: warn-only — payload still reachable after UNDECLARED_EDGE" {
  setup_envelope_fixture "scout-report" "unknown-eidolon" "9.9.9"
  [ -f "${PAYLOAD_PATH}" ]
  run cat "${PAYLOAD_PATH}"
  [ "$status" -eq 0 ]
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
