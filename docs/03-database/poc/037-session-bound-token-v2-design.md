# Session-Bound Authorization Context Token v2 — Design Proposal

- **Status:** Proposal for disposable PoC review only; not approved for implementation or production.
- **Date:** 2026-11-27
- **Scope:** PostgreSQL 18 disposable database `sinau_design_poc`.
- **Related:** `021-authorization-freshness-design.md`, scripts 005, 010, 019, 020, 022–024, and 036; ADR-003, ADR-007, ADR-008.

> This document refines the proposed v2 contract after the 2026-11-27 read-only inventory. It contains no executable SQL and authorizes no database, application, RLS, role, or service changes.

## 1. Evidence baseline

The latest execution of script 022 completed in `sinau_design_poc` as PostgreSQL superuser `postgres`, under `BEGIN READ ONLY`, and reached `ROLLBACK` plus the completion marker.

The inventory reported:

- PostgreSQL 18.7 and database `sinau_design_poc`.
- The six synthetic issuer relations, `sinau_private.context_keys`, and `public.tenants` were present.
- The account, session, tenant-membership, and unit-membership relations have no generation columns.
- The session reference is `poc_auth_sessions.session_hash`, a 32-byte `bytea` primary key, associated with `actor_id`, status, authenticated/expiry/revocation timestamps, and assurance level.
- The current four context functions are owned by `sinau_context_owner`; the verifier and issuer validation functions are SECURITY DEFINER and VOLATILE, while `current_verified_context()` is SECURITY INVOKER and VOLATILE. All have a fixed `pg_catalog, pg_temp` search path.
- The runtime has SET membership in both issuer and query capability roles. The role split is not a boundary against arbitrary SQL executed through the trusted runtime connection.
- Fourteen public RLS policies remain installed. No permanent policy change was made by scripts 035/036.

Script 036 passed EU-RLS-01 through EU-RLS-11, exactly eight verifier calls for eight protected SELECTs, all three write-denial checks, ROLLBACK, and exact policy restoration. Its permission revocation/restoration cases are statement-to-statement changes inside one transaction; they do not prove cross-connection freshness for account/session/membership.

## 2. Proposed v2 canonical token

Candidate payload (16 pipe-delimited fields, with the final field being the MAC):

```text
v2|audience|kid|actor_uuid|session_ref_hex|tenant_uuid|unit_uuid_or_dash|xid8|iat|exp|nonce_hex|account_epoch|tenant_membership_epoch|unit_membership_epoch|unit_epoch|mac_hex
```

The HMAC-SHA-256 covers fields 1–15, in their exact canonical order and UTF-8/ASCII representation. Field 16 is the lowercase hexadecimal MAC.

| Field | Contract |
|---|---|
| `v2` | Exact version. The v2 verifier rejects v1; there is no fallback or silent upgrade. |
| `audience` | Exact database/application audience configured by the verifier. The PoC value is `sinau_design_poc`. |
| `kid` | Canonical identifier of an active signing key. |
| `actor_uuid` | Lowercase canonical UUID resolved from the authenticated server-side session. Never supplied as an authorization fact by the client. |
| `session_ref_hex` | Exactly 64 lowercase hex characters representing the 32-byte SHA-256 session reference stored in `poc_auth_sessions.session_hash`. It is an identifier, not a bearer credential. |
| `tenant_uuid` | Lowercase canonical tenant UUID authorized by the issuer. |
| `unit_uuid_or_dash` | Lowercase canonical unit UUID or exact `-` for tenant-only scope. |
| `xid8` | Canonical unsigned decimal top-level transaction XID. |
| `iat`, `exp` | Canonical unsigned decimal Unix timestamps. |
| `nonce_hex` | Exactly 32 lowercase hex characters (16 cryptographically random bytes). |
| `account_epoch` | Positive signed-bigint-range decimal generation from the authoritative account row. |
| `tenant_membership_epoch` | Positive signed-bigint-range decimal generation for this actor/tenant membership. |
| `unit_membership_epoch` | Positive generation for the exact actor/tenant/unit membership, or `-` for tenant-only scope. |
| `unit_epoch` | Positive generation for the unit lifecycle, or `-` for tenant-only scope. |
| `mac_hex` | Exactly 64 lowercase hex characters for HMAC-SHA-256. |

Canonical integer claims use `0` or a non-zero digit followed by decimal digits, with no sign or leading zero. Epochs must be in the range 1 through 9223372036854775807. UUIDs and hex strings are lowercase. The parser must reject wrong field count, empty fields, extra separators, non-canonical values, overlong input, and out-of-range casts before casting.

For a unit-bound token, both `unit_membership_epoch` and `unit_epoch` are required positive integers. For tenant-only scope, `unit_uuid_or_dash`, `unit_membership_epoch`, and `unit_epoch` must all be the exact `-` sentinel. A tenant-only token must never satisfy a unit-scoped policy.

Candidate time limits retain the tested v1 bounds unless separately reviewed: lifetime 1–300 seconds, maximum five seconds of future issue-time skew, `exp > iat`, and `exp > now`. The verifier checks XID equality and signing-key validity before returning any context.

## 3. Session identity and lifecycle

1. The trusted backend authenticates a session first. The issuer hashes the server-side session bearer/reference and resolves exactly one active session row.
2. The issuer returns the actor and the stored 32-byte session hash as an internal session reference. The signer hex-encodes that hash. The raw session bearer never enters the signed token, SQL logs, command-line arguments, or browser.
3. The verifier looks up the exact `session_hash` and requires the same `actor_id`, active status, valid authenticated/expiry times, and `revoked_at IS NULL` on every protected statement.
4. Session identifiers are immutable and never reused. Session rows are terminal: an active session may become revoked/expired but a revoked/expired session is never reactivated. A new login creates a new random session reference and row.
5. Hard deletion of session rows is prohibited while a token could still be valid; retain a tombstone or a permanent non-reuse ledger. Do not allow reuse of a previous session hash.
6. Revoking session A must deny A's token while an independent active session B for the same actor remains eligible, provided the account and relevant memberships remain active.

A hash is not proof of authentication. Possession of the session reference alone must not create a valid token or authenticate an HTTP request. The token remains an internal database-transaction artifact and must not be returned to the browser, logged, put in a URL, or cached across requests.

The current fixture validator accepts a session bearer and resolves its hash, but its result currently returns only actor/tenant/unit. A future issuer prototype must return the internally resolved session reference and epochs from trusted rows; it must not accept actor, session hash, or epoch claims as client-authoritative inputs.

## 4. Generation semantics

The v2 candidate deliberately includes a unit lifecycle generation in addition to the three generations listed in design 021. This closes a resurrection case: a unit may become inactive/closed and later active again while the membership row remains unchanged. A live status check alone would deny during inactivity but could allow an old token again after reactivation.

| Authoritative row | Candidate column | Increment when |
|---|---|---|
| `poc_identities` | `account_epoch` | Account authorization state changes, including disable/lock and later re-enable. |
| `poc_tenant_memberships` | `membership_epoch` | Membership status, effective start/end, or revocation state changes. |
| `poc_unit_memberships` | `membership_epoch` | Unit membership status, effective start/end, or revocation state changes. |
| `poc_units` | `unit_epoch` | Unit lifecycle status changes, including active ↔ inactive/closed. |

Candidate type: `bigint NOT NULL`, initialized to 1, constrained to positive values. The v2 verifier compares each signed generation with the current authoritative row on every protected statement, as well as checking the current status and effective-time predicates. Epoch claims supplement live checks; they do not replace them.

To prevent a missed version increment, the PoC should test database-enforced mutation rules rather than rely only on application convention. A candidate trigger design should:

- own generation updates inside the database;
- increment exactly once when an authorization-relevant column changes;
- ignore/reject caller-supplied attempts to set an epoch directly;
- reject generation overflow;
- prohibit hard deletion/recreation that would reset a generation;
- keep the session reference, actor binding, and session creation identity immutable.

For membership revoke/regrant, retain the same row as a tombstone and advance the generation on each relevant transition. If future retention/privacy rules require deletion, a durable generation ledger or a non-reusable membership-instance identifier is required before deletion can be considered safe. Do not delete and recreate an authorization row with generation 1.

Session epoch is omitted from the minimal token because the session reference is immutable/non-reusable and session state is checked live. This is safe only if terminal session states cannot be reactivated and identifiers cannot be reused.

## 5. Live verifier contract

For every protected SQL statement, the v2 verifier must:

1. Parse and validate the complete canonical v2 token, audience, key status, MAC, time window, nonce, and exact top-level XID.
2. Fetch the account by `actor_id`; require active status and exact `account_epoch`.
3. Fetch the exact session by `session_ref_hex` and actor; require active, not revoked, and not expired.
4. Fetch tenant membership by `(actor_id, tenant_id)`; require active/effective status and exact `tenant_membership_epoch`.
5. For unit scope, fetch unit membership by `(actor_id, tenant_id, unit_id)` and unit lifecycle by `(tenant_id, unit_id)`; require active/effective status and exact `unit_membership_epoch` and `unit_epoch`.
6. Return one verified context only if all applicable checks succeed. Missing/mismatched rows return no context. Unexpected permission or database errors abort the statement; do not suppress exceptions or fall back to token claims.

The verifier must not trust mutable scope GUCs. The only client-writable carrier remains the opaque `app.context_token`. The verifier must use a fixed audited search path, schema-qualified relations/functions, a non-login owner, and narrow EXECUTE grants. Runtime/query roles must not gain direct reads of key or authorization tables.

The verifier should remain VOLATILE for the candidate because its internal reads must see the required READ COMMITTED revocation visibility. Do not change volatility or snapshot strategy without the in-flight and multi-row race evidence in section 7.

## 6. Separate permissions and entitlements

- Tenant-wide `education_units.list_all` remains an explicit permission, not implied by a null unit claim, tenant membership, or role label. The query helper must read its current role/permission mapping for each protected statement. Script 036 proves only its same-transaction statement-to-statement re-evaluation.
- Feature entitlements remain separate from identity/session/membership context and must be checked at the relevant feature boundary. Do not treat feature entitlement as a tenant or unit membership epoch.
- Resource relationships, delegation, use-case permission, and application authorization remain separate checks. RLS is defense-in-depth, not a substitute for them.

## 7. Required PoC 037 session-isolation test

Script 037 must be a new rollback-only disposable-database experiment and must not alter the installed verifier or policies permanently.

Synthetic setup:
- One active actor, tenant, and unit membership.
- Two distinct active sessions A and B for the same actor, each with a unique 32-byte session reference.
- Two independently signed v2 tokens with the same actor/tenant/unit/XID but different session references and matching authoritative generations.
- Token contents and session bearers are never printed.

Required cases:
- Both A and B are initially accepted.
- Wrong actor/session pairing is rejected.
- Revoking A causes the next protected statement using A's token to be denied.
- B remains accepted after A is revoked.
- Revoked A cannot be reactivated; a fresh session C is independently eligible after trusted issuance.
- Expired session, missing session, unknown session reference, wrong XID, wrong MAC, and v1 token are denied.
- Unit-bound tokens with stale unit epoch are denied after unit lifecycle transition/re-activation.
- The verifier call count is measured per protected statement.
- Any transactional fixture and candidate objects are rolled back; if a cross-connection commit is needed, restoration is performed and verified separately before the test is called complete.

This gate validates session binding and session isolation. Separate subsequent tests must cover account, tenant-membership, and unit-membership epoch revoke/regrant, plus actual cross-connection statement-boundary and in-flight snapshot behavior.

## 8. Required race semantics and later tests

Keep the ADR-007 baseline:

- Protected transactions use READ COMMITTED.
- A protected statement that starts after a revocation commit must deny the revoked context.
- A statement already in progress is not forcibly cancelled by this policy; record whether it completes or aborts.
- The next protected statement after the revocation commit must deny.
- No authorization result is cached across protected statements.
- REPEATABLE READ is not permitted for protected transactions; SERIALIZABLE is not part of the baseline.

Test revocation from a second connection for account, exact session, tenant membership, and unit membership. Test a deliberately long-running multi-row protected statement while the second connection commits a revocation, then test the following statement. Record function volatility, internal SPI behavior, snapshot boundary, row visibility, and verifier calls.

## 9. Index plan

Begin with the existing primary keys:

- account: `poc_identities(actor_id)`;
- exact session: `poc_auth_sessions(session_hash)`;
- tenant membership: `poc_tenant_memberships(actor_id, tenant_id)`;
- unit membership: `poc_unit_memberships(actor_id, tenant_id, unit_id)`;
- unit lifecycle: `poc_units(tenant_id, unit_id)`;
- signing key: `context_keys(key_id)`.

Do not add secondary indexes merely because epoch columns are added. Compare PK lookup plans and representative cardinalities first. Add an actor-level session index only if revoke-all-session query plans justify it.

## 10. Implementation gates and safety boundary

1. Review/accept this token contract, especially unit lifecycle epoch and non-deletion/tombstone invariants.
2. Prepare a separate guarded disposable-only schema prototype for the epoch columns and mutation enforcement.
3. Implement an isolated candidate v2 verifier and issuer. Explicitly reject v1 on the v2 path.
4. Run script 037 session isolation, then account/tenant/unit epoch tests.
5. Run cross-connection and in-flight snapshot races through actual RLS-protected SELECTs.
6. Audit function owner, SECURITY mode, volatility, search_path, grants, global default ACL, role memberships, and query plans.
7. Benchmark before considering additional indexes or any caching.
8. Record the decision in ADRs before application or production implementation.

No production migration, persistent RLS rewrite, production role change, Laravel integration, service change, SQLRadius change, or MikroTik change is authorized by this proposal. ADR-003/007/008 remain subject to their own review and approval.
