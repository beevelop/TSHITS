#!/usr/bin/env bash
# test-bc-cli.sh - Test the bc CLI helper
# Usage: ./scripts/test-bc-cli.sh

set -euo pipefail

# Find the repository root (parent of .github directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BC_CLI="${REPO_ROOT}/scripts/bc"

# Colors for output
if [[ -t 1 ]]; then
  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[0;33m'
  readonly CYAN='\033[0;36m'
  readonly NC='\033[0m'
else
  readonly RED='' GREEN='' YELLOW='' CYAN='' NC=''
fi

TESTS_PASSED=0
TESTS_FAILED=0

log() {
  echo -e "${CYAN}[test]${NC} $*"
}

pass() {
  echo -e "${GREEN}[PASS]${NC} $*"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
  echo -e "${RED}[FAIL]${NC} $*"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Test: bc exists and is executable
test_bc_exists() {
  log "Testing bc script exists and is executable..."
  if [[ -x "$BC_CLI" ]]; then
    pass "bc script is executable"
  else
    fail "bc script not found or not executable: $BC_CLI"
  fi
}

# Test: bc help command
test_help() {
  log "Testing bc help command..."
  local output
  if output=$("$BC_CLI" help 2>&1); then
    if echo "$output" | grep -q "BeeCompose CLI Helper"; then
      pass "bc help works"
    else
      fail "bc help missing expected content"
    fi
  else
    fail "bc help failed"
  fi
}

# Test: bc --help flag
test_help_flag() {
  log "Testing bc --help flag..."
  local output
  if output=$("$BC_CLI" --help 2>&1); then
    if echo "$output" | grep -q "USAGE:"; then
      pass "bc --help flag works"
    else
      fail "bc --help missing expected content"
    fi
  else
    fail "bc --help failed"
  fi
}

# Test: bc version command
test_version() {
  log "Testing bc version command..."
  local output
  if output=$("$BC_CLI" version 2>&1); then
    if echo "$output" | grep -q "bc (BeeCompose CLI) version"; then
      pass "bc version works"
    else
      fail "bc version missing expected content"
    fi
  else
    fail "bc version failed"
  fi
}

# Test: bc list command
test_list() {
  log "Testing bc list command..."
  local output
  if output=$("$BC_CLI" list 2>&1); then
    if echo "$output" | grep -q "metabase"; then
      pass "bc list works"
    else
      fail "bc list missing expected services"
    fi
  else
    fail "bc list failed"
  fi
}

# Test: bc init creates config file
test_init() {
  log "Testing bc init command..."
  local tmp_dir
  tmp_dir=$(mktemp -d)
  trap "rm -rf $tmp_dir" RETURN
  
  pushd "$tmp_dir" > /dev/null
  
  if "$BC_CLI" init v26.1.6 2>&1; then
    if [[ -f .beecompose ]]; then
      if grep -q "BEECOMPOSE_VERSION=v26.1.6" .beecompose; then
        pass "bc init creates config with correct version"
      else
        fail "bc init config missing correct version"
      fi
    else
      fail "bc init did not create .beecompose file"
    fi
  else
    fail "bc init failed"
  fi
  
  popd > /dev/null
}

# Test: Version resolution from .beecompose file
test_version_from_config() {
  log "Testing version resolution from .beecompose file..."
  local tmp_dir
  tmp_dir=$(mktemp -d)
  trap "rm -rf $tmp_dir" RETURN
  
  pushd "$tmp_dir" > /dev/null
  
  echo "BEECOMPOSE_VERSION=v1.2.3" > .beecompose
  
  # Use debug mode to see version resolution
  local output
  if output=$(BEECOMPOSE_DEBUG=1 "$BC_CLI" metabase config 2>&1 || true); then
    if echo "$output" | grep -q "v1.2.3"; then
      pass "Version resolution from .beecompose works"
    else
      fail "Version not read from .beecompose file"
    fi
  else
    fail "Version resolution test failed"
  fi
  
  popd > /dev/null
}

# Test: Version override via -v flag
test_version_override() {
  log "Testing version override via -v flag..."
  
  # Use debug mode to see version resolution
  local output
  if output=$(BEECOMPOSE_DEBUG=1 "$BC_CLI" -v v99.9.9 metabase config 2>&1 || true); then
    if echo "$output" | grep -q "v99.9.9"; then
      pass "Version override via -v flag works"
    else
      fail "Version override not applied"
    fi
  else
    fail "Version override test failed"
  fi
}

# Test: Environment variable override
test_env_version() {
  log "Testing version from BEECOMPOSE_VERSION env..."
  
  local output
  if output=$(BEECOMPOSE_VERSION=v88.8.8 BEECOMPOSE_DEBUG=1 "$BC_CLI" metabase config 2>&1 || true); then
    if echo "$output" | grep -q "v88.8.8"; then
      pass "BEECOMPOSE_VERSION environment variable works"
    else
      fail "BEECOMPOSE_VERSION not applied"
    fi
  else
    fail "Environment variable test failed"
  fi
}

# Test: Missing service error
test_missing_service() {
  log "Testing error handling for missing command..."
  local output
  if output=$("$BC_CLI" metabase 2>&1); then
    fail "Should have failed with missing command"
  else
    if echo "$output" | grep -qi "missing command\|usage"; then
      pass "Missing command error handled correctly"
    else
      fail "Missing command error not helpful"
    fi
  fi
}

# Test: Bash syntax check
test_syntax() {
  log "Testing bash syntax..."
  if bash -n "$BC_CLI" 2>&1; then
    pass "bc script has valid bash syntax"
  else
    fail "bc script has syntax errors"
  fi
}

# Test: Shellcheck (if available)
test_shellcheck() {
  log "Testing with shellcheck..."
  if command -v shellcheck &> /dev/null; then
    if shellcheck -x "$BC_CLI" 2>&1; then
      pass "shellcheck passed"
    else
      fail "shellcheck found issues"
    fi
  else
    echo -e "${YELLOW}[SKIP]${NC} shellcheck not installed"
  fi
}

# Run all tests
main() {
  echo ""
  echo "==================================="
  echo "  BeeCompose CLI Tests"
  echo "==================================="
  echo ""
  
  test_bc_exists
  test_syntax
  test_help
  test_help_flag
  test_version
  test_list
  test_init
  test_version_from_config
  test_version_override
  test_env_version
  test_missing_service
  test_shellcheck
  
  echo ""
  echo "==================================="
  echo "  Results"
  echo "==================================="
  echo ""
  echo -e "Passed: ${GREEN}${TESTS_PASSED}${NC}"
  echo -e "Failed: ${RED}${TESTS_FAILED}${NC}"
  echo ""
  
  if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
  fi
  
  echo -e "${GREEN}All tests passed!${NC}"
}

main "$@"
