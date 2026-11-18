# Ruang Lingkup MVP SINAU

**Status:** Proposed — perlu persetujuan pemilik produk

## Tujuan MVP
Membuktikan bahwa fondasi multi-tenant dan proses administrasi-akademik inti dapat dipakai oleh sekolah umum (SD, SMP, SMA, SMK) dan madrasah (MI, MTs, MA, MAK), baik di bawah yayasan maupun mandiri.

## MVP — wajib
### A. Registrasi, platform, dan organisasi
- Registrasi pelanggan menyediakan dua pilihan: **Yayasan/penyelenggara pendidikan** atau **Sekolah/madrasah mandiri**.
- Pilihan tersebut menetapkan tipe tenant (foundation atau independent_provider), bukan jenis/jenjang pendidikan.
- Yayasan dapat menambahkan satu atau beberapa unit sekolah umum, madrasah, atau campuran keduanya.
- Registrasi mandiri membuat tenant tanpa entitas yayasan fiktif dan menghubungkannya dengan unit pendidikan yang didaftarkan.
- Registrasi/onboarding tenant melalui alur yang dikendalikan.
- Profil tenant dan satu/lebih unit pendidikan.
- Konfigurasi jenis lembaga dan jenjang.
- Pengguna, undangan/aktivasi, role, permission, dan keanggotaan unit.
- Pemilihan unit aktif dengan validasi server-side.
- Audit aktivitas sensitif.

### B. Data dasar
- Data siswa dan identitas dasar.
- Data orang tua/wali dan hubungan siswa-wali.
- Data guru dan pegawai.
- Status aktif/nonaktif dan riwayat perubahan.
- Impor awal CSV dengan validasi, preview, laporan kesalahan, dan audit.

### C. Setup akademik
- Tahun ajaran dan semester.
- Kurikulum/program yang diberi versi dan masa berlaku.
- Mata pelajaran dan pengelompokan mapel.
- Tingkat/kelas dan rombongan belajar.
- Penugasan guru.
- Enrollment siswa per unit, tahun ajaran, dan rombel.

### D. Operasional akademik dasar
- Presensi siswa per kelas/sesi dengan pencatatan pembuat dan waktu.
- Koreksi presensi dengan alasan dan audit.
- Penilaian dasar yang dapat dikonfigurasi; tidak mengunci formula rapor nasional/madrasah.
- Rekap presensi dan hasil belajar sederhana.
- Ekspor sesuai permission.

## Setelah MVP
- PPDB lengkap dan pembayaran pendaftaran.
- Tagihan, pembayaran online, akuntansi dan RKAS.
- Surat masuk/keluar, disposisi dan TTE.
- Kesiswaan lanjutan, BK, perpustakaan, inventaris, alumni.
- Portal orang tua/siswa lengkap dan aplikasi mobile.
- Integrasi data pemerintah/penyedia eksternal.
- Payroll dan HR lanjutan.

## Batasan penting
- MVP tidak boleh mengklaim menggantikan semua aplikasi/pelaporan resmi.
- Struktur mapel, penilaian, dan rapor harus dapat dikonfigurasi per jenis lembaga, jenjang, kurikulum, dan periode.
- Dukungan madrasah harus diuji dengan pengguna madrasah; tidak cukup hanya mengganti label sekolah.
- Dukungan SD/SMP/SMA/SMK juga harus diuji; yayasan sekolah umum merupakan skenario pelanggan yang valid.
- Fitur yang belum masuk MVP tidak boleh dibuat diam-diam tanpa change request.

## Gerbang kelulusan MVP
1. Skenario registrasi yayasan sekolah umum lulus.
2. Skenario registrasi yayasan madrasah atau campuran lulus.
3. Skenario registrasi sekolah/madrasah mandiri lulus tanpa yayasan fiktif.
4. Tes isolasi tenant dan unit lulus.
2. Tes permission untuk seluruh use case MVP lulus.
3. Import data dapat dipreview dan ditolak dengan alasan yang jelas.
4. Koreksi data sensitif terekam.
5. Pilot menyelesaikan skenario inti sekolah umum dan madrasah.
6. Backup/restore dan monitoring dasar terbukti.
7. Tidak ada bug kritis terbuka terkait kebocoran atau kerusakan data.
