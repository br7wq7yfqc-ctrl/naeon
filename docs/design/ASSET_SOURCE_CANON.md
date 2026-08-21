# NAEON — Asset source canon (якорь)

**Authority:** откуда берётся меш. Версия 1.1, 2026-08-17.  
How-to пайплайна: `docs/ASSET_PIPELINE.md`.  
Авторский скелет / безымянный filler: `docs/design/WORLD_FILL.md` §3.1.  
OPEN SPACE бар: `docs/design/OPEN_SPACE_SC_BENCHMARK.md`.

Столпы: нет P2W · Knowledge soft · Infection max 5 · story ≠ power · Godot 4.7.2 · взрослый hard-sci-fi.

| Класс | Источник | Хранение | Git |
|-------|----------|----------|-----|
| **Unique** — фракционные герои, dual-theme CX/GR, `site_pin`, locked catalog | **Tripo only** (один прогон → Blender LOD + faction kit) | `s3://neon/generations/` + манифест | меш никогда |
| **Generic** — грунт, скалы, флора, HDRI, unnamed scatter | **CC0** (Poly Haven, AmbientCG) | `s3://neon` + строка манифеста | никогда |
| **Paid scan** — поверхности / растения / камень | **ScansLibrary** (royalty-free, не OSS) | `s3://neon` + **notice** в билде | никогда |
| **Неясная лицензия** | **Отказ** | — | — |

Жёсткие правила:

- Максимум готового из сети. Tripo — только уникальное / фракционное.
- Безымянный грунт, скала, флора — готовые CC0/сканы в `s3://neon`, никогда в git.
- Готовый меш **не** становится `SITE_*` и **не** даёт power.
- Неясная лицензия = отказ. Не «пока положим».
- `assets/` и `generations/` не в git. Секреты не коммитить. S3 Index не патчить из этого якоря.
- SPDX репо оставить `null`, пока в пайплайне есть ScansLibrary.
