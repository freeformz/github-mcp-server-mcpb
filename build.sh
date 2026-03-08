#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.32.0}"
REPO="github/github-mcp-server"
BUILD_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Building github-mcp-server MCPB v${VERSION}..."

# Determine platform and architecture
OS=$(uname -s)
ARCH=$(uname -m)

case "$OS" in
  Darwin) PLATFORM="Darwin" ;;
  Linux)  PLATFORM="Linux" ;;
  *)      echo "Unsupported OS: $OS"; exit 1 ;;
esac

case "$ARCH" in
  x86_64)  ARCH_LABEL="x86_64" ;;
  arm64|aarch64) ARCH_LABEL="arm64" ;;
  i386|i686) ARCH_LABEL="i386" ;;
  *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

ASSET_NAME="github-mcp-server_${PLATFORM}_${ARCH_LABEL}.tar.gz"

echo "Downloading ${ASSET_NAME} from release v${VERSION}..."

# Create server directory in work dir
mkdir -p "$WORK_DIR/server"

# Download and extract the binary
gh release download "v${VERSION}" \
  --repo "$REPO" \
  --pattern "$ASSET_NAME" \
  --dir "$WORK_DIR"

tar -xzf "$WORK_DIR/$ASSET_NAME" -C "$WORK_DIR/server"
rm "$WORK_DIR/$ASSET_NAME"

# Ensure binary is executable
chmod +x "$WORK_DIR/server/github-mcp-server"

# Copy manifest
cp "$BUILD_DIR/manifest.json" "$WORK_DIR/manifest.json"

# Update version in manifest if different from default
if [ "$VERSION" != "0.32.0" ]; then
  if command -v jq &>/dev/null; then
    jq --arg v "$VERSION" '.version = $v' "$WORK_DIR/manifest.json" > "$WORK_DIR/manifest.tmp" \
      && mv "$WORK_DIR/manifest.tmp" "$WORK_DIR/manifest.json"
  else
    sed -i.bak "s/\"version\": \"0.32.0\"/\"version\": \"$VERSION\"/" "$WORK_DIR/manifest.json"
    rm -f "$WORK_DIR/manifest.json.bak"
  fi
fi

# Build the .mcpb (zip archive)
OUTPUT="$BUILD_DIR/github-mcp-server-${VERSION}-${PLATFORM}-${ARCH_LABEL}.mcpb"
(cd "$WORK_DIR" && zip -r "$OUTPUT" manifest.json server/)

echo ""
echo "Built: $OUTPUT"
echo "Size: $(du -h "$OUTPUT" | cut -f1)"
