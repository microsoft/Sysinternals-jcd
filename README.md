# JCD - Enhanced Directory Navigation Tool

`jcd` (Jump Change Directory) is a Rust-based command-line tool that provides enhanced directory navigation with substring matching and smart selection. It's like the `cd` command, but with superpowers! 'jcd' is part of the Sysinternals tool suite.

![JCD Demo](https://github.com/microsoft/jcd/blob/main/assets/jcd.gif?raw=true)

## Features

- **Tab Navigation**: Intelligent cycling through all matches with visual feedback and animated loading indicators
- **Bidirectional Tab Cycling**: Tab cycles forward, Shift+Tab cycles backward through matches
- **Case Sensitivity Control**: Use `-i` flag for case-insensitive matching (default is case-sensitive)
- **Directory Ignore Support**: Skip unwanted directories using `.jcdignore` files with regex patterns
- **Flexible Ignore Configuration**: Support for project-local, user, and system-wide ignore files
- **First-Match Jump**: Press Enter after typing to immediately navigate to the best match
- **Priority Matching Order**:
  1. Exact matches prioritized over partial matches
  2. Up-tree matches (parent directories) have highest priority
  3. Down-tree matches (subdirectories) sorted by proximity
  4. Alphabetical sorting within same priority level
- **Substring Matching**: Find directories by partial name matches
- **Bidirectional Search**: Searches both up the directory tree and down into subdirectories

## Install
Please see installation instructions [here](INSTALL.md).

## Development
Please see development instructions [here](DEVELOPMENT.md).

## Usage

```bash
Usage:
  jcd [-i] [-x] <directory_pattern>   - Changes directory according to the pattern

Flags:
  -i                     - Case-insensitive matching (default: case-sensitive)
  -x                     - Bypass ignore patterns (search all directories)

directory_pattern:
  jcd <substring>        # Navigate to directory matching substring
  jcd <absolute_path>    # Navigate to absolute path
  jcd <path/pattern>     # Navigate using path-like patterns
```

### Examples

#### Basic Navigation
```bash
# Navigate to any directory containing "proj"
jcd proj

# Case-insensitive search for directories with "PROJ", "proj", "Proj", etc.
jcd -i proj

# Find directories with "src" in the name
jcd src

# Navigate to parent directories matching "work"
jcd work

# Navigate to absolute path
jcd /home/user/projects

# Use path patterns
jcd projects/src    # Find 'src' within 'projects'
```

#### Case Sensitivity Examples
```bash
# Default behavior is case-sensitive
jcd Test        # Matches: Test, TestDir  (but not test, TEST)
jcd test        # Matches: test, testdir  (but not Test, TEST)

# Use -i flag for case-insensitive matching
jcd -i test     # Matches: test, Test, TEST, TestDir, testdir, etc.
jcd -i proj     # Matches: proj, PROJ, Project, project, etc.

# Case-insensitive with tab completion
jcd -i test<Tab>         # Cycles through all matches regardless of case
jcd -i test<Shift+Tab>   # Cycles backward through matches
```

#### Ignore Patterns
```bash
# Skip common build/cache directories (honors .jcdignore files)
jcd target      # Skipped if "target" is in ignore patterns
jcd node        # Skipped if "node_modules" is in ignore patterns

# Use -x to bypass ignore patterns and search all directories
jcd -x target   # Finds target directory even if ignored
jcd -x node     # Finds node_modules even if ignored

# Combine flags
jcd -i -x test  # Case-insensitive search bypassing ignore patterns
```


### Advanced Tab Completion

When multiple directories match your search term, `jcd` provides intelligent tab completion that cycles through all available matches with visual feedback:

```bash
# Type 'jcd fo' and press Tab - shows animated dots while searching
$ jcd fo<Tab>
...  # Animated loading indicator
jcd /.font-unix

# Press Tab again to cycle forward to next match
$ jcd /.font-unix<Tab>
jcd /foo

# Press Shift+Tab to cycle backward to previous match
$ jcd /foo<Shift+Tab>
jcd /.font-unix

# Press Tab again to cycle forward
$ jcd /.font-unix<Tab>
jcd /some/other/folder

# Press Enter to navigate to the currently shown match
$ jcd /foo<Enter>
# Now in /foo directory
```

#### Tab Completion Features

- **Animated Loading**: Visual dots animation during search operations
- **Bidirectional Cycling**: Tab cycles forward, Shift+Tab cycles backward through matches
- **Inline Cycling**: Tab repeatedly to cycle through all matches in both directions
- **Smart Prioritization**: Exact matches shown before partial matches
- **Proximity Sorting**: Closer directories (fewer levels away) shown first
- **Trailing Slash Support**: Add `/` to explore subdirectories of the current match
- **Relative Path Support**: Full tab completion for `../`, `../../`, etc.
- **Case Sensitivity**: Works with both case-sensitive (default) and case-insensitive (`-i`) modes


### Directory Ignore Support

`jcd` supports ignoring unwanted directories using `.jcdignore` files with regex patterns. This helps skip common build directories, cache folders, and other directories you typically don't want to navigate to.

#### Ignore File Locations

`jcd` searches for ignore files in the following order (first found takes precedence):

1. **Project-local**: `./.jcdignore` (in current directory)
2. **User config**: `~/.config/jcd/ignore` (follows XDG Base Directory Specification)
3. **Legacy user**: `~/.jcdignore` (for backward compatibility)
4. **System-wide**: `/etc/jcd/ignore` (affects all users)

#### Ignore File Format

Ignore files contain regex patterns, one per line:

```bash
# .jcdignore example
# Common build directories
target
build
dist

# Cache and temporary directories
\.cache
\.tmp
temp.*

# Version control
\.git
\.svn

# Node.js
node_modules
npm-debug\.log

# Complex patterns using regex
.*\.egg-info
__pycache__
\.pytest_cache

# Python virtual environments
venv
\.venv
env
```

#### Comment and Empty Line Support

- Lines starting with `#` are comments and ignored
- Empty lines are ignored
- Whitespace-only lines are ignored
- Invalid regex patterns are skipped (with silent error handling)

#### Usage Examples

##### Basic Ignore Usage
```bash
# Create a project-local ignore file
echo "target" > .jcdignore
echo "node_modules" >> .jcdignore

# These directories will be skipped in searches
jcd target      # No results found (ignored)
jcd node        # No results found (ignored)

# Bypass ignore patterns with -x flag
jcd -x target   # Finds target directory
jcd -x node     # Finds node_modules directory
```

##### User-Wide Ignore Configuration
```bash
# Create user config directory
mkdir -p ~/.config/jcd

# Create user-wide ignore patterns
cat > ~/.config/jcd/ignore << 'EOF'
# User-wide ignores
\.git
\.svn
cache
temp
build
target
node_modules
__pycache__
\.pytest_cache
EOF

# These patterns now apply to all jcd searches
jcd cache       # Skipped everywhere
jcd build       # Skipped everywhere
```

##### Regex Pattern Examples
```bash
# Ignore all hidden directories (starting with .)
echo "\\..*" > .jcdignore

# Ignore specific patterns
echo "target|build|dist" > .jcdignore

# Ignore numbered cache directories
echo "cache\\d+" > .jcdignore

# Ignore temporary files and directories
echo "tmp.*|temp.*|\\.tmp" > .jcdignore
```

#### Precedence Rules

When multiple ignore files exist:

1. **Project-local** `.jcdignore` has highest precedence
2. **User config** `~/.config/jcd/ignore`
3. **Legacy user** `~/.jcdignore`
4. **System-wide** `/etc/jcd/ignore` has lowest precedence

Only the first found file is used (no merging).

### Best Practices

1. **Use project-local ignore** for project-specific patterns
2. **Use user config** for personal preferences across all projects
3. **Use simple regex** for better performance and readability
4. **Comment your patterns** for future maintenance
5. **Test patterns** using the `-x` flag to verify they work as expected

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

