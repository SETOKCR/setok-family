# Provider-binding registry (contract v1)

This directory holds the provider-neutral, tenant-scoped registry that maps SETOK Family internal identities to replaceable provider identifiers. It was introduced by ST-PB-001.

- `provider-binding-registry.schema.json` is the JSON Schema (draft 2020-12) for the registry document.
- `registry.desired.json` is the desired, versioned registry. It contains no observed state, timestamps, health or PII.
- `scripts/st-pb-001/Invoke-StPb001.ps1` checks the cross-record invariants that a schema cannot express, and reconciles the registry read-only against the providers.

## Records

| Record | Purpose | Internal ID |
|---|---|---|
| tenant | A SETOK Family tenant (family). It is not an Authentik or Cloudflare tenant. | `tnt_<ULID>` |
| subject | A human or device that SETOK reasons about. `subject_type` is `human` or `device`, a closed set. | `sub_<ULID>` |
| integration | A provider boundary the tenant uses. `ownership` is `dedicated` or `shared`. A `shared` integration must list `not_owned` objects. | `int_<ULID>` |
| resource | A provider configuration object that SETOK Family manages, such as `device_profile`. A device profile is **not** a device. | `res_<ULID>` |
| binding | A link from a subject, integration or resource to a provider identifier. | `bnd_<ULID>` |

Internal IDs are random ULIDs. They are never derived from provider IDs, emails or account IDs, and they do not change when a provider binding is replaced.

## Binding types (type matrix)

| binding_type | target | integration capability | Example |
|---|---|---|---|
| `identity_user` | human subject | identity | Authentik user uuid/pk |
| `device_enrollment` | device subject | enforcement or device_management | future: Cloudflare/MDM device id (0 in ST-PB-001) |
| `integration_account` | the integration itself | any | Cloudflare account id and team domain |
| `managed_resource` | resource of the same integration | any | Cloudflare `SETOK-FAMILY-MANAGED` policy id |

`external` may hold only stable, non-secret provider identifiers. The schema rejects property names that look like email, name, password, secret, token, key or recovery fields, and the validator rejects email-like and secret-like values.

## Lifecycle

| Status | Meaning |
|---|---|
| `ACTIVE` | In force. Counted for cardinality and gates. |
| `RETIRED` | Ended or replaced. It is kept for history and needs `retired_on`. |
| `STALE` | The provider object is no longer observed or can't be verified, pending remediation. |
| `ERROR` | Reconciliation found a contradiction, such as a wrong type, a superuser or a duplicate. |

`STALE` and `ERROR` are statuses that a person writes into the registry after a reconciliation finding. Observed results stay in evidence.

**Replacement** works like this:
1. Set the old binding to `RETIRED` and give it a `retired_on` date.
2. Add a new binding with `replaces: <old binding_id>`. It keeps the same tenant, target, provider and binding_type, and gets a new `external` value.

The internal `subject_id` or `resource_id` never changes.

## Cardinality

- No two `ACTIVE` bindings may share the same tenant, target, provider, binding_type and external value.
- One external identity may not be `ACTIVE` for two different targets within the same tenant, provider and binding_type.
- One subject may have several bindings to different providers or binding types. The registry doesn't impose one binding per subject.

## Out of scope

The registry encodes no authorization, so there is no Owner, Parent, Viewer, Guardian or Child. Domain authorization and the Phase 2 runtime persistence (SQLite/Drizzle) are later work. The tables `provider_integrations` and `provider_device_bindings` in architecture §22 are expected to be derived from this contract.
