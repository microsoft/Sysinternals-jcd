#!/bin/bash

echo "=== Testing Absolute Path Consistency Fix ==="
echo "Bug: Absolute patterns like '/4' had different search behavior than relative patterns like '4'"
echo "Fix: Made absolute paths use the same comprehensive search logic as relative paths"
echo

# Set up test directory structure
cd /datadrive/jcd
rm -rf test_absolute_consistency
mkdir -p test_absolute_consistency/tmp/foo/deep/nested/foo4
mkdir -p test_absolute_consistency/tmp/foo/deep/nested/uniquefoo999
mkdir -p test_absolute_consistency/tmp/foo/deep/nested/test123

cd test_absolute_consistency/tmp/foo

echo "Test directory structure created:"
echo "Current directory: $(pwd)"
echo "Directories containing '4':"
find /datadrive/jcd/test_absolute_consistency -name "*4*" -type d
echo "Directories containing 'uniquefoo':"
find /datadrive/jcd/test_absolute_consistency -name "*uniquefoo*" -type d
echo "Directories containing 'test123':"
find /datadrive/jcd/test_absolute_consistency -name "*test123*" -type d
echo

echo "=== Test 1: Pattern '4' vs '/4' ==="
echo "From directory: $(pwd)"
echo

echo "Relative pattern '4':"
result_rel=$(../../../target/release/jcd 4 0 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "  ✓ Found: $result_rel"
else
    echo "  ✗ Not found"
fi

echo "Absolute pattern '/4':"
result_abs=$(../../../target/release/jcd /4 0 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "  ✓ Found: $result_abs"
    if [[ "$result_abs" == *"foo4"* ]]; then
        echo "  ✓ Found the expected deep directory"
    else
        echo "  ⚠ Found different directory: $result_abs"
    fi
else
    echo "  ✗ Not found"
fi

echo

echo "=== Test 2: Pattern 'uniquefoo' vs '/uniquefoo' ==="
echo "From directory: $(pwd)"
echo

echo "Relative pattern 'uniquefoo':"
result_rel=$(../../../target/release/jcd uniquefoo 0 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "  ✓ Found: $result_rel"
else
    echo "  ✗ Not found"
fi

echo "Absolute pattern '/uniquefoo':"
result_abs=$(../../../target/release/jcd /uniquefoo 0 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "  ✓ Found: $result_abs"
    if [[ "$result_rel" == "$result_abs" ]]; then
        echo "  ✓ Both patterns found the same directory - CONSISTENT!"
    else
        echo "  ⚠ Different results - still inconsistent"
        echo "    Relative: $result_rel"
        echo "    Absolute: $result_abs"
    fi
else
    echo "  ✗ Not found"
fi

echo

echo "=== Test 3: Pattern 'test123' vs '/test123' ==="
echo "From directory: $(pwd)"
echo

echo "Relative pattern 'test123':"
result_rel=$(../../../target/release/jcd test123 0 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "  ✓ Found: $result_rel"
else
    echo "  ✗ Not found"
fi

echo "Absolute pattern '/test123':"
result_abs=$(../../../target/release/jcd /test123 0 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "  ✓ Found: $result_abs"
    if [[ "$result_rel" == "$result_abs" ]]; then
        echo "  ✓ Both patterns found the same directory - CONSISTENT!"
    else
        echo "  ⚠ Different results - still inconsistent"
    fi
else
    echo "  ✗ Not found"
fi

echo

echo "=== Test 4: Testing with bash completion ==="
cd /datadrive/jcd/test_absolute_consistency/tmp/foo
export JCD_BINARY="../../../target/release/jcd"
export JCD_DEBUG=0
source ../../../jcd_function.sh 2>/dev/null

echo "Testing tab completion for absolute pattern '/uniquefoo':"

# Test absolute pattern completion
export COMP_WORDS=("jcd" "/uniquefoo")
export COMP_CWORD=1
export COMPREPLY=()
_jcd_tab_complete 2>/dev/null

if [ ${#COMPREPLY[@]} -gt 0 ]; then
    echo "  ✓ Completion result: '${COMPREPLY[0]}'"
else
    echo "  ✗ No completion result"
fi

echo

echo "=== Summary ==="
echo "The fix ensures that absolute patterns like '/pattern' now behave exactly"
echo "like relative patterns like 'pattern' - they both do comprehensive deep"
echo "searches when no immediate matches are found, providing consistent behavior."
echo
echo "Key changes:"
echo "- Absolute paths now use search_down_breadth_first_all() with max_depth=8"
echo "- Previously used search_breadth_first() with max_depth=3"
echo "- This provides consistent behavior between '4' and '/4' patterns"

# Cleanup
cd /datadrive/jcd
rm -rf test_absolute_consistency