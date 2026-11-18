# SINAU Master Blueprint

**Status:** Draft baseline — perlu validasi kebutuhan rinci  
**Tanggal:** 2026-11-18

## 1. Visi

Menjadi platform digital terpadu yang membantu sekolah dan madrasah mengelola proses pendidikan, administrasi, komunikasi, dan tata kelola dalam satu sistem yang aman dan mudah digunakan.

## 2. Sasaran pengguna

- Pengelola/platform operator SaaS.
- Yayasan atau pengelola beberapa lembaga.
- Kepala sekolah/kepala madrasah dan wakil.
- Tata usaha/operator.
- Guru dan wali kelas.
- Bendahara dan staf keuangan.
- Pustakawan dan pengelola aset.
- Siswa/peserta didik.
- Orang tua/wali.
- Pengawas atau pihak lain sesuai kewenangan dan dasar akses.

## 3. Model organisasi

Model konseptual awal:

`Platform SINAU → Tenant/Pelanggan → Unit Pendidikan → Periode Operasional`

Tenant dapat berupa yayasan atau lembaga pelanggan yang menaungi satu atau beberapa unit. Unit dapat berupa SD/SMP/SMA/SMK atau MI/MTs/MA/MAK. Model final harus mendukung juga pelanggan yang hanya memiliki satu sekolah tanpa memaksakan struktur yayasan.

Pengguna dapat memperoleh akses ke lebih dari satu tenant/unit jika ditetapkan secara eksplisit dan diaudit.

## 4. Domain kemampuan produk

1. Platform core, tenant, langganan, konfigurasi, dan akses.
2. Data referensi pendidikan dan profil lembaga.
3. Penerimaan peserta didik baru (PPDB/PMB sesuai konteks lembaga).
4. Data peserta didik, orang tua/wali, dan riwayat enrollment.
5. Tahun ajaran, semester, kalender, kurikulum, kelas, dan rombongan belajar.
6. Guru, pegawai, dan sumber daya manusia.
7. Jadwal, presensi, kegiatan belajar, tugas, penilaian, dan rapor.
8. Keuangan sekolah: tagihan, pembayaran, kas, jurnal, anggaran, dan laporan.
9. Kesiswaan, bimbingan, prestasi, pelanggaran, dan kegiatan.
10. Surat masuk/keluar, disposisi, persetujuan, arsip, dan tanda tangan elektronik melalui penyedia sah.
11. RKS/RKT/RKAS atau perencanaan lembaga sesuai ketentuan yang berlaku.
12. Perpustakaan, inventaris, dan aset.
13. Portal guru, siswa, dan orang tua/wali.
14. Notifikasi, komunikasi, dashboard, laporan, ekspor, dan audit.

Domain ini adalah peta perencanaan, bukan janji bahwa semua modul dibuat sekaligus.

## 5. Prinsip multi-jenis lembaga

- Satu core product dengan konfigurasi jenis lembaga dan jenjang.
- Perbedaan kurikulum dan pelaporan dimodelkan tanpa mengunci pada satu kurikulum.
- Modul atau field khusus hanya diaktifkan ketika relevan.
- Data referensi dan aturan memiliki sumber serta versi.
- Pengalaman pengguna menampilkan istilah yang sesuai konteks lembaga jika memang berbeda.

## 6. Model bisnis SaaS

Rencana awal: langganan per tenant dengan paket dan batas penggunaan yang dapat dikonfigurasi, misalnya jumlah peserta didik, unit, pengguna, penyimpanan, dan modul. Detail harga, paket, kuota, trial, billing, dan penagihan belum disahkan.

## 7. Prinsip teknis

- Modular monolith terlebih dahulu.
- API versioning untuk integrasi dan aplikasi mobile.
- Database relational dengan constraint integritas.
- Queue untuk pekerjaan lama dan integrasi; setiap job harus tenant-aware.
- Object storage privat untuk dokumen.
- Logging, monitoring, backup, restore, dan audit sejak awal.
- Hindari ketergantungan vendor yang menghambat portabilitas tanpa alasan.

Stack teknologi final ditetapkan dalam ADR setelah validasi kebutuhan, kompatibilitas versi, biaya, dukungan, dan keamanan.

## 8. Kualitas dan kriteria keberhasilan

- Tidak ada akses lintas tenant yang tidak sah.
- Alur akademik dan administrasi tervalidasi oleh pengguna sekolah umum dan madrasah.
- Data historis dapat ditelusuri.
- UI konsisten dan responsif.
- Proses penting mempunyai audit trail.
- Backup dapat dipulihkan melalui uji restore.
- Integrasi dan proses async aman terhadap retry/duplikasi.
- Modul dapat dirilis bertahap tanpa merusak modul lain.

## 9. Hal yang belum diputuskan

- Stack final dan versi runtime/framework.
- Jenis dan strategi database final.
- Struktur tenant/yayasan/unit final.
- Paket SaaS dan billing.
- Design tokens final dan identitas visual.
- Modul MVP dan prioritas peluncuran.
- Integrasi pemerintah, payment gateway, tanda tangan elektronik, dan layanan eksternal.
- Model deployment, SLA, retensi, serta pemulihan bencana.

Setiap keputusan final harus dicatat dalam ADR atau spesifikasi yang sesuai.
