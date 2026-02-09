#!/usr/bin/env bash
set -e

# DevFlow Installer for Unix systems
# Usage: curl -sSL https://raw.githubusercontent.com/franchise-factory/devflow-releases/main/install.sh | bash

VERSION="${1:-latest}"
DEST_DIR="${2:-}"
GITHUB_REPO="franchise-factory/devflow-releases"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Detect OS and architecture
detect_platform() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"

    case "$OS" in
        Darwin)
            OS="darwin"
            ;;
        Linux)
            OS="linux"
            ;;
        *)
            error "Unsupported operating system: $OS"
            ;;
    esac

    case "$ARCH" in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        *)
            error "Unsupported architecture: $ARCH"
            ;;
    esac

    BINARY_NAME="devflow-${OS}-${ARCH}"
}

# Determine install directory
get_dest_dir() {
    if [ -n "$DEST_DIR" ]; then
        mkdir -p "$DEST_DIR"
        echo "$DEST_DIR"
        return
    fi

    # Use /usr/local/bin only if directly writable, otherwise ~/.local/bin
    if [ -w /usr/local/bin ]; then
        echo "/usr/local/bin"
    else
        USER_BIN="$HOME/.local/bin"
        mkdir -p "$USER_BIN"
        echo "$USER_BIN"
    fi
}

# Download binary
download_binary() {
    local version="$1"
    local dest_dir="$2"
    local binary_name="$3"

    if [ "$version" = "latest" ]; then
        DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/latest/download/${binary_name}"
    else
        DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${version}/${binary_name}"
    fi

    info "Downloading DevFlow from $DOWNLOAD_URL"
    curl -fsSL "$DOWNLOAD_URL" -o "$dest_dir/devflow"
    chmod +x "$dest_dir/devflow"
}

# Verify checksum
verify_checksum() {
    local dest_dir="$1"
    local version="$2"
    local binary_name="$3"

    info "Verifying checksum..."

    if [ "$version" = "latest" ]; then
        CHECKSUM_URL="https://github.com/${GITHUB_REPO}/releases/latest/download/checksums.txt"
    else
        CHECKSUM_URL="https://github.com/${GITHUB_REPO}/releases/download/${version}/checksums.txt"
    fi

    curl -fsSL "$CHECKSUM_URL" -o /tmp/devflow-checksums.txt

    # Get checksum for our binary
    EXPECTED=$(grep "$binary_name" /tmp/devflow-checksums.txt | awk '{print $1}')

    # Use sha256sum or shasum depending on platform
    if command -v sha256sum >/dev/null 2>&1; then
        ACTUAL=$(sha256sum "$dest_dir/devflow" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then
        ACTUAL=$(shasum -a 256 "$dest_dir/devflow" | awk '{print $1}')
    else
        warn "No sha256sum or shasum found, skipping checksum verification"
        rm -f /tmp/devflow-checksums.txt
        return
    fi

    if [ "$EXPECTED" != "$ACTUAL" ]; then
        error "Checksum mismatch! Expected: $EXPECTED, Got: $ACTUAL"
    fi

    info "Checksum verified"
    rm -f /tmp/devflow-checksums.txt
}

# Update PATH if needed
update_path() {
    local dest_dir="$1"

    if [ "$dest_dir" = "/usr/local/bin" ]; then
        return
    fi

    if ! echo "$PATH" | grep -q "$dest_dir"; then
        warn "Adding $dest_dir to PATH"
        echo "export PATH=\"$dest_dir:\$PATH\"" >> "$HOME/.bashrc"
        echo "export PATH=\"$dest_dir:\$PATH\"" >> "$HOME/.zshrc" 2>/dev/null || true
        info "Please restart your shell or run: export PATH=\"$dest_dir:\$PATH\""
    fi
}

# Main installation
main() {
    echo "DevFlow Installer"
    echo "================="

    detect_platform
    info "Detected platform: $OS $ARCH"

    DEST_DIR=$(get_dest_dir)
    info "Installing to: $DEST_DIR"

    download_binary "$VERSION" "$DEST_DIR" "$BINARY_NAME"
    verify_checksum "$DEST_DIR" "$VERSION" "$BINARY_NAME"

    update_path "$DEST_DIR"

    info "Installation complete!"
    echo ""
    info "Run 'devflow --version' to verify"
    info "Run 'devflow --help' to get started"
}

main
