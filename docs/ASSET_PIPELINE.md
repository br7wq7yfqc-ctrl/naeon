# NAEON Asset Pipeline

**Канон источника важнее автоматизации.** Версия 2.0, 2026-08-16.  
Короткий якорь: `docs/design/ASSET_SOURCE_CANON.md`.  
WorldFill (авторский скелет / безымянный filler): `docs/design/WORLD_FILL.md` — не дублируется здесь.

---

## 0. Canon — откуда берётся меш

Нет P2W · Knowledge soft · Infection max 5 · story ≠ power · Godot 4.3 · взрослый hard-sci-fi.

Максимум готовых ассетов из сети. **Tripo только для уникального.** Генерировать «ещё один слой грунта» запрещено.

| Класс | Что это | Источник | Куда класть | Git |
|-------|---------|----------|-------------|-----|
| **unique → Tripo** | Фракционные герои, dual-theme CX/GR, `site_pin`, позиции locked-каталога (`TRIPO_ASSET_MANIFEST`, `approved_sketches`) | Tripo (один прогон) → Blender LOD0/1/2 + faction kit | `s3://neon/generations/` + строка манифеста | меш никогда |
| **generic + CC0 → neon + манифест** | Грунт, скалы, флора, HDRI, unnamed scatter, belt rocks | [Poly Haven](https://polyhaven.com/license) **CC0**, [AmbientCG](https://docs.ambientcg.com/license/) **CC0 1.0** | `s3://neon` + строка манифеста (лицензия, URL, дата) | никогда |
| **paid scan → neon + notice** | Сканы поверхностей / растений / камня | [ScansLibrary](https://www.scanslibrary.com/content/licence) — **royalty-free, не OSS** | `s3://neon` + notice в билде: `Contains assets from ScansLibrary.com - Assets may not be redistributed` | никогда |
| **неясное → отказ** | Нет SPDX / «found on Discord» / перепакованный сток | не брать | — | — |

Запреты:

- Готовый меш не становится `SITE_*` и не даёт combat / claim / Infection power.
- Free-секция ScansLibrary без оплаченного плана — не в коммерцию.
- ScansLibrary несовместим с OSS/CC на игру, пока сканы в пайплайне. SPDX репо = `null`.
- Не патчить S3 Index (`generations/catalog.json`) из этого документа.
- Не коммитить `assets/`, `generations/`, `.env`, ключи.

P0 остров (см. `DEVELOPMENT_PLAN.md`): **1 пад** (code-first или CC0) + **1 generic CC0 проп** + **1 уникальный Tripo-герой**. Остальное — после зелёного P0.

---

## 1. Pipeline (после канона, не вместо)

Тяжёлая обработка (LOD, dual-theme, export) — на VM + локальный `assets/` (gitignore) ↔ бакет `neon`.

```
1. Класс (unique / generic+CC0 / paid scan / отказ) — сначала это, не промпт
2. unique: Tripo → pipeline/inbox/
   generic/paid: download from named library → inbox/ + licence note
3. Blender headless: cleanup, LOD0/1/2, CX/GR kit только для unique
4. Export → assets/{category}/{name}/  (local, gitignored)
5. Манифест + rclone/aws → s3://neon/dev/ или generations/
```

```
naeon/
├── pipeline/inbox|processing|processed|briefs|scripts/
├── assets/          # gitignored
└── godot/           # placeholders only
```

Tripo key: `TRIPO_API_KEY` в окружении. Никогда в git. Скрипт: `pipeline/scripts/generate_tripo.py`.

Dual-theme (CX cyan / GR biomass) — только для **unique**. Generic CC0 и paid scan остаются нейтральным filler; WorldFill не красит их во фракционных героев.

---

## 2. Status

- Канон источника записан (этот файл + `ASSET_SOURCE_CANON.md`).
- Структура пайплайна есть; генерация «всего подряд в Tripo» **снята с приоритета**.
- Следующий ingest: один P0-герой из манифеста, когда P0-остров дойдёт до ассета — не T1 hypergate.

S3 Index `generations/catalog.json` был стёрт 2026-08-15. Этот PR его не чинит.
