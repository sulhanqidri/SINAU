-- Optional synthetic scale test. Run only on a disposable PoC database.
-- Adds 1,000,000 synthetic rows to Tenant 1 / Unit 101.
SET search_path TO sinau_poc;

INSERT INTO unit_scoped_records (tenant_id, unit_id, record_key, payload)
SELECT
    1,
    101,
    'bench-' || lpad(g::text, 7, '0'),
    'synthetic benchmark payload'
FROM generate_series(1, 1000000) AS g;

ANALYZE unit_scoped_records;

-- Record execution time, buffers, and plan. Inspect index usage and row estimates.
EXPLAIN (ANALYZE, BUFFERS, WAL, SUMMARY)
SELECT id, record_key
FROM unit_scoped_records
WHERE tenant_id = 1 AND unit_id = 101
ORDER BY id DESC
LIMIT 50;

EXPLAIN (ANALYZE, BUFFERS, SUMMARY)
SELECT COUNT(*)
FROM unit_scoped_records
WHERE tenant_id = 1 AND unit_id = 101;
