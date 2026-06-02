#!/usr/bin/env bash
#
# get-section-skus.sh -- find purchasable SKUs for a property section
#
# The sections response includes primary_purchase_skus inline on each gated section or content item
#
# Usage:
#   USER_TOKEN=<token> PROPERTY_ID=<iq__...> SECTION_ID=<pscm...> ./get-section-skus.sh

FABRIC_URL="${FABRIC_URL:-https://as.glb.contentfabric.io/as}"
USER_TOKEN="${USER_TOKEN:?USER_TOKEN is required}"
PROPERTY_ID="${PROPERTY_ID:?PROPERTY_ID is required}"
SECTION_ID="${SECTION_ID:?SECTION_ID is required}"

echo "Fetching section ${SECTION_ID} for property: ${PROPERTY_ID}"
echo ""

section=$(curl -s -H 'Content-Type: application/json' -H 'Accept: application/json' \
  -H "Authorization: Bearer ${USER_TOKEN}" \
  "${FABRIC_URL}/mw/properties/${PROPERTY_ID}/sections?content_limit=5" \
  -d "[\"${SECTION_ID}\"]")

# Section-level purchase SKUs (behavior = show_purchase)
echo "=== Section-level ==="
echo "${section}" | jq '
  .contents[0] | {
    behavior:             .permissions.behavior,
    primary_purchase_skus: .permissions.primary_purchase_skus
  }'
echo ""

# Content-item-level purchase SKUs
echo "=== Content items with primary_purchase_skus ==="
echo "${section}" | jq '
  .contents[0].content[]? |
  select(.primary_purchase_skus != null and (.primary_purchase_skus | length) > 0) |
  {
    media_id:             .media_id,
    title:                .media.title,
    primary_purchase_skus: .primary_purchase_skus
  }'
