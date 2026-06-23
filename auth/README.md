# Authorization

## Policies

* [Policy Overview](policy/policy-auth.md)
* [Policy YAML Reference](policy/policy-language-reference.yaml)


## Common Policies

Ready-to-use policies for common access control scenarios:

* [Allowed Users Policy](common_policies/allowed_users_policy.yaml) -- Permits access to a fixed list of user addresses;
      also allows node-level decrypt when the token subject matches the node ID.
* [Asset Permissions Policy](common_policies/asset-permissions-policy.yaml) -- Centralized site policy driven by a separate
      permission data model. Supports per-user/group permissions on assets and AV offerings, hierarchical delegation
      (e.g. season --> episodes), time-windowed access, and optional IP/geo restrictions.
* [NFT Owner Policy](common_policies/nft_owner.yaml) -- Grants read access to any owner of a token governed by the
      content object's linked ERC-721 smart contract.
* [NFT Owner + Minter Policy](common_policies/nft_owner_minter.yaml) -- Same as NFT Owner, but also grants access
      to a designated user address (e.g. a minter account).

Annotated examples illustrating specific policy features:

* [IP/Geo Policy](sample_policies/policy-ip-geo.yaml) -- Demonstrates IP and geolocation-based authorization: validates
      the token signer, then restricts access by country code, region, client IP (exact or regex), and user agent (exact or regex).
* [Cross-Chain NFT Policy](sample_policies/nft_cross_chain.yml) -- Grants access based on a cross-chain oracle balance
      check. The `authorizedAssets` list spans multiple chains (Ethereum, Polygon, Eluvio, Solana, Flow); a user
      must hold at least one token from any listed asset.


## Editor-Signed Tokens

With an **Editor-Signed Access Token**, or ESAT, the token is signed directly by a user who holds edit rights on the content. The
fabric node verifies that the token signer matches the policy signer, so the policy does not need to re-validate the
signer. The `ctx` embedded in the token carries fine-grained constraints (`authorized_meta`, `authorized_files`,
etc.) that the policy can inspect.

* [Editor-Signed Tokens](editor_signed_tokens.md)
* [Editor-Signed Token Policy](common_policies/editor_signed_policy.yaml) -- Enforces `authorized_meta`, `authorized_files`,
    `authorized_reps`, and `authorized_offerings` constraints carried in the editor-signed token's context.



## Client-Signed Tokens

A **Client-Signed Access Token**, or CSAT, is a fabric bearer token issued to a regular user by an auth service,
typically obtained by exchanging a trusted JWT. CSATs are used for all media wallet API calls -- entitlements,
playout, user info, etc. See [Media Wallet Authentication](../media-wallet/auth/README.md) for how to obtain one.

### Evaluating CSATs Against a Policy

CSATs can be assessed against authorization policies, with one important difference: the policy itself must validate
the token signer. With ESATs, the fabric node verifies the KMS signature before policy evaluation; with a CSAT the
node does not pre-validate the signer, so the policy's entry point must do it explicitly.

The convention for CSAT policies is:

* Name the top-level entry point rule `authorize` (the `expr` block points to it)
* Include an `isValidTokenSigner` rule that checks `env: token/adr` against a list of authorized signer addresses
* Gate all access through `authorize` so the signer check cannot be bypassed

The [IP/Geo Policy](sample_policies/policy-ip-geo.yaml) and [Cross-Chain NFT Policy](sample_policies/nft_cross_chain.yml) are
both CSAT policy examples and show this pattern in full.


## Token Types and Policy Interaction

Three token types can be assessed against authorization policies. They differ in who signs the token, how the node
validates it, and how policy delegation is wired up.

| | State-Channel Token | Editor-Signed (ESAT) | Client-Signed (CSAT) |
|---|---|---|---|
| **Signed by** | KMS | User with edit rights on the content | Regular client/user |
| **Node pre-validation** | Verifies KMS signature | Enforces token signer == policy signer | Time check only |
| **Policy delegation** | Via `elv:delegation-id` in token `ctx` | Via `elv:delegation-id` in token `ctx` | Via contract metadata `_ELV`) |
| **Policy entry point** | Flexible | Flexible | Must be named `authorize` |
| **Policy validates signer?** | No -- node already did it | No -- node already did it | Yes -- policy must do it explicitly |

## State-Channel Tokens

A **State-Channel Token (SCT)** is created and signed by the KMS, not the user. The flow: the user signs a small
blob and submits it; we verify it, check the user's access rights, resolves blockchain group memberships, and
returns a KMS-signed token. The fabric node trusts the token because it trusts the KMS signature.

Oauth-derived tokens and N-Time Password (NTP)/ticket tokens are both State Channel Tokens sub-types -- they carry
group group membership in `ctx`, which policies can inspect via `env: token/ctx/elv:groups` and `env: token/ctx/elv:groupIds`.

## Editor-Signed Tokens

A **Editor-Signed Access Token (ESAT)** is signed directly by a user who holds edit rights on the content. No KMS
is involved. When used with a delegated policy, the node enforces that the token signer is identical to the policy
signer. Fine-grained constraints (`authorized_meta`, `authorized_files`, `authorized_offerings`, etc.) are embedded
in the token's `ctx` for the policy to inspect.

## Client-Signed Tokens

A **Client-Signed Access Token (CSAT)** is signed by a regular (non-editor) client. The node performs only a time
check -- no cryptographic pre-validation. CSATs are used for all media wallet API calls (entitlements, playout, user
info, etc.). See [Media Wallet Authentication](../media-wallet/auth/README.md) for how to obtain one.

