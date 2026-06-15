# Rental Timing Model

A rental has two time windows:

| Window            | Field         | Expiry   | Behavior |
|-------------------|---------------|----------|----------|
| Rental Duration   | `start_watch` | **Soft** | How long after the rental start the user can begin watching. If the deadline passes without a recorded `first_played_at`, the rental expires immediately — no PD window opens. Once initiated, the PD window can extend past the deadline. |
| Playback Duration | `active_for`  | **Hard** | How long access is open once the playback window starts. Anchored to `first_played_at`, or the RD deadline if never set. Permanently revoked at expiry. |

**Expiry formula:** `effective_watch_start + active_for`

`effective_watch_start` is `first_played_at` if set and on or before the RD deadline, otherwise the deadline itself.

> **Wall-clock, not minutes.** Expiry is a point in time, not accumulated viewing minutes.
> Pausing and resuming within the expiry window is always allowed.

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

If `first_played_at` is never recorded, no PD window opens. The rental expires at the RD deadline.

```
     d0  d1  d2  d3  d4  d5  d6  d7  d8  d9
RD   [══════════════════════════]············  7d soft; expires at d7 if watch_start never called

C1   ································▶·······  ✗  play after deadline, no watch_start → expired
```

---

The **rental duration deadline is soft** for users who initiated playback — the PD window can extend past it.  
The **rental duration deadline is hard** if `watch_start` was never called — no access after the deadline.  
The **playback duration expiry is always hard** — access is permanently revoked and the rental token is swept.
