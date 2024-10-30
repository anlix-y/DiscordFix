$ErrorActionPreference = "Stop"
# Enable TLSv1.2 for compatibility with older clients for current session
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$destinationFolder = "$env:APPDATA\DiscordFix"
if (-not (Test-Path -Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder
}

# Download all files from https://github.com/Flowseal/zapret-discord-youtube
$repoURL = 'https://api.github.com/repos/Flowseal/zapret-discord-youtube/contents/'
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
    }
}

# Download script.ps1 from https://github.com/anlix-y/DiscordFix
$scriptURL = 'https://raw.githubusercontent.com/anlix-y/DiscordFix/main/script.ps1'
try {
    $response = Invoke-WebRequest -Uri $scriptURL -UseBasicParsing
    $scriptPath = Join-Path -Path $destinationFolder -ChildPath "script.ps1"
    Set-Content -Path $scriptPath -Value $response.Content
}
catch {
    Write-Warning "Failed to retrieve $scriptURL, skipping..."
}

# Run script.ps1 if it exists
if (Test-Path -Path $scriptPath) {
    Start-Process powershell.exe -ArgumentList "-File `"$scriptPath`"" -Wait
} else {
    Write-Warning "script.ps1 not found, aborting!"
}
