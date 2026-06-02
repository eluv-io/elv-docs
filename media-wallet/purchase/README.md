# Purchase & Entitlement Paths

The Eluvio Content Fabric supports several ways for tenants and affiliates to grant users access to content. Each path suits a different integration model.

For Media Wallet API reference (authentication, section/content APIs, schemas), see **[Media Wallet](../README.md)**.

---

## Choosing a Path

| Path | Best for | Who handles payment |
|---|---|---|
| [Hosted Checkout](hosted-checkout/README.md) | Stripe checkout without building payment UI | Eluvio (Stripe-hosted) |
| [Entitlements API](entitlements/README.md) | Fulfillment from any external payment system | Tenant |

---


## Hosted Checkout

Tenant app redirects the user to an Eluvio-hosted Stripe checkout page. On payment completion, the fabric mints an NFT token and the tenant polls for status.

```mermaid
sequenceDiagram
    participant User
    participant TenantApp
    participant FabricAPI
    participant Stripe

    TenantApp->>FabricAPI: POST /tnt/:tid/checkout/external<br/>(admin token, SKU, elv_addr, success/cancel URLs)
    FabricAPI->>Stripe: Create checkout session
    Stripe-->>FabricAPI: session ID + checkout URL
    FabricAPI-->>TenantApp: {checkout_id, checkout_url}
    TenantApp->>User: Redirect to checkout_url
    User->>Stripe: Enter payment details & pay
    Stripe->>User: Redirect to success_url
    Stripe->>FabricAPI: Webhook: payment complete
    FabricAPI->>FabricAPI: Mint NFT token
    TenantApp->>FabricAPI: GET /tnt/:tid/checkout/external/:checkout_id (poll)
    FabricAPI-->>TenantApp: {status: "complete", token_id, token_addr}
```

### Discovering What to Purchase

Before initiating a purchase, your app needs to know which SKU gates the content a user wants to access. Use the Sections API to discover this:

```mermaid
sequenceDiagram
    participant TenantApp
    participant FabricAPI

    TenantApp->>FabricAPI: GET /mw/properties/:propertyId/sections<br/>(user token, section IDs)
    FabricAPI-->>TenantApp: Section content with permission_item_ids<br/>and primary_purchase_options[]{sku, title}
    Note over TenantApp: For sections with behavior="show_purchase":<br/>primary_purchase_options lists SKUs to offer
    TenantApp->>FabricAPI: GET /mw/properties/:propertyId/permissions<br/>(user token)
    FabricAPI-->>TenantApp: {prmo...: {authorized, marketplace_sku, title}}
    Note over TenantApp: Cross-reference to confirm user<br/>does not already own a qualifying pass
```

See [Hosted Checkout — Discovering SKUs](hosted-checkout/README.md#discovering-which-sku-to-purchase) for a worked example.

---

## Entitlements API

Tenant submits a fulfilled purchase or rental directly. Supports purchase and rental types with fine-grained rental window control.

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
    FabricAPI-->>TenantApp: {token_id, token_addr, confirmation_id}
    TenantApp->>User: Confirm access granted
```


