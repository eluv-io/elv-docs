# Rental Timing Model

> **Deprecated:** this page has moved to [https://docs.eluv.io/docs/media-wallet/api-guide/purchase/entitlements/rental-timing/](https://docs.eluv.io/docs/media-wallet/api-guide/purchase/entitlements/rental-timing/) and is no longer maintained here.

A rental has two time windows:

| Window            | Field         | Expiry   | Behavior                                                                                                                                                                                                                                   |
|-------------------|---------------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Rental Duration   | `start_watch` | **Soft** | How long after the rental start the user can begin watching. If the deadline passes without a recorded `first_played_at`, the rental expires immediately — no PD window opens. Once initiated, the PD window can extend past the deadline. |
| Playback Duration | `active_for`  | **Hard** | How long access is open once the playback window starts. Anchored to `first_played_at`; never opens if `first_played_at` is not recorded by the RD deadline. Permanently revoked at expiry.                                                |

**Expiry:** `first_played_at + active_for` once watching has started; the RD deadline (`start + start_watch`) if
`first_played_at` was never recorded.


---

## Timeline Diagrams

All examples use **RD = 7 days** (`start_watch`), **PD = 2 days** (`active_for`).

```
Legend
  [═══]  window open      ···  inactive / past expiry
  ▶──    playback session   ✓  access allowed   ✗  access denied (hard expiry)
```

### First play on day 3 — PD anchored to first_played_at

```
     d0  d1  d2  d3  d4  d5  d6  d7  d8  d9
RD   [══════════════════════════]············  7d soft; deadline = d7
PD   ············[═══════]···················  2d hard; expiry = d5

A1   ············▶──────·····················  ✓  within PD
A2   ············▶──────────────·············  ✗  exceeds PD expiry
A3   ············▶──·▶──·····················  ✓  stop/restart, both within PD
A4   ············▶─────·▶────────············  ✗  second session crosses PD expiry
```

### First play on day 6 — PD extends past RD deadline (soft expiry in action)

```
     d0  d1  d2  d3  d4  d5  d6  d7  d8  d9
RD   [══════════════════════════]············  7d soft; deadline = d7
PD   ························[═══════]·······  2d hard; expiry = d8

B1   ························▶──────·········  ✓  within PD; crosses RD deadline (RD is soft)
B2   ························▶──────────────·  ✗  exceeds PD expiry
B3   ························▶──·▶───········  ✓  stop/restart within PD
B4   ························▶──·▶────────···  ✗  second session crosses PD expiry
```

### No watch_start call — expires at RD deadline

If `first_played_at` is never recorded, no PD window opens. The rental expires at the RD deadline, and its token is
revoked about 15 minutes later (a late `watch_start` for a play before the deadline is accepted until then).

```
     d0  d1  d2  d3  d4  d5  d6  d7  d8  d9
RD   [══════════════════════════]············  7d soft; expires at d7 if watch_start never called

C1   ································▶·······  ✗  play after deadline, no watch_start → expired
```

---

The **rental duration deadline is soft** for users who initiated playback — the PD window can extend past it.
The **rental duration deadline is hard** if `watch_start` was never called — no access after the deadline.
The **playback duration expiry is always hard** — access is permanently revoked and the rental token is swept.
