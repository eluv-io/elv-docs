#!/usr/bin/env bash
#
# create-checkout.sh — create a hosted checkout session
#
# Usage:
#   ADMIN_TOKEN=<token> SKU=<sku> ELV_ADDR=<addr> ./create-checkout.sh
#
# Output is saved to /tmp/extcheckout.last for use by poll-status.sh

FABRIC_URL="${FABRIC_URL:-https://as.glb.contentfabric.io/as}"
TENANT_ID="${TENANT_ID:?TENANT_ID is required}"
ADMIN_TOKEN="${ADMIN_TOKEN:?ADMIN_TOKEN is required}"
SKU="${SKU:?SKU is required}"
ELV_ADDR="${ELV_ADDR:?ELV_ADDR is required}"
SUCCESS_URL="${SUCCESS_URL:-https://example.com/success}"
CANCEL_URL="${CANCEL_URL:-https://example.com/cancel}"
COUNTRY_CODE="${COUNTRY_CODE:-US}"
EMAIL="${EMAIL:-}"

curl -s -X POST -H 'Content-Type: application/json' -H 'Accept: application/json' \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  "${FABRIC_URL}/tnt/${TENANT_ID}/checkout/external" \
  -d "$(jq -n \
    --arg sku        "${SKU}" \
    --arg elv_addr   "${ELV_ADDR}" \
    --arg success    "${SUCCESS_URL}" \
    --arg cancel     "${CANCEL_URL}" \
    --arg country    "${COUNTRY_CODE}" \
    --arg email      "${EMAIL}" \
    '{sku:$sku, elv_addr:$elv_addr, success_url:$success, cancel_url:$cancel, country_code:$country, email:$email}')" \
  | tee /tmp/extcheckout.last \
  | jq

echo ""
echo "checkout_id: $(jq -r .checkout_id /tmp/extcheckout.last)"
echo "checkout_url: $(jq -r .checkout_url /tmp/extcheckout.last)"
echo ""
echo "Redirect the user to the checkout_url above."
echo "Then run poll-status.sh to check for completion."
