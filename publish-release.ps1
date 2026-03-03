<#
.SYNOPSIS
    Automated GitHub release publisher with TOC version auto-detection.

.DESCRIPTION
    Reads version from SimpleUnitFrames.toc, sets GitHub token, and publishes release.
    This is a convenience wrapper around upload-github-release.ps1.

.PARAMETER TocFile
    Path to the TOC file (default: ./SimpleUnitFrames.toc)

.PARAMETER OwnerRepo
    GitHub repository in owner/repo format (default: pfchrono/SimpleUnitFrames)

.PARAMETER GitHubToken
    GitHub Personal Access Token with 'repo' scope.
    If not provided, will read from GITHUB_TOKEN environment variable.

.PARAMETER ReleasesDir
    Directory containing release archives (default: ./releases)

.PARAMETER DryRun
    Show what would be done without actually publishing

.EXAMPLE
    .\publish-release.ps1 -GitHubToken 'ghp_xxxxx'
    
.EXAMPLE
    .\publish-release.ps1
    # Uses GITHUB_TOKEN environment variable

.EXAMPLE
    $env:GITHUB_TOKEN = 'ghp_xxxxx'
    .\publish-release.ps1 -DryRun
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$TocFile = "./SimpleUnitFrames.toc",

    [Parameter()]
    [string]$OwnerRepo = "pfchrono/SimpleUnitFrames",

    [Parameter()]
    [string]$GitHubToken,

    [Parameter()]
    [string]$ReleasesDir = "./releases",

    [Parameter()]
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Function: Extract version from TOC file
function Get-VersionFromToc {
    param([string]$TocPath)
    
    if (-not (Test-Path $TocPath)) {
        throw "TOC file not found: $TocPath"
    }
    
    $content = Get-Content $TocPath -Raw
    if ($content -match '##\s*Version:\s*([0-9]+\.[0-9]+\.[0-9]+)') {
        # Extract only major.minor.patch (ignore date suffix)
        return $Matches[1]
    }
    
    throw "Could not extract version from TOC file: $TocPath"
}

# Function: Verify prerequisites
function Test-Prerequisites {
    # Check if upload-github-release.ps1 exists
    $uploadScript = Join-Path $PSScriptRoot "upload-github-release.ps1"
    if (-not (Test-Path $uploadScript)) {
        throw "Required script not found: upload-github-release.ps1"
    }
    
    return $uploadScript
}

# Main execution
try {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "SimpleUnitFrames Release Publisher" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Verify prerequisites
    Write-Host "→ Verifying prerequisites..." -ForegroundColor Yellow
    $uploadScriptPath = Test-Prerequisites
    Write-Host "  ✓ upload-github-release.ps1 found" -ForegroundColor Green
    
    # Extract version from TOC
    Write-Host ""
    Write-Host "→ Reading version from TOC file..." -ForegroundColor Yellow
    $version = Get-VersionFromToc -TocPath $TocFile
    Write-Host "  ✓ Version detected: $version" -ForegroundColor Green
    
    # Construct paths
    $archiveName = "SimpleUnitFrames-$version.zip"
    $archivePath = Join-Path $ReleasesDir $archiveName
    $releaseNotesFile = "RELEASE_NOTES_v$version.md"
    
    # Verify archive exists
    Write-Host ""
    Write-Host "→ Verifying release archive..." -ForegroundColor Yellow
    if (-not (Test-Path $archivePath)) {
        throw "Release archive not found: $archivePath`nPlease run build-release.ps1 first."
    }
    $archiveSize = (Get-Item $archivePath).Length / 1MB
    Write-Host ("  ✓ Archive found: {0:N2} MB" -f $archiveSize) -ForegroundColor Green
    
    # Verify release notes exist
    Write-Host ""
    Write-Host "→ Verifying release notes..." -ForegroundColor Yellow
    if (-not (Test-Path $releaseNotesFile)) {
        Write-Host "  ⚠ Release notes not found: $releaseNotesFile" -ForegroundColor Yellow
        Write-Host "    Will create release without detailed notes." -ForegroundColor Yellow
        $releaseNotesFile = $null
    } else {
        Write-Host "  ✓ Release notes found: $releaseNotesFile" -ForegroundColor Green
    }
    
    # Handle GitHub token
    Write-Host ""
    Write-Host "→ Checking GitHub authentication..." -ForegroundColor Yellow
    if ($GitHubToken) {
        $env:GITHUB_TOKEN = $GitHubToken
        Write-Host "  ✓ Token provided via parameter" -ForegroundColor Green
    } elseif ($env:GITHUB_TOKEN) {
        Write-Host "  ✓ Token found in GITHUB_TOKEN environment variable" -ForegroundColor Green
    } else {
        throw "GitHub token required. Provide via -GitHubToken parameter or GITHUB_TOKEN environment variable."
    }
    
    # Display summary
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Release Configuration" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Version:       " -NoNewline; Write-Host $version -ForegroundColor White
    Write-Host "  Repository:    " -NoNewline; Write-Host $OwnerRepo -ForegroundColor White
    Write-Host "  Archive:       " -NoNewline; Write-Host $archivePath -ForegroundColor White
    Write-Host "  Archive Size:  " -NoNewline; Write-Host ("{0:N2} MB" -f $archiveSize) -ForegroundColor White
    Write-Host "  Release Notes: " -NoNewline
    if ($releaseNotesFile) {
        Write-Host $releaseNotesFile -ForegroundColor White
    } else {
        Write-Host "(none)" -ForegroundColor Gray
    }
    Write-Host ""
    
    if ($DryRun) {
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "DRY RUN - Would Execute:" -ForegroundColor Yellow
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  & `"$uploadScriptPath`" ```" -ForegroundColor Gray
        Write-Host "    -Version '$version' ```" -ForegroundColor Gray
        Write-Host "    -ArchivePath '$archivePath' ```" -ForegroundColor Gray
        Write-Host "    -OwnerRepo '$OwnerRepo' ```" -ForegroundColor Gray
        if ($releaseNotesFile) {
            Write-Host "    -ReleaseNotesFile '$releaseNotesFile'" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "✓ Dry run complete. No changes made." -ForegroundColor Green
        Write-Host ""
        return
    }
    
    # Confirm before publishing
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    $confirmation = Read-Host "Publish release v$version to GitHub? (y/N)"
    if ($confirmation -notmatch '^[Yy]') {
        Write-Host ""
        Write-Host "✗ Release cancelled by user." -ForegroundColor Yellow
        Write-Host ""
        return
    }
    
    # Execute upload
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Publishing Release to GitHub" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $uploadParams = @{
        Version = $version
        ArchivePath = $archivePath
        OwnerRepo = $OwnerRepo
    }
    
    if ($releaseNotesFile) {
        $uploadParams['ReleaseNotesFile'] = $releaseNotesFile
    }
    
    & $uploadScriptPath @uploadParams
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "✓ Release v$version Published Successfully!" -ForegroundColor Green
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "View release at: https://github.com/$OwnerRepo/releases/tag/v$version" -ForegroundColor Cyan
        Write-Host ""
    } else {
        throw "Release publication failed with exit code: $LASTEXITCODE"
    }
    
} catch {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "✗ Error Publishing Release" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    
    if ($_.Exception.InnerException) {
        Write-Host "Inner Exception:" -ForegroundColor Yellow
        Write-Host $_.Exception.InnerException.Message -ForegroundColor Red
        Write-Host ""
    }
    
    exit 1
}
