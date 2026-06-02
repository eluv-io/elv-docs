# Media Wallet

The Eluvio Media Wallet covers the user-facing content access layer of the Content Fabric -- authentication, content browsing, and purchase.

Full API reference documentation is published at: [docs.eluv.io](https://docs.eluv.io/) under Media Wallet API, which covers
the basics of:

- Authentication: How to obtain and use client-signed access tokens (CSATs) for user sessions, including wallet address resolution
- APIs: Endpoints for media properties, pages, sections, and media items including:
  - Listing and filtering content
  - Resolving section content with permission and purchase metadata
  - Sidebar and multiview
  - Playout options and live video
- Schemas: Data shapes for all request and response objects

---

## Authentication

[Authentication](auth/README.md) covers user session management for tenant-integrated applications:

- [Generate User Access Token](auth/user-access-token.md) -- exchange a trusted JWT for a Fabric CSAT
- [Refresh Token](auth/refresh-token.md) -- renew a session without re-authentication
- [Create User Access Wallet](auth/create-user-wallet.md) -- provision an on-chain wallet for a user
- [Get User Info](auth/get-user-info.md) -- retrieve wallet status, tenant group membership, and role flags

---

## Purchase & Access

The Media Wallet APIs surface which content is gated and what a user needs to gain access.

[Purchase & Entitlement Paths](purchase/README.md) covers a variety of supported ways to grant content access, including:

- [Hosted Checkout](purchase/hosted-checkout/README.md) -- Eluvio-hosted Stripe checkout, no payment UI required
- [Entitlements API](purchase/entitlements/README.md) -- direct entitlement creation from any payment system

---

## Media Playback

[Media Playback](playout/README.md) covers retrieving playback URLs after entitlement verification:

- [Clear Playback](playout/clear.md) -- non-DRM DASH/HLS URLs for unprotected content
- [DRM Playback](playout/drm.md) -- Widevine-protected DASH URLs with license server for premium content
- [VOD ABR Ladder Specification](playout/abr-ladder.md) -- encoding bandwidth targets across HEVC profiles
