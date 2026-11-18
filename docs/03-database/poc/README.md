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
