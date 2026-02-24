# Revoke Entitlement API

## Overview

The **Revoke Entitlement API** allows a tenant to transfer an NFT token from one address to another, effectively revoking a user's entitlement.

This endpoint is used when:

* A user's entitlement needs to be revoked or reclaimed
* Administrative action is required to correct or remove an entitlement

---

## Endpoint

**POST**

```
/tnt/:tid/transfer/token
```

---

## Authentication

This API requires **TenantAuth** authorization -- a Tenant or Content admin CSAT

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
| Authorization | Bearer <token>   |

---

## Request Body

### Required Fields

| Field     | Type   | Required | Description                                    |
| --------- | ------ | -------- | ---------------------------------------------- |
| nft_addr  | string | Yes      | Contract address of the NFT                    |
| token_id  | string | Yes      | Token ID of the NFT to transfer                |
| from_addr | string | Yes      | Current owner address (must be the actual owner)|
| to_addr   | string | Yes      | Destination address to transfer the token to   |

---

## Curl Example

```bash
curl -X POST "https://<fabric-authority-url>/tnt/<tid>/transfer/token" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "nft_addr": "0x1234",
    "token_id": "777",
    "from_addr": "0x9876",
    "to_addr": "0xABCD"
  }'
```

---

# Response

## Success Response (HTTP 200)

Returned when the token transfer is completed successfully.

### Fields

| Field            | Type    | Description                                     |
| ---------------- | ------- | ----------------------------------------------- |
| success          | boolean | `true` when the transfer completed successfully |
| request          | object  | Echo of the original request parameters         |
| request.nft_addr | string  | Contract address of the NFT                     |
| request.token_id | string  | Token ID that was transferred                   |
| request.from_addr| string  | Address the token was transferred from          |
| request.to_addr  | string  | Address the token was transferred to            |

### Example Success Response

```json
{
  "success": true,
  "request": {
    "nft_addr": "0x4ada3485494889cc72671af3c23d6202ffa8518f",
    "token_id": "78",
    "from_addr": "0x80ff0c9b1e7aa9a3c4b665e3a601d648d402bd7e",
    "to_addr": "0x0000000000000000000000000000000000000001"
  }
}
```

---

## Error Response

Returned when the transfer cannot be completed.

### Fields

| Field   | Type    | Description                          |
| ------- | ------- | ------------------------------------ |
| success | boolean | `false` when the transfer failed     |
| error   | string  | Description of what went wrong       |

### Example Error Response

```json
{
  "success": false,
  "error": "error transferring nft tokenId: provided fromAddr 0x0000000000000000000000000000000000000001 is not owner of tokenId 78, actual owner = 0x80ff0c9b1e7aa9a3c4b665e3a601d60000000000"
}
```

---

## Common Error Messages

| Message                                      | Meaning                                              |
| -------------------------------------------- | ---------------------------------------------------- |
| provided fromAddr is not owner of tokenId    | The `from_addr` does not match the actual token owner |
