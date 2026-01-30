#!/bin/bash
set -T

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test if the $_ variable is preserved correctly
function test_underscore_variable {
  echo -e "\n${YELLOW}Testing that \$_ variable is not affected:${NC}"

  # shellcheck disable=SC2016
  local cmd_to_run='echo This is a \$_ test by _unique_string_'
  local expected='_unique_string_'

  echo "Running: '${cmd_to_run}'"

  # Execute the command.
  eval "$cmd_to_run" > /dev/null

  # The DEBUG trap in jcd_function.sh triggers here.
  # If the fix is missing, $_ will be overwritten by internal jcd commands.

  # Capture $_ immediately
  local actual="$_"

  echo "Expected: '${expected}'"
  echo "Actual:   '${actual}'"

  if [[ "$actual" == "$expected" ]]; then
    echo -e "${GREEN}✓ PASSED${NC} - \$_ variable is as expected.\n"
  else
    echo -e "${RED}✗ FAILED${NC} - \$_ variable is NOT as expected!\n"
    return 1
  fi
}


echo -e "\n${BLUE}=== Testing that standard bash behavior is not affected ===${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the shell function
source "$SCRIPT_DIR/../src/jcd_function.sh"

declare -i _failed=0

# Run tests
test_underscore_variable || (( _failed++ ))

# Summary
exit $(( _failed ))
