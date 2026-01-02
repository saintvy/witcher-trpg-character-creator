# Script to generate DROP IF EXISTS commands for all tables based on file names
# Usage: .\generate_drops.ps1 [output_file]

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputFile = if ($args.Count -gt 0) { $args[0] } else { Join-Path $scriptDir "drop_all_tables.sql" }

# Get all SQL files
$sqlFiles = Get-ChildItem -Path $scriptDir -Filter "*.sql" | 
    Where-Object { $_.Name -notmatch "^(all_items|drop_all_tables)\.sql$" } |
    Sort-Object Name

if ($sqlFiles.Count -eq 0) {
    Write-Host "SQL files not found in folder $scriptDir" -ForegroundColor Yellow
    exit 1
}

Write-Host "Found $($sqlFiles.Count) SQL files" -ForegroundColor Green

# Extract table names from file names
$tables = @()

foreach ($file in $sqlFiles) {
    # File format: NNN_wcc_table_name.sql
    # Extract part after first underscore
    $fileName = $file.BaseName
    if ($fileName -match '^\d+_(.+)$') {
        $tableName = $matches[1]
        $tables += $tableName
        Write-Host "  Found table: $tableName" -ForegroundColor Cyan
    } else {
        Write-Host "  Warning: Could not extract table name from file $($file.Name)" -ForegroundColor Yellow
    }
}

if ($tables.Count -eq 0) {
    Write-Host "No tables found for DROP command generation" -ForegroundColor Yellow
    exit 1
}

# Generate DROP commands in reverse order (for proper deletion order considering dependencies)
# Sort in reverse order by file name
$tables = $tables | Sort-Object -Descending

$dateStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$output = "-- ============================================================================`n"
$output += "-- Automatically generated DROP IF EXISTS commands for all tables`n"
$output += "-- Generated: $dateStr`n"
$output += "-- Table count: $($tables.Count)`n"
$output += "-- ============================================================================`n"
$output += "-- WARNING: This file will delete all tables from items folder!`n"
$output += "-- Use with caution.`n"
$output += "-- ============================================================================`n`n"

# Generate DROP commands
foreach ($table in $tables) {
    $output += "DROP TABLE IF EXISTS $table CASCADE;`n"
}

# Save result
[System.IO.File]::WriteAllText($outputFile, $output, [System.Text.Encoding]::UTF8)

Write-Host "`nFile generated: $outputFile" -ForegroundColor Green
Write-Host "DROP command count: $($tables.Count)" -ForegroundColor Cyan
