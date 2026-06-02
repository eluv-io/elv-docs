#!/usr/bin/env bash
#
# get-section-skus.sh — fetch a property section and extract purchasable SKUs
#
# For each section with behavior="show_purchase", prints the primary_purchase_skus
# (SKU + title) the user can buy to unlock that section.
#
# Usage:
#   USER_TOKEN=<token> PROPERTY_ID=<iq__...> SECTION_IDS='["pscm..."]' ./get-section-skus.sh

FABRIC_URL="${FABRIC_URL:-https://as.glb.contentfabric.io/as}"
USER_TOKEN="${USER_TOKEN:?USER_TOKEN is required}"
PROPERTY_ID="${PROPERTY_ID:?PROPERTY_ID is required}"
SECTION_IDS="${SECTION_IDS:?SECTION_IDS is required (JSON array of section IDs)}"

echo "Fetching sections for property: ${PROPERTY_ID}"
echo ""

response=$(curl -s \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H "Authorization: Bearer ${USER_TOKEN}" \
  "${FABRIC_URL}/mw/properties/${PROPERTY_ID}/sections" \
  -d "${SECTION_IDS}")

echo "${response}" | jq '
  .contents[] |
  {
    section_id:       .id,
    section_label:    .label,
    behavior:         .permissions.behavior,
    purchase_options: .permissions.primary_purchase_skus
  } |
  select(.purchase_options != null and (.purchase_options | length) > 0)
'

echo ""
echo "--- Content-item level permission_item_ids ---"
echo "${response}" | jq '
  .contents[].content[]? |
  select(.permission_item_ids != null and (.permission_item_ids | length) > 0) |
  {
    media_id:           .media_id,
    permission_item_ids: .permission_item_ids
  }
'
