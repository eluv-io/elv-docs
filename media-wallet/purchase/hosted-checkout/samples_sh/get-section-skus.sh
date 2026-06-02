#!/usr/bin/env bash
#
# get-section-skus.sh — find purchasable SKUs for a property section
#
# Fetches the section's permission_item_ids (section-level and per-content-item),
# then looks them up in the /permissions endpoint to resolve SKU and title.
#
# Usage:
#   USER_TOKEN=<token> PROPERTY_ID=<iq__...> SECTION_ID=<pscm...> ./get-section-skus.sh

FABRIC_URL="${FABRIC_URL:-https://as.glb.contentfabric.io/as}"
USER_TOKEN="${USER_TOKEN:?USER_TOKEN is required}"
PROPERTY_ID="${PROPERTY_ID:?PROPERTY_ID is required}"
SECTION_ID="${SECTION_ID:?SECTION_ID is required}"

echo "Fetching section ${SECTION_ID} for property: ${PROPERTY_ID}"
echo ""

# 1. Fetch the section (limit items to keep response manageable)
section=$(curl -s \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H "Authorization: Bearer ${USER_TOKEN}" \
  "${FABRIC_URL}/mw/properties/${PROPERTY_ID}/sections?content_limit=5" \
  -d "[\"${SECTION_ID}\"]")

# 2. Fetch the permissions map (unwrap permission_auth_state)
permissions=$(curl -s \
  -H 'Accept: application/json' \
  -H "Authorization: Bearer ${USER_TOKEN}" \
  "${FABRIC_URL}/mw/properties/${PROPERTY_ID}/permissions" \
  | jq '.permission_auth_state // .')

# 3. Section-level permission_item_ids
echo "=== Section-level permissions ==="
echo "${section}" | jq -r '
  .contents[0] |
  "behavior: \(.permissions.behavior // "(none)")",
  "permission_item_ids: \(.permissions.permission_item_ids | length) entries",
  "primary_purchase_skus: \((.permissions.primary_purchase_skus // []) | length) entries"
'
echo ""

section_ids=$(echo "${section}" | jq -c '[.contents[0].permissions.permission_item_ids // [] | .[]]')
if [[ "${section_ids}" != "[]" && "${section_ids}" != "null" ]]; then
  echo "--- SKUs for section-level permission items ---"
  echo "${permissions}" | jq --argjson ids "${section_ids}" '
    to_entries[] |
    select(.key as $k | $ids | index($k) != null) |
    {permission_item_id: .key, sku: .value.marketplace_sku, title: .value.title, authorized: .value.authorized}
  '
  echo ""
fi

# 4. Content-item-level permission_item_ids (from media.permissions[] or computed field)
echo "=== Content-item-level permissions (first 5 items) ==="
all_item_ids=$(echo "${section}" | jq -c '
  [
    .contents[0].content[]? |
    (
      (.permission_item_ids // []) +
      ([.media.permissions[]?.permission_item_id] | map(select(. != null)))
    )
  ] | flatten | unique
')

item_count=$(echo "${section}" | jq '.contents[0].content | length')
echo "Content items in response: ${item_count}"
echo "Unique permission_item_ids across items: $(echo "${all_item_ids}" | jq 'length')"
echo ""

if [[ "$(echo "${all_item_ids}" | jq 'length')" -gt 0 ]]; then
  echo "--- SKUs for content-item permission items ---"
  echo "${permissions}" | jq --argjson ids "${all_item_ids}" '
    to_entries[] |
    select(.key as $k | $ids | index($k) != null) |
    {permission_item_id: .key, sku: .value.marketplace_sku, title: .value.title, authorized: .value.authorized}
  '
else
  echo "No permission items found on content items."
fi
