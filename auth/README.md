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

* [IP/Geo Policy](sample_policies/policy-ip-geo.yaml) -- Demonstrates IP and geolocation-based authorization: validates the token signer, then restricts access by country code, region, client IP (exact or regex), and user agent (exact or regex).
* [Cross-Chain NFT Policy](sample_policies/nft_cross_chain.yml) -- Grants access based on a cross-chain oracle balance check. The `authorizedAssets` list spans multiple chains (Ethereum, Polygon, Eluvio, Solana, Flow); a user must hold at least one token from any listed asset.


## Editor-signed Tokens and Editor-Signed Token Policies

* [Editor-Signed Tokens](editor_signed_tokens.md)
* [Editor-Signed Token Policy](common_policies/editor_signed_policy.yaml) -- Enforces `authorized_meta`, `authorized_files`, `authorized_reps`, and `authorized_offerings` constraints carried in the editor-signed token's context.
