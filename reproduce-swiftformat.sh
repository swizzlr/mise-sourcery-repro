#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Defaults
MISE_VERSION="v2026.1.8"  # Current version with Xcode app issue

# Parse arguments
for arg in "$@"; do
    case $arg in
        --verbose)
            export MISE_VERBOSE=1
            ;;
        --v2026.1.6)
            MISE_VERSION="v2026.1.6"  # Last week's version
            ;;
        --v2026.1.8)
            MISE_VERSION="v2026.1.8"  # Current version
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --verbose      Enable mise verbose output"
            echo "  --v2026.1.6    Use mise v2026.1.6 (last week)"
            echo "  --v2026.1.8    Use mise v2026.1.8 (current, default)"
            echo "  --help         Show this help"
            echo ""
            exit 0
            ;;
    esac
done

MISE_BINARY="mise-swiftformat-test"
MISE_URL="https://github.com/jdx/mise/releases/download/${MISE_VERSION}/mise-${MISE_VERSION}-macos-arm64"

# Clean up local state
echo "Cleaning up local state: ./$MISE_BINARY, .mise-swiftformat/"
rm -rf "$MISE_BINARY" .mise-swiftformat/

# Download mise
echo ""
echo "Downloading mise ${MISE_VERSION} from:"
echo "  $MISE_URL"
curl -fsSL "$MISE_URL" -o "$MISE_BINARY"
chmod +x "$MISE_BINARY"
echo "Downloaded mise ${MISE_VERSION}"

echo ""
echo "========================================"
echo "🔧 Running: ./mise version"
echo "========================================"
./"$MISE_BINARY" version

# Set all mise directories to local .mise-swiftformat folder for isolation
export MISE_DATA_DIR="$SCRIPT_DIR/.mise-swiftformat"
export MISE_CACHE_DIR="$SCRIPT_DIR/.mise-swiftformat"
export MISE_STATE_DIR="$SCRIPT_DIR/.mise-swiftformat"
export MISE_CONFIG_DIR="$SCRIPT_DIR/.mise-swiftformat"

# Fully isolated - no config files loaded
export MISE_YES=1
export MISE_NO_CONFIG=1

echo ""
echo "Environment:"
echo "  MISE_DATA_DIR=$MISE_DATA_DIR"
echo "  MISE_CACHE_DIR=$MISE_CACHE_DIR"
echo "  MISE_STATE_DIR=$MISE_STATE_DIR"
echo "  MISE_CONFIG_DIR=$MISE_CONFIG_DIR"
echo "  MISE_YES=$MISE_YES"
echo "  MISE_NO_CONFIG=$MISE_NO_CONFIG"
echo ""

echo "========================================"
echo "🔧 Running: ./mise cfg"
echo "========================================"
./"$MISE_BINARY" cfg

echo ""
echo "========================================"
echo "🔧 Running: ./mise install swiftformat@0.54.6"
echo "========================================"
./"$MISE_BINARY" install swiftformat@0.54.6

echo ""
echo "========================================"
echo "🔧 Running: ./mise tool swiftformat"
echo "========================================"
./"$MISE_BINARY" tool swiftformat

echo ""
echo "========================================"
echo "🔧 Running: ./mise which swiftformat"
echo "========================================"
./"$MISE_BINARY" which swiftformat

echo ""
echo "========================================"
echo "🔧 Running: ./mise exec swiftformat@0.54.6 -- swiftformat --version"
echo "========================================"
./"$MISE_BINARY" exec swiftformat@0.54.6 -- swiftformat --version

echo ""
echo "========================================"
echo "🔧 Checking binary location and downloaded asset"
echo "========================================"
echo "Downloaded files:"
ls -la "$MISE_DATA_DIR/downloads/swiftformat/0.54.6/" 2>&1 || echo "No downloads directory"
echo ""
echo "Install directory contents:"
ls -la "$MISE_DATA_DIR/installs/swiftformat/0.54.6/" 2>&1 || echo "No installs directory"
echo ""
echo "Looking for swiftformat binary:"
find "$MISE_DATA_DIR/installs/swiftformat/0.54.6" -name "swiftformat" -o -name "SwiftFormat" 2>&1 | head -5 || true
