# NAEON

Многопользовательская онлайн-игра во вселенной Aexion (Cybernex vs gROT).

**Репозиторий:** https://github.com/br7wq7yfqc-ctrl/naeon  
**Концепция:** [CONCEPT.md](CONCEPT.md)  
**План разработки:** [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md)  
**Локальный сетап:** [docs/LOCAL_SETUP.md](docs/LOCAL_SETUP.md)  
**Handoff:** [docs/HANDOFF.md](docs/HANDOFF.md)

## Быстрый старт (Godot 4.3)

```bash
git clone https://github.com/br7wq7yfqc-ctrl/naeon.git
cd naeon
# Открыть папку godot/ в Godot 4.3+
# Main scene: scenes/test/TestArena.tscn
```

### Что стартует (не «playable для человека»)

Прототип на 2026-08-16 **непригоден для человека**. План: [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) v3 (P0). Отчёт VM: [docs/PLAYTEST_SANDBOX.md](docs/PLAYTEST_SANDBOX.md).

| Сцена | Содержание | Статус |
|-------|------------|--------|
| `MainMenu` | Boot | стартует |
| `OpenSpace` | Полёт + 3 тела + live terrain | стартует, **хаос террейна** |
| `TestArena` | Clash sandbox (`M`/`Tab` режут сюда) | стартует; это не карта галактики |
| `SpaceTest` | Старый ship shell | стартует |

**Управление (TestArena):** WASD, мышь, Space, Shift, Q/E/R/F, Tab → космос  
**Управление (Ship):** WASD + Space/Shift, Q огонь, E посадка, R модуль

## Структура

```
naeon/
├── godot/                  # Godot 4.3 проект
├── assets/                 # Тяжёлые ассеты (gitignore)
├── pipeline/               # Tripo → Blender → dual-theme
├── docs/                   # Документация + handoff
├── scripts/                # Sync utilities
├── CONCEPT.md
└── DEVELOPMENT_PLAN.md
```

## Asset pipeline

```bash
export TRIPO_API_KEY=tsk_...
./pipeline/scripts/run_pipeline.sh "cybernex canine robot, dark neon" canine_scout B
```

См. [docs/ASSET_PIPELINE.md](docs/ASSET_PIPELINE.md).

## Правила

- Тяжёлые ассеты **никогда** не коммитятся (`assets/`)
- Секреты только в `.env` / GitHub Secrets
- Клиент: **macOS + Windows**
