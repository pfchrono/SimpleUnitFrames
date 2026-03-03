# GitHub Release Upload Script
# Automatically creates a GitHub release and uploads the archive
# 
# Requirements:
#   - GitHub Personal Access Token (with 'repo' scope)
#   - Set as environment variable: $env:GITHUB_TOKEN
#
# Usage:
#   .\upload-github-release.ps1 -Version "1.26.0" -ArchivePath "./releases/SimpleUnitFrames-1.26.0.zip" -OwnerRepo "pfchrono/SimpleUnitFrames"

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$true)]
    [string]$ArchivePath,
    
    [Parameter(Mandatory=$true)]
    [string]$OwnerRepo,
    
    [string]$ReleaseNotesFile = $null,
    [string]$ReleaseName = "SimpleUnitFrames v$Version - Release"
)

$ErrorActionPreference = "Stop"

# Parse owner/repo
$parts = $OwnerRepo -split "/"
if ($parts.Count -ne 2) {
    Write-Host "❌ Invalid OwnerRepo format. Use: owner/repo" -ForegroundColor Red
    exit 1
}

$owner, $repo = $parts
$tag = "v$Version"

# Verify token
$token = $env:GITHUB_TOKEN
if (-not $token) {
    Write-Host "❌ GITHUB_TOKEN environment variable not set" -ForegroundColor Red
    Write-Host "   Set with: `$env:GITHUB_TOKEN = 'your-token'" -ForegroundColor Yellow
    exit 1
}

# Verify archive exists
if (-not (Test-Path $ArchivePath)) {
    Write-Host "❌ Archive not found: $ArchivePath" -ForegroundColor Red
    exit 1
}

$archiveFile = Get-Item $ArchivePath
$archiveSize = [math]::Round($archiveFile.Length / 1MB, 2)

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "GitHub Release Upload" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📦 Release Details:" -ForegroundColor Yellow
Write-Host "   Owner/Repo: $OwnerRepo"
Write-Host "   Tag: $tag"
Write-Host "   Title: $ReleaseName"
Write-Host "   Archive: $($archiveFile.Name) ($archiveSize MB)"
Write-Host ""

# Read release notes if provided
$releaseBody = ""
if ($ReleaseNotesFile -and (Test-Path $ReleaseNotesFile)) {
    $releaseBody = Get-Content $ReleaseNotesFile -Raw
    Write-Host "📝 Using release notes from: $ReleaseNotesFile" -ForegroundColor Gray
}
else {
    $releaseBody = "SimpleUnitFrames v$Version Release`n`nFor details, see the archive contents."
}

try {
    Write-Host "🔐 Authenticating with GitHub..." -ForegroundColor Cyan
    
    # Create release
    Write-Host "📌 Creating GitHub release..." -ForegroundColor Cyan
    
    $headers = @{
        "Authorization" = "token $token"
        "Accept" = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
    
    $releaseData = @{
        tag_name = $tag
        name = $ReleaseName
        body = $releaseBody
        draft = $false
        prerelease = $false
    } | ConvertTo-Json
    
    $createUrl = "https://api.github.com/repos/$owner/$repo/releases"
    $releaseResponse = Invoke-RestMethod -Uri $createUrl -Method Post -Headers $headers -Body $releaseData -ContentType "application/json"
    
    $releaseId = $releaseResponse.id
    $uploadUrlBase = $releaseResponse.upload_url -replace '\{.*?\}', ''  # Remove the {?name,label} part
    
    Write-Host "   ✓ Release created (ID: $releaseId)" -ForegroundColor Green
    
    # Upload archive
    Write-Host "📦 Uploading archive..." -ForegroundColor Cyan
    
    # Build upload URL with proper parameter encoding
    $fileName = [System.Uri]::EscapeDataString($archiveFile.Name)
    $uploadUrl = "${uploadUrlBase}?name=$fileName"
    $archiveContent = [System.IO.File]::ReadAllBytes($ArchivePath)
    
    $uploadHeaders = @{
        "Authorization" = "token $token"
        "Accept" = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
        "Content-Type" = "application/octet-stream"
    }
    
    $assetResponse = Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers $uploadHeaders -Body $archiveContent
    
    Write-Host "   ✓ Archive uploaded" -ForegroundColor Green
    Write-Host "   ✓ Asset ID: $($assetResponse.id)" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "✅ Release Published Successfully!" -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "🔗 View Release:" -ForegroundColor Yellow
    Write-Host "   https://github.com/$owner/$repo/releases/tag/$tag" -ForegroundColor Cyan
    Write-Host ""
    
}
catch {
    Write-Host ""
    Write-Host "❌ Upload failed:" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    
    # Try to get detailed error response
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
        Write-Host "   Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    elseif ($_ -is [System.Net.WebException] -and $_.Exception.Response) {
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            $reader.Close()
            Write-Host "   Server Response: $responseBody" -ForegroundColor Red
        } catch {
            Write-Host "   (Could not read server response)" -ForegroundColor Gray
        }
    }
    
    exit 1
}
