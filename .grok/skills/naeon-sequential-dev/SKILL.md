---
name: naeon-sequential-dev
description: >
  Sequential deepening of NAEON (Godot 4.7.2) mechanics, physics, and
  approved design-to-Tripo pipeline. Use when the user says
  "naeon-sequential-dev", "дальше по плану", continue development,
  or when ingesting approved renders / orthogonal Tripo schemes.
---

# NAEON — Sequential Dev

Load with `naeon-holistic-economical`. Self-drive against CONCEPT + DEV_PLAN + SESSION_CONTRACT.

## Mode

- Deepen mechanics + physics + optimization. No checklist theater.
- No DMG unless the owner asks.
- Smoke after each patch (`OpenSpace` + `TestArena` headless).
- One sequential change, then verify, then the next.

## Bucket: approved designs → Tripo

**Canonical store:** Yandex Object Storage bucket `neon`, prefix `generations/`.

| Path | What belongs there |
|------|--------------------|
| `s3://neon/generations/` | **Only approved** design renders and orthogonal schemes for Tripo |
| `s3://neon/generations/rendered/` | Approved beauty / design renders |
| `s3://neon/generations/imagine_images/` | Approved stills / ortho / concept plates |
| `s3://neon/generations/imagine_videos/` | Approved motion refs (optional) |
| **`s3://neon/generations/catalog.json`** | **Index. Update on every new approved ingest** |

Local working copy: `/Users/vladmann/Documents/naeon/generations/` (gitignored). Sync to the bucket; never commit binaries.

### catalog.json (required)

- Single source of truth for what is approved and Tripo-ready.
- Rebuild/update **whenever** a new generation is approved and uploaded.
- Script: `scripts/assets/update_generations_catalog.py` (writes local + `aws s3 cp` to the bucket).
- Schema (keep stable):

```json
{
  "version": 1,
  "updated": "ISO-8601",
  "bucket": "neon",
  "prefix": "generations/",
  "purpose": "Approved design renders and orthogonal schemes for Tripo",
  "entries": [
    {
      "id": "stable-id",
      "key": "generations/rendered/foo.jpg",
      "kind": "render | ortho | concept | video",
      "approved": true,
      "tripo_ready": true,
      "folder": "rendered"
    }
  ]
}
```

### Agent duties (every ingest)

1. Put approved files under `generations/` (correct folder).
2. Run `update_generations_catalog.py` (or equivalent) so `catalog.json` includes the new keys.
3. Upload file **and** `catalog.json` to `s3://neon/generations/`.
4. Use catalog entries as Tripo briefs (ortho + approved render), not raw unlisted dumps.

`dev/` stays private working assets. `releases/` is installers. Do not mix.

## Also remember

- CORS already on the bucket. Public GET for `generations/*` needs `storage.admin` + `apply_bucket_access.sh`.
- Until public policy: `scripts/assets/presign_generation.sh <key>`.
