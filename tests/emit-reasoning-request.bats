#!/usr/bin/env bats
# tests/emit-reasoning-request.bats — reasoning-request emit conformance (base-profile only, D1)

load helpers.bash

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
TEMPLATE="${REPO_ROOT}/templates/reasoning-request.envelope.json"

@test "reasoning-request template exists" {
  [ -f "${TEMPLATE}" ]
}

@test "reasoning-request template is valid JSON" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq empty "${TEMPLATE}"
  [ "$status" -eq 0 ]
}

@test "performative is REQUEST" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.performative' "${TEMPLATE}"
  [ "$status" -eq 0 ]
  [[ "$output" == "REQUEST" ]]
}

@test "to.eidolon is forge" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.to.eidolon' "${TEMPLATE}"
  [ "$status" -eq 0 ]
  [[ "$output" == "forge" ]]
}

@test "from.eidolon is apivr" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.from.eidolon' "${TEMPLATE}"
  [ "$status" -eq 0 ]
  [[ "$output" == "apivr" ]]
}

@test "artifact.kind is reasoning-request" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.artifact.kind' "${TEMPLATE}"
  [ "$status" -eq 0 ]
  [[ "$output" == "reasoning-request" ]]
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

@test "trust_level is standard (base-profile only, D1)" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.constraints.trust_level' "${TEMPLATE}"
  [ "$status" -eq 0 ]
  [[ "$output" == "standard" ]]
}

@test "base-profile schema has required eidolon version kind status created_at" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.required[]' "${REPO_ROOT}/schemas/_base-profile.v1.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"eidolon"* ]]
  [[ "$output" == *"version"* ]]
  [[ "$output" == *"kind"* ]]
  [[ "$output" == *"status"* ]]
  [[ "$output" == *"created_at"* ]]
}

@test "no reasoning-request-specific profile schema exists (D1: base-only)" {
  # D1 decision: reasoning-request validates against _base-profile.v1.json only.
  # No dedicated reasoning-request-profile.v1.json should exist.
  [ ! -f "${REPO_ROOT}/schemas/reasoning-request-profile.v1.json" ]
}
