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

