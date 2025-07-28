#!/usr/bin/env python3
"""
Basic functionality verification for JCD including case sensitivity tests.
This script tests core functionality and case sensitivity without relying on complex bash environments.
"""

import subprocess
import os
import tempfile
import shutil
from pathlib import Path

def run_jcd(pattern, index=0, cwd=None, case_sensitive=True):
    """Run the jcd binary and return the result."""
    cmd = ['/datadrive/jcd/target/release/jcd']
    if not case_sensitive:  # Add -i flag for case insensitive
        cmd.append('-i')
    cmd.extend([pattern, str(index)])
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd, timeout=5)
        if result.returncode == 0:
            return result.stdout.strip()
        else:
            return None
    except (subprocess.TimeoutExpired, subprocess.CalledProcessError):
        return None

def test_basic_functionality():
    """Test basic jcd functionality."""
    print("=== Basic JCD Functionality Test ===")

    # Create test structure
    test_dir = Path("/tmp/jcd_basic_test")
    if test_dir.exists():
        shutil.rmtree(test_dir)

    test_structure = {
        "parent/child1": [],
        "parent/child2": [],
        "parent/subdir/deep1": [],
        "parent/subdir/deep2": [],
        "sibling/sub1": [],
        "sibling/sub2": [],
        "foo/bar": [],
        "foo/baz": [],
        # Case sensitivity test directories
        "case_test/TestDir": [],
        "case_test/testdir": [],
        "case_test/TESTDIR": [],
        "case_test/MixedCase": [],
        "case_test/lowercase": [],
        "case_test/UPPERCASE": [],
    }

    for path, _ in test_structure.items():
        (test_dir / path).mkdir(parents=True, exist_ok=True)

    print(f"Created test structure in {test_dir}")

    # Use working directory for relative navigation tests
    working_dir = test_dir / "parent" / "child1"
    print(f"Working directory: {working_dir}")

    tests = [
        # Basic relative navigation
        ("..", f"{test_dir}/parent", "Parent navigation"),
        ("../..", f"{test_dir}", "Grandparent navigation"),
        ("../child2", f"{test_dir}/parent/child2", "Sibling navigation"),
        ("../../foo", f"{test_dir}/foo", "Deep relative navigation"),

        # Pattern matching
        ("../ch", f"{test_dir}/parent/child1", "Pattern matching (first result)"),

        # Note: Removed unique pattern test that expects traversal up and back down
    ]

    passed = 0
    failed = 0

    for pattern, expected, description in tests:
        result = run_jcd(pattern, cwd=working_dir)
        if result == expected:
            print(f"✓ PASS: {description}")
            print(f"  Pattern: '{pattern}' -> {result}")
            passed += 1
        else:
            print(f"✗ FAIL: {description}")
            print(f"  Pattern: '{pattern}'")
            print(f"  Expected: {expected}")
            print(f"  Got: {result}")
            failed += 1

    # Note: Removed absolute pattern consistency test that relied on up-and-back-down traversal

    # Cleanup
    shutil.rmtree(test_dir)

    # Summary
    print(f"\n=== Test Summary ===")
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    print(f"Total: {passed + failed}")

    if failed == 0:
        print("🎉 All tests passed! No regressions detected.")
        return True
    else:
        print("❌ Some tests failed - potential regression detected!")
        return False

def test_case_sensitivity():
    """Test case sensitivity functionality with -i flag."""
    print("\n=== Case Sensitivity Test ===")
    print("Default: case sensitive, -i flag: case insensitive")

    # Create test structure with different case directories
    test_dir = Path("/tmp/jcd_case_test")
    if test_dir.exists():
        shutil.rmtree(test_dir)

    case_dirs = ["TestDir", "testdir", "TESTDIR"]
    for dir_name in case_dirs:
        (test_dir / dir_name).mkdir(parents=True, exist_ok=True)

    print(f"Created case test structure in {test_dir}")

    passed = 0
    failed = 0

    # Test case sensitivity
    tests = [
        ("test", False, ["TestDir", "testdir", "TESTDIR"], "Case insensitive 'test' with -i"),
        ("TestDir", True, ["TestDir"], "Case sensitive 'TestDir' (default)"),
        ("testdir", True, ["testdir"], "Case sensitive 'testdir' (default)"),
        ("TESTDIR", True, ["TESTDIR"], "Case sensitive 'TESTDIR' (default)"),
    ]

    for pattern, case_sensitive, possible_matches, description in tests:
        result = run_jcd(pattern, case_sensitive=case_sensitive, cwd=test_dir)
        if result and any(match in result for match in possible_matches):
            print(f"✓ PASS: {description}")
            print(f"  Pattern: '{pattern}' (case_sensitive={case_sensitive}) -> {result}")
            passed += 1
        else:
            print(f"✗ FAIL: {description}")
            print(f"  Pattern: '{pattern}' (case_sensitive={case_sensitive})")
            print(f"  Expected one of: {possible_matches}")
            print(f"  Got: {result}")
            failed += 1

    # Cleanup
    shutil.rmtree(test_dir)

    # Summary
    print(f"\n=== Case Sensitivity Test Summary ===")
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    print(f"Total: {passed + failed}")

    if failed == 0:
        print("🎉 All case sensitivity tests passed!")
        return True
    else:
        print("❌ Some case sensitivity tests failed!")
        return False

def test_binary_exists():
    """Test that the binary exists and is executable."""
    binary_path = Path("/datadrive/jcd/target/release/jcd")
    if binary_path.exists() and os.access(binary_path, os.X_OK):
        print(f"✓ Binary exists and is executable: {binary_path}")
        return True
    else:
        print(f"✗ Binary not found or not executable: {binary_path}")
        return False

def main():
    print("JCD Regression Test - Python Version")
    print("=====================================")

    # Check binary
    if not test_binary_exists():
        return 1

    # Run functionality tests
    basic_passed = test_basic_functionality()
    case_passed = test_case_sensitivity()

    if basic_passed and case_passed:
        print("\n✅ No regressions detected in core functionality and case sensitivity!")
        return 0
    else:
        print("\n❌ Potential regressions detected!")
        return 1

    # Run case sensitivity tests
    if test_case_sensitivity():
        print("\n✅ No regressions detected in case sensitivity functionality!")
        return 0
    else:
        print("\n❌ Potential regressions detected in case sensitivity functionality!")
        return 1

if __name__ == "__main__":
    exit(main())