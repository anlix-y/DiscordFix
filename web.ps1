$OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorActionPreference = "Stop"
# Enable TLSv1.2 for compatibility with older clients for current session
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "You do not have sufficient privileges. Please run the script as an administrator."
    exit
}

$destinationFolder = "$env:APPDATA\DiscordFix"
if (-not (Test-Path -Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder
}

function Check-DiscordStatus {
    try {
        $response = Invoke-RestMethod -Uri 'https://discord.com/api/v9/gateway' -TimeoutSec 5
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
        $content = Get-Content -Path $file.FullName

        # Проверяем, содержит ли файл слова "general" или "discord"
        if (($content -match 'general' -or $content -match 'discord') -and -not ($content -match 'service')) {
            Write-Host "Running $($file.FullName)"

            $batFilePath = $file.FullName
            $workingDirectory = Split-Path -Path $batFilePath
            $taskName = "TempFIX_" + [guid]::NewGuid().ToString()
            schtasks /create /tn $taskName /tr "`"$batFilePath`"" /sc once /st 00:00 /rl highest /f /it /ru System
            schtasks /run /tn $taskName
            Start-Sleep -Seconds 2
            schtasks /delete /tn $taskName /f

            # Start-Process -FilePath $file.FullName -WindowStyle Hidden -NoNewWindow
            Start-Sleep -Seconds 3
            if (Check-DiscordStatus) {
                Clear-Host
                
                Write-Host "1 - добавить в автозагрузку"
                Write-Host "2 - не добовлять в автозагрузки"

                $choice = Read-Host "Введите номер действия"

                switch ($choice) {
                    1 {
                        Clear-Host
                        $batFilePath = $file.FullName
                        $workingDirectory = Split-Path -Path $batFilePath
                        $taskName = "DiscordFix"
                        schtasks /delete /tn $taskName /f 2>$null
                        schtasks /create /tn $taskName /tr "`"$batFilePath`"" /sc onlogon /rl highest /f /it /ru System
                        Write-Host "Задача '$taskName' успешно добавлена в автозапуск."
                        Read-Host "Нажмите enter что бы продолжить..."
                        Clear-Host
                        Show-Menu-start
                    }
                    2 {
                        Clear-Host
                        Read-Host "Нажмите enter что бы продолжить..."
                        Clear-Host
                        Show-Menu-start
                    }
                    default {
                        Read-Host "Неверный выбор."
                    }
                }
            }
            Stop-WinwsProcess
        }
    }
    Write-Host "Discord is not working correctly."
}

function Show-Menu-start {
    Clear-Host
    Write-Host "╔═══╗                   ╔╗ ╔═══╗      "
    Write-Host "╚╗╔╗║                   ║║ ║╔══╝      "
    Write-Host " ║║║║╔╗╔══╗╔══╗╔══╗╔═╗╔═╝║ ║╚══╗╔╗╔╗╔╗"
    Write-Host " ║║║║╠╣║══╣║╔═╝║╔╗║║╔╝║╔╗║ ║╔══╝╠╣╚╬╬╝"
    Write-Host "╔╝╚╝║║║╠══║║╚═╗║╚╝║║║ ║╚╝║╔╝╚╗  ║║╔╬╬╗"
    Write-Host "╚═══╝╚╝╚══╝╚══╝╚══╝╚╝ ╚══╝╚══╝  ╚╝╚╝╚╝"
    Write-Host 
    Write-Host "Выберите действие:"
    Write-Host "1 - Установить\обновить"
    Write-Host "2 - Открыть меню работы с файлами"
    Write-Host "3 - Удалить"
    Write-Host "0 - Выход"

    $choice = Read-Host "Введите номер действия"

    switch ($choice) {
        1 {
            Clear-Host
            Stop-WinwsProcess
            Start-install
            Show-Menu-install
        }
        2 {
            Show-Menu-install
        }
        3 {
            Clear-Host
            Remove-DiscordFixDirectory
        }
        0 {
            exit
        }
        default {
            Read-Host "Неверный выбор."
            Clear-Host
            Show-Menu-start -ClearScreen $false
        }
    }
}

function Show-Menu-install {
    Clear-Host
    
    Write-Host "Выберите действие:"
    Write-Host "1 - Авто настройка"
    Write-Host "2 - Ручной выбор"
    Write-Host "3 - Удалить из автозапуска"
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
            Read-Host "Нажмите Enter что бы продолжить..."
        }
        0 {
            exit
        }
        default {
            Write-Host "Неверный выбор. Пожалуйста, попробуйте снова."
            Show-Menu-install -ClearScreen $false
        }
    }
}


#! Функции работы с удалением

function Remove-DiscordFixDirectory {
    # Указываем путь к директории DiscordFix
    $directoryPath = "$env:APPDATA\DiscordFix"

    # Проверяем, существует ли директория
    if (Test-Path -Path $directoryPath) {
        try {
            # Удаляем директорию и все её содержимое
            Remove-Item -Path $directoryPath -Recurse -Force
            Write-Host "Успешно!!!"
        } catch {
            Write-Host "Ошибка удаления!"
        }
    } else {
        Write-Host "Папки не существует..."
    }
}

function Manual-Selection {
    Write-Host "В разработке..."
    Show-Menu-start
}

function Remove-StartupShortcut {
    $taskName = "DiscordFix"
    $taskExists = schtasks /query /tn $taskName 2>$null

    if ($taskExists) {
        schtasks /delete /tn $taskName /f
        Write-Host "Задача '$taskName' успешно удалена из автозапуска."
    } else {
        Write-Host "Задача '$taskName' не найдена. Нечего удалять."
    }
}


function Stop-WinwsProcess {
    Get-Process -Name winws -ErrorAction SilentlyContinue | ForEach-Object { $_.Kill() }
    Write-Host "Процесс winws.exe завершен."
}


#! Функции работы с загрузкой

function Download-File {
    param (
        [string]$Url,
        [string]$File
    )
    Write-Host "Downloading $Url to $File"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $Url -OutFile $File
}

function Remove-Directory {
    param (
        [string]$Path
    )
    if ([System.IO.Directory]::Exists($Path)) {
        Write-Host "Deleting $Path"
        [System.IO.Directory]::Delete($Path, $true)
    }
}

function Unzip-File {
    param(
        [string]$File,
        [string]$Destination = (Get-Location).Path
    )

    $FilePath = Resolve-Path $File
    $DestinationPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination)

    If ($PSVersionTable.PSVersion.Major -ge 3) {
        [System.IO.Compression.ZipFile]::ExtractToDirectory("$FilePath", "$DestinationPath")
    }
    else {
        throw "Unzip-File is not supported on PowerShell versions less than 3.0"
    }
}

function Move-DirectoryContent {
    param (
        [string]$Source,
        [string]$Destination
    )

    $SourcePath = Resolve-Path $Source
    $DestinationPath = Resolve-Path $Destination

    Write-Output "Moving content of $SourcePath to $DestinationPath"
    Get-ChildItem -Path $SourcePath -Recurse | Move-Item -Destination $DestinationPath
}

function Start-install {
    $UserName = "Flowseal"
    $RepoName = "zapret-discord-youtube"
    $Branch = "main"

    $DotfileTmpDir = $env:TEMP
    $SourceFile = Join-Path $DotfileTmpDir "zapret-discord-youtube.zip"
    $DestPath = "$env:APPDATA\DiscordFix"
    # Скачивание репозитория
    Download-File "https://github.com/$UserName/$RepoName/archive/refs/heads/$Branch.zip" $SourceFile

    # Удаление существующей папки назначения
    Remove-Directory $DestPath

    # Распаковка архива
    Unzip-File $SourceFile $DestPath

    # Путь к распакованной папке
    $ZipOutputDir = Join-Path $DestPath "$RepoName-$Branch"

    # Перемещение содержимого распакованной папки в папку назначения
    Move-DirectoryContent $ZipOutputDir $DestPath

    # Удаление временной папки
    Remove-Directory $ZipOutputDir
}


Show-Menu-start