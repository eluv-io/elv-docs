# elv-docs
Documentation

## API Documentation

Detailed API documentation is available in the [`./doc`](./doc) directory.

This folder contains specifications and usage details for the following APIs:

* **Entitlement APIs**
    * `entitlement-create-api.md` – Create entitlements
    * `entitlement-listing-api.md` – List existing entitlements
    * `entitlement-revoke-api.md` – Revoke entitlements

* **Playout APIs**
    * `playout-clear-api.md` – Clear (non-DRM) playout
    * `playout-drm-api.md` – DRM-protected playout


* **User APIs**
    * `user-access-token-api.md` – Generate user access tokens

For implementation details, request/response formats, and example payloads, refer to the respective markdown files inside the `doc/` directory.

---

## Authorization

### Policies

* [Policy Overview](auth/policy/policy-auth.md)
* [Policy YAML Reference](auth/policy/policy-language-reference.yaml)


### Tokens

* [Editor-Signed Tokens](auth/editor_signed_tokens.md)
* [Editor-Signed Tokens Example Policy](auth/common_policies/editor_signed_policy.yaml)

