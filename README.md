# NAEON

Многопользовательская онлайн-игра во вселенной Aexion (Cybernex vs gROT).

**Репозиторий:** https://github.com/br7wq7yfqc-ctrl/naeon  
**Концепция:** [CONCEPT.md](CONCEPT.md)  
**План разработки:** [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md)

## Структура

```
naeon/
├── godot/                  # Godot 4.x проект
├── assets/                 # Тяжёлые ассеты (локально, в .gitignore)
├── docs/                   # Документация
├── scripts/                # Скрипты синхронизации и утилит
├── .github/workflows/      # CI/CD
├── CONCEPT.md
└── DEVELOPMENT_PLAN.md
```

## Быстрый старт

1. Клонировать репозиторий
2. Открыть папку `godot/` в Godot 4.3+
3. (Опционально) Настроить синхронизацию ассетов с бакетом `neon` — см. `docs/ASSETS_STORAGE.md` и `docs/ASSETS_AUTO_SYNC.md`

## CI/CD

При каждом push/PR в `main` и `develop` запускается:

- Проверка на случайно закоммиченные секреты
- Валидация структуры проекта
- Godot headless check

Подробнее: [docs/CI_CD.md](docs/CI_CD.md)

## Важные правила

- Тяжёлые ассеты **никогда** не коммитятся (папка `assets/` в `.gitignore`)
- Секреты хранятся только локально (`.env`) или в GitHub Secrets
- Клиент должен собираться под **macOS и Windows**
