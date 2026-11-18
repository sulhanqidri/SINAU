# ADR-002: Strategi Isolasi Database Tenant

- **Status:** Proposed baseline untuk MVP; menunggu PoC engine database sebelum migration.
- **Tanggal:** 2026-11-18
- **Area:** Database tenancy, isolation, scalability

## Konteks

SINAU melayani tenant yayasan multi-unit dan sekolah/madrasah mandiri. Arsitektur perlu mencegah kebocoran lintas tenant, tetap sederhana untuk operasi MVP, serta menyediakan jalur scale-out tanpa mengubah model pelanggan.

## Opsi

### A. Shared database, shared schema
Semua tenant memakai tabel yang sama. Setiap tabel tenant/unit-scoped membawa scope key dan semua query menerapkan scope. Constraint database mengikat relasi dalam scope yang sama.

Kelebihan: biaya dan operasi awal lebih rendah, migrasi/backup terpusat, laporan lintas unit dalam satu yayasan lebih sederhana. Kekurangan: satu bug query dapat berdampak lintas tenant; noisy-neighbor; restore satu tenant lebih kompleks.

### B. Database terpisah per tenant
Setiap tenant memiliki database sendiri.

Kelebihan: isolasi fisik lebih kuat, restore dan pemindahan tenant lebih terarah. Kekurangan: migrasi, koneksi, monitoring, backup, dan query lintas unit bertambah kompleks sejak awal; biaya operasional lebih tinggi.

### C. Hybrid / shard
Tenant ditempatkan pada kelompok database atau database khusus berdasarkan kebutuhan.

Kelebihan: jalur pertumbuhan dan isolasi fleksibel. Kekurangan: membutuhkan tenant routing, provisioning, migration orchestration, serta observability yang matang.

## Baseline yang direkomendasikan

Untuk MVP, gunakan **shared database dan shared schema** dengan defense-in-depth:
1. tenant_id pada seluruh data tenant-scoped.
2. tenant_id + unit_id pada seluruh data unit-scoped, atau relasi terkontrol yang membuktikan tenant pemilik unit.
3. Composite unique key dan composite foreign key untuk menjaga pasangan scope.
4. Semua akses melalui repository/query service/use case yang menerima tenant context tervalidasi.
5. Authorization policy memeriksa membership, scope, status, dan permission.
6. Database role aplikasi tidak menggunakan akses superuser; kredensial migrasi dipisahkan dari runtime bila infrastruktur memungkinkan.
7. Test suite negatif lintas tenant/unit menjadi gerbang CI.
8. File, cache, queue, search, export, dan audit menggunakan scope key yang konsisten.

Strategi ini adalah baseline arsitektur, bukan keputusan engine database. PostgreSQL dan MySQL/MariaDB tetap dibandingkan melalui PoC. Row-Level Security dapat dievaluasi jika PostgreSQL dipilih, tetapi tidak menjadi satu-satunya lapisan keamanan dan tidak boleh diasumsikan tersedia pada semua engine.

## Jalur evolusi

Rancang tenant resolver agar dapat berkembang dari satu koneksi ke tenant-to-database mapping. Jangan menyimpan asumsi bahwa semua tenant selamanya berada pada satu database. Sharding/database-per-tenant baru diaktifkan berdasarkan kebutuhan terukur: ukuran tenant, SLA restore, residency/compliance, noisy-neighbor, atau biaya operasional.

## Konsekuensi dan risiko

- Shared schema menuntut disiplin query scope yang tinggi; satu query tanpa filter dapat menjadi insiden serius.
- Backup global tidak otomatis memenuhi kebutuhan restore satu tenant. Prosedur export/restore tenant perlu dirancang dan diuji.
- Query analitik lintas tenant harus dibatasi pada jalur platform yang terotorisasi dan diaudit.
- Tidak boleh ada tenant_id yang dipercaya langsung dari request.
- Jangan mengklaim isolasi fisik antar tenant pada model shared schema.

## Gerbang sebelum migration

- PoC engine database membuktikan composite FK/check constraint yang dibutuhkan.
- Uji query planner dan indeks pada pola filter tenant_id/unit_id.
- Uji tenant isolation untuk ORM, query builder, raw SQL, queue, file, export, dan cache.
- Uji backup/restore dan prosedur pemulihan.
- Threat model serta keputusan final engine database disetujui.

## Kriteria evaluasi ulang

Evaluasi database-per-tenant atau sharding saat ada kebutuhan isolasi fisik/kontrak, tenant besar yang mengganggu tenant lain, kebutuhan restore mandiri, kewajiban lokasi data, atau batas kapasitas database bersama.
