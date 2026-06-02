# Entitlements API

Use this path to grant a user access to content by submitting a fulfilled purchase or rental directly to the Eluvio
Authority. Supports purchase and rental types with fine-grained rental window control.

---

## Overview

```mermaid
sequenceDiagram
    participant User
    participant TenantApp
    participant PaymentProvider
    participant FabricAPI

    User->>TenantApp: Initiates purchase or rental
    TenantApp->>PaymentProvider: Process payment
    PaymentProvider-->>TenantApp: Payment confirmed
    TenantApp->>FabricAPI: POST /tnt/:tid/entitlement/add<br/>(admin token, transaction, SKUs[], elv_addr)
    FabricAPI->>FabricAPI: Mint NFT token
    FabricAPI-->>TenantApp: {confirmation_id, token_id, token_addr}
    TenantApp->>User: Confirm access granted
```

---

## Endpoints

| Operation | Endpoint |
|---|---|
| Create entitlement | `POST /tnt/:tid/entitlement/add` |
| List entitlements | `POST /tnt/:tid/entitlement/list/:addr` |
| Revoke by token | `POST /tnt/:tid/entitlement/revoke` |
| Revoke by SKU | `POST /tnt/:tid/entitlement/revoke_by_sku` |

**Authentication:** Tenant admin bearer token for all operations.

---

## When to Use

- Payment is processed outside Eluvio (any provider)
- You need rental window control (`start_watch`, `active_for`)
- You want entitlement records for reporting and revocation
- You are integrating with a distributor or affiliate system

---

## Supported Transaction Types

| Type | Description |
|---|---|
| `purchase` | Permanent entitlement |
| `rental` | Time-limited entitlement with configurable window |

---

 Full API reference:

pull in from vub docs tree/main/doc
