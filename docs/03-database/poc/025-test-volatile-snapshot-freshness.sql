-- SINAU PostgreSQL 18 Design PoC
-- Characterize MVCC snapshot visibility inside a VOLATILE SECURITY DEFINER
-- PL/pgSQL function under READ COMMITTED using two connections.
--
-- Connection A: run this script as PostgreSQL administrator.
-- Connection B: run the documented exact one-row account-state update after
-- observing the advisory lock acquired by Connection A.
--
-- This script creates one probe function inside its own transaction and
-- rolls the function back. It does not change fixture rows or persistent ACLs.
-- Connection B must commit the synthetic status change and later restore it.
-- Run ONLY against sinau_design_poc. Never use production databases.

\set ON_ERROR_STOP on
\pset pager off
\echo '===== SINAU POC — VOLATILE SPI SNAPSHOT FRESHNESS TEST (SESSION A) ====='

DO $guard$
DECLARE
    v_owner_oid pg_catalog.oid;
    v_actor_count pg_catalog.int8;
    v_lock_exists pg_catalog.bool;
BEGIN
    IF pg_catalog.current_database() <> 'sinau_design_poc'
       OR session_user <> 'postgres'
       OR current_user <> 'postgres'
       OR NOT EXISTS (
           SELECT 1
           FROM pg_catalog.pg_roles
           WHERE rolname = current_user
             AND rolsuper
       ) THEN
        RAISE EXCEPTION
            'SAFETY STOP: run only as PostgreSQL superuser postgres in sinau_design_poc';
    END IF;

    SELECT oid
      INTO v_owner_oid
      FROM pg_catalog.pg_roles
     WHERE rolname = 'sinau_context_owner'
       AND NOT rolcanlogin
       AND NOT rolsuper
       AND NOT rolbypassrls;

    IF v_owner_oid IS NULL THEN
        RAISE EXCEPTION
            'SAFETY STOP: sinau_context_owner must exist as NOLOGIN non-superuser without BYPASSRLS';
    END IF;

    SELECT pg_catalog.count(*)
      INTO v_actor_count
      FROM sinau_issuer_poc.poc_identities
     WHERE actor_id = '91000000-0000-0000-0000-000000000001'
       AND account_status = 'active';

    IF v_actor_count <> 1 THEN
        RAISE EXCEPTION
            'SAFETY STOP: expected exactly one active synthetic identity; found %',
            v_actor_count;
    END IF;

    IF pg_catalog.to_regprocedure(
        'sinau_private.poc_volatile_snapshot_probe()'
    ) IS NOT NULL THEN
        RAISE EXCEPTION
            'SAFETY STOP: snapshot probe function name already exists';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_locks
        WHERE locktype = 'advisory'
          AND classid = 42424::pg_catalog.oid
          AND objid = 52525::pg_catalog.oid
          AND objsubid = 2
          AND granted
    )
    INTO v_lock_exists;

    IF v_lock_exists THEN
        RAISE EXCEPTION
            'SAFETY STOP: selected advisory coordination key is already in use';
    END IF;
END
$guard$;

\echo '===== PRECONDITIONS PASS — START READ COMMITTED PROBE ====='

BEGIN ISOLATION LEVEL READ COMMITTED;

SET LOCAL ROLE sinau_context_owner;

CREATE FUNCTION sinau_private.poc_volatile_snapshot_probe()
RETURNS pg_catalog.text
LANGUAGE plpgsql
VOLATILE
PARALLEL UNSAFE
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $probe$
DECLARE
    v_before pg_catalog.text;
    v_after pg_catalog.text;
BEGIN
    SELECT i.account_status
      INTO STRICT v_before
      FROM sinau_issuer_poc.poc_identities AS i
     WHERE i.actor_id = '91000000-0000-0000-0000-000000000001';

    -- Signal to Connection B that the first SELECT has completed.
    -- The xact lock is automatically released when Connection A rolls back.
    PERFORM pg_catalog.pg_advisory_xact_lock(42424, 52525);

    -- Connection B must observe this lock, update the one synthetic identity,
    -- and COMMIT while this function is sleeping.
    PERFORM pg_catalog.pg_sleep(60::pg_catalog.float8);

    -- This is a second internal SPI SELECT in the same top-level SELECT call.
    -- VOLATILE PL/pgSQL should obtain a fresh READ COMMITTED snapshot here.
    SELECT i.account_status
      INTO STRICT v_after
      FROM sinau_issuer_poc.poc_identities AS i
     WHERE i.actor_id = '91000000-0000-0000-0000-000000000001';

    RETURN v_before || '|' || v_after;
END
$probe$;

RESET ROLE;

\echo '===== PROBE RUNNING ====='
\echo 'Connection A has started the VOLATILE probe. In terminal B, run the section 28 coordination/update instructions in README.'
\echo 'The test waits 60 seconds after the first internal SELECT to allow Connection B to commit.'
\echo 'Do not interrupt Session A until the result and ROLLBACK appear.'

DO $assert$
DECLARE
    v_result pg_catalog.text;
BEGIN
    SELECT sinau_private.poc_volatile_snapshot_probe()
      INTO STRICT v_result;

    RAISE NOTICE 'VOLATILE SPI status sequence: %', v_result;

    IF v_result <> 'active|disabled' THEN
        RAISE EXCEPTION
            'FAIL: expected active|disabled (Connection B commit visible to second internal SELECT), observed %',
            v_result;
    END IF;

    RAISE NOTICE
        'PASS: VOLATILE internal SELECT after the concurrent COMMIT observed the new READ COMMITTED state';
END
$assert$;

ROLLBACK;

\echo '===== SESSION A ROLLED BACK — TEMPORARY PROBE FUNCTION REMOVED ====='
\echo 'Connection B must now restore the synthetic account_status to active and verify exactly one row.'
