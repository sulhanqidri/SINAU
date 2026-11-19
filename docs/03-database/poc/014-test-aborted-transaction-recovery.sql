-- SINAU PostgreSQL 18 Design PoC — aborted transaction recovery
-- Run ONLY in sinau_design_poc after scripts 005 and 007.
-- Open psql as administrator, then SET SESSION AUTHORIZATION sinau_poc.
-- This test intentionally raises division_by_zero (SQLSTATE 22012) inside a
-- transaction to model a statement exception. The expected error is detected
-- by psql; the transaction is rolled back before the same connection is reused.
-- No persistent objects or application rows are created or modified.

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

\echo '===== CONTROLLED SQL ERROR / ABORTED TRANSACTION ====='

BEGIN;

SELECT pg_catalog.set_config(
    'app.context_token',
    'poc-aborted-transaction-context-marker',
    true
) IS NOT NULL AS transaction_local_context_installed;

SET LOCAL ROLE sinau_rls_test;

DO $before_error$
DECLARE
    v_context pg_catalog.text;
    v_count pg_catalog.int8;
BEGIN
    IF current_user <> 'sinau_rls_test' THEN
        RAISE EXCEPTION 'FAIL: query role was not active before controlled SQL error';
    END IF;

    v_context := pg_catalog.current_setting('app.context_token', true);
    IF v_context IS DISTINCT FROM 'poc-aborted-transaction-context-marker' THEN
        RAISE EXCEPTION 'FAIL: transaction-local marker missing before controlled SQL error';
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
      FROM sinau_private.current_verified_context();

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL: invalid context marker produced verified claims';
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
      FROM public.academic_years;

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL: invalid marker exposed academic rows before controlled SQL error';
    END IF;

    RAISE NOTICE 'PASS: query role and invalid transaction-local marker are active before error';
END
$before_error$;

-- A statement-level SQL error aborts the current transaction. ON_ERROR_STOP is
-- disabled only for this one expected error so the script can inspect SQLSTATE,
-- issue ROLLBACK, and verify safe reuse of this same psql connection.
\set ON_ERROR_STOP off
SELECT 1 / 0;
\if :ERROR
    \echo 'PASS: expected SQL exception observed; SQLSTATE=' :SQLSTATE
\else
    \echo 'FAIL: controlled SQL exception did not occur'
    ROLLBACK;
    \quit 3
\endif
\set ON_ERROR_STOP on

-- The transaction is now aborted. ROLLBACK is mandatory before any further SQL.
ROLLBACK;

DO $after_error_rollback$
DECLARE
    v_context pg_catalog.text;
BEGIN
    IF session_user <> 'sinau_poc' OR current_user <> 'sinau_poc' THEN
        RAISE EXCEPTION 'FAIL: ROLLBACK did not restore sinau_poc after SQL error';
    END IF;

    v_context := pg_catalog.current_setting('app.context_token', true);
    IF v_context IS NOT NULL AND v_context <> '' THEN
        RAISE EXCEPTION 'FAIL: transaction-local context survived aborted transaction rollback';
    END IF;

    RAISE NOTICE 'PASS: ROLLBACK after SQL error restored sinau_poc and cleared context';
END
$after_error_rollback$;

\echo '===== REUSE SAME CONNECTION AFTER ABORT ====='

BEGIN;
SET LOCAL ROLE sinau_rls_test;

DO $same_connection_reuse$
DECLARE
    v_context pg_catalog.text;
    v_count pg_catalog.int8;
BEGIN
    IF current_user <> 'sinau_rls_test' THEN
        RAISE EXCEPTION 'FAIL: query role could not be selected after aborted transaction rollback';
    END IF;

    v_context := pg_catalog.current_setting('app.context_token', true);
    IF v_context IS NOT NULL AND v_context <> '' THEN
        RAISE EXCEPTION 'FAIL: old context leaked into the transaction after SQL error recovery';
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
      FROM sinau_private.current_verified_context();

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL: recovered transaction unexpectedly has verified context';
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
      FROM public.academic_years;

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL: recovered transaction exposed academic rows without context';
    END IF;

    RAISE NOTICE 'PASS: same connection reused after SQL error; no context and zero academic rows';
END
$same_connection_reuse$;

ROLLBACK;

DO $final_connection_state$
BEGIN
    IF session_user <> 'sinau_poc' OR current_user <> 'sinau_poc' THEN
        RAISE EXCEPTION 'FAIL: final ROLLBACK did not restore sinau_poc';
    END IF;

    IF pg_catalog.current_setting('app.context_token', true) IS NOT NULL
       AND pg_catalog.current_setting('app.context_token', true) <> '' THEN
        RAISE EXCEPTION 'FAIL: context remained after same-connection recovery test';
    END IF;

    RAISE NOTICE 'PASS: connection is clean and restored to sinau_poc';
END
$final_connection_state$;

\echo 'ABORTED TRANSACTION RECOVERY TESTS PASSED — SAME CONNECTION REUSED'
