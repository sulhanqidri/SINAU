# Integritas Data dan Scope

## Tenant/unit integrity
- Record tenant-scoped harus selalu mempunyai tenant_id yang tervalidasi.
- Record unit-scoped harus mempunyai unit_id dan tenant_id yang konsisten.
- Foreign key antar domain harus memastikan pasangan tenant/unit cocok, bukan hanya ID record cocok.
- Unique constraint harus memasukkan scope bila nilai hanya unik per tenant/unit.
- Query builder, raw SQL, laporan, search, export, job, webhook, dan cache wajib membatasi scope eksplisit.

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
