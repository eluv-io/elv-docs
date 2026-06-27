# Playout Authorization Errors

The playout endpoint (`/q/:objectId/rep/playout/:offering/options.json`) returns **HTTP 403** for
all authorization failures. Two distinct failure types can occur, and they produce different error
bodies that clients can use to surface the right message to users.

---

## Geo-Restriction

The request originated from a region not permitted by the content's geo policy. The error is
produced before policy evaluation and always includes an `"op": "authorization"` entry with a
`"location"` field containing the detected country code.

```json
{
  "errors": [
    {
      "op": "authorization",
      "kind": "permission denied",
      "reason": "client geo location not authorized",
      "location": "SE"
    }
  ]
}
```

| Field      | Value                                  |
|------------|----------------------------------------|
| `op`       | `"authorization"`                      |
| `reason`   | `"client geo location not authorized"` |
| `location` | ISO country code of the request origin |

**Suggested user message:** "This content is not available in your region."

---

## No Entitlement

The user has no active subscription, purchase, or rental for this content. The error originates
from the policy or grant layer and contains an `"op": "Allow"` entry whose cause chain reaches
`"enforcePolicy"` or `"isAllowed"`.

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
              "kind": "permission denied"
            }
          ]
        }
      }
    }
  ]
}
```

| Field  | Value                |
|--------|----------------------|
| `op`   | `"Allow"`            |
| `kind` | `"permission denied"`|

**Suggested user message:** "A subscription or purchase is required to watch this title."

---

## Distinguishing the Two

Check the top-level `errors[0].op` field:

| `op` value        | Meaning            | Action                         |
|-------------------|--------------------|--------------------------------|
| `"authorization"` | Geo-blocked        | Show regional availability message |
| `"Allow"`         | No entitlement     | Show subscription/purchase CTA |

The `"location"` field is only present on geo errors and can be used to name the region if
needed. It is absent on entitlement errors.

```javascript
const err = response.errors?.[0];
if (err?.op === "authorization" && err?.reason?.includes("geo")) {
  // geo-blocked
} else if (err?.op === "Allow") {
  // no entitlement
}
```
