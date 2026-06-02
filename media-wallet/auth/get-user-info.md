# Get User Info API

## Overview

The **Get User Info API** allows an authenticated caller to retrieve information about themselves based on their
authentication token, including the status of their associated access wallet, tenant group membership, and admin privileges.

---

## Endpoint

```http
GET /tnt/:tid/user
```

---

## Authentication

This API requires the caller to be authenticated using a user token CSAT.

---

## Path Parameters

| Name  | Type   | Required | Description |
| ----- | ------ | -------- | ----------- |
| `tid` | string | Yes      | Tenant ID   |

---

## Required Headers

| Header        | Value            |
| ------------- | ---------------- |
| Accept        | application/json |
| Authorization | Bearer \<token\> |

---

## Response

### Success Response (HTTP 200)

Returned when the user info is retrieved successfully.

#### Fields

| Field              | Description                                             |
| ------------------ | ------------------------------------------------------- |
| tenant_id          | Tenant ID the user belongs to                           |
| user_address       | User wallet address derived from the auth token         |
| user_id            | External user ID or identity (from JWT)                 |
| user_access_wallet | On-chain access wallet address (if exists)              |
| is_tenant_admin    | True if user is a tenant admin                          |
| is_content_admin   | True if user is a content admin                         |
| is_tenant_user     | True if user is a regular tenant user                   |
| groups             | List of groups the user belongs to                      |
| metadata           | Optional metadata about the user                        |
| error              | Error message if any issue occurs                       |

### Example Success Response

```json
{
  "tenant_id": "<tenantId>",
  "user_address": "0xabc123...",
  "user_id": "user@example.com",
  "user_access_wallet": "0xdef456...",
  "is_tenant_admin": false,
  "is_content_admin": false,
  "is_tenant_user": true,
  "groups": [
    { "id": "group1", "name": "Subscribers" }
  ],
  "metadata": {}
}
```

---

### Error Response

**Bad Request (400)**

```json
{
  "error": "failed to retrieve user info"
}
```

---

## Notes

* The `user_access_wallet` field will be empty if the user does not yet have a wallet; call [Create User Access Wallet](./create-user-wallet.md) first.
* The `groups` array shows the groups the user belongs to within the tenant.
