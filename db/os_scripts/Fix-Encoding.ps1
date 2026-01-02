# Скрипт для исправления кодировки SQL файлов
# Исправляет проблему двойной кодировки UTF-8 (крякозябры)

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

Write-Host "Fix-Encoding.ps1" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan
Write-Host "Path: $Path" -ForegroundColor Yellow
Write-Host ""

# Проверка существования папки
if (-not (Test-Path $Path)) {
    Write-Host "Error: Path '$Path' does not exist." -ForegroundColor Red
    exit 1
}

# Получаем все SQL файлы
$files = Get-ChildItem -Path $Path -File -Filter "*_wcc_*.sql"

if ($files.Count -eq 0) {
    Write-Host "No SQL files found matching pattern '*_wcc_*.sql'." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($files.Count) file(s) to check." -ForegroundColor Green
Write-Host ""

$fixedCount = 0
$skippedCount = 0
$errorCount = 0

foreach ($file in $files) {
    try {
        # Читаем файл как байты
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        
        # Проверяем байты напрямую - ищем характерные последовательности для двойной кодировки
        # 0xC3 0x82 = Ã, 0xC3 0xA2 = â, 0xE2 0x80 = начало проблемных последовательностей
        $hasCorruption = $false
        for ($i = 0; $i -lt ($bytes.Length - 1); $i++) {
            if (($bytes[$i] -eq 0xC3 -and ($bytes[$i+1] -eq 0x82 -or $bytes[$i+1] -eq 0xA2)) -or
                ($bytes[$i] -eq 0xE2 -and $i+2 -lt $bytes.Length -and $bytes[$i+1] -eq 0x80)) {
                $hasCorruption = $true
                break
            }
        }
        
        if ($hasCorruption) {
            Write-Host "Fixing: $($file.Name)" -ForegroundColor Yellow
            
            # Пробуем исправить: декодируем как Windows-1251, затем перекодируем в UTF-8
            try {
                $encoding1251 = [System.Text.Encoding]::GetEncoding(1251)
                $textFixed = $encoding1251.GetString($bytes)
                
                # Проверяем, что исправление дало результат (должны быть русские буквы)
                # Используем Unicode диапазон для кириллицы
                $hasRussian = $textFixed -match '[\u0400-\u04FF]'
                if ($hasRussian) {
                    # Сохраняем в UTF-8 без BOM
                    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                    [System.IO.File]::WriteAllText($file.FullName, $textFixed, $utf8NoBom)
                    
                    Write-Host "  Fixed: $($file.Name)" -ForegroundColor Green
                    $fixedCount++
                } else {
                    Write-Host "  Warning: Fix attempt did not produce Russian text. Skipping." -ForegroundColor Yellow
                    $skippedCount++
                }
            } catch {
                Write-Host "  Warning: Could not fix $($file.Name): $_" -ForegroundColor Red
                $errorCount++
            }
        } else {
            # Проверяем, есть ли русские буквы - читаем как UTF-8
            $text = [System.Text.Encoding]::UTF8.GetString($bytes)
            $hasRussian = $text -match '[\u0400-\u04FF]'
            if ($hasRussian) {
                Write-Host "OK: $($file.Name)" -ForegroundColor Gray
                $skippedCount++
            } else {
                # Файл без русских букв - пропускаем
                Write-Host "Skipping (no Russian text): $($file.Name)" -ForegroundColor Gray
                $skippedCount++
            }
        }
    } catch {
        Write-Host "Error processing $($file.Name): $_" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Fixed: $fixedCount file(s)" -ForegroundColor Green
Write-Host "  Skipped: $skippedCount file(s)" -ForegroundColor Yellow
Write-Host "  Errors: $errorCount file(s)" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })

