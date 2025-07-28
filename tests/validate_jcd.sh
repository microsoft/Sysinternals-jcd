#!/bin/bash

# Quick validation script for JCD functionality
echo "=== JCD Quick Validation ==="

# Check if binary exists and is executable
if [[ -x "/datadrive/jcd/target/release/jcd" ]]; then
    echo "✓ Binary exists and is executable"
else
    echo "✗ Binary not found or not executable"
    exit 1
fi

# Test basic binary functionality
echo "Testing binary functionality..."

# Create test structure
mkdir -p /tmp/jcd_test/{parent/{child1,child2},sibling}
cd /tmp/jcd_test/parent/child1

# Test parent navigation
result=$(/datadrive/jcd/target/release/jcd ".." 2>/dev/null)
if [[ "$result" == "/tmp/jcd_test/parent" ]]; then
    echo "✓ Parent navigation works"
else
    echo "✗ Parent navigation failed. Got: '$result'"
fi

# Test multi-level navigation
result=$(/datadrive/jcd/target/release/jcd "../.." 2>/dev/null)
if [[ "$result" == "/tmp/jcd_test" ]]; then
    echo "✓ Multi-level navigation works"
else
    echo "✗ Multi-level navigation failed. Got: '$result'"
fi

# Test relative pattern search
result=$(/datadrive/jcd/target/release/jcd "../child2" 2>/dev/null)
if [[ "$result" == "/tmp/jcd_test/parent/child2" ]]; then
    echo "✓ Relative pattern search works"
else
    echo "✗ Relative pattern search failed. Got: '$result'"
fi

# Test shell function
echo "Testing shell function..."
source /datadrive/jcd/jcd_function.sh

# Test function existence
if declare -f jcd > /dev/null; then
    echo "✓ Shell function loaded"
else
    echo "✗ Shell function not loaded"
fi

# Test shell function navigation
cd /tmp/jcd_test/parent/child1
jcd ".." 2>/dev/null
if [[ "$(pwd)" == "/tmp/jcd_test/parent" ]]; then
    echo "✓ Shell function navigation works"
else
    echo "✗ Shell function navigation failed. Current dir: $(pwd)"
fi

# Test Shift+Tab functionality
echo "Testing Shift+Tab functionality..."

# Check if direction variable exists
if grep -q "_JCD_CYCLING_DIRECTION" /datadrive/jcd/jcd_function.sh; then
    echo "✓ Shift+Tab direction support found"
else
    echo "✗ Shift+Tab direction support missing"
fi

# Check if backward completion function exists
if declare -f _jcd_backward_tab_complete > /dev/null; then
    echo "✓ Backward tab completion function loaded"
else
    echo "✗ Backward tab completion function missing"
fi

# Cleanup
rm -rf /tmp/jcd_test

echo "=== Validation Complete ==="
