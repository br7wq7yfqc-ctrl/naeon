# CI/CD — NAEON

## Текущий статус (Build-Session 1+)

Настроена базовая непрерывная интеграция через **GitHub Actions**.

### Workflows

| Файл | Назначение |
|------|------------|
| `.github/workflows/ci.yml` | Основной CI: проверка секретов, .gitignore, Godot headless |
| `.github/workflows/secret-scan.yml` | Дополнительное сканирование секретов (TruffleHog) |

### Что проверяется сейчас

1. **Нет секретов в репозитории** (`.env`, ключи, pem-файлы)
2. **Папка `/assets/` защищена** в `.gitignore`
3. **Существует `godot/project.godot`**
4. **Godot 4.3 headless** может открыть проект

### Что будет добавлено позже

- Экспорт под Windows / macOS / Linux
- Загрузка билдов в Yandex Object Storage (`neon/releases/`)
- Автоматические тесты Ability System / Ownership
- Версионирование и GitHub Releases
- Уведомления в Telegram / Discord

## Секреты в GitHub Actions

Когда понадобится доступ к бакету `neon` из CI (загрузка релизов), добавьте в
**Settings → Secrets and variables → Actions** следующие secrets:

```
YC_STORAGE_ACCESS_KEY
YC_STORAGE_SECRET_KEY
YC_STORAGE_ENDPOINT   (https://storage.yandexcloud.net)
YC_STORAGE_BUCKET     (neon)
```

**Никогда** не кладите эти значения в код или в файлы репозитория.

## Локальный запуск аналога CI

```bash
# Проверка, что нет секретов
git ls-files | grep -E '\.env$|id_rsa|id_ed25519|\.pem$'

# Godot headless (если установлен)
cd godot
godot --headless --editor --quit-after 20
```

## Рекомендуемый следующий шаг

1. Добавить `export_presets.cfg` (Windows + macOS) когда появятся первые playable билды.
2. Раскомментировать job `export-windows` в `ci.yml`.
3. Настроить загрузку артефактов в `s3://neon/releases/`.
