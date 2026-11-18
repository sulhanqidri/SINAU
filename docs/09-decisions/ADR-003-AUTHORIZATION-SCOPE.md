# ADR-003: Identitas, Membership, dan Authorization Scope

- **Status:** Proposed baseline; role catalog dan implementasi teknis perlu PoC.
- **Tanggal:** 2026-11-18
- **Area:** Authentication, tenant context, RBAC, unit access

## Konteks

Satu akun dapat bekerja pada beberapa tenant dan beberapa unit. Yayasan dapat mengelola banyak unit, sementara sekolah mandiri hanya memiliki unit sendiri. Login saja tidak membuktikan hak akses terhadap tenant, unit, siswa, atau data akademik.

## Keputusan baseline

### Identitas akun
- `users` adalah identitas autentikasi global dan tidak menjadi sumber akses domain secara otomatis.
- Satu user dapat memiliki beberapa tenant membership.
- Email/nomor telepon yang sama tidak membuat membership atau relasi wali otomatis.
- Penonaktifan akun global memutus seluruh sesi; pencabutan membership memutus akses hanya pada scope terkait.

### Membership
- `tenant_memberships`: user ↔ tenant, status, periode berlaku, inviter/approver, dan audit.
- `unit_memberships`: user ↔ education unit, status, periode berlaku, dan audit.
- Membership unik per pasangan user+tenant dan user+unit sesuai kebijakan histori.
- Tenant membership memberi akses ke fungsi tenant-level yang diizinkan, bukan otomatis ke data operasional seluruh unit.
- Unit membership memberi kandidat akses unit; permission dan relasi tugas tetap harus diperiksa.

### Role dan permission
Gunakan permission eksplisit dengan scope platform, tenant, atau unit. Baseline tabel konseptual:
- `permissions`: kode aksi stabil, misalnya student.view, attendance.correct.
- `roles`: role sistem atau role kustom dengan scope yang jelas.
- `platform_user_roles`: role platform.
- `tenant_membership_roles`: role pada tenant membership.
- `unit_membership_roles`: role pada unit membership.

Pemisahan pivot menghindari relasi polymorphic scope yang sulit diberi foreign key. Custom role tidak boleh memberikan permission di luar scope pembuatnya. Deny/allow precedence dan inheritance harus didefinisikan eksplisit; jangan mengandalkan nama role saja.

### Akses berbasis relasi
Permission umum belum cukup untuk seluruh data:
- Guru hanya dapat mengakses kelas/mapel/periode sesuai teacher assignment.
- Wali hanya dapat mengakses siswa yang relasinya diverifikasi dan masih berlaku, serta data yang memang tersedia untuk wali.
- Siswa hanya dapat mengakses profil dan hasil miliknya sendiri.
- Staf keuangan hanya mengakses domain keuangan sesuai unit/tenant dan tanggung jawab.
- Akses data anak dan data sensitif memerlukan minimisasi, audit, dan pembatasan field.

### Pemilihan konteks aktif
1. Setelah autentikasi, server mengambil membership aktif dari database.
2. User memilih tenant dari daftar membership yang sah.
3. Jika operasi membutuhkan unit, user memilih unit yang memiliki membership/grant sah.
4. Server menyimpan context pada session/token terverifikasi dan memvalidasi ulang status membership serta tenant-unit relationship pada request.
5. Request tidak boleh mengganti tenant/unit hanya dengan mengirim ID lain.
6. Context yang hilang, kedaluwarsa, dicabut, atau tidak konsisten ditolak secara default.

Untuk API, tenant/unit selector boleh menjadi petunjuk pemilihan konteks, tetapi server wajib membuktikan membership. Header khusus bukan bukti otorisasi.

### Akses administrator yayasan
Tidak ada akses seluruh unit secara implisit hanya karena role bernama administrator yayasan. Pilihan akses harus berupa grant eksplisit yang dapat diaudit: unit tertentu atau permission tenant-level yang secara jelas memberi kemampuan mengelola unit. Akses baca/ubah data siswa dan nilai tetap dapat dibatasi terpisah.

### Platform support dan impersonation
Akses operator platform ke data pelanggan bersifat istimewa, terbatas waktu, berdasarkan alasan/tiket, disetujui sesuai kebijakan, diberi indikator UI, dan seluruh tindakan diaudit. Impersonation tidak boleh menjadi jalan pintas untuk melewati audit.

## Invarian keamanan

- Default deny.
- Check dilakukan server-side pada setiap request dan setiap resource.
- Jangan percaya tenant_id/unit_id dari payload, route parameter, cookie yang tidak ditandatangani, atau header.
- Cegah IDOR dengan scoped lookup sebelum tindakan.
- Revalidate membership ketika role/status berubah dan cabut session/cache terkait.
- Queue/job membawa scope eksplisit dan memverifikasi ulang sebelum mengeksekusi.
- Audit mencatat actor, action, target, scope, timestamp, outcome, dan correlation ID tanpa merekam secret.

## Belum diputuskan

- Framework RBAC/permission library.
- Apakah permission tertentu diwariskan dari tenant ke unit.
- MFA wajib untuk role sensitif.
- Mekanisme session/token dan API auth final.
- Model identitas people/student/employee serta relasi lintas unit.
- Detail approval untuk break-glass support.

Semua perlu PoC dan review keamanan sebelum implementasi.
