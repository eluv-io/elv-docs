# List Entitlement API

## Overview

The **Entitlement List API** allows a client application to retrieve a user's NFT-based entitlements for a specific tenant.

An entitlement represents access granted via an NFT (for example: rental, purchase, access pass, or digital asset ownership).

Returns a paginated list of entitlement actions for a user within a tenant.

Each record represents a blockchain entitlement operation (e.g. mint, rent, claim, burn) and may include:

* Operation type (op)
* Transaction ID
* Status
* Minted NFTs
* Product details
* Purchase metadata (if available)
* Rental lifecycle data (state, expiry, watch start) -- for rental entries only

---

## Endpoint

```
POST /tnt/:tid/entitlement/list/:addr
```

---

## Authentication

This API requires **TenantAuth** authorization -- a Tenant or Content admin CSAT.

Include in header:

```
Authorization: Bearer <access_token>
```

---

## Path Parameters

| Name   | Type   | Required | Description         |
| ------ | ------ | -------- | ------------------- |
| `tid`  | string | Yes      | Tenant ID           |
| `addr` | string | Yes      | User wallet address |

---

## Query Parameters

| Name       | Type    | Required | Description                                      |
| ---------- | ------- | -------- | ------------------------------------------------ |
| `offset`   | integer | No       | Paging offset (default: 0)                       |
| `count`    | integer | No       | Maximum results to return                        |
| `start_ts` | integer | No       | Start time (Unix timestamp). Default: 0          |
| `end_ts`   | integer | No       | End time (Unix timestamp). Default: current time |

## Request Body

| Field             | Type            | Required | Description                                                                        |
| ----------------- | --------------- | -------- | ---------------------------------------------------------------------------------- |
| `include_revoked` | bool            | No       | Whether to include fully-revoked entitlements; default false                       |
| `skus`            | array of string | No       | If non-empty, only return entitlements containing any of these SKUs                |
| `rental_states`   | array of string | No       | Filter by rental state (`upcoming`, `playable`, `expired`)                         |
| `actions`         | array of string | No       | Restrict to specific operation types (e.g. `nft-rent`, `nft-buy`); omit for all    |

---

## Example Request

```bash
# List all entitlements, with paging offset and count
curl -X POST "https://<fabric-authority-url>/tnt/<tenantId>/entitlement/list/<addr>?offset=0&count=5" \
  -H "Authorization: Bearer <tenant-token>" \
  -H "Content-Type: application/json" \
  -d '{}'
```

```bash
# Filter by one or more SKUs
curl -X POST "https://<fabric-authority-url>/tnt/<tenantId>/entitlement/list/<addr>" \
  -H "Authorization: Bearer <tenant-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "skus": ["<sku-1>", "<sku-2>"]
  }'
```

---

## Example Response

```json
{
  "contents": [
    {
      "tenant": "<tenantId>",
      "site": "<siteId>",
      "wallet_addr": "0xabc123...",
      "op": "nft-rent",
      "trans_id": "3pp:<tenantId>:pi_3pp_xyz",
      "status": "complete",
      "timestamp": 1765832948,
      "num_minted": 1,
      "num_burned": 0,
      "metadata": {
        "customer_id": "cus_abc123",
        "description": "Example rental",
        "title_iq": "iq__abc123",
        "title": "Example Title",
        "title_type": "feature",
        "ip_title_id": "TVOD-001",
        "billing_ids": ["BILLING_001"]
      },
      "status_op": "nft-rent:<siteId>:pi_3pp_xyz",
      "products": [
        {
          "sku": "<sku-1>",
          "quant": 1
        }
      ],
      "minted": [
        {
          "name": "Example Title",
          "contract_addr": "0xcontract123...",
          "token_id": "454"
        }
      ],
      "rental": {
        "state": "playable",
        "start": "2026-05-01T00:00:00Z",
        "expiry": "2026-06-02T00:00:00Z",
        "first_played_at": "2026-05-02T14:30:00Z"
      }
    }
  ],
  "paging": {
    "offset": 0,
    "limit": 1,
    "total": 10,
    "start_ts": 0,
    "end_ts": 1772581531
  }
}
```

---

# Response Fields

## Paging

| Field      | Description                        |
| ---------- | ---------------------------------- |
| `offset`   | Current page offset                |
| `limit`    | Page size                          |
| `total`    | Total matching entitlement records |
| `start_ts` | Start time used                    |
| `end_ts`   | End time used                      |

---

## Entitlement Record (`contents[]`)

| Field         | Description                                                    |
| ------------- | -------------------------------------------------------------- |
| `tenant`      | Tenant ID                                                      |
| `site`        | Site / collection identifier                                   |
| `wallet_addr` | User wallet address                                            |
| `op`          | Operation type (e.g. `nft-rent`, `nft-buy`, `nft-claim`)       |
| `trans_id`    | Transaction ID associated with operation                       |
| `status`      | Operation status (`complete`, etc.)                            |
| `timestamp`   | Unix timestamp of operation                                    |
| `num_minted`  | Number of NFTs minted in this operation                        |
| `num_burned`  | Number of NFTs burned                                          |
| `status_op`   | Composite status string                                        |
| `metadata`    | Purchase and title metadata (if correlated with payment)       |
| `products`    | Products associated with this operation                        |
| `minted`      | NFTs minted during this operation                              |
| `rental`      | Rental lifecycle data -- present only for `nft-rent` entries   |

---

## Minted NFTs (`minted[]`)

| Field           | Description          |
| --------------- | -------------------- |
| `name`          | NFT name             |
| `contract_addr` | NFT contract address |
| `token_id`      | NFT token ID         |

---

## Products (`products[]`)

| Field   | Description |
| ------- | ----------- |
| `sku`   | Product SKU |
| `quant` | Quantity    |

---

## Metadata (`metadata`)

Contains the user-supplied metadata from the entitlement add request, plus title catalog fields when available.
Internal processing fields are excluded.

Standard fields (when payment data is available):

| Field         | Description                                           |
| ------------- | ----------------------------------------------------- |
| `customer_id` | Third-party customer ID (if provided at add time)     |
| `description` | User-supplied description (if provided at add time)   |
| *(custom)*    | Any additional fields passed in `metadata` on add     |

Title catalog fields (when the tenant has a title catalog configured):

| Field         | Description                                             |
| ------------- | ------------------------------------------------------- |
| `title_iq`    | Content fabric `iq__` identifier for the title          |
| `title`       | Display title                                           |
| `title_type`  | Title type (e.g. `feature`, `episode`)                  |
| `ip_title_id` | IP title identifier                                     |
| `billing_ids` | Array of billing IDs associated with the matched SKU(s) |

---

## Rental Object (`rental`)

Present only when `op` is `nft-rent`. Describes the current lifecycle state of the rental.

| Field             | Type              | Description                                                               |
| ----------------- | ----------------- | ------------------------------------------------------------------------- |
| `state`           | string            | See rental states table below                                             |
| `start`           | ISO8601 timestamp | When the rental window opened                                             |
| `expiry`          | ISO8601 timestamp | When the rental expires (computed from watch start + active_for duration) |
| `first_played_at` | ISO8601 timestamp | When the user first began watching; omitted if not yet recorded           |

### Rental States

| State      | Meaning                                                              |
| ---------- | -------------------------------------------------------------------- |
| `upcoming` | Before `start` -- rental purchased but window not yet open           |
| `playable` | Window open and within `active_for` -- user can watch now            |
| `expired`  | Past expiry -- token has been or will be revoked by the sweep        |

`first_played_at` being non-nil indicates the user has started watching.
The `playable` state covers both not-yet-started and in-progress rentals.

### Rental State Filter (`rental_states`)

`entitlement/list` accepts a `rental_states` array in the request body. Three concrete states are accepted:

| Value      | Returns                                            |
| ---------- | -------------------------------------------------- |
| `upcoming` | Rentals not yet open                               |
| `playable` | Window open, within rental period (started or not) |
| `expired`  | Past expiry                                        |

Multiple values may be combined: `["upcoming", "expired"]`.
Omit the field or pass an empty array to return all states.
When a rental state filter is active, non-rental entitlements are excluded from the results.

`expiry` is computed as: `first_played_at + active_for` if `first_played_at` is set;
otherwise `start + start_watch` (offer deadline; expires immediately if playback never starts).

---

## Common Error Messages

| Message              | Meaning                             |
| -------------------- | ----------------------------------- |
| `invalid time range` | The provided timestamps are invalid |
| `invalid address`    | The wallet address is not valid     |
