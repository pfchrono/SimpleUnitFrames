param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[sync-skills] $Message"
}

$agentsDir = $PSScriptRoot
$repoRoot = Split-Path -Parent $agentsDir
$sourceDir = Join-Path $repoRoot ".github\skills"
$destDir = Join-Path $agentsDir "skills"

if (-not (Test-Path $sourceDir)) {
    throw "Source skills directory not found: $sourceDir"
}

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir | Out-Null
}

Write-Info "Source: $sourceDir"
Write-Info "Destination: $destDir"

if ($DryRun) {
    Write-Info "Dry run enabled. No files will be copied."
} else {
    $null = robocopy $sourceDir $destDir /E /R:2 /W:1 /NFL /NDL /NJH /NJS /NC /NS /NP
    if ($LASTEXITCODE -gt 7) {
        throw "robocopy failed with exit code $LASTEXITCODE"
    }
    Write-Info "Sync copy complete (robocopy exit code: $LASTEXITCODE)."
}

$skillFiles = Get-ChildItem -Path $destDir -Recurse -Filter "SKILL.md" -File
$normalizedCount = 0
$invalidFiles = @()

foreach ($file in $skillFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    if ([string]::IsNullOrWhiteSpace($content)) {
        $invalidFiles += $file.FullName
        continue
    }

    $lines = @($content -split "`r?`n")
    $changed = $false

    if ($lines.Count -gt 0 -and $lines[0].Trim() -eq '```skill') {
        if ($lines.Count -eq 1) {
            $lines = @()
        } else {
            $lines = $lines[1..($lines.Count - 1)]
        }
        $changed = $true
    }

    while ($lines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($lines[-1])) {
        if ($lines.Count -eq 1) {
            $lines = @()
        } else {
            $lines = $lines[0..($lines.Count - 2)]
        }
        $changed = $true
    }

    if ($lines.Count -gt 0 -and $lines[-1].Trim() -eq '```') {
        if ($lines.Count -eq 1) {
            $lines = @()
        } else {
            $lines = $lines[0..($lines.Count - 2)]
        }
        $changed = $true
    }

    if ($changed -and -not $DryRun) {
        Set-Content -Path $file.FullName -Value $lines -Encoding UTF8
        $normalizedCount++
    }

    if ($lines.Count -eq 0 -or $lines[0].Trim() -ne "---") {
        $invalidFiles += $file.FullName
    }
}

if ($invalidFiles.Count -gt 0) {
    Write-Info "Validation failed. Invalid SKILL.md files:"
    $invalidFiles | ForEach-Object { Write-Host " - $_" }
    exit 1
}

Write-Info "Validated $($skillFiles.Count) SKILL.md files."
if ($DryRun) {
    Write-Info "Dry run complete."
} else {
    Write-Info "Normalized $normalizedCount SKILL.md file(s)."
    Write-Info "Done."
}
