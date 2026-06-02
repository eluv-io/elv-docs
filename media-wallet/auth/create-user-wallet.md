# Create User Access Wallet API

## Overview

The **Create User Access Wallet API** is required for allowing users to be added into tenant groups in the Fabric core. You can set up such users using a JWT from their login.

---

## Endpoint

```http
POST /tnt/:tid/user/access_wallet
```

---

## Authentication

This API requires a **Tenant admin** token in the request header:

```
Authorization: Bearer <token>
```

---

## Path Parameters

| Name  | Type   | Required | Description |
| ----- | ------ | -------- | ----------- |
| `tid` | string | Yes      | Tenant ID   |

---

## Required Headers

| Header        | Value            |
| ------------- | ---------------- |
| Content-Type  | application/json |
| Accept        | application/json |
| Authorization | Bearer \<token\> |

---

## Request Body

| Field | Required | Description |
| ----- | -------- | ----------- |
| jwt   | Yes      | OAuth JWT   |

### Example Request

```json
{
  "jwt": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

## Curl Example

```bash
curl -X POST "https://<fabric-authority-url>/tnt/<tenantId>/user/access_wallet" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "jwt": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }'
```

---

## Response

### Success Response (HTTP 200)

Returned when the user access wallet is created successfully.

#### Fields

| Field                     | Description                                               |
| ------------------------- | --------------------------------------------------------- |
| user_addr                 | User's wallet address (derived from the JWT)              |
| created_wallet_addr       | Newly created user access wallet address                  |
| faucet.status             | Funding status (`success`, `already-funded`, or `failed`) |
| faucet.error              | Error message if funding failed                           |
| faucet.claimed            | Amount claimed from the faucet (if any)                   |
| faucet.amount_transferred | Amount transferred from the faucet                        |
| faucet.user_balance       | User wallet balance after funding                         |

### Example Success Response

```json
{
  "user_addr": "0xabc123...",
  "created_wallet_addr": "0xdef456...",
  "faucet": {
    "status": "success",
    "error": "",
    "claimed": 1,
    "amount_transferred": 10,
    "user_balance": 50
  }
}
```

---

### Error Responses

Returned when the request is invalid or the admin is not authorized.

**Bad Request (400)**

```json
{
  "message": "invalid request body",
  "error": "json parsing error"
}
```

```json
{
  "message": "invalid tenant_id",
  "error": "cannot parse tenant id"
}
```

**Unauthorized (401)**

```json
{
  "message": "tenant admin, content admin, or admin auth required"
}
```

---

## Common Error Messages

| Message                                             | Meaning                                      |
| --------------------------------------------------- | -------------------------------------------- |
| invalid request body                                | JSON is malformed or missing required fields |
| tenant admin, content admin, or admin auth required | Caller is not authorized for this action     |
| user address not found                              | Could not resolve user wallet address        |
| error creating wallet                               | Wallet creation failed                       |
| failed                                              | Faucet funding failed                        |
