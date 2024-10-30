@echo off
chcp 65001 >nul
setlocal

:: Путь к вашему батч-файлу
set scriptPath=%APPDATA%\DiscordFix\DsFix1.bat

:: Путь к папке автозапуска
set startupFolder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup

:: Создаем ярлык
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%startupFolder%\Start Winws DsFix1.lnk'); $s.TargetPath = '%scriptPath%'; $s.Save()"

echo Ярлык для автозапуска создан.
pause
