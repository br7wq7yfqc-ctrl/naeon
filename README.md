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

### Что уже playable

| Сцена | Содержание |
|-------|------------|
| `TestArena` | TPS, abilities (Pulse / Firewall / Probe), form cycle, Ownership pillars, extractor → Contribution |
| `SpaceTest` | Semi-Newtonian ship, modules, fire, land → TestArena |

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
