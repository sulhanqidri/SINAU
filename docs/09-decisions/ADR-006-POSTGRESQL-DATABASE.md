# ADR-006: Pemilihan PostgreSQL sebagai Database SINAU

- **Status:** Accepted — keputusan pemilik produk
- **Tanggal:** 2026-11-18
- **Area:** Database engine, tenancy, scalability
- **Terkait:** ADR-002, ADR-005, DATABASE-POC-PLAN.md

## Konteks

SINAU dirancang sebagai SaaS multi-tenant untuk yayasan dan sekolah/madrasah mandiri. Platform diproyeksikan mengelola data siswa, wali, guru, kelas, kehadiran, nilai, histori akademik, serta laporan dalam volume yang terus bertumbuh. Database perlu mendukung integritas relasional, transaksi bersamaan, query kompleks, pengindeksan, partisi tabel, backup/pemulihan, dan jalur scale-out.

## Keputusan

Pemilik produk menetapkan **PostgreSQL 18 sebagai database utama SINAU**.

- Target mayor: PostgreSQL 18.
- Versi minor: gunakan patch PostgreSQL 18 terbaru yang tersedia dan lolos validasi deployment saat implementasi; jangan mengunci patch lama tanpa alasan.
- MySQL 8.4 LTS tidak lagi menjadi kandidat database utama dan tidak perlu menjadi gerbang pembanding sebelum implementasi.
- Draft PoC MySQL boleh tetap disimpan sebagai artefak historis/rujukan, tetapi pengujian resmi dan pengembangan berikutnya berfokus pada PostgreSQL.
- Keputusan ini khusus untuk SINAU dan tidak mengubah sistem atau database SQLRadius.

## Baseline arsitektur database

1. Mulai dengan shared database/shared schema untuk MVP.
2. Semua tabel tenant-scoped membawa tenant_id; tabel unit-scoped membawa tenant_id dan unit_id.
3. Gunakan primary key, unique constraint, foreign key, dan composite foreign key untuk menjaga konsistensi pasangan tenant/unit.
4. Terapkan tenant context dan unit context tervalidasi di aplikasi; authorization default-deny dan membership tetap wajib.
5. Evaluasi PostgreSQL Row-Level Security (RLS) sebagai defense-in-depth. RLS tidak menggantikan authorization aplikasi, query scoping, atau pengujian akses.
6. Gunakan indeks sesuai pola query nyata. Partisi tabel besar (misalnya histori kehadiran atau audit berdasarkan waktu) hanya setelah volume, retensi, dan query plan membenarkannya.
7. Mulai dengan satu primary. Tambahkan connection pooling, read replica, analytical store, atau sharding berdasarkan metrik beban dan kebutuhan pemulihan, bukan asumsi sejak awal.
8. Rancang backup terjadwal, point-in-time recovery, restore drill, dan prosedur export/restore tenant.

## Validasi teknis yang tetap wajib

Keputusan engine sudah ditetapkan, tetapi desain skema dan kesiapan operasional tetap harus dibuktikan melalui PoC PostgreSQL sebelum migration domain produksi:

- Composite FK dan constraint scope tenant/unit.
- Transaksi serta concurrency entitlement.
- Tenant isolation pada ORM, query builder, raw SQL, job, file, cache, export, dan audit.
- RLS bila dipakai, termasuk reset context pada pooled connections/transactions.
- Index dan EXPLAIN/EXPLAIN ANALYZE pada dataset sintetis bertingkat.
- Migration, backup, point-in-time recovery, restore, dan prosedur pemulihan.
- Kinerja import, pencarian, paginasi, join akademik, dan laporan.

Satu bypass lintas tenant/unit adalah blocker. Jangan menggunakan data pribadi nyata dalam PoC.

## Konsekuensi

- Implementasi dan CI SINAU menggunakan PostgreSQL sebagai satu-satunya engine database target.
- Dokumentasi, schema PoC, dan konfigurasi lokal harus konsisten dengan PostgreSQL.
- Driver, SQL, migration, dan fitur database harus diuji terhadap PostgreSQL 18.
- Portabilitas lintas-engine bukan target MVP; abstraksi aplikasi tetap dijaga agar domain tidak bergantung secara tidak perlu pada detail vendor.
- Skala besar dicapai bertahap melalui desain query/index, pooling, partisi yang terukur, replica, dan bila diperlukan sharding.

## Gerbang sebelum migration produksi

PoC PostgreSQL memenuhi seluruh acceptance criteria integritas, authorization, concurrency, performa awal, serta backup/restore. Hasil uji dan konfigurasi lingkungan dicatat sebelum migration domain dibuat.
