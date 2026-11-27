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
3. At the original psql prompt, import the token into `pg_temp.poc_signed_context_input` using `\copy`.
4. Stage `008-test-signed-context-rls.sql` under `/run` and run `\i /run/008-test-signed-context-rls.sql` from that same psql session. Do not run the test file with a new psql process because the XID and temp table are session-bound.
5. Expected assertions: valid token sees only tenant A/unit A1; changing unsigned legacy `app.tenant_id` and `app.unit_id` to tenant B/unit B1 does not change visibility; empty/malformed token sees zero rows; same-scope INSERT succeeds; cross-tenant and cross-unit INSERTs are rejected by RLS `WITH CHECK`.
6. After all assertions pass, execute `ROLLBACK;`, exit psql, and remove both token copies from `/run`. Do not commit test data.

The functional SQL file is assertion-oriented and deliberately does not commit or roll back the outer transaction. If it raises an assertion error, the transaction becomes aborted; run `ROLLBACK;` before retrying with a fresh XID and token. The token is valid for at most 240 seconds; discard it if expired or if the transaction ends.

**Not yet executed:** adding this file to the repository is not evidence that the functional assertions passed. Record actual server output in the project tracker only after the user runs it.

### 8.2 Transaction-local context reset

After the assertions in `008-test-signed-context-rls.sql` pass, do not exit psql yet. First execute `ROLLBACK;` to end the token-bearing transaction. In the same psql connection, keep `SET SESSION AUTHORIZATION sinau_poc` unchanged and run:

```sql
\i /run/009-test-context-reset.sql
```

The script begins a new transaction, applies `SET LOCAL ROLE sinau_rls_test`, and asserts that the prior transaction-local `app.context_token` is absent/empty and that `academic_years` exposes zero rows without a token. It does not need a new token. After the assertions pass, execute `ROLLBACK;` again and then `\q`.

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
\i /run/011-context-issuer-validation-tests.sql
\q
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
\i /run/sinau-poc-012.sql
```

Expected notices:
- Issuer role is active, retains the original XID, has EXECUTE on the narrow validator, and has no direct membership-table SELECT.
- Query role retains the same XID and transaction-local probe, can execute the verified-context accessor, but cannot execute the membership validator or read membership/key tables.
- Switching back to issuer role retains the same top-level XID.
- ROLLBACK restores the original session role and clears the transaction-local probe.

The script ends with ROLLBACK. Exit psql with `\q` after it reports `ROLE SWITCH / XID CONTINUITY TESTS PASSED — TRANSACTION ROLLED BACK`.

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
\i /run/sinau-poc-013.sql
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
\i /run/sinau-poc-014.sql
```

Expected behavior:
- Before the injected error, invalid context is rejected and no academic rows are visible.
- The script deliberately emits a PostgreSQL division-by-zero error (SQLSTATE 22012); this is a PASS condition only when psql confirms that exact error.
- It rolls back the aborted transaction, then checks that `app.context_token` is empty and the role is `sinau_poc`.
- It starts another transaction on the same connection under `sinau_rls_test`; the verified-context accessor returns no context and zero academic rows remain visible.
- It finishes with ROLLBACK and restores `sinau_poc`.

Expected final notice: `ABORTED TRANSACTION RECOVERY TESTS PASSED — SAME CONNECTION REUSED`.

**Execution status — verified 2026-11-19:** Script 014 passed on PostgreSQL 18.7. The deliberate `division by zero` error was observed as SQLSTATE `22012`; ROLLBACK cleared the transaction-local context and restored `sinau_poc`; a fresh transaction on the same connection then remained fail-closed with zero academic rows. Final notice: `ABORTED TRANSACTION RECOVERY TESTS PASSED — SAME CONNECTION REUSED`.

**Limit:** this simulates a SQL statement error and manual transaction rollback on a direct psql connection. It is not a Laravel exception-handler, PDO pool, PgBouncer, network disconnect, cancellation, or production connection-pool test. Run only against `sinau_design_poc`.



## 14. Participant trigger temporary-object shadowing

### Finding — read-only audit, 2026-11-26

The following attached trigger functions had no function-level \`search_path\` and used an unqualified reference to \`student_class_placements\` in both the row type declaration and SELECT:

- \`public.poc_check_assessment_participant()\`, attached to \`public.assessment_participants\`;
- \`public.poc_check_attendance_participant()\`, attached to \`public.attendance_session_participants\`.

A rolled-back test using \`SET LOCAL ROLE sinau_rls_test\` confirmed that an empty temporary table named \`student_class_placements\` shadows the unqualified relation and row type. The temporary schema was \`pg_temp_1\`. Runtime and query roles cannot create triggers on the participant tables, but both have TEMP privilege in the PoC.

The read-only constraint audit returned 40 validated rows. Composite foreign keys preserve tenant/unit/placement/enrollment links. The class-group equality and date-within-placement-period checks remain in the trigger functions.

### Apply the isolated PoC patch

The patch script verifies the database name, administrator role, existing function owners/bodies, trigger attachments, and query-role SELECT privilege before changing anything. It schema-qualifies the placement row type/relation and pins the two SECURITY INVOKER functions to \`search_path = pg_catalog, pg_temp\`. The transaction commits only those two function definitions and preserves their owners and existing ACLs.

Download the two scripts from this branch to a temporary directory:

\`\`\`bash
mkdir -p /tmp/sinau-trigger-hardening
cd /tmp/sinau-trigger-hardening

BASE='https://raw.githubusercontent.com/sulhanqidri/SINAU/feature/phase-0-requirements-blueprint/docs/03-database/poc'

curl -fL "$BASE/015-harden-participant-trigger-search-path.sql" \
  -o 015-harden-participant-trigger-search-path.sql

curl -fL "$BASE/016-test-participant-trigger-temp-shadowing.sql" \
  -o 016-test-participant-trigger-temp-shadowing.sql

sudo install -o postgres -g postgres -m 600 \
  015-harden-participant-trigger-search-path.sql \
  /run/015-harden-participant-trigger-search-path.sql

sudo install -o postgres -g postgres -m 600 \
  016-test-participant-trigger-temp-shadowing.sql \
  /run/016-test-participant-trigger-temp-shadowing.sql
\`\`\`

Apply the function-only patch, **only** to \`sinau_design_poc\`:

\`\`\`bash
sudo -u postgres psql -X -v ON_ERROR_STOP=1 \
  -d sinau_design_poc \
  -f /run/015-harden-participant-trigger-search-path.sql
\`\`\`

Then run the trigger regression test in a separate fresh PostgreSQL session:

\`\`\`bash
sudo -u postgres psql -X -v ON_ERROR_STOP=1 \
  -d sinau_design_poc \
  -f /run/016-test-participant-trigger-temp-shadowing.sql
\`\`\`

### Expected interpretation

- The test intentionally creates an empty temporary table with the same name as the permanent placement table.
- It first confirms that the caller's unqualified name resolves to the temporary table. The trigger functions must nevertheless read the schema-qualified permanent table under their pinned function search path.
- For each participant table containing at least one row, the script performs a no-op UPDATE so its existing BEFORE trigger runs, then rolls the update back.
- A PASS notice means that trigger completed with the empty temporary shadow present. A SKIP notice means that table has no fixture row and the corresponding trigger has not yet been exercised. Do not record a full pass if either trigger is skipped.
- The script ends with ROLLBACK; it does not retain the no-op updates or temporary table.

Both scripts abort unless the current database is exactly \`sinau_design_poc\` and \`current_user\` is \`postgres\`. They are not migrations and must not be run against \`sinau\`, role \`sinau_app\`, SQLRadius, or any production service.

**Execution status — 2026-11-26:**
- Script 015 was executed successfully against `sinau_design_poc`: preflight passed, both function replacements succeeded, postflight passed, and COMMIT completed. The two functions now have `search_path=pg_catalog, pg_temp` and schema-qualified placement relation/row type references.
- Script 016 confirmed the temporary shadow relation resolves as `pg_temp_9`, while `public.student_class_placements` remains addressable.
- Both actual trigger invocations were SKIPPED because the two participant tables contained no rows. The test ended with ROLLBACK.
- The remediation is applied, but the regression gate is **not yet passed**. Create valid synthetic PoC fixtures within a rollback-only test and obtain PASS for each trigger before closing the finding.
- No production database or services were changed. ADR-007 remains Proposed.


### Patch-script correction — PostgreSQL deparser case normalization

The first server-side attempt reached both `CREATE OR REPLACE FUNCTION` statements, then failed in the script's postflight text inspection. PostgreSQL's `pg_get_functiondef()` normalizes the declaration text to lowercase in this output; the postflight compared that lowercase result to an uppercase literal `%ROWTYPE`. Because the script runs inside one transaction, exiting after the `ON_ERROR_STOP` error rolled the function replacements back. The subsequent regression preflight correctly found zero hardened functions.

The patch script is corrected to compare the row-type expression case-insensitively:
`position(lower('public.student_class_placements%ROWTYPE') IN lower(v_def))`.

Re-download the corrected 015 script from the branch before retrying. No database changes were retained by the failed attempt. The 016 regression script did not make any changes because its preflight stopped before creating the test temporary table.



## 15. Full participant-trigger regression with synthetic fixtures

Script \`017-test-hardened-participant-triggers.sql\` exercises both hardened participant triggers with an empty temporary \`student_class_placements\` shadow table. It is one rollback-only transaction and refuses to run unless the database is \`sinau_design_poc\`, the current role is \`postgres\`, both trigger functions have the expected hardened invoker configuration, and both expected triggers are enabled.

The PoC already contains two tenants, three education units, and three academic years. The latest read-only inventory identified a valid parent chain:
- tenant \`tenant-a\`: \`00000000-0000-0000-0000-000000000001\`
- unit \`unit-a1\`: \`10000000-0000-0000-0000-000000000001\`
- academic year 2026–2027: \`30000000-0000-0000-0000-000000000001\`

The revised script reuses those exact parent rows. It does **not** insert, update, or delete tenants, education units, or academic years. It locks the seven target academic tables for the duration of the test transaction, uses a dedicated UUID namespace and student code, and stops only if those exact fixture keys already exist. Unrelated rows in the target tables do not cause a blanket empty-table failure.

Within the transaction, the script creates two synthetic class groups, one enrollment, one time-bounded placement, three assessment definitions, and three attendance sessions. It then exercises:
- valid INSERT and no-op UPDATE paths for both participant triggers;
- wrong-class rejection for assessment and attendance;
- out-of-placement-period rejection for assessment and attendance;
- final assertions that the two valid participant IDs exist and all four invalid participant IDs are absent.

Each negative case must raise the exact expected trigger message. A foreign-key error, another exception, or an unexpected successful insert aborts the script. The script ends with \`ROLLBACK\`; no fixture rows, locks, or temporary objects are retained.

Download the SQL file from the exact commit SHA reported with this update (avoid a potentially stale cached branch URL), then run it only against the dedicated PoC database:

\`\`\`bash
# Replace 50b8e6555b5e3c5074c016d796cf4f9176e21da6 with the commit SHA accompanying this script update.
curl -fL 'https://raw.githubusercontent.com/sulhanqidri/SINAU/50b8e6555b5e3c5074c016d796cf4f9176e21da6/docs/03-database/poc/017-test-hardened-participant-triggers.sql' \
  -o /run/017-test-hardened-participant-triggers.sql

sudo chown postgres:postgres /run/017-test-hardened-participant-triggers.sql
sudo chmod 600 /run/017-test-hardened-participant-triggers.sql

sudo -u postgres psql -X -v ON_ERROR_STOP=1 \
  -d sinau_design_poc \
  -f /run/017-test-hardened-participant-triggers.sql
\`\`\`

Expected result: PASS for existing parent fixture validation, collision checks, function/trigger preconditions, temporary shadow setup, valid INSERT/UPDATE paths, all four invalid cases, final row assertions, and the final \`ALL PARTICIPANT TRIGGER REGRESSION TESTS PASSED — TRANSACTION ROLLED BACK\` marker. The script does not perform COMMIT.

**Execution result — PASS, 2026-11-26:**
- User downloaded the pinned revision from commit \`66c6770f278d97fa5e5b02cb4e45e094d8463183\`, validated the revised fixture markers, installed it as \`postgres:postgres\` mode 0600, and executed it against \`sinau_design_poc\` with \`ON_ERROR_STOP=1\`.
- Preflight passed for the existing \`tenant-a / unit-a1 / academic_year 2026–2027\` parent chain, exact fixture-key collision checks, both hardened SECURITY INVOKER functions, and both enabled participant triggers.
- The temporary shadow resolved to \`pg_temp_14\`; the permanent \`public.student_class_placements\` relation remained distinct.
- Both valid participant INSERTs and both no-op UPDATE trigger paths passed.
- All four negative cases passed: assessment wrong-class, assessment out-of-period, attendance wrong-class, and attendance out-of-period.
- Final assertions passed: exactly one valid synthetic row in each participant table and no invalid fixture IDs remained.
- The script completed \`ROLLBACK\` and printed \`ALL PARTICIPANT TRIGGER REGRESSION TESTS PASSED — TRANSACTION ROLLED BACK\`. No synthetic academic rows, locks, or temporary objects were retained.
- This closes the PoC regression gate for the temporary-table shadowing issue. It does not constitute production security acceptance or approval of production migrations. No production database, role, service, SQLRadius, or MikroTik changes were made. ADR-007 remains Proposed.


## 16. Read-only audit — account/session/membership authorization freshness

The next open ADR-007 security gate is whether a signed context is rechecked against authoritative account, authentication-session, tenant-membership, and unit-membership state for **each protected SQL statement**.

The current source-level contract distinguishes two operations:
- \`sinau_issuer_poc.validate_context_request(...)\` validates identity, session, and membership when a context is requested.
- \`sinau_private.verify_context_token(...)\`, called by \`sinau_private.current_verified_context()\` and the public RLS policies, verifies the signed token, audience, time window, transaction XID, and signing-key state.

The existing issuer test ISS-01—ISS-14 proves that invalid account/session/membership state is rejected when requesting a new context. It does not prove that a token already issued is rejected by a **later protected statement** after those source records are revoked.

Script \`018-audit-authorization-freshness.sql\` is the next read-only inspection. It checks the installed PostgreSQL function definitions and metadata, verifies the RLS accessor calls the verifier, compares the verifier's references with the four synthetic authorization-state tables, confirms the issuer validator references those source tables, and lists public RLS policies that use the verified-context accessor. It performs no DML or DDL and ends with ROLLBACK.

Run only against \`sinau_design_poc\` as PostgreSQL administrator:

\`\`\`bash
# Replace 50b8e6555b5e3c5074c016d796cf4f9176e21da6 with the commit SHA containing script 018.
curl -fL 'https://raw.githubusercontent.com/sulhanqidri/SINAU/50b8e6555b5e3c5074c016d796cf4f9176e21da6/docs/03-database/poc/018-audit-authorization-freshness.sql' \
  -o /run/018-audit-authorization-freshness.sql

sudo chown postgres:postgres /run/018-audit-authorization-freshness.sql
sudo chmod 600 /run/018-audit-authorization-freshness.sql

sudo -u postgres psql -X -v ON_ERROR_STOP=1 \
  -d sinau_design_poc \
  -f /run/018-audit-authorization-freshness.sql
\`\`\`

Expected diagnostic: the verifier function's installed body does not reference one or more live authorization-state tables, while the issuer validator does. This is reported as a **confirmed gap**, not as a passing authorization-revocation test. The follow-up is a separate rollback-only, two-connection test of account disable, session revoke, tenant-membership revoke, and unit-membership revoke under the approved \`READ COMMITTED\` semantics. No verifier implementation change is included in this audit script. ADR-007 remains Proposed.


## 17. Two-connection authorization-revocation behavior test

Script `020-test-live-authorization-revocation.sql` is the Session A controller for the next PoC gate. It opens one explicit `READ COMMITTED` transaction, allocates an XID, installs a short-lived signed token for the existing synthetic actor `91000000-0000-0000-0000-000000000001`, and confirms one `academic_years` row is visible for tenant A/unit A1. It then waits while Session B revokes one source authorization record and commits. Session A runs another protected SELECT using the **same XID and token**, reports whether the row remains visible, and rolls back.

The matching Session B statements and restoration blocks are documented below. They change one synthetic PoC fixture row at a time and commit the temporary revoke so that Session A can observe a new READ COMMITTED statement snapshot. After Session A rolls back, the exact fixture row must be restored and committed before another scenario. This is not a single rollback-only test: the revocation needs a commit to become visible across connections. Only the known synthetic fixture records are changed, and every mutation has a checked one-row restoration step. Do not interrupt between revoke and restore.

Download and install the two test files from the pinned commit:

```bash
COMMIT='a9cdf96c693846ac874df3d6336d82f58f17631e'

curl -fL "https://raw.githubusercontent.com/sulhanqidri/SINAU/$COMMIT/docs/03-database/poc/019-sign-authorization-freshness-token.py" \
  -o "$HOME/019-sign-authorization-freshness-token.py"
chmod 700 "$HOME/019-sign-authorization-freshness-token.py"

curl -fL "https://raw.githubusercontent.com/sulhanqidri/SINAU/$COMMIT/docs/03-database/poc/020-test-live-authorization-revocation.sql" \
  -o "$HOME/020-test-live-authorization-revocation.sql"
sudo install -o postgres -g postgres -m 600 \
  "$HOME/020-test-live-authorization-revocation.sql" \
  /run/020-test-live-authorization-revocation.sql
```

### Prepare the synthetic token signer

`019-sign-authorization-freshness-token.py` signs the same PoC token contract as script 006, but uses the known active issuer fixture actor `910...001`. It does not invoke the issuer validator and is not an application issuer. This is intentional: the experiment isolates what the database verifier does with an already-issued actor/tenant/unit token after source authorization state changes. The token format contains no session identifier; therefore the session case can only test the actor's single active synthetic session and also exposes the need for an explicit session identifier or epoch if per-session revocation is required.

Download and install the two test files from the pinned commit containing them. Install the signer as a user-owned executable under `$HOME`; it reads the existing PoC key from the current user's 0600 secret file. The SQL script is installed for PostgreSQL administrator execution.

### Run one revocation scenario at a time

1. Open terminal A and start Session A:

```bash
sudo -u postgres psql -X -v ON_ERROR_STOP=1 \
  -d sinau_design_poc \
  -f /run/020-test-live-authorization-revocation.sql
```

2. Session A prints its XID and waits. In terminal B, run the signer using that XID, then install the short-lived token where the PostgreSQL OS account can read it:

```bash
python3 "$HOME/019-sign-authorization-freshness-token.py" XID_FROM_SESSION_A

sudo install -o postgres -g postgres -m 600 \
  /run/sinau-poc-token-signer/authfreshness-context.token \
  /run/authfreshness-context.token
```

3. Press Enter in terminal A. It imports the token without printing it, sets transaction-local context, and checks the baseline row count. When it waits for the revoke, run the matching Session B block from the fixture-revoke section, replacing nothing; the statements are fixed to actor `910...001`, tenant A, and unit A1.

4. After Session B reports COMMIT, press Enter in terminal A. Record the `FINDING REPRODUCED` or `PASS` notice. Session A always ends with ROLLBACK.

5. After Session A reports ROLLBACK, run the matching restoration block in terminal B and COMMIT it. Remove the two tmpfs token files:

```bash
sudo rm -f -- /run/authfreshness-context.token \
  /run/sinau-poc-token-signer/authfreshness-context.token
```

Repeat the complete sequence independently for account, session, tenant membership, and unit membership. Never continue to the next case unless the restore block reports exactly one row updated. A baseline failure or unexpected row count means stop; do not improvise another update.

### Connection B — revoke and restore one synthetic fixture row

Run each mutation **only after Session A has printed its XID and is waiting for the revoke**. Run the matching restore block only after Session A has printed its ROLLBACK. Every block checks that exactly one expected synthetic row was changed.

**A. Disable the synthetic global identity**

Revoke:
```sql
BEGIN;
DO $revoke$
DECLARE n integer;
BEGIN
  UPDATE sinau_issuer_poc.poc_identities
     SET account_status = 'disabled'
   WHERE actor_id = '91000000-0000-0000-0000-000000000001'
     AND account_status = 'active';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 1 THEN RAISE EXCEPTION 'Expected one active synthetic identity, updated %', n; END IF;
END
$revoke$;
COMMIT;
```

Restore:
```sql
BEGIN;
DO $restore$
DECLARE n integer;
BEGIN
  UPDATE sinau_issuer_poc.poc_identities
     SET account_status = 'active'
   WHERE actor_id = '91000000-0000-0000-0000-000000000001'
     AND account_status = 'disabled';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 1 THEN RAISE EXCEPTION 'Expected one disabled synthetic identity, updated %', n; END IF;
END
$restore$;
COMMIT;
```

**B. Revoke the single active synthetic authentication session**

Revoke:
```sql
BEGIN;
DO $revoke$
DECLARE n integer;
BEGIN
  UPDATE sinau_issuer_poc.poc_auth_sessions
     SET session_status = 'revoked',
         revoked_at = pg_catalog.clock_timestamp()
   WHERE session_hash = sinau_crypto.digest(
           pg_catalog.convert_to('SINAU-POC-ACTIVE-SESSION-A-NOT-A-REAL-CREDENTIAL', 'UTF8'),
           'sha256'
         )
     AND actor_id = '91000000-0000-0000-0000-000000000001'
     AND session_status = 'active'
     AND revoked_at IS NULL;
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 1 THEN RAISE EXCEPTION 'Expected one active synthetic session, updated %', n; END IF;
END
$revoke$;
COMMIT;
```

Restore:
```sql
BEGIN;
DO $restore$
DECLARE n integer;
BEGIN
  UPDATE sinau_issuer_poc.poc_auth_sessions
     SET session_status = 'active',
         revoked_at = NULL
   WHERE session_hash = sinau_crypto.digest(
           pg_catalog.convert_to('SINAU-POC-ACTIVE-SESSION-A-NOT-A-REAL-CREDENTIAL', 'UTF8'),
           'sha256'
         )
     AND actor_id = '91000000-0000-0000-0000-000000000001'
     AND session_status = 'revoked'
     AND revoked_at IS NOT NULL;
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 1 THEN RAISE EXCEPTION 'Expected one revoked synthetic session, updated %', n; END IF;
END
$restore$;
COMMIT;
```

**C. Revoke the synthetic tenant membership**

Revoke:
```sql
BEGIN;
DO $revoke$
DECLARE n integer;
BEGIN
  UPDATE sinau_issuer_poc.poc_tenant_memberships
     SET membership_status = 'revoked',
         revoked_at = pg_catalog.clock_timestamp()
   WHERE actor_id = '91000000-0000-0000-0000-000000000001'
     AND tenant_id = '00000000-0000-0000-0000-000000000001'
     AND membership_status = 'active'
     AND revoked_at IS NULL;
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 1 THEN RAISE EXCEPTION 'Expected one active synthetic tenant membership, updated %', n; END IF;
END
$revoke$;
COMMIT;
```

Restore:
```sql
BEGIN;
DO $restore$
DECLARE n integer;
BEGIN
  UPDATE sinau_issuer_poc.poc_tenant_memberships
     SET membership_status = 'active',
         revoked_at = NULL
   WHERE actor_id = '91000000-0000-0000-0000-000000000001'
     AND tenant_id = '00000000-0000-0000-0000-000000000001'
     AND membership_status = 'revoked'
     AND revoked_at IS NOT NULL;
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 1 THEN RAISE EXCEPTION 'Expected one revoked synthetic tenant membership, updated %', n; END IF;
END
$restore$;
COMMIT;
```

**D. Revoke the synthetic unit membership**

Revoke:
```sql
BEGIN;
DO $revoke$
DECLARE n integer;
BEGIN
  UPDATE sinau_issuer_poc.poc_unit_memberships
     SET membership_status = 'revoked',
         revoked_at = pg_catalog.clock_timestamp()
   WHERE actor_id = '91000000-0000-0000-0000-000000000001'
     AND tenant_id = '00000000-0000-0000-0000-000000000001'
     AND unit_id = '10000000-0000-0000-0000-000000000001'
     AND membership_status = 'active'
     AND revoked_at IS NULL;
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 1 THEN RAISE EXCEPTION 'Expected one active synthetic unit membership, updated %', n; END IF;
END
$revoke$;
COMMIT;
```

Restore:
```sql
BEGIN;
DO $restore$
DECLARE n integer;
BEGIN
  UPDATE sinau_issuer_poc.poc_unit_memberships
     SET membership_status = 'active',
         revoked_at = NULL
   WHERE actor_id = '91000000-0000-0000-0000-000000000001'
     AND tenant_id = '00000000-0000-0000-0000-000000000001'
     AND unit_id = '10000000-0000-0000-0000-000000000001'
     AND membership_status = 'revoked'
     AND revoked_at IS NOT NULL;
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 1 THEN RAISE EXCEPTION 'Expected one revoked synthetic unit membership, updated %', n; END IF;
END
$restore$;
COMMIT;
```

For every scenario, the order is: start Session A; copy its XID; create token; let A pass baseline and wait; run the matching revoke block in B and COMMIT; press Enter in A and record its post-revocation notice; wait for A ROLLBACK; run the matching restore block in B and COMMIT; verify the fixture is active before the next scenario. Never run two revoke scenarios at the same time.


### Interpretation and limits

- `FINDING REPRODUCED` with one visible row means a protected statement begun after the revoke commit still accepted the token. That confirms the missing per-statement state check for that authorization source.
- `PASS` with zero rows means that scenario was denied after revoke. It does not by itself prove all other revocation cases.
- The token is bound to one XID and is re-used only inside Session A. Do not move it to another transaction or connection.
- The session token does not carry a session ID. The current test fixture has one active session for actor 910...001; exact per-session revocation semantics require a session identifier or an authorization epoch in the eventual token contract.
- This test is deliberately a PoC behavior experiment. It does not modify the verifier or RLS policies. It must only run against `sinau_design_poc`, never `sinau`, `sinau_app`, SQLRadius, or production services.
- A `FINDING REPRODUCED` result is not an application exploit test. It is evidence that the current verifier does not enforce the chosen revocation semantics on a subsequent protected statement.


## 18. Execution result — two-connection authorization-revocation test (2026-11-27)

The four scenarios in section 17 were executed against `sinau_design_poc` under `READ COMMITTED`, using the same transaction XID for Session A and its signed PoC token. Each valid run passed the baseline assertion (exactly one tenant-A/unit-A1 academic-year row), then Session B committed one synthetic authorization-state revocation before Session A's next protected SELECT.

**Observed result: all four scenarios reported `FINDING REPRODUCED`** — the next protected statement still saw one row after the corresponding revocation commit.

| Authorization source | Session B mutation | Session A result | Fixture restoration |
|---|---|---|---|
| Global account identity | `account_status: active → disabled` | `FINDING REPRODUCED` | Restored to `active` |
| Authentication session | `session_status: active → revoked` | `FINDING REPRODUCED` | Verified `active`, `revoked_at IS NULL` |
| Tenant membership | `membership_status: active → revoked` | `FINDING REPRODUCED` | Restored to `active` |
| Unit membership | `membership_status: active → revoked` | `FINDING REPRODUCED` | Restored to `active` |

Each revoke/restore block asserted exactly one affected synthetic row. The final read-only audit returned `matching_rows = 1`, `active_rows = 1`, and `PASS` for all four fixtures. That audit ran under `BEGIN READ ONLY` and ended with `ROLLBACK`. Temporary token files were removed from `/run`.

An earlier preliminary attempt with mismatched XIDs (Session A XID 934 vs signer XID 935) failed its baseline and is excluded from the four valid results. The successful runs used matching XIDs and passed baseline before each revocation.

**Finding:** the installed PoC verifier does not enforce account, authentication-session, tenant-membership, or unit-membership revocation on the next protected statement in the tested READ COMMITTED flow. This is a PoC authorization-freshness finding, not a production exploit demonstration or production-security acceptance.

**Limitations:** the PoC token has no session identifier. The session scenario tests only the single active synthetic session for actor `910...001`; it does not establish per-session revocation semantics for actors with multiple sessions. The experiment requires Session B's revocation commit to become visible, followed by a separately committed fixture restoration; it is not an all-rollback test.

**Next gate:** design the token/session binding and live authorization freshness contract, then implement and retest only within `sinau_design_poc`. Compare per-statement authoritative-state checks with a carefully versioned authorization-epoch approach, including race/snapshot semantics and query cost. Do not modify production schemas, roles, RLS, or Laravel integration until the design and tests are reviewed. ADR-007 remains Proposed.


## 19. Authorization freshness and session-bound token design — proposal (2026-11-27)

The two-connection test in section 18 reproduced the same authorization-freshness gap for all four synthetic sources: account, authentication session, tenant membership, and unit membership. The final read-only audit confirmed that all four fixtures were restored and active. This is a `sinau_design_poc` finding only.

The proposed next design is documented in [021-authorization-freshness-design.md](021-authorization-freshness-design.md). Its recommended direction is a hybrid:

- Perform live, authoritative account/session/membership checks for every protected SQL statement. Do not cache authorization state across statements.
- Bind the signed context to one immutable, server-side session reference. Revoking one session must not revoke another session belonging to the same actor.
- Include monotonic account, tenant-membership, and unit-membership generations so that an old token cannot become valid again after a disable/revoke followed by reactivation/regrant. Generations supplement live checks; they do not replace them.
- Preserve the approved `READ COMMITTED` statement-boundary policy. The exact interaction between the current `VOLATILE` verifier's internal SQL reads and statement snapshots still requires a controlled in-flight concurrency test.

The existing primary keys are the starting point for point lookups: actor, session hash, actor/tenant membership, actor/tenant/unit membership, unit ownership, and key ID. Do not add status or epoch indexes speculatively; measure query plans and representative cardinalities first. A session `actor_id` index is only a candidate for bulk logout if the revoke-all query plan justifies it.

**No implementation is included:** no SQL migration or verifier patch has been prepared or executed; no database, role, RLS policy, Laravel integration, production service, SQLRadius, or MikroTik has been changed. The v2 token format and generation columns remain proposals pending review. ADR-007 remains Proposed, and PR #1 must remain Open/Draft/unmerged.


## 20. Read-only installed context-state inventory

Script `022-audit-context-state-inventory.sql` inventories the installed authorization-source tables, columns, constraints, primary/unique/foreign-key indexes, function definitions and metadata, effective table/function privileges, role attributes/memberships, and RLS policies.

**Safety properties:**
- Hard-stops unless connected to `sinau_design_poc` as PostgreSQL superuser `postgres`.
- Starts `BEGIN READ ONLY` and ends with `ROLLBACK`.
- Reads PostgreSQL catalogs only; it does not read fixture rows, token values, session hashes, key bytes, credentials, or application records.
- Does not create temporary objects or modify schema, data, roles, grants, policies, or functions.
- Function source is included for review, but no secret/key contents are selected.

Run on the SINAU PoC host:

```bash
curl -fL 'https://raw.githubusercontent.com/sulhanqidri/SINAU/702a7340ac8e0556871b92aa065922b6612c81c8/docs/03-database/poc/022-audit-context-state-inventory.sql' \
  -o /run/022-audit-context-state-inventory.sql

sudo chown postgres:postgres /run/022-audit-context-state-inventory.sql
sudo chmod 600 /run/022-audit-context-state-inventory.sql

sudo -u postgres psql -X -v ON_ERROR_STOP=1 \
  -d sinau_design_poc \
  -f /run/022-audit-context-state-inventory.sql
```

The download URL is pinned to the commit containing this script; run the command as shown. Preserve the output for review, but redact hostnames or other environment details if sharing publicly. The output is an inventory, not a pass/fail approval. In particular, catalog-recorded `pg_depend` entries may omit table references inside PL/pgSQL function bodies; review the displayed function definitions as well.

The inventory must be checked against the live PoC host before proposing any DDL. Do not assume the repository's original fixture DDL exactly matches the installed database. PR #1 remains Open/Draft/unmerged; no verifier implementation is authorized by this audit.


## 21. Runtime authorization-state inventory — 2026-11-27

The user executed script 022 on the SINAU host. The output confirms PostgreSQL 18.7, database `sinau_design_poc`, role `postgres`, and `transaction_read_only = on`; the script reached its final ROLLBACK marker. This is a catalog inventory, not a verifier acceptance test.

**Confirmed runtime structure:**
- All eight expected relations were present: the six issuer fixture tables, `sinau_private.context_keys`, and `public.tenants`.
- The four authorization source tables have no generation/epoch columns: `poc_identities`, `poc_auth_sessions`, `poc_tenant_memberships`, and `poc_unit_memberships`.
- `poc_auth_sessions.session_hash` is `bytea NOT NULL`, constrained to 32 bytes and is the primary key. Its row also stores `actor_id`, session status, authenticated/expiry/revocation timestamps, and assurance level.
- Primary-key indexes on the six issuer fixture tables and `context_keys` were all valid, ready, and live. No secondary indexes were reported for those tables.
- The issuer fixture relations and `context_keys` are owned by `sinau_context_owner`; `public.tenants` is owned by `sinau_poc`.
- All 14 listed public RLS policies use `sinau_private.current_verified_context()`. `education_units` is tenant-scoped; `audit_events` retains the special tenant-level NULL-unit rule.
- Effective privilege output showed `sinau_rls_test` cannot directly SELECT the issuer membership/session tables or key store and cannot execute the issuer validator. It can execute the verifier and accessor required by the current invoker accessor chain.
- The role membership catalog showed `sinau_app_runtime_poc` can SET ROLE to both `sinau_context_issuer_poc` and `sinau_rls_test` (`set_option = true`, `inherit_option = false`). The corrected script now inventories this runtime role's attributes and effective privileges explicitly; inspect that output before accepting the role boundary.
- The `pg_depend` query returned no rows for these PL/pgSQL/SQL function dependencies. This is not proof of no dependencies: review the function source, as the script warns.

**Audit script defect discovered and corrected:**
- The first run's function metadata lookup used `pg_get_function_identity_arguments()` with an assumed type-only string. That predicate did not match the installed verifier/issuer functions, even though section 7 displayed their definitions. The first output's blank metadata rows for those functions are therefore an audit-query defect, not evidence that those functions were absent.
- Script 022 now matches function overloads using `pronargs` and `proargtypes`, and includes `sinau_app_runtime_poc` in privilege/role inventories. Re-run the corrected, pinned script before relying on the function metadata and runtime-role sections.
- No database/schema/role/privilege/RLS change was made by either audit run. The first run ended with ROLLBACK. Do not proceed to DDL until the corrected audit is reviewed.

The raw first-run output is not treated as a full audit pass because the function metadata section was incomplete. The corrected run is still required.


### Follow-up audit correction — runtime role attributes

The second 022 run successfully populated all four function metadata rows and included `sinau_app_runtime_poc` in table/function effective-privilege output and role-membership output. It still omitted that role from section 10's role-attribute SELECT because that one filter list had not been updated. The script is corrected again to include `sinau_app_runtime_poc` in the role-attribute result. Re-run this final pinned revision before concluding whether the runtime role is login-capable or has additional role attributes. The existing membership output proves `SET ROLE` membership to issuer and query roles; it does not prove whether the role is a login itself.


## 22. Corrected runtime audit results — function metadata and role grants

The corrected execution of script 022 successfully returned all four function metadata rows. All four functions are `VOLATILE` with `search_path=pg_catalog, pg_temp`:

| Function | Owner | Security mode | Effective EXECUTE grant |
|---|---|---|---|
| `sinau_issuer_poc.validate_context_request(text,uuid,uuid)` | `sinau_context_owner` | SECURITY DEFINER | owner, issuer role |
| `sinau_issuer_poc.has_feature_entitlement(uuid,text)` | `sinau_context_owner` | SECURITY DEFINER | owner, issuer role |
| `sinau_private.verify_context_token(text)` | `sinau_context_owner` | SECURITY DEFINER | owner, query role |
| `sinau_private.current_verified_context()` | `sinau_context_owner` | SECURITY INVOKER | owner, query role |

The function definitions in section 7 match those names/signatures. This corrects the metadata lookup gap from the first run.

The direct effective privilege checks showed:
- `sinau_app_runtime_poc`, `sinau_context_issuer_poc`, `sinau_poc`, and `sinau_rls_test` have no direct SELECT/INSERT/UPDATE/DELETE/TRUNCATE privileges on the authorization source tables or `context_keys`.
- `sinau_app_runtime_poc` has no direct EXECUTE on the listed context functions.
- `sinau_context_issuer_poc` can execute the two issuer functions, but has no direct SELECT on their source tables.
- `sinau_rls_test` can execute the verifier and accessor, but cannot execute issuer functions or read source/key tables directly.
- `sinau_context_owner` owns the protected fixture/key tables and has full table privileges.

The role-membership output confirms `sinau_app_runtime_poc` has `SET` membership (not inherited membership) in both `sinau_context_issuer_poc` and `sinau_rls_test`. This means the runtime role can deliberately switch into each capability role. This is a trust boundary, not evidence of a direct table grant. The application design must constrain when/how it issues SET ROLE; the model does not protect against arbitrary SQL execution by a compromised runtime connection. Do not remove or change these memberships as part of this audit.

**Role-attribute follow-up — completed by focused read-only query**

The one-row query returned:

| Attribute | Result |
|---|---:|
| `rolsuper` | false |
| `rolcanlogin` | true |
| `rolinherit` | false |
| `rolcreaterole` | false |
| `rolcreatedb` | false |
| `rolreplication` | false |
| `rolbypassrls` | false |

This closes the role-attribute question for `sinau_app_runtime_poc` without rerunning the full script 022. The query was wrapped in `BEGIN READ ONLY` / `ROLLBACK`; it did not change any catalog object.

### Security interpretation and remaining gate

The runtime role is a login-capable, non-superuser principal with no direct elevated role attributes in the listed categories. However, the membership inventory shows `SET` (but not `INHERIT`) membership in both `sinau_context_issuer_poc` and `sinau_rls_test`. Consequently, the runtime can explicitly switch to those roles. `rolinherit=false` is not a barrier to `SET ROLE`, and the absence of direct grants on the unswitched runtime role does not mean that those capabilities are unreachable from its login.

This is a role-capability boundary that must be decided in the threat model. If the runtime credential is intended to be unable to exercise issuer/query capabilities under arbitrary SQL execution, the relevant `SET` memberships need a separately reviewed reduction and the application must use another controlled capability path. If those memberships are intentional, document that the runtime is trusted with the capabilities, and audit privileges/default privileges after each role switch. **Do not change memberships as part of this read-only audit.**

The final corrected script 022 remains pinned to commit `702a7340ac8e0556871b92aa065922b6612c81c8`; this focused query did not rerun the full script. All checks described here were read-only. No data, schema, role, membership, privilege, policy, or function was modified. Keep verifier DDL on hold until the role-capability decision and snapshot/concurrency design are reviewed.


## 23. Runtime SET ROLE capability test — 2026-11-27

A focused test simulated the runtime session identity from a `postgres` connection in two separate read-only transactions. The SQL used `SET LOCAL SESSION AUTHORIZATION sinau_app_runtime_poc`, followed by one of these commands:

- `SET LOCAL ROLE sinau_context_issuer_poc`
- `SET LOCAL ROLE sinau_rls_test`

**Both role switches succeeded.** The observed identities were:

| Test | `session_user` | `current_user` | Result |
|---|---|---|---|
| Runtime baseline | `sinau_app_runtime_poc` | `sinau_app_runtime_poc` | PASS |
| Switch to issuer | `sinau_app_runtime_poc` | `sinau_context_issuer_poc` | PASS |
| Switch to query | `sinau_app_runtime_poc` | `sinau_rls_test` | PASS |

Each test transaction ended with `ROLLBACK`. No role, membership, grant, schema, function, policy, or table data was modified.

### Interpretation

This confirms that the recorded SET memberships are usable: a session with runtime identity can assume either capability role. The session identity remains the runtime role while `current_user` changes to the capability role. Consequently, the runtime connection can exercise privileges granted to issuer/query roles after an explicit `SET ROLE`, despite having `rolinherit=false` and no corresponding direct grants while unswitched.

### Limitation

The test connection itself was authenticated as `postgres`; the command `SET LOCAL SESSION AUTHORIZATION` simulated the runtime identity. Therefore, it proves the permission to execute `SET ROLE` once operating with that identity, but does not test an actual network login using the runtime credential, password/SCRAM, `pg_hba.conf`, or application connection configuration.

### Decision gate

Do not change memberships or start verifier DDL based on this test alone. The threat model must choose whether the runtime credential is trusted with both capabilities. If not, propose a separately reviewed PoC role-model change and a controlled alternative path for the issuer and query functions. If yes, record the trust assumption and audit the effective privileges after each role switch. ADR-007 remains Proposed and PR #1 remains Open, Draft, and unmerged.


## 24. Issuer capability effective-privilege audit — 2026-11-27

The read-only audit ran after setting the session identity to `sinau_app_runtime_poc` and switching to `sinau_context_issuer_poc`. It reported:

- `session_user = sinau_app_runtime_poc`
- `current_user = sinau_context_issuer_poc`
- schema `sinau_issuer_poc` USAGE: true
- schema `sinau_private` USAGE: false

The OID-based checks avoided resolving schema-qualified relation names as the issuer role and completed for all five relations:

| Relation | SELECT | INSERT | UPDATE | DELETE | TRUNCATE |
|---|---:|---:|---:|---:|---:|
| `sinau_issuer_poc.poc_auth_sessions` | false | false | false | false | false |
| `sinau_issuer_poc.poc_identities` | false | false | false | false | false |
| `sinau_issuer_poc.poc_tenant_memberships` | false | false | false | false | false |
| `sinau_issuer_poc.poc_unit_memberships` | false | false | false | false | false |
| `sinau_private.context_keys` | false | false | false | false | false |

Function EXECUTE results:

| Function | EXECUTE |
|---|---:|
| `sinau_issuer_poc.validate_context_request(text,uuid,uuid)` | true |
| `sinau_issuer_poc.has_feature_entitlement(uuid,text)` | true |
| `sinau_private.verify_context_token(text)` | false |
| `sinau_private.current_verified_context()` | false |

The transaction ended with `ROLLBACK`; no catalog object or row was modified.

**Interpretation:** direct issuer-role privileges match the intended capability split for the inspected relations/functions. The issuer can execute its two issuer functions, but cannot directly read or write the authorization fixture tables/key store and cannot execute the verifier/accessor.

**Transitive runtime access:** because the earlier SET ROLE test succeeded, a session with runtime identity can explicitly assume the issuer role and then execute its two functions. Thus, this is role-to-role separation, not protection against arbitrary SQL running through a runtime connection that retains the SET membership.

**Limitations:** this audit checks effective ACL privileges via catalog OIDs; it did not invoke the SECURITY DEFINER functions or test the actual network login path for the runtime credential.


## 25. Query capability effective-privilege audit — 2026-11-27

The read-only audit ran after setting the session identity to `sinau_app_runtime_poc` and switching to `sinau_rls_test`. It reported:

- `session_user = sinau_app_runtime_poc`
- `current_user = sinau_rls_test`
- schema `sinau_issuer_poc` USAGE: false
- schema `sinau_private` USAGE: true

OID-based relation privilege checks returned false for SELECT, INSERT, UPDATE, DELETE, and TRUNCATE on all five inspected relations: the four issuer authorization tables (`poc_identities`, `poc_auth_sessions`, `poc_tenant_memberships`, and `poc_unit_memberships`) and `sinau_private.context_keys`.

Function EXECUTE results:

| Function | EXECUTE |
|---|---:|
| `sinau_issuer_poc.validate_context_request(text,uuid,uuid)` | false |
| `sinau_issuer_poc.has_feature_entitlement(uuid,text)` | false |
| `sinau_private.verify_context_token(text)` | true |
| `sinau_private.current_verified_context()` | true |

The transaction ended with `ROLLBACK`; no catalog object or row was modified.

**Interpretation:** direct query-role privileges match the intended capability split for the inspected relations/functions. The query role can use the private schema and execute the verifier/accessor, but cannot directly read or write authorization tables/key storage and cannot execute issuer functions.

**Transitive runtime access:** because the earlier SET ROLE test succeeded, a session with runtime identity can explicitly assume the query role and execute the two query functions. Thus, this is issuer/query role-to-role separation, not protection against arbitrary SQL running through a runtime connection that retains the SET membership.

**Limitations:** this audit checks effective ACL privileges via catalog OIDs. It did not invoke the verifier/accessor, exercise all RLS-protected operations, or test the actual network login path for the runtime credential.


## 26. Read-only runtime role boundary audit

The role-switch and effective-privilege checks establish that the runtime login can explicitly enter the issuer and query capability roles, and that each capability role has a narrow direct privilege surface. Before recording the role topology as accepted, run script `023-audit-runtime-role-boundary.sql` to inspect the complete membership options and ownership boundary.

The script reports:
- attributes for the runtime login, issuer/query capability roles, context owner, and PoC owner;
- membership edges with `ADMIN`, `INHERIT`, and `SET` options;
- all roles reachable from runtime through `SET TRUE` membership chains;
- all privileges inherited through `INHERIT TRUE` membership chains;
- direct runtime schema/function privileges without switching;
- owners of the private schemas, authorization tables, key store, and context functions;
- context-owner default ACLs.

It reads catalog metadata and effective ACLs only. It does not inspect token/session/key values or application rows, and it performs no DDL, DML, GRANT, or REVOKE. It has a hard guard for `sinau_design_poc` + superuser `postgres`, begins `READ ONLY`, and ends with `ROLLBACK`.

Run the exact pinned script:

```bash
curl -fL 'https://raw.githubusercontent.com/sulhanqidri/SINAU/c104e12ad07cec56086084e7d5a4cd89f4534982/docs/03-database/poc/023-audit-runtime-role-boundary.sql' \
  -o /run/023-audit-runtime-role-boundary.sql

sudo chown postgres:postgres /run/023-audit-runtime-role-boundary.sql
sudo chmod 600 /run/023-audit-runtime-role-boundary.sql

sudo -u postgres psql -X -v ON_ERROR_STOP=1 \
  -d sinau_design_poc \
  -f /run/023-audit-runtime-role-boundary.sql
```

### Review criteria

- `sinau_app_runtime_poc` is the only login in the runtime/capability chain; issuer, query, and context-owner roles are NOLOGIN.
- Runtime has `SET` reachability only to the intended issuer and query roles (plus any separately documented PoC-only path). It must not reach the owner, PoC admin, or PostgreSQL administrator.
- Runtime has no `ADMIN OPTION` on capability/owner roles.
- Issuer/query memberships do not accidentally expose other roles through nested membership paths.
- Capability roles do not own the schemas, protected tables, key store, or security-definer functions.
- Runtime cannot CREATE in the private schemas and has no unexpected direct object privileges.
- Default ACLs do not grant future private functions to PUBLIC.

The role-switching ability is required by the current same-connection flow: script 012 proves issuer → query → issuer switches while preserving one XID. Therefore, removing runtime SET membership is not a safe standalone change; it would require a different context-issuance/query architecture and a new XID-continuity proof. The candidate role model treats the runtime login as a trusted backend executor, while keeping the issuer and query capabilities as separate NOLOGIN roles with narrow grants. This remains a proposal until script 023 output and threat-model review are complete.

No role or privilege should be changed based only on the inventory. ADR-007 remains Proposed and PR #1 remains Open/Draft/unmerged.


## 27. Runtime role boundary findings and default function ACL correction — 2026-11-27

The user executed script `023-audit-runtime-role-boundary.sql` on PostgreSQL 18.7 in `sinau_design_poc`. The script completed and reached its final ROLLBACK marker.

### Confirmed runtime role boundary

Role attributes:

| Role | LOGIN | INHERIT | SUPERUSER | BYPASSRLS |
|---|---:|---:|---:|---:|
| `sinau_app_runtime_poc` | true | false | false | false |
| `sinau_context_issuer_poc` | false | false | false | false |
| `sinau_rls_test` | false | true | false | false |
| `sinau_context_owner` | false | false | false | false |
| `sinau_poc` | true | true | false | false |

Membership edges:

| Member | Granted role | ADMIN | INHERIT | SET |
|---|---|---:|---:|---:|
| `sinau_app_runtime_poc` | `sinau_context_issuer_poc` | false | false | true |
| `sinau_app_runtime_poc` | `sinau_rls_test` | false | false | true |
| `sinau_poc` | `sinau_context_issuer_poc` | false | true | true |
| `sinau_poc` | `sinau_rls_test` | false | true | true |

The recursive SET-role inventory found only two roles reachable from runtime: `sinau_context_issuer_poc` and `sinau_rls_test`. There were no inherited-role paths from runtime, and no SET path to `sinau_context_owner`, `sinau_poc`, or `postgres`. Runtime has no ADMIN OPTION on the inspected memberships.

The direct runtime checks returned false for USAGE and CREATE on `sinau_crypto`, `sinau_issuer_poc`, and `sinau_private`; false for direct EXECUTE on all four context functions; and false for the reported CREATE/TRIGGER surface on the inspected objects. The four context functions and five inspected private relations are owned by `sinau_context_owner`. The context owner, issuer, and query roles are all NOLOGIN and have no superuser/BYPASSRLS attributes.

**PoC-only elevated login:** `sinau_poc` is also a LOGIN role and inherits both capability memberships. It is the dedicated database owner/test login used by earlier PoC scripts, not the intended application runtime principal. Do not use `sinau_poc` as the web/runtime login or copy its inherited memberships into production. The runtime reachability result is specific to `sinau_app_runtime_poc`.

### Candidate architecture interpretation

The runtime role's SET membership is required by the existing same-connection/XID flow validated by script 012 (issuer → query → issuer). Removing either SET membership independently would invalidate that tested sequence and requires a replacement architecture plus new XID-continuity evidence.

The candidate threat model is therefore:
- treat `sinau_app_runtime_poc` as a trusted backend executor whose SQL is generated by controlled application code, not as a general-purpose SQL account;
- keep issuer and query capability roles NOLOGIN, with the distinct direct privileges already measured;
- do not expose arbitrary SQL execution, SQL consoles, or untrusted query fragments through the runtime connection;
- recognize that a compromise or SQL injection in the runtime session may switch into both granted capabilities; the role split is not a defense against arbitrary SQL executed as the trusted runtime;
- keep `sinau_poc` as a separate PoC owner/test login and never as the application runtime.

This is a PoC role-model proposal, not a production security acceptance. The audit made no role or privilege changes.

### Default function EXECUTE finding

Section 7 of script 023 returned **zero** `pg_default_acl` rows for `sinau_context_owner`. The installed verifier script 005 had attempted:

```sql
ALTER DEFAULT PRIVILEGES
    FOR ROLE sinau_context_owner
    IN SCHEMA sinau_private
    REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
```

That schema-scoped REVOKE does not remove PostgreSQL's built-in global default EXECUTE privilege for PUBLIC. Per-schema default privileges can add to global defaults; a schema-specific REVOKE cannot remove a privilege granted globally. Consequently, the attempted default hardening was ineffective for future functions. The four currently installed functions individually revoke PUBLIC EXECUTE, so this finding concerns future functions created by `sinau_context_owner`; it does not establish that those four current functions are executable by PUBLIC. See the official [PostgreSQL 18 ALTER DEFAULT PRIVILEGES documentation](https://www.postgresql.org/docs/18/sql-alterdefaultprivileges.html).

The source scripts have been corrected:
- `005-verify-context-token.sql` now uses a global `ALTER DEFAULT PRIVILEGES FOR ROLE sinau_context_owner REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC`.
- `010-context-issuer-fixtures.sql` now establishes the same global default before creating issuer functions, so the clean PoC installation order protects both private schemas.

These repository edits do **not** change the already-installed database. Apply and verify the intended isolated database change with script `024-fix-context-owner-default-function-acl.sql`.

### Apply the default ACL correction in the disposable PoC

Script 024:
- refuses to run outside `sinau_design_poc` or unless invoked by superuser `postgres`;
- verifies the context owner role, schema ownership, all four installed function owners, and absence of PUBLIC EXECUTE on the current functions before applying the fix;
- persists only the global default function ACL revocation for objects created by `sinau_context_owner`;
- creates a temporary probe function under `sinau_private`, checks that its ACL has owner EXECUTE but no PUBLIC EXECUTE, then rolls that probe transaction back;
- confirms that the global default ACL persists and the probe function does not.

The pinned script is commit `ecf5477239d0ed76b4090b30c292c365cf991692`:

```bash
curl -fL 'https://raw.githubusercontent.com/sulhanqidri/SINAU/ecf5477239d0ed76b4090b30c292c365cf991692/docs/03-database/poc/024-fix-context-owner-default-function-acl.sql' \
  -o /run/024-fix-context-owner-default-function-acl.sql

sudo chown postgres:postgres /run/024-fix-context-owner-default-function-acl.sql
sudo chmod 600 /run/024-fix-context-owner-default-function-acl.sql

sudo -u postgres psql -X -v ON_ERROR_STOP=1 \
  -d sinau_design_poc \
  -f /run/024-fix-context-owner-default-function-acl.sql
```

Expected final evidence:
- global default function ACL entry exists for `sinau_context_owner`;
- PUBLIC EXECUTE is absent from that default ACL;
- each existing context function still has no PUBLIC EXECUTE;
- temporary probe reports owner EXECUTE=true and PUBLIC EXECUTE=false;
- final persistence check reports `probe_function_persisted=false` and `global_default_acl_persisted=true`;
- script prints `CONTEXT OWNER DEFAULT FUNCTION ACL FIX COMPLETE`.

The only persistent effect is the context owner's global default EXECUTE policy for future functions in this database. No existing function grant is changed by script 024, and no role membership, schema, table, policy, application row, or production object is changed. Do not consider this gate passed until the script has actually been run and its complete output reviewed.


## 28. VOLATILE SPI snapshot visibility test — 2026-11-27

### Script 024 execution result — PASS

The user executed `024-fix-context-owner-default-function-acl.sql` against `sinau_design_poc`.

Observed:
- Pre-fix inventory had zero stored default ACL rows for `sinau_context_owner`.
- The global `ALTER DEFAULT PRIVILEGES FOR ROLE sinau_context_owner REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC` completed and committed.
- The stored global function ACL became `{sinau_context_owner=X/sinau_context_owner}`; PUBLIC EXECUTE was absent.
- All four existing context functions retained their specific owner/capability-role EXECUTE grants, and all four returned `public_can_execute=false`.
- The probe function was created by `sinau_context_owner` in a rollback-only transaction. Its ACL was `{sinau_context_owner=X/sinau_context_owner}`, with PUBLIC EXECUTE false and owner EXECUTE true.
- The probe transaction rolled back; the final persistence query reported `probe_function_persisted=false` and `global_default_acl_persisted=true`.
- The script ended with `CONTEXT OWNER DEFAULT FUNCTION ACL FIX COMPLETE`.

**Gate closed:** the live disposable database now has a global default function ACL for `sinau_context_owner` that excludes PUBLIC EXECUTE. This does not change existing function grants, role memberships, tables, policies, or production objects. The corrected clean-install sources 005 and 010 now contain the same global revoke.

### Why the next test is needed

PostgreSQL 18 documents that a VOLATILE SQL/PLpgSQL function obtains a fresh snapshot for each internal query it executes, whereas STABLE/IMMUTABLE functions use the calling query's snapshot. Separately, READ COMMITTED gives each top-level command its own snapshot. References:
- [PostgreSQL 18 Function Volatility Categories](https://www.postgresql.org/docs/18/xfunc-volatility.html)
- [PostgreSQL 18 Visibility of Data Changes (SPI)](https://www.postgresql.org/docs/18/spi-visibility.html)
- [PostgreSQL 18 Transaction Isolation](https://www.postgresql.org/docs/18/transaction-iso.html)

That behavior means a verifier that performs multiple independent SPI SELECTs for account, session, tenant membership, unit membership, unit lifecycle, and key state could observe different committed database states during one verifier call. To avoid internally mixed authorization state, the v2 design should retrieve all authoritative authorization rows and the applicable signing-key record with **one joined SQL SELECT**, then perform signature/epoch comparisons in PL/pgSQL. A single SPI command uses one snapshot for that joined read. The existing verifier does not yet implement this.

### Run the VOLATILE SPI snapshot probe

Script `025-test-volatile-snapshot-freshness.sql` is a two-connection experiment. **Execution result — PASS:** Connection A reported `VOLATILE SPI status sequence: active|disabled`; Connection B committed the synthetic account disable between the two internal reads; then Connection A rolled back and removed the temporary `SECURITY DEFINER VOLATILE` probe function. The function:
1. reads the synthetic identity status (`active`);
2. acquires a transaction-level advisory lock with key `(42424, 52525)` to signal Connection B;
3. sleeps for 60 seconds;
4. executes a second internal SELECT against the same synthetic identity row;
5. expects to return `active|disabled` after Connection B commits the change during the sleep.

The probe function is created after the global default ACL fix; it should not grant EXECUTE to PUBLIC. The function and all A-side DDL are rolled back when the test ends. Connection B performs one exact synthetic-row update that must be restored after A rolls back.

Download and stage the script:

```bash
curl -fL 'https://raw.githubusercontent.com/sulhanqidri/SINAU/70b2f3ccdadf14f306ca77104b6a5b4fb35328b0/docs/03-database/poc/025-test-volatile-snapshot-freshness.sql' \
  -o /run/025-test-volatile-snapshot-freshness.sql

sudo chown postgres:postgres /run/025-test-volatile-snapshot-freshness.sql
sudo chmod 600 /run/025-test-volatile-snapshot-freshness.sql
```

#### Connection A — start the probe

Run in terminal A. It blocks for up to 60 seconds during the probe:

```bash
sudo -u postgres psql -X -v ON_ERROR_STOP=1 \
  -d sinau_design_poc \
  -f /run/025-test-volatile-snapshot-freshness.sql
```

When it prints `PROBE RUNNING`, immediately execute the following block in terminal B. Do not wait for A to finish.

#### Connection B — wait for A's advisory lock, revoke, and commit

```bash
sudo -u postgres psql -X -v ON_ERROR_STOP=1 \
  -d sinau_design_poc <<'SQL'
BEGIN;

DO $revoke$
DECLARE
    v_seen pg_catalog.bool := false;
    v_rows pg_catalog.int4;
    i pg_catalog.int4;
BEGIN
    FOR i IN 1..400 LOOP
        SELECT EXISTS (
            SELECT 1
            FROM pg_catalog.pg_locks
            WHERE locktype = 'advisory'
              AND classid = 42424::pg_catalog.oid
              AND objid = 52525::pg_catalog.oid
              AND objsubid = 2
              AND granted
              AND pid <> pg_catalog.pg_backend_pid()
        )
        INTO v_seen;

        EXIT WHEN v_seen;
        PERFORM pg_catalog.pg_sleep(0.1::pg_catalog.float8);
    END LOOP;

    IF NOT v_seen THEN
        RAISE EXCEPTION
            'TIMEOUT: Connection A did not expose the expected advisory lock';
    END IF;

    UPDATE sinau_issuer_poc.poc_identities
       SET account_status = 'disabled'
     WHERE actor_id = '91000000-0000-0000-0000-000000000001'
       AND account_status = 'active';

    GET DIAGNOSTICS v_rows = ROW_COUNT;

    IF v_rows <> 1 THEN
        RAISE EXCEPTION
            'Expected exactly one active synthetic identity, updated %',
            v_rows;
    END IF;

    RAISE NOTICE
        'PASS: observed Connection A probe lock and changed exactly one synthetic identity';
END
$revoke$;

COMMIT;
SQL
```

Expected Connection A result:

```text
VOLATILE SPI status sequence: active|disabled
PASS: VOLATILE internal SELECT after the concurrent COMMIT observed the new READ COMMITTED state
SESSION A ROLLED BACK — TEMPORARY PROBE FUNCTION REMOVED
```

#### Mandatory restoration after Connection A finishes

Run in terminal B even if the probe reports a failure, provided the disable transaction committed:

```bash
sudo -u postgres psql -X -v ON_ERROR_STOP=1 \
  -d sinau_design_poc <<'SQL'
BEGIN;

DO $restore$
DECLARE
    v_rows pg_catalog.int4;
BEGIN
    UPDATE sinau_issuer_poc.poc_identities
       SET account_status = 'active'
     WHERE actor_id = '91000000-0000-0000-0000-000000000001'
       AND account_status = 'disabled';

    GET DIAGNOSTICS v_rows = ROW_COUNT;

    IF v_rows <> 1 THEN
        RAISE EXCEPTION
            'Expected exactly one disabled synthetic identity for restoration, updated %',
            v_rows;
    END IF;

    RAISE NOTICE 'PASS: restored exactly one synthetic identity to active';
END
$restore$;

COMMIT;

BEGIN READ ONLY;

SELECT
    pg_catalog.count(*) AS matching_rows,
    pg_catalog.count(*) FILTER (
        WHERE account_status = 'active'
    ) AS active_rows,
    pg_catalog.count(*) FILTER (
        WHERE account_status = 'disabled'
    ) AS disabled_rows
FROM sinau_issuer_poc.poc_identities
WHERE actor_id = '91000000-0000-0000-0000-000000000001';

ROLLBACK;
SQL
```

**User execution result — PASS:** the restoration block updated exactly one row and the final read-only audit returned `matching_rows=1`, `active_rows=1`, `disabled_rows=0`. The synthetic account fixture is restored. No cleanup update is outstanding.

If Connection B times out before the update, it rolls back without changing the row. Connection A will not report the expected sequence; stop and inspect, but do not run a blind restore. If Connection A fails after Connection B commits the revocation, restore the exact row before doing any other test.

**Interpretation:** `active|disabled` proves the second internal SQL query of a VOLATILE function saw a commit made after the first internal query in the same top-level statement. It does not prove that RLS currently rechecks membership; the installed verifier v1 still does not consult these state tables. It also does not guarantee that a statement is forcibly cancelled by a revocation occurring after its authorization check.

**Next design consequence:** implement v2 authoritative state retrieval in one joined SPI SELECT so account, exact session, tenant membership, unit membership/unit state, and signing-key status are evaluated from one coherent snapshot. Then test revoke-before-statement, revoke-during-check, and revoke-after-check boundaries through actual RLS policies. Do not add epochs or change verifier code until the probe result is recorded and the complete v2 token/epoch contract has been reviewed.


## 29. Audit actual RLS verifier invocation count — 2026-11-27

### Why this diagnostic is the next gate

The source of script 007 generates a predicate for academic_years with two scalar subqueries: one reads tenant_id from sinau_private.current_verified_context(), and another independently reads unit_id from the same accessor. Since the accessor and verifier are VOLATILE, this source shape raises a question about repeated calls and potentially different internal SPI snapshots.

PostgreSQL 18 provides two relevant diagnostic tools:
- EXPLAIN (VERBOSE) displays the subplans generated for the policy; plain EXPLAIN plans the statement but does not execute it. See https://www.postgresql.org/docs/18/sql-explain.html and https://www.postgresql.org/docs/18/using-explain.html.
- track_functions='pl' plus pg_stat_xact_user_functions records PL/pgSQL function calls made by the current transaction. The transaction-local view updates continuously; no global statistics reset is needed. See https://www.postgresql.org/docs/18/runtime-config-statistics.html and https://www.postgresql.org/docs/18/monitoring-stats.html.

Script 026-audit-rls-verifier-call-count.sql performs one protected SELECT against public.academic_years, then reports the actual number of calls to sinau_private.verify_context_token(text) for that transaction. It also prints the installed policy expression and the non-executing EXPLAIN plan. The setting track_functions='pl' is LOCAL to the transaction, and the script ends in ROLLBACK. It does not change database objects, role grants, policies, persistent configuration, or fixture rows.

### Prepare the script and existing synthetic signer

~~~bash
set -e

SIGNER_COMMIT='70b2f3ccdadf14f306ca77104b6a5b4fb35328b0'
AUDIT_COMMIT='cf6862bd82b938ded662eff97352b2227a80720e'

curl -fL "https://raw.githubusercontent.com/sulhanqidri/SINAU/$SIGNER_COMMIT/docs/03-database/poc/019-sign-authorization-freshness-token.py" \
  -o "$HOME/019-sign-authorization-freshness-token.py"
chmod 700 "$HOME/019-sign-authorization-freshness-token.py"

curl -fL "https://raw.githubusercontent.com/sulhanqidri/SINAU/$AUDIT_COMMIT/docs/03-database/poc/026-audit-rls-verifier-call-count.sql" \
  -o "$HOME/026-audit-rls-verifier-call-count.sql"

sudo install -o postgres -g postgres -m 600 \
  "$HOME/026-audit-rls-verifier-call-count.sql" \
  /run/026-audit-rls-verifier-call-count.sql

install -d -m 700 /run/sinau-poc-token-signer
sudo rm -f -- /run/authfreshness-context.token \
  /run/sinau-poc-token-signer/authfreshness-context.token
~~~

The signer is the already-reviewed synthetic v1 signer; it reads the existing 0600 PoC HMAC key from the current OS user's home. It is not a real application issuer. Its token must be signed for the exact XID that Session A prints.

### Terminal A — start the diagnostic

~~~bash
sudo -u postgres psql -X -v ON_ERROR_STOP=1 \
  -d sinau_design_poc \
  -f /run/026-audit-rls-verifier-call-count.sql
~~~

The script starts a READ COMMITTED transaction, enables PL/pgSQL function tracking only for that transaction, prints the XID, and waits for the token. Leave it running.

### Terminal B — sign the exact XID and stage the token

Replace XID_FROM_SESSION_A with the decimal XID printed in Terminal A:

~~~bash
python3 "$HOME/019-sign-authorization-freshness-token.py" XID_FROM_SESSION_A

sudo install -o postgres -g postgres -m 600 \
  /run/sinau-poc-token-signer/authfreshness-context.token \
  /run/authfreshness-context.token
~~~

Press Enter in Terminal A. The script imports the token without displaying it, prints the installed policy expression and EXPLAIN plan, executes exactly one protected SELECT, reads the current transaction's verifier-call counter, and rolls back.

### What to record

- Visible row count should be 1 for the tenant-A/unit-A1 fixture.
- Record the actual calls count for sinau_private.verify_context_token(text).
- Examine the EXPLAIN output for independent InitPlan/SubPlan nodes corresponding to tenant and unit extraction.
- **User execution result — PASS:** one protected SELECT returned exactly one row and recorded `verify_context_token(text) calls=2` (`total_time_ms=2.790`, `self_time_ms=2.790`). EXPLAIN showed two independent InitPlans: InitPlan 1 called `current_verified_context()` for `tenant_id`; InitPlan 2 called it again for `unit_id`. The installed policy expression and execution plan therefore confirm two verifier executions for this single SELECT. The query transaction rolled back.
- A count of 0 is a failed diagnostic (tracking disabled, policy not exercised, or function not tracked); do not interpret it as proof of one invocation.

After script 026 reports ROLLBACK, remove both token copies:

~~~bash
sudo rm -f -- /run/authfreshness-context.token \
  /run/sinau-poc-token-signer/authfreshness-context.token
~~~

**Scope:** this measures the verifier invocation count for one SELECT on academic_years only. It does not establish counts for every table/policy or production query plan. No DDL or RLS policy modification is part of this gate.

**Next design consequence:** repeated verifier execution is confirmed. A candidate policy for tables requiring both tenant and unit scope should obtain both claims from one row-valued subquery, for example `(tenant_id, unit_id) = (SELECT ctx.tenant_id, ctx.unit_id FROM sinau_private.current_verified_context() AS ctx)`. PostgreSQL's single-row comparison requires the subquery to return exactly as many columns as the left row constructor and at most one row. Script 027 tests this candidate inside a transaction and rolls it back. Tenant-only tables and `audit_events` with nullable `unit_id` require separate safe expressions; do not mechanically apply the same predicate to them.

## 30. Candidate one-row context policy — rollback-only probe

Script `027-test-single-row-context-policy.sql` tests a candidate rewrite for `public.academic_years` only. It temporarily replaces the installed `sinau_rls_isolation` policy inside a transaction with a single row-valued subquery:

```sql
(tenant_id, unit_id) = (
    SELECT ctx.tenant_id, ctx.unit_id
    FROM sinau_private.current_verified_context() AS ctx
)
```

The subquery returns two columns for the two left-hand row fields and at most one row because the verified context function returns at most one row for a valid transaction-bound token. PostgreSQL documents that a `row_constructor operator (subquery)` comparison requires the subquery to return exactly as many columns as the left row constructor, and at most one row. See https://www.postgresql.org/docs/18/functions-subquery.html.

The candidate policy is applied only inside the open transaction. The script runs EXPLAIN and one actual protected SELECT, measures verifier calls with transaction-local function tracking, checks that the query still returns exactly one tenant-A/unit-A1 row, and then ROLLBACK restores the original installed two-subquery policy. It prints the restored policy after rollback as an additional check.

Pinned script:
https://raw.githubusercontent.com/sulhanqidri/SINAU/021ea42dcdd90760e58d1c114c2bb47490ef5f3f/docs/03-database/poc/027-test-single-row-context-policy.sql

Download and stage:

```bash
set -e

SIGNER_COMMIT='70b2f3ccdadf14f306ca77104b6a5b4fb35328b0'
POLICY_COMMIT='021ea42dcdd90760e58d1c114c2bb47490ef5f3f'

curl -fL "https://raw.githubusercontent.com/sulhanqidri/SINAU/$SIGNER_COMMIT/docs/03-database/poc/019-sign-authorization-freshness-token.py" \
  -o "$HOME/019-sign-authorization-freshness-token.py"
chmod 700 "$HOME/019-sign-authorization-freshness-token.py"

curl -fL "https://raw.githubusercontent.com/sulhanqidri/SINAU/$POLICY_COMMIT/docs/03-database/poc/027-test-single-row-context-policy.sql" \
  -o "$HOME/027-test-single-row-context-policy.sql"

sudo install -o postgres -g postgres -m 600 \
  "$HOME/027-test-single-row-context-policy.sql" \
  /run/027-test-single-row-context-policy.sql

install -d -m 700 /run/sinau-poc-token-signer
sudo rm -f -- /run/authfreshness-context.token \
  /run/sinau-poc-token-signer/authfreshness-context.token
```

Terminal A:

```bash
sudo -u postgres psql -X -v ON_ERROR_STOP=1 \
  -d sinau_design_poc \
  -f /run/027-test-single-row-context-policy.sql
```

When Terminal A prints the transaction XID, sign a token for that exact XID in Terminal B:

```bash
python3 "$HOME/019-sign-authorization-freshness-token.py" XID_FROM_SESSION_A

sudo install -o postgres -g postgres -m 600 \
  /run/sinau-poc-token-signer/authfreshness-context.token \
  /run/authfreshness-context.token
```

Press Enter in Terminal A. Expected candidate evidence:
- The candidate policy expression uses one row-valued subquery for both `tenant_id` and `unit_id`.
- EXPLAIN shows one InitPlan/Function Scan for `current_verified_context()` returning both columns.
- The protected SELECT returns one visible row.
- `verify_context_token(text)` call count is exactly 1.
- Script prints `PASS: composite row comparison returned one row with exactly one verifier call`.
- After ROLLBACK, the catalog output shows the original two-subquery policy restored.

After the script has rolled back, remove the token copies:

```bash
sudo rm -f -- /run/authfreshness-context.token \
  /run/sinau-poc-token-signer/authfreshness-context.token
```

### Script 027 execution result — PASS

The user executed script 027 using a transaction-bound synthetic token for XID 958.

Observed:
- The temporary candidate policy used one row-valued subquery returning both `ctx.tenant_id` and `ctx.unit_id`.
- EXPLAIN showed one InitPlan and one Function Scan on `current_verified_context()`; the index condition used both columns from the same InitPlan (`col1` and `col2`).
- The protected SELECT returned exactly one row.
- `pg_stat_xact_user_functions` recorded exactly one call to `sinau_private.verify_context_token(text)` (`total_time_ms=2.623`, `self_time_ms=2.623`).
- The script reported `PASS: composite row comparison returned one row with exactly one verifier call`.
- ROLLBACK restored the original installed policy; the post-rollback `pg_policies` output again showed the two original scalar subqueries for tenant and unit.

**Conclusion:** for `academic_years`, the candidate reduces the verifier calls per protected SELECT from two to one while preserving the observed visible-row count. This result supports the candidate shape but does not approve permanent adoption or generalization to other table classes.

### Remaining policy matrix before changing script 007

Next inspect every RLS-protected table and classify it as tenant-only, tenant+unit, or special nullable-unit (`audit_events`). For each class, verify SELECT, INSERT, UPDATE, and DELETE behavior; malformed/expired token fail-closed behavior; and cross-tenant/cross-unit scope enforcement. The candidate must use one coherent verified-context row per policy check. Do not replace persistent script 007 yet.


This candidate is not yet adopted. First test it, inspect its plan and actual count, and verify fail-closed behavior with malformed/expired tokens and cross-tenant/unit rows. This script covers only `academic_years`; it does not settle the null-unit exception for `audit_events`, tenant-only tables, or write policy semantics across every table. Do not modify persistent script 007 or install this candidate policy outside the disposable rollback-only probe.

## 31. Read-only RLS table/policy matrix inventory

Script `028-audit-rls-policy-table-matrix.sql` is a read-only catalog audit to enumerate every public ordinary/partitioned table that has `tenant_id`, `unit_id`, or RLS enabled. It classifies scope columns and nullability, reports ENABLE/FORCE RLS, lists the exact installed policy expressions and commands, and flags scoped tables without both ENABLE and FORCE or RLS tables without policies.

It also prints focused details for `tenants`, `education_units`, and `audit_events`. These distinctions are required before generalizing the one-row context candidate:
- `tenants` is the global registry and intentionally remains outside tenant RLS in the current PoC.
- `education_units` is tenant-scoped, not unit-scoped.
- `audit_events` allows a tenant-level row with `unit_id IS NULL`; preserve that behavior explicitly.

Script 028 uses a READ ONLY transaction and a database/superuser guard. It performs no persistent changes.

Download and run:

~~~bash
set -e

AUDIT_COMMIT='dd1dacb269d660b8e00e7274d2419ea9f6af7fa3'

curl -fL \
  "https://raw.githubusercontent.com/sulhanqidri/SINAU/$AUDIT_COMMIT/docs/03-database/poc/028-audit-rls-policy-table-matrix.sql" \
  -o "$HOME/028-audit-rls-policy-table-matrix.sql"

sudo install -o postgres -g postgres -m 600 \
  "$HOME/028-audit-rls-policy-table-matrix.sql" \
  /run/028-audit-rls-policy-table-matrix.sql

sudo -u postgres psql -X -v ON_ERROR_STOP=1 \
  -d sinau_design_poc \
  -f /run/028-audit-rls-policy-table-matrix.sql
~~~

### Script 028 execution result — PASS

The user executed script 028 against `sinau_design_poc`. The read-only audit reported 14 public tables with tenant/unit scope columns:

| Scope class | Count | Tables |
|---|---:|---|
| Tenant-only | 1 | `education_units` |
| Tenant + unit, both NOT NULL | 12 | `academic_years`, `assessment_definitions`, `assessment_participants`, `attendance_corrections`, `attendance_record_revisions`, `attendance_records`, `attendance_session_participants`, `attendance_sessions`, `class_groups`, `student_class_placements`, `student_enrollments`, `student_scores` |
| Tenant + unit, nullable | 1 | `audit_events` |

All 14 scoped tables had RLS enabled and forced. No scoped table was missing ENABLE/FORCE, and no RLS-enabled public table was missing a policy. The 14 installed policies were permissive, targeted `sinau_rls_test`, and used command `ALL` with both USING and WITH CHECK expressions. `tenants` has neither scope column and remains outside RLS as the global registry. `education_units` uses only tenant scope. `audit_events` keeps the exception `(unit_id IS NULL OR unit_id = context.unit_id)`.

### Important audit_events schema observation

The metadata shows **both** `audit_events.tenant_id` and `audit_events.unit_id` are nullable. Source DDL `001-schema.sql` defines `CHECK (unit_id IS NULL OR tenant_id IS NOT NULL)`. This prohibits a unit-scoped row without a tenant, but it permits both columns to be NULL (SQL CHECK accepts UNKNOWN). The current RLS predicate still denies a row with `tenant_id IS NULL` to an ordinary tenant context because `tenant_id = context.tenant_id` is not TRUE. Do not interpret both-NULL rows as visible/global tenant events without an explicit authorization decision.

Script `029-audit-audit-events-null-scope.sql` was executed successfully. Both `tenant_id` and `unit_id` are nullable. The validated check `unit_id IS NULL OR tenant_id IS NOT NULL` permits both-NULL rows while prohibiting a unit without a tenant. However, the table currently has zero rows: `total_rows=0`, both-NULL=0, tenant-only=0, unit-scoped=0, and invalid-by-check=0. The actor-type grouped query also returned zero rows. Therefore the data audit does not establish that global audit events exist or are needed; preserve the current tenant-scoped policy, which does not expose both-NULL rows to an ordinary tenant context.

Download and run script 029:

~~~bash
set -e
AUDIT_COMMIT='d36e304ceb979de68479b54d3d26e983250509a3'
curl -fL \
  "https://raw.githubusercontent.com/sulhanqidri/SINAU/$AUDIT_COMMIT/docs/03-database/poc/029-audit-audit-events-null-scope.sql" \
  -o "$HOME/029-audit-audit-events-null-scope.sql"
sudo install -o postgres -g postgres -m 600 \
  "$HOME/029-audit-audit-events-null-scope.sql" \
  /run/029-audit-audit-events-null-scope.sql
sudo -u postgres psql -X -v ON_ERROR_STOP=1 \
  -d sinau_design_poc \
  -f /run/029-audit-audit-events-null-scope.sql
~~~

The metadata/data gate is closed for this PoC snapshot: `audit_events` currently contains no rows. Its future both-NULL semantics remain a domain decision, not a demonstrated data requirement. Preserve the current conservative behavior (not visible to tenant context) unless a separate global-audit authorization policy is explicitly designed and tested.

Review all five output sections, especially scope class/nullability, exact USING/WITH CHECK expressions, scoped tables not ENABLE/FORCE, and special-table behavior. The script ends with ROLLBACK and an explicit read-only completion marker.

**Gate:** do not change persistent script 007 until the complete inventory is reviewed and a per-class SELECT/INSERT/UPDATE/DELETE matrix is designed. The `academic_years` composite policy probe is validated only for that table and does not prove the candidate is appropriate for tenant-only or nullable-unit policies.

## 32. Transactional RLS read/write matrix for representative table classes

Script `030-test-rls-policy-classes.sql` is a rollback-only behavioral test using three representative classes from inventory 028:
- `education_units`: tenant-only (`tenant_id NOT NULL`, no unit column);
- `academic_years`: tenant+unit (`tenant_id` and `unit_id NOT NULL`);
- `audit_events`: nullable scope (`tenant_id` and `unit_id` nullable, with `CHECK (unit_id IS NULL OR tenant_id IS NOT NULL)`).

It uses the fixed synthetic tenant A/B and unit A1/A2/B1 fixture IDs. It creates temporary test rows, exercises same-scope reads/writes, checks cross-tenant/unit isolation, records that the tenant-only table currently shows both tenant-A units to a token scoped to unit A1, and tests the audit-specific tenant-level row (`unit_id IS NULL`). **That cross-unit visibility on `education_units` is an observed consequence of its tenant-only policy, not yet an approved authorization requirement:** confirm whether every tenant member may enumerate all units or whether visibility must depend on tenant-admin/role status. It also checks that a both-NULL audit event is rejected by the current tenant-scoped WITH CHECK, and that empty/malformed tokens fail closed. All DML is performed inside one explicit transaction that ends with ROLLBACK; test IDs are preflight-checked so an existing row is never overwritten.

**Important scope:** the script tests representative tables for the three policy classes; it does not insert into every complex attendance/assessment domain table, and it does not prove every business-specific FK/trigger invariant. Inventory 028 showed the other 11 tenant+unit tables share the same generated policy predicate, but a full domain-level regression suite remains required before a permanent global policy rewrite.

Download and stage the tested revision:

~~~bash
set -e

SIGNER_COMMIT='70b2f3ccdadf14f306ca77104b6a5b4fb35328b0'
MATRIX_COMMIT='be9dc6e42a28cf31abcc8836f8091328f1ca3fca'

curl -fL "https://raw.githubusercontent.com/sulhanqidri/SINAU/$SIGNER_COMMIT/docs/03-database/poc/019-sign-authorization-freshness-token.py" \
  -o "$HOME/019-sign-authorization-freshness-token.py"
chmod 700 "$HOME/019-sign-authorization-freshness-token.py"

curl -fL "https://raw.githubusercontent.com/sulhanqidri/SINAU/$MATRIX_COMMIT/docs/03-database/poc/030-test-rls-policy-classes.sql" \
  -o "$HOME/030-test-rls-policy-classes.sql"

sudo install -o postgres -g postgres -m 600 \
  "$HOME/030-test-rls-policy-classes.sql" \
  /run/030-test-rls-policy-classes.sql

install -d -m 700 /run/sinau-poc-token-signer
sudo rm -f -- /run/authfreshness-context.token \
  /run/sinau-poc-token-signer/authfreshness-context.token
~~~

Terminal A:

~~~bash
sudo -u postgres psql -X -v ON_ERROR_STOP=1 \
  -d sinau_design_poc \
  -f /run/030-test-rls-policy-classes.sql
~~~

When Terminal A prints the XID, sign a token for that exact XID in Terminal B:

~~~bash
python3 "$HOME/019-sign-authorization-freshness-token.py" XID_FROM_SESSION_A

sudo install -o postgres -g postgres -m 600 \
  /run/sinau-poc-token-signer/authfreshness-context.token \
  /run/authfreshness-context.token
~~~

Press Enter in Terminal A. The script must report PASS for tenant-only, tenant+unit, audit-events nullable scope, and fail-closed checks, then finish with `ROLLBACK`.

After completion, remove both tmpfs token files:

~~~bash
sudo rm -f -- /run/authfreshness-context.token \
  /run/sinau-poc-token-signer/authfreshness-context.token
~~~

**Execution result (2026-11-27): PASS.** Script 030 was executed against `sinau_design_poc` with transaction XID `962`. The transaction-bound token was installed successfully; tenant-only `education_units`, tenant+unit `academic_years`, nullable-scope `audit_events`, and empty/malformed-token fail-closed checks all reported PASS. The script reached `ROLLBACK` and printed `RLS POLICY CLASS MATRIX COMPLETE — ALL TEST DML ROLLED BACK`. This confirms the tested representative behaviors only; it did not persist test DML or alter installed policies.

**Observed authorization behavior still requiring a product decision:** a token scoped to unit A1 can enumerate both tenant-A units through the tenant-only `education_units` policy. The test records current behavior; it does not approve that access rule for all unit members.

**Gate:** script 030 has passed, but do not make a persistent policy rewrite in script 007 yet. First resolve the intended `education_units` enumeration permission and complete domain-level regression tests for every protected table. This representative-class result is not a replacement for those tests.

## 33. Read-only domain-integrity inventory for remaining tenant+unit tables

Script `031-audit-domain-integrity-matrix.sql` inventories the eleven tenant+unit relations not yet covered by the representative RLS behavior test:
`assessment_definitions`, `assessment_participants`, `attendance_corrections`, `attendance_record_revisions`, `attendance_records`, `attendance_session_participants`, `attendance_sessions`, `class_groups`, `student_class_placements`, `student_enrollments`, and `student_scores`.

It reads PostgreSQL catalog metadata only: columns and defaults, nullability, primary/unique/foreign-key/check/exclusion constraints, deferrability and validation, non-internal trigger definitions and trigger-function security settings, indexes, and installed RLS policies. It does not read application rows, create temp objects, or alter any database object, role, grant, policy, or setting. The script has a strict database/role guard and runs in a READ ONLY transaction.

Download and execute on the disposable PoC only:

~~~bash
set -e

DOMAIN_COMMIT='7049b5b3d171ff1f4e7bde7acf50cc14b855f447'

curl -fL "https://raw.githubusercontent.com/sulhanqidri/SINAU/$DOMAIN_COMMIT/docs/03-database/poc/031-audit-domain-integrity-matrix.sql" \
  -o "$HOME/031-audit-domain-integrity-matrix.sql"

sudo install -o postgres -g postgres -m 600 \
  "$HOME/031-audit-domain-integrity-matrix.sql" \
  /run/031-audit-domain-integrity-matrix.sql

sudo -u postgres psql -X -v ON_ERROR_STOP=1 \
  -d sinau_design_poc \
  -f /run/031-audit-domain-integrity-matrix.sql
~~~

Expected final marker: `DOMAIN INTEGRITY INVENTORY COMPLETE — READ ONLY`. Review the output sections for constraints, trigger functions, indexes, and RLS policy coverage. This is an inventory, not yet a domain write regression. Preserve the output for designing the next rollback-only test. Script 017 already passed its dedicated regression for the two assessment/attendance participant triggers; do not duplicate that trigger-shadow test.

## 34. Proposed tenant-wide visibility rule for education_units — NOT ADOPTED

Recommended authorization behavior for the multi-unit foundation and independent-school model:

- A tenant owner or explicitly authorized foundation/tenant administrator may enumerate all active education units within that tenant.
- A unit-scoped member may enumerate only the unit selected in the verified context, unless a separate tenant-wide capability is active.
- No role may read units from another tenant. Creating, editing, deactivating, or transferring units should be governed by separate write capabilities rather than inferred from permission to list units.

This is a design recommendation, not an approved policy. The current PoC issuer fixtures store tenant and unit membership status but no role/capability field. The v1 context exposes actor, tenant, and unit identifiers but no tenant-wide permission. Therefore, current context claims cannot safely distinguish a foundation administrator from an ordinary unit member. Before changing the `education_units` RLS predicate, the issuer design must add and validate a tenant-wide capability from authoritative membership/authorization state, and the verified context must expose it coherently. Do not infer this capability from a client-provided setting or from tenant membership alone.
