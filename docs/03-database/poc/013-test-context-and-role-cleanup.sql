-- SINAU PostgreSQL 18 Design PoC — transaction-local context and role cleanup
-- Run ONLY in sinau_design_poc, after scripts 005, 007, and 010.
-- Open psql as administrator, then SET SESSION AUTHORIZATION sinau_poc.
-- This test uses intentionally invalid, non-secret context marker strings.
-- It creates no persistent objects and writes no application rows.
-- It exercises COMMIT and ROLLBACK cleanup on one PostgreSQL connection.

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

\echo '===== COMMIT PATH: CONTEXT AND ROLE CLEANUP ====='

BEGIN;

SELECT pg_catalog.set_config(
    'app.context_token',
    'poc-invalid-context-commit-marker',
    true
) IS NOT NULL AS transaction_local_context_installed;

SET LOCAL ROLE sinau_rls_test;

DO $commit_path_test$
DECLARE
    v_context pg_catalog.text;
    v_count pg_catalog.int8;
BEGIN
    IF current_user <> 'sinau_rls_test' THEN
        RAISE EXCEPTION 'FAIL: query role was not active inside COMMIT test';
    END IF;

    v_context := pg_catalog.current_setting('app.context_token', true);
    IF v_context IS DISTINCT FROM 'poc-invalid-context-commit-marker' THEN
        RAISE EXCEPTION 'FAIL: expected transaction-local marker before COMMIT';
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
      FROM sinau_private.current_verified_context();

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL: invalid context marker produced verified claims';
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
      FROM public.academic_years;

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL: invalid context marker exposed academic rows';
    END IF;

    RAISE NOTICE 'PASS: COMMIT path rejected invalid context and exposed zero academic rows';
END
$commit_path_test$;

COMMIT;

DO $after_commit_test$
DECLARE
    v_context pg_catalog.text;
BEGIN
    IF session_user <> 'sinau_poc' OR current_user <> 'sinau_poc' THEN
        RAISE EXCEPTION 'FAIL: SET LOCAL ROLE survived COMMIT';
    END IF;

    v_context := pg_catalog.current_setting('app.context_token', true);
    IF v_context IS NOT NULL AND v_context <> '' THEN
        RAISE EXCEPTION 'FAIL: app.context_token survived COMMIT';
    END IF;

    RAISE NOTICE 'PASS: COMMIT cleared transaction-local context and restored sinau_poc role';
END
$after_commit_test$;

\echo '===== ROLLBACK PATH: CONTEXT AND ROLE CLEANUP ====='

BEGIN;

SELECT pg_catalog.set_config(
    'app.context_token',
    'poc-invalid-context-rollback-marker',
    true
) IS NOT NULL AS transaction_local_context_installed;

SET LOCAL ROLE sinau_context_issuer_poc;
SET LOCAL ROLE sinau_rls_test;

DO $rollback_path_test$
DECLARE
    v_context pg_catalog.text;
    v_count pg_catalog.int8;
BEGIN
    IF current_user <> 'sinau_rls_test' THEN
        RAISE EXCEPTION 'FAIL: query role was not active inside ROLLBACK test';
    END IF;

    v_context := pg_catalog.current_setting('app.context_token', true);
    IF v_context IS DISTINCT FROM 'poc-invalid-context-rollback-marker' THEN
        RAISE EXCEPTION 'FAIL: expected transaction-local marker before ROLLBACK';
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
      FROM sinau_private.current_verified_context();

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL: invalid context marker produced verified claims';
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
      FROM public.academic_years;

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL: invalid context marker exposed academic rows';
    END IF;

    RAISE NOTICE 'PASS: ROLLBACK path rejected invalid context and exposed zero academic rows';
END
$rollback_path_test$;

ROLLBACK;

DO $after_rollback_test$
DECLARE
    v_context pg_catalog.text;
BEGIN
    IF session_user <> 'sinau_poc' OR current_user <> 'sinau_poc' THEN
        RAISE EXCEPTION 'FAIL: role switch survived ROLLBACK';
    END IF;

    v_context := pg_catalog.current_setting('app.context_token', true);
    IF v_context IS NOT NULL AND v_context <> '' THEN
        RAISE EXCEPTION 'FAIL: app.context_token survived ROLLBACK';
    END IF;

    RAISE NOTICE 'PASS: ROLLBACK cleared transaction-local context and restored sinau_poc role';
END
$after_rollback_test$;

\echo '===== FRESH TRANSACTION WITHOUT CONTEXT ====='

BEGIN;
SET LOCAL ROLE sinau_rls_test;

DO $fresh_transaction_test$
DECLARE
    v_context pg_catalog.text;
    v_count pg_catalog.int8;
BEGIN
    v_context := pg_catalog.current_setting('app.context_token', true);
    IF v_context IS NOT NULL AND v_context <> '' THEN
        RAISE EXCEPTION 'FAIL: old context marker leaked into a fresh transaction';
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
      FROM sinau_private.current_verified_context();

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL: fresh transaction received verified context without a token';
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
      FROM public.academic_years;

    IF v_count <> 0 THEN
        RAISE EXCEPTION 'FAIL: fresh transaction exposed academic rows without a context token';
    END IF;

    RAISE NOTICE 'PASS: fresh transaction has no context and sees zero academic rows';
END
$fresh_transaction_test$;

ROLLBACK;

DO $final_session_test$
BEGIN
    IF session_user <> 'sinau_poc' OR current_user <> 'sinau_poc' THEN
        RAISE EXCEPTION 'FAIL: final rollback did not restore sinau_poc';
    END IF;

    RAISE NOTICE 'PASS: connection returned to sinau_poc after all test transactions';
END
$final_session_test$;

\echo 'CONTEXT AND ROLE CLEANUP TESTS PASSED — COMMIT/ROLLBACK COMPLETE'
