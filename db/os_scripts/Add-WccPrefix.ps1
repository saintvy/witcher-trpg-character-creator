# Скрипт для добавления "wcc_" после первого подчеркивания в именах файлов
# Формат: 068_witcher_events_benefit.sql -> 068_wcc_witcher_events_benefit.sql

param(
    [Parameter(Mandatory=$false)]
    [string]$Path = ""
)

# Устанавливаем путь по умолчанию
if ([string]::IsNullOrEmpty($Path)) {
    $Path = Join-Path $PSScriptRoot "..\sql"
}

# Нормализуем путь
$Path = [System.IO.Path]::GetFullPath($Path)

Write-Host "Add-WccPrefix.ps1" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host "Path: $Path" -ForegroundColor Yellow
Write-Host ""

# Проверка существования папки
if (-not (Test-Path $Path)) {
    Write-Host "Error: Path '$Path' does not exist." -ForegroundColor Red
    exit 1
}

$files = Get-ChildItem -Path $Path -File -Filter "*.sql"

$filesToRename = @()
foreach ($file in $files) {
    # Пропускаем файлы, которые уже содержат wcc_ после первого подчеркивания
    if ($file.Name -match '^(\d{3})_wcc_') {
        Write-Host "Skipping (already has wcc_): $($file.Name)" -ForegroundColor Gray
        continue
    }
    
    # Проверяем, начинается ли файл с трех цифр и подчеркивания
    if ($file.Name -match '^(\d{3})_(.+)$') {
        $prefix = $matches[1]
        $rest = $matches[2]
        $newName = "${prefix}_wcc_$rest"
        
        $filesToRename += [PSCustomObject]@{
            File = $file
            OldName = $file.Name
            NewName = $newName
        }
    }
}

if ($filesToRename.Count -eq 0) {
    Write-Host "No files to rename." -ForegroundColor Yellow
    exit 0
}

Write-Host "Files to rename:" -ForegroundColor Green
foreach ($item in $filesToRename | Sort-Object -Property OldName) {
    Write-Host "  $($item.OldName) -> $($item.NewName)" -ForegroundColor Cyan
}

Write-Host ""
$confirmation = Read-Host "Proceed with renaming? (y/N)"
if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

# Выполняем переименование
$renamedCount = 0
foreach ($item in $filesToRename) {
    $newPath = Join-Path $Path $item.NewName
    
    # Проверяем, не существует ли уже файл с таким именем
    if (Test-Path $newPath) {
        Write-Host "Warning: File '$($item.NewName)' already exists. Skipping '$($item.OldName)'." -ForegroundColor Red
        continue
    }
    
    try {
        Rename-Item -Path $item.File.FullName -NewName $item.NewName -ErrorAction Stop
        Write-Host "Renamed: $($item.OldName) -> $($item.NewName)" -ForegroundColor Green
        $renamedCount++
    } catch {
        Write-Host "Error renaming '$($item.OldName)': $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Renaming complete. Renamed $renamedCount file(s)." -ForegroundColor Green

