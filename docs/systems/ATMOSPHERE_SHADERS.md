# Анализ шейдеров атмосферы (NAEON OpenSpace)

## 1. Что было (baseline)

**Модель:** один `SphereMesh` радиуса `R + H`, `StandardMaterial3D`:
- `UNSHADED` + `TRANSPARENCY_ALPHA`
- `CULL_FRONT` (смотрим внутреннюю сторону оболочки)
- `DEPTH_DRAW_DISABLED`
- alpha гасится скриптом по дистанции

| Плюсы | Минусы |
|-------|--------|
| Очень дёшево (1 draw, no lighting) | Плоский «мыльный пузырь», нет лимба |
| Стабильно на 1060 | Нет day/night terminator на ореоле |
| Просто debug | Изнутри = тот же плоский alpha |
| | Overdraw всего диска, если alpha высок |

**Вердикт baseline:** OK как placeholder, **не** SC-like.

---

## 2. Карта подходов (от дешёвых к тяжёлым)

| # | Подход | GPU cost (1060) | Визуал | Когда |
|---|--------|-----------------|--------|-------|
| **A** | Flat shell (было) | ★☆☆☆☆ | ★☆☆☆☆ | прототип |
| **B** | **Fresnel / limb shell** (сейчас) | ★★☆☆☆ | ★★★☆☆ | **default NAEON** |
| **C** | Dual shell outer+inner haze | ★★☆☆☆ | ★★★☆☆ | approach / inside |
| **D** | Height fog `Environment` band | ★☆☆☆☆ | ★★☆☆☆ | low altitude only |
| **E** | Single-scatter raymarch (8–16 steps) | ★★★☆☆ | ★★★★☆ | HIGH tier optional |
| **F** | Bruneton / Hillaire LUT (precompute) | ★★★☆☆ + bake | ★★★★★ | post-20k / rec GPU |
| **G** | Full volumetric multi-scatter | ★★★★★ | ★★★★★ | offline / cinematic, **не** realtime multi-planet |

Star Citizen / AAA space: обычно **F** (precomputed atmosphere) + aerial perspective.  
Для NAEON min **1060 3GB** и 3 планеты одновременно: **B+C (+D)** — правильный economical выбор.

---

## 3. Математика (что важно понимать)

### 3.1 Limb / Fresnel (то, что внедрили)
На оболочке:
```
fresnel = (1 - sat(dot(N, V))) ^ rim_power
alpha  ≈ fresnel * density * day * color.a
```
- Край диска ярче (как рассеянный край атмосферы).
- Центр почти прозрачен → меньше «заливки» планеты.
- `day` из `dot(N_world, sun)` даёт мягкий terminator на ореоле.

**Стоимость:** несколько ALU во fragment, без texture fetch, без loops.

### 3.2 Optical depth (ray-sphere)
Классика:
```
T = exp(-β * optical_length(ray ∩ atmosphere))
L = sun_inscatter + ground * T
```
Нужны ray-sphere intersections + 1–2 scatter lobes (Rayleigh/Mie).  
В full form — либо raymarch (E), либо LUT (F).

### 3.3 Rayleigh / Mie
- **Rayleigh** ~ λ⁻⁴ → голубой ореол (Cybernex worlds).
- **Mie** → forward haze, закаты, «грязный» gROT красный.

В шейдере B мы **не** считаем λ-спектр; цвет задаётся `atmosphere_color` (faction tint) — достаточно для dual-faction identity.

---

## 4. Текущая реализация NAEON

| Asset | Role |
|-------|------|
| `shaders/planet_atmosphere.gdshader` | Outer shell, `cull_front`, limb + sun |
| `shaders/planet_atmosphere_inner.gdshader` | Inner haze when altitude < H |
| `PlanetBody._update_atmosphere` | Distance fade, horizon_boost, inner toggle |
| Quality tier | rim/density/intensity scales LOW→ULTRA |

### Quality mapping
| Tier | rim_power | density | intensity | Notes |
|------|-----------|---------|-----------|-------|
| LOW (1060) | 4.5 | 0.75 | 1.1 | thinner, less overdraw |
| MEDIUM | 3.8 | 0.95 | 1.35 | default |
| HIGH (3060) | 3.2 | 1.05 | 1.5 | richer limb |
| ULTRA (4060) | 2.8 | 1.15 | 1.65 | softer falloff |

### Pipeline per frame (throttled ~8 Hz in PlanetBody)
1. dist → show/hide outer (LOD < IMPOSTOR)  
2. `horizon_boost` as altitude → H*3  
3. intensity *= distance fade  
4. inner haze if altitude < H  

---

## 5. Риски / артефакты

| Issue | Mitigation |
|-------|------------|
| Sorting vs transparent props | atmosphere depth_draw_never; pads opaque |
| Overdraw 3 large spheres | atmo_max_dist cull + impostor hides atmo |
| Flat look at noon center | intentional (limb model); optional fill term already small |
| Inside-atmo popping | inner shell soft density by depth |
| Sun not matching light | `OpenSpace._sync_planet_sun()` from DirectionalLight |

---

## 6. Roadmap (без ломки 1060)

| Phase | Work | Tripo | GPU |
|-------|------|-------|-----|
| **Done** | B+C fresnel dual shell | 0 | all tiers |
| **Next** | D — Environment fog density vs altitude in OpenSpace | 0 | all |
| Later | E — optional raymarch flag on HIGH only, 8 steps | 0 | 3060+ |
| Later | F — bake 2D transmittance LUT offline | 0 | rec+ |
| Never default | G full volume multi-scatter realtime | — | — |

---

## 7. Рекомендации (выводы)

1. **Не** тащить Bruneton realtime на min spec — убивает 3GB VRAM/fillrate при 3 планетах.  
2. **Limb shell + faction color** даёт 80% «космического» силуэта за 5% цены SC.  
3. **Inner haze** закрывает approach/landing, где flat shell ломается.  
4. **Height fog (D)** — следующий дешёвый шаг для surface immersion.  
5. LUT (F) — когда будет один «hero system» и запас по month budget на polish, не сейчас.

## 8. Файлы
- `godot/shaders/planet_atmosphere.gdshader`
- `godot/shaders/planet_atmosphere_inner.gdshader`
- `godot/scripts/world/PlanetBody.gd` (`_apply_atmo_uniforms`, `_update_atmosphere`)
- `godot/scripts/world/OpenSpace.gd` (`_sync_planet_sun`)
