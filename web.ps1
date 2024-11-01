$ErrorActionPreference = "Stop"
# Enable TLSv1.2 for compatibility with older clients for current session
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$destinationFolder = "$env:APPDATA\DiscordFix"
if (-not (Test-Path -Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder
}

function Check-DiscordStatus {
    try {
        $response = Invoke-RestMethod -Uri 'https://discord.com/api/v9/gateway' -TimeoutSec 10
        if ($response) {
            Write-Host "Discord API is accessible."
            return $true
        }
    } catch {
        Write-Host "Error accessing Discord API: $_"
        return $false
    }
    
    Write-Host "Discord API returned status code: $($_.Exception.Response.StatusCode)"
    return $false
}

function FindAndRunBatFiles {
    # Указываем путь к директории DiscordFix
    $directoryPath = "$env:APPDATA\DiscordFix"

    # Проверяем, существует ли директория
    if (-Not (Test-Path -Path $directoryPath)) {
        Write-Host "Directory $directoryPath does not exist."
        return
    }

    Write-Host "Searching for .bat files in ${directoryPath}"

    # Получаем все файлы в указанной директории (без поддиректорий)
    $allFiles = Get-ChildItem -Path $directoryPath -File

    # Проверяем, найдены ли файлы
    if ($allFiles.Count -eq 0) {
        Write-Host "No files found in ${directoryPath}."
        return
    }

    # Фильтруем .bat файлы
    $batFiles = $allFiles | Where-Object { $_.Extension -eq '.bat' }

    # Проверяем, найдены ли .bat файлы
    if ($batFiles.Count -eq 0) {
        Write-Host "No .bat files found in ${directoryPath}."
        return
    }

    foreach ($file in $batFiles) {

        # Читаем содержимое файла
        $content = Get-Content -Path $file.FullName

        # Проверяем, содержит ли файл слова "general" или "discord"
        if (($content -match 'general' -or $content -match 'discord') -and -not ($content -match 'service')) {
            "Running $($file.FullName)"

            if (Check-DiscordStatus)
            {
                Write-Host "Discord is working correctly."
            }
        }
    }
    Write-Host "Discord is not working correctly."
}

function Show-Menu {
    param (
        [switch]$ClearScreen = $true
    )

    if ($ClearScreen) {
        Clear-Host
    }

    Write-Host "Выберите действие:"
    Write-Host "1 - Авто настройка"
    Write-Host "2 - Ручной выбор"
    Write-Host "3 - Удалить из авто запуска"
    Write-Host "4 - Снаять задачу"
    Write-Host "0 - Выход"

    $choice = Read-Host "Введите номер действия"

    switch ($choice) {
        1 {
            Clear-Host
            FindAndRunBatFiles
        }
        2 {
            Clear-Host
            Manual-Selection
        }
        3 {
            Clear-Host
            Remove-StartupShortcut
        }
        4 {
            Clear-Host
            Stop-WinwsProcess
        }
        0 {
            exit
        }
        default {
            Write-Host "Неверный выбор. Пожалуйста, попробуйте снова."
            Show-Menu -ClearScreen $false
        }
    }
}

function Manual-Selection {
    Write-Host "В разработке..."
    # Здесь ваш код для ручного выбора
}

function Remove-StartupShortcut {
    param (
        [string]$shortcutName = "Start Winws DsFix1.lnk"
    )

    # Путь к папке автозапуска
    $startupFolder = [System.IO.Path]::Combine($env:APPDATA, "Microsoft\Windows\Start Menu\Programs\Startup")

    # Проверяем существование ярлыка
    $shortcutPath = [System.IO.Path]::Combine($startupFolder, $shortcutName)
    if (Test-Path -Path $shortcutPath) {
        Remove-Item -Path $shortcutPath
        Write-Host "Ярлык для автозапуска удален."
    } else {
        Write-Host "Ярлык для автозапуска не найден."
    }
    
    Stop-WinwsProcess
    # Пауза перед закрытием окна
    Read-Host "Нажмите Enter для выхода..."
}


function Stop-WinwsProcess {
    # Завершение процесса winws.exe
    Get-Process -Name winws -ErrorAction SilentlyContinue | ForEach-Object { $_.Kill() }

    Write-Host "Процесс winws.exe завершен."

    # Пауза перед закрытием окна
    Read-Host "Нажмите Enter для выхода..."
}

# Function to download files and directories recursively
function Download-Repository {
    param (
        [string]$repoURL,
        [string]$destinationFolder
    )

    $files = Invoke-RestMethod -Uri $repoURL

    foreach ($file in $files) {
        if ($file.type -eq 'file') {
            $downloadURL = $file.download_url
            $fileName = $file.name
            $filePath = Join-Path -Path $destinationFolder -ChildPath $fileName
            try {
                $response = Invoke-WebRequest -Uri $downloadURL -UseBasicParsing
                Set-Content -Path $filePath -Value $response.Content
            }
            catch {
                Write-Warning "Failed to retrieve $downloadURL, skipping..."
            }
        } elseif ($file.type -eq 'dir') {
            $dirName = $file.name
            $dirPath = Join-Path -Path $destinationFolder -ChildPath $dirName
            if (-not (Test-Path -Path $dirPath)) {
                New-Item -ItemType Directory -Path $dirPath
            }
            Download-Repository -repoURL $file.url -destinationFolder $dirPath
        }
    }
}

# Download all files and directories from https://github.com/Flowseal/zapret-discord-youtube
$repoURL = 'https://api.github.com/repos/Flowseal/zapret-discord-youtube/contents/'
Download-Repository -repoURL $repoURL -destinationFolder $destinationFolder

Show-Menu

