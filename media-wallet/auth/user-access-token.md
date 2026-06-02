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
| Authorization | Bearer \<JWT\>   |
| Content-Type  | application/json |

---

## Request Body

| Field     | Type   | Required | Description                                                                            |
| --------- | ------ | -------- | -------------------------------------------------------------------------------------- |
| tid       | string | Yes      | Tenant ID                                                                              |
| device_id | string | Yes      | Unique identifier for a user/device, to differentiate sessions; minimum 12 characters  |
| ext       | object | No       | Arbitrary metadata fields                                                              |
| exp       | int    | No       | Requested token TTL in seconds; clamped to a maximum of 1209600 (2 weeks)              |

### Example Request Body

```json
{
  "tid": "<tenantId>",
  "device_id": "MyApp-unique_id_for_device-001",
  "ext": {},
  "exp": 86400
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
  "refresh_token": "def50200a1b2c3...",
  "existing_tokens": [
    {
      "user_addr": "0xabc123...",
      "ip_addr": "203.0.113.42",
      "user_agent": "MyApp/1.0",
      "nonce": "MyApp-unique_id_for_device-001",
      "nonce_hash": "a3f1...",
      "issued_at": "2024-01-01T00:00:00Z",
      "expires_at": "2024-01-15T00:00:00Z"
    }
  ],
  "limits": {
    "max_tokens_per_user": 5,
    "allow_empty_nonce": false,
    "issuer": "https://auth.example.com/eluvio"
  }
}
```

---

## Response Fields

### Success (HTTP 200)

| Field           | Type   | Description                                               |
| --------------- | ------ | --------------------------------------------------------- |
| user_addr       | string | Wallet address associated with the user                   |
| sub             | string | Subject identifier from the JWT                           |
| token           | string | Fabric user access token (CSAT)                           |
| refresh_token   | string | Refresh token for renewing the session                    |
| existing_tokens | array  | List of currently active tokens for this user (see below) |
| limits          | object | Token concurrency limits for this user (see below)        |

### Error (HTTP 4xx/5xx)

| Field | Type   | Description                                   |
| ----- | ------ | --------------------------------------------- |
| error | string | Human-readable message describing the failure |

### `existing_tokens` entries

Each entry is an `ActiveTokenDescription`:

| Field      | Type   | Description                                       |
| ---------- | ------ | ------------------------------------------------- |
| user_addr  | string | Wallet address                                    |
| ip_addr    | string | IP address from which the token was issued        |
| user_agent | string | User-agent string from which the token was issued |
| nonce      | string | Device nonce / `device_id`                        |
| nonce_hash | string | Hash of the nonce                                 |
| issued_at  | string | ISO 8601 timestamp when the token was issued      |
| expires_at | string | ISO 8601 timestamp when the token expires         |

### `limits` object

| Field               | Type   | Description                                                          |
| ------------------- | ------ | -------------------------------------------------------------------- |
| max_tokens_per_user | int    | Maximum number of concurrent active tokens allowed                   |
| allow_empty_nonce   | bool   | Whether tokens without a nonce/device_id are allowed — always false  |
| issuer              | string | The trusted issuer configured for this tenant                        |

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
curl -X POST "https://<fabric-authority-url>/wlt/login/jwt/csat" \
  -H "Authorization: Bearer <JWT>" \
  -H "Content-Type: application/json" \
  -d '{
    "tid": "<tenantId>",
    "device_id": "MyApp-unique_id_for_device-001",
    "ext": {}
  }'
```

---

## Notes

* The JWT must be valid and trusted by your tenant configuration
* `device_id` should be a unique device ID / app ID, used for login/playout limits; must be at least 12 characters
* The returned `token` is used as a **UserAuth token** for other APIs
* `refresh_token` may be used to extend the session without re-authentication
* `limits` and `existing_tokens` help enforce session concurrency rules
* The `exp` request field is clamped server-side to a maximum of 1209600 seconds (2 weeks)
