# PostgreSQL 18 Design PoC — SINAU

**Status:** executable design experiment; not production schema, not migration approval.  
**Target:** PostgreSQL 18 in a disposable database only.  
**Repository branch:** \`feature/phase-0-requirements-blueprint\`.

## Objective

Test selected high-risk invariants from \`LOGICAL-ERD-MVP.md\` v0.2.0 and audit AUD-LD-001:

1. Composite tenant/unit foreign keys.
2. Effective-dated student class placement and overlap prevention using \`btree_gist\` + exclusion constraint.
3. Attendance and assessment participant snapshots, including class/date validation.
4. Distinguishing scored zero from absent/pending/exempt.
5. Correction/revision linkage and idempotency key uniqueness at schema level.
6. Audit actor shape and correlation requirement.

The PoC deliberately does not implement the complete SINAU domain, authentication, RLS policy, file authorization, retention, API, or application transaction orchestration.

## Safety boundary

- Never run this PoC against the existing \`sinau\` database or SQLRadius database.
- Create a disposable database named \`sinau_design_poc\` and a separate role named \`sinau_poc\`.
- Do not reuse the production/application role \`sinau_app\`.
- Do not place database passwords in this repository, SQL files, shell history, or screenshots.
- The test file ends with ROLLBACK; schema creation is separate and persists only inside the disposable database.
- Drop only \`sinau_design_poc\` after preserving the output/evidence you need.

## 1. Create isolated database and role

Run on the SINAU Debian server as an administrator. First confirm the target cluster and that the database name is unused:

\`\`\`bash
sudo -u postgres psql -X -d postgres -v ON_ERROR_STOP=1 -c "SELECT version();"
sudo -u postgres psql -X -d postgres -Atc "SELECT datname FROM pg_database WHERE datname = 'sinau_design_poc';"
\`\`\`

If the second command prints nothing, create a dedicated login role. Use an interactive password prompt (do not paste the password into a command):

\`\`\`bash
sudo -u postgres psql -X -d postgres
\`\`\`

At the psql prompt:

\`\`\`sql
CREATE ROLE sinau_poc LOGIN;
\password sinau_poc
CREATE DATABASE sinau_design_poc OWNER sinau_poc;
\q
\`\`\`

If the role or database already exists, stop and inspect it; do not drop or overwrite it blindly.

## 2. Copy repository PoC files to the server

From a trusted workstation with the repository checked out, copy this directory to a temporary location on the SINAU server using your normal secure file-transfer method:

- \`docs/03-database/poc/001-schema.sql\`
- \`docs/03-database/poc/002-tests.sql\`

Do not copy these files into the application migration directory.

## 3. Execute

Confirm the target database explicitly before every psql command:

\`\`\`bash
psql -h 127.0.0.1 -U sinau_poc -d sinau_design_poc -X -v ON_ERROR_STOP=1 -f 001-schema.sql
psql -h 127.0.0.1 -U sinau_poc -d sinau_design_poc -X -v ON_ERROR_STOP=1 -f 002-tests.sql
\`\`\`

Expected output includes PASS notices for overlap, mismatched participant context, invalid score state, and invalid actor shape. The SQL test transaction rolls back fixture data at completion. The schema remains in this disposable database.

## 4. Manual concurrency test (two terminals)

Use two psql sessions connected to \`sinau_design_poc\`. Insert a test enrollment and one placement in session A, then attempt an overlapping placement for the same tenant/unit/enrollment in session B before A commits. Commit A. Session B must wait and then fail with exclusion_violation. Repeat with the transactions reversed. Record exact output and PostgreSQL version.

The fixture IDs in \`002-tests.sql\` are rolled back; create dedicated concurrency fixtures in a separate explicit transaction or a temporary copy of the schema. Do not alter the committed smoke-test file without recording the change.

## 5. Evidence to capture

Record:
- \`SELECT version();\`
- \`SELECT extname, extversion FROM pg_extension WHERE extname='btree_gist';\`
- Schema execution exit code.
- Test execution output and exit code.
- Concurrency test results from both sessions.
- Any failure, SQLSTATE, and exact statement (redact credentials/PII).

## 6. Current expected limitations / follow-up

- A composite FK proves tenant/unit and referenced-row identity; it does not alone prove every cross-domain temporal business rule.
- Trigger checks in this PoC validate participant placement at insert/update. Production design must also prevent later mutation of referenced placement/session context from invalidating an existing snapshot (immutability/locking or stronger FK design).
- Assessment score maximum is not yet enforced by a trigger in this reduced PoC; add a dedicated test/constraint strategy before considering score integrity accepted.
- Correction/revision tables prove reference shape and uniqueness only. Atomic approve/apply, current projection, stale revision conflict, and retry behavior require a transaction-level application PoC.
- RLS/authorization is not tested here. It needs separate non-owner role tests, FORCE ROW LEVEL SECURITY, tenant/unit context handling, connection-pool reset, background jobs, exports, and IDOR scenarios.
- This PoC does not close AUD-LD-06 guardian access or any privacy/security review.

## 7. Exit criteria

PoC is considered technically informative only after all SQL tests and concurrency tests have evidence. Logical design acceptance additionally requires:
- Product/domain-owner review of open policy choices.
- Privacy/security review (especially children, guardians, files, audit, retention).
- Reconciliation of ERD, Data Dictionary, ownership matrix, process specs, and test matrix.
- Explicit Product Owner acceptance before physical schema/migrations.

## Files

- \`001-schema.sql\` — candidate schema subset.
- \`002-tests.sql\` — positive/negative smoke tests.
- \`README.md\` — isolation, execution, evidence, and exit criteria.


## 7. RLS tenant/unit isolation test (separate from smoke tests)

The RLS experiment uses two additional scripts:

- `003-rls-setup.sql` — run as PostgreSQL administrator against `sinau_design_poc`. It creates a non-login role `sinau_rls_test`, seeds deterministic test fixtures before enabling RLS, applies `ENABLE ROW LEVEL SECURITY` and `FORCE ROW LEVEL SECURITY` to tenant-scoped tables, and grants limited table privileges to the test role.
- `004-rls-tests.sql` — run as `sinau_poc` against `sinau_design_poc`. It switches to `sinau_rls_test`, sets a simulated tenant/unit context, and tests SELECT, INSERT, UPDATE, and DELETE isolation. Its transaction ends with ROLLBACK.

Commands:

```bash
# Download both scripts from the same repository branch/commit used for this PoC.
# Then configure RLS as the PostgreSQL administrator:
sudo -u postgres psql -X -v ON_ERROR_STOP=1 -d sinau_design_poc -f 003-rls-setup.sql

# Run policy tests using the dedicated PoC login:
psql -h 127.0.0.1 -U sinau_poc -d sinau_design_poc -X -P pager=off -v ON_ERROR_STOP=1 -f 004-rls-tests.sql
```

Expected PASS notices cover same-unit visibility/write, cross-unit and cross-tenant read isolation, cross-unit UPDATE zero rows, cross-tenant DELETE zero rows, and cross-tenant INSERT rejection. The test transaction rolls back.

**Critical limitation:** this is a policy behavior test, not a complete authentication boundary test. The scripts use custom session settings `app.tenant_id` and `app.unit_id`. A database client able to issue arbitrary SQL can change those settings. Production must establish tenant/unit context through a trusted mechanism that validates the authenticated principal's memberships, and must test connection-pool reset, background jobs, exports, support access, and IDOR paths. Do not interpret a passing run as proof against context forgery or as production approval.

If the setup script reports that the role already exists, it is designed to reuse it. Do not run it against `sinau`, `sinau_app`, or SQLRadius.

## 8. Signed-context RLS integration (PoC)

The earlier `003-rls-setup.sql` / `004-rls-tests.sql` experiment used client-writable `app.tenant_id` and `app.unit_id` settings. A SQL caller can change those settings, so those policies are useful only for demonstrating policy mechanics; they are not a trusted tenant-context boundary.

`007-rls-signed-context.sql` is the next isolated experiment. It creates `sinau_private.current_verified_context()` as an invoker-rights accessor and replaces the `sinau_rls_isolation` predicates on tenant-scoped PoC tables. The accessor reads the opaque transaction-local `app.context_token` and calls `verify_context_token(text)`. The RLS policy obtains tenant/unit values only from verified claims, not from `app.tenant_id` or `app.unit_id`.

Run only after the signer/verifier/key store from this PoC is already installed, and only as the PostgreSQL administrator against `sinau_design_poc`:

```bash
sudo -u postgres psql -X -v ON_ERROR_STOP=1 -d sinau_design_poc -f 007-rls-signed-context.sql
```

Expected setup evidence:
- `current_verified_context()` is owned by `sinau_context_owner`, SECURITY INVOKER, VOLATILE, PARALLEL UNSAFE, with fixed `search_path=pg_catalog, pg_temp`.
- `sinau_rls_test` has EXECUTE on the accessor and the underlying verifier, but no access to key bytes.
- Tenant-scoped tables remain ENABLE/FORCE ROW LEVEL SECURITY; their `sinau_rls_isolation` policy expressions call the verified-context accessor.
- The global `tenants` registry remains outside RLS. `education_units` remains tenant-scoped. `audit_events` retains the special rule allowing tenant-level rows with `unit_id IS NULL`.

After setup, use the two-terminal flow in the handoff: begin a transaction as `sinau_poc`, set local role to `sinau_rls_test`, allocate XID, sign for exactly that XID, import the token into a temporary table, and set only `app.context_token` with `set_config(..., true)`. Do not print the token. Test the valid scope, then change the legacy `app.tenant_id` / `app.unit_id` settings to tenant B/unit B1: rows must remain limited to claims in the signed token. Replacing `app.context_token` with an invalid value must fail closed (zero visible scoped rows). Restore the valid token only from the temporary table, finish the assertions, then ROLLBACK and remove tmpfs token files.

Important limitations:
- The custom GUC `app.context_token` is intentionally client-writable; its value is safe as a carrier only because every policy evaluation derives scope from a cryptographically verified token. Never use the unsigned tenant/unit GUCs in an RLS predicate.
- A valid token is a bearer credential within its bound transaction. The trusted issuer/backend must authenticate the principal and verify current actor-to-tenant/unit membership before signing. The current PoC Python signer has hard-coded synthetic IDs and does not perform authentication or membership checks; it is not a production issuer.
- This script does not install a trusted context setter and does not prove connection-pool, rollback, nested-transaction, concurrency, performance, or real membership behavior. Those require separate tests.
- Do not treat this as production authorization approval. Do not run it against `sinau`, use `sinau_app`, or alter SQLRadius/MikroTik.

### 8.1 Functional assertions

After successfully applying `007-rls-signed-context.sql`, run the functional test in the same psql session/transaction that owns the token's XID:

1. Open psql against `sinau_design_poc`; set session authorization to `sinau_poc`; create a temporary token input table; grant SELECT/INSERT on it to `sinau_rls_test`; begin; set local role to `sinau_rls_test`; allocate and record `pg_current_xact_id()::text`.
2. Use `006-sign-context-token.py` in a separate Bash terminal to create a token for exactly that XID. Copy it into a postgres-owned mode-0600 file under `/run` (tmpfs). Never display the token or key.
3. At the original psql prompt, import the token into `pg_temp.poc_signed_context_input` using `\\copy`.
4. Stage `008-test-signed-context-rls.sql` under `/run` and run `\\i /run/008-test-signed-context-rls.sql` from that same psql session. Do not run the test file with a new psql process because the XID and temp table are session-bound.
5. Expected assertions: valid token sees only tenant A/unit A1; changing unsigned legacy `app.tenant_id` and `app.unit_id` to tenant B/unit B1 does not change visibility; empty/malformed token sees zero rows; same-scope INSERT succeeds; cross-tenant and cross-unit INSERTs are rejected by RLS `WITH CHECK`.
6. After all assertions pass, execute `ROLLBACK;`, exit psql, and remove both token copies from `/run`. Do not commit test data.

The functional SQL file is assertion-oriented and deliberately does not commit or roll back the outer transaction. If it raises an assertion error, the transaction becomes aborted; run `ROLLBACK;` before retrying with a fresh XID and token. The token is valid for at most 240 seconds; discard it if expired or if the transaction ends.

**Not yet executed:** adding this file to the repository is not evidence that the functional assertions passed. Record actual server output in the project tracker only after the user runs it.

### 8.2 Transaction-local context reset

After the assertions in `008-test-signed-context-rls.sql` pass, do not exit psql yet. First execute `ROLLBACK;` to end the token-bearing transaction. In the same psql connection, keep `SET SESSION AUTHORIZATION sinau_poc` unchanged and run:

```sql
\\i /run/009-test-context-reset.sql
```

The script begins a new transaction, applies `SET LOCAL ROLE sinau_rls_test`, and asserts that the prior transaction-local `app.context_token` is absent/empty and that `academic_years` exposes zero rows without a token. It does not need a new token. After the assertions pass, execute `ROLLBACK;` again and then `\\q`.

This proves local GUC reset across a transaction boundary on the same connection. It is a useful connection-reuse check, but it is not a substitute for testing the actual application pooler or worker lifecycle.

## 9. Trusted backend issuer boundary

Before replacing the synthetic fixed-claim signer with an issuer, review [Trusted Backend Context Issuer Design](../../05-security/TRUSTED-CONTEXT-ISSUER-DESIGN.md).

The current database PoC schema has no physical users, authentication sessions, tenant memberships, unit memberships, role assignments, or subscription/entitlement tables. ADR-003 defines those as conceptual entities, but they are not present in 001-schema.sql. Therefore the existing signer cannot validate real identity or membership, and no issuer implementation may infer those records from the synthetic RLS fixtures.

The next executable experiment must create isolated synthetic fixtures (preferably in a dedicated private PoC schema) for global account state, authentication session state, tenant membership, unit membership, and scope lifecycle. It must keep entitlement separate and test it as a distinct feature gate. Fixture writes and test grants must be restricted to an administrator/fixture owner; the request/query role must not be able to create or mutate memberships, sessions, roles, or entitlement state.

Do not use the current sinau_poc owner role as a production issuer role. The production design must use a least-privilege backend/query role, a separately protected signing key, a server-side authenticated principal, and the same transaction connection/XID through context issuance and protected queries. The final authentication framework and application stack have not yet been approved, so the next step is a database-only synthetic membership issuer PoC plus an implementation-neutral backend contract, not production application code.

## 10. Synthetic membership validation PoC

The current PoC does not contain production identity/membership tables. The following scripts add **synthetic-only** fixtures in the private schema `sinau_issuer_poc`:

- `010-context-issuer-fixtures.sql` creates synthetic identities, hashed synthetic authentication sessions, tenant memberships, unit memberships, a private synthetic unit catalog, and separate feature-entitlement fixtures. It creates a NOLOGIN role `sinau_context_issuer_poc`, granted to `sinau_poc` only to simulate role switching in this experiment.
- The SECURITY DEFINER function `sinau_issuer_poc.validate_context_request(session_token, tenant_id, unit_id)` resolves the actor from a hashed active session and validates account, session, tenant membership, unit membership, effective dates, and tenant/unit pairing. It accepts no actor_id argument and returns zero rows for denied requests.
- `has_feature_entitlement(tenant_id, feature_code)` is a separate entitlement check. A valid membership context does not imply that a feature is entitled.
- `011-context-issuer-validation-tests.sql` tests active access, no unit grant, revoked/suspended/expired tenant membership, tenant-only context, disabled identity, revoked/expired session, not-yet-valid membership, expired unit membership, inactive unit, unit/tenant mismatch, separate entitlement behavior, and least-privilege restrictions.

The unit catalog is duplicated only as synthetic fixture metadata in the private PoC schema. The validator deliberately does **not** query `public.education_units` before a signed context is installed because that table is FORCE-RLS protected. This avoids creating a SECURITY DEFINER bypass path around the operational RLS policy.

### Install fixtures

Download both scripts from the same repository branch/commit used for the PoC and stage them under `/run` with owner postgres/mode 0600. Run setup only as PostgreSQL administrator and only against `sinau_design_poc`:

```bash
sudo -u postgres psql -X -v ON_ERROR_STOP=1 -d sinau_design_poc -f 010-context-issuer-fixtures.sql
```

### Run membership validation tests

Open an interactive psql session as administrator:

```bash
sudo -u postgres psql -X -d sinau_design_poc -v ON_ERROR_STOP=1 -P pager=off
```

At the psql prompt, simulate the PoC application login and run the tests:

```sql
SET SESSION AUTHORIZATION sinau_poc;
\\i /run/011-context-issuer-validation-tests.sql
\\q
```

The test file changes to `sinau_context_issuer_poc` to call the narrow validation functions, then changes to `sinau_rls_test` to prove that the query role cannot call the issuer, read membership fixtures or key material, or mutate membership fixtures. Its test transaction ends with ROLLBACK.

### Execution status — verified 2026-11-19

- Script 010 was executed successfully against `sinau_design_poc`. Its initial run exposed a PostgreSQL type-name typo (`pg_catalog.boolean`); the source was corrected to `pg_catalog.bool` in commit `b51f2227187482c623664f14dfd09ad2ac8db042`, then rerun successfully. The metadata report confirmed `sinau_context_owner` ownership, `SECURITY DEFINER`, VOLATILE, PARALLEL UNSAFE, fixed search path, and the expected least-privilege ACLs.
- The corrected script 011 was executed in an interactive psql session as `sinau_poc`. ISS-01 through ISS-14 all passed. Its first run found an issue in the privilege-test code because resolving a private-schema function through `regprocedure` required schema USAGE. The test was corrected in commit `4c6ced509d65a84c345b47eab8bb9e67a5b0c6a4` to inspect catalog OIDs without requiring private-schema USAGE.
- The corrected final privilege test passed: `sinau_rls_test` cannot execute the issuer validator, read the membership fixtures or key store, or mutate membership fixtures. The script ended with `ROLLBACK` and `CONTEXT ISSUER VALIDATION TESTS PASSED — TRANSACTION ROLLED BACK`.
- This verifies only synthetic database membership validation and test-role boundaries. It does not implement or approve a real web authentication integration, application-level role/permission/resource relationship checks, or a signed context issuer.

**Critical limitations:**
- The session strings inside 010/011 are public synthetic fixtures, not real credentials. Do not reuse these strings for any application login or session.
- The validator is a membership-validation gate, not a token signer. It does not authenticate a real browser session, validate role/permission delegation or resource-level relationships, implement tenant/unit lifecycle rules, or sign a database context token.
- The private synthetic unit catalog is not a production source of truth. Real application integration must resolve unit ownership through the approved domain model and the trusted backend transaction flow.
- The role grant from `sinau_poc` to `sinau_context_issuer_poc` is test convenience only. Production runtime roles must be separately provisioned and must not inherit owner/admin privileges.
- This test does not touch or model application database `sinau`, role `sinau_app`, SQLRadius, or MikroTik. Do not treat a passing fixture test as production authentication/authorization approval.


## 11. Same-connection issuer/query role switch and XID continuity

This is the next isolated database experiment derived from [ADR-007](../../09-decisions/ADR-007-TRUSTED-CONTEXT-ISSUER.md). It does not create persistent objects or modify application rows. It checks whether the PoC session can switch from the issuer executor role to the RLS query role and back while retaining one top-level XID and transaction-local state.

Prerequisites: scripts 005 (token verifier/key store), 007 (verified-context accessor), and 010 (synthetic membership validator) have been installed successfully in `sinau_design_poc`.

Stage `012-test-issuer-query-role-switch.sql` under `/run` with owner postgres and mode 0600, then open an interactive psql session:

```bash
sudo -u postgres psql -X -d sinau_design_poc -v ON_ERROR_STOP=1 -P pager=off
```

At the psql prompt:

```sql
SET SESSION AUTHORIZATION sinau_poc;
\\i /run/sinau-poc-012.sql
```

Expected notices:
- Issuer role is active, retains the original XID, has EXECUTE on the narrow validator, and has no direct membership-table SELECT.
- Query role retains the same XID and transaction-local probe, can execute the verified-context accessor, but cannot execute the membership validator or read membership/key tables.
- Switching back to issuer role retains the same top-level XID.
- ROLLBACK restores the original session role and clears the transaction-local probe.

The script ends with ROLLBACK. Exit psql with `\\q` after it reports `ROLE SWITCH / XID CONTINUITY TESTS PASSED — TRANSACTION ROLLED BACK`.

**Execution status — verified 2026-11-19:** Script 012 passed on PostgreSQL 18.7 against `sinau_design_poc`. The output showed issuer → query → issuer role transitions with the same top-level XID (890); issuer/query privileges were constrained as expected; ROLLBACK restored session authorization to `sinau_poc` and cleared the transaction-local probe. Final notice: `ROLE SWITCH / XID CONTINUITY TESTS PASSED — TRANSACTION ROLLED BACK`.

**Limit:** this verifies role changes and transaction-local state on one direct PostgreSQL session. It is not a PgBouncer/Laravel connection-pool test, does not allocate or sign a real context token, and does not approve production role names or privileges. Run only against `sinau_design_poc`.


## 12. Transaction-local context and role cleanup

This experiment checks context and `SET LOCAL ROLE` cleanup across both COMMIT and ROLLBACK on the same PostgreSQL connection. It uses invalid synthetic marker strings only; no valid bearer token, key bytes, or application rows are created or modified.

Prerequisites: scripts 005 (verifier/key store), 007 (verified-context accessor), and 010 (synthetic membership fixtures) are installed in `sinau_design_poc`.

Stage `013-test-context-and-role-cleanup.sql` under `/run` with owner postgres/mode 0600, then open psql as administrator:

```bash
sudo -u postgres psql -X -d sinau_design_poc -v ON_ERROR_STOP=1 -P pager=off
```

At the psql prompt:

```sql
SET SESSION AUTHORIZATION sinau_poc;
\\i /run/sinau-poc-013.sql
```

The assertions cover:
- Invalid marker in a COMMIT transaction produces no verified context and exposes zero academic rows.
- After COMMIT, transaction-local `app.context_token` is empty and `SET LOCAL ROLE` has restored `sinau_poc`.
- Invalid marker in a ROLLBACK transaction produces no verified context and exposes zero academic rows.
- After ROLLBACK, `app.context_token` is empty and the session returns to `sinau_poc`.
- A new transaction on the same connection, without a token, has zero verified context and sees zero academic rows.

The script performs no persistent DDL and no application-row writes. It finishes with ROLLBACK and should report `CONTEXT AND ROLE CLEANUP TESTS PASSED — COMMIT/ROLLBACK COMPLETE`.

**Execution status — verified 2026-11-19:** Script 013 passed on PostgreSQL 18.7 in one interactive session. COMMIT and ROLLBACK both cleared the invalid transaction-local context marker and restored session/current role to `sinau_poc`; a fresh transaction on the same connection had no verified context and saw zero academic rows. Final notice: `CONTEXT AND ROLE CLEANUP TESTS PASSED — COMMIT/ROLLBACK COMPLETE`.

**Limit:** this is a direct PostgreSQL session lifecycle test. It does not verify PgBouncer, Laravel/PDO pooling, persistent connections, asynchronous workers, cancellation, or production token issuance. Run only against `sinau_design_poc`.


## 13. Aborted transaction recovery and same-connection reuse

This experiment injects one controlled SQL error (`division_by_zero`, SQLSTATE `22012`) after a transaction-local invalid context marker is installed and the RLS query role is selected. The error is expected and is detected by psql's `ERROR`/`SQLSTATE` variables. The script then issues ROLLBACK and verifies that the same connection can start a new transaction with no inherited context or role.

Prerequisites: scripts 005 (verifier/key store) and 007 (verified-context accessor) are installed in `sinau_design_poc`.

Stage `014-test-aborted-transaction-recovery.sql` under `/run` with owner postgres/mode 0600, then open psql:

```bash
sudo -u postgres psql -X -d sinau_design_poc -v ON_ERROR_STOP=1 -P pager=off
```

At the psql prompt:

```sql
SET SESSION AUTHORIZATION sinau_poc;
\\i /run/sinau-poc-014.sql
```

Expected behavior:
- Before the injected error, invalid context is rejected and no academic rows are visible.
- The script deliberately emits a PostgreSQL division-by-zero error (SQLSTATE 22012); this is a PASS condition only when psql confirms that exact error.
- It rolls back the aborted transaction, then checks that `app.context_token` is empty and the role is `sinau_poc`.
- It starts another transaction on the same connection under `sinau_rls_test`; the verified-context accessor returns no context and zero academic rows remain visible.
- It finishes with ROLLBACK and restores `sinau_poc`.

Expected final notice: `ABORTED TRANSACTION RECOVERY TESTS PASSED — SAME CONNECTION REUSED`.

**Limit:** this simulates a SQL statement error and manual transaction rollback on a direct psql connection. It is not a Laravel exception-handler, PDO pool, PgBouncer, network disconnect, cancellation, or production connection-pool test. Run only against `sinau_design_poc`.

