-- SINAU PostgreSQL 18 Design PoC — RLS isolation tests
-- Run as sinau_poc against sinau_design_poc after 003-rls-setup.sql.
-- All test writes are rolled back. This tests policy behavior when the
-- application context variables are trusted; it does NOT prove callers
-- cannot forge those variables.

\set ON_ERROR_STOP on
BEGIN;
SET LOCAL ROLE sinau_rls_test;
SELECT set_config('app.tenant_id','00000000-0000-0000-0000-000000000001',true);
SELECT set_config('app.unit_id','10000000-0000-0000-0000-000000000001',true);

DO $$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM academic_years;
  IF n <> 1 THEN
    RAISE EXCEPTION 'FAIL: tenant A/unit A1 should see 1 academic year; got %', n;
  END IF;
  RAISE NOTICE 'PASS: unit A1 sees only its own academic year';

  SELECT count(*) INTO n FROM academic_years
  WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
    AND unit_id = '10000000-0000-0000-0000-000000000002';
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL: cross-unit row visible'; END IF;
  RAISE NOTICE 'PASS: unit A1 cannot read unit A2 row';

  SELECT count(*) INTO n FROM academic_years
  WHERE tenant_id = '00000000-0000-0000-0000-000000000002';
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL: cross-tenant row visible'; END IF;
  RAISE NOTICE 'PASS: tenant A cannot read tenant B row';

  UPDATE academic_years
    SET ends_on = '2027-06-29'
    WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
      AND unit_id = '10000000-0000-0000-0000-000000000002';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL: cross-unit UPDATE affected % rows', n; END IF;
  RAISE NOTICE 'PASS: cross-unit UPDATE affects zero rows';

  DELETE FROM academic_years
    WHERE tenant_id = '00000000-0000-0000-0000-000000000002';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL: cross-tenant DELETE affected % rows', n; END IF;
  RAISE NOTICE 'PASS: cross-tenant DELETE affects zero rows';
END $$;

-- Valid write in the active tenant/unit must succeed.
INSERT INTO academic_years
  (tenant_id, unit_id, id, starts_on, ends_on)
VALUES
  ('00000000-0000-0000-0000-000000000001',
   '10000000-0000-0000-0000-000000000001',
   '30000000-0000-0000-0000-000000000011',
   '2027-07-01','2028-06-30');
\echo PASS: same-tenant/same-unit INSERT accepted

-- A forged tenant context must fail WITH CHECK under the active RLS policy.
DO $$
BEGIN
  BEGIN
    INSERT INTO academic_years
      (tenant_id, unit_id, id, starts_on, ends_on)
    VALUES
      ('00000000-0000-0000-0000-000000000002',
       '20000000-0000-0000-0000-000000000001',
       '30000000-0000-0000-0000-000000000012',
       '2027-07-01','2028-06-30');
    RAISE EXCEPTION 'FAIL: cross-tenant INSERT was accepted';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'PASS: cross-tenant INSERT rejected by RLS WITH CHECK';
  END;
END $$;

-- Changing the session context to another unit is possible for this test
-- role, demonstrating why trusted context-setting must be designed separately.
SELECT set_config('app.unit_id','10000000-0000-0000-0000-000000000002',true);
DO $$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM academic_years;
  IF n <> 1 THEN
    RAISE EXCEPTION 'FAIL: switching to unit A2 context should show 1 row; got %', n;
  END IF;
  RAISE NOTICE 'PASS: policy follows the supplied unit context';
END $$;

ROLLBACK;
\echo RLS TESTS FINISHED — transaction rolled back
