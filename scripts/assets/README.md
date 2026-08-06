# Asset sync scripts

## Manual sync

```bash
./scripts/assets/sync_from_bucket.sh     # bucket → local
./scripts/assets/sync_to_bucket.sh       # local → bucket
```

## Automatic sync

См. подробную инструкцию: `docs/ASSETS_AUTO_SYNC.md`

### Быстрый старт (macOS)

1. Установите rclone и fswatch:
   ```bash
   brew install rclone fswatch
   ```
2. Настройте remote `neon` (`rclone config`)
3. Запустите вотчер:
   ```bash
   chmod +x scripts/assets/watch_and_sync.sh
   ./scripts/assets/watch_and_sync.sh
   ```

### Периодическая синхронизация (macOS launchd)

1. Отредактируйте `scripts/assets/com.naeon.assets.sync.plist` (путь к проекту)
2. Скопируйте в `~/Library/LaunchAgents/`
3. Загрузите:
   ```bash
   launchctl load ~/Library/LaunchAgents/com.naeon.assets.sync.plist
   ```

### Windows

Используйте `windows_auto_sync.ps1` + Task Scheduler.
