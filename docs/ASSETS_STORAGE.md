# Хранение тяжёлых ассетов NAEON

## Обзор

Тяжёлые ассеты (модели, текстуры, аудио, варианты Dynamic Ownership и т.д.) **не хранятся в Git**.

- **Центральное хранилище**: Yandex Object Storage, бакет `neon`
- **Локальная рабочая копия**: папка `assets/` на машине разработчика (в `.gitignore`)

## Бакет `neon`

**Endpoint:** `https://storage.yandexcloud.net`  
**Регион:** `ru-central1`

### Рекомендуемая структура папок в бакете

```
neon/
├── dev/                          # текущие рабочие ассеты команды
│   ├── characters/
│   ├── ships/
│   ├── environments/
│   │   ├── cybernex/             # Venus Project style
│   │   └── grot/                 # biomass industrial
│   ├── audio/
│   ├── vfx/
│   └── ui/
├── shared/                       # стабильные общие версии
├── releases/                     # собранные пакеты под версии клиента
└── placeholders/                 # лёгкие заглушки (можно дублировать в git)
```

## Безопасное хранение ключей

Ключи S3 **никогда** не коммитятся.

1. Скопируйте `.env.example` → `.env`
2. Заполните реальные значения:
   ```
   YC_STORAGE_ACCESS_KEY=YCAJ...
   YC_STORAGE_SECRET_KEY=YCPW...
   ```
3. Файл `.env` уже находится в `.gitignore`.

Альтернатива — AWS CLI профиль:

```bash
aws configure --profile neon
# AWS Access Key ID:     <Key ID>
# AWS Secret Access Key: <Secret>
# Default region:        ru-central1
# Default output:        json
```

Затем всегда указывайте `--profile neon --endpoint-url https://storage.yandexcloud.net`.

## Синхронизация

### Вариант 1: aws-cli (рекомендуется)

```bash
# Скачать всё из бакета в локальную папку assets/
aws s3 sync s3://neon/dev/ ./assets/ \
  --endpoint-url https://storage.yandexcloud.net \
  --profile neon

# Загрузить локальные изменения в бакет
aws s3 sync ./assets/ s3://neon/dev/ \
  --endpoint-url https://storage.yandexcloud.net \
  --profile neon
```

### Вариант 2: rclone

```bash
rclone sync neon:dev ./assets
rclone sync ./assets neon:dev
```

Конфиг rclone (`~/.config/rclone/rclone.conf`):

```
[neon]
type = s3
provider = Other
access_key_id = <Key ID>
secret_access_key = <Secret>
endpoint = storage.yandexcloud.net
region = ru-central1
```

### Вариант 3: скрипты в репозитории

См. папку `scripts/assets/`.

## Как Godot использует ассеты

1. В репозитории лежат только лёгкие placeholder-ассеты.
2. Во время разработки Godot может читать из локальной папки `../assets/` (через скрипт или symlink).
3. Позже будет добавлен `AssetLoader` на базе `ResourceLoader.load_threaded_request` + возможность подгрузки из Object Storage.

## Правила

- Никогда не коммитьте `.env`, ключи или содержимое `/assets/`.
- Перед пушем больших бинарников проверяйте `.gitignore`.
- Для команды используйте общую структуру папок выше.


## Права доступа

См. [BUCKET_ACCESS.md](./BUCKET_ACCESS.md).

- `dev/` — приватно
- `generations/`, `releases/` — публичный GET (после применения политики)
- запись — только SA `neon-access`
