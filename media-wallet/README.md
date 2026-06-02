# Media Wallet

The Eluvio **Media Wallet** covers the user-facing content access layer of the Content Fabric — authentication, content browsing, and purchase.

Full API reference documentation is published at: **[docs.eluv.io](https://docs.eluv.io/)** under **Media Wallet API**, which covers
the basics of

### Authentication

How to obtain and use client-signed access tokens (CSATs) for user sessions, including wallet address resolution, token scoping, and token refresh.

### APIs

Endpoints for media properties, pages, sections, and media items including:

- Listing and filtering content
- Resolving section content with permission and purchase metadata
- Sidebar and multiview
- Playout options and live video

### Schemas

Data shapes for all request and response objects, including `MediaProperty`, `MediaSection`, `MediaItem`, `PermissionSet`, and related types.

---

## Purchase & Access

The Media Wallet APIs surface which content is gated and what a user needs  to gain access.

**[Purchase & Entitlement Paths](purchase/README.md)** covers a variety of supported ways to grant content access, including:

- [Hosted Checkout](purchase/hosted-checkout/README.md) — Eluvio-hosted Stripe checkout, no payment UI required
- [Entitlements API](purchase/entitlements/README.md) — direct entitlement creation from any payment system
