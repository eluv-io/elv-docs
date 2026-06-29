# Playout Authorization Errors

The playout endpoint (`/q/{objectId}/rep/playout/{offering}/options.json`) returns **HTTP 403** for all authorization
failures. When geo-restriction is enforced via a policy, both geo-block and no-entitlement failures share the same
outer error structure. They are distinguished by the `trace` field inside the `Policy.Enforce` cause.

---

## No Entitlement

The user has no active subscription, purchase, or rental for this content. The `trace` shows
entitlement checks (NFT ownership, admin group) failing.

```json
{
  "errors": [
    {
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
                "trace": "fail - policy: ... fail - func: isOwnerOfLinkedNft\n"
              }
            }
          ]
        }
      }
    }
  ]
}
```

**Suggested user message:** "A subscription or purchase is required to watch this title."

---

## Geo-Restriction

The request originated from a blocked region. The `trace` shows `ipGeoLocationProps` returning
the user's country code, which was matched against the blocked list.

```json
{
  "errors": [
    {
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
                "trace": "fail - policy: ... pass - in(US,[US])\n        data - func: ipGeoLocationProps - US\n"
              }
            }
          ]
        }
      }
    }
  ]
}
```

**Suggested user message:** "This content is not available in your region."

---

## Distinguishing the Two

Both errors are HTTP 403 with `op: "Allow"` at the top level. Detect the type by inspecting
the `trace` string inside `errors[0].cause.cause.errors[0].cause.trace`:

| Trace contains                             | Meaning        | Action                             |
|--------------------------------------------|----------------|------------------------------------|
| `ipGeoLocationProps`                       | Geo-blocked    | Show regional availability message |
| `isOwnerOfLinkedNft` / `userIsTenantAdmin` | No entitlement | Show subscription/purchase CTA     |


```javascript
function classifyPlayoutError(response) {
  const trace = response.errors?.[0]
    ?.cause?.cause?.errors?.[0]
    ?.cause?.trace ?? "";

  if (trace.includes("ipGeoLocationProps")) return "geo-blocked";
  if (trace.includes("enforcePolicy"))      return "no-entitlement";
  return "unknown";
}
```
