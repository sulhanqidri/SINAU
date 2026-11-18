# Arsitektur Multi-Tenant SINAU

**Status:** Keputusan model pelanggan dikonfirmasi. Rancangan ini menjadi baseline arsitektur; detail teknis database tetap harus diuji sebelum migration.

## Keputusan model pelanggan

SINAU mendukung dua tipe tenant:
1. **Yayasan / badan penyelenggara** (foundation): satu tenant dapat menaungi beberapa unit pendidikan, termasuk kombinasi sekolah umum dan madrasah.
2. **Sekolah/madrasah mandiri** (independent_provider): sekolah atau madrasah menjadi pelanggan langsung tanpa diwajibkan memiliki yayasan.

Tenant adalah batas kontrak SaaS, billing, konfigurasi pelanggan, dan isolasi data. Education unit adalah batas operasional pendidikan. Tipe tenant menjelaskan bentuk pelanggan, bukan jenis atau jenjang pendidikan.

Kedua tipe memakai model data, modul akademik, keamanan, dan proses operasional yang sama. Tidak dibuat cabang aplikasi terpisah.

## Model konseptual

- Platform: operator penyedia SaaS SINAU.
- Tenant: pelanggan SaaS bertipe foundation atau independent_provider.
- Education unit: satu sekolah/madrasah dengan identitas resmi, jenis, jenjang, alamat, status, dan konfigurasi sendiri.
- User: identitas akun global yang dapat memiliki membership pada beberapa tenant dan unit.
- Tenant membership: hubungan user dengan tenant beserta peran tenant.
- Unit membership: akses user ke unit tertentu beserta peran/permission unit.
- Academic period: tahun ajaran, semester, dan periode operasional milik unit.

Relasi utama: platform 1:N tenants; tenant 1:N education_units. Yayasan lazimnya memiliki banyak unit. Tenant mandiri lazimnya dimulai dengan satu unit. Model tidak mengharuskan semua pelanggan menjadi yayasan.

## Struktur dan lifecycle

- Setiap education unit berada di bawah tepat satu tenant aktif pada satu waktu.
- Satu tenant dapat memiliki satu atau banyak education unit.
- Tenant mandiri dibuat bersama unit pendidikan pertamanya; onboarding tidak meminta yayasan.
- Tenant yayasan dapat menambahkan unit bertahap. Unit dapat berbeda jenis/jenjang: SD, MI, SMP, MTs, SMA, SMK, MA, MAK, dan perluasan yang disetujui.
- Unit bukan sekadar cabang UI: identitas, data akademik, periode, kurikulum, pengguna, laporan, dan konfigurasi operasionalnya memiliki scope sendiri.
- Perpindahan unit ke tenant lain bukan update tenant_id biasa. Wajib melalui workflow transfer dengan otorisasi platform, pemeriksaan kontrak/konflik, audit, serta kebijakan histori dan retensi.
- Penutupan tenant/unit mengikuti lifecycle dan retensi; tidak menghapus histori akademik otomatis.
- Tenant type tidak menentukan education type/level. Jenis dan jenjang melekat pada education unit.

## Scope data dan otorisasi

Setiap tabel/aggregate diklasifikasikan sebagai platform-global, tenant-scoped, unit-scoped, user-scoped, atau reference/master data dengan aturan versioning.

- Tenant context berasal dari sesi/token dan membership tervalidasi, bukan input client.
- Unit context harus merupakan unit aktif pada tenant aktif dan user memiliki membership/permission.
- Akses lintas unit hanya diberikan melalui grant eksplisit. Tenant membership tidak otomatis membuka semua unit.
- Tenant administrator mengelola unit sesuai permission; operator unit dibatasi pada unit yang ditugaskan.
- User multi-unit berpindah konteks secara eksplisit; setiap pergantian divalidasi dan diaudit.
- Platform operator memakai jalur akses istimewa terpisah, least privilege, alasan akses, dan audit.

Global ORM scope saja tidak cukup. Query builder, raw SQL, laporan, pencarian, export, API, file, queue, scheduler, webhook, dan cache wajib menerapkan scope eksplisit. Constraint database harus mencegah relasi lintas tenant/unit.

## Pola integritas database

- Record tenant-scoped memiliki tenant_id tervalidasi.
- Record unit-scoped memiliki unit_id. tenant_id boleh didenormalisasi untuk constraint/efisiensi, tetapi harus konsisten dengan pemilik unit.
- Gunakan unique/composite key dan composite foreign key (atau strategi setara yang diuji) agar pasangan tenant_id/unit_id cocok.
- Server menentukan scope dari context; tenant_id/unit_id dari payload bukan otoritas.
- Reference catalog global dapat memiliki override tenant/unit hanya melalui model override eksplisit.

## Keanggotaan dan akun

- users adalah identitas autentikasi global, bukan sumber hak akses data.
- tenant_memberships menghubungkan user dan tenant; unik per pasangan user+tenant dengan status dan rentang berlaku.
- unit_memberships menghubungkan user dan unit; unik per pasangan user+unit dengan status dan rentang berlaku.
- Role/permission memiliki scope platform, tenant, atau unit yang jelas.
- Hubungan wali-orang tua dengan siswa adalah relasi domain tersendiri. Akses portal memeriksa relasi wali-siswa, verifikasi, dan enrollment relevan.

## Data yang wajib mengikuti scope

Siswa, enrollment, wali, pegawai, kelas, jadwal, presensi, asesmen, nilai, rapor, keuangan, surat, file, import/export, notifikasi, audit, dan laporan.

Cache key, file/object key, job uniqueness, idempotency key, dan pencarian harus mengandung scope benar. Background job membawa context tervalidasi dan gagal tertutup jika context hilang/tidak cocok.

## Pengujian wajib

- Tenant A tidak dapat membaca/mengubah/menghapus/mengekspor data tenant B.
- Unit A tidak dapat mengakses unit B tanpa grant.
- User yayasan hanya mengakses unit yang diizinkan membership dan permission.
- User sekolah mandiri tidak memerlukan yayasan.
- Unit mandiri dan unit yayasan menjalankan alur akademik yang sama.
- Manipulasi ID di URL, payload, API, file, dan export tidak menghasilkan IDOR.
- Relasi lintas tenant/unit ditolak aplikasi dan constraint database.
- Cache, queue, scheduler, webhook, search, dan laporan tidak membocorkan data.
- Transfer unit, penutupan tenant, dan pencabutan membership diaudit serta menjaga histori.

## Hal yang masih memerlukan ADR teknis

Composite foreign key/denormalisasi tenant_id; role/permission dan akses administrator; people/student/employee identity; prosedur transfer dan retensi histori; serta strategi database fisik (shared database/schema vs database per tenant) setelah threat model dan PoC.
