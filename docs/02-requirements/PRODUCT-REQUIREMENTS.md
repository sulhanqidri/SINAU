# Product Requirements — SINAU

**Status:** Draft 0.1 — perlu validasi dengan calon pengguna  
**Tanggal:** 2026-11-18

## 1. Ringkasan
SINAU adalah aplikasi SaaS multi-tenant untuk administrasi dan operasional pendidikan di Indonesia. Satu platform melayani sekolah umum (SD, SMP, SMA, SMK) dan madrasah (MI, MTs, MA, MAK), baik yang berada di bawah yayasan maupun yang mandiri, dengan konfigurasi sesuai kebutuhan lembaga.

## 2. Masalah yang ingin diselesaikan
Lembaga pendidikan sering memakai banyak aplikasi/berkas terpisah untuk data siswa, akademik, presensi, keuangan, surat, dan komunikasi. SINAU bertujuan mengurangi duplikasi data, menyatukan alur kerja, memperjelas hak akses, dan menyediakan riwayat yang dapat diaudit.

## 3. Model pelanggan dan registrasi
Pada registrasi pelanggan, SINAU menyediakan dua pilihan:

1. **Yayasan/penyelenggara pendidikan**: akun pelanggan mewakili yayasan/badan penyelenggara yang menaungi satu atau beberapa sekolah/madrasah. Berlaku untuk yayasan yang menaungi SD, SMP, SMA, SMK, MI, MTs, MA, MAK, atau kombinasi di antaranya.
2. **Sekolah/madrasah mandiri**: satuan pendidikan menjadi pelanggan langsung tanpa perlu membuat entitas yayasan.

Pilihan ini menentukan tipe tenant (foundation atau independent_provider), bukan jenis atau jenjang pendidikan. Jenis dan jenjang dipilih saat membuat setiap education unit. Yayasan dapat menambahkan beberapa unit dengan jenis/jenjang berbeda; pelanggan mandiri memulai dengan unitnya sendiri.

## 4. Persona utama
- Operator/platform admin: mengelola tenant, paket, dan dukungan platform.
- Admin yayasan/pengelola: mengelola satu atau beberapa unit.
- Kepala sekolah/madrasah: memantau operasional unit.
- Tata usaha/operator: mengelola data induk dan administrasi.
- Guru/wali kelas: mengelola kelas, presensi, dan penilaian sesuai kewenangan.
- Bendahara: mengelola tagihan dan transaksi sesuai kewenangan.
- Siswa: melihat informasi yang diizinkan.
- Orang tua/wali: melihat informasi anak yang terhubung dan sah.

## 5. Prinsip kebutuhan
- Satu identitas orang tidak harus menjadi satu record siswa per sekolah; identitas dan riwayat enrollment dipisahkan.
- Akses diberikan berdasarkan tenant, unit, role, permission, dan relasi yang sah.
- Jenis lembaga dan jenjang memengaruhi konfigurasi, bukan membuat cabang aplikasi yang tidak terpelihara.
- Bentuk pelanggan (yayasan atau mandiri) terpisah dari jenis/jenjang pendidikan setiap unit.
- Perubahan kurikulum dan aturan harus memiliki versi/periode efektif.
- Semua alur penting memiliki status, validasi, dan audit.

## 6. Kebutuhan fungsional tingkat produk
FR-001 Platform dapat membuat dan mengelola tenant.
FR-002 Tenant dapat memiliki satu atau beberapa unit pendidikan.
FR-003 Pengguna dapat diberi akses ke tenant/unit tertentu.
FR-004 Sistem menyediakan role dan permission yang dapat dikonfigurasi secara aman.
FR-005 Sistem menyimpan profil unit, jenis lembaga, jenjang, dan identitas resmi yang relevan.
FR-006 Sistem mengelola siswa, orang tua/wali, guru, dan pegawai.
FR-007 Sistem mengelola tahun ajaran, semester, kurikulum, mata pelajaran, kelas, rombel, dan enrollment.
FR-008 Sistem menyediakan presensi dengan status dan koreksi yang diaudit.
FR-009 Sistem menyediakan asesmen/nilai dan pelaporan akademik sesuai konfigurasi.
FR-010 Sistem menyediakan laporan dan ekspor yang dibatasi hak akses.
FR-011 Sistem mendukung konfigurasi khusus sekolah umum, SMK, dan madrasah.
FR-012 Sistem mencatat aktivitas sensitif dan perubahan data penting.
FR-013 Sistem menyediakan antarmuka responsif desktop/tablet/ponsel.
FR-014 Registrasi pelanggan menyediakan pilihan yayasan/penyelenggara atau sekolah/madrasah mandiri.
FR-015 Yayasan dapat menaungi sekolah umum, madrasah, atau kombinasi keduanya dalam satu tenant.

## 7. Kebutuhan nonfungsional
- Keamanan tenant/unit wajib diuji pada setiap modul.
- Ketersediaan dan target performa ditentukan sebelum pilot.
- Data sensitif diminimalkan dan aksesnya dibatasi.
- Operasi berulang/webhook/job dirancang idempotent jika berisiko duplikasi.
- Backup dan restore harus dapat diuji.
- UI memenuhi standar aksesibilitas yang ditetapkan proyek.
- Log dan monitoring tidak membocorkan kredensial atau data pribadi berlebihan.

## 8. Di luar MVP awal
Payment gateway, akuntansi penuh, tanda tangan elektronik tersertifikasi, integrasi pemerintah, PPDB end-to-end, perpustakaan, inventaris, payroll, aplikasi mobile native, dan analitik lanjutan. Modul ini tetap masuk roadmap, tetapi bukan syarat pilot pertama.

## 9. Pertanyaan validasi
- Alur akademik minimum apa yang wajib ada saat pilot?
- Metode presensi mana yang harus tersedia sejak awal?
- Laporan apa yang paling sering digunakan setiap jenis lembaga?
- Data apa yang wajib diimpor dari sistem lama?
- Apakah orang tua/siswa perlu portal pada MVP atau setelahnya?

## 10. Acceptance produk MVP
MVP dinyatakan siap pilot bila pelanggan dapat onboarding sebagai yayasan atau sekolah/madrasah mandiri; tenant yayasan dapat mengelola beberapa unit termasuk sekolah umum dan madrasah; tenant mandiri dapat berjalan tanpa entitas yayasan fiktif; proses akademik dasar berjalan; seluruh akses dibatasi sesuai tenant/unit/role; dan alur diuji oleh perwakilan sekolah umum serta madrasah.
