# Asset sync scripts

These scripts synchronise the local `assets/` folder with the Yandex Object Storage bucket `neon`.

## Prerequisites

- `aws-cli` installed
- Credentials provided either via:
  - environment variables (`YC_STORAGE_ACCESS_KEY`, `YC_STORAGE_SECRET_KEY`), or
  - AWS profile named `neon`

## Usage

```bash
# Download from bucket → local
./scripts/assets/sync_from_bucket.sh          # syncs neon/dev/ → ./assets/
./scripts/assets/sync_from_bucket.sh shared   # syncs neon/shared/

# Upload local → bucket
./scripts/assets/sync_to_bucket.sh
./scripts/assets/sync_to_bucket.sh shared
```

Make scripts executable once:

```bash
chmod +x scripts/assets/*.sh
```
