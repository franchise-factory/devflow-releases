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

    # Try /usr/local/bin first
    if [ -w /usr/local/bin ] || sudo -n true 2>/dev/null; then
        echo "/usr/local/bin"
    else
        # Fallback to user bin
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

    # Check available disk space (need ~20MB)
    local available_kb
    available_kb=$(df -k "$dest_dir" 2>/dev/null | awk 'NR==2 {print $4}')
    if [ -n "$available_kb" ] && [ "$available_kb" -lt 20480 ]; then
        error "Insufficient disk space. Available: ${available_kb}KB, Required: ~20MB."
    fi

    info "Downloading DevFlow from $DOWNLOAD_URL"

    # Download to temp file first to avoid partial writes and pipe conflicts
    # The </dev/null detaches stdin, preventing issues when run via curl | bash
    local tmp_file
    tmp_file=$(mktemp /tmp/devflow-download.XXXXXX)

    if ! curl -fsSL "$DOWNLOAD_URL" -o "$tmp_file" </dev/null; then
        rm -f "$tmp_file"
        error "Download failed. Try manually: curl -fsSL '$DOWNLOAD_URL' -o '$dest_dir/devflow'"
    fi

    mv "$tmp_file" "$dest_dir/devflow"
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

    # The </dev/null detaches stdin, preventing issues when run via curl | bash
    curl -fsSL "$CHECKSUM_URL" -o /tmp/checksums.txt </dev/null

    # Get checksum for our binary
    EXPECTED=$(grep "$binary_name" /tmp/checksums.txt | awk '{print $1}')
    ACTUAL=$(sha256sum "$dest_dir/devflow" | awk '{print $1}')

    if [ "$EXPECTED" != "$ACTUAL" ]; then
        error "Checksum mismatch! Expected: $EXPECTED, Got: $ACTUAL"
    fi

    info "Checksum verified"
    rm -f /tmp/checksums.txt
}

# Update PATH if needed
update_path() {
    local dest_dir="$1"

    case "$dest_dir" in
        /usr/local/bin)
            # Standard location, should already be in PATH
            ;;
        ~/.local/bin)
            if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
                warn "Adding $HOME/.local/bin to PATH"
                echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
                echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.zshrc" 2>/dev/null || true
                info "Please restart your shell or run: export PATH=\"\$HOME/.local/bin:\$PATH\""
            fi
            ;;
    esac
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

    # Rename binary
    mv "$DEST_DIR/devflow" "$DEST_DIR/devflow-$BINARY_NAME"
    ln -sf "$DEST_DIR/devflow-$BINARY_NAME" "$DEST_DIR/devflow"

    update_path "$DEST_DIR"

    info "Installation complete!"
    echo ""
    info "Run 'devflow --version' to verify"
    info "Run 'devflow --help' to get started"
}

main "$@"
