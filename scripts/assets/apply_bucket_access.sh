#!/usr/bin/env bash
# Apply NAEON neon bucket access: CORS + public GET on generations/ and releases/.
# Needs storage.admin on the bucket (storage.editor is not enough for PutBucketPolicy).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export PATH="$HOME/Library/Python/3.9/bin:$PATH"
ENDPOINT="${YC_STORAGE_ENDPOINT:-https://storage.yandexcloud.net}"
PROFILE="${AWS_PROFILE:-neon}"
BUCKET="${YC_STORAGE_BUCKET:-neon}"

echo "→ CORS"
aws s3api put-bucket-cors \
  --bucket "$BUCKET" \
  --cors-configuration "file://$ROOT/scripts/assets/neon-cors.json" \
  --endpoint-url "$ENDPOINT" \
  --profile "$PROFILE"
aws s3api get-bucket-cors --bucket "$BUCKET" --endpoint-url "$ENDPOINT" --profile "$PROFILE" >/dev/null
echo "  CORS ok (GET/HEAD *)"

echo "→ bucket policy (public GET generations/* + releases/*)"
if aws s3api put-bucket-policy \
  --bucket "$BUCKET" \
  --policy "file://$ROOT/scripts/assets/neon-bucket-policy.json" \
  --endpoint-url "$ENDPOINT" \
  --profile "$PROFILE"; then
  echo "  policy applied"
  echo "  public: https://storage.yandexcloud.net/${BUCKET}/generations/"
  echo "  public: https://storage.yandexcloud.net/${BUCKET}/releases/"
else
  echo "  DENIED — SA neon-access needs storage.admin on bucket ${BUCKET}"
  echo "  Console: Object Storage → neon → Права доступа →"
  echo "    1) сервисный аккаунт neon-access (ajeesl2i6831roe889nl) → роль storage.admin"
  echo "    2) либо вставьте scripts/assets/neon-bucket-policy.json как политику бакета"
  exit 2
fi

echo "→ probe anonymous GET"
code=$(curl -sI --max-time 15 "https://storage.yandexcloud.net/${BUCKET}/generations/rendered/ypNsZ.jpg" | awk "NR==1{print \$2}")
echo "  generations sample HTTP $code (expect 200 after policy)"
