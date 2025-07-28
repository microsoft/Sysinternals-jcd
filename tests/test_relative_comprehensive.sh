#!/bin/bash

# Comprehensive test for JCD relative path functionality
# This script tests all the new relative path features

echo "=== JCD Relative Path Functionality Test ==="
echo "Testing enhanced directory navigation with relative paths"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test result counters
PASSED=0
FAILED=0

# Test function
test_jcd() {
    local description="$1"
    local command="$2"
    local expected_pattern="$3"
    local current_dir="$(pwd)"

    echo -e "\n${YELLOW}Test:${NC} $description"
    echo "Command: $command"
    echo "Current dir: $current_dir"

    # Execute the command
    local result
    result=$(eval "$command" 2>&1)
    local exit_code=$?

    echo "Result: $result"
    echo "Exit code: $exit_code"

    if [[ $exit_code -eq 0 ]] && [[ "$result" =~ $expected_pattern ]]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "Expected pattern: $expected_pattern"
        ((FAILED++))
    fi
}

# Setup test environment
echo -e "\n=== Setting up test environment ==="
TEST_ROOT="/tmp/jcd_test_comprehensive"
rm -rf "$TEST_ROOT"
mkdir -p "$TEST_ROOT"/{parent/{child1,child2,subdir/{deep1,deep2}},sibling/{sub1,sub2},foo/{bar,baz,foobar},test/{project1,project2}}

echo "Created test directory structure:"
tree "$TEST_ROOT" 2>/dev/null || find "$TEST_ROOT" -type d | sort

# Test binary directly
echo -e "\n=== Testing JCD Binary Directly ==="

cd "$TEST_ROOT/parent/child1"

# Test 1: Basic parent navigation
test_jcd "Navigate to parent with '..'" \
         "/datadrive/jcd/target/release/jcd '..'" \
         ".*/parent$"

# Test 2: Multi-level navigation
test_jcd "Navigate two levels up with '../..'" \
         "/datadrive/jcd/target/release/jcd '../..'" \
         ".*/jcd_test_comprehensive$"

# Test 3: Relative pattern search
test_jcd "Search for 'child2' from parent level" \
         "/datadrive/jcd/target/release/jcd '../child2'" \
         ".*/child2$"

# Test 4: Deep relative search
test_jcd "Search for 'foo' from grandparent level" \
         "/datadrive/jcd/target/release/jcd '../../foo'" \
         ".*/foo$"

# Test 5: Multi-match relative search
test_jcd "Find all matches for '../ch' pattern" \
         "/datadrive/jcd/target/release/jcd '../ch' 0" \
         ".*/child[12]$"

# Test shell function
echo -e "\n=== Testing JCD Shell Function ==="

# Source the function
source /datadrive/jcd/jcd_function.sh

cd "$TEST_ROOT/parent/child1"
echo "Starting directory: $(pwd)"

# Test shell function navigation
echo -e "\n${YELLOW}Testing shell function navigation:${NC}"

echo "jcd '..' -> "
jcd ".."
if [[ "$(pwd)" == "$TEST_ROOT/parent" ]]; then
    echo -e "${GREEN}✓ PASSED${NC} - Now in parent directory"
    ((PASSED++))
else
    echo -e "${RED}✗ FAILED${NC} - Expected parent directory, got $(pwd)"
    ((FAILED++))
fi

echo "jcd 'child1' -> "
jcd "child1"
if [[ "$(pwd)" == "$TEST_ROOT/parent/child1" ]]; then
    echo -e "${GREEN}✓ PASSED${NC} - Back in child1"
    ((PASSED++))
else
    echo -e "${RED}✗ FAILED${NC} - Expected child1, got $(pwd)"
    ((FAILED++))
fi

echo "jcd '../..' -> "
jcd "../.."
if [[ "$(pwd)" == "$TEST_ROOT" ]]; then
    echo -e "${GREEN}✓ PASSED${NC} - Now in test root"
    ((PASSED++))
else
    echo -e "${RED}✗ FAILED${NC} - Expected test root, got $(pwd)"
    ((FAILED++))
fi

echo "jcd 'parent/child2' -> "
jcd "parent/child2"
if [[ "$(pwd)" == "$TEST_ROOT/parent/child2" ]]; then
    echo -e "${GREEN}✓ PASSED${NC} - Now in child2"
    ((PASSED++))
else
    echo -e "${RED}✗ FAILED${NC} - Expected child2, got $(pwd)"
    ((FAILED++))
fi

# Test tab completion (manual instructions)
echo -e "\n=== Tab Completion Test Instructions ==="
echo "To test tab completion manually, run these commands:"
echo "1. cd $TEST_ROOT/parent/child1"
echo "2. Type: jcd ../<TAB>     (should show child1, child2, subdir)"
echo "3. Type: jcd ../c<TAB>    (should cycle forward between child1, child2)"
echo "4. Type: jcd ../c<Shift+TAB> (should cycle backward between child1, child2)"
echo "5. Type: jcd ../../<TAB>  (should show parent, sibling, foo, test)"
echo "6. Type: jcd ../sub<TAB>  (should complete to ../subdir/)"
echo "7. Type: jcd ../subdir/<TAB> (should show deep1, deep2)"
echo ""
echo "NEW: Shift+Tab support added for backward cycling through matches!"

# Performance test
echo -e "\n=== Performance Test ==="
cd "$TEST_ROOT/parent/child1"

echo "Testing search performance with relative patterns..."
time_start=$(date +%s%N)
for i in {1..10}; do
    /datadrive/jcd/target/release/jcd "../ch" >/dev/null 2>&1
done
time_end=$(date +%s%N)
duration=$(( (time_end - time_start) / 1000000 ))  # Convert to milliseconds

echo "10 searches completed in ${duration}ms (average: $((duration/10))ms per search)"

if [[ $duration -lt 1000 ]]; then
    echo -e "${GREEN}✓ PERFORMANCE GOOD${NC} - Under 1 second for 10 searches"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ PERFORMANCE SLOW${NC} - Over 1 second for 10 searches"
fi

# Cleanup
echo -e "\n=== Cleanup ==="
rm -rf "$TEST_ROOT"
echo "Test environment cleaned up"

# Summary
echo -e "\n=== Test Summary ==="
total=$((PASSED + FAILED))
echo "Total tests: $total"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [[ $FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 All tests passed! Relative path functionality is working correctly.${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed. Please check the implementation.${NC}"
    exit 1
fi
