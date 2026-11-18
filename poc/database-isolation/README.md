# Database Isolation PoC

Eksperimen database yang terpisah dari aplikasi produksi SINAU. Seluruh fixture bersifat sintetis. Script schema bersifat **destruktif** terhadap schema bernama `sinau_poc`; jalankan hanya pada instance/database disposable.

## Isi

- `postgresql/schema-and-fixtures.sql` — schema dan fixture PostgreSQL 18.
- `postgresql/verify-constraints.sql` — tes otomatis FK, composite FK, unique constraint, tenant membership, delete restriction, dan rollback.
- `postgresql/benchmark-million.sql` — benchmark opsional 1 juta baris sintetis.
- `postgresql/compose.yaml` — PostgreSQL lokal disposable, port host 55432.
- `postgresql/run-poc.sh` — menjalankan setup dan tes dasar.
- `mysql/schema-and-fixtures.sql` — artefak historis, bukan target pengembangan MVP.

## Menjalankan lokal dengan Docker

Prasyarat: Docker Engine/Desktop dan Docker Compose v2.

Dari root repository:

```bash
bash poc/database-isolation/postgresql/run-poc.sh
```

Script akan menjalankan PostgreSQL 18 pada `127.0.0.1:55432`, membuat schema `sinau_poc`, memasukkan fixture sintetis, lalu menjalankan tes constraint otomatis.

Untuk menjalankan benchmark tambahan 1 juta baris:

```bash
RUN_BENCHMARK=1 bash poc/database-isolation/postgresql/run-poc.sh
```

Benchmark menambah satu juta record sintetis ke schema PoC. Jalankan hanya setelah setup dasar pada database disposable. Hasil `EXPLAIN ANALYZE` akan dicetak ke terminal; catat CPU, RAM, versi Docker, dan hasil query plan saat membandingkan eksperimen.

Untuk menghentikan dan menghapus container PoC:

```bash
docker compose -f poc/database-isolation/postgresql/compose.yaml down
```

Tidak ada volume persisten yang dikonfigurasi. Jangan mengubah nama database/schema/credential script untuk menunjuk ke database lain. Credential pada compose hanya untuk eksperimen lokal dan tidak boleh dipakai di luar lingkungan disposable.

## Menjalankan di PostgreSQL yang sudah tersedia

Pastikan DSN menunjuk ke database disposable yang memang disiapkan untuk PoC. Script schema akan menghapus dan membuat ulang schema `sinau_poc`.

```bash
psql "$SINAU_POC_PG_DSN" -X -v ON_ERROR_STOP=1 -f poc/database-isolation/postgresql/schema-and-fixtures.sql
psql "$SINAU_POC_PG_DSN" -X -v ON_ERROR_STOP=1 -f poc/database-isolation/postgresql/verify-constraints.sql
```

## CI

Workflow `.github/workflows/postgresql-poc.yml` menjalankan setup dan tes constraint otomatis pada service PostgreSQL 18 setiap ada perubahan PoC terkait di pull request, serta dapat dijalankan manual.

## Hasil fixture yang diharapkan

Setelah schema/fixture dibuat (sebelum tes):

- tenants: 2
- education_units: 4
- unit_scoped_records: 4
- unit_memberships: 3
- tenant_memberships: 3

Tes verifikasi menambahkan satu unit tambahan untuk membuktikan kode unit yang sama boleh digunakan tenant berbeda.

## Batasan yang belum dibuktikan

- Tes otomatis saat ini membuktikan sebagian integritas relasional, bukan keseluruhan keamanan aplikasi.
- Belum menguji authorization Laravel, RLS, raw SQL aplikasi, concurrency entitlement, file, cache, queue, export, backup/PITR/restore, maupun target SLA performa produksi.
- Benchmark 1 juta baris adalah baseline awal, bukan bukti kesiapan produksi.
- Belum ada hasil eksekusi lokal dari pemilik proyek. CI akan memberi bukti eksekusi saat workflow berhasil.
- Jangan gunakan credential, database, atau data SQLRadius.
