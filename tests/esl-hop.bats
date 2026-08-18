#!/usr/bin/env bats
# tests/esl-hop.bats — ESL lifecycle hop skill (maker != checker, ESL C4/C8)

load helpers.bash

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

# ── Skill content assertions ────────────────────────────────────────────────

@test "esl-hop skill file exists" {
  [ -f "${REPO_ROOT}/skills/esl-hop/SKILL.md" ]
}

@test "esl-hop skill frontmatter name is apivr-esl-hop" {
  grep -q 'name: apivr-esl-hop' "${REPO_ROOT}/skills/esl-hop/SKILL.md"
}

@test "esl-hop skill frontmatter has metadata block with methodology" {
  grep -q 'metadata:' "${REPO_ROOT}/skills/esl-hop/SKILL.md"
  grep -q 'methodology: APIVR-Δ' "${REPO_ROOT}/skills/esl-hop/SKILL.md"
}

@test "esl-hop skill declares APIVR-Δ as MAKER" {
  grep -q 'MAKER' "${REPO_ROOT}/skills/esl-hop/SKILL.md"
}

@test "esl-hop skill states maker != checker invariant" {
  grep -qE 'maker\(apivr\) ≠ checker|maker != checker|maker ≠ checker' \
    "${REPO_ROOT}/skills/esl-hop/SKILL.md"
}

@test "esl-hop skill says it does NOT self-verify" {
  grep -qE 'NEVER self-verify|do not self-verify|does NOT self-verify' \
    "${REPO_ROOT}/skills/esl-hop/SKILL.md"
}

@test "esl-hop skill hands off via ECL PROPOSE" {
  grep -q 'PROPOSE' "${REPO_ROOT}/skills/esl-hop/SKILL.md"
}

@test "esl-hop skill names Kupo and VIGIL as checker candidates" {
  grep -q 'Kupo' "${REPO_ROOT}/skills/esl-hop/SKILL.md"
  grep -q 'VIGIL' "${REPO_ROOT}/skills/esl-hop/SKILL.md"
}

@test "esl-hop skill cites tonberry C4 mechanical enforcement" {
  grep -q 'tonberry' "${REPO_ROOT}/skills/esl-hop/SKILL.md"
  grep -q 'C4' "${REPO_ROOT}/skills/esl-hop/SKILL.md"
}

@test "esl-hop skill cites C8 as advisory" {
  grep -q 'C8' "${REPO_ROOT}/skills/esl-hop/SKILL.md"
}

@test "esl-hop skill declares graceful skip when tonberry unavailable" {
  grep -qi 'graceful skip' "${REPO_ROOT}/skills/esl-hop/SKILL.md"
  grep -qi 'never hard-fail' "${REPO_ROOT}/skills/esl-hop/SKILL.md"
}

@test "esl-hop skill references self-attested ise on its emitted envelopes" {
  grep -q 'self-attested' "${REPO_ROOT}/skills/esl-hop/SKILL.md"
}

# ── install.sh registration check ───────────────────────────────────────────




# ── install run: skill lands in target + manifest ───────────────────────────




@test "PERSONA.md skill loading table references esl-hop.md" {
  grep -q 'skills/esl-hop/SKILL.md' "${REPO_ROOT}/PERSONA.md"
}
