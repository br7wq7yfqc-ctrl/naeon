# Автоматическая синхронизация ассетов NAEON

Цель: локальная папка `assets/` автоматически синхронизируется с бакетом `neon` (Yandex Object Storage).

## Рекомендуемый инструмент: rclone

`rclone` — лучший выбор для S3-совместимых хранилищ. Работает одинаково на macOS и Windows.

### 1. Установка rclone

**macOS:**
```bash
brew install rclone
```

**Windows:**
Скачать с https://rclone.org/downloads/ или:
```powershell
winget install Rclone.Rclone
```

### 2. Настройка remote `neon`

```bash
rclone config
```

Выберите `New remote` → имя `neon` → тип `s3` → provider `Other`.

Параметры:
```
access_key_id     = <YC_STORAGE_ACCESS_KEY>
secret_access_key = <YC_STORAGE_SECRET_KEY>
endpoint          = storage.yandexcloud.net
region            = ru-central1
location_constraint =
acl               = private
```

Или создайте файл `~/.config/rclone/rclone.conf` вручную (не коммитьте!):

```ini
[neon]
type = s3
provider = Other
env_auth = false
access_key_id = YCAJ...
secret_access_key = YCPW...
endpoint = storage.yandexcloud.net
region = ru-central1
```

### 3. Варианты автоматической синхронизации

#### Вариант A — Периодический sync (самый простой и надёжный)

Синхронизация каждые N минут в одну сторону или двусторонне.

**macOS (launchd):** см. файл `scripts/assets/com.naeon.assets.sync.plist`

**Windows (Task Scheduler):** см. `scripts/assets/windows_auto_sync.ps1`

**Linux/cron:**
```bash
*/15 * * * * rclone sync neon:dev /path/to/naeon/assets --fast-list
```

#### Вариант B — Синхронизация при изменении файлов (watch)

Использует `fswatch` (macOS) или `rclone` + скрипт.

```bash
# macOS
brew install fswatch
./scripts/assets/watch_and_sync.sh
```

#### Вариант C — rclone mount (как локальный диск)

```bash
mkdir -p ~/mnt/naeon-assets
rclone mount neon:dev ~/mnt/naeon-assets --vfs-cache-mode full --daemon
```

После этого можно работать с ассетами как с обычной папкой. Изменения будут видны в бакете (с задержкой кэша).

> Для Godot удобнее иметь обычную локальную папку `assets/`, поэтому варианты A и B предпочтительнее.

### 4. Полезные команды rclone

```bash
# Скачать из бакета → локально (dev)
rclone sync neon:dev ./assets --progress

# Загрузить локально → бакет
rclone sync ./assets neon:dev --progress

# Двусторонняя синхронизация (осторожно!)
rclone bisync neon:dev ./assets --resync   # первый раз
rclone bisync neon:dev ./assets            # потом

# Посмотреть разницу
rclone check neon:dev ./assets
```

### 5. Рекомендуемый режим для команды

- Основной источник правды — бакет `neon/dev/`
- Разработчики периодически делают `rclone sync neon:dev ./assets`
- При добавлении новых ассетов — `rclone sync ./assets neon:dev`
- Для автоматизации — launchd / Task Scheduler каждые 10–30 минут + ручной запуск при необходимости

### 6. Фильтры (чтобы не синхронизировать мусор)

Создайте файл `.rcloneignore` или используйте флаги:

```bash
rclone sync neon:dev ./assets \
  --exclude ".DS_Store" \
  --exclude "*.tmp" \
  --exclude "*.blend1" \
  --exclude "Thumbs.db"
```

---

После настройки запустите первую синхронизацию вручную и проверьте, что файлы появляются в `./assets`.
