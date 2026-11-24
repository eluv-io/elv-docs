# Create Entitlement API

## Overview

The **Create Entitlement API** allows your application to submit externally processed payments (such as Stripe,
Google Pay, Apple Pay, Roku, etc.) into the Eluvio Content Fabric.

This endpoint is used when:
* Payment is completed outside of the Eluvio no-code "Wallet Client" marketplaces
* You want Fabric to create the correct entitlement for the user, by assigning a token to their address
* You want the transaction recorded for reporting and tracking

### Supported Entitlement Types

* **Purchase**
* **Rental**
* **Subscription** (SVOD)

---

## Endpoint

```
POST /tnt/:tid/entitlement/add
```

---

## Authentication

This API requires **tenant admin authorization**.

Include the bearer token in the request header:

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

### Required Fields

| Field            | Description                                                                                  |
|------------------|----------------------------------------------------------------------------------------------|
| transaction.id   | Unique payment ID from your payment provider                                                 |
| transaction_type | `purchase`, `rental`, `subscription`, `est`, `tvod`, or `svod`                               |
| elv_addr         | User wallet address                                                                          |
| skus or sku      | `skus`: array of one or more product SKUs; or `sku`: a single SKU\*                          |

\* Send exactly one of `skus` or `sku`, not both. A subscription takes exactly one SKU.

transaction_type `est` is an alias for `purchase`, `tvod` an alias for `rental`, `svod` an alias for `subscription`:
- EST: Electronic Sell-Through
- TVOD: Transactional Video On Demand
- SVOD: Subscription Video On Demand

An alias has exactly the same requirements as the type it stands for: `tvod` takes `rental_duration`, and `svod` requires
`subscription_details` with `end_timestamp`.


### Optional Fields

| Field                  | Description                                                                                              |
|------------------------|----------------------------------------------------------------------------------------------------------|
| set_async              | If `true`, do not wait for the mint                                                                      |
| include_pending_claims | If `true`, include `asset_claims` in the response                                                        |
| asset_claimer          | If set, refreshes the given session inline                                                               |
| rental_duration        | Rental timing; see [Rental Duration](#rental-duration-required-for-rentals)                              |
| subscription_details   | Required for subscriptions; see [Subscription Details](#subscription-details-required-for-subscriptions) |
| metadata               | Your own fields, kept for reporting; see [Metadata](#metadata-optional)                                  |
| search_index           | `iq__` ID of a title catalog search index to use instead of the tenant's configured one                  |

See [Async Mode](#async-mode) and [Optimistic Access to Media](#optimistic-access-to-media) for details.

`search_index` may also be passed as a query parameter (`?search_index=iq__...`), which takes precedence over the body
field.

#### asset_claimer object

| Field         | Description                                                     |
|---------------|-----------------------------------------------------------------|
| nonce         | The `device_id`/nonce originally bound to `refresh_token`       |
| refresh_token | An existing CSAT refresh token for the user in `elv_addr`       |

---

## Transaction Object

| Field        | Required | Description                                                  |
| ------------ | -------- | ------------------------------------------------------------ |
| id           | Yes      | Payment identifier (must be globally unique)                 |
| customer_id  | No       | Customer ID from your payment provider                       |
| total        | No       | Total amount paid (if omitted, payment will not be recorded) |
| tax          | No       | Tax amount                                                   |
| currency     | Yes      | Currency code (example: `USD`)                               |
| country_code | Yes      | Country code (example: `US`)                                 |

---

## Transaction Types

| Value        | Description                                                   |
|--------------|---------------------------------------------------------------|
| purchase     | Permanent entitlement                                         |
| rental       | Time-limited entitlement                                      |
| subscription | Entitlement for a subscription period, kept up to date by you |
| est          | Alias for `purchase`                                          |
| tvod         | Alias for `rental`                                            |
| svod         | Alias for `subscription`                                      |

Each SKU's offer type must match: an SVOD SKU (by title catalog offer or marketplace tag) requires `subscription`,
and `subscription` requires an SVOD SKU. Likewise, TVOD requires `rental` and EST requires `purchase`.

---

## Rental Duration (Required for Rentals)

If `transaction_type` is `rental` (or its alias `tvod`), include a `rental_duration` object with these optional fields:

| Field             | Type    | Description                                                                                      |
| ----------------- | ------- | ------------------------------------------------------------------------------------------------ |
| `start_timestamp` | string  | ISO8601 timestamp: when the rental window opens. Default is now                                  |
| `start_watch`     | integer | Seconds after `start_timestamp` the user has to begin watching. Default `2592000` = 30 days      |
| `active_for`      | integer | Seconds of playback access after the user starts watching. Default `172800` = 2 days             |

**Example:** `start_timestamp` = `"2026-03-11T21:10:00Z"`, `start_watch` = `2592000` (30 days), `active_for` = `172800` (2 days)
means the user has until April 10 9:10 PM UTC to start watching, and once they begin they have 2 days to finish.

See [Rental Timing Model](./rental-timing.md) for the Rental Duration and Playback Duration model for rentals

---

## Subscription Details (Required for Subscriptions)

If `transaction_type` is `subscription` (or its alias `svod`), a `subscription_details` object is required:

| Field                 | Type   | Required | Description                                                                         |
| --------------------- | ------ | -------- | ----------------------------------------------------------------------------------- |
| `end_timestamp`       | string | Yes      | ISO8601 timestamp: the end of the paid period                                       |
| `start_timestamp`     | string | No       | ISO8601 timestamp: the start of the paid period. Default is now                     |
| `grace_end_timestamp` | string | No       | ISO8601 timestamp: when access is removed. Default is `end_timestamp` + 7 days      |

* `end_timestamp` must be after `start_timestamp`, and `grace_end_timestamp` must not be before `end_timestamp`.
* A new subscription is always `active`; `status` cannot be set here.
* The user's token is revoked automatically at `grace_end_timestamp`. The grace period lets a renewal arrive late
  without the user losing access.
* Keep the subscription current as your billing system renews, cancels, or refunds it with
  [Update Subscription](./subscription-update.md), using the `trans_id` from this call.
* Resending the same request (same `transaction.id`, `elv_addr`, and SKU) is safe: it returns the existing
  subscription rather than creating another. The same `transaction.id` with a different `elv_addr` or SKU is
  rejected with HTTP 409.

**Example:** `end_timestamp` = `"2026-12-15T00:00:00Z"` with no `grace_end_timestamp` means the subscription is paid
through December 15 and, unless renewed, the user keeps access until December 22.

---

## Metadata (Optional)

You may include arbitrary custom fields for reporting:

```json
{
  "metadata": {
    "title": "Example Title",
    "description": "Example Title rental with promo",
    "affiliate": "Example Partner",
    "discount_desc": "20% off promo applied via discount code",
    "discount_code": "PROMO20"
  }
}
```

---

## Curl Example

```bash
curl -X POST "https://<fabric-authority-url>/tnt/<tenantId>/entitlement/add" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "transaction": {
      "id": "pi_3pp_1234",
      "customer_id": "cus_3pp_1234",
      "total": 3.26,
      "tax": 0.27,
      "currency": "USD",
      "country_code": "US"
    },
    "transaction_type": "rental",
    "rental_duration": {
      "start_timestamp": "2026-03-11T21:10:00Z",
      "start_watch":     2592000,
      "active_for":      172800
    },
    "elv_addr": "0xabc123...",
    "skus": ["<sku-1>"],
    "metadata": {
      "description": "Example rental"
    }
  }'
```

### Subscription Example

```bash
curl -X POST "https://<fabric-authority-url>/tnt/<tenantId>/entitlement/add" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "transaction": {
      "id": "pi_3pp_sub_5678",
      "customer_id": "cus_3pp_1234",
      "total": 9.99,
      "tax": 0.0,
      "currency": "USD",
      "country_code": "US"
    },
    "transaction_type": "subscription",
    "subscription_details": {
      "end_timestamp": "2026-12-15T00:00:00Z"
    },
    "elv_addr": "0xabc123...",
    "skus": ["<svod-sku>"],
    "metadata": {
      "description": "Example monthly subscription"
    }
  }'
```

---

## Async Mode

By default, `entitlement/add` does not respond until the NFT has been minted and the token has been confirmed
to appear in the user's wallet. This can take anywhere from a few seconds up to about a minute.
If your integration would rather not wait for this, set the `set_async` flag to `true` in the request.
In Async Mode, the call will respond immediately with a HTTP 202 and a `poll_id`.  Use this `poll_id` from the
response with [Poll Entitlement Status](#poll-entitlement-status) to check the mint and wallet-confirm progress.

Note: If this exact transaction was already fully processed (e.g. a retried request), it simply returns HTTP 200.


---

# Response

## Success Response (HTTP 200, or HTTP 202 with `set_async`)

Returned when the payment is accepted and the entitlement is created.
Returns HTTP 200, or HTTP 202 when `set_async` is used and the mint has not already completed.

### Fields

| Field                      | Description                                                            |
|----------------------------|------------------------------------------------------------------------|
| message                    | Success message                                                        |
| trans_id                   | Full transaction ID - used with watch_start and entitlement/list       |
| op                         | `nft-buy` for a purchase or subscription, `nft-rent` for a rental      |
| tenant_revenue             | Revenue allocated to the tenant                                        |
| platform_fee               | Platform fee amount                                                    |
| user_addr                  | User wallet address                                                    |
| tokens                     | All tokens minted in this transaction. Absent if `set_async` was used  |
| poll_id                    | Job identifier for [Poll Entitlement Status](#poll-entitlement-status) |
| asset_claims_tokens        | An updated fabric_token and refresh_token for the entitled user        |
| asset_claims               | Pending-entitlement claims, if `include_pending_claims` was set        |
| metadata                   | Title catalog fields for the SKU(s), if a title catalog is configured  |
| subscription               | Subscriptions only: the subscription record, see below                 |

Treat `poll_id` as opaque: pass it back unchanged to [Poll Entitlement Status](#poll-entitlement-status).

See [Optimistic Access to Media](#optimistic-access-to-media) for details on `asset_claims_tokens`.

### Subscription Record

Returned as `subscription` by this call and by [Update Subscription](./subscription-update.md).

| Field          | Description                                                                          |
|----------------|--------------------------------------------------------------------------------------|
| sub_id         | Subscription ID; the same as `trans_id`                                              |
| user_addr      | User wallet address                                                                  |
| tenant         | Tenant ID                                                                            |
| description    | `metadata.description` from the request, or the product name                         |
| status         | `active`, `canceled`, `expired`, or `refunded`                                       |
| start_time     | Start of the paid period                                                             |
| end_time       | End of the paid period                                                               |
| paid_to        | Same as `end_time`                                                                   |
| grace_end      | When access is removed                                                               |
| token_addr     | Contract address of the user's token, once minted                                    |
| token_id       | Token ID of the user's token, once minted                                            |
| token_removed  | When the token was revoked, once it has been                                         |
| attributes     | Details such as `sku`, `customer_id`, and `country`                                  |
| metadata       | Your `metadata` from the request, as you sent it                                     |
| created        | When the record was created                                                          |
| updated        | When the record last changed                                                         |

With `set_async`, `token_addr` and `token_id` are absent until the mint completes.

### Example Success Response

#### Synchronous, HTTP 200

```json
{
  "message": "3pp payment processed successfully",
  "trans_id": "3pp:<tenantId>:pi_3pp_1234",
  "op": "nft-rent",
  "tenant_revenue": 2.75,
  "platform_fee": 0.51,
  "user_addr": "0xabc123...",
  "tokens": [
    {
      "contract_addr": "0xcontract123...",
      "token_id": "551"
    }
  ],
  "poll_id": "0xabc123...:nft-rent:<siteId>:pi_3pp_1234"
}
```

#### Asynchronous, HTTP 202

```json
{
  "message": "3pp payment processed successfully",
  "trans_id": "3pp:<tenantId>:pi_3pp_1234",
  "op": "nft-rent",
  "tenant_revenue": 2.75,
  "platform_fee": 0.51,
  "user_addr": "0xabc123...",
  "poll_id": "0xabc123...:nft-rent:<siteId>:pi_3pp_1234"
}
```

#### Subscription, HTTP 200

```json
{
  "message": "3pp payment processed successfully",
  "trans_id": "3pp:<tenantId>:pi_3pp_sub_5678",
  "op": "nft-buy",
  "tenant_revenue": 9.38,
  "platform_fee": 0.61,
  "user_addr": "0xabc123...",
  "tokens": [
    {
      "contract_addr": "0xcontract456...",
      "token_id": "62"
    }
  ],
  "subscription": {
    "sub_id": "3pp:<tenantId>:pi_3pp_sub_5678",
    "user_addr": "0xabc123...",
    "token_addr": "0xcontract456...",
    "token_id": "62",
    "tenant": "<tenantId>",
    "description": "Example monthly subscription",
    "status": "active",
    "start_time": "2026-11-15T00:00:00Z",
    "end_time": "2026-12-15T00:00:00Z",
    "paid_to": "2026-12-15T00:00:00Z",
    "grace_end": "2026-12-22T00:00:00Z",
    "attributes": {
      "sku": ["<svod-sku>"],
      "customer_id": ["cus_3pp_1234"],
      "country": ["US"]
    },
    "metadata": {
      "description": "Example monthly subscription"
    },
    "created": "2026-11-15T00:00:01Z",
    "updated": "2026-11-15T00:00:01Z"
  },
  "poll_id": "0xabc123...:nft-buy:<siteId>:pi_3pp_sub_5678"
}
```

#### Asynchronous with `asset_claimer`, HTTP 202

```json
{
  "message": "3pp payment processed successfully",
  "trans_id": "3pp:<tenantId>:pi_3pp_1234",
  "op": "nft-rent",
  "tenant_revenue": 2.75,
  "platform_fee": 0.51,
  "user_addr": "0xabc123...",
  "poll_id": "0xabc123...:nft-rent:<siteId>:pi_3pp_1234",
  "asset_claims_tokens": {
    "fabric_token": "new-csat-token",
    "refresh_token": "new-refresh-token"
  }
}
```

---

## Optimistic Access to Media

In asynchronous mode, the entitled asset may not be minted / globally distributed for some time after
`entitlement/add` returns. To allow immediate access to media controlled by these assets,
there are two ways to grant it:

1. Request a [Token Refresh](../../auth/refresh-token.md#optimistic-access-to-media) (or
   [User Sign In](../../auth/user-access-token.md#optimistic-access-to-media) on first
   sign-in) with `include_asset_claims: true`. This detects the user's recent pending purchases and
   grants immediate access to them in the returned token.
2. Set `asset_claimer: { nonce, refresh_token }` on this call, alongside `set_async: true`, using an
   existing session for the same user (`nonce` is the `device_id` originally bound to
   `refresh_token`). This refreshes that session inline and returns the result as
   `asset_claims_tokens: { fabric_token, refresh_token }` -- equivalent to option 1, without a second HTTP round-trip.
   (`fabric_token` here is the same CSAT that option 1 returns as `token` -- named differently because it's nested
   in `asset_claims_tokens` rather than being the top-level refresh/login response.)


---

## Poll Entitlement Status

```
GET /tnt/:tid/entitlement/status/:poll_id
```

Check on mint and wallet-confirm progress for a job started with `set_async`.

#### Authentication

Tenant admin bearer token.

#### Path Parameters

| Parameter | Description                                 |
|-----------|---------------------------------------------|
| `tid`     | Your tenant ID                              |
| `poll_id` | The `poll_id` returned from the create call |

#### Query Parameters

| Parameter  | Required | Description                                                  |
|------------|----------|--------------------------------------------------------------|
| `elv_addr` | Yes      | The user's wallet address, as submitted to `entitlement/add` |

#### Response Fields

| Field         | Description                                                                                                  |
|---------------|--------------------------------------------------------------------------------------------------------------|
| `poll_id`     | Polled job identifier                                                                                        |
| `status`      | Overall status: `"pending"`, `"complete"`, or `"failed"`                                                     |
| `mint_status` | Supplementary detail on `"pending"`/`"failed"`: `"complete"` indicates minted, but not yet wallet-confirmed  |
| `tokens`      | Present once `status` is `"complete"`                                                                        |
| `error`       | Present when `mint_status` is `"failed"`, if a reason is available                                           |

#### Status: pending

```json
{
  "poll_id": "0xabc123...:nft-rent:<siteId>:pi_3pp_1234",
  "status": "pending",
  "mint_status": "pending"
}
```

#### Status: complete

```json
{
  "poll_id": "0xabc123...:nft-rent:<siteId>:pi_3pp_1234",
  "status": "complete",
  "mint_status": "complete",
  "tokens": [
    {
      "contract_addr": "0xcontract123...",
      "token_id": "551"
    }
  ]
}
```

#### Status: failed

```json
{
  "poll_id": "0xabc123...:nft-rent:<siteId>:pi_3pp_1234",
  "status": "failed",
  "mint_status": "failed"
}
```

Poll every 1-2 seconds for up to a minute after `entitlement/add` returns.

---

## Error Response (HTTP 400, 409, 500)

Returned when the request is invalid or cannot be processed: HTTP 400 for an invalid request, 409 when a
subscription's `transaction.id` was already used for a different `elv_addr` or SKU, and 500 for a server failure.

### Example Error Response

```json
{
  "message": "3pp submit failed, error normalizing request",
  "error": {
    "op": "3pp submit failed: invalid user address",
    "kind": "unclassified error"
  }
}
```

---

## Common Error Messages

| Message                                                     | Meaning                                                                     |
|-------------------------------------------------------------|-----------------------------------------------------------------------------|
| Invalid request                                             | Request body is malformed                                                   |
| Invalid user address                                        | `elv_addr` is not a valid wallet address                                    |
| No marketplace for SKU                                      | SKU is not recognized                                                       |
| Marketplace does not match tenant                           | SKU does not belong to your tenant                                          |
| Refund not supported yet                                    | `refund` is not a supported `transaction_type`; see below                   |
| Invalid transaction type                                    | Must be `purchase`, `rental`, or `subscription` (or an alias)               |
| Missing or invalid poll_id                                  | `poll_id` path parameter was omitted or malformed (status API)              |
| Missing or invalid elv_addr query parameter                 | `elv_addr` query parameter was omitted or invalid (status API)              |
| No SKU provided                                             | Neither `sku` nor `skus` was sent                                           |
| Use either 'sku' or 'skus', not both                        | Both `sku` and `skus` were sent                                             |
| All SKUs must belong to the same marketplace                | The SKUs span more than one marketplace                                     |
| SKU ... requires transaction_type ...                       | The SKU's offer type (TVOD, EST, SVOD) needs a different `transaction_type` |
| Invalid search_index                                        | `search_index` is not an `iq__` ID                                          |
| asset_claimer.refresh_token / nonce cannot be empty         | `asset_claimer` was sent without both fields                                |
| subscription_details.end_timestamp is required              | `subscription` was sent without `end_timestamp`                             |
| end_timestamp must be after start_timestamp                 | `end_timestamp` is at or before `start_timestamp` (default now)             |
| grace_end_timestamp must not be before end_timestamp        | `grace_end_timestamp` is earlier than `end_timestamp`                       |
| subscription_details.status cannot be set on create         | Send `status` only to [Update Subscription](./subscription-update.md)       |
| A subscription takes exactly one SKU                        | `subscription` was sent with more than one SKU                              |
| SKU ... is not SVOD                                         | `subscription` was sent with a SKU that is not SVOD                         |
| Transaction id already used for a different elv_addr or sku | HTTP 409: a resent subscription doesn't match the original                  |

Refunds are not submitted through `entitlement/add`, even though some error messages list `refund` as a type. To refund
a subscription, use [Update Subscription](./subscription-update.md) with `status: refunded`. To take back a purchase or
rental, use [Revoke](./revoke.md) or [Revoke by SKU](./revoke-by-sku.md).

