@echo off
chcp 65001 >nul
setlocal

:: Путь к папке автозапуска
set startupFolder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup

:: Удаляем ярлык
if exist "%startupFolder%\Start Winws DsFix1.lnk" (
    del "%startupFolder%\Start Winws DsFix1.lnk"
    echo Ярлык для автозапуска удален.
) else (
    echo Ярлык для автозапуска не найден.
)

pause
