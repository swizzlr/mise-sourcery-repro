#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Defaults
MISE_VERSION="v2026.1.1"  # Broken version
VERBOSE=""

# Parse arguments
for arg in "$@"; do
    case $arg in
        --verbose)
            export MISE_VERBOSE=1
            VERBOSE="yes"
            ;;
        --working)
            MISE_VERSION="v2025.12.12"  # Working version
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --verbose   Enable mise verbose output"
            echo "  --working   Use mise v2025.12.12 (working version)"
            echo "  --help      Show this help"
            echo ""
            echo "By default, uses mise v2026.1.1 which exhibits the bug."
            exit 0
            ;;
    esac
done

if [[ -n "$VERBOSE" ]]; then
    echo "Verbose mode enabled"
fi

MISE_BINARY="mise"
MISE_URL="https://github.com/jdx/mise/releases/download/${MISE_VERSION}/mise-${MISE_VERSION}-macos-arm64"

# Clean up local state
echo "Cleaning up local state: ./$MISE_BINARY, .mise/"
rm -rf "$MISE_BINARY" .mise/

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
./mise version

# Set all mise directories to local .mise folder for isolation
export MISE_DATA_DIR="$SCRIPT_DIR/.mise"
export MISE_CACHE_DIR="$SCRIPT_DIR/.mise"
export MISE_STATE_DIR="$SCRIPT_DIR/.mise"
export MISE_CONFIG_DIR="$SCRIPT_DIR/.mise"

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
./mise cfg

echo ""
echo "========================================"
echo "🔧 Running: ./mise install sourcery@2.2.7"
echo "========================================"
./mise install sourcery@2.2.7

echo ""
echo "========================================"
echo "🔧 Running: ./mise tool sourcery"
echo "========================================"
./mise tool sourcery

echo ""
echo "========================================"
echo "🔧 Running: ./mise which sourcery"
echo "========================================"
./mise which sourcery

echo ""
echo "========================================"
echo "🔧 Running: ./mise exec sourcery@2.2.7 -- sourcery --version"
echo "========================================"
./mise exec sourcery@2.2.7 -- sourcery --version

echo ""
echo "========================================"
echo "🔧 Checking binary location"
echo "========================================"
echo "Expected (exe=bin/sourcery):"
echo "  $MISE_DATA_DIR/installs/sourcery/2.2.7/bin/sourcery"
ls -la "$MISE_DATA_DIR/installs/sourcery/2.2.7/bin/" 2>&1 || true
echo ""
echo "Actual location:"
find "$MISE_DATA_DIR/installs/sourcery/2.2.7" -name "sourcery" -type f 2>&1 || true
