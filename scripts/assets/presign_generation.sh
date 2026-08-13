#!/usr/bin/env bash
# Temporary signed URL (1h) — works with storage.editor, no public bucket needed.
set -euo pipefail
export PATH="$HOME/Library/Python/3.9/bin:$PATH"
KEY="${1:-generations/rendered/ypNsZ.jpg}"
SECS="${2:-3600}"
aws s3 presign "s3://neon/${KEY}" \
  --expires-in "$SECS" \
  --endpoint-url https://storage.yandexcloud.net \
  --profile neon
