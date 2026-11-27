-- SINAU PostgreSQL 18 Design PoC — trusted context issuer membership tests
-- Run ONLY in sinau_design_poc after 010-context-issuer-fixtures.sql.
-- Open psql as the PoC login sinau_poc (or session-authorize to sinau_poc).
-- This script uses public synthetic session strings from 010; they are not
-- real credentials. It never issues or prints an RLS context token.
-- All test work ends with ROLLBACK.

\set ON_ERROR_STOP on

DO $database_guard$
BEGIN
    IF pg_catalog.current_database() <> 'sinau_design_poc' THEN
        RAISE EXCEPTION
            'REFUSING TO RUN: expected database sinau_design_poc, got %',
            pg_catalog.current_database();
    END IF;
END
$database_guard$;

BEGIN;

SET LOCAL ROLE sinau_context_issuer_poc;

DO $issuer_tests$
DECLARE
    v_count pg_catalog.int8;
    v_actor_matches pg_catalog.int8;
BEGIN
    -- ISS-01: active identity + session + tenant membership + unit membership.
    SELECT
        pg_catalog.count(*),
        pg_catalog.count(*) FILTER (
            WHERE r.actor_id = '91000000-0000-0000-0000-000000000001'
        )
      INTO v_count, v_actor_matches
      FROM sinau_issuer_poc.validate_context_request(
          'SINAU-POC-ACTIVE-SESSION-A-NOT-A-REAL-CREDENTIAL',
          '00000000-0000-0000-0000-000000000001',
          '10000000-0000-0000-0000-000000000001'
      ) AS r;

    IF v_count <> 1 OR v_actor_matches <> 1 THEN
        RAISE EXCEPTION 'FAIL ISS-01: active membership should authorize unit context';
    END IF;
    RAISE NOTICE 'PASS ISS-01: active user/session/tenant/unit membership accepted';

    -- ISS-02: tenant member but revoked unit membership cannot receive unit scope.
    SELECT pg_catalog.count(*) INTO v_count
    FROM sinau_issuer_poc.validate_context_request(
        'SINAU-POC-ACTIVE-SESSION-A-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000002'
    );

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL ISS-02: revoked unit membership was accepted';
    END IF;
    RAISE NOTICE 'PASS ISS-02: tenant membership alone does not grant another unit';

    -- ISS-03: unit membership exists, but parent tenant membership is revoked.
    SELECT pg_catalog.count(*) INTO v_count
    FROM sinau_issuer_poc.validate_context_request(
        'SINAU-POC-ACTIVE-SESSION-A-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000002',
        '20000000-0000-0000-0000-000000000001'
    );

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL ISS-03: revoked tenant membership was accepted';
    END IF;
    RAISE NOTICE 'PASS ISS-03: revoked tenant membership blocks unit context';

    -- ISS-04: tenant-level context is possible with active tenant membership;
    -- the null unit claim does not grant a unit.
    SELECT
        pg_catalog.count(*),
        pg_catalog.count(*) FILTER (
            WHERE r.actor_id = '91000000-0000-0000-0000-000000000001'
        )
      INTO v_count, v_actor_matches
      FROM sinau_issuer_poc.validate_context_request(
          'SINAU-POC-ACTIVE-SESSION-A-NOT-A-REAL-CREDENTIAL',
          '00000000-0000-0000-0000-000000000001',
          NULL
      ) AS r;

    IF v_count <> 1 OR v_actor_matches <> 1 THEN
        RAISE EXCEPTION 'FAIL ISS-04: active tenant membership should allow tenant-only context';
    END IF;
    RAISE NOTICE 'PASS ISS-04: tenant-level context accepted with unit_id NULL';

    -- ISS-05: disabled global identity cannot receive context.
    SELECT pg_catalog.count(*) INTO v_count
    FROM sinau_issuer_poc.validate_context_request(
        'SINAU-POC-DISABLED-ACTOR-SESSION-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001'
    );

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL ISS-05: disabled identity was accepted';
    END IF;
    RAISE NOTICE 'PASS ISS-05: disabled global identity rejected';

    -- ISS-06: revoked authentication session cannot receive context.
    SELECT pg_catalog.count(*) INTO v_count
    FROM sinau_issuer_poc.validate_context_request(
        'SINAU-POC-REVOKED-SESSION-A-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001'
    );

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL ISS-06: revoked session was accepted';
    END IF;
    RAISE NOTICE 'PASS ISS-06: revoked authentication session rejected';

    -- ISS-07: expired authentication session cannot receive context.
    SELECT pg_catalog.count(*) INTO v_count
    FROM sinau_issuer_poc.validate_context_request(
        'SINAU-POC-EXPIRED-SESSION-A-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001'
    );

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL ISS-07: expired session was accepted';
    END IF;
    RAISE NOTICE 'PASS ISS-07: expired authentication session rejected';

    -- ISS-08: not-yet-valid tenant membership is denied.
    SELECT pg_catalog.count(*) INTO v_count
    FROM sinau_issuer_poc.validate_context_request(
        'SINAU-POC-FUTURE-MEMBER-SESSION-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001'
    );

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL ISS-08: not-yet-valid tenant membership was accepted';
    END IF;
    RAISE NOTICE 'PASS ISS-08: not-yet-valid tenant membership rejected';

    -- ISS-09: expired unit membership is denied.
    SELECT pg_catalog.count(*) INTO v_count
    FROM sinau_issuer_poc.validate_context_request(
        'SINAU-POC-EXPIRED-UNIT-SESSION-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001'
    );

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL ISS-09: expired unit membership was accepted';
    END IF;
    RAISE NOTICE 'PASS ISS-09: expired unit membership rejected';

    -- ISS-10: suspended tenant membership is denied.
    SELECT pg_catalog.count(*) INTO v_count
    FROM sinau_issuer_poc.validate_context_request(
        'SINAU-POC-SUSPENDED-MEMBER-SESSION-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001'
    );

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL ISS-10: suspended tenant membership was accepted';
    END IF;
    RAISE NOTICE 'PASS ISS-10: suspended tenant membership rejected';

    -- ISS-11: expired tenant membership is denied.
    SELECT pg_catalog.count(*) INTO v_count
    FROM sinau_issuer_poc.validate_context_request(
        'SINAU-POC-EXPIRED-TENANT-MEMBER-SESSION-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001'
    );

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL ISS-11: expired tenant membership was accepted';
    END IF;
    RAISE NOTICE 'PASS ISS-11: expired tenant membership rejected';

    -- ISS-12: an inactive unit cannot receive operational context.
    SELECT pg_catalog.count(*) INTO v_count
    FROM sinau_issuer_poc.validate_context_request(
        'SINAU-POC-ACTIVE-SESSION-A-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000003'
    );

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL ISS-12: inactive unit was accepted';
    END IF;
    RAISE NOTICE 'PASS ISS-12: inactive unit rejected';

    -- ISS-13: a foreign unit ID cannot be paired with tenant A.
    SELECT pg_catalog.count(*) INTO v_count
    FROM sinau_issuer_poc.validate_context_request(
        'SINAU-POC-ACTIVE-SESSION-A-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000001',
        '20000000-0000-0000-0000-000000000001'
    );

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL ISS-13: unit belonging to another tenant was accepted';
    END IF;
    RAISE NOTICE 'PASS ISS-13: tenant/unit relationship mismatch rejected';

    -- ISS-14: context validity is separate from feature entitlement.
    IF NOT sinau_issuer_poc.has_feature_entitlement(
        '00000000-0000-0000-0000-000000000001',
        'poc.feature.active'
    ) THEN
        RAISE EXCEPTION 'FAIL ISS-14: active synthetic entitlement should be true';
    END IF;

    IF sinau_issuer_poc.has_feature_entitlement(
        '00000000-0000-0000-0000-000000000001',
        'poc.feature.expired'
    ) THEN
        RAISE EXCEPTION 'FAIL ISS-14: expired synthetic entitlement should be false';
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
    FROM sinau_issuer_poc.validate_context_request(
        'SINAU-POC-ACTIVE-SESSION-A-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001'
    );

    IF v_count <> 1 THEN
        RAISE EXCEPTION 'FAIL ISS-14: membership context was incorrectly coupled to feature entitlement';
    END IF;
    RAISE NOTICE 'PASS ISS-14: feature entitlement is evaluated separately from membership context';

    -- Unknown and empty session credentials fail closed.
    SELECT pg_catalog.count(*) INTO v_count
    FROM sinau_issuer_poc.validate_context_request(
        'not-a-known-session-credential',
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001'
    );

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL: unknown session credential was accepted';
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
    FROM sinau_issuer_poc.validate_context_request(
        '',
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001'
    );

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL: empty session credential was accepted';
    END IF;
    RAISE NOTICE 'PASS: unknown and empty session credentials fail closed';
END
$issuer_tests$;

-- The query role must not be able to call the issuer validator, read fixtures,
-- read the database key store, or mutate membership/session tables.
SET LOCAL ROLE sinau_rls_test;

DO $privilege_tests$
DECLARE
    v_argument_names pg_catalog.text[];
    v_validator_oid pg_catalog.oid;
    v_memberships_relation_oid pg_catalog.oid;
    v_keys_relation_oid pg_catalog.oid;
BEGIN
    -- Inspect the function through system catalogs. Resolve its OID without
    -- casting a qualified name to regprocedure, which would require USAGE
    -- on the private schema that this query role intentionally does not have.
    SELECT p.oid, p.proargnames[1:3]
      INTO v_validator_oid, v_argument_names
      FROM pg_catalog.pg_proc AS p
      JOIN pg_catalog.pg_namespace AS n
        ON n.oid = p.pronamespace
     WHERE n.nspname = 'sinau_issuer_poc'
       AND p.proname = 'validate_context_request'
       AND p.pronargs = 3
       AND p.proargtypes[0] = 'pg_catalog.text'::pg_catalog.regtype::pg_catalog.oid
       AND p.proargtypes[1] = 'pg_catalog.uuid'::pg_catalog.regtype::pg_catalog.oid
       AND p.proargtypes[2] = 'pg_catalog.uuid'::pg_catalog.regtype::pg_catalog.oid;

    IF v_validator_oid IS NULL THEN
        RAISE EXCEPTION 'FAIL: issuer validator catalog entry not found';
    END IF;

    -- The validator derives actor_id from the session bearer; no actor_id
    -- parameter is present that a caller could forge.
    IF v_argument_names IS DISTINCT FROM
       ARRAY['p_session_token', 'p_tenant_id', 'p_unit_id']::pg_catalog.text[] THEN
        RAISE EXCEPTION 'FAIL: issuer validator argument contract changed';
    END IF;

    IF pg_catalog.has_function_privilege(
        'sinau_rls_test',
        v_validator_oid,
        'EXECUTE'
    ) THEN
        RAISE EXCEPTION 'FAIL: RLS query role can execute the issuer validator';
    END IF;

    -- Resolve relation OIDs from catalogs so the tests do not need schema USAGE.
    SELECT c.oid
      INTO v_memberships_relation_oid
      FROM pg_catalog.pg_class AS c
      JOIN pg_catalog.pg_namespace AS n
        ON n.oid = c.relnamespace
     WHERE n.nspname = 'sinau_issuer_poc'
       AND c.relname = 'poc_tenant_memberships'
       AND c.relkind IN ('r', 'p');

    IF v_memberships_relation_oid IS NULL THEN
        RAISE EXCEPTION 'FAIL: membership fixture relation not found';
    END IF;

    SELECT c.oid
      INTO v_keys_relation_oid
      FROM pg_catalog.pg_class AS c
      JOIN pg_catalog.pg_namespace AS n
        ON n.oid = c.relnamespace
     WHERE n.nspname = 'sinau_private'
       AND c.relname = 'context_keys'
       AND c.relkind IN ('r', 'p');

    IF v_keys_relation_oid IS NULL THEN
        RAISE EXCEPTION 'FAIL: context key-store relation not found';
    END IF;

    IF pg_catalog.has_table_privilege(
        'sinau_rls_test',
        v_memberships_relation_oid,
        'SELECT'
    ) THEN
        RAISE EXCEPTION 'FAIL: RLS query role can read membership fixtures';
    END IF;

    IF pg_catalog.has_table_privilege(
        'sinau_rls_test',
        v_keys_relation_oid,
        'SELECT'
    ) THEN
        RAISE EXCEPTION 'FAIL: RLS query role can read the key store';
    END IF;

    IF pg_catalog.has_table_privilege(
        'sinau_rls_test',
        v_memberships_relation_oid,
        'INSERT,UPDATE,DELETE'
    ) THEN
        RAISE EXCEPTION 'FAIL: RLS query role can mutate membership fixtures';
    END IF;

    RAISE NOTICE 'PASS: RLS query role cannot issue context, read fixtures/key, or mutate memberships';
END
$privilege_tests$;

ROLLBACK;

\echo 'CONTEXT ISSUER VALIDATION TESTS PASSED — TRANSACTION ROLLED BACK'
