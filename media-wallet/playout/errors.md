# Playout Authorization Errors

The playout endpoint (`/q/{objectId}/rep/playout/{offering}/options.json`) returns **HTTP 403** for all
authorization failures. There are two variations to disambiguate: geographic restrictions and missing
access pass restrictions.  The error responses share the same outer structure and are distinguished by function
names embedded in the `trace` field inside the `Policy.Enforce` cause.

This document shares these details, and matching JavaScript code to detect them.

---

## No Entitlement -- Missing Access Pass

The user does not own a qualifying NFT. Produced by, for example, `nft_owner.yaml` or `nft_owner_or_admin.yaml`.
The `trace` shows `isOwnerOfLinkedNft` failing.

```json
{
  "errors": [
    {
      "op": "Q.callJPC",
      "kind": "permission denied",
      "cause": {
        "op": "Allow",
        "kind": "permission denied",
        "permissions_error": {
          "op": "Allow",
          "kind": "permission denied",
          "cause": {
            "op": "isAllowed",
            "kind": "permission denied",
            "cause": {
              "errors": [
                {
                  "op": "enforcePolicy",
                  "kind": "permission denied",
                  "cause": {
                    "op": "Policy.Enforce",
                    "kind": "permission denied",
                    "trace": "fail - policy: ... isOwnerOfLinkedNft - 1.8ms\n"
                  }
                }
              ]
            }
          }
        }
      }
    }
  ]
}
```

**Suggested user message:** "A subscription, purchase, or rental is required to watch this title."

To determine which pass to offer, see [Discovering What to Purchase](../purchase/pass-discovery.md).

---

## Geo-Restriction

The request originated from a blocked region. Produced by, for example, a geo policy (e.g. `policy-ip-geo.yaml`)
applied to the content or its associated pass. The `trace` shows `ipGeoLocationProps` returning
the user's country code, matched against the blocked list.

```json
{
  "errors": [
    {
      "op": "Q.callJPC",
      "kind": "permission denied",
      "cause": {
        "op": "Allow",
        "kind": "permission denied",
        "permissions_error": {
          "op": "Allow",
          "kind": "permission denied",
          "cause": {
            "op": "isAllowed",
            "kind": "permission denied",
            "cause": {
              "errors": [
                {
                  "op": "enforcePolicy",
                  "kind": "permission denied",
                  "cause": {
                    "op": "Policy.Enforce",
                    "kind": "permission denied",
                    "trace": "fail - policy: ... ipGeoLocationProps - 13.5µs - US\n"
                  }
                }
              ]
            }
          }
        }
      }
    }
  ]
}
```

**Suggested user message:** "This content is not available in your region."

---

## Distinguishing the Two

Both errors are HTTP 403. The classification signal is function names embedded anywhere in the
error response JSON:

| Signal in response JSON   | Meaning        | Action                             |
|---------------------------|----------------|------------------------------------|
| `"ipGeoLocationProps"`    | Geo-blocked    | Show regional availability message |
| `"isOwnerOfLinkedNft"`    | No entitlement | Show subscription/purchase CTA     |

Geo is checked first because a geo policy on a pass can produce a response that also contains
entitlement markers from the content policy.

```javascript
function classifyPlayoutError(response) {
  const s = JSON.stringify(response);
  if (s.includes("ipGeoLocationProps")) return "geo-blocked";
  if (s.includes("isOwnerOfLinkedNft")) return "no-entitlement";
  return "unknown";
}
```
