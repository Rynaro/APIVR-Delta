#!/usr/bin/env bats
# tests/emit-repair-failed-report.bats — repair-failed-report emit conformance

load helpers.bash

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
TEMPLATE="${REPO_ROOT}/templates/repair-failed-report.envelope.json"

@test "repair-failed-report template exists" {
  [ -f "${TEMPLATE}" ]
}

@test "repair-failed-report template is valid JSON" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq empty "${TEMPLATE}"
  [ "$status" -eq 0 ]
}

@test "performative is ESCALATE" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.performative' "${TEMPLATE}"
  [ "$status" -eq 0 ]
  [[ "$output" == "ESCALATE" ]]
}

@test "trust_level is high" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.constraints.trust_level' "${TEMPLATE}"
  [ "$status" -eq 0 ]
  [[ "$output" == "high" ]]
}

@test "assumptions[0] is the trigger string (ECL §2.2.3)" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.assumptions[0]' "${TEMPLATE}"
  [ "$status" -eq 0 ]
  [[ "$output" == "trigger: 3-failure-same-category" ]]
}

@test "to.eidolon is vigil" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.to.eidolon' "${TEMPLATE}"
  [ "$status" -eq 0 ]
  [[ "$output" == "vigil" ]]
}

@test "from.eidolon is apivr" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.from.eidolon' "${TEMPLATE}"
  [ "$status" -eq 0 ]
  [[ "$output" == "apivr" ]]
}

@test "artifact.kind is repair-failed-report" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.artifact.kind' "${TEMPLATE}"
  [ "$status" -eq 0 ]
  [[ "$output" == "repair-failed-report" ]]
}

@test "profile schema minimum attempts is 3" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.allOf[1].properties.attempts.minimum' \
    "${REPO_ROOT}/schemas/repair-failed-report-profile.v1.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "3" ]]
}

@test "profile schema requires failure_category and last_test_command" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.allOf[1].required[]' \
    "${REPO_ROOT}/schemas/repair-failed-report-profile.v1.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"failure_category"* ]]
  [[ "$output" == *"last_test_command"* ]]
}
