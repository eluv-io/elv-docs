# Rental Watch Start API

## Overview

The **Rental Watch Start API** records the moment a user first presses play on a rental.

### Why this matters

A rental has two separate time limits:

1. **The offer window** -- the period during which the user can *start* watching. Set at purchase time via
`start_watch` (e.g. 2 days). If the user never presses play before this window closes, the watch window is treated
as implicitly started at the deadline; the user still receives the full `active_for` duration from that point.

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
* Once set, `first_played_at` cannot be changed -- subsequent calls for the same `trans_id` are rejected

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

### Error (HTTP 400 / 404)

| Message                                                 | Meaning                                                      |
| ------------------------------------------------------- | ------------------------------------------------------------ |
| `payment not found for trans_id ...`                    | No rental exists with that transaction ID                    |
| `trans_id ... is not a rental payment`                  | The transaction is not a rental                              |
| `watch already recorded for trans_id ... at ...`        | `first_played_at` has already been set; it cannot be changed |
| `first_played_at ... is before rental start ...`        | Timestamp is earlier than the offer window open date         |

---

## Effect on Rental Expiry

Terms used below:

| Symbol            | Meaning                                         |
| ----------------- | ----------------------------------------------- |
| `rental.start`    | When the offer window opened                    |
| `start_watch`     | Offer-window duration (rental setting)          |
| `active_for`      | Active-window duration (rental setting)         |
| `deadline`        | `rental.start + start_watch`                    |
| `first_played_at` | Recorded watch-start timestamp (set by this API)|

The rental expiry is always:

```
expiry = effective_watch_start + active_for
```

`effective_watch_start` resolves as follows:

| Condition                                         | `effective_watch_start` |
|---------------------------------------------------| ----------------------- |
| `first_played_at` is set and <= `deadline`        | `first_played_at`       |
| `first_played_at` is set but > `deadline`         | `deadline`              |
| `first_played_at` is never set (API never called) | `deadline`              |

If the user watches before the offer window closes, the active window starts when they first pressed play. In all
other cases — late play or no play — the active window starts at `deadline`, giving the user the full `active_for`
duration from that point.

After a successful call, expiry is anchored to the actual watch time and reflected in subsequent `entitlement/list`
responses via `rental.expiry` and `rental.first_played_at`. The sweep uses this expiry to determine when to revoke
the rental token.
