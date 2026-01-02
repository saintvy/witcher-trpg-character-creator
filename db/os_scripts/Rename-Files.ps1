param(
    [Parameter(Mandatory=$false)]
    [int]$FromIndex = 1,
    
    [Parameter(Mandatory=$false)]
    [int]$ToIndex = -1,  # -1 означает "до последнего"
    
    [Parameter(Mandatory=$false)]
    [int]$Shift = 0,  # По умолчанию 0, вычисляется из IndexTarget если задан
    
    [Parameter(Mandatory=$false)]
    [int]$IndexTarget = -1,  # -1 означает "не задан", если задан - вычисляет Shift автоматически
    
    [Parameter(Mandatory=$false)]
    [int]$Digits = 3,
    
    [Parameter(Mandatory=$false)]
    [string]$Path = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('Y', 'N')]
    [string]$AddEcho = 'Y'
)

# Устанавливаем путь по умолчанию
if ([string]::IsNullOrEmpty($Path)) {
    $Path = Join-Path $PSScriptRoot "..\sql"
}

# Нормализуем путь
$Path = [System.IO.Path]::GetFullPath($Path)

# Функция для извлечения числовой части из имени файла
function Get-NumberPrefix {
    param([string]$FileName)
    
    if ($FileName -match '^(\d+)') {
        return [int]$matches[1]
    }
    return $null
}

# Функция для получения остальной части имени файла (после числового префикса)
function Get-RemainingName {
    param([string]$FileName)
    
    # Извлекаем все после числового префикса (включая буквы после цифр, если есть)
    if ($FileName -match '^\d+(.*)$') {
        return $matches[1]
    }
    return $null
}

# Функция для форматирования числа с ведущими нулями
function Format-NumberWithZeros {
    param(
        [int]$Number,
        [int]$Digits
    )
    
    return $Number.ToString().PadLeft($Digits, '0')
}

Write-Host "Rename-Files.ps1" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan
Write-Host "From Index: $FromIndex" -ForegroundColor Yellow

# Проверка существования папки
if (-not (Test-Path $Path)) {
    Write-Host "Error: Path '$Path' does not exist." -ForegroundColor Red
    exit 1
}

# Получаем все файлы в папке
$files = Get-ChildItem -Path $Path -File

# Если ToIndex не указан, находим максимальный номер среди всех файлов, начинающихся с цифр
if ($ToIndex -eq -1) {
    $maxNumber = 0
    foreach ($file in $files) {
        $number = Get-NumberPrefix -FileName $file.Name
        if ($null -ne $number -and $number -gt $maxNumber) {
            $maxNumber = $number
        }
    }
    $ToIndex = $maxNumber
    if ($ToIndex -eq 0) {
        Write-Host "No files with numeric prefixes found." -ForegroundColor Yellow
        exit 0
    }
    Write-Host "To Index: $ToIndex (auto - to last file)" -ForegroundColor Yellow
} else {
    Write-Host "To Index: $ToIndex" -ForegroundColor Yellow
}

# Если задан IndexTarget, вычисляем Shift автоматически (приоритет у IndexTarget)
if ($IndexTarget -ne -1) {
    $Shift = $IndexTarget - $FromIndex
    Write-Host "Index Target: $IndexTarget" -ForegroundColor Yellow
    Write-Host "Shift: $Shift (computed from IndexTarget)" -ForegroundColor Yellow
} else {
    if ($Shift -eq 0) {
        Write-Host "Error: Either Shift or IndexTarget must be specified." -ForegroundColor Red
        exit 1
    }
    Write-Host "Shift: $Shift" -ForegroundColor Yellow
}

Write-Host "Digits: $Digits" -ForegroundColor Yellow
Write-Host "AddEcho: $AddEcho" -ForegroundColor Yellow
Write-Host "Path: $Path" -ForegroundColor Yellow
Write-Host ""

# Фильтруем файлы, которые начинаются с цифр и попадают в диапазон
# Учитываем "дырки" в нумерации - обрабатываем все файлы в диапазоне
$filesToRename = @()
foreach ($file in $files) {
    $number = Get-NumberPrefix -FileName $file.Name
    if ($null -ne $number -and $number -ge $FromIndex -and $number -le $ToIndex) {
        $filesToRename += @{
            File = $file
            OldNumber = $number
            RemainingName = Get-RemainingName -FileName $file.Name
        }
    }
}

if ($filesToRename.Count -eq 0) {
    Write-Host "No files found in range [$FromIndex..$ToIndex]." -ForegroundColor Yellow
    exit 0
}

# Вычисляем новые имена для всех файлов
$filesWithNewNames = @()
foreach ($item in $filesToRename) {
    $newNumber = $item.OldNumber + $Shift
    $oldNumberStr = $item.OldNumber.ToString()
    $newNumberFormatted = if ($oldNumberStr.Length -gt $Digits) {
        Format-NumberWithZeros -Number $newNumber -Digits $oldNumberStr.Length
    } else {
        Format-NumberWithZeros -Number $newNumber -Digits $Digits
    }
    $newName = $newNumberFormatted + $item.RemainingName
    
    $filesWithNewNames += [PSCustomObject]@{
        File = $item.File
        OldNumber = [int]$item.OldNumber
        RemainingName = $item.RemainingName
        NewName = $newName
        NewNumber = [int]$newNumber
        NewNumberFormatted = $newNumberFormatted
    }
}

# Сортируем по числовому значению нового индекса для вывода (явно указываем числовую сортировку)
$filesForDisplay = $filesWithNewNames | Sort-Object -Property @{Expression={[int]$_.NewNumber}}

Write-Host "Files to rename:" -ForegroundColor Green
foreach ($item in $filesForDisplay) {
    Write-Host "  $($item.File.Name) -> $($item.NewName)" -ForegroundColor Cyan
}

# Сортируем по номеру в обратном порядке для переименования, чтобы избежать конфликтов
if ($Shift -gt 0) {
    # При сдвиге вверх, обрабатываем от большего к меньшему
    $filesToRename = $filesWithNewNames | Sort-Object -Property OldNumber -Descending
} else {
    # При сдвиге вниз, обрабатываем от меньшего к большему
    $filesToRename = $filesWithNewNames | Sort-Object -Property OldNumber
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
    # Используем уже вычисленные значения
    $newNumber = $item.NewNumber
    $newName = $item.NewName
    
    # Проверяем, не выходит ли новый номер за допустимые пределы
    if ($newNumber -lt 0) {
        Write-Host "Warning: New number for '$($item.File.Name)' would be negative ($newNumber). Skipping." -ForegroundColor Red
        continue
    }
    
    $newPath = Join-Path $Path $newName
    
    # Проверяем, не существует ли уже файл с таким именем
    if (Test-Path $newPath) {
        Write-Host "Warning: File '$newName' already exists. Skipping '$($item.File.Name)'." -ForegroundColor Red
        continue
    }
    
    try {
        Rename-Item -Path $item.File.FullName -NewName $newName -ErrorAction Stop
        Write-Host "Renamed: $($item.File.Name) -> $newName" -ForegroundColor Green
        $renamedCount++
        
        # Обновляем \echo в файле, если AddEcho = 'Y'
        if ($AddEcho -eq 'Y') {
            $newFilePath = Join-Path $Path $newName
            try {
                # Читаем файл как байты, чтобы сохранить оригинальную кодировку
                $bytes = [System.IO.File]::ReadAllBytes($newFilePath)
                
                # Проверяем наличие UTF-8 BOM (EF BB BF)
                $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
                $contentBytes = if ($hasBom) { $bytes[3..($bytes.Length-1)] } else { $bytes }
                
                # Декодируем как UTF-8 (предполагаем, что файлы в UTF-8)
                $utf8Encoding = New-Object System.Text.UTF8Encoding $false
                $content = $utf8Encoding.GetString($contentBytes)
                
                # Разбиваем на строки, сохраняя информацию о переводе строк
                $lineEnding = if ($content -match "`r`n") { "`r`n" } elseif ($content -match "`n") { "`n" } else { "`n" }
                $lines = $content -split "`r?`n"
                
                if ($lines.Count -gt 0) {
                    $firstLine = $lines[0]
                    $firstLineTrimmed = $firstLine.TrimStart()
                    
                    # Проверяем, начинается ли первая строка с \echo (с возможными пробелами)
                    if ($firstLineTrimmed -match '^\\echo') {
                        # Заменяем первую строку на \echo с новым именем файла в кавычках
                        # Сохраняем исходные пробелы в начале строки
                        $leadingSpaces = $firstLine -replace '^(\s*).*', '$1'
                        $newFirstLine = $leadingSpaces + "\echo '$newName'"
                        $lines[0] = $newFirstLine
                    } else {
                        # Добавляем \echo в начало
                        $lines = @("\echo '$newName'") + $lines
                    }
                    
                    # Собираем обратно содержимое с сохранением оригинального окончания строк
                    $newContent = $lines -join $lineEnding
                    # Сохраняем оригинальное окончание файла (если было)
                    if ($content.EndsWith($lineEnding)) {
                        $newContent += $lineEnding
                    } elseif ($content.EndsWith("`n")) {
                        $newContent += "`n"
                    }
                    
                    # Сохраняем в UTF-8 с тем же BOM, что был в оригинале
                    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                    $newBytes = $utf8NoBom.GetBytes($newContent)
                    
                    # Добавляем BOM, если он был в оригинальном файле
                    if ($hasBom) {
                        $bomBytes = [byte[]](0xEF, 0xBB, 0xBF)
                        $newBytes = $bomBytes + $newBytes
                    }
                    
                    [System.IO.File]::WriteAllBytes($newFilePath, $newBytes)
                    
                    Write-Host "  Updated \echo in file" -ForegroundColor Gray
                }
            } catch {
                Write-Host "  Warning: Could not update \echo in '$newName': $_" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "Error renaming '$($item.File.Name)': $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Renaming complete. Renamed $renamedCount file(s)." -ForegroundColor Green

