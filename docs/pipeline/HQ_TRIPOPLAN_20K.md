# NAEON HQ Asset Plan

## Two-week budget (ACTIVE) — 2026-08-06 → 2026-08-20

| | |
|--|--|
| **Cap** | **5 000** Tripo API credits |
| Hard reserve | 200 |
| Usable | **4 800** |
| Policy file | `pipeline/briefs/hq_budget_policy.json` |
| Tracker | `logs/hq_budget_tracker.json` |

**Scope this window:** finish Wave S heroes + prioritized Wave A (high, not ultra where possible).  
**Do not** start full Wave C expansion or extreme retexture mass-pass until after 2026-08-20 unless owner raises cap.

`run_hq_wave.sh` enforces: stop if `hq_spent >= usable` or balance < min_balance/reserve.

## Long-term plan (NOT CANCELLED) — 20 000

After the 2-week window (or when owner tops up for full campaign):

| Bucket | Credits | Purpose |
|--------|---------|---------|
| S Heroes | ~3 000 | forms, hull, enemies, habitat… |
| A Gameplay | ~4 000 | modules, colony, combat props |
| B World | ~3 500 | env fill |
| C New | ~5 000 | frigate, thrall, hubs… |
| R Retexture | ~2 000 | detailed/extreme pass |
| Buffer + reserve | ~2 500 | retries + floor |

Resume: set `cap_credits` / `usable_this_window` in policy to 20000/19500 or new window, then `run_hq_wave.sh C 500`.

## Observed costs
- ultra (v3.1 detailed): **~50 cr**
- high: **~30–40 cr**

## CLI
```bash
# Status
python3 -c "import json; print(json.load(open(\"logs/hq_budget_tracker.json\"))[\"remaining_under_cap\"])"

# Waves (respect policy automatically)
bash pipeline/scripts/run_hq_wave.sh S 200
bash pipeline/scripts/run_hq_wave.sh A 200   # uses brief; 2w chain uses a_2w subset
```
