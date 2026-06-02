# Revoke Single Entitlement

## Overview

The **Tenant Entitlement Revoke API** allows a tenant administrator to revoke a user's NFT-based entitlement.

---

## Endpoint

```
POST /tnt/:tid/entitlement/revoke
```

---

## Authentication

This API requires **TenantAuth** authorization -- a Tenant or Content admin CSAT.

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

### Required Fields

| Field     | Type   | Required | Description                                     |
| --------- | ------ | -------- | ----------------------------------------------- |
| nft_addr  | string | Yes      | Contract address of the NFT                     |
| token_id  | string | Yes      | Token ID of the NFT to transfer                 |
| from_addr | string | Yes      | Current owner address (must be the actual owner) |

---

## Curl Example

```bash
curl -X POST "https://<fabric-authority-url>/tnt/<tenantId>/entitlement/revoke" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "nft_addr": "0xcontract123...",
    "token_id": "777",
    "from_addr": "0xowner123..."
  }'
```

---

# Response

## Success Response (HTTP 200)

Returned when the token transfer is completed successfully.

### Fields

| Field             | Type    | Description                                      |
| ----------------- | ------- | ------------------------------------------------ |
| success           | boolean | `true` when the transfer completed successfully  |
| request           | object  | Echo of the original request parameters          |
| request.nft_addr  | string  | Contract address of the NFT                      |
| request.token_id  | string  | Token ID that was transferred                    |
| request.from_addr | string  | Address the token was transferred from           |
| request.to_addr   | string  | Address the token was transferred to             |

### Example Success Response

```json
{
  "success": true,
  "request": {
    "nft_addr": "0xcontract123...",
    "token_id": "78",
    "from_addr": "0xowner123..."
  }
}
```

---

## Error Response

Returned when the transfer cannot be completed.

### Fields

| Field   | Type    | Description                      |
| ------- | ------- | -------------------------------- |
| success | boolean | `false` when the transfer failed |
| error   | string  | Description of what went wrong   |

---

## Common Error Messages

| Message                                     | Meaning                                                                 |
| ------------------------------------------- | ----------------------------------------------------------------------- |
| `cannot find minter keys config`            | The tenant does not have a configured minter/proxy owner setup          |
| `cannot find proxyOwner ikmskey`            | The tenant configuration exists but does not define a proxy owner       |
| `invalid request body: <details>`           | The JSON request body is malformed or missing required fields           |
| `invalid 'from' address`                    | The provided `from_addr` is not a valid Ethereum address                |
| `invalid 'to' address`                      | The internally assigned burn address failed validation (unexpected)     |
| `invalid NFT address`                       | The provided `nft_addr` is not a valid Ethereum contract address        |
| `error transferring nft tokenId: <details>` | The blockchain transfer execution failed (permission, ownership, etc.)  |
