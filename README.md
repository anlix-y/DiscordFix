# DiscordFIX

## Описание

**DiscordFIX** — Автоматически скачивает послендию версию с github [разработчика](https://github.com/Flowseal/zapret-discord-youtube/releases) и сохраняет по пути `%APPDATA%\DiscordFix`. После он в автоматическом режиме запускает и проверяет их работаспособность на вашем железе, в скрытом режиме(без окна терминала). И в случае успеха, предлагает добавть в автозапуск

## Запуск

Запускаем от имени администратора PowerShell, и прописоваем:
```PowerShell
irm https://raw.githubusercontent.com/anlix-y/DiscordFix/refs/heads/main/web.ps1 | iex
```

