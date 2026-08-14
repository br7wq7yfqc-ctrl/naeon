---
name: naeon-asset-design
description: Universal NAEON visual design + canon lock. On every new approval OR any change to an existing lock, write the row to Index generations/catalog.json in the same turn.
version: 1.3
---

# NAEON Asset Design

## 4. Index — write on every lock AND every change (mandatory)

**Index (authority):** `s3://neon/generations/catalog.json`

Same turn. No “write later”.

| Event | Action in `generations/catalog.json` |
|-------|--------------------------------------|
| New approval (утверждено / согласовано / фиксируем / канон) | **Append** a locked row. Copy image to `generations/canon/{class}/{id}/master.jpg`. |
| Change to an existing lock (new UUID, view swap, label, class, notes, cinematic↔ortho, slug bind) | **Patch that row in place.** Keep slug. Update `id` / `bucket_key` / `grok_url` / `notes`. |
| Reject / supersede | If a row exists: `status: superseded`, `usable: false`. Do not delete history. |
| Draft / seating test | Do **not** write. |

Full rules: loadable skill `naeon-asset-design` v1.3.
