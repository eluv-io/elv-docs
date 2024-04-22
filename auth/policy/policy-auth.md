## Authorization with Auth Policies

* [Policy Language](#policy-language)
* [Policy Delegation Mechanism](#policy-delegation-mechanism)
  * [Creating a Policy Object](#creating-a-policy-object)
* [Policy Evaluation Flow](#policy-evaluation-flow)
* [Policy Evaluation Context](#policy-evaluation-context)
  * [Call](#call)
  * [Auth Token](#auth-token)
  * [Data](#data)
* [Evaluating a Policy Rule from Bitcode](#evaluating-a-policy-rule-from-bitcode)

Authorization policies provide a flexible means to implement business rules that
control access to content objects in the content fabric. The policy language
offers a powerful expression syntax that can combine user data, content metadata
and API call information in order to allow or deny access to a given resource.

An effective delegation mechanism allows to manage groups of related contents
with a single policy, and individual content objects can be tied to multiple
independent policies. This enables fast and straightforward re-use of assets and
offerings in ad-hoc events, theme-based sites, VOD catalogues, etc.  

Policies can also be used by custom bitcode as a generic, configurable rule
engine, separating the decision logic from the implementation of the actual
bitcode functions.

### Policy Language

Authorization policies are written in a YAML syntax that represents the Abstract
Syntax Tree (AST) of the policy logic. See
[policy-language-reference.yaml](policy-language-reference.yaml)
for details.

A specialized higher-level policy language is planned for the future.

### Policy Delegation Mechanism

Policy authorization is enabled by creating and configuring a "policy object"
for auth delegation as detailed below. This has to be performed by a user who
has "edit rights" on the policy object as well as all the content objects that
should be governed by that policy object.

In order to make use of the policy for authorization, a state channel token for
the policy object is requested from elvmasterd and subsequently used to access
any content object:

1. for which the policy signer is an editor (i.e. member of a group with edit
rights on the content object)
2. that is allowed by the policy

The generated state channel token will contain a key `ctx/elv:delegation-id`
that specifies the ID of the policy content object as well as group membership
information for the requesting user:

```json
{
  "ctx": {
    "elv:delegation-id": "iq__2Fid6JkeqSxtn58k5oUsLbk9Nv2F",
      "elv:groups": [
        "viewers, screeners"
      ],
      "elv:groupIds": [
        "igrpXtdeWtLKf59kEDd7zetKPuoLxmZ"
      ]
  }
}
```

`elv:groups` lists oauth groups bound to the content objects, while
`elv:groupIds` contains all group memberships defined in the blockchain.

Alternatively, a self-signed auth token may be created, with the additional
restriction that the token signer be identical to the signer of the auth policy.
Obviously it also needs to include the `elv:delegation-id` and possibly other
criteria that may be needed by the policy.

#### Creating a Policy Object

1. Write the policy

   Create a policy.yaml document according to the specification in the policy
   language section.
   
2. Test the policy

    A policy test system is in the works - instructions to be added when
    completed.

3. Create a policy object

   Create a new content object that will host the policy or add the policy to an
   existing content object.
   
   New object:
   
   ```
   $ qfab_cli content create ilib111
   $ qfab_cli content policy set ilib111 tqw_222 \
              @policy.yaml --qid iq__333 --finalize
   ```

   Existing object:
   
   ```
   $ qfab_cli content policy set ilib111 iq__333 \
              @policy.yaml --data './meta/path/to/custom/data'
   ```
   
   Note the `--data` option, which allows to link to an arbitrary metadata path
   within the policy object. This metadata will be added to the [Policy
   Evaluation Context](#policy-evaluation-context) and therefore accessible from
   the policy.
   
   The `policy set` command automatically verifies the policy syntax, signs the
   policy and sets it on the provided content object. In addition, it configures
   the content contract for auth delegation to this policy.

### Policy Evaluation Flow

The content fabric node performs the following token and policy verification
steps when receiving an API request with a policy delegation token:

* Check the integrity of the received token by verifying the token's signature.
* Verify that the signer of the embedded state channel token is a trusted KMS
  (elvmasterd) unless the token is self-signed.
* Load the delegation policy, verify its signature and its content by parsing
  it.
* If the token is self-signed, verify that the token signer is identical to the
  policy signer (and therefore has edit rights on the content as mentioned
  above).

The API returns a `403 Forbidden` error if any of these verification steps fail.
Otherwise, the policy is ready and used for authorizing the API request.

In general, an API request is made up of a series of `elementary actions`, and
each of these actions is authorized individually by re-evaluating the policy
with the action and other call information as input - see [Policy Evaluation
Context](#policy-evaluation-context) below. 

A request to the metadata endpoint, for example, might require to read metadata
from multiple content objects if the requested path contains absolute links to
other content objects. So the policy is evaluated for each of the traversed
content objects individually. Even the actual action might be change during the
processing of the request, for example when a metadata path contains a link to a
file. In that case, the first elementary action is to read metadata, the second
to read file data (of the file referenced by the metadata path).

If any of the policy evaluations fail by returning anything but `true` from its
main expression, the call  fails with `403 Forbidden` error.

### Policy Evaluation Context

The information that a policy can use in its decisions logic is provided by the
policy evaluation context. It consists of the following sources of information,
each exposed in the context with a unique key:

 Key         | Source
-------------|---  
 `call`      | Specific call context corresponding to an `elementary action`
 `token`     | User-related data included in the auth token
 `data`      | Custom data linked to the policy (with `policy set ... --data` option)

This data can be used in the policy through an `env ref`, for example:

```yaml
  env: call/action
```

#### Call

The `call` data structure provides information on the internal API call that
triggered the evaluation of the policy.

```json
{
  "call": {
    "action": "q.read.bccall",
    "subject": "iusr4FfSM55wQ2trU8g1DewZk8bViPMQ",
    "library_id": "ilib3birRFR6jSUph1TXcRWvaystf6Yb",
    "resource_id": "iq__4N7ABSCRUCNVHmZHnV7QyiccrYs5",
    "resource_hash": "hq__24TaYdU7xQ8PRmHtcWbAdjPsfDEmb8zZZH5ikfFfUnHJ1sVRWBeH9TYF5ACizK9C9xjeSNGUwV",
    "part_hash": null,
    "need_rekey": false,
    "files_encryption_scheme": "",
    "blob_encryption_scheme": "",
    "node_id": "inodXnRMo5b4svum81wHZtvpDq9DtUf",
    "token_resource": "iq__2Fid6JkeqSxtn58k5oUsLbk9Nv2F",
    "is_entry_point": true,
    "meta_path": "",
    "bc_call": {
      "function": "content",
      "qtype": "hq__6WCWYqMNNCHoA1kewhunyMHPBf4f3MgYgy5hrZR5j9pVgkiwWQ4Fc3jW92T66WAnY5o53TR7qF",
      "path": "/thumbnail/files/assets/birds120.jpg"
    },
    "grant": "read"
  }
}
```

Field                   | Description
------------------------|---
action                  | The identifier of the API endpoint
subject                 | The subject of the call - usually a user ID
library_id              | The ID of the target library
resource_id             | The ID of the target resource - a content ID or content write token
resource_hash           | The hash of the target content object if available
part_hash               | The hash of the target content part if available
need_rekey              | True if the call requires re-encryption of the requested target data (e.g. metadata or filedata)
files_encryption_scheme | empty or `none`: no encryption <br>`cgck`: client-generated content key
blob_encryption_scheme  | encryption scheme of a "blob link" - see above
meta_path               | The requested path when reading metadata
bc_call                 | bitcode call information - available only for bitcode calls (/rep or /call endpoints)
node_id                 | The ID of the fabric node executing the request
token_resource          | The "qid" from the auth token
is_entrypoint           | True if the call is the first elementary action corresponding to the initial API call, false if the call is a subsequent internal call (e.g. to read metadata of a linked content object)


Action            | Description
------------------|---
q.read.meta       | read metadata
q.read.bccall     | call a bitcode function (/rep/... or /call/...)
q.read.info       | internal call to get content ID, hash, type & lib
q.read.part.read  | read parts
q.read.part.list  | list parts
q.read.part.info  | read part info 
q.read.part.proofs| read part proofs
q.read.files.read | read a file from a content object
q.read.files.list | list files in a content object
q.read.files.link | follow & read absolute file links
q.read.blob.link  | read blob links
q.read.versions   | list the versions of a content object
q.read.decrypt    | decrypt content data
q.read.crypt      | access data in the "content crypt" 


#### Auth Token

```json
{
  "token": {
    "qspace_id": "ispc2gfzuWxi2krZv2SqkNz3f6UpMbJe",
    "qlib_id": "ilib3RiwiP7UJJiHxFLbkL46BoVfKWrB",
    "addr": "0xe97b8ccEf4fe13377992339E2Ff97b1F7517025F",
    "qid": "iq__2Fid6JkeqSxtn58k5oUsLbk9Nv2F",
    "grant": "read",
    "iat": 1603137387,
    "exp": 1603140987,
    "ctx": {
      "elv:delegation-id": "iq__2Fid6JkeqSxtn58k5oUsLbk9Nv2F",
      "elv:groups": [
        "default-group"
      ]
    },
    "auth_sig": "ES256K_2TZQZ4rHdVSpRMzcm8wSSM229KHZAv3eUYQzqNHMmwh6a27AFrw3CdaZ74ZdxkPkQPvHhBVPB9zhBDpURixqcggP2",
    "afgh_pk": "",
    ".": "ES256K_LdWVBH6RmrKhLRy87ZX44PsCcurWb2Su6mXRqufcNuzA7gHMTMsr1kd5b3fkimx6zDNYwQsoq3Ce9Jzv7vaR3fFKe"
  }
}
```

Field                   | Description
------------------------|---
qspace_id               | The ID of the space for which the token is applicable
qlib_id                 | The library ID
addr                    | The client (blockchain) address
qid                     | The content ID for which this token is valid
grant                   | The grant type of the token: `create`, `access`, `read`, `update`, `read-crypt`
iat                     | Issued At (seconds since epoch)
exp                     | Expires At (seconds since epoch)
ctx                     | Custom token context (retrieved from content contract's `_AUTH_CONTEXT` metadata key
auth_sig                | Signature of a state channel token (created by elvmaster)
afgh_pk                 | The public AFGH key used for re-encryption
.                       | The token signature (created by the client)

Note: there is an ongoing effort to consolidate and restructure auth tokens,
which might cause changes to how that information is exposed to policies.

#### Data

The `data` key exposes arbitrary metadata of the policy object that was linked
to the policy on creation. See [Creating a Policy Object](#creating-a-policy-object).
 
### Evaluating a Policy Rule from Bitcode

Besides being used for API call authorization, a policy may also be called from
bitcode. A specific policy rule can be evaluated with a simple function call.
The function accepts an arbitrary data structure that will be added to the
[Policy Evaluation Context](#policy-evaluation-context) and exposed by the
`call` key to the policy.

By default bitcode execution maps `urlType` to a policy rule:

* DashManifest, HLSManifest, Options, AudioVideo to `allowOffering`
* MediaDownload to: `allowMediaDownload`

**Note**: bitcode execution does not fail - and accepts the user's request - if no policy is used or if the policy does not contain the expected rule. 
