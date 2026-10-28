# JCD Test Suite

This directory contains test scripts for the JCD (Enhanced Directory Navigation) tool.

## Test Scripts

### `test_path_safety.py`
**Path and pipeline security regression tests (Linux/Bash)**
- Checks NUL-delimited binary output and navigation with spaces, quotes,
  metacharacters, control characters, trailing newlines, and non-UTF-8 bytes.
- Exercises actual Tab and Shift+Tab input through a pseudo-terminal and verifies
  the selected directory without executing filename contents.
- Checks completion record boundaries, no-match behavior, and terminal escaping.
- Executes the build template's shell body with literal parameter values and a
  stubbed `cargo`; checks that checkout credential persistence is disabled.
  This does not substitute for a live Azure Pipelines run.
- Uses isolated temporary fixtures and removes them when finished.

```bash
cargo test
cargo build --release
bash -n src/jcd_function.sh
python3 tests/test_path_safety.py
```

For manual testing, run the following from the repository root in Bash:

```bash
export JCD_BINARY="$PWD/target/release/jcd"
source src/jcd_function.sh
fixture=$(mktemp -d)
cd -- "$fixture"
mkdir -- 'probe-$(touch JCD_UNEXPECTED)' 'probe-`touch JCD_UNEXPECTED`' \
    'probe-space quote' $'probe-tab\tname' $'probe-newline\nname' \
    $'probe-trailing\n' $'probe-escape\e[31m'
```

Type `jcd probe`, press Tab or Shift+Tab, then Enter. Repeat from the fixture
directory for the different names. `printf '%q\n' "$PWD"` should show the exact
selected filename; `test ! -e "$fixture/JCD_UNEXPECTED"` should succeed. The
literal `touch` strings are harmless markers, not commands that should execute.
Return to the fixture directory with `cd -- "$fixture"`.
Running `"$JCD_BINARY" probe-escape --quiet` directly should display an escaped
control character, not change the terminal color.

In a disposable pipeline run, confirm ordinary/empty `ldpath` values still build,
and values containing literal `$()` or quotes are not executed. After checkout,
check that the repository Git configuration has no persisted authorization
header without printing any credential values. This last check requires Azure
Pipelines and is not covered by the local stub.

### `test_relative_comprehensive.sh`
**Primary regression test suite**
- Comprehensive testing of all relative path functionality
- 10 test cases covering navigation patterns, search contexts, and edge cases
- Performance timing and pass/fail reporting
- Should be run before any release

Usage:
```bash
./tests/test_relative_comprehensive.sh
```

### `validate_jcd.sh`
**Quick validation script**
- Lightweight smoke test for CI/CD pipelines
- Verifies binary exists and basic functionality works
- Fast execution suitable for automated workflows

Usage:
```bash
./tests/validate_jcd.sh
```

### `verify_basic_functionality.py`
**Python-based comprehensive test**
- Tests core JCD functionality including relative path navigation
- Tests case sensitivity functionality with `-i` flag
- Cross-platform Python script for reliable testing
- No external dependencies beyond standard library

Usage:
```bash
python3 tests/verify_basic_functionality.py
```

### `test_ignore_functionality.sh`
**Comprehensive ignore pattern test suite**
- Tests all ignore file locations and precedence rules
- Validates regex pattern matching and bypassing with `-x` flag
- Tests project-local, user config, legacy, and system-wide ignore files
- Verifies complex regex patterns and error handling
- Comprehensive coverage of the ignore feature

Usage:
```bash
./tests/test_ignore_functionality.sh
```

### `test_case_sensitivity.sh`
**Standalone case sensitivity test**
- Dedicated test for the new `-i` flag functionality
- Tests both case insensitive (default) and case sensitive modes
- Bash-based test with comprehensive scenarios

Usage:
```bash
./tests/test_case_sensitivity.sh
```

### `simple_test.sh`
**Manual testing and documentation**
- Good for manual verification during development
- Clear test structure documentation
- Intermediate complexity testing

Usage:
```bash
./tests/simple_test.sh
```

## Running Tests

### All Tests
```bash
# Run comprehensive test suite
./tests/test_relative_comprehensive.sh

# Quick validation
./tests/validate_jcd.sh
```

### CI/CD Integration
For automated testing, use the validate script:
```bash
./tests/validate_jcd.sh && echo "Tests passed"
```

## Test Requirements

- Tests require the compiled binary at `target/release/jcd`
- Tests create temporary directories under `/tmp/jcd_test/`
- All tests clean up after themselves
- Tests should be run from the project root directory
