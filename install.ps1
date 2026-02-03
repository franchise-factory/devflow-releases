# DevFlow Installer for Windows
# Usage: irm https://raw.githubusercontent.com/franchise-factory/devflow-releases/main/install.ps1 | iex

param(
    [string]$Version = "latest",
    [string]$Destination = ""
)

$ErrorActionPreference = "Stop"
$GitHubRepo = "franchise-factory/devflow-releases"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    exit 1
}

function Detect-Platform {
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    switch ($arch) {
        "X64" { return "amd64" }
        "Arm64" { return "arm64" }
        default { Write-Error "Unsupported architecture: $arch" }
    }
}

function Get-DestinationDir {
    if ($Destination) {
        $dest = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)
        if (-not (Test-Path $dest)) {
            New-Item -ItemType Directory -Path $dest -Force | Out-Null
        }
        return $dest
    }

    # Use user's local AppData
    $dest = Join-Path $env:LOCALAPPDATA "devflow"
    if (-not (Test-Path $dest)) {
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
    }
    return $dest
}

function Download-Binary {
    param(
        [string]$Version,
        [string]$DestDir
    )

    $arch = Detect-Platform
    $binaryName = "devflow-windows-$arch.exe"

    if ($Version -eq "latest") {
        $downloadUrl = "https://github.com/$GitHubRepo/releases/latest/download/$binaryName"
    } else {
        $downloadUrl = "https://github.com/$GitHubRepo/releases/download/$Version/$binaryName"
    }

    Write-Info "Downloading DevFlow from $downloadUrl"
    $outputPath = Join-Path $DestDir "devflow.exe"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath

    return $binaryName
}

function Verify-Checksum {
    param(
        [string]$DestDir,
        [string]$Version,
        [string]$BinaryName
    )

    Write-Info "Verifying checksum..."

    if ($Version -eq "latest") {
        $checksumUrl = "https://github.com/$GitHubRepo/releases/latest/download/checksums.txt"
    } else {
        $checksumUrl = "https://github.com/$GitHubRepo/releases/download/$Version/checksums.txt"
    }

    $checksumFile = Join-Path $env:TEMP "checksums.txt"
    Invoke-WebRequest -Uri $checksumUrl -OutFile $checksumFile

    $checksums = Get-Content $checksumFile
    $expected = ($checksums | Where-Object { $_ -like "*$BinaryName*" }).Split(" ")[0]

    $actual = (Get-FileHash -Path (Join-Path $DestDir "devflow.exe") -Algorithm SHA256).Hash.ToLower()

    if ($expected -ne $actual) {
        Write-Error "Checksum mismatch! Expected: $expected, Got: $actual"
    }

    Write-Info "Checksum verified"
    Remove-Item $checksumFile -Force
}

function Update-Path {
    param([string]$DestDir)

    $pathEnv = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($pathEnv -notlike "*$DestDir*") {
        $addToPath = Read-Host "Add $DestDir to PATH? (Y/n)"
        if ($addToPath -ne "n") {
            [Environment]::SetEnvironmentVariable("Path", "$pathEnv;$DestDir", "User")
            Write-Info "Added to PATH. Please restart your terminal for changes to take effect."
        }
    }
}

function Main {
    Write-Host "DevFlow Installer" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan

    $arch = Detect-Platform
    Write-Info "Detected architecture: $arch"

    $destDir = Get-DestinationDir
    Write-Info "Installing to: $destDir"

    $binaryName = Download-Binary -Version $Version -DestDir $destDir
    Verify-Checksum -DestDir $destDir -Version $Version -BinaryName $binaryName

    Update-Path -DestDir $destDir

    Write-Info "Installation complete!"
    Write-Host ""
    Write-Info "Run 'devflow --version' to verify"
    Write-Info "Run 'devflow --help' to get started"
}

Main
