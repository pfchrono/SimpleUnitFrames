<#
.SYNOPSIS
    Publishes a new release with auto-generated release notes.

.DESCRIPTION
    This script:
    - Generates release notes from commits since the last tag
    - Updates CHANGELOG.md with the new release
    - Creates a git tag
    - Optionally pushes to remote

.PARAMETER Version
    The version number for this release (e.g., "1.28.1")

.PARAMETER Push
    If specified, pushes the tag to the remote repository

.PARAMETER ChangelogPath
    Path to the CHANGELOG.md file (default: "CHANGELOG.md")

.PARAMETER DryRun
    If specified, shows what would be done without making changes

.EXAMPLE
    .\publish-release.ps1 -Version "1.28.1"
    Creates a release with auto-generated notes

.EXAMPLE
    .\publish-release.ps1 -Version "1.28.1" -Push
    Creates a release and pushes the tag to remote

.EXAMPLE
    .\publish-release.ps1 -Version "1.28.1" -DryRun
    Shows what would be done without making changes
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [switch]$Push,

    [string]$ChangelogPath = "CHANGELOG.md",

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Validate version format (e.g., 1.28.1 or 1.28.1.30326)
if ($Version -notmatch '^\d+\.\d+\.\d+(\.\d+)?$') {
    Write-Error "Invalid version format. Expected format: X.Y.Z or X.Y.Z.BUILD (e.g., 1.28.1 or 1.28.1.30326)"
    exit 1
}

# Ensure we're in a git repository
if (-not (Test-Path ".git")) {
    Write-Error "Not in a git repository root"
    exit 1
}

# Get the last tag
Write-Host "🔍 Finding last release tag..." -ForegroundColor Cyan
$lastTag = git describe --tags --abbrev=0 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "No previous tags found. Will generate notes from all commits."
    $lastTag = $null
}
else {
    Write-Host "   Last tag: $lastTag" -ForegroundColor Gray
}

# Get commits since last tag
$commitRange = if ($lastTag) { "$lastTag..HEAD" } else { "HEAD" }
Write-Host "📝 Analyzing commits in range: $commitRange" -ForegroundColor Cyan

# Use a unique delimiter (<<<COMMIT_BREAK>>>) instead of newlines
# Format: %H|%s (we only need hash and subject for categorization, not body)
$commits = git log $commitRange --pretty=format:"%H|%s<<<COMMIT_BREAK>>>" --no-merges
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to get git log"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($commits)) {
    Write-Warning "No commits found since last tag. Nothing to release."
    exit 0
}

# Parse and categorize commits
$categories = @{
    "Added"      = @()
    "Changed"    = @()
    "Fixed"      = @()
    "Removed"    = @()
    "Security"   = @()
    "Performance"= @()
    "Documentation" = @()
    "Other"      = @()
}

# Split by the unique delimiter to separate commits
$commitEntries = $commits -split "<<<COMMIT_BREAK>>>" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
foreach ($entry in $commitEntries) {
    # Format is now simply: hash|subject
    if ([string]::IsNullOrWhiteSpace($entry)) { continue }
    
    # Split by | to separate hash and subject
    $parts = $entry -split "\|", 2
    if ($parts.Count -lt 2) { continue }
    
    $hash = $parts[0].Trim()
    $subject = $parts[1].Trim()
    
    # DEBUG: Show what we're parsing
    # Write-Host "DEBUG: hash=$hash subject_len=$($subject.Length) first_50_chars=$($subject.Substring(0, [Math]::Min(50, $subject.Length)))"
    
    # Skip if empty
    if ([string]::IsNullOrWhiteSpace($subject)) { continue }
    
    # Categorize by conventional commit prefix
    $category = "Other"
    $message = $subject
    
    # Extract conventional commit type and scope
    if ($subject -match '^(feat|feature|add)(\([^)]+\))?:\s*(.+)$') {
        $category = "Added"
        $message = $Matches[3]
    }
    elseif ($subject -match '^(fix|bugfix)(\([^)]+\))?:\s*(.+)$') {
        $category = "Fixed"
        $message = $Matches[3]
    }
    elseif ($subject -match '^(change|refactor|style|chore)(\([^)]+\))?:\s*(.+)$') {
        $category = "Changed"
        $message = $Matches[3]
    }
    elseif ($subject -match '^(remove|delete)(\([^)]+\))?:\s*(.+)$') {
        $category = "Removed"
        $message = $Matches[3]
    }
    elseif ($subject -match '^(perf|performance)(\([^)]+\))?:\s*(.+)$') {
        $category = "Performance"
        $message = $Matches[3]
    }
    elseif ($subject -match '^(docs|doc|documentation)(\([^)]+\))?:\s*(.+)$') {
        $category = "Documentation"
        $message = $Matches[3]
    }
    elseif ($subject -match '^(security|sec)(\([^)]+\))?:\s*(.+)$') {
        $category = "Security"
        $message = $Matches[3]
    }
    elseif ($subject -match '^(sync)(\([^)]+\))?:\s*(.+)$') {
        $category = "Changed"
        $message = "Sync: $($Matches[3])"
    }
    
    # Capitalize first letter
    if ($message.Length -gt 0) {
        $message = $message.Substring(0, 1).ToUpper() + $message.Substring(1)
    }
    
    # Add commit hash reference (short form)
    $shortHash = $hash.Substring(0, 7)
    $changeEntry = "- $message (``$shortHash``)"
    
    $categories[$category] += $changeEntry
}

# Count total changes
$totalChanges = ($categories.Values | ForEach-Object { $_.Count }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum

if ($totalChanges -eq 0) {
    Write-Warning "No categorizable commits found. Nothing to release."
    exit 0
}

Write-Host "✅ Found $totalChanges changes across $($categories.Keys.Count) categories" -ForegroundColor Green

# Generate changelog entry
$releaseDate = Get-Date -Format "yyyy-MM-dd"
$newEntry = @"
## [$Version] - $releaseDate

"@

foreach ($category in @("Added", "Changed", "Fixed", "Removed", "Security", "Performance", "Documentation", "Other")) {
    $items = $categories[$category]
    if ($items.Count -gt 0) {
        $newEntry += "`n### $category`n"
        foreach ($item in $items) {
            $newEntry += "$item`n"
        }
    }
}

$newEntry += "`n---`n"

# Show preview
Write-Host "`n📄 Generated Release Notes:" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor DarkGray
Write-Host $newEntry -ForegroundColor White
Write-Host "=" * 60 -ForegroundColor DarkGray

if ($DryRun) {
    Write-Host "`n🔍 DRY RUN MODE - No changes made" -ForegroundColor Yellow
    Write-Host "   Would update: $ChangelogPath" -ForegroundColor Gray
    Write-Host "   Would create tag: v$Version" -ForegroundColor Gray
    if ($Push) {
        Write-Host "   Would push tag to remote" -ForegroundColor Gray
    }
    exit 0
}

# Update CHANGELOG.md
if (-not (Test-Path $ChangelogPath)) {
    Write-Error "CHANGELOG.md not found at: $ChangelogPath"
    exit 1
}

Write-Host "`n📝 Updating CHANGELOG.md..." -ForegroundColor Cyan

$changelogContent = Get-Content -Path $ChangelogPath -Raw
# Find the position after the header to insert new entry
$headerPattern = "(?s)(# .+?Changelog\s+.*?\n\n)"
if ($changelogContent -match $headerPattern) {
    $updatedChangelog = $changelogContent -replace $headerPattern, "`$1$newEntry`n"
}
else {
    # If no header pattern found, prepend to file
    $updatedChangelog = $newEntry + "`n`n" + $changelogContent
}

Set-Content -Path $ChangelogPath -Value $updatedChangelog -NoNewline -Encoding UTF8
Write-Host "   ✅ CHANGELOG.md updated" -ForegroundColor Green

# Generate release notes file for manual GitHub upload (if using publish-release.ps1 directly)
$releaseNotesPath = "RELEASE_NOTES_v$Version.md"
Write-Host "`n📝 Generating release notes file for GitHub upload..." -ForegroundColor Cyan
Set-Content -Path $releaseNotesPath -Value $newEntry -NoNewline -Encoding UTF8
Write-Host "   ✅ $releaseNotesPath created" -ForegroundColor Green
Write-Host "   💡 This file can be used with: .\publish-release.ps1 -Version $Version" -ForegroundColor Gray

# Stage the changelog
git add $ChangelogPath
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to stage CHANGELOG.md"
    exit 1
}

# Create commit for changelog update
$commitMessage = "chore: Update CHANGELOG.md for v$Version"
git commit -m $commitMessage
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Failed to commit CHANGELOG.md (might be nothing to commit)"
}
else {
    Write-Host "   ✅ Committed CHANGELOG.md update" -ForegroundColor Green
}

# Create git tag
$tagName = "v$Version"
Write-Host "`n🏷️  Creating tag: $tagName" -ForegroundColor Cyan

# Create tag with full release notes as the annotation message
# This ensures BigWigs packager can extract the notes for GitHub releases
$tagMessage = @"
Release $Version

$newEntry
"@

git tag -a $tagName -m $tagMessage
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create tag: $tagName"
    exit 1
}

Write-Host "   ✅ Tag created: $tagName" -ForegroundColor Green

# Push to remote if requested
if ($Push) {
    Write-Host "`n🚀 Pushing to remote..." -ForegroundColor Cyan
    
    # Push commits
    git push origin
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to push commits"
        exit 1
    }
    Write-Host "   ✅ Commits pushed" -ForegroundColor Green
    
    # Push tag
    git push origin $tagName
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to push tag: $tagName"
        exit 1
    }
    Write-Host "   ✅ Tag pushed: $tagName" -ForegroundColor Green
}

# Summary
Write-Host "`n" + "=" * 60 -ForegroundColor Green
Write-Host "🎉 Release $Version published successfully!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green

Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "  Version: $Version" -ForegroundColor White
Write-Host "  Tag: $tagName" -ForegroundColor White
Write-Host "  Changes: $totalChanges commits" -ForegroundColor White
Write-Host "  Changelog: Updated" -ForegroundColor White
if ($Push) {
    Write-Host "  Remote: Pushed" -ForegroundColor White
}
else {
    Write-Host "  Remote: Not pushed (use -Push to push)" -ForegroundColor Yellow
}

Write-Host "`n💡 Next steps:" -ForegroundColor Cyan
if (-not $Push) {
    Write-Host "  1. Review the changes in CHANGELOG.md" -ForegroundColor Gray
    Write-Host "  2. Run: git push origin && git push origin $tagName" -ForegroundColor Gray
}
Write-Host "  $(if ($Push) { '1' } else { '3' }). Create a GitHub release at: https://github.com/YOUR_ORG/SimpleUnitFrames/releases/new?tag=$tagName" -ForegroundColor Gray

exit 0
