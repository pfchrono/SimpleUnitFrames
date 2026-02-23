param(
	[switch]$AllChanges,
	[string]$Type = "feat",
	[string]$Scope = "",
	[string]$OutputFile = "",
	[switch]$NoCodex,
	[int]$CodexTimeoutSec = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
	$PSNativeCommandUseErrorActionPreference = $false
}

function Write-Message {
	param([string]$Text)
	if ($OutputFile) {
		Set-Content -Path $OutputFile -Value $Text -Encoding UTF8
	} else {
		Write-Output $Text
	}
}

$diffArgs = @("diff")
if (-not $AllChanges) {
	$diffArgs += "--cached"
}

$nameOnlyText = (& git @diffArgs --name-only 2>$null) -join "`n"
$files = @()
if ($nameOnlyText) {
	$files = @(
		$nameOnlyText -split "`n" |
		ForEach-Object { $_.Trim() } |
		Where-Object { $_ -ne "" -and $_ -notmatch '^warning:' }
	)
}

if ($files.Count -eq 0 -and -not $AllChanges) {
	$nameOnlyText = (& git diff --name-only 2>$null) -join "`n"
	if ($nameOnlyText) {
		$files = @(
			$nameOnlyText -split "`n" |
			ForEach-Object { $_.Trim() } |
			Where-Object { $_ -ne "" -and $_ -notmatch '^warning:' }
		)
		$AllChanges = $true
		$diffArgs = @("diff")
	}
}

if ($files.Count -eq 0) {
	Write-Message "chore: no changes detected"
	exit 0
}

$shortStat = (& git @diffArgs --shortstat 2>$null) -join "`n"
$insertions = 0
$deletions = 0
if ($shortStat -match "(\d+)\s+insertion") { $insertions = [int]$Matches[1] }
if ($shortStat -match "(\d+)\s+deletion") { $deletions = [int]$Matches[1] }

$areas = [ordered]@{
	"oUF sync" = @($files | Where-Object { $_ -like "Libraries/oUF/*" }).Count
	"SUF core" = @($files | Where-Object { $_ -eq "SimpleUnitFrames.lua" -or $_ -like "Units/*" }).Count
	"TOC" = @($files | Where-Object { $_ -like "*.toc" }).Count
	"Docs" = @($files | Where-Object { $_ -like "*.md" }).Count
	"Media" = @($files | Where-Object { $_ -like "Media/*" }).Count
}

$nonZeroAreas = @($areas.Keys | Where-Object { $areas[$_] -gt 0 })
if ($nonZeroAreas.Count -eq 0) {
	$nonZeroAreas = @("misc updates")
}

$subjectParts = @()
foreach ($area in $nonZeroAreas) {
	$subjectParts += $area.ToLowerInvariant()
	if ($subjectParts.Count -ge 3) { break }
}

$subjectCore = "update " + ($subjectParts -join ", ")
$prefix = $Type
if ($Scope -and $Scope.Trim() -ne "") {
	$prefix = "$Type($Scope)"
}
$title = "${prefix}: $subjectCore"
if ($title.Length -gt 72) {
	$title = $title.Substring(0, 72).TrimEnd()
}

$modeLabel = if ($AllChanges) { "working tree" } else { "staged" }
$summaryLine = "Auto-generated from $modeLabel changes."
$impactLine = "Changed $($files.Count) file(s), +$insertions/-$deletions lines."

$keyFiles = $files | Select-Object -First 12
$keyFileLines = @()
foreach ($file in $keyFiles) {
	$keyFileLines += "- $file"
}
if ($files.Count -gt $keyFiles.Count) {
	$keyFileLines += "- ...and $($files.Count - $keyFiles.Count) more"
}

$areaLines = @()
foreach ($area in $nonZeroAreas) {
	$areaLines += "- ${area}: $($areas[$area]) file(s)"
}

$defaultTitle = "${prefix}: $subjectCore"
if ($defaultTitle.Length -gt 72) {
	$defaultTitle = $defaultTitle.Substring(0, 72).TrimEnd()
}

$body = @()
$body += $summaryLine
$body += ""
$body += $impactLine
$body += ""
$body += "Areas touched:"
$body += $areaLines
$body += ""
$body += "Key files:"
$body += $keyFileLines

$fallbackMessage = $title + "`n`n" + (($body | ForEach-Object { [string]$_ }) -join "`n")

function Try-GenerateWithCodex {
	param(
		[string[]]$ChangedFiles,
		[string]$ShortStatText,
		[string]$DefaultTitleHint
	)

	if ($NoCodex) {
		return $null
	}

	$codexCmd = Get-Command codex -ErrorAction SilentlyContinue
	if (-not $codexCmd) {
		return $null
	}
	$codexExe = $codexCmd.Source

	$summaryFiles = ($ChangedFiles | Select-Object -First 40) -join "`n"
	$extraCount = [Math]::Max(0, $ChangedFiles.Count - 40)
	if ($extraCount -gt 0) {
		$summaryFiles += "`n...and $extraCount more files"
	}

	$diffPreview = (& git @diffArgs --unified=0 --no-color 2>$null) -join "`n"
	if ($diffPreview.Length -gt 14000) {
		$diffPreview = $diffPreview.Substring(0, 14000)
	}

	$promptLines = @(
		"Generate a high-quality git commit message for this repository.",
		"",
		"Requirements:",
		"- Output plain text only.",
		"- First line: Conventional Commit style subject (max ~72 chars).",
		"- Then a blank line.",
		"- Then concise bullet points summarizing the meaningful changes.",
		"- Do not include markdown fences.",
		"",
		"Hints:",
		"- Suggested type/scope prefix: $DefaultTitleHint",
		"- Diff scope: $(if ($AllChanges) { 'working tree' } else { 'staged changes' })",
		"- Short stat: $ShortStatText",
		"",
		"Changed files:",
		$summaryFiles,
		"",
		"Diff preview:",
		$diffPreview
	)
	$prompt = $promptLines -join "`n"

	$tempOut = [System.IO.Path]::GetTempFileName()
	try {
		$execArgs = @(
			"exec",
			"--sandbox", "read-only",
			"--output-last-message", $tempOut,
			$prompt
		)

		$job = Start-Job -ScriptBlock {
			param($exe, $a)
			& $exe @a | Out-Null
		} -ArgumentList $codexExe, (,$execArgs)

		$finished = Wait-Job -Job $job -Timeout $CodexTimeoutSec
		if (-not $finished) {
			Stop-Job -Job $job -ErrorAction SilentlyContinue | Out-Null
			Remove-Job -Job $job -Force -ErrorAction SilentlyContinue | Out-Null
			return $null
		}

		Receive-Job -Job $job -ErrorAction SilentlyContinue | Out-Null
		Remove-Job -Job $job -Force -ErrorAction SilentlyContinue | Out-Null

		if (-not (Test-Path $tempOut)) {
			return $null
		}

		$text = (Get-Content -Path $tempOut -Raw -ErrorAction SilentlyContinue)
		if (-not $text) {
			return $null
		}

		$text = $text.Trim()
		if ($text -eq "") {
			return $null
		}

		return $text
	}
	finally {
		if (Test-Path $tempOut) {
			Remove-Item -Path $tempOut -Force -ErrorAction SilentlyContinue
		}
	}
}

$codexMessage = Try-GenerateWithCodex -ChangedFiles $files -ShortStatText $shortStat -DefaultTitleHint $defaultTitle
if ($codexMessage) {
	Write-Message $codexMessage
	exit 0
}

Write-Message $fallbackMessage
