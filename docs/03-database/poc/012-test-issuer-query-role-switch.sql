-- SINAU PostgreSQL 18 Design PoC — role switching and transaction continuity
-- Run ONLY in sinau_design_poc, after scripts 005, 007, and 010.
-- Open psql as administrator, then SET SESSION AUTHORIZATION sinau_poc.
-- This test creates no persistent objects and writes no application rows.
-- It verifies role switching and XID/local-GUC continuity in one transaction.
-- Final ROLLBACK is part of the test.

\set ON_ERROR_STOP on

DO $database_guard$
BEGIN
    IF pg_catalog.current_database() <> 'sinau_design_poc' THEN
        RAISE EXCEPTION
            'REFUSING TO RUN: expected sinau_design_poc, got %',
            pg_catalog.current_database();
    END IF;

    IF session_user <> 'sinau_poc' OR current_user <> 'sinau_poc' THEN
        RAISE EXCEPTION
            'REFUSING TO RUN: expected session/current user sinau_poc, got %/%',
            session_user, current_user;
    END IF;
END
$database_guard$;

\echo '===== SAME-CONNECTION ROLE SWITCH / XID TEST ====='

BEGIN;

-- Allocate exactly one top-level XID and record it in transaction-local state.
SELECT pg_catalog.set_config(
    'app.poc_role_switch_xid',
    pg_catalog.pg_current_xact_id()::pg_catalog.text,
    true
) AS xid_recorded;

SET LOCAL ROLE sinau_context_issuer_poc;

DO $issuer_role_test$
DECLARE
    v_xid pg_catalog.text;
    v_validator_oid pg_catalog.oid;
    v_memberships_oid pg_catalog.oid;
BEGIN
    IF current_user <> 'sinau_context_issuer_poc' THEN
        RAISE EXCEPTION 'FAIL: issuer role switch did not take effect';
    END IF;

    v_xid := pg_catalog.current_setting('app.poc_role_switch_xid', true);
    IF v_xid IS NULL
       OR v_xid <> pg_catalog.pg_current_xact_id_if_assigned()::pg_catalog.text THEN
        RAISE EXCEPTION 'FAIL: XID or transaction-local state changed after issuer role switch';
    END IF;

    SELECT p.oid
      INTO v_validator_oid
      FROM pg_catalog.pg_proc AS p
      JOIN pg_catalog.pg_namespace AS n ON n.oid = p.pronamespace
     WHERE n.nspname = 'sinau_issuer_poc'
       AND p.proname = 'validate_context_request'
       AND p.pronargs = 3
       AND p.proargtypes[0] = 'pg_catalog.text'::pg_catalog.regtype::pg_catalog.oid
       AND p.proargtypes[1] = 'pg_catalog.uuid'::pg_catalog.regtype::pg_catalog.oid
       AND p.proargtypes[2] = 'pg_catalog.uuid'::pg_catalog.regtype::pg_catalog.oid;

    IF v_validator_oid IS NULL
       OR NOT pg_catalog.has_function_privilege(current_user, v_validator_oid, 'EXECUTE') THEN
        RAISE EXCEPTION 'FAIL: issuer role cannot execute the narrow membership validator';
    END IF;

    SELECT c.oid
      INTO v_memberships_oid
      FROM pg_catalog.pg_class AS c
      JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
     WHERE n.nspname = 'sinau_issuer_poc'
       AND c.relname = 'poc_tenant_memberships'
       AND c.relkind IN ('r', 'p');

    IF v_memberships_oid IS NULL
       OR pg_catalog.has_table_privilege(current_user, v_memberships_oid, 'SELECT') THEN
        RAISE EXCEPTION 'FAIL: issuer role has direct membership table access or fixture is missing';
    END IF;

    RAISE NOTICE 'PASS: issuer role active; XID unchanged; validator EXECUTE only, no direct membership SELECT';
END
$issuer_role_test$;

SET LOCAL ROLE sinau_rls_test;

DO $query_role_test$
DECLARE
    v_xid pg_catalog.text;
    v_validator_oid pg_catalog.oid;
    v_accessor_oid pg_catalog.oid;
    v_memberships_oid pg_catalog.oid;
    v_keys_oid pg_catalog.oid;
BEGIN
    IF current_user <> 'sinau_rls_test' THEN
        RAISE EXCEPTION 'FAIL: query role switch did not take effect';
    END IF;

    v_xid := pg_catalog.current_setting('app.poc_role_switch_xid', true);
    IF v_xid IS NULL
       OR v_xid <> pg_catalog.pg_current_xact_id_if_assigned()::pg_catalog.text THEN
        RAISE EXCEPTION 'FAIL: XID or transaction-local state changed after query role switch';
    END IF;

    SELECT p.oid
      INTO v_validator_oid
      FROM pg_catalog.pg_proc AS p
      JOIN pg_catalog.pg_namespace AS n ON n.oid = p.pronamespace
     WHERE n.nspname = 'sinau_issuer_poc'
       AND p.proname = 'validate_context_request'
       AND p.pronargs = 3
       AND p.proargtypes[0] = 'pg_catalog.text'::pg_catalog.regtype::pg_catalog.oid
       AND p.proargtypes[1] = 'pg_catalog.uuid'::pg_catalog.regtype::pg_catalog.oid
       AND p.proargtypes[2] = 'pg_catalog.uuid'::pg_catalog.regtype::pg_catalog.oid;

    SELECT p.oid
      INTO v_accessor_oid
      FROM pg_catalog.pg_proc AS p
      JOIN pg_catalog.pg_namespace AS n ON n.oid = p.pronamespace
     WHERE n.nspname = 'sinau_private'
       AND p.proname = 'current_verified_context'
       AND p.pronargs = 0;

    SELECT c.oid
      INTO v_memberships_oid
      FROM pg_catalog.pg_class AS c
      JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
     WHERE n.nspname = 'sinau_issuer_poc'
       AND c.relname = 'poc_tenant_memberships'
       AND c.relkind IN ('r', 'p');

    SELECT c.oid
      INTO v_keys_oid
      FROM pg_catalog.pg_class AS c
      JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
     WHERE n.nspname = 'sinau_private'
       AND c.relname = 'context_keys'
       AND c.relkind IN ('r', 'p');

    IF v_validator_oid IS NULL
       OR pg_catalog.has_function_privilege(current_user, v_validator_oid, 'EXECUTE') THEN
        RAISE EXCEPTION 'FAIL: query role can execute issuer validator or validator is missing';
    END IF;

    IF v_accessor_oid IS NULL
       OR NOT pg_catalog.has_function_privilege(current_user, v_accessor_oid, 'EXECUTE') THEN
        RAISE EXCEPTION 'FAIL: query role cannot execute verified-context accessor';
    END IF;

    IF v_memberships_oid IS NULL
       OR pg_catalog.has_table_privilege(current_user, v_memberships_oid, 'SELECT') THEN
        RAISE EXCEPTION 'FAIL: query role can read membership fixtures or fixture is missing';
    END IF;

    IF v_keys_oid IS NULL
       OR pg_catalog.has_table_privilege(current_user, v_keys_oid, 'SELECT') THEN
        RAISE EXCEPTION 'FAIL: query role can read signing keys or key store is missing';
    END IF;

    RAISE NOTICE 'PASS: query role active; same XID retained; accessor allowed; issuer/key/membership access denied';
END
$query_role_test$;

-- Switch back to the issuer role without starting a new transaction.
SET LOCAL ROLE sinau_context_issuer_poc;

DO $return_role_test$
BEGIN
    IF current_user <> 'sinau_context_issuer_poc' THEN
        RAISE EXCEPTION 'FAIL: switching back to issuer role failed';
    END IF;

    IF pg_catalog.current_setting('app.poc_role_switch_xid', true)
       IS DISTINCT FROM pg_catalog.pg_current_xact_id_if_assigned()::pg_catalog.text THEN
        RAISE EXCEPTION 'FAIL: XID changed when switching back to issuer role';
    END IF;

    RAISE NOTICE 'PASS: issuer/query/issuer role sequence retained one top-level XID';
END
$return_role_test$;

ROLLBACK;

DO $post_rollback_test$
DECLARE
    v_probe pg_catalog.text;
BEGIN
    IF session_user <> 'sinau_poc' OR current_user <> 'sinau_poc' THEN
        RAISE EXCEPTION 'FAIL: session authorization/current role was not restored after ROLLBACK';
    END IF;

    v_probe := pg_catalog.current_setting('app.poc_role_switch_xid', true);
    IF v_probe IS NOT NULL AND v_probe <> '' THEN
        RAISE EXCEPTION 'FAIL: transaction-local role-switch probe survived ROLLBACK';
    END IF;

    RAISE NOTICE 'PASS: ROLLBACK restored session role and cleared transaction-local probe';
END
$post_rollback_test$;

\echo 'ROLE SWITCH / XID CONTINUITY TESTS PASSED — TRANSACTION ROLLED BACK'
