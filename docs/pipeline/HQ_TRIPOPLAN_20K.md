# NAEON HQ Asset + World Plan (August 2026)

## Budgets
| Window | Cap | Usable (reserve 200) |
|--------|-----|----------------------|
| **Next week** (2026-08-06 → 08-13) | **5 000** | 4 800 |
| **This month** | **20 000** | 19 500 |
| After month | Owner tops up further — vision not capped | |

**Code systems (seamless, physics, quality tiers) cost 0 Tripo.**

## Product targets (all target GPUs ≥ 1060 3GB)
1. Seamless landing (pad + surface) without scene swap  
2. Whole planet render (sphere + atmo + free orbit)  
3. Bases on surface  
4. Free space flight anywhere in volume  
5. Free surface walk (radial gravity)  
6. SC-like ship modes SCM/NAV/HOVER  

## Wave spend plan (this month ≤20k)

| Phase | When | Assets | Est cr |
|-------|------|--------|--------|
| S Heroes | week 1 | forms, hull, enemies, pad, habitat… | ~500 (done) |
| A Gameplay | week 1 | modules, props priority | ~500–800 |
| A full + B density | week 2–3 | env fill, stations | ~3 000 |
| C new content | week 3–4 | frigate, thrall, hubs | ~2 000–5 000 |
| R retexture | week 4 | hero polish | ~2 000 |
| Buffer | — | retries | ~2 000 |

## Observed costs
- ultra ≈ 50 · high ≈ 30

## Enforcement
`pipeline/briefs/hq_budget_policy.json` + `run_hq_wave.sh` stop at week cap.
