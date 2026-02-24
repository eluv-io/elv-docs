# Title Playout DRM API

## Overview

This API retrieves playout options for a media item with **Widevine DRM protection**.

* Supports stable playback (via object version hash) or latest version playback (via object ID)
* Returns URLs for DASH streaming and the license server
* Used to integrate with players like ExoPlayer or other DRM-capable clients

---

## Endpoint

**GET**

```
/q/{objectId}/rep/playout/{offering}/options.json
```

### Path Parameters

| Parameter | Description                         |
| --------- | ----------------------------------- |
| objectId  | ID of the media object              |
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
| exo       | int    | No       | If `1`, includes ExoPlayer-specific info |

> You may optionally provide an **object version hash** instead of `objectId` to lock playback to a specific version of the media.

---

# Response

## Success (HTTP 200)

Returns playout options including **DASH Widevine URL** and the **license server URL**.

### Example Response

```json 
{
  "dash-widevine": {
    "uri": "dash/widevine.mpd?token=abc123",
    "properties": {
      "license_servers": [
        "https://license.example.com/widevine"
      ]
    }
  },
  "hls": {
    "uri": "hls/master.m3u8"
  }
}
```

---

## Extracted Fields for Playback

| Field                                       | Description                             |
| ------------------------------------------- | --------------------------------------- |
| dash-widevine.uri                           | DASH manifest URL for Widevine playback |
| dash-widevine.properties.license_servers[0] | License server URL for Widevine DRM     |
| hls.uri                                     | Optional HLS manifest URL (non-DRM)     |

---

## Curl Example

```bash 
curl -X GET "https://<fabric-url>/q/<objectId>/rep/playout/default/options.json?authorization=<token>&exo=1" \
  -H "Accept: application/json"
```

### Response Example

```json 
{
  "dash-widevine": {
    "uri": "dash/widevine.mpd?token=abc123",
    "properties": {
      "license_servers": [
        "https://license.example.com/widevine"
      ]
    }
  }
}
```

---

## Notes

* Use `objectId` to always play the latest version
* Use object version hash for stable playback of a specific version
* The `exo=1` parameter adds extra metadata optimized for ExoPlayer integration

