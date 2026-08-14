# NAEON — Friends List, Squads & Parties

**Version:** 0.1  
**Depends on:** rules/11 alliance, 17 voice, 10 UI, 18 TransitionContext  
**Reference practices:** WoW/FFXIV party clarity + EVE fleet seed — keep low-end and no combat power from social tier

---

## 1. Friends list

| Feature | Rule |
|---------|------|
| Add / remove | Bidirectional accept |
| Status | Online / in-layer / busy / offline |
| Notes | Private local note |
| Invite | To squad, party, or alliance (if rank allows) |
| Block | Separate from friend; hides chat/invites |
| Cross-faction friends | **Allowed** — social only; does not bypass war rules on structures |

Friends never grant damage buffs, claim strength, or War Score multipliers.

---

## 2. Squad (fireteam)

Small persistent-ish group for TPS/Space ops.

| Param | Value |
|-------|--------|
| Size | **2–5** players |
| Leader | Inviter or elected |
| Shared | Markers, basic target ping, squad chat |
| Loot / credit | Optional need/greed or free-for-all — **no** forced power redistribute |
| Transition | Squad members can opt-in follow land/dock if same instance policy |
| Voice | Squad channel if unlocked (sub or achievement rules/17) |

Squad is **not** an alliance and does not hold Ownership.

---

## 3. Party (match / activity group)

| Param | Value |
|-------|--------|
| Size | Up to **5** (align squad) or up to **10** for PvE instances later |
| Lifetime | Until disband or activity end |
| Use | Quests, Contested pushes, Arena premade queue seed |
| Roles | Optional tags (tank/support/dps fantasy) — cosmetic for matchmaking hints only |

---

## 4. Fleet seed (Space / Strategy)

| Param | Value |
|-------|--------|
| Size target | Up to **~30** under flagship aggregation |
| Command | Flagship pilot / designated FC (alliance officer+) |
| LOD | Aggregated representation on low-end (rules/22) |
| Abilities | Fleet-order pings; Strategy bandwidth abilities later |

Full multi-crew seats remain per-ship (rules/22).

---

## 5. Invites & safety

- Invite spam rate limits.
- Block list respected across squad/party/fleet invites.
- War state does not auto-kick cross-faction friends from social list; structure permissions still apply.

---

## 6. UI contracts

- Friends panel in Meta / Social layer (rules/10).
- Squad frames: Integrity + Infection pips readable (5 max) + Firewall state — same threat rules as solo HUD.
- Layer label preserved when squad transitions (rules/18).

---

## 7. VS minimum

Local friends list mock, 2–5 squad invite, squad chat text, no power aura from being grouped.

---

*Social group source of truth; alliance hierarchy remains rules/11.*
