# SimpleUnitFrames Release Build Script
# Builds a release archive with all addon files, README, and bundled PerformanceLib
# 
# Usage:
#   .\build-release.ps1 -Version 1.26.0 -BuildDir ".\releases"
#   .\build-release.ps1 -Version 1.26.0 -PerformanceLibPath "C:\path\to\PerformanceLib"
#   .\build-release.ps1 -SkipPerformanceLib
#
# Parameters:
#   -Version                 Release version (default: 1.26.0)
#   -BuildDir                Output directory for zip (default: .\releases)
#   -OutputPath              Explicit zip file path
#   -PerformanceLibPath      Custom path to PerformanceLib addon (auto-detected by default)
#   -SkipPerformanceLib      Skip bundling PerformanceLib (optional dep)

param(
    [string]$Version = "1.26.0",
    [string]$BuildDir = ".\releases",
    [string]$OutputPath = $null,
    [string]$PerformanceLibPath = $null,
    [switch]$SkipPerformanceLib = $false
)

$ErrorActionPreference = "Stop"

# Paths
$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SUFDir = $RootDir
$WorkspaceRoot = Split-Path $RootDir
$TempBuild = Join-Path $env:TEMP "SUF-Release-$Version"
$ZipPath = if ($OutputPath) { $OutputPath } else { Join-Path $BuildDir "SimpleUnitFrames-$Version.zip" }

# Determine PerformanceLib path
$PerfLibDir = $null

# 1. Use explicit path if provided
if ($PerformanceLibPath -and (Test-Path $PerformanceLibPath)) {
    $PerfLibDir = $PerformanceLibPath
    Write-Host "Using PerformanceLib from explicitly provided path" -ForegroundColor Green
}
# 2. Check adjacent directory (default)
elseif (Test-Path (Join-Path $WorkspaceRoot "PerformanceLib")) {
    $PerfLibDir = Join-Path $WorkspaceRoot "PerformanceLib"
}
# 3. Check workspace root for /PerformanceLib
elseif (Test-Path (Join-Path $WorkspaceRoot ".." "PerformanceLib")) {
    $PerfLibDir = Join-Path $WorkspaceRoot ".." "PerformanceLib"
}
# 4. Search current workspace root
elseif (Test-Path "$WorkspaceRoot/PerformanceLib") {
    $PerfLibDir = "$WorkspaceRoot/PerformanceLib"
}

# 5. If still not found and not skipping, try to find it anywhere in parent directories
if (-not $PerfLibDir -and -not $SkipPerformanceLib) {
    $SearchPath = $WorkspaceRoot
    for ($i = 0; $i -lt 3; $i++) {
        $TestPath = Join-Path $SearchPath "PerformanceLib"
        if (Test-Path $TestPath) {
            $PerfLibDir = $TestPath
            break
        }
        $SearchPath = Split-Path $SearchPath
    }
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "SimpleUnitFrames Release Builder" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "📦 Version: $Version" -ForegroundColor Yellow
Write-Host "📁 Root: $RootDir" -ForegroundColor Yellow
Write-Host "🎯 Output: $ZipPath" -ForegroundColor Yellow
Write-Host ""

# Clean and create temp directory
if (Test-Path $TempBuild) {
    Remove-Item $TempBuild -Recurse -Force
    Write-Host "✓ Cleaned existing temp build directory" -ForegroundColor Green
}
New-Item -ItemType Directory -Path $TempBuild | Out-Null
Write-Host "✓ Created temp build directory: $TempBuild" -ForegroundColor Green

# Function to copy addon files (excluding .git*, docs, workspaces, etc.)
function Copy-AddonFiles {
    param([string]$SourceDir, [string]$DestDir, [string]$AddonName)
    
    Write-Host ""
    Write-Host "📌 Copying $AddonName addon files..." -ForegroundColor Cyan
    
    $ExcludePatterns = @(
        '.git',
        '.github',
        '.vscode',
        '.agents',
        '.claude',
        '.gitignore',
        'docs',
        'scripts',
        'releases',
        '*.code-workspace',
        '*.tgz',
        '*.zip',
        '*.ps1',
        'test_*',
        'node_modules',
        '__pycache__',
        'COMMIT_MESSAGE.txt',
        'CLAUDE.md',
        'API_VALIDATION_REPORT.md',
        'RESEARCH.md',
        'WORK_SUMMARY.md',
        'TODO.md',
        'LIBQTIP_*',
        'PHASE*',
        'README.workspace.md',
        'MIGRAT*'
    )
    
    $CopyCount = 0
    Get-ChildItem -Path $SourceDir -Recurse | ForEach-Object {
        $RelativePath = $_.FullName.Substring($SourceDir.Length + 1)
        $IsExcluded = $false
        
        # Check if any parent directory (or this directory) is in the exclusion list
        $RelativeParts = $RelativePath -split '\\'
        foreach ($part in $RelativeParts) {
            # Check if this part starts with a dot (catches .agents, .claude, .github, etc.)
            if ($part -like '.*') {
                $IsExcluded = $true
                break
            }
            
            # Check against exclusion patterns
            foreach ($pattern in $ExcludePatterns) {
                if ($part -like $pattern) {
                    $IsExcluded = $true
                    break
                }
            }
            if ($IsExcluded) { break }
        }
        
        # Special case: In root directory, only keep README.md (exclude all other .md files)
        if (-not $IsExcluded -and $_ -is [System.IO.FileInfo]) {
            if (-not $RelativePath.Contains('\')) {  # Root level file only
                if ($_.Extension -eq '.md' -and $_.Name -ne 'README.md') {
                    $IsExcluded = $true
                }
            }
        }
        
        if (-not $IsExcluded) {
            $DestPath = Join-Path $DestDir $RelativePath
            if ($_ -is [System.IO.DirectoryInfo]) {
                New-Item -ItemType Directory -Path $DestPath -Force | Out-Null
            }
            else {
                New-Item -ItemType Directory -Path (Split-Path $DestPath) -Force | Out-Null
                Copy-Item -Path $_.FullName -Destination $DestPath -Force
                $CopyCount++
            }
        }
    }
    
    Write-Host "  → Copied $CopyCount files from $AddonName" -ForegroundColor Green
    return $CopyCount
}

# Copy SimpleUnitFrames files
$SUFPath = Join-Path $TempBuild "SimpleUnitFrames"
New-Item -ItemType Directory -Path $SUFPath | Out-Null
$SUFCount = Copy-AddonFiles -SourceDir $SUFDir -DestDir $SUFPath -AddonName "SimpleUnitFrames"

# Copy README.md specifically (even if it's in docs exclusion logic)
$ReadmePath = Join-Path $SUFDir "README.md"
if (Test-Path $ReadmePath) {
    Copy-Item -Path $ReadmePath -Destination (Join-Path $SUFPath "README.md") -Force
    Write-Host "  → Included README.md" -ForegroundColor Green
}

# Copy PerformanceLib if it exists or can be found
if (-not $SkipPerformanceLib) {
    if ($PerfLibDir -and (Test-Path $PerfLibDir)) {
        Write-Host ""
        Write-Host "📌 Bundling PerformanceLib addon..." -ForegroundColor Cyan
        Write-Host "  → Found at: $PerfLibDir" -ForegroundColor Gray
        $PerfPath = Join-Path $TempBuild "PerformanceLib"
        New-Item -ItemType Directory -Path $PerfPath | Out-Null
        $PerfCount = Copy-AddonFiles -SourceDir $PerfLibDir -DestDir $PerfPath -AddonName "PerformanceLib"
        
        # Copy PerformanceLib README if exists
        $PerfReadme = Join-Path $PerfLibDir "README.md"
        if (Test-Path $PerfReadme) {
            Copy-Item -Path $PerfReadme -Destination (Join-Path $PerfPath "README.md") -Force
            Write-Host "  → Included PerformanceLib README.md" -ForegroundColor Green
        }
    }
    else {
        Write-Host ""
        Write-Host "⚠️  PerformanceLib not found (optional - continuing without bundling)" -ForegroundColor Yellow
        if (-not $SkipPerformanceLib) {
            Write-Host "    Searched locations:" -ForegroundColor Yellow
            Write-Host "    • $WorkspaceRoot/PerformanceLib" -ForegroundColor Gray
            Write-Host "    • $(Join-Path $WorkspaceRoot ".." "PerformanceLib")" -ForegroundColor Gray
            Write-Host ""
            Write-Host "    To specify custom path: .\build-release.ps1 -PerformanceLibPath 'C:\path\to\PerformanceLib'" -ForegroundColor Yellow
            Write-Host "    To skip bundling: .\build-release.ps1 -SkipPerformanceLib" -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host ""
    Write-Host "⏭️  PerformanceLib bundling skipped (-SkipPerformanceLib flag)" -ForegroundColor Yellow
}

# Create build info file
Write-Host ""
Write-Host "📝 Creating build info..." -ForegroundColor Cyan
$BuildInfo = @"
SimpleUnitFrames Release v$Version
Built: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Contents

- **SimpleUnitFrames/** - Main addon with complete functionality
- **PerformanceLib/** - Optional performance library (bundled for convenience)
- **README.md** - Installation and usage guide (in SimpleUnitFrames dir)

## Installation

1. Extract this archive to your World of Warcraft Interface/Addons directory
   ```
   WorldOfWarcraft\_retail_\Interface\AddOns\
   ```
   
2. Both SimpleUnitFrames and PerformanceLib will be loaded as separate addons

3. Launch WoW and enable addons in the addon list

## Usage

- **/suf** - Open main options
- **/suf test** - Open interactive test panel
- **/sufperf** - Toggle performance dashboard (requires PerformanceLib)
- **/SUFprofile start|stop|analyze** - Performance profiling

## Requirements

- World of Warcraft Retail (Patch 12.0.0+)
- PerformanceLib (optional, bundled)

## Documentation

See SimpleUnitFrames/README.md for complete documentation.
"@

$BuildInfo | Out-File -FilePath (Join-Path $TempBuild "BUILD_INFO.txt") -Encoding UTF8
Write-Host "  → Created BUILD_INFO.txt" -ForegroundColor Green

# Create zip archive
Write-Host ""
Write-Host "📦 Creating release archive..." -ForegroundColor Cyan

# Ensure output directory exists
$Output = Split-Path $ZipPath
if (-not (Test-Path $Output)) {
    New-Item -ItemType Directory -Path $Output -Force | Out-Null
}

# Remove existing zip if present
if (Test-Path $ZipPath) {
    Remove-Item $ZipPath -Force
}

# Create zip using .NET compression
$CompressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
$null = [System.IO.Compression.ZipFile]::CreateFromDirectory($TempBuild, $ZipPath, $CompressionLevel, $false)

$ZipSize = (Get-Item $ZipPath).Length / 1MB
Write-Host "  → Created: $(Split-Path $ZipPath -Leaf)" -ForegroundColor Green
Write-Host "  → Size: $([math]::Round($ZipSize, 2)) MB" -ForegroundColor Green

# Cleanup temp
Write-Host ""
Write-Host "🧹 Cleaning up temp files..." -ForegroundColor Cyan
Remove-Item $TempBuild -Recurse -Force
Write-Host "  → Removed temp build directory" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "✅ Release Archive Created Successfully!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "📦 Archive: $ZipPath" -ForegroundColor Yellow
Write-Host "💾 Size: $([math]::Round($ZipSize, 2)) MB" -ForegroundColor Yellow
Write-Host ""
Write-Host "📋 To distribute this release:" -ForegroundColor Cyan
Write-Host "   • Share the .zip file with users" -ForegroundColor Gray
Write-Host "   • They extract to: Interface\AddOns\" -ForegroundColor Gray
Write-Host "   • Both addons will auto-load" -ForegroundColor Gray
Write-Host ""
