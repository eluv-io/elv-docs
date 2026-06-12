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

| Field            | Required | Description                                                 |
| ---------------- | -------- | ----------------------------------------------------------- |
| transaction.id   | Yes      | Unique payment ID from your payment provider                |
| transaction_type | Yes      | `purchase` or `rental`                                      |
| elv_addr         | Yes      | User wallet address                                         |
| skus             | Yes      | Array of one or more product SKUs being purchased or rented |

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

| Value    | Description              |
| -------- | ------------------------ |
| purchase | Permanent entitlement    |
| rental   | Time-limited entitlement |

---

## Rental Duration (Required for Rentals)

If `transaction_type = rental`, include a `rental_duration` object with these optional fields:

| Field             | Type    | Description                                                                                      |
| ----------------- | ------- | ------------------------------------------------------------------------------------------------ |
| `start_timestamp` | string  | ISO8601 timestamp: when the rental window opens. Default is now                                  |
| `start_watch`     | integer | Seconds after `start_timestamp` the user has to begin watching. Default `2592000` = 30 days      |
| `active_for`      | integer | Seconds of playback access after the user starts watching. Default `172800` = 2 days             |

**Example:** `start_timestamp` = `"2026-03-11T21:10:00Z"`, `start_watch` = `2592000` (30 days), `active_for` = `172800` (2 days)
means the user has until April 10 9:10 PM UTC to start watching, and once they begin they have 2 days to finish.

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
      "start_watch":     172800,
      "active_for":      2592000
    },
    "elv_addr": "0xabc123...",
    "skus": ["<sku-1>"],
    "metadata": {
      "description": "Example rental"
    }
  }'
```

---

# Response

## Success Response (HTTP 200)

Returned when the payment is accepted and the entitlement is created.

### Fields

| Field          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| message        | Success message                                                           |
| trans_id       | Full transaction ID - used with the watch_start and entitlement list APIs |
| tenant_revenue | Revenue allocated to the tenant                                           |
| platform_fee   | Platform fee amount                                                       |
| user_addr      | User wallet address                                                       |
| tokens         | All tokens minted in this transaction                                     |

### Example Success Response

```json
{
  "message": "3pp payment processed successfully",
  "trans_id": "3pp:<tenantId>:pi_3pp_1234",
  "tenant_revenue": 2.75,
  "platform_fee": 0.51,
  "user_addr": "0xabc123...",
  "tokens": [
    {
      "contract_addr": "0xcontract123...",
      "token_id": "551"
    }
  ]
}
```

---

## Error Response (HTTP 400)

Returned when the request is invalid or cannot be processed.

### Example Error Response

```json
{
  "message": "Invalid transaction type",
  "error": {
    "details": "transaction_type must be purchase or rental"
  }
}
```

---

## Common Error Messages

| Message                           | Meaning                                  |
| --------------------------------- | ---------------------------------------- |
| Invalid request                   | Request body is malformed                |
| Invalid user address              | `elv_addr` is not a valid wallet address |
| No marketplace for SKU            | SKU is not recognized                    |
| Marketplace does not match tenant | SKU does not belong to your tenant       |
| Refund not supported yet          | Refund transaction type is not available |
| Invalid transaction type          | Must be `purchase` or `rental`           |
