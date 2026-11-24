# Update Subscription API

## Overview

The **Update Subscription API** keeps a subscription created with [Create Entitlement](./create.md) in step with
your billing system: renewals, cancellations, expirations, refunds, and your own metadata.

A subscription has three times:

| Time                  | Meaning                                                                    |
| --------------------- | -------------------------------------------------------------------------- |
| `start_timestamp`     | Start of the paid period                                                   |
| `end_timestamp`       | End of the paid period                                                     |
| `grace_end_timestamp` | When the user's token is revoked; default `end_timestamp` + 7 days         |

The token is revoked automatically at `grace_end_timestamp` (checked every few minutes, so allow up to about 10
minutes). Grace applies only while the subscription is `active`: for any other status the token is revoked at
`end_timestamp`, unless you set `grace_end_timestamp` explicitly. An update that ends access now revokes the token
during the call.

Always end a subscription with this API, not with [Revoke](./revoke.md) or [Revoke by SKU](./revoke-by-sku.md):
those remove the token but leave the subscription `active`.

---

## Endpoint

```
POST /tnt/:tid/entitlement/subscription/update
```

---

## Authentication

This API requires **tenant admin authorization**.

```
Authorization: Bearer <token>
```

---

## Path Parameters

| Name  | Type   | Required | Description |
| ----- | ------ | -------- | ----------- |
| `tid` | string | Yes      | Tenant ID   |

---

## Request Body

Only the fields you send are changed.

| Field                 | Type              | Required | Description                                                         |
| --------------------- | ----------------- | -------- | ------------------------------------------------------------------- |
| `trans_id`            | string            | Yes      | The `trans_id` returned by `entitlement/add`                        |
| `status`              | string            | No       | `active`, `canceled`, `expired`, or `refunded`                      |
| `end_timestamp`       | ISO8601 timestamp | No       | New end of the paid period                                          |
| `grace_end_timestamp` | ISO8601 timestamp | No       | When the token is revoked; must not be before the end               |
| `keep_token`          | boolean           | No       | With `status` = `refunded` only: keep the token until the end       |
| `metadata`            | object            | No       | Your metadata; replaces any earlier metadata                        |

`cancelled` is accepted for `canceled`.

---

## Common Updates

| Update                                    | Request                                         | Result                                                         |
| ----------------------------------------- | ----------------------------------------------- | -------------------------------------------------------------- |
| Renew                                     | `end_timestamp`                                 | New end; grace end moves to the new end + 7 days               |
| Cancel (no renewal)                       | `status: canceled`                              | Access continues to the end of the paid period                 |
| Expire now                                | `status: expired`                               | Token revoked immediately                                      |
| Refund                                    | `status: refunded`                              | Token revoked immediately                                      |
| Refund, keep access to the end            | `status: refunded`, `keep_token: true`          | Token revoked at the end of the paid period                    |
| Extend or shorten the grace period        | `grace_end_timestamp`                           | Token revoked at the new time                                  |
| Reactivate                                | `status: active` (optionally `end_timestamp`)   | Grace end returns to the end + 7 days                          |
| Record your own details                   | `metadata`                                      | Stored with the subscription; nothing else changes             |

When you set `status` to `expired` or `refunded` without an `end_timestamp`, the end moves to now. When you send an
`end_timestamp` with a new status, it is used as given.

### After the Token Is Revoked

Once the token has been revoked, the subscription is final: only `metadata` and a late `status: refunded` can be
updated. To entitle the user again, create a new subscription with [Create Entitlement](./create.md).

---

## Example Request

```bash
curl -X POST "https://<fabric-authority-url>/tnt/<tenantId>/entitlement/subscription/update" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "trans_id":      "3pp:<tenantId>:pi_3pp_sub_5678",
    "end_timestamp": "2027-01-15T00:00:00Z",
    "metadata":      { "renewal_invoice": "in_9876" }
  }'
```

---

## Response

### Success (HTTP 200)

Returns the updated [Subscription Record](./create.md#subscription-record).

```json
{
  "message": "success",
  "subscription": {
    "sub_id": "3pp:<tenantId>:pi_3pp_sub_5678",
    "user_addr": "0xabc123...",
    "token_addr": "0xcontract456...",
    "token_id": "62",
    "tenant": "<tenantId>",
    "status": "active",
    "start_time": "2026-11-15T00:00:00Z",
    "end_time": "2027-01-15T00:00:00Z",
    "paid_to": "2027-01-15T00:00:00Z",
    "grace_end": "2027-01-22T00:00:00Z",
    "attributes": {
      "sku": ["<svod-sku>"]
    },
    "metadata": {
      "renewal_invoice": "in_9876"
    },
    "created": "2026-11-15T00:00:01Z",
    "updated": "2026-12-14T09:12:40Z"
  }
}
```

If an update ends access now but revoking the token fails, the update is still saved and the token is revoked
automatically shortly after. The `message` then begins with `updated; token revoke pending`.

### Errors

Errors are returned as `{"error": "<message>"}`. For the invalid-value errors, the message is embedded in a longer
string, so match on the text in the table rather than the whole string:

```json
{
  "error": "op [Resolve] kind [invalid] reason [keep_token only applies to status refunded]"
}
```

| HTTP | Message                                                                               | Meaning                                                        |
| ---- | ------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| 400  | `trans_id is required`                                                                | `trans_id` was omitted                                         |
| 400  | `invalid request body: ...`                                                           | The body is not valid JSON or a field has the wrong type       |
| 404  | `no subscription entitlement for trans_id`                                            | No subscription with that `trans_id` for this tenant           |
| 400  | `invalid status: must be active, canceled, expired, or refunded`                      | Unknown `status`                                               |
| 400  | `keep_token only applies to status refunded`                                          | `keep_token` sent without `status: refunded`                   |
| 400  | `end_timestamp must be after the subscription start`                                  | `end_timestamp` is at or before the start                      |
| 400  | `grace_end_timestamp must not be before the end`                                      | `grace_end_timestamp` is earlier than the end                  |
| 400  | `subscription has ended and its token was revoked; use entitlement/add to re-entitle` | See [After the Token Is Revoked](#after-the-token-is-revoked) |
| 400  | `invalid metadata`                                                                    | `metadata` could not be stored                                 |
| 500  | `update failed: ...`                                                                  | A server failure; retry the request                            |
