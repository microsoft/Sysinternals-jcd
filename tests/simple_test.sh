#!/bin/bash

echo "Testing relative path functionality..."

# Create a test directory structure
mkdir -p /tmp/jcd_test/{parent/{child1,child2,childX},sibling/{sub1,sub2},foo/{bar,baz}}

echo "Created test structure:"
echo "/tmp/jcd_test/"
echo "├── parent/"
echo "│   ├── child1/"
echo "│   ├── child2/"
echo "│   └── childX/"
echo "├── sibling/"
echo "│   ├── sub1/"
echo "│   └── sub2/"
echo "└── foo/"
echo "    ├── bar/"
echo "    └── baz/"

# Test the binary directly
echo -e "\n=== Testing binary with relative paths ==="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JCD_BINARY="$SCRIPT_DIR/../target/release/jcd"

cd /tmp/jcd_test/parent/child1
echo "Current directory: $(pwd)"

echo -e "\nTest 1: jcd '..' (should go to parent)"
result=$("$JCD_BINARY" ".." 2>&1)
echo "Result: $result"

echo -e "\nTest 2: jcd '../..' (should go to jcd_test)"
result=$("$JCD_BINARY" "../.." 2>&1)
echo "Result: $result"

echo -e "\nTest 3: jcd '../child2' (should find sibling directory)"
result=$("$JCD_BINARY" "../child2" 2>&1)
echo "Result: $result"

echo -e "\nTest 4: jcd '../../foo' (should find foo directory)"
result=$("$JCD_BINARY" "../../foo" 2>&1)
echo "Result: $result"

# Test with patterns
echo -e "\nTest 5: jcd '../ch' (should find child directories)"
for i in {0..5}; do
    result=$("$JCD_BINARY" "../ch" $i 2>/dev/null)
    if [[ -n "$result" ]]; then
        echo "Match $i: $result"
    else
        break
    fi
done

echo -e "\n=== Testing shell function ==="

# Source the shell function
source "$SCRIPT_DIR/../src/jcd_function.sh"

cd /tmp/jcd_test/parent/child1
echo "Current directory: $(pwd)"

echo -e "\nTesting jcd function:"
echo "jcd '..' -> "
jcd ".."
echo "Now in: $(pwd)"

echo "jcd 'child1' -> "
jcd "child1"
echo "Now in: $(pwd)"

echo "jcd '../..' -> "
jcd "../.."
echo "Now in: $(pwd)"

echo "jcd 'parent/child2' -> "
jcd "parent/child2"
echo "Now in: $(pwd)"

# Clean up
echo -e "\n=== Cleaning up ==="
rm -rf /tmp/jcd_test
echo "Test completed!"
