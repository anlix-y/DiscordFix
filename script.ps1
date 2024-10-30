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

# Вызов функции
FindAndRunBatFiles
