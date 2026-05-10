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
