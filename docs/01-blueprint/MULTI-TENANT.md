# Arsitektur Multi-Tenant SINAU

## Model konseptual

- **Platform:** operator penyedia SaaS SINAU.
- **Tenant:** pelanggan SINAU; dapat mewakili yayasan atau lembaga mandiri.
- **Unit pendidikan:** satu sekolah/madrasah dalam tenant.
- **User:** identitas akun yang dapat diberi akses ke satu atau beberapa tenant/unit sesuai penugasan.
- **Periode:** tahun ajaran, semester, dan periode operasional lain.

Relasi final harus mendukung tenant satu-unit dan multi-unit.

## Klasifikasi data

Setiap tabel/aggregate harus diklasifikasikan sebagai:
1. Platform-global.
2. Tenant-scoped.
3. School/unit-scoped.
4. User-scoped.
5. Reference/master data dengan aturan pemakaian dan versioning yang jelas.

Klasifikasi dicatat di data dictionary.

## Aturan isolasi

- Tenant context ditentukan dari sesi/token dan keanggotaan yang tervalidasi, bukan dipercaya dari input client.
- Setiap query dan operasi tulis membatasi ruang data dengan konteks yang benar.
- Foreign key/constraint atau strategi integritas lain mencegah relasi lintas tenant.
- Otorisasi mencakup tenant dan unit, bukan hanya role global.
- Global admin memiliki alur eksplisit, least privilege, dan audit.
- Ekspor, laporan, pencarian, unduhan berkas, API, queue, scheduler, webhook, dan cache mengikuti batas tenant.
- Cache key, file path, object key, dan job uniqueness harus mengandung scope yang tepat.
- Raw SQL dan query builder wajib menambahkan pembatasan scope secara eksplisit.
- Perpindahan konteks unit harus memvalidasi keanggotaan.

Global ORM scope saja tidak cukup sebagai jaminan keamanan.

## Pengujian wajib

- User tenant A tidak dapat membaca, membuat, mengubah, atau menghapus data tenant B.
- User unit A tidak dapat mengakses unit B tanpa izin.
- Manipulasi identifier tidak menghasilkan IDOR.
- Relasi data lintas tenant ditolak.
- API, ekspor, file, laporan, search, queue, dan webhook menguji scope.
- Cache tidak membocorkan data antar tenant.
- Background job gagal tertutup jika tenant context hilang atau tidak valid.

## Operasi dan audit

Catat pergantian tenant/unit, akses istimewa, ekspor, unduhan sensitif, perubahan role, serta tindakan administratif. Jangan mencatat secret atau payload pribadi secara berlebihan.

## Hal yang harus diputuskan sebelum migrasi awal

- Apakah tenant selalu yayasan/lembaga atau dapat langsung berupa sekolah.
- Apakah satu sekolah dapat dimiliki lebih dari satu badan pengelola.
- Aturan pemindahan unit antar tenant.
- Keanggotaan pengguna lintas tenant dan pemisahan akun.
- Strategi database dan constraint untuk tenant scoping.
