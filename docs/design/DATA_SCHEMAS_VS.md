# NAEON — Vertical-Slice Data Schemas (examples)

**Version:** 0.1  
**Non-normative examples** for Godot Resources / JSON. Authority remains rules/04, /16, /18.

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
  "active_quest_ids": ["CQ-CX-I-01"],
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

Numbers must match rules/04 at rank 1; ranks from rules/16.

---

## QuestResource (Act I)

```json
{
  "id": "CQ-CX-I-01",
  "faction": "Cybernex",
  "giver_role_id": "CX_WARDEN",
  "layer": "tps",
  "reward_contribution": [40, 60],
  "premium": false
}
```

---

*Examples only — implement as Godot Resources preferred.*
