# mise + Sourcery Bug Reproduction

Minimal reproduction of a bug where `mise install sourcery@2.2.7` reports success but `mise exec` fails.

## The Bug

When installing Sourcery via mise, the installation reports success but the tool cannot be executed:

```
$ mise install sourcery@2.2.7
mise sourcery@2.2.7 ✓ installed

$ mise exec sourcery@2.2.7 -- sourcery --version
mise ERROR "sourcery" couldn't exec process: No such file or directory
```

## Root Cause

Sourcery uses the `github` backend with `exe=bin/sourcery`:
```
Backend: github:krzysztofzablocki/Sourcery[exe=bin/sourcery]
```

The Sourcery release has two zip assets:
- `sourcery-2.2.7.zip` - standard zip with `bin/sourcery` at top level
- `sourcery-2.2.7.artifactbundle.zip` - artifact bundle with nested `sourcery/bin/sourcery`

The newer mise version incorrectly selects the artifact bundle, which has an extra nesting level that breaks the `exe=bin/sourcery` path.

**Expected binary location** (based on `exe=bin/sourcery`):
```
.mise/installs/sourcery/2.2.7/bin/sourcery
```

**Actual binary location:**
```
.mise/installs/sourcery/2.2.7/sourcery/bin/sourcery
```

## Regression Analysis

This is a **regression** introduced in commit `4f5c80541` (part of v2026.1.0):

```diff
# src/backend/asset_matcher.rs
- if asset.contains(".artifactbundle") {
+ if asset.ends_with(".artifactbundle") {
      penalty -= 30;
  }
```

**Before**: `.contains(".artifactbundle")` matched `sourcery-2.2.7.artifactbundle.zip` → -30 penalty applied → regular `.zip` selected

**After**: `.ends_with(".artifactbundle")` does NOT match `sourcery-2.2.7.artifactbundle.zip` (ends with `.zip`) → no penalty → artifact bundle selected

| Version | Asset Selected | Binary Location | Works? |
|---------|----------------|-----------------|--------|
| v2025.12.12 | `sourcery-2.2.7.zip` | `bin/sourcery` | ✅ Yes |
| v2026.1.1 | `sourcery-2.2.7.artifactbundle.zip` | `sourcery/bin/sourcery` | ❌ No |

## Suggested Fix

The penalty check should match `.artifactbundle.zip` files:

```rust
if asset.ends_with(".artifactbundle") || asset.contains(".artifactbundle.") {
    penalty -= 30;
}
```

Or revert to the original `.contains()` check.

## Reproduction

```bash
./reproduce.sh           # Uses broken v2026.1.1
./reproduce.sh --working # Uses working v2025.12.12
./reproduce.sh --verbose # With verbose output
./reproduce.sh --help    # Show all options
```

The script:
1. Downloads the specified mise version (macOS ARM64)
2. Sets up fully isolated mise directories (`.mise/`)
3. Uses `MISE_NO_CONFIG=1` for complete isolation
4. Installs `sourcery@2.2.7`
5. Attempts to execute sourcery
6. Shows the actual vs expected binary locations

## Environment

- Broken mise version: v2026.1.1
- Working mise version: v2025.12.12
- Tool: sourcery@2.2.7
- Backend: `github:krzysztofzablocki/Sourcery[exe=bin/sourcery]`
- Platform: macOS ARM64

## Files

- `reproduce.sh` - Self-contained reproduction script
- `README.md` - This file
