# Revoke Entitlement by SKU

## Overview

The **Tenant Entitlement Revoke by SKU API** allows a tenant administrator to revoke a user's NFT-based entitlement for one or more SKUs in a single call.

---

## Endpoint

```
POST /tnt/:tid/entitlement/revoke_by_sku
```

---

## Authentication

This API requires **TenantAuth** authorization — a Tenant or Content admin CSAT.

Include the bearer token in the request header:

```
Authorization: Bearer <token>
```

---

## Path Parameters

| Name | Type   | Required | Description            |
| ---- | ------ | -------- | ---------------------- |
| tid  | string | Yes      | Your tenant identifier |

---

## Required Headers

| Header        | Value            |
| ------------- | ---------------- |
| Content-Type  | application/json |
| Accept        | application/json |
| Authorization | Bearer \<token\> |

---

## Request Body

Provide either `sku` (single SKU) or `skus` (one or more SKUs). If both are present, `skus` takes precedence.

| Field     | Type            | Required | Description                                      |
| --------- | --------------- | -------- | ------------------------------------------------ |
| sku       | string          | No*      | Single product SKU (use `skus` for multiple)     |
| skus      | array of string | No*      | One or more product SKUs to revoke               |
| from_addr | string          | Yes      | Current owner address (must be the actual owner) |

\* One of `sku` or `skus` is required.

---

## Curl Examples

### Single SKU

```bash
curl -X POST "https://<fabric-authority-url>/tnt/<tenantId>/entitlement/revoke_by_sku" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "sku": "<sku-1>",
    "from_addr": "0xowner123..."
  }'
```

### Multiple SKUs

```bash
curl -X POST "https://<fabric-authority-url>/tnt/<tenantId>/entitlement/revoke_by_sku" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "skus": ["<sku-1>", "<sku-2>"],
    "from_addr": "0xowner123..."
  }'
```

---

## Response

### Success Response

Returned when all requested SKUs are successfully processed.

| Field                   | Type            | Description                                       |
| ----------------------- | --------------- | ------------------------------------------------- |
| wallet_addr             | string          | Wallet address from which the NFT(s) were revoked |
| skus                    | array of string | SKUs that were processed                          |
| revoked                 | array           | List of successfully revoked NFT tokens           |
| revoked[].sku           | string          | SKU associated with this token                    |
| revoked[].contract_addr | string          | Contract address of the revoked NFT               |
| revoked[].token_id      | string          | Token ID of the revoked NFT                       |

---

#### Example Success Response

```json
{
  "wallet_addr": "0xowner123...",
  "skus": ["<sku-1>"],
  "revoked": [
    {
      "sku": "<sku-1>",
      "contract_addr": "0xcontract123...",
      "token_id": "484"
    }
  ]
}
```

#### Example Multi-SKU Success Response

```json
{
  "wallet_addr": "0xowner123...",
  "skus": ["<sku-1>", "<sku-2>"],
  "revoked": [
    {
      "sku": "<sku-1>",
      "contract_addr": "0xcontract123...",
      "token_id": "484"
    },
    {
      "sku": "<sku-2>",
      "contract_addr": "0xcontract456...",
      "token_id": "12"
    }
  ]
}
```

---

### Error / Partial Failure Response

Returned when one or more NFT revocations fail.

| Field                  | Type            | Description                                        |
| ---------------------- | --------------- | -------------------------------------------------- |
| wallet_addr            | string          | Wallet address from which the revoke was attempted |
| skus                   | array of string | SKUs that were processed                           |
| revoked                | array           | List of tokens successfully revoked (may be empty) |
| failed                 | array           | List of tokens that failed to revoke               |
| failed[].sku           | string          | SKU associated with this token                     |
| failed[].contract_addr | string          | Contract address of the NFT that failed            |
| failed[].token_id      | string          | Token ID of the NFT that failed                    |
| failed[].error         | string          | Error message explaining why the revoke failed     |

---

#### Example Failure Response

```json
{
  "wallet_addr": "0xowner123...",
  "skus": ["<sku-1>"],
  "revoked": [],
  "failed": [
    {
      "sku": "<sku-1>",
      "contract_addr": "0xcontract123...",
      "token_id": "484",
      "error": "failed to process NFT Transfer from, err: op [error in ExecWaitTrans] kind [unclassified error] nonce [257] cause [execution reverted]"
    }
  ]
}
```
