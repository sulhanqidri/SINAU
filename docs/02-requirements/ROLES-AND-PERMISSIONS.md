# Matriks Peran dan Akses Awal

Ini adalah baseline konseptual. Permission final harus diturunkan dari use case dan diuji, bukan mengandalkan nama role saja.

| Peran | Cakupan default | Tanggung jawab utama |
|---|---|---|
| Platform Super Admin | Platform | Tenant, paket, dukungan terkontrol |
| Tenant Owner | Tenant | Profil tenant, unit, admin tenant |
| Tenant Admin | Tenant | Pengguna dan konfigurasi tenant |
| Unit Head | Unit | Pengawasan unit dan persetujuan |
| Unit Admin/TU | Unit | Data induk dan administrasi |
| Academic Admin | Unit | Periode, kurikulum, kelas, enrollment |
| Teacher | Unit/kelas yang ditugaskan | Presensi, pembelajaran, nilai |
| Homeroom Teacher | Rombel yang ditugaskan | Rekap dan proses wali kelas |
| Finance Staff | Unit | Modul keuangan saat dirilis |
| Student | Identitas/relasi sendiri | Informasi milik sendiri |
| Parent/Guardian | Anak yang terhubung | Informasi anak sesuai izin |

## Aturan
- Role adalah kumpulan permission; role bukan satu-satunya batas akses.
- Setiap permission dievaluasi bersama tenant, unit, kepemilikan/relasi record, dan konteks periode.
- Guru hanya boleh mengubah kelas/mapel yang ditugaskan dan dalam jendela yang diizinkan.
- Wali hanya boleh melihat anak yang hubungan walinya sudah diverifikasi.
- Platform admin tidak boleh otomatis memiliki akses bebas ke seluruh data akademik/keuangan tenant.
- Akses darurat/support harus memiliki alasan, masa berlaku, persetujuan bila diperlukan, dan audit.
- Perubahan role dan membership selalu diaudit.

## Format permission
Gunakan nama berbasis aksi dan domain, misalnya `students.view`, `students.create`, `attendance.record`, `attendance.correct`, `grades.enter`, `grades.approve`, `reports.export`. Daftar final dibuat dari use case aktual.
