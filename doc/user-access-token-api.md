# Generate User Access Token API

## Overview

This API generates a **User Access Token (CSAT)** using a valid JWT.

It is typically used to:

* Exchange a trusted JWT for a Fabric user access token
* Log a user into Fabric
* Retrieve the associated Fabric wallet address
* Enable authenticated API calls (entitlements, playout, etc.)
* Enforce token concurrency limits

This endpoint is part of the **Auth Service**.

---

## Endpoint

**POST**

```
/as/wlt/login/jwt/csat
```

---

## Authentication

This request requires a valid **JWT** in the `Authorization` header.

```
Authorization: Bearer <JWT>
```

The JWT must be issued by a trusted identity provider configured for your tenant.

---

## Request Headers

| Header        | Value            |
| ------------- | ---------------- |
| Authorization | Bearer <JWT>     |
| Content-Type  | application/json |

---

## Request Body

| Field | Type   | Required | Description                                   |
| ----- | ------ | -------- | --------------------------------------------- |
| tid   | string | Yes      | Tenant ID                                     |
| nonce | string | Yes      | Unique nonce per unique user/device session   |
| ext   | object | No       | Optional extension fields (can be empty `{}`) |

### Example Request Body

```json
{
  "tid": "tenant_123",
  "nonce": "test-001-001",
  "ext": {}
}
```

---

# Response

## Success (HTTP 200)

Returns a CSAT (Client Session Access Token) object.

### Example Success Response

```json
{
  "user_addr": "0xabc123...",
  "sub": "user_001",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "existing_tokens": [
    {
      "token_id": "tok_123",
      "created_at": 1734000000
    }
  ],
  "limits": {
    "max_tokens": 3,
    "active_tokens": 1
  },
  "refresh_token": "def50200a1b2c3...",
  "expires_at": 1734012345,
  "message": "Login successful"
}
```

---

## Response Fields

| Field           | Type   | Description                             |
| --------------- | ------ | --------------------------------------- |
| user_addr       | string | Wallet address associated with the user |
| sub             | string | Subject identifier from the JWT         |
| token           | string | Fabric user access token (CSAT)         |
| existing_tokens | array  | List of active tokens for this user     |
| limits          | object | Token concurrency limits for this user  |
| refresh_token   | string | Refresh token for renewing session      |
| expires_at      | int64  | Expiration time (Unix timestamp)        |
| message         | string | Success message (if applicable)         |
| error           | string | Error message (if login failed)         |

---

## Error Response

If authentication fails or request is invalid:

```json
{
  "error": "Invalid JWT token"
}
```

---

## Curl Example

```bash
curl -X POST "https://<fabric-authority-url>/as/wlt/login/jwt/csat" \
  -H "Authorization: Bearer <JWT>" \
  -H "Content-Type: application/json" \
  -d '{
    "tid": "<tenantId>",
    "nonce": "test-001-001",
    "ext": {}
  }'
```

---

## Notes

* The JWT must be valid and trusted by your tenant configuration
* The `nonce` should be a unique session-specific identifier, for example a device ID or app ID, used for login/playout limits
* The returned `token` is used as a **UserAuth token** for other APIs
* `refresh_token` may be used to extend the session without re-authentication
* `limits` and `existing_tokens` help enforce session concurrency rules
* `expires_at` is a Unix timestamp indicating when the token expires

