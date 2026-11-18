# Ruang Lingkup MVP SINAU

**Status:** Accepted sebagai baseline perencanaan — disetujui pemilik produk pada 2026-11-18; dapat direvisi melalui change control.

## Tujuan MVP
Membuktikan bahwa fondasi multi-tenant dan proses administrasi-akademik inti dapat dipakai oleh sekolah umum (SD, SMP, SMA, SMK) dan madrasah (MI, MTs, MA, MAK), baik di bawah yayasan maupun mandiri.

## MVP — wajib
### A. Registrasi, platform, dan organisasi
- Registrasi pelanggan menyediakan dua pilihan: **Yayasan/penyelenggara pendidikan** atau **Sekolah/madrasah mandiri**.
- Pilihan tersebut menetapkan tipe tenant (foundation atau independent_provider), bukan jenis/jenjang pendidikan.
- Yayasan dan sekolah/madrasah mandiri dapat menambahkan unit sesuai entitlement paket; tipe tenant tidak menentukan kuota unit.
- Dokumen legal yayasan dapat dilengkapi pada tahap verifikasi, bukan syarat upload saat registrasi awal.
- NPSN/NSM dapat kosong saat registrasi awal dan dilengkapi saat verifikasi; identifier yang diisi divalidasi tanpa membocorkan data lembaga lain.
- Status verifikasi dipisahkan dari status subscription; akses dievaluasi berdasarkan kedua status.
- Tenant memperoleh 7 hari kalender sejak onboarding selesai untuk menyerahkan persyaratan verifikasi wajib; jika belum diserahkan sampai akhir tenggat, tenant otomatis suspended dengan akses terbatas.
- Tenant yang menyerahkan persyaratan tepat waktu tidak boleh disuspend hanya karena pemeriksaan internal belum selesai.
- Downgrade tidak menghapus unit atau data; jika jumlah unit melampaui entitlement, penambahan unit baru diblokir.
- Registrasi mandiri membuat tenant tanpa entitas yayasan fiktif dan menghubungkannya dengan unit pendidikan yang didaftarkan.
- Registrasi/onboarding tenant melalui alur yang dikendalikan, dengan status verifikasi dan subscription terpisah.
- Entitlement jumlah unit diperiksa server-side pada setiap pembuatan unit.
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
5. Tes permission untuk seluruh use case MVP lulus.
6. Import data dapat dipreview dan ditolak dengan alasan yang jelas.
7. Koreksi data sensitif terekam.
8. Pilot menyelesaikan skenario inti sekolah umum dan madrasah.
9. Backup/restore dan monitoring dasar terbukti.
10. Tidak ada bug kritis terbuka terkait kebocoran atau kerusakan data.


## Persetujuan dan pengendalian revisi

**Persetujuan baseline:** Pemilik produk menyetujui ruang lingkup MVP yang tercantum dalam dokumen ini pada 2026-11-18 sebagai baseline perencanaan SINAU.

Persetujuan ini:
- menjadi dasar penyusunan domain model, ERD konseptual/logis, module blueprint, dan rencana validasi;
- tidak berarti seluruh detail proses, field data, regulasi, stack aplikasi, atau desain teknis telah disetujui;
- tidak mengizinkan implementasi produksi atau migration domain sebelum gerbang PoC, review keamanan, dan persetujuan implementasi terkait terpenuhi;
- tidak mengunci scope secara permanen.

**Revisi di tengah proyek diperbolehkan** melalui mekanisme change control. Setiap usulan revisi harus mencatat alasan, kebutuhan/masalah yang dijawab, dampak terhadap proses bisnis, modul, data, tenant/unit isolation, keamanan/privasi, jadwal, dan acceptance criteria. Perubahan scope MVP harus disetujui pemilik produk dan disinkronkan ke dokumen terkait (process map/specification, domain model, ERD, katalog blueprint, test plan, dan project progress). Riwayat keputusan lama tidak dihapus; keputusan baru mencatat apakah mengganti atau melengkapi keputusan sebelumnya.

Perubahan editorial atau klarifikasi yang tidak mengubah perilaku/scope dapat dicatat sebagai revisi dokumentasi. Perubahan yang menambah, mengurangi, atau mengubah perilaku produk memerlukan change request dan persetujuan eksplisit.
