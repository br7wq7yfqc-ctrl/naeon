#!/usr/bin/env bash
# Download assets from Yandex Object Storage bucket "neon" to local ./assets
# Requires: aws-cli and either --profile neon or environment variables.

set -euo pipefail

ENDPOINT="${YC_STORAGE_ENDPOINT:-https://storage.yandexcloud.net}"
BUCKET="${YC_STORAGE_BUCKET:-neon}"
PREFIX="${1:-dev}"          # default: dev/
LOCAL_DIR="${LOCAL_ASSETS_PATH:-./assets}"

echo "→ Syncing s3://${BUCKET}/${PREFIX}/ → ${LOCAL_DIR}/"

mkdir -p "${LOCAL_DIR}"

if [[ -n "${YC_STORAGE_ACCESS_KEY:-}" && -n "${YC_STORAGE_SECRET_KEY:-}" ]]; then
  export AWS_ACCESS_KEY_ID="${YC_STORAGE_ACCESS_KEY}"
  export AWS_SECRET_ACCESS_KEY="${YC_STORAGE_SECRET_KEY}"
  aws s3 sync "s3://${BUCKET}/${PREFIX}/" "${LOCAL_DIR}/" \
    --endpoint-url "${ENDPOINT}" \
    --region ru-central1
else
  # fallback to named profile
  aws s3 sync "s3://${BUCKET}/${PREFIX}/" "${LOCAL_DIR}/" \
    --endpoint-url "${ENDPOINT}" \
    --profile neon \
    --region ru-central1
fi

echo "✓ Done"
