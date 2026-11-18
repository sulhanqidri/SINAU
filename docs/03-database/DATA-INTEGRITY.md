# Integritas Data dan Scope

## Tenant/unit integrity
- Record tenant-scoped harus selalu mempunyai tenant_id tervalidasi.
- Record unit-scoped harus mempunyai unit_id dan tenant_id yang konsisten dengan education_units.tenant_id.
- Education unit berada di bawah tepat satu tenant aktif pada satu waktu.
- Tenant foundation maupun independent_provider menggunakan struktur education_units yang sama.
- Tenant mandiri tidak dipaksa memiliki parent foundation.
- Foreign key antar domain memastikan pasangan tenant/unit cocok, bukan hanya ID record cocok.
- Unique constraint memasukkan scope bila nilai hanya unik per tenant/unit.
- Tenant membership dan unit membership adalah grant terpisah; akses unit diperiksa eksplisit.
- Query builder, raw SQL, laporan, search, export, job, webhook, dan cache wajib membatasi scope eksplisit.
- Perubahan tenant_id pada unit tidak dilakukan melalui CRUD biasa; gunakan workflow transfer terotorisasi dan audit.

## Riwayat akademik
- Enrollment adalah histori; jangan menyimpan current_class sebagai satu-satunya sumber.
- Penugasan guru dan konfigurasi kurikulum memiliki periode berlaku.
- Nilai/rapor yang sudah disahkan tidak boleh berubah diam-diam.
- Koreksi membuat jejak perubahan dan alasan.

## Konsistensi operasional
- Gunakan transaksi database untuk perubahan multi-record yang atomik.
- Gunakan unique key/idempotency untuk mencegah presensi, impor, dan nilai ganda sesuai alur.
- Validasi konflik jadwal dan enrollment aktif.
- Operasi bulk harus punya preview, hasil per baris, dan mekanisme kegagalan yang jelas.

## Migrasi
- Migration diuji pada database kosong dan snapshot data sintetis representatif.
- Perubahan besar memakai pola expand/migrate/contract bila diperlukan.
- Hindari migration destruktif tanpa backup, rencana pemulihan, dan persetujuan.
