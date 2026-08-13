# Права доступа к бакету `neon`

Endpoint: `https://storage.yandexcloud.net`  
Регион: `ru-central1`

## Модель

| Префикс | Кто читает | Кто пишет |
|---------|------------|-----------|
| `dev/` | только ключ SA | SA `neon-access` (`storage.editor`) |
| `generations/` | **публичный GET** (эскизы / Imagine) | SA |
| `releases/` | **публичный GET** (DMG / пакеты) | SA |
| остальное | приватно | SA |

Запись снаружи не открыта. CORS: `GET`/`HEAD` с любого origin (превью в браузере).

## Что уже применено (ключ SA)

- Профиль AWS CLI `neon` на Mac
- CORS на бакете: `GET`/`HEAD`, `AllowedOrigins: *`

## Что требует `storage.admin` (сейчас Access Denied)

`PutBucketPolicy` и `PutObjectAcl` ключом `storage.editor` отклоняются.

Сервисный аккаунт: **neon-access** (`ajeesl2i6831roe889nl`).

В консоли Yandex Cloud:

1. Object Storage → бакет **neon** → **Права доступа**
2. Назначить `neon-access` роль **`storage.admin`** (на бакет, не на каталог)
3. На Mac:

```bash
~/Documents/naeon/scripts/assets/apply_bucket_access.sh
```

Либо вручную вставить `scripts/assets/neon-bucket-policy.json` как политику бакета.

После этого объекты открываются так:

```
https://storage.yandexcloud.net/neon/generations/rendered/<file>.jpg
https://storage.yandexcloud.net/neon/releases/<file>
```

## Пока политика не применена

Временные ссылки (1 час), без публикации бакета:

```bash
~/Documents/naeon/scripts/assets/presign_generation.sh generations/rendered/ypNsZ.jpg
```

## Проверки

```bash
# список (нужен ключ)
aws s3 ls s3://neon/generations/ --endpoint-url https://storage.yandexcloud.net --profile neon

# анонимное чтение (после политики → 200, сейчас 403)
curl -sI https://storage.yandexcloud.net/neon/generations/rendered/ypNsZ.jpg
```

## Approved designs index

`generations/` holds **approved** design renders and orthogonal schemes for Tripo.

Index (update on every new approved ingest):

`s3://neon/generations/catalog.json`

Rebuild + upload:

```bash
python3 ~/Documents/naeon/scripts/assets/update_generations_catalog.py
```

Rule is locked in `.grok/skills/naeon-sequential-dev/SKILL.md`.
