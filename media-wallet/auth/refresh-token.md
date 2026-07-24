# Refresh Wallet CSAT API

## Overview

The **Refresh Wallet CSAT API** allows your application to refresh a user's CSAT using a valid refresh token.

This endpoint is used when:

* The user's current CSAT is expired or about to expire
* You want to obtain a new CSAT token along with updated concurrency limits

---

## Endpoint

```http
POST /wlt/refresh/csat
```

---

## Authentication

This API requires the user to be authenticated with a valid **refresh token**.

Include the token in the request body.

---

## Required Headers

| Header       | Value            |
| ------------ | ---------------- |
| Content-Type | application/json |
| Accept       | application/json |

---

## Request Body

### Fields

| Field                  | Required | Description                                                                             |
|------------------------|----------|-----------------------------------------------------------------------------------------|
| refresh_token          | Yes      | CSAT refresh token issued earlier                                                       |
| nonce                  | Yes      | Unique value binding this refresh to the device_id                                      |
| exp                    | No       | Token expiration in seconds (default 2 weeks)                                           |
| include_asset_claims   | No       | If `true`, include any pending entitlements -- see [below](#optimistic-access-to-media) |
| asset_claims           | No       | Signed claim token(s) to include directly -- see [below](#optimistic-access-to-media)   |


### Example Request

```json
{
  "refresh_token": "eyJ1c...",
  "nonce": "unique-device-id"
}
```

### Optimistic Access to Media

If the user has any asynchronous [Entitlement Creations](../purchase/entitlements/create.md) in flight,
they can get immediate access to that media.

To enable this feature, after a new entitlement, initiate a user refresh with 
`include_asset_claims: true` set on the POST body.  This looks up the user's recent 
pending transactions and includes signed assertions in the response token about any it finds.

Have the user start using the fresh CSAT -- these inline claim assertions enable 
immediate playout access to the media.

Only set this flag on a refresh that follows a entitlement/purchase/grant -- not on every routine token refresh.


---

## Curl Example

```bash
curl -X POST "https://<fabric-authority-url>/wlt/refresh/csat" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "refresh_token": "abc123refresh",
    "nonce": "unique-nonce-value"
  }'
```

---

## Response

### Success Response (HTTP 200)

Returned when the CSAT is refreshed successfully.

#### Fields

| Field           | Description                                 |
| --------------- | ------------------------------------------- |
| user_addr       | User wallet address                         |
| token           | Newly issued CSAT token                     |
| refresh_token   | New refresh token                           |
| expires_at      | Expiration time of the token (milliseconds) |
| existing_tokens | List of active tokens for this user         |
| limits          | Token concurrency limits                    |
| message         | Success message                             |
| warning         | Optional warning message                    |
| error           | Optional error message (if any)             |

### Example Success Response

```json
{
  "user_addr": "0xabc123...",
  "token": "new-csat-token",
  "refresh_token": "new-refresh-token",
  "expires_at": 1712345678900,
  "existing_tokens": [],
  "limits": {
    "max_concurrent": 5,
    "current": 2
  },
  "message": "",
  "warning": "",
  "error": ""
}
```

---

### Error Responses

Returned when the refresh token is invalid, expired, or cannot be processed.

#### Example Error Responses

**Bad Request (400)**

```json
{
  "message": "could not decode refresh token",
  "error": "token format invalid"
}
```

```json
{
  "message": "missing nonce"
}
```

```json
{
  "message": "cannot refresh stale token",
  "error": "stored ULID is newer than requested"
}
```

**Unauthorized (401)**

```json
{
  "message": "refresh token has expired (max age 12 months), please re-authenticate"
}
```

**Forbidden (403)**

```json
{
  "message": "invalid nonce, cannot refresh",
  "existing_tokens": [
    {
      "token": "old-token-1",
      "expires_at": 1712345678900
    }
  ]
}
```

---

## Common Error Messages

| Message                                            | Meaning                                              |
| -------------------------------------------------- | ---------------------------------------------------- |
| could not bind request                             | Request JSON is invalid or malformed                 |
| could not decode refresh token                     | Token is invalid or corrupted                        |
| missing nonce                                      | Nonce value is required                              |
| refresh token has expired                          | Token is older than maximum allowed age (12 months)  |
| invalid nonce                                      | Nonce does not match active token                    |
| cannot refresh stale token                         | Token is too old; requires re-authentication         |
| could not make refresh token                       | Server failed to generate a new refresh token        |
| could not validate token                           | Newly generated token could not be validated         |
| sigProvider ulid does not match refresh token ulid | Signature ULID mismatch between old and new token    |
| sigProvider addr does not match refresh token addr | Signature address mismatch between old and new token |
