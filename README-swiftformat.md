# mise + SwiftFormat Bug Reproduction

Reproduction showing that SwiftFormat's github backend has never worked correctly on macOS.

## The Bug

SwiftFormat installs report success but the tool cannot be executed:

```
$ mise install swiftformat@0.54.6
mise swiftformat@0.54.6 ✓ installed

$ mise exec swiftformat@0.54.6 -- swiftformat --version
mise ERROR "swiftformat" couldn't exec process: No such file or directory
```

## Root Cause

SwiftFormat has multiple assets for the same platform:
- `swiftformat.zip` - CLI tool (correct) ✅
- `SwiftFormat.for.Xcode.app.zip` - Xcode app bundle ❌
- `SwiftFormat.arm64.msi` - Windows installer ❌
- `swiftformat.artifactbundle.zip` - Swift artifact bundle ❌

The asset scoring doesn't differentiate between CLI tools and IDE/GUI distributions.

## Version History

| Version | Downloads | Why | Works? |
|---------|-----------|-----|--------|
| v2026.1.6 (Jan 20) | `SwiftFormat.arm64.msi` | No .msi penalty yet, arch match (+50) wins | ❌ No (Windows installer) |
| v2026.1.8 (current) | `SwiftFormat.for.Xcode.app.zip` | .msi penalty added, Xcode app ties with CLI at +5 | ❌ No (IDE bundle) |

## Reproduction

```bash
./reproduce-swiftformat.sh --v2026.1.6  # Last week's version
./reproduce-swiftformat.sh --v2026.1.8  # Current version
./reproduce-swiftformat.sh --verbose    # With verbose output
```

## Suggested Fix

Add penalties for IDE/GUI-specific distributions in `score_build_penalties`:

```rust
// Penalize IDE/GUI-specific distributions
if asset.contains("xcode")
    || asset.contains(".app.")
    || asset.contains("gui") {
    penalty -= 20;
}
```

This would make `SwiftFormat.for.Xcode.app.zip` score -15 instead of +5, allowing `swiftformat.zip` (at +5) to win.

## Files

- `reproduce-swiftformat.sh` - Reproduction script testing different mise versions
- `README-swiftformat.md` - This file
