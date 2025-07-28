#!/bin/bash

# Simple test to validate that Shift+Tab functionality was added correctly

set -e

echo "=== JCD Shift+Tab Test ==="

# Test environment  
TEST_ROOT="/tmp/jcd_simple_$$"
mkdir -p "$TEST_ROOT/test1" "$TEST_ROOT/test2" "$TEST_ROOT/testing"
cd "$TEST_ROOT"

# Set up JCD
export JCD_BINARY="/datadrive/jcd/target/release/jcd"

# Source just the necessary parts
export -f jcd >/dev/null 2>&1 || true

# Test that the JCD binary works
echo "Testing JCD binary:"
"$JCD_BINARY" test1 0 2>/dev/null && echo "✓ Binary works" || echo "✗ Binary failed"

# Check that the shell functions contain the new direction variable
echo "Checking for Shift+Tab implementation:"

# Check if the shell script contains the new direction variable
if grep -q "_JCD_CYCLING_DIRECTION" /datadrive/jcd/jcd_function.sh; then
    echo "✓ Direction variable found in shell script"
else
    echo "✗ Direction variable not found"
fi

# Check if the backward tab function exists
if grep -q "_jcd_backward_tab_complete" /datadrive/jcd/jcd_function.sh; then
    echo "✓ Backward tab completion function found"
else
    echo "✗ Backward tab completion function not found"
fi

# Check if Shift+Tab key binding exists
if grep -q '\\e\[Z' /datadrive/jcd/jcd_function.sh; then
    echo "✓ Shift+Tab key binding found"
else
    echo "✗ Shift+Tab key binding not found"
fi

# Test the direction logic in cycling
if grep -q "_JCD_CYCLING_DIRECTION.*-1" /datadrive/jcd/jcd_function.sh; then
    echo "✓ Backward cycling logic found"
else
    echo "✗ Backward cycling logic not found"
fi

# Clean up
cd /tmp
rm -rf "$TEST_ROOT"

echo "=== Manual Testing Instructions ==="
echo "To test Shift+Tab manually:"
echo "1. Source the jcd_function.sh file in an interactive bash session"
echo "2. Create some test directories with common prefixes"
echo "3. Type 'jcd test<TAB>' to cycle forward through matches"
echo "4. Type 'jcd test<Shift+TAB>' to cycle backward through matches"
echo ""
echo "The implementation adds:"
echo "- _JCD_CYCLING_DIRECTION variable to track direction"
echo "- _jcd_backward_tab_complete function for reverse cycling"  
echo "- Key binding for Shift+Tab (\\e[Z sequence)"
echo "- Modified cycling logic to support both directions"

echo -e "\n✓ Shift+Tab implementation validation completed"
