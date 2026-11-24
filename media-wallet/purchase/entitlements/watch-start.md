# Rental Watch Start API

## Overview

The **Rental Watch Start API** records the moment a user first presses play on a rental.

### Why this matters

A rental has two separate time limits:

1. **The offer window** -- the period during which the user can *start* watching. Set at purchase time via
`start_watch` (default 30 days). If the user never presses play before this window closes, the rental expires
immediately at the deadline — no playback duration window opens.

2. **The active window** -- once playback starts, the user has `active_for` seconds to finish
watching. This window is anchored to the moment they first pressed play, not to the offer deadline. Concretely:
   - If they start on day 1, they can watch until day 1 + `active_for`.
   - If they start on day 29 of a 30-day window, they still get the full `active_for` duration.

The user can return and continue watching at any point within the active window. Once that window expires, access is
permanently revoked regardless of how much of the content they watched.

Calling this API anchors the expiry to the actual watch time when the user presses play before the deadline. **This
call should be made when the user first initiates playback** -- it cannot be changed once set.

---

## Endpoint

```
POST /tnt/:tid/entitlement/rental/watch_start
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

| Field             | Type              | Required | Description                                                  |
| ----------------- | ----------------- | -------- |--------------------------------------------------------------|
| `trans_id`        | string            | Yes      | The `trans_id` returned from the entitlement add or list API |
| `first_played_at` | ISO8601 timestamp | No       | When the user first pressed play; omit to use server time    |

### Validation Rules

* `first_played_at` must be at or after `rental.start` (the offer window open time)
* `first_played_at` must be at or before the offer deadline (`rental.start + start_watch`)
* Once set, `first_played_at` cannot be changed -- subsequent calls for the same `trans_id` are rejected
* The call must arrive no later than 15 minutes after the deadline. A late report with a `first_played_at` before the
  deadline is still accepted within those 15 minutes; after that it is rejected, because the rental may already have
  been revoked
* If `first_played_at` is omitted, the server time is used, so a call after the deadline is rejected

---

## Example Request

```bash
curl -X POST "https://<fabric-authority-url>/tnt/<tenantId>/entitlement/rental/watch_start" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "trans_id":         "3pp:<tenantId>:pi_3pp_abc123",
    "first_played_at":  "2026-05-02T14:30:00Z"
  }'
```

---

## Response

### Success (HTTP 200)

```json
{
  "trans_id":         "3pp:<tenantId>:pi_3pp_abc123",
  "first_played_at":  "2026-05-02T14:30:00Z"
}
```

### Error (HTTP 400)

Errors are returned as `{"error": "<message>"}`; rule violations begin with `rental watch start: `.

```json
{
  "error": "rental watch start: watch already recorded for trans_id 3pp:<tenantId>:pi_3pp_abc123 at 2026-05-02T14:30:00Z"
}
```

| Message                                                   | Meaning                                                         |
| --------------------------------------------------------- | --------------------------------------------------------------- |
| `invalid request body: ...`                               | The body is not valid JSON or a field has the wrong type        |
| `trans_id is required`                                    | `trans_id` was omitted                                          |
| `invalid first_played_at: must be RFC3339`                | `first_played_at` is not an ISO8601 / RFC3339 timestamp         |
| `payment not found for trans_id ...`                      | No rental exists with that transaction ID                       |
| `no payment found for trans_id ...`                       | No rental exists with that transaction ID                       |
| `trans_id ... is not a rental payment`                    | The transaction is not a rental                                 |
| `watch already recorded for trans_id ... at ...`          | `first_played_at` has already been set; it cannot be changed    |
| `first_played_at ... is before rental start ...`          | Timestamp is earlier than the offer window open date            |
| `first_played_at ... is after start_watch deadline ...`   | Timestamp is later than the offer deadline                      |
| `received after ..., too late for start_watch deadline ...` | The call arrived more than 15 minutes after the deadline      |

---

## Effect on Rental Expiry

Terms used below:

| Symbol            | Meaning                                                                       |
| ----------------- | ----------------------------------------------------------------------------- |
| `rental.start`    | When the offer window opened                                                  |
| `start_watch`     | Seconds after `start` the user has to begin watching (default 30 days)        |
| `active_for`      | Seconds of playback access after the user starts watching (default 2 days)    |
| `deadline`        | `rental.start + start_watch`                                                  |
| `first_played_at` | Recorded watch-start timestamp (set by this API)                              |

The rental expiry is:

| Condition                                                  | `expiry`                                      |
| ---------------------------------------------------------- | --------------------------------------------- |
| `first_played_at` is set (always within the offer window)  | `first_played_at + active_for`                |
| `first_played_at` is never set (API never called)          | `deadline` -- no playback window opens        |

This API rejects a `first_played_at` that falls after the deadline; `first_played_at` is therefore always
within the offer window when set. If the deadline passes with no recorded `first_played_at`, the rental
expires at the deadline and no playback window opens; its token is revoked about 15 minutes later, once a late
`watch_start` can no longer arrive.

After a successful call, expiry is anchored to the actual watch time and reflected in subsequent `entitlement/list`
responses via `rental.expiry` and `rental.first_played_at`. The sweep uses this expiry to determine when to revoke
the rental token.
