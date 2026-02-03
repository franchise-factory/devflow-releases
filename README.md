# DevFlow Releases

This repository contains release binaries for [DevFlow](https://github.com/franchise-factory/devflow), a Go CLI tool for streamlined development workflows.

## Quick Install

### macOS / Linux

```bash
curl -sSL https://raw.githubusercontent.com/franchise-factory/devflow-releases/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/franchise-factory/devflow-releases/main/install.ps1 | iex
```

## Installation

### Prerequisites

- **macOS**: No additional dependencies
- **Linux**: No additional dependencies
- **Windows**: PowerShell 5.1 or later

### Unix Installation

The install script will:
1. Detect your OS and architecture
2. Download the appropriate binary
3. Install to `/usr/local/bin` (or `~/.local/bin` if no write access to `/usr/local/bin`)
4. Verify the checksum
5. Update your PATH if needed

```bash
# Install latest version
curl -sSL https://raw.githubusercontent.com/franchise-factory/devflow-releases/main/install.sh | bash

# Install specific version
curl -sSL https://raw.githubusercontent.com/franchise-factory/devflow-releases/main/install.sh | bash -s -- v0.1.0

# Install to custom directory
curl -sSL https://raw.githubusercontent.com/franchise-factory/devflow-releases/main/install.sh | bash -s -- -d ~/.local/bin
```

### Windows Installation

The PowerShell script will:
1. Detect your architecture
2. Download the appropriate binary
3. Install to a user-accessible location
4. Add to your PATH (if requested)

```powershell
# Install latest version
irm https://raw.githubusercontent.com/franchise-factory/devflow-releases/main/install.ps1 | iex

# Install specific version
irm https://raw.githubusercontent.com/franchise-factory/devflow-releases/main/install.ps1 | iex -Version v0.1.0

# Install to custom directory
irm https://raw.githubusercontent.com/franchise-factory/devflow-releases/main/install.ps1 | iex -Destination "C:\Tools"
```

### Manual Installation

1. Download the binary for your platform from the [latest release](https://github.com/franchise-factory/devflow-releases)
2. Verify the checksum:
   ```bash
   sha256sum -c checksums.txt
   ```
3. Make it executable (Unix only):
   ```bash
   chmod +x devflow-*
   ```
4. Move to your PATH:
   ```bash
   # macOS/Linux
   sudo mv devflow-* /usr/local/bin/devflow

   # Windows
   # Add to your PATH manually or use the PowerShell script
   ```

## Verification

After installation, verify:

```bash
devflow --version
devflow --help
```

## Supported Platforms

| Platform | Architecture | Binary |
|----------|-------------|--------|
| macOS | Apple Silicon (arm64) | `devflow-darwin-arm64` |
| macOS | Intel (amd64) | `devflow-darwin-amd64` |
| Linux | amd64 | `devflow-linux-amd64` |
| Linux | arm64 | `devflow-linux-arm64` |
| Windows | amd64 | `devflow-windows-amd64.exe` |

## Version History

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.

## Development

DevFlow is developed at [franchise-factory/devflow](https://github.com/franchise-factory/devflow).

## License

MIT License - see main DevFlow repository for details.
