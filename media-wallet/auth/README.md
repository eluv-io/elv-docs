# Authentication

These APIs cover user session management for tenant-integrated applications: exchanging a trusted JWT for a Fabric user access token (CSAT), refreshing that token without re-login, and managing user access wallets.

---

## Quick Start: Auth Flow

```mermaid
sequenceDiagram
    participant App
    participant IdP as Identity Provider
    participant FabricAPI

    App->>IdP: User authenticates (OAuth / OIDC)
    IdP-->>App: JWT

    App->>FabricAPI: POST /as/wlt/login/jwt/csat (JWT)
    FabricAPI-->>App: CSAT + user_addr + refresh_token

    App->>FabricAPI: POST /tnt/:tid/user/access_wallet (admin token, JWT)
    FabricAPI-->>App: user_access_wallet address
```

The resulting CSAT is the bearer token used for all subsequent entitlement and playout API calls.

---

## APIs

### [Generate User Access Token](./user-access-token.md)

Exchanges a trusted JWT for a Fabric CSAT (Client Signed Access Token).

- Resolves the user's wallet address
- Returns a `refresh_token` for session renewal
- Enforces per-tenant token concurrency limits

### [Refresh Token](./refresh-token.md)

Obtains a new CSAT from an existing refresh token, without requiring the user to re-authenticate.

### [Create User Access Wallet](./create-user-wallet.md)

Provisions an on-chain access wallet for a user and adds them to the tenant's user group. Required before entitlement operations can be performed for a user.

### [Get User Info](./get-user-info.md)

Returns the caller's wallet address, access wallet status, tenant group membership, and admin role flags.
