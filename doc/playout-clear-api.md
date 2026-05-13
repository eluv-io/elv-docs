# Title Playout Clear API

## Overview

This API retrieves playout options for a media item **without DRM (clear playback)**.

* Supports stable playback (via object version hash) or latest version playback (via object ID)
* Returns URLs for DASH streaming or HLS streaming
* Used to integrate with players like ExoPlayer or other standard video players
* No DRM license required

Customers use this API when they want non-protected playback of media items.

---

## Endpoint

**GET**

```
/q/{objectId}/rep/playout/{offering}/options.json
```

### Path Parameters

| Parameter | Description                         |
| --------- | ----------------------------------- |
| objectId  | Media object ID                     |
| offering  | Media offering, usually `"default"` |

---

## Authentication

Requires a **Fabric authorization token**.

Pass the token in the query parameter:

```
?authorization=<token>
```

---

## Request Parameters

| Parameter | Type   | Required | Description                              |
| --------- | ------ | -------- | ---------------------------------------- |
| objectId  | string | Yes      | Media object ID                          |
| token     | string | Yes      | Authorization token                      |
| exo       | int    | No       | If `1`, adds ExoPlayer-specific metadata |

> Optionally, you can provide an **object version hash** instead of `objectId` to lock playback to a specific version.

---

# Response

## Success (HTTP 200)

Returns playout options including **DASH Clear URL** and optionally an **HLS URL**.

### Example Response

```json
{
  "dash-clear": {
    "uri": "dash/clear.mpd?token=abc123",
    "properties": {}
  },
  "hls": {
    "uri": "hls/master.m3u8"
  }
}
```

---

## Extracted Fields for Playback

| Field          | Description                                              |
| -------------- | -------------------------------------------------------- |
| dash-clear.uri | DASH manifest URL for clear playback                     |
| hls.uri        | Optional HLS manifest URL                                |
| properties     | Additional metadata (currently empty for clear playback) |

---

## Curl Example

```bash
curl -X GET "https://<fabric-url>/q/<objectId>/rep/playout/default/options.json?authorization=<token>&exo=1" \
  -H "Accept: application/json"
```

### Response Example

```json
{
  "dash-clear": {
    "uri": "dash/clear.mpd?token=abc123",
    "properties": {}
  }
}
```

---

## Notes

* Use `objectId` to always play the latest version
* Use object version hash for stable playback of a specific version
* Clear playback URLs do **not** require DRM license servers
* The `exo=1` parameter adds metadata optimized for ExoPlayer integration
* Useful for embedding content in players that do not support DRM

