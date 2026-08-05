#!/usr/bin/env bash
# Upload local ./assets to Yandex Object Storage bucket "neon"
# Requires: aws-cli and either --profile neon or environment variables.

set -euo pipefail

ENDPOINT="${YC_STORAGE_ENDPOINT:-https://storage.yandexcloud.net}"
BUCKET="${YC_STORAGE_BUCKET:-neon}"
PREFIX="${1:-dev}"          # default: dev/
LOCAL_DIR="${LOCAL_ASSETS_PATH:-./assets}"

if [[ ! -d "${LOCAL_DIR}" ]]; then
  echo "Local assets directory not found: ${LOCAL_DIR}"
  exit 1
fi

echo "→ Syncing ${LOCAL_DIR}/ → s3://${BUCKET}/${PREFIX}/"

if [[ -n "${YC_STORAGE_ACCESS_KEY:-}" && -n "${YC_STORAGE_SECRET_KEY:-}" ]]; then
  export AWS_ACCESS_KEY_ID="${YC_STORAGE_ACCESS_KEY}"
  export AWS_SECRET_ACCESS_KEY="${YC_STORAGE_SECRET_KEY}"
  aws s3 sync "${LOCAL_DIR}/" "s3://${BUCKET}/${PREFIX}/" \
    --endpoint-url "${ENDPOINT}" \
    --region ru-central1
else
  aws s3 sync "${LOCAL_DIR}/" "s3://${BUCKET}/${PREFIX}/" \
    --endpoint-url "${ENDPOINT}" \
    --profile neon \
    --region ru-central1
fi

echo "✓ Done"
