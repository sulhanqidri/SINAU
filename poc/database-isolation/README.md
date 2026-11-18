# Database Isolation PoC

Eksperimen database terpisah dari aplikasi produksi SINAU. Semua fixture bersifat sintetis. Script schema bersifat **destruktif** terhadap schema/database bernama sinau_poc; jalankan hanya pada instance/database disposable.

## Isi

- `postgresql/schema-and-fixtures.sql` — PostgreSQL 18.
- `mysql/schema-and-fixtures.sql` — MySQL 8.4 LTS, InnoDB.
- Hasil yang diharapkan dan negative test mengacu pada `docs/01-blueprint/DATABASE-POC-PLAN.md`.

## Menjalankan PostgreSQL

Jalankan dari database PoC kosong:

```bash
psql "$SINAU_POC_PG_DSN" -v ON_ERROR_STOP=1 -f poc/database-isolation/postgresql/schema-and-fixtures.sql
```

## Menjalankan MySQL

Gunakan server MySQL 8.4 LTS disposable:

```bash
mysql --show-warnings --default-character-set=utf8mb4 < poc/database-isolation/mysql/schema-and-fixtures.sql
```

## Hasil fixture yang diharapkan

- tenants: 2
- education_units: 3
- unit_scoped_records: 3
- unit_memberships: 3
- tenant_memberships: 3

## Negative tests manual

Setelah schema dan fixture berhasil dibuat, jalankan setiap pernyataan berikut secara terpisah. Setiap pernyataan harus gagal karena foreign key atau unique constraint; bila berhasil, PoC gagal.

1. Tenant A menunjuk unit milik Tenant B:

```sql
INSERT INTO sinau_poc.unit_scoped_records (tenant_id, unit_id, record_key)
VALUES (1, 201, 'invalid-cross-tenant');
```

2. Unit membership Tenant A menunjuk unit milik Tenant B:

```sql
INSERT INTO sinau_poc.unit_memberships (tenant_id, unit_id, user_id, status)
VALUES (1, 201, 1001, 'active');
```

3. Duplikasi kode unit di dalam tenant yang sama:

```sql
INSERT INTO sinau_poc.education_units (tenant_id, unit_code, name)
VALUES (1, 'A-SD', 'Duplicate unit');
```

4. Unit membership untuk user yang tidak memiliki tenant membership pada tenant tersebut:

```sql
INSERT INTO sinau_poc.unit_memberships (tenant_id, unit_id, user_id, status)
VALUES (1, 101, 2001, 'active');
```

5. Penghapusan tenant yang masih memiliki unit:

```sql
DELETE FROM sinau_poc.tenants WHERE id = 1;
```

Catat error code/message dan versi engine. Jangan menafsirkan kegagalan perintah karena alasan selain constraint yang dituju sebagai hasil lulus.

## Batasan saat ini

- Script hanya membuktikan sebagian integritas relasional.
- Belum menguji authorization Laravel, RLS, raw SQL aplikasi, concurrency entitlement, file, cache, queue, export, backup/restore, maupun performa.
- Belum ada hasil eksekusi; jangan menganggap PoC lulus hanya karena script sudah tersedia.
- Jangan gunakan kredensial, database, atau data SQLRadius.
