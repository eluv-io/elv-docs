# Editor-signed Tokens & Policies

## Description

Users who have `edit` rights on a content can issue editor-signed tokens for this content.
Editor-signed tokens expire after a default duration of `4 hours`. The creator of the token can extend this duration up to 24 hours.

If no additional information is added - such as the context described below - the token provides a default set of permissions - to the _public area_ - when accessing the content.

**_Public Area_ and Object Visibility**


* Content objects have a public area and a private area.

  * metadata: the public area is metadata under the "public" key subtree
  * parts (and files): the public area is all unencrypted parts (and files)
 
* Content objects have a visibility flag (int)

|visibility|description|
|-|-|
| 0  | the object is private (only accessible to groups and individuals specifically permitted) |
| 1  | the object is 'published' - everybody can access its public area using an unauthenticated token |
| 10 | the object is publicly accessible - everybody can access its public and private areas (including encrypted parts) |


The user can also take the control on the permissions granted to the token by using a `policy` and embedding contextual information in the token. This requires the user who creates (and signs) the token to:

* be an editor of the content
* be the signer of the policy

The steps to create such a token are:

* write a policy for the content
* sign the policy
* create a policy object and store the signed policy under the `auth_policy` key in the meta-data of the policy object
* create a editor-signed token that embeds - as contextual information - the ID of the policy object as well as other values that might be used in the evaluation of the policy.

## Simple Editor-Signed Token

In this simple form editor-signed tokens provide default permissions to their users.

In the example below the `bearer` value is used as the authorization to access the content `iq__1234`:

```
 ./qfab_cli content token sign ilib1234 iq__1234 --expires-in 2h | jq .
{
  "token": {
    "qspace_id": "ispc218Pn4tTNJELz8ASyV8o4KRggfoD",
    "qlib_id": "ilib1234",
    "addr": "0x65419C9f653703ED7Fb6CC636cf9fda6cC024E2e",
    "qid": "iq__1234",
    "grant": "read",
    "tx_required": false,
    "iat": 1603359486,
    "exp": 1603366686,
    "auth_sig": "ES256K_JhQhFWK16WbYTGS7bktSTr3pZXKYuHwPjYn3qQAQk9gUMRrXuho7kooMeEkhMMmZc1rkkkyc5sw8Vjssdk3o8opPA",
    "afgh_pk": "",
    ".": "ES256K_6MdykCk5CHVvLzJJ9tLCtpJR798SxokBWYajr8xrhRfpxJTqPatHuucoc1RcKTTqRvGuEPJoiu8GRsLLwGGAuSXk4"
  },
  "bearer": "eyJxc3BhY2VfaWQiOiJpc3BjMjE4UG40dFROSkVMejhBU3lWOG80S1JnZ2ZvRCIsInFsaWJfaWQiOiJpbGliMTIzNCIsImFkZHIiOiIweDY1NDE5QzlmNjUzNzAzRUQ3RmI2Q0M2MzZjZjlmZGE2Y0MwMjRFMmUiLCJxaWQiOiJpcV9fMTIzNCIsImdyYW50IjoicmVhZCIsInR4X3JlcXVpcmVkIjpmYWxzZSwiaWF0IjoxNjAzMzU5NDg2LCJleHAiOjE2MDMzNjY2ODYsImF1dGhfc2lnIjoiRVMyNTZLX0poUWhGV0sxNldiWVRHUzdia3RTVHIzcFpYS1l1SHdQalluM3FRQVFrOWdVTVJyWHVobzdrb29NZUVraE1NbVpjMXJra2t5YzVzdzhWanNzZGszbzhvcFBBIiwiYWZnaF9wayI6IiJ9.RVMyNTZLXzZNZHlrQ2s1Q0hWdkx6Sko5dExDdHBKUjc5OFN4b2tCV1lhanI4eHJoUmZweEpUcVBhdEh1dWNvYzFSY0tUVHFSdkd1RVBKb2l1OEdSc0xMd0dHQXVTWGs0"
}

```

## Editor-Signed Token with Finer-Grained Permission

### Write an Authorization Policy

* write the policy: see [general policy documentation](policy/policy-auth.md)
* example: [editor signed policy](common_policies/editor_signed_policy.yaml)

### Create a Policy Object

create the policy object

```
./qfab_cli content create ilib1234

{
  "qlib_id": "ilib1234",
  "q": {
    "qid": "iq__1234",
    "qtype": "hq__EGKXyxx",
    "write_token": "tqw_6K52PR6yhNJDTh5526T8TtNbQf7QZufwQ"
  }
}
```

and store the policy created in previous step. This:

* validates and signs the policy
* stores the policy in the delegate

```
./qfab_cli content policy set ilib1234 tqw_6K52PR6yhNJDTh5526T8TtNbQf7QZufwQ @policy.yaml --qid iq__1234

{
	"hash" : "hq__1234",
	"id" : "iq__4567"
}

```

### Create an Editor-Signed Token with Permissions


```
qfab_cli content token sign ilib1234 iq__1234 --ctx @ctx.json --policy iq__4567 | jq .

{
  "token": {
    "qspace_id": "ispc218Pn4tTNJELz8ASyV8o4KRggfoD",
    "qlib_id": "ilib1234",
    "addr": "0x65419C9f653703ED7Fb6CC636cf9fda6cC024E2e",
    "qid": "iq__1234",
    "grant": "read",
    "tx_required": false,
    "iat": 1603293819,
    "exp": 1603308219,
    "ctx": {
      "authorized_meta": [
        "/preferences"
      ],
      "authorized_files": [
        "/files/assets/birds2.jpg"
      ],
      "authorized_offerings": [
        "default",
        "special"
      ],
      "elv:delegation-id": "iq__4567"
    },
    "auth_sig": "ES256K_MuPyAU8GSd6Buykx6HctubafbMGudz49FL2v9EgQa3Y6shAaWxzMMfMtJfbPeFRzQQUCMybUS9EAhvuSuViWEBrLG",
    "afgh_pk": "",
    ".": "ES256K_F9NTVgW1d2tNY9zZK8PED7hYo9RuLnYkPrRVg8bxyxjhuXwG85GvPNUxoEaLpJAnFut7DaEBzNbVrVQ8oExRDeUeB"
  },
  "bearer": "eyJxc3BhY2VfaWQiOiJpc3BjMjE4UG40dFROSkVMejhBU3lWOG80S1JnZ2ZvRCIsInFsaWJfaWQiOiJpbGliMTIzNCIsImFkZHIiOiIweDY1NDE5QzlmNjUzNzAzRUQ3RmI2Q0M2MzZjZjlmZGE2Y0MwMjRFMmUiLCJxaWQiOiJpcV9fMTIzNCIsImdyYW50IjoicmVhZCIsInR4X3JlcXVpcmVkIjpmYWxzZSwiaWF0IjoxNjAzMjkzODE5LCJleHAiOjE2MDMzMDgyMTksImN0eCI6eyJhdXRob3JpemVkX29mZmVyaW5ncyI6WyJkZWZhdWx0Iiwic3BlY2lhbCJdLCJlbHY6ZGVsZWdhdGlvbi1pZCI6ImlxX180NTY3In0sImF1dGhfc2lnIjoiRVMyNTZLX011UHlBVThHU2Q2QnV5a3g2SGN0dWJhZmJNR3VkejQ5RkwydjlFZ1FhM1k2c2hBYVd4ek1NZk10SmZiUGVGUnpRUVVDTXliVVM5RUFodnVTdVZpV0VCckxHIiwiYWZnaF9wayI6IiJ9.RVMyNTZLX0Y5TlRWZ1cxZDJ0Tlk5elpLOFBFRDdoWW85UnVMbllrUHJSVmc4Ynh5eGpodVh3Rzg1R3ZQTlV4b0VhTHBKQW5GdXQ3RGFFQnpOYlZyVlE4b0V4UkRlVWVC"
}
```

### Allowing multiple contents within a unique token

Multiple contents may be authorised with a unique token by adding the ids of the additional contents in the `ctx` map of the token under key `authorized_qids`. The command line offers a `--authorized-qids` flag for convenience.

The signer of the token must also be an editor of the additional contents.


```
qfab_cli content token sign ilib1234 iq__1234 --ctx @ctx.json --policy iq__4567 --authorized-qids 'iq__5678,iq__1291' | jq .
{
  "token": {
    "EthAddr": "0x65419c9f653703ed7fb6cc636cf9fda6cc024e2e",
    "AFGHPublicKey": "",
    "QPHash": null,
    "SID": "ispcfpv2HnWnarY3MJQ1huLo2hjPL3V",
    "LID": "ilib1234",
    "QID": "iq__1234",
    "Subject": "iusr2QpVishg9QSGU4TW3Nn4g6gYw6TP",
    "Grant": "read",
    "IssuedAt": "2021-05-12T20:06:12.757Z",
    "Expires": "2021-05-13T00:06:12.757Z",
    "Ctx": {
      "authorized_files": [
        "/files/assets/birds2.jpg"
      ],
      "authorized_meta": [
        "/preferences"
      ],
      "authorized_offerings": [
        "default",
        "special"
      ],
      "authorized_qids": [
        "iq__5678",
        "iq__1291"
      ],
      "elv:delegation-id": "iq__4567"
    }
  },
  "bearer": "aessjc2iuFSnERGbErMyEqKJk7yVZyQov9w4xqy1KStHCgWcLdZ58Uv83xACJndwwqvzFQ2oHmtRkkzvjmwMFHXr9hHuNt8ewVjnPJ9ZPKcGRUApqv24Ur767jNxrBp6hdMrsTf9muX5LXZ65yLUs2StRN3oaooxrzcAstk9xVTPRJNEm5VtNEauMwAWYx7pqGoqvL1K9Y455JW6S65jEAA8iZdzvyCHHVxC6PRLEFwSBV3rshjTWLiWs1Frz5sfgMms4Dt6nJaQubmKBWqxtyVXtdTESzPvgJCZjvZzqCm8smz31X4rYbTbisTv3JXPhGCok6LsvffeiHxjg8rVtxSmv8rLXqBm1uL69FuF94R3yHaQuRwZRwBnnQWqCpXHJSgMgGhgwvJYHkxXsqRB6YtYG4WFwWeqBwiZFZr9LZbZ9oPpJCvqUtRjEGiPekhnMXZMFPGxEhWXTBnw3zV5oydVyRbpfBpHeE8aPhYoE4AYbx"
}
```
