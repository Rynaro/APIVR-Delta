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

@test "envelope_version is 2.0 (ECL v2.0 adoption)" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.envelope_version' "${TEMPLATE}"
  [ "$status" -eq 0 ]
  [[ "$output" == "2.0" ]]
}

@test "template carries an ise block with assertion_grade self-attested" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.ise.assertion_grade' "${TEMPLATE}"
  [ "$status" -eq 0 ]
  [[ "$output" == "self-attested" ]]
}

@test "template ise.receiver_authorization matches ECL v2.0 §6.5.3 defaults" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -c '.ise.receiver_authorization' "${TEMPLATE}"
  [ "$status" -eq 0 ]
  [[ "$output" == '{"auto_route":true,"auto_merge":false,"auto_deploy":false}' ]]
}

@test "template validates against the vendored v2 envelope schema" {
  if ! command -v python3 &>/dev/null; then
    skip "python3 not available"
  fi
  run python3 -c "import jsonschema" 2>/dev/null
  [ "$status" -eq 0 ] || skip "jsonschema module not available"
  run python3 -c "
import json
import jsonschema
schema = json.load(open('${REPO_ROOT}/schemas/ecl-envelope.v2.json'))
env = json.load(open('${TEMPLATE}'))
jsonschema.Draft202012Validator(schema, format_checker=jsonschema.FormatChecker()).validate(env)
"
  [ "$status" -eq 0 ] || { echo "$output" >&3; false; }
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
