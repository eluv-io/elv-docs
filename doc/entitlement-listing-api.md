# List Entitlement API

## Overview

This API allows a user to list all entitlements in their wallet.

* Returns all purchased or rented entitlements (digital products, rentals, or special content)
* Supports pagination, filtering, and sorting
* Requires an authenticated user

---

## Endpoint

**GET**

```
/wlt/items
```

---

## Authentication

Requires a **UserAuth token** (CSAT client-signed token).

Example header:

```
Authorization: Bearer <token>
```

---

## Query Parameters

| Parameter       | Type   | Required | Description                                       |
| --------------- | ------ | -------- | ------------------------------------------------- |
| filter          | string | No       | Filter entitlements, e.g., `sku:eq:SKU_ABC_001`   |
| start           | int    | No       | Paging offset (default: 0)                        |
| limit           | int    | No       | Paging limit of results to return (default: 20)   |
| sort_by         | string | No       | Column to sort by (default: `block`)              |
| sort_descending | bool   | No       | `true` = descending, `false` = ascending          |

---

# Response

## Success (HTTP 200)

### Example Response

```json
{
  "contents": [
    {
      "block": 12455365,
      "created": 1765832951,
      "cap": 10000,
      "contract_name": "Goat Pack One",
      "contract_addr": "0x59267d3eff5a4a595f6bfb790d18ed6af358653a",
      "hold": 1765832952,
      "meta": { },
      "ordinal": 454,
      "token_id": 455,
      "token_id_str": "455",
      "token_owner": "0x761f45287ea364db6b216bd655910430afa3e839",
      "token_uri": "https://demov3.net955210.contentfabric.io/s/demov3/q/hq__3QrfjaGHGJg2DT8YRpcaGjVsLgxEZH6BK3ZQyrSscfvDV18fDpBqydkdzv1rgBt1EZWqhtWYyC/meta/public/nft"
    }
  ],
  "paging": {
    "start": 0,
    "limit": 1,
    "total": 10
  }
}
```

---

## Field Descriptions

| Field                    | Type   | Description                                       |
| ------------------------ | ------ | ------------------------------------------------- |
| paging.total             | int    | Total entitlements in the wallet matching query   |
| contents                 | array  | Array of entitlements                             |
| contents.metadata        | object | Name, description, image, and other details       |
| contents.contract_name   | string | Entitlement text description                      |
| contents.contract_addr   | string | Entitlement contract address owning entitlement   |
| contents.token_owner     | string | Wallet address of the user owning the entitlement |

pending:
| sku             | string | Product SKU                                       |
| entitlement_id  | string | Unique ID for this entitlement                    |

---

## Curl Example

```bash
curl -X GET "https://<fabric-authority-url>/wlt/items?start=0&limit=1" \
  -H "Authorization: Bearer <token>" \
  -H "Accept: application/json"
```

---

## Filtering Examples

Filter by SKU:

```
filter=sku:eq:SKU_ABC_001
```

Filter by collection:

```
filter=collection_name:eq:Transformers
```

Combine multiple filters:

```
filter=sku:eq:SKU_ABC_001/collection_name:eq:Transformers
```
