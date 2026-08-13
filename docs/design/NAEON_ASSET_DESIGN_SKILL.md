---
name: naeon-asset-design
description: Universal NAEON visual design + canon lock. After every user approval, append the locked sketch to Index generations/catalog.json and copy the file to neon canon/.
version: 1.2
---

# NAEON Asset Design

## Index + bucket — after EVERY approval

**Index (authority):** `s3://neon/generations/catalog.json`
Repo mirror: `docs/design/approved_sketches.json`

On утверждено / согласовано / фиксируем:

1. Append one locked row to `generations/catalog.json` (id, faction, view, class, label, status, bucket_key, grok_url).
2. Copy image to `generations/canon/{class}/{id}/master.jpg`.
3. Rejects do not enter the Index.

Full rules: loadable skill `naeon-asset-design` v1.2.
