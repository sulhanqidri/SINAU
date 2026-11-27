# Authorization Freshness and Session-Bound Context Token — Design Proposal

- **Status:** Design proposal only; not approved for implementation or production.
- **Date:** 2026-11-27
- **Scope:** PostgreSQL 18 disposable PoC `sinau_design_poc`.
- **Related:** ADR-003, ADR-007, ADR-008; PoC scripts 005, 010, 011, 018, 019, and 020.

> This document records a proposed design after the two-connection authorization-revocation experiment. It contains no executable SQL and grants no approval to change the PoC database, production database, application, RLS policies, roles, or services.

## 1. Executive decision proposal

Use a **hybrid design**:

1. **Live authoritative-state verification is the source of truth.** Every protected SQL statement must validate the current account, exact authentication session, tenant membership, and (when unit-scoped) unit membership. Authorization state must not be cached across protected statements.
2. **Monotonic authorization generations prevent resurrection.** Account, tenant-membership, and unit-membership generations are included in the signed context and compared with the current authoritative rows. A revoke/regrant or disable/reenable cycle must advance the relevant generation. Epochs supplement live checks; they do not replace them.
3. **Session identity is bound explicitly.** The token identifies exactly one server-side session through a non-bearer SHA-256 reference that matches the stored session record. A session reference is never reused. Revoking one session must not revoke another session belonging to the same actor.
4. **Preserve the approved transaction policy.** Protected transactions use `READ COMMITTED`; a protected statement that starts after a revocation commit must be denied. No cross-statement authorization cache is permitted. A statement already in progress is not forcibly cancelled by this policy.

This is a recommendation for review, not an accepted ADR decision. Live checks alone are insufficient for the required "old token stays invalid after reactivation" behavior unless reactivation also invalidates the old generation/session. Epoch-only checks are insufficient because a missed version increment can leave stale authorization valid.

## 2. Evidence and current gap

The installed PoC verifier in `005-verify-context-token.sql` validates token structure, HMAC, audience/database, time window, top-level transaction XID, and signing-key status. Its v1 token contract contains actor, tenant, unit, XID, time, nonce, and MAC, but no session identity or authorization generation.

The issuer fixtures in `010-context-issuer-fixtures.sql` and validation tests in `011-context-issuer-validation-tests.sql` check account, session, tenant membership, and unit membership at context-request time. That does not refresh those facts when a later protected statement evaluates RLS.

The read-only audit in script 018 confirmed the installed verifier does not reference the four authorization-state fixture tables, while the issuer validator does. The four valid READ COMMITTED two-connection cases in scripts 019/020 then produced:

| Source changed by Session B | Session A next protected statement |
|---|---|
| Account changed from active to disabled | `FINDING REPRODUCED` |
| One active session changed to revoked | `FINDING REPRODUCED` |
| Tenant membership changed to revoked | `FINDING REPRODUCED` |
| Unit membership changed to revoked | `FINDING REPRODUCED` |

All four exact synthetic rows were restored and the final read-only audit reported one matching active row and `PASS` for each. The audit used `BEGIN READ ONLY` and ended with `ROLLBACK`. These are PoC findings only, not evidence of impact to production.

### Scope limits of the evidence

- The existing session case had only one active synthetic session for the actor. It did not prove per-session behavior when an actor has multiple active sessions.
- The current token has no session identifier; the experiment therefore cannot establish that revoking one of several sessions leaves the others usable.
- The four tests revoke state and commit in Session B **before** Session A begins its next protected SELECT. They establish the missing next-statement check, not forced cancellation of a statement already running.
- An earlier mismatched-XID attempt is excluded; the four recorded cases passed their baseline with matching XIDs.
- The experiment changed only synthetic rows in `sinau_design_poc`. No production database, role, migration, application, SQLRadius, or MikroTik was changed.

## 3. Proposed token v2 contract

Candidate canonical payload:

```text
v2|audience|kid|actor_uuid|session_ref_hex|tenant_uuid|unit_uuid_or_dash|xid8|iat|exp|nonce_hex|account_epoch|tenant_membership_epoch|unit_membership_epoch|mac_hex
```

The MAC covers every preceding field in canonical order and canonical encoding.

| Claim | Requirement |
|---|---|
| `v2` | Explicit version; v1 is not silently upgraded or accepted by the v2 verifier |
| `audience` | Must equal the intended database audience and current database policy |
| `kid` | Identifies a currently valid signing key |
| `actor_uuid` | Derived from a trusted authenticated principal/session, never from request input |
| `session_ref_hex` | 32-byte SHA-256 reference, encoded as exactly 64 lowercase hexadecimal characters |
| `tenant_uuid` | Tenant selected by the request but authorized by the server |
| `unit_uuid_or_dash` | Explicit unit scope, or `-` for a tenant-only context |
| `xid8` | Exact top-level transaction XID |
| `iat`, `exp` | Canonical integer timestamps; lifetime and clock-skew bounds remain configuration decisions |
| `nonce_hex` | Cryptographically random per-token nonce; not a substitute for XID binding |
| `account_epoch` | Monotonically increasing generation from the authoritative account row |
| `tenant_membership_epoch` | Generation for this actor/tenant membership |
| `unit_membership_epoch` | Generation for this actor/tenant/unit membership; `-` when no unit is bound |
| `mac_hex` | Signature over the complete canonical payload |

### 3.1 Session binding

- The backend obtains a server-side session reference only after authenticating the session. The database lookup uses its SHA-256 reference; raw cookie values, raw session bearers, passwords, and credentials never enter the token.
- The reference must match the stored session hash and the actor in the same row. A hash is an identifier, not proof of login; possession of the hash alone must not authenticate a request.
- A session reference is unique and never reused. Logout/revocation marks that exact session inactive. A new login creates a new reference.
- If an actor has sessions A and B, revoking A must make A fail while B remains independently valid (subject to account and membership state).
- Global account disable invalidates all contexts through account state and generation; session-specific logout must not increment a global account generation.
- The token is internal to the backend/database transaction. It is never returned to the browser, logged, placed in URLs, or stored in a cross-request cache.

The fixture table currently uses `poc_auth_sessions.session_hash` as its primary key. The exact production session-reference derivation and mapping to the chosen server-side session store remain open and must not be inferred from the synthetic fixture strings.

### 3.2 Epoch semantics

The proposed v2 payload includes account, tenant-membership, and unit-membership generations. These generations are monotonically increasing integers (or another strictly monotonic, non-reusable version representation).

- Increment the relevant generation whenever an authorization grant is revoked, replaced, or re-granted in a way that must invalidate older contexts.
- Account disable/reenable must not revive a context issued before disable. Account disable should also revoke existing sessions according to the approved account policy; the account generation provides an additional global invalidation boundary.
- Tenant or unit membership revoke/regrant must produce a new generation. Reusing the same active row without advancing its generation could resurrect an unexpired old token and is not acceptable.
- Do not reset or decrement generations. Do not reuse identifiers for a different membership/session.
- Session epoch is not required in the minimal proposal if `session_ref` is immutable and unique, never reused, and session state is checked live. Add a session generation only if the final session lifecycle permits reuse or replacement of the same session identity; the preferred rule is to prohibit reuse.
- For tenant-only context, unit claim and unit generation must both use the canonical no-unit sentinel. A tenant-only token must not pass a unit-scoped policy.
- Epoch claims must be covered by the MAC and compared against the current row on every protected statement. A token-side epoch without a live comparison provides no freshness.

The exact epoch column names, integer width, overflow policy, update ownership, and mutation pathways are not selected here. They require schema inventory and a separate PoC change proposal.

## 4. Proposed verifier contract

The future verifier must perform these checks in a fail-closed sequence:

1. Bound input size and reject NULL, empty, malformed, non-canonical, unknown-version, wrong-field-count, and out-of-range values before unsafe casts.
2. Verify audience, key status, MAC, issue/expiry bounds, nonce syntax, and exact XID binding.
3. Read the authoritative account row by `actor_id`; require active status and exact `account_epoch`.
4. Read the exact session row using `session_ref` and `actor_id`; require active status, not revoked, and not expired.
5. Read the exact tenant-membership row by `(actor_id, tenant_id)`; require active status, effective dates, no revocation, and exact membership generation.
6. For a unit-bound token, read the exact unit-membership row by `(actor_id, tenant_id, unit_id)` and the corresponding unit; require active/effective membership, correct tenant ownership, permitted unit lifecycle, and exact unit-membership generation.
7. Return exactly one verified context only when every applicable check succeeds. Missing or mismatched records return no context; unexpected database/permission errors abort the protected statement rather than exposing internal details or falling back to unverified claims.

The verifier must not accept `actor_id`, `session_ref`, tenant, unit, or epoch values from mutable client GUCs as trusted input. The only client-writable GUC remains the opaque carrier `app.context_token`; all scope must be derived from the verified token and authoritative records.

The RLS policies continue to use `sinau_private.current_verified_context()`. The accessor must not create a bypass path, and RLS remains defense-in-depth rather than a replacement for application authorization. Role/permission, delegation, resource relationships, feature entitlement, and use-case authorization remain separate checks.

### 4.1 Privilege and function safety

- Keep the verifier owner non-login and separate from runtime/query roles.
- Keep a fixed, audited `search_path`; schema-qualify every non-system relation, type, and function.
- Runtime/query roles must not read key bytes or authorization tables directly and must not execute the issuer-validation capability.
- Do not grant new table privileges to runtime roles as a shortcut.
- Re-audit function owner, SECURITY DEFINER/INVOKER mode, volatility, ACL, default privileges, RLS ownership, and all dependencies before any implementation.
- Do not catch and suppress unexpected verifier exceptions. Invalid/unauthorized contexts must fail closed; unexpected database errors must abort the statement.

## 5. Snapshot, concurrency, and revocation semantics

The previously approved ADR-007 policy remains the baseline:

- Every protected transaction uses `READ COMMITTED`.
- A protected statement that starts after a revocation commit must deny the revoked context.
- A statement already in progress is not forcibly cancelled by this policy and may complete.
- `REPEATABLE READ` is not permitted for protected transactions. `SERIALIZABLE` is not part of the baseline.
- Authorization results are not cached across protected statements.

### 5.1 Important snapshot question to prove

The installed `verify_context_token()` is currently `VOLATILE` and performs internal SQL reads. PostgreSQL function volatility and snapshots can affect when internal reads see concurrent commits. The design must not assume that labeling a function `VOLATILE`, `STABLE`, or `IMMUTABLE` automatically proves the required statement boundary.

Before implementation, run a controlled PoC with a deliberately long-running protected statement and a second connection that commits revocation at known points:

- revoke commit completed before the protected statement begins: the statement must be denied;
- protected statement begins and obtains its relevant snapshot before revocation commit: it may complete under the approved in-flight policy;
- the next protected statement after revocation commit: it must be denied;
- repeat with multiple rows and policy evaluations to detect mixed visibility within one statement.

Record the actual function volatility, internal SPI query behavior, statement snapshot, and observed RLS result. Do not change function volatility or snapshot strategy without this evidence and review.

### 5.2 Required race tests

| Race | Required outcome |
|---|---|
| Account/session/membership revoke commits before the next protected statement | Deny |
| Revoke commits while a protected statement is already executing | No forced cancellation guarantee; record whether it completes or aborts |
| Next statement after that in-flight statement | Deny |
| Revoke and regrant before the old token is reused | Old token remains denied because its generation is stale |
| Session A revoked while session B for same actor remains active | A denied; B remains eligible |
| Two independent revocations overlap | No stale generation or reactivation can restore the old context |
| Verifier cannot read an authoritative table or key | Statement fails closed; no unverified context |

The two-connection test already completed covers the first case for four sources only in the current v1 verifier (and reproduced the gap). It does not cover the in-flight race or the v2 contract.

## 6. Index and query-cost strategy

Use the existing primary keys for point lookups first. Current PoC keys reported in the fixture design are:

| Table | Existing lookup key | Intended verifier lookup |
|---|---|---|
| `poc_identities` | PK `(actor_id)` | Exact actor |
| `poc_auth_sessions` | PK `(session_hash)` | Exact session reference, then verify actor |
| `poc_tenant_memberships` | PK `(actor_id, tenant_id)` | Exact tenant membership |
| `poc_unit_memberships` | PK `(actor_id, tenant_id, unit_id)` | Exact unit membership |
| `poc_units` | PK `(tenant_id, unit_id)` | Exact unit and tenant ownership |
| `context_keys` | PK `(key_id)` | Exact signing key |

Do not add low-selectivity status indexes or duplicate indexes without evidence. Epoch columns do not inherently require separate indexes when the lookup is already by the full primary key; compare the row after PK lookup.

A separate index on session `actor_id` may help a bulk "logout all sessions for actor" operation. Add it only if the revoke-all query plan and representative cardinalities justify it. It is not needed for the exact session verifier lookup by `session_hash`.

### 6.1 Benchmark plan

Compare current v1 signature/XID/key verification, live state lookups by existing primary keys, live checks plus generation comparisons, and RLS statements with one row and representative multi-row result sets.

Use synthetic data at representative cardinalities and 1, 10, 50, and 100 protected statements per transaction. Record median, P95, P99, throughput, CPU, `EXPLAIN (ANALYZE, BUFFERS)`, buffer hits/reads, rows examined, query count, and planning/execution time. Separate cryptographic cost from authorization lookup and RLS policy cost. No latency target is claimed until measured.

## 7. Required PoC test matrix

All tests must use synthetic fixtures in `sinau_design_poc`, explicit preconditions, exact expected row counts, and a final state audit. Tests that commit a revocation must have a separately checked restoration step; do not describe those as all-rollback tests.

1. Two active sessions for one actor: revoke A; A denied and B remains eligible.
2. Account disable increments account generation and invalidates existing tokens; reenable does not revive the prior token.
3. Session expiry and explicit session revoke each deny the matching session.
4. Tenant membership revoke/regrant increments generation; old token denied, newly issued token eligible.
5. Unit membership revoke/regrant increments generation; old token denied, newly issued token eligible.
6. Wrong actor/session pairing, wrong tenant, wrong unit, inactive unit, and tenant/unit mismatch all deny.
7. Wrong or missing epoch, malformed token, invalid MAC, unknown key, expired token, wrong audience, and wrong XID all deny.
8. v1 token is rejected by the v2 verifier; no silent compatibility fallback.
9. The four source revocations committed before a later protected statement are denied through actual RLS policies, not only by calling the verifier directly.
10. In-flight statement and multi-row snapshot behavior are characterized as described in section 5.
11. Commit, rollback, exception, timeout, and connection reuse leave no transaction-local context or stale verified state.
12. Repeated statements in the same top-level transaction re-evaluate authorization; no cross-statement cache.
13. Verify query-role privileges, function ACL/owner/search_path, and inability to read key or authorization tables directly.
14. Benchmark current and candidate paths using the plan in section 6.

A test is PASS only when the expected result, fixture restoration, and final read-only audit all succeed. SKIP, an untested scenario, or a baseline failure is not a pass.

## 8. Implementation sequence and gates

1. **Read-only inventory:** confirm installed function definitions and metadata, table keys/columns, constraints, RLS policies, role memberships, grants, and representative plans.
2. **Token contract review:** settle v2 canonical format, session-reference derivation, generation semantics, token lifetime, audience, and key handling.
3. **Disposable PoC schema proposal:** only after review, prepare a new guarded script for synthetic generation columns and any required indexes. No production DDL.
4. **Verifier prototype:** implement only in `sinau_design_poc`, with fixed search_path, least privilege, no raw key exposure, and explicit v1 rejection.
5. **Behavior and race tests:** run the complete matrix, including multi-session isolation and statement-boundary races.
6. **Benchmark and review:** compare measured costs and inspect plans before adding indexes or caching.
7. **ADR decision:** record accepted/rejected design choices and remaining gaps. Production implementation remains a separate approval.

## 9. Safety boundary

- Do not run any script from this proposal; this document contains no executable SQL.
- Do not modify `sinau`, `sinau_app`, production migrations, production roles, Laravel/Fortify, services, SQLRadius, or MikroTik.
- Do not reuse the PoC signer with static actor/tenant/unit values as an application issuer.
- Do not expose session identifiers, token payloads, MACs, key material, or credentials in logs or evidence.
- Keep PR #1 **Open and Draft**. Do not merge it without explicit instruction.
- ADR-007 remains **Proposed** until the design and all required PoC gates are reviewed and accepted.

## 10. Review questions still open

1. What server-side session store/reference contract will produce the immutable `session_ref` without exposing the raw credential?
2. What are the exact account and membership generation columns, and which narrowly defined database/application operations may increment them?
3. Must tenant and unit lifecycle transitions also have monotonic generations to prevent old contexts reviving after suspend/reactivate?
4. What is the final token lifetime and accepted clock skew for the request/transaction budget?
5. What function volatility/snapshot strategy provides the approved statement boundary without caching across statements?
6. What benchmark cardinalities and latency budgets represent the expected SINAU deployment?
7. Which key algorithm and custody model will be evaluated for production, separate from the HMAC PoC?

Until these questions and test gates are resolved, token v2 is a proposal—not an implementation contract.


## 11. Repository source inventory — not a live database result

A source review of committed scripts `010-context-issuer-fixtures.sql`, `011-context-issuer-validation-tests.sql`, and `005-verify-context-token.sql` establishes the following **repository baseline only**:

| Source table | Key in the fixture DDL | Relevant fields | Generation field in source DDL |
|---|---|---|---|
| `poc_identities` | PK `(actor_id)` | `account_status`, `created_at` | None |
| `poc_auth_sessions` | PK `(session_hash)` | `actor_id`, status, authentication/expiry/revocation timestamps, assurance level | None |
| `poc_tenant_memberships` | PK `(actor_id, tenant_id)` | status, valid-from/until, revoked-at | None |
| `poc_unit_memberships` | PK `(actor_id, tenant_id, unit_id)` | status, valid-from/until, revoked-at | None |
| `poc_units` | PK `(tenant_id, unit_id)` | `unit_status` | None |
| `poc_feature_entitlements` | PK `(tenant_id, feature_code)` | entitlement status and validity period | Not part of context-membership freshness |

Additional source-level observations:

- `poc_auth_sessions.session_hash` is `bytea` with a 32-byte length check. The issuer validator hashes its supplied session token with SHA-256 and searches by that primary key; the actor is derived from the matching session row.
- The fixture DDL defines no explicit secondary index for session `actor_id`. The exact session lookup is supported by `session_hash` PK. A bulk logout-by-actor index is a separate measured optimization, not a verifier prerequisite.
- `validate_context_request()` is `VOLATILE SECURITY DEFINER` with fixed `search_path=pg_catalog, pg_temp`. It checks account/session state and tenant/unit membership at context-request time.
- The installed v1 verifier source checks token syntax, HMAC, audience/database, time window, top-level XID, and signing-key status. Its token has no session claim and verifier body has no live references to the four authorization fixture tables.
- The fixture tables currently contain no account, tenant-membership, or unit-membership generation columns. The token v2 generations and session claim remain proposals; no schema change is implied by this inventory.

These facts are derived from repository source, not from the live PostgreSQL instance. Script 022 is the required runtime comparison and must be executed successfully before preparing any DDL. If the installed schema, constraints, indexes, owners, privileges, function definitions, or role memberships differ, record the difference and stop to reconcile it rather than assuming either side is correct.
