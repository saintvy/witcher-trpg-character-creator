# Script to combine all SQL files from items folder into one file
# Usage: .\build_all.ps1 [output_file]

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputFile = if ($args.Count -gt 0) { $args[0] } else { Join-Path $scriptDir "all_items.sql" }

# Get all SQL files, sorted by name
$sqlFiles = Get-ChildItem -Path $scriptDir -Filter "*.sql" | 
    Where-Object { $_.Name -notmatch "^all_items\.sql$" } |
    Sort-Object Name

if ($sqlFiles.Count -eq 0) {
    Write-Host "SQL files not found in folder $scriptDir" -ForegroundColor Yellow
    exit 1
}

Write-Host "Found $($sqlFiles.Count) SQL files" -ForegroundColor Green

# Create output file
$dateStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$output = "-- ============================================================================`n"
$output += "-- Automatically combined file from all SQL scripts in items folder`n"
$output += "-- Generated: $dateStr`n"
$output += "-- File count: $($sqlFiles.Count)`n"
$output += "-- ============================================================================`n`n"

# Add content of each file
foreach ($file in $sqlFiles) {
    $output += "`n-- ============================================================================`n"
    $output += "-- File: $($file.Name)`n"
    $output += "-- ============================================================================`n`n"
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $output += $content
    $output += "`n`n"
}

# Save result
[System.IO.File]::WriteAllText($outputFile, $output, [System.Text.Encoding]::UTF8)

Write-Host "File created: $outputFile" -ForegroundColor Green
Write-Host "Size: $([math]::Round((Get-Item $outputFile).Length / 1KB, 2)) KB" -ForegroundColor Cyan
