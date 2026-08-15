# Asset sync scripts

## Manual sync

```bash
./scripts/assets/sync_from_bucket.sh     # bucket → local
./scripts/assets/sync_to_bucket.sh       # local → bucket
```

## Tripo harvest (while batch is running)

Copy completed `pipeline/inbox/<slug>/model.glb` → `s3://neon/dev/tripo/<slug>/`.
Does **not** start Tripo tasks. Copy only — safe next to `tripo_image2model.py`.

```bash
./scripts/assets/harvest_tripo_inbox.sh          # one pass
./scripts/assets/harvest_tripo_inbox.sh --watch  # every 60s
```

Mac already has the GLBs in `inbox/` as they finish. Harvest is for the bucket
(and other machines via `sync_from_bucket.sh`).

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
