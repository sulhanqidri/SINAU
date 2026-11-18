# Rencana PoC Database dan Isolasi Tenant SINAU

**Status:** CI PostgreSQL 18.7 berhasil menjalankan schema/fixture dan tes constraint otomatis; benchmark skala, authorization aplikasi, RLS, backup/restore, dan tes lokal pengguna masih belum dilakukan  
**Tanggal:** 2026-11-18  
**Keputusan engine:** PostgreSQL 18 — [ADR-006](../09-decisions/ADR-006-POSTGRESQL-DATABASE.md)  
**Terkait:** ADR-002, ADR-003, ADR-005

## 1. Tujuan

Membuktikan bahwa desain shared database/shared schema SINAU menjaga integritas tenant/unit dan siap dioperasikan pada PostgreSQL 18 sebelum migration domain produksi dibuat. Keputusan engine PostgreSQL sudah disetujui; PoC ini memvalidasi desain skema, keamanan, kinerja awal, dan operasional — bukan membandingkan pilihan engine.

Schema dan fixture sintetis, tes constraint otomatis, Docker Compose lokal, runner shell, benchmark opsional satu juta baris, dan workflow CI tersedia di [poc/database-isolation/postgresql](../../poc/database-isolation/postgresql/schema-and-fixtures.sql). CI run #3 pada PostgreSQL 18.7 berhasil (setup schema/fixture dan verify-constraints). Hasil ini hanya membuktikan smoke test integritas relasional di CI; bukan kelulusan seluruh PoC. Hasil lokal pemilik proyek belum diterima.

Draft MySQL 8.4 yang masih berada di direktori PoC dipertahankan hanya sebagai artefak historis/rujukan dan bukan target pengujian atau implementasi MVP. Workflow CI PostgreSQL 18 menjalankan schema dan tes constraint saat perubahan PoC terkait masuk ke pull request.

## 2. Scope data sintetis

Buat fixture minimal:

- Tenant A: foundation dengan Unit A1 (sekolah umum), Unit A2 (madrasah), Unit A3 (SMK).
- Tenant B: independent_provider dengan Unit B1.
- User U1: tenant admin Tenant A, hanya memiliki unit membership A1.
- User U2: pengelola Unit A2.
- User U3: anggota Tenant B dan Unit B1.
- Record contoh pada tabel induk dan tabel unit-scoped.

Gunakan identifier sintetis yang jelas bukan data resmi.

## 3. Skema minimum yang diuji

### tenants
- id primary key.
- tenant_type.
- status.

### education_units
- id primary key.
- tenant_id not null.
- unit_code not null.
- UNIQUE (tenant_id, id).
- UNIQUE (tenant_id, unit_code).
- FK tenant_id → tenants.id.

### unit_scoped_records
- id primary key.
- tenant_id not null.
- unit_id not null.
- Composite FK (tenant_id, unit_id) → education_units(tenant_id, id).

### memberships
- Tenant membership dan unit membership dipisah.
- Unique constraint sesuai pasangan membership.
- Unit membership mengacu pada pasangan (tenant_id, unit_id) yang valid.

Pilih tipe data ID yang konsisten pada seluruh parent dan child. Semua FK harus eksplisit.

## 4. Skenario pengujian wajib

| ID | Skenario | Hasil yang diwajibkan |
|---|---|---|
| DB-01 | Insert unit dengan tenant yang valid | Berhasil |
| DB-02 | Insert unit dengan tenant yang tidak ada | Ditolak FK |
| DB-03 | Insert record dengan pasangan tenant/unit yang cocok | Berhasil |
| DB-04 | Insert record dengan tenant A + unit milik tenant B | Ditolak composite FK |
| DB-05 | Update record mengganti tenant_id tanpa mengganti unit_id yang sesuai | Ditolak |
| DB-06 | Duplikasi unit_code dalam tenant yang sama | Ditolak unique |
| DB-07 | Unit_code sama pada tenant berbeda | Diizinkan |
| DB-08 | Penghapusan tenant/unit yang masih direferensikan | Ditolak atau mengikuti kebijakan lifecycle eksplisit; tidak cascade menghapus data operasional |
| DB-09 | Transaksi pembuatan tenant/unit/membership gagal di tengah | Seluruh transaksi rollback |
| DB-10 | Dua request bersamaan menambah unit pada sisa entitlement satu | Maksimal satu yang berhasil |
| DB-11 | Query daftar unit dan data siswa dengan tenant/unit scope | Hanya mengembalikan data scope sah |
| DB-12 | Raw SQL tanpa filter scope | PoC harus membuktikan kontrol defense-in-depth yang dipilih; jangan menganggap ORM scope melindungi raw SQL |
| DB-13 | RLS PostgreSQL tanpa context atau dengan context tenant lain | Ditolak; reset context antar transaksi/connection diuji |
| DB-14 | Index dan query plan untuk pola tenant_id + unit_id | Index dipakai secara masuk akal pada dataset uji |
| DB-15 | Migration up/down dan restore backup | Dapat direproduksi dan hasil konsisten |

## 5. Skenario authorization aplikasi

- U1 dapat mengelola fungsi tenant-level yang diizinkan, tetapi tidak otomatis membaca data akademik A2/A3.
- U1 tidak dapat mengakses Unit B1 meskipun mengetahui ID-nya.
- U2 dapat mengakses A2 sesuai role dan permission.
- U3 hanya dapat mengakses Tenant B/Unit B1.
- Mengganti tenant_id/unit_id pada route, query string, body, header, atau identifier nested tidak memberi akses.
- Membership yang dicabut langsung menolak request berikutnya dan membatalkan context/cache yang relevan.
- Queue/job harus menolak scope yang tidak lagi valid saat dieksekusi.

## 6. Pengujian transaksi dan concurrency

Uji entitlement dengan dua koneksi/request yang benar-benar berjalan bersamaan. Locking atau mekanisme serialisasi harus memastikan kuota tidak terlampaui. Jangan hanya mengandalkan validasi UI atau pola read-then-insert tanpa proteksi concurrency.

Uji pembuatan tenant, unit, membership, dan audit dalam satu transaksi. Kegagalan pada setiap langkah harus menghasilkan rollback yang konsisten.

## 7. Kinerja dan operasional

Gunakan dataset sintetis bertingkat, misalnya 10 ribu, 100 ribu, dan 1 juta record unit-scoped (sesuaikan resource PoC). Ukur:

- Query daftar/pencarian/paginasi dengan filter tenant dan unit.
- Join siswa-enrollment-kelas pada scope unit.
- Laporan ringkas per unit dan lintas unit dalam satu tenant.
- Insert/import batch dan transaksi.
- Index size, query plan, lock contention, dan waktu migration.
- Backup, restore, dan prosedur export satu tenant.
- Uji partisi untuk histori berbasis waktu sebagai eksperimen terpisah bila dataset dan query membenarkannya; jangan mempartisi semua tabel secara otomatis.

Catat hardware, versi PostgreSQL 18, konfigurasi, ukuran dataset, warm/cold cache, serta metodologi. Jangan menyimpulkan kesiapan produksi hanya dari satu benchmark.

## 8. Kriteria lulus

PoC PostgreSQL dinyatakan lulus bila:

1. Semua tes integritas DB-01 sampai DB-10 lulus.
2. Semua tes authorization dan IDOR lulus.
3. Tidak ada jalur akses lintas tenant/unit yang hanya bergantung pada disiplin developer.
4. Concurrency tidak melampaui entitlement.
5. Backup/restore dapat diuji dan hasilnya diverifikasi.
6. Migration dan rollback/forward-fix dapat direproduksi.
7. Kinerja query memenuhi target awal yang disepakati dan bottleneck diketahui.
8. Keterbatasan PostgreSQL, ORM, dan operasional dicatat.

Satu saja bypass lintas tenant/unit adalah blocker, bukan sekadar temuan performa.

## 9. Menjalankan PoC lokal

Dari root repository dengan Docker Compose v2:

```bash
bash poc/database-isolation/postgresql/run-poc.sh
```

Untuk benchmark opsional satu juta baris sintetis:

```bash
RUN_BENCHMARK=1 bash poc/database-isolation/postgresql/run-poc.sh
```

Runner memakai PostgreSQL 18 disposable di port host 55432. Script schema menghapus dan membuat ulang schema `sinau_poc`; jangan mengarahkan koneksi ke database lain. Workflow `.github/workflows/postgresql-poc.yml` menjalankan setup dan tes constraint di CI.

## 10. Output PoC

- Script/schema PoC PostgreSQL 18 dan automated tests.
- Hasil eksekusi yang dapat direproduksi.
- Ringkasan performa dengan metodologi.
- Threat/risk notes.
- Rekomendasi konfigurasi PostgreSQL dan prosedur operasional.
- Checklist kesiapan migration produksi.

## 11. Larangan selama PoC

- Jangan membuat migration domain produksi.
- Jangan memakai data pribadi nyata.
- Jangan memakai database atau credential SQLRadius.
- Jangan menaruh secret di Git.
- Jangan memakai RLS sebagai pengganti authorization aplikasi.
- Jangan memakai ON DELETE CASCADE untuk menghapus histori akademik secara tidak sengaja.
