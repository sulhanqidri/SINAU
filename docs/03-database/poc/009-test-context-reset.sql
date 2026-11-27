-- SINAU PostgreSQL 18 Design PoC — transaction-local context reset
-- Run in the SAME psql connection, after ROLLBACK of 008's outer transaction.
-- Session authorization should remain sinau_poc. This opens a fresh transaction
-- with no newly signed token and checks that the prior transaction's local
-- app.context_token does not survive rollback/connection reuse.
--
-- This is a same-session transaction reset check, not a full external pooler
-- integration test. Target: sinau_design_poc only.

\set ON_ERROR_STOP on

\echo '===== TRANSACTION-LOCAL CONTEXT RESET TEST ====='

BEGIN;

SET LOCAL ROLE sinau_rls_test;

DO $reset_test$
DECLARE
    v_context pg_catalog.text;
    v_count pg_catalog.int8;
BEGIN
    v_context := pg_catalog.current_setting('app.context_token', true);

    IF v_context IS NOT NULL AND v_context <> '' THEN
        RAISE EXCEPTION
            'FAIL: app.context_token survived the prior transaction boundary';
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
    FROM public.academic_years;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'FAIL: expected zero visible academic years without a context token; got %',
            v_count;
    END IF;

    RAISE NOTICE 'PASS: transaction-local signed token was reset';
    RAISE NOTICE 'PASS: new transaction has no tenant data without a token';
END
$reset_test$;

\echo 'CONTEXT RESET ASSERTIONS PASSED'
\echo 'IMPORTANT: caller must ROLLBACK this verification transaction.'
