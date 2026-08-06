# Автоматическая синхронизация assets ↔ Yandex Object Storage (neon)

## Рекомендуемый инструмент: rclone

### 1. Установка

**macOS:**
```bash
brew install rclone
```

**Windows:**
Скачайте с https://rclone.org/downloads/ или через winget:
```powershell
winget install Rclone.Rclone
```

### 2. Настройка remote

```bash
rclone config
```

Создайте remote с именем `neon`:

```
n) New remote
name> neon
Storage> s3
provider> Other
env_auth> false
access_key_id> <ваш Key ID>
secret_access_key> <ваш Secret>
region> ru-central1
endpoint> https://storage.yandexcloud.net
```

(Остальные параметры можно оставить по умолчанию.)

### 3. Ручная проверка

```bash
rclone lsd neon:
rclone ls neon:dev
```

### 4. Варианты автоматической синхронизации

#### Вариант A — Периодический bisync (рекомендуется)

Двусторонняя синхронизация каждые N минут.

```bash
# Первый запуск (создаёт baseline)
rclone bisync ./assets neon:dev --create-empty-src-dirs --resync

# Обычный запуск
rclone bisync ./assets neon:dev --create-empty-src-dirs
```

#### Вариант B — Односторонняя периодическая синхронизация

```bash
# Скачать изменения из бакета
rclone sync neon:dev ./assets --create-empty-src-dirs

# Загрузить локальные изменения в бакет
rclone sync ./assets neon:dev --create-empty-src-dirs
```

#### Вариант C — rclone mount (бакет как диск)

```bash
# macOS / Linux
rclone mount neon:dev ./assets --vfs-cache-mode full --daemon

# Windows (нужен WinFsp)
rclone mount neon:dev X: --vfs-cache-mode full
```

### 5. Автозапуск

**macOS (LaunchAgent)**  
Создайте `~/Library/LaunchAgents/com.naeon.assets.sync.plist`

**Windows**  
Используйте Task Scheduler + скрипт `.ps1` / `.bat`.

**Простой способ для обоих**  
Запускайте `rclone bisync` вручную или через terminal multiplexer / фоновый процесс во время работы над проектом.

### Рекомендация для NAEON

На этапе разработки используйте:

1. `rclone bisync` 1–2 раза в час или по запросу.
2. Или `rclone mount` для удобства (если ассетов не слишком много).

Ключи храните только в `rclone.conf` (он локальный) или через переменные окружения.
