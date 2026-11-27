# Trusted Backend Context Issuer — SINAU

**Status:** proposed technical design for the isolated PostgreSQL PoC; not a production implementation or approval.  
**Date:** 2026-11-19  
**Scope:** backend authentication-to-database-context boundary for tenant/unit RLS.  
**Related:** ADR-003, ADR-004, ADR-007, BP-PLT-05, TENANT-ISOLATION-TEST-PLAN.md, and PostgreSQL PoC scripts 007–011.

## 0. Implementation decision record

The implementation-neutral session, database-role, same-connection XID, transaction-local context, and connection-pool contract is tracked in [ADR-007](../09-decisions/ADR-007-TRUSTED-CONTEXT-ISSUER.md). ADR-007 is Proposed; this design document does not override the unresolved authentication, key-custody, role-switching, or in-flight revocation decisions.

## 1. Purpose

The trusted context issuer is the only backend component allowed to turn an authenticated application principal plus a requested tenant/unit scope into a short-lived database context token.

The current PoC has proved that PostgreSQL can verify a signed, audience-bound, time-limited, top-level-transaction-bound token and use its verified tenant/unit claims inside RLS policies. It has **not** yet proved that a real authenticated user is entitled to receive those claims. The current Python signer still uses fixed synthetic identity/scope values and must not be used as an application issuer.

This design closes that missing conceptual boundary. It does not create production migrations or decide the final authentication framework.

## 2. Normative source rules

The issuer must preserve the existing SINAU baseline:

- A global user identity is not a grant to any tenant or unit.
- A user can have more than one tenant membership.
- Tenant membership does not automatically grant access to every education unit.
- Unit membership is an explicit grant for a specific unit.
- Membership, role/permission, tenant lifecycle, unit lifecycle, verification, subscription, and entitlement are separate state dimensions.
- Role names alone are not sufficient; permissions are evaluated with scope and resource relationship.
- User, tenant, unit, membership, and role changes must be auditable. Revocation must invalidate subsequent access and associated session/cache grants.
- Context selectors from a route, request body, query string, cookie, or header are hints only. The server must prove the grant independently.

These are baseline requirements, not permission to assume that every open policy question has already been decided.

## 3. Trust boundary and responsibilities

### Trusted inputs

1. **Authenticated principal:** an immutable server-side principal produced by the authentication/session middleware after credential validation. It contains the globally authenticated user ID and authentication assurance/session metadata.
2. **Requested tenant and unit:** selectors chosen by the user or route. They are untrusted until checked against membership.
3. **Database transaction:** the same PostgreSQL connection and top-level transaction that will execute tenant-scoped queries.
4. **Signing key:** supplied to the backend issuer through a dedicated secret-management path. It must not be sent by a browser/client, written to logs, or committed to Git.

### Responsibilities

| Component | Responsibility | Must not do |
|---|---|---|
| Authentication middleware | Validate login/session/MFA and produce authenticated principal | Accept actor ID from request payload as authenticated identity |
| Context issuer | Validate principal, requested scope, membership and lifecycle gates; sign transaction-bound claims | Grant scope just because the caller knows a tenant/unit UUID |
| Application authorization/policy layer | Evaluate permission, role scope, delegation ceiling and resource relationships | Treat a valid context token as proof of every action permission |
| Entitlement evaluator | Enforce feature/quota/plan rules on relevant operations | Convert entitlement into a user membership or role |
| PostgreSQL verifier + RLS | Authenticate token claims and constrain rows to verified tenant/unit scope | Replace application authorization, resource-level checks, or audit |
| Audit service | Record context selection, grant/rejection, membership/role changes and sensitive actions | Store bearer token, HMAC key, password, or session secret |

## 4. Issuance contract

Conceptual interface:

**issueContext(authenticatedPrincipal, requestedTenantId, requestedUnitId?, transaction)**

The implementation must receive authenticatedPrincipal from trusted server-side middleware. It must not accept a free-form actor/user ID as proof of identity.

### Required validation order

1. **Authentication validity**
   - Principal exists and is authenticated.
   - Global account is active and not locked/disabled.
   - Authentication session is active, not expired, and not revoked.
   - Sensitive operations apply the configured MFA/assurance policy.
2. **Tenant membership**
   - The principal has an active tenant membership for the requested tenant.
   - valid_from is less than or equal to server time.
   - valid_until is null or later than server time.
   - Membership is not suspended, revoked, or expired.
3. **Tenant lifecycle**
   - Tenant exists and is in a lifecycle state that permits the requested operation.
   - Pending-verification, suspended, and closed states follow their separately approved access policies. Do not equate verification, subscription, or tenant status.
4. **Unit scope, when requested**
   - The unit exists and belongs to the requested tenant.
   - The unit is in a lifecycle state that permits the requested operation.
   - The principal has an active unit membership for that exact tenant/unit pair, with a valid effective period.
   - Tenant membership alone is insufficient for a unit-scoped token.
5. **Role/permission**
   - The application policy layer confirms the required permission at the correct platform/tenant/unit scope.
   - Delegation ceiling prevents an inviter/admin from granting a role or permission above their authority.
   - Teacher/class, guardian/child, student/self, and other resource relationships are checked at the use case/resource layer.
6. **Entitlement**
   - For operations governed by a plan or quota, the backend separately checks the current entitlement before executing the operation.
   - Entitlement is not embedded as a broad authorization grant in the tenant/unit context token. A valid context token does not imply that a feature is paid for or enabled.
7. **Transaction binding**
   - Begin the database transaction on the connection that will run the protected query.
   - Allocate/record that transaction's top-level XID.
   - Validate membership and scope using the trusted backend/database path.
   - Sign a new token for that exact XID. Never cache or reuse a token in another transaction or connection.
8. **Install context**
   - Set app.context_token transaction-locally (set_config(..., true) or equivalent SET LOCAL).
   - Run protected SQL on the same connection/transaction.
   - Commit or roll back. Transaction-local context must disappear at the boundary.
9. **Audit and response**
   - Record actor, scope, result, reason code, correlation ID, timestamp, and relevant policy version.
   - Never log the token, session secret, MAC key, password, or raw credential.

A failure at any validation stage must fail closed and must not execute a protected query or produce a partially scoped context.

## 5. Tenant-level versus unit-level context

- **Tenant-level context** uses a null unit claim. It is appropriate only for explicitly tenant-scoped operations whose permission allows them. It must not reveal unit-scoped academic rows.
- **Unit-level context** includes one concrete unit ID and requires active membership in that exact unit plus membership in its parent tenant.
- A tenant admin does not automatically receive academic data access across units. Explicit per-unit grants or narrowly defined tenant-level operations are required.
- Cross-tenant unit transfer is not a context switch; it remains a separate high-impact workflow with its own approval, ownership, audit, and data-integrity rules.

The current PoC policy treats a null unit claim as no match for ordinary unit-scoped rows; audit_events has a separately defined tenant-level row rule. Verify these special cases in policy tests before treating them as final product policy.

## 6. Token contract and transaction lifecycle

The current PoC v1 token fields are:

**v1 | audience | kid | actor_uuid | tenant_uuid | unit_uuid_or_dash | xid8 | iat | exp | nonce_hex | mac_hex**

Constraints already tested in PostgreSQL PoC:

- Exact audience/database match.
- Canonical lowercase UUID and hexadecimal fields.
- Canonical decimal XID and timestamps (no leading zeros except the value zero).
- 16-byte nonce and 32-byte HMAC-SHA256.
- Maximum lifetime 300 seconds; the test signer defaults to 240 seconds.
- Verification requires the same allocated top-level transaction XID.
- Only active/not-yet-revoked key IDs are accepted.

Issuer rules:

- Generate a fresh random nonce and MAC for every transaction context.
- Sign only after the transaction XID exists.
- Keep the token in application memory or a narrowly scoped transaction-local parameter; never return it to the browser.
- Do not put the token in query logs, tracing spans, exceptions, debug dumps, database audit payloads, or application telemetry.
- A token is a bearer credential for its bound transaction. A same-transaction holder may reuse it until transaction end/expiry; it is not a single-query token.
- The v1 HMAC key is shared between signer and verifier. Production key custody must be reviewed; asymmetric signing (backend private key, database public key) should be evaluated before production if DBA/DB compromise is in the threat model.

## 7. Membership revocation and transaction semantics

The PoC currently authenticates token claims but does not query membership state on each RLS evaluation. Therefore a membership revoked after context issuance may not invalidate an already-open transaction's token.

Proposed minimum semantics for review:

- A newly starting transaction must not receive context after membership/session revocation has committed.
- An already-running request transaction may finish only within the short request/transaction timeout and token expiry, unless product/security policy requires immediate interruption.
- Revocation must invalidate subsequent transactions and related server sessions/cache grants.
- If immediate revocation within an open transaction is required, the design must add a current authorization epoch/revocation check to token verification (or an equivalent database-enforced mechanism), and test the locking/isolation race. Do not claim immediate revocation based only on the present PoC.

This in-flight transaction policy remains a decision for security/product review.

## 8. Database and service boundaries

The repository's ADR-003 defines conceptual entities including users, tenant_memberships, unit_memberships, permissions, roles, tenant_membership_roles, and unit_membership_roles. The current 001-schema.sql PoC does not implement this identity/membership model. These entities must not be presumed to exist in sinau_design_poc.

Before an executable membership issuer PoC is built, create isolated synthetic fixtures in a dedicated PoC schema or tables. The fixtures must include:

- active and disabled global identities;
- active, suspended, revoked, expired, and not-yet-valid tenant memberships;
- active and revoked unit memberships;
- units whose tenant_id does not match the selected tenant;
- sessions that are active, expired, and revoked;
- an explicit separation between membership and an entitlement/feature gate.

The fixture must be synthetic, must not copy real people, and must not alter the accepted product schema or production database.



### Current synthetic PoC fixture implementation

The database-only synthetic membership-validation experiment is prepared in:

- `docs/03-database/poc/010-context-issuer-fixtures.sql` (type qualification fix commit `b51f2227187482c623664f14dfd09ad2ac8db042`; verified blob `c415e7a2a1a56722d1b371f99c1585669f38ef4f`). It creates private synthetic identities, hashed session fixtures, tenant memberships, unit memberships, an active/inactive private unit catalog, and separate feature entitlements. It also creates a NOLOGIN issuer-test role and a narrow SECURITY DEFINER validator. The validator accepts a synthetic session bearer and requested tenant/unit; it resolves actor identity from the stored hash and has no caller-supplied actor_id parameter. The corrected script was executed successfully in `sinau_design_poc`.
- `docs/03-database/poc/011-context-issuer-validation-tests.sql` (private-schema privilege-test fix commit `4c6ced509d65a84c345b47eab8bb9e67a5b0c6a4`; verified blob `f31c3a8ec405e0ea82bc8bdb24a8c9f9a80bbb65`). It tests active access, revoked unit grant, revoked tenant membership, tenant-only context, disabled global identity, revoked/expired session, future/suspended/expired tenant membership, expired unit membership, inactive unit, tenant/unit mismatch, entitlement separation, and least-privilege restrictions for the RLS query role. The corrected file was executed successfully; all ISS-01—ISS-14 tests and the final query-role privilege test passed, then the test transaction rolled back.
- The role grant from `sinau_poc` to `sinau_context_issuer_poc` is only a test convenience for role switching. It is not a production role design.
- The unit catalog is private synthetic fixture metadata rather than a query against `public.education_units`. That table is FORCE-RLS protected; the validator must not bypass its policy before a signed context is installed.
- Session strings in the fixture/test files are fixed, public synthetic values; they are not real user credentials and must never be reused for application login.

**Execution status (2026-11-19):** Both corrected scripts were executed against `sinau_design_poc` only. Script 010 installed the synthetic fixtures and reported the validator as owned by `sinau_context_owner`, `SECURITY DEFINER`, VOLATILE, PARALLEL UNSAFE, with fixed `search_path=pg_catalog, pg_temp`; issuer EXECUTE is granted while PUBLIC/query-role execution and direct fixture/key-table access are denied. Script 011 passed ISS-01 through ISS-14, including fail-closed handling for unknown/empty session credentials, and passed the final privilege check proving `sinau_rls_test` cannot execute the validator, read membership/key fixtures, or mutate memberships. The script ended with `ROLLBACK` and `CONTEXT ISSUER VALIDATION TESTS PASSED`. This is verified synthetic database membership-validation only. The validator is not a token signer; it does not authenticate a real browser session, validate final permission/delegation/resource relationship rules, apply the final tenant/unit lifecycle policy, or create an RLS context token. The actual application issuer remains unimplemented pending the approved authentication stack and least-privilege runtime connection design.

### Least-privilege requirements

- The web/application database role must not own protected tables, be superuser, have BYPASSRLS, or inherit an administrative role.
- The signing key must not be readable by the ordinary SQL role or end user. The backend process receives it only through a dedicated secret channel.
- Membership lookup must use parameterized queries and a narrowly scoped service contract.
- The RLS verifier may read key material only through its restricted security-definer function; the request role must not read the key table or execute raw HMAC directly.
- Do not grant the test role or ordinary SQL clients permission to insert/update membership, sessions, roles, or entitlement fixtures.
- Keep the issuer's database role, query role, and administrative migration role distinct in the design. Do not collapse them for convenience in production.

## 9. Threat and abuse cases

| Threat | Required control | Test evidence |
|---|---|---|
| Client submits another actor ID | Actor comes only from authenticated server principal | Forged actor field is ignored/rejected |
| Client changes tenant_id or unit_id | Treat selectors as hints; query active membership | Unauthorized tenant/unit selection rejected |
| Tenant membership mistaken for all unit access | Require explicit unit membership | Tenant member without unit grant cannot receive unit context |
| Revoked/expired membership reused | Validate status and effective dates per new transaction; invalidate cache/session | Revoked/expired cases rejected |
| Session replay after logout | Session active/revocation/expiry check | Revoked session cannot obtain new context |
| Tenant/unit disabled | Lifecycle policy check | Inactive scope cannot receive ordinary operational context |
| Role escalation through invitation | Delegation ceiling and scoped permission | Above-ceiling grant rejected |
| Entitlement treated as permission | Separate feature/quota evaluator | Role without entitlement and entitlement without role both fail as appropriate |
| Token stolen/replayed | Short TTL, XID binding, no browser exposure, no logs | Cross-transaction replay rejected |
| Secret disclosure | Secret manager, permissions, key rotation, no logs | File/secret access tests and rotation drill |
| SQL role bypass | Separate non-owner/no-BYPASSRLS runtime role | Role/catalog privilege tests |
| Membership revoked mid-transaction | Explicit in-flight policy or authorization epoch | Concurrent revoke/use test |

## 10. Additional acceptance matrix for a real backend issuer

The database-only synthetic membership fixture tests in `011-context-issuer-validation-tests.sql` have passed, but they are not an end-to-end application issuer. The matrix below is a separate set of acceptance requirements for the eventual real backend integration; none of these application-level cases is established by the synthetic fixture result alone. The real backend issuer must not be marked complete until these cases have actual PostgreSQL/backend output:

| ID | Scenario | Expected |
|---|---|---|
| APP-ISS-01 | Active user + active tenant membership + active unit membership | Unit token issued |
| APP-ISS-02 | Active tenant membership but no unit membership | Unit token denied |
| APP-ISS-03 | Tenant membership suspended/revoked/expired/not-yet-valid | Denied |
| APP-ISS-04 | Unit membership revoked/expired/not-yet-valid | Denied |
| APP-ISS-05 | Global user disabled/locked | Denied |
| APP-ISS-06 | Authentication session expired/revoked | Denied |
| APP-ISS-07 | Unit belongs to another tenant | Denied without revealing foreign tenant information |
| APP-ISS-08 | Tenant-level request with active tenant membership and unit null | Tenant-only context issued, subject to permission |
| APP-ISS-09 | Caller supplies forged actor ID distinct from authenticated principal | Supplied actor ID ignored; actual principal used |
| APP-ISS-10 | Feature entitlement missing/expired | Relevant feature operation denied separately; context alone does not grant the feature |
| APP-ISS-11 | Membership revoked after prior transaction | New transaction cannot obtain context |
| APP-ISS-12 | Token is copied to another top-level XID | Database verifier rejects it |
| APP-ISS-13 | Request role attempts to read signing key or mutate membership | Permission denied |
| APP-ISS-14 | Context transaction rolls back and connection is reused | Context absent in next transaction |

## 11. Decisions still required before production

1. Final authentication/session technology and how server-side authenticated principals are represented.
2. Final identity/membership physical schema, including effective-dated uniqueness and concurrent revocation.
3. Tenant/unit lifecycle access matrix for pending verification, suspension, closure, billing restriction, and restricted data export.
4. Permission inheritance/delegation rules and resource-level relationships.
5. Entitlement policy for restricted operations and downgrade behavior.
6. In-flight transaction semantics for membership revocation.
7. HMAC versus asymmetric signing and production key-management/KMS rotation.
8. Runtime database role and pooler topology, including whether the same connection is guaranteed through XID allocation, context installation, and protected queries.

## 12. Non-goals and safety boundary

- This document does not implement login, MFA, a user-facing session endpoint, RBAC, billing, or entitlement.
- This document does not authorize production schema/migrations or make Laravel/Vue/Inertia a final stack decision.
- The current synthetic signer must remain PoC-only.
- Any executable test must run only against sinau_design_poc, with synthetic fixtures and explicit rollback/cleanup.
- Never touch application database sinau, role sinau_app, SQLRadius, or MikroTik as part of this PoC.
- PR #1 stays Draft/open and must not be merged without explicit approval.


## 13. Runtime capability-role boundary and default function ACL — 2026-11-27

The read-only runtime audit 023 confirms the PoC runtime login can SET ROLE only to the NOLOGIN issuer and query capability roles, with no inherited role path and no ADMIN OPTION. It cannot SET ROLE to the context owner, `sinau_poc`, or `postgres`. It has no direct schema USAGE/CREATE on private schemas and no direct EXECUTE on the context functions. The separate `sinau_poc` login is a PoC database-owner/test identity with inherited issuer/query capability; it is not an application runtime identity.

The existing same-connection issuer → query → issuer test needs the runtime SET memberships to preserve one top-level XID. The proposed model therefore treats runtime as a trusted backend executor whose SQL is only generated by controlled application code. This model does not protect against arbitrary SQL or SQL injection in a runtime session, which can explicitly assume either capability role. A different role topology would require a separately designed issuer/query connection flow and new XID-continuity tests.

The 023 audit also found no stored default-ACL row for `sinau_context_owner`. Source scripts 005 and 010 were corrected to use a global default function EXECUTE revoke. Script 024 was then executed successfully against `sinau_design_poc`: the global ACL now contains owner EXECUTE only, the four existing context functions remain non-executable by PUBLIC, and a newly created probe had owner EXECUTE=true/PUBLIC EXECUTE=false before its transaction rolled back. The final check confirmed the global default ACL persisted while the probe did not. This closes the default-function-ACL PoC gate only.

PostgreSQL 18 documents that VOLATILE functions obtain a fresh snapshot for each internal query, while STABLE/IMMUTABLE functions use the calling query snapshot. A new rollback-only two-connection probe, script 025, has been prepared to verify this behavior with a synthetic account-state row and a commit from a second connection. It has not yet been executed. The proposed verifier-v2 strategy is to retrieve key status and all authoritative authorization-state rows with one joined SELECT so that the verifier evaluates them from one coherent SPI statement snapshot. The live tests must still characterize revoke-before-check, revoke-during-check, and revoke-after-check behavior through actual RLS policies.

This section records PoC evidence and a proposed boundary only. It does not approve production role grants, SQL execution pathways, verifier implementation, or backend integration.
