#!/usr/bin/env bash
#
# poll-status.sh — poll a hosted checkout session until complete or failed
#
# Usage (reads checkout_id from /tmp/extcheckout.last if not set):
#   TOKEN=<admin-or-user-token> ./poll-status.sh
#   TOKEN=<token> CHECKOUT_ID=elvs_xxx ./poll-status.sh

FABRIC_URL="${FABRIC_URL:-https://as.glb.contentfabric.io/as}"
TENANT_ID="${TENANT_ID:?TENANT_ID is required}"
TOKEN="${TOKEN:?TOKEN is required (admin or user token)}"

CHECKOUT_ID="${CHECKOUT_ID:-}"
if [[ -z "${CHECKOUT_ID}" && -f /tmp/extcheckout.last ]]; then
  CHECKOUT_ID="$(jq -r '.checkout_id // empty' /tmp/extcheckout.last 2>/dev/null || true)"
fi

POLL_INTERVAL="${POLL_INTERVAL:-2}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-30}"

if [[ -z "${CHECKOUT_ID}" ]]; then
  echo "Error: CHECKOUT_ID not set and could not read checkout_id from /tmp/extcheckout.last." >&2
  exit 1
fi

echo "Polling ${CHECKOUT_ID} ..."

attempt=0
while (( attempt < MAX_ATTEMPTS )); do
  response=$(curl -s -H 'Content-Type: application/json' -H 'Accept: application/json' \
    -H "Authorization: Bearer ${TOKEN}" \
    "${FABRIC_URL}/tnt/${TENANT_ID}/checkout/external/${CHECKOUT_ID}")

  status=$(echo "${response}" | jq -r .status)
  echo "[$(( ++attempt ))/${MAX_ATTEMPTS}] status: ${status}"

  if [[ "${status}" == "complete" || "${status}" == "failed" ]]; then
    echo ""
    echo "${response}" | jq
    exit 0
  fi

  sleep "${POLL_INTERVAL}"
done

echo "Timed out waiting for checkout to complete." >&2
exit 1
