# NAEON — Vertical-Slice Data Schemas (examples)

**Version:** 0.2  
**Non-normative examples** for Godot Resources / JSON.  
**Authority:** rules/04, 16, 18, **25**; lore quest IDs; LEGENDARY_SITES

---

## TransitionContext (rules/18)

```json
{
  "schema_version": 1,
  "from_layer": "space",
  "to_layer": "tps",
  "player_id": "local",
  "faction": "Cybernex",
  "form_id": "canine_01",
  "active_quest_ids": ["CQ-CX-II-02"],
  "site_pin_id": "SITE_ARK_RING",
  "claim_target_id": "pillar_a",
  "claim_state": "Contested",
  "claim_progress": 0.42,
  "cargo_snapshot": [{"item_id": "ore_basic", "qty": 12}],
  "cargo_risk_flag": false,
  "ship_id": "starter_hull",
  "dock_or_pad_id": "pad_01",
  "alliance_id": null,
  "party_ids": [],
  "match_id": null,
  "war_score_pending": null,
  "show_layer_label": true,
  "fade_style": "standard"
}
```

S1: preserve quest ids, site pin, claim, cargo across land/dock without hitch (rules/25).

---

## AbilityResource (subset)

```json
{
  "id": "infect_link",
  "display_name": "Infect Link",
  "faction_tag": "gROT",
  "tags": ["Hack", "Infection"],
  "cost": 35,
  "cooldown": 16.0,
  "cast_time": 0.4,
  "range": 18.0,
  "max_stacks_ref": 5,
  "rank": 1
}
```

---

## QuestResource

```json
{
  "id": "CQ-CX-II-01",
  "faction": "Cybernex",
  "act": 2,
  "giver_role_id": "CX_QUARTERMASTER",
  "layer": "tps",
  "site_pin_ids": ["SITE_ARK_RING"],
  "objectives": [
    {"type": "gather", "item_id": "ore_basic", "count": 15}
  ],
  "reward_contribution": [70, 100],
  "premium": false,
  "vo_optional_keys": ["vo.cx.aegis.quest_handoff"]
}
```

---

## SitePin (legendary / quest)

```json
{
  "id": "SITE_ARK_RING",
  "system": "ARK",
  "display_name": "Ring of Quiet Lights",
  "layer_hint": "space_or_tps",
  "ownership_sensitive": true,
  "codex_key": "codex.site.ark_ring"
}
```

IDs align with LEGENDARY_SITES.md (`SITE_ARK_VAULT_CROWN`, `SITE_ROT_SPIRE`, `SITE_ROT_KILNS`, `SITE_SHATTERED_TWIN_MOON_A`, …).

---

## Perf note on data

Quest spawn tables must declare **max concurrent** dummies/props. Unbounded objective spawns fail rules/25 QA.

---

*Examples only — prefer Godot Resources.*
