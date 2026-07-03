#!/usr/bin/env bats
# tests/emit-completion-report.bats — completion-report emit conformance

load helpers.bash

setup() {
  setup_envelope_fixture "apivr-completion-report" "apivr" "3.7.1"
}

teardown() {
  teardown_fixture
}

@test "fixture envelope is valid JSON" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq empty "${ENVELOPE_PATH}"
  [ "$status" -eq 0 ]
}

@test "fixture envelope_version is 2.0" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.envelope_version' "${ENVELOPE_PATH}"
  [ "$status" -eq 0 ]
  [[ "$output" == "2.0" ]]
}

@test "fixture from.eidolon is apivr" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.from.eidolon' "${ENVELOPE_PATH}"
  [ "$status" -eq 0 ]
  [[ "$output" == "apivr" ]]
}

@test "fixture to.eidolon is idg for completion-report" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  # The template sets to=idg; the fixture helper uses to=apivr (inbound).
  # For outbound, we check the template directly.
  run jq -r '.to.eidolon' "${REPO_ROOT}/templates/apivr-completion-report.envelope.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "idg" ]]
}

@test "template performative is PROPOSE" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.performative' "${REPO_ROOT}/templates/apivr-completion-report.envelope.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "PROPOSE" ]]
}

@test "template artifact.kind is apivr-completion-report" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.artifact.kind' "${REPO_ROOT}/templates/apivr-completion-report.envelope.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "apivr-completion-report" ]]
}

@test "template envelope_version is 2.0 (ECL v2.0 adoption)" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.envelope_version' "${REPO_ROOT}/templates/apivr-completion-report.envelope.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "2.0" ]]
}

@test "template carries an ise block with assertion_grade self-attested" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.ise.assertion_grade' "${REPO_ROOT}/templates/apivr-completion-report.envelope.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "self-attested" ]]
}

@test "template ise.receiver_authorization matches ECL v2.0 §6.5.3 defaults" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -c '.ise.receiver_authorization' "${REPO_ROOT}/templates/apivr-completion-report.envelope.json"
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
env = json.load(open('${REPO_ROOT}/templates/apivr-completion-report.envelope.json'))
jsonschema.Draft202012Validator(schema, format_checker=jsonschema.FormatChecker()).validate(env)
"
  [ "$status" -eq 0 ] || { echo "$output" >&3; false; }
}

@test "integrity sha256 recompute matches declared value in fixture" {
  computed="$(sha256_of "${PAYLOAD_PATH}")"
  declared="$(jq -r '.integrity.value' "${ENVELOPE_PATH}" 2>/dev/null || echo "jq-missing")"
  if [[ "$declared" == "jq-missing" ]]; then
    skip "jq not available"
  fi
  [[ "$computed" == "$declared" ]]
}

@test "profile schema ref validates base fields" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  # Check that the profile schema has the required allOf structure
  run jq '.allOf | length' "${REPO_ROOT}/schemas/apivr-completion-report-profile.v1.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "2" ]]
}

@test "profile schema requires files_changed_count tests_run tests_passed" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.allOf[1].required[]' "${REPO_ROOT}/schemas/apivr-completion-report-profile.v1.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"files_changed_count"* ]]
  [[ "$output" == *"tests_run"* ]]
  [[ "$output" == *"tests_passed"* ]]
}
