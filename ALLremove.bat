@echo off
chcp 65001 >nul
:: 65001 - UTF-8

:: Завершение процесса winws.exe с помощью PowerShell
powershell -Command "Get-Process -Name winws -ErrorAction SilentlyContinue | ForEach-Object { $_.Kill() }"

echo Процесс winws.exe завершен.
pause
