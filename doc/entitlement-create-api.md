# Create Entitlement API

## Overview

The **Create Entitlement API** allows your application to submit externally processed payments (such as Stripe, Google Pay, Apple Pay, Roku, etc.) into the Eluvio Content Fabric.

This endpoint is used when:
* Payment is completed outside of the eluvio no-code "Wallet Client" marketplaces
* You want Fabric to create the correct entitlement for the user, by assigning a token to their address
* You want the transaction recorded for reporting and tracking

### Supported Entitlement Types

* **Purchase**
* **Rental**

---

## Endpoint

**POST**

```
/otp/3pp/{tenantId}/payment
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

| Name     | Type   | Required | Description            |
| -------- | ------ | -------- | ---------------------- |
| tenantId | string | Yes      | Your tenant identifier |

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

| Field            | Required | Description                                  |
| ---------------- | -------- | -------------------------------------------- |
| transaction.id   | Yes      | Unique payment ID from your payment provider |
| transaction_type | Yes      | `purchase` or `rental`                       |
| elv_addr         | Yes      | User wallet address                          |
| sku              | Yes      | Product SKU being purchased or rented        |

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

If `transaction_type = rental`, include:

| Field | Description                        |
| ----- | ---------------------------------- |
| start | Rental start time (ISO8601 format) |
| end   | Rental end time (ISO8601 format)   |

---

## Metadata (Optional)

You may include custom fields for reporting:

```json
"metadata": {
  "description": "Promo rental - Percy Jackson"
}
```

---

## Curl Example

```bash
curl -X POST "https://<fabric-authority-url>/otp/3pp/<tenantId>/payment" \
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
      "start": "2025-12-13T18:00:00Z",
      "end": "2025-12-16T18:00:00Z"
    },
    "elv_addr": "0xabc123...",
    "sku": "SKU_ABC_001",
    "metadata": {
      "description": "Test rental - Bumblebee"
    }
  }'
```

---

# Response

## Success Response (HTTP 200)

Returned when the payment is accepted and the entitlement is created.

### Fields

| Field           | Description                          |
| --------------- | ------------------------------------ |
| message         | Success message                      |
| confirmation_id | Confirmation identifier for tracking |
| tenant_revenue  | Revenue allocated to the tenant      |
| platform_fee    | Platform fee amount                  |
| user_addr       | User wallet address                  |

### Example Success Response

```json
{
  "message": "3pp payment processed successfully",
  "confirmation_id": "rent_98765",
  "tenant_revenue": 2.75,
  "platform_fee": 0.51,
  "user_addr": "0xabc123..."
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


