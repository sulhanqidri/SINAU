# SINAU Project Constitution

**Status:** Baseline awal  
**Versi dokumen:** 1.0.0  
**Tanggal:** 2026-11-18

Dokumen ini adalah aturan dasar produk dan pengembangan SINAU. Semua keputusan teknis, desain, dan implementasi wajib selaras dengannya. Perubahan terhadap aturan ini harus melalui proses pengendalian perubahan.

## 1. Identitas dan misi

Nama produk adalah **SINAU — Sistem Informasi dan Administrasi Pendidikan Terpadu**.

Misi: menyediakan platform pendidikan terpadu yang aman, mudah digunakan, dapat dikonfigurasi, dan membantu lembaga pendidikan mengelola proses akademik maupun administrasi.

Tagline kerja: **Satu Platform, Seluruh Kebutuhan Pendidikan.** Tagline ini dapat ditinjau sebagai bagian dari pengembangan identitas merek, tetapi tidak boleh menyebabkan perubahan arah produk tanpa keputusan tertulis.

## 2. Cakupan lembaga

SINAU dirancang untuk:
- Sekolah umum: SD, SMP, SMA, dan SMK.
- Madrasah: MI, MTs, MA, dan MAK.
- RA dapat menjadi perluasan cakupan setelah kebutuhan dan aturan operasionalnya dikaji.

Sistem tidak boleh menganggap sekolah umum dan madrasah memiliki seluruh struktur kurikulum, mata pelajaran, pelaporan, kewenangan, atau regulasi yang sama. Perbedaan harus direpresentasikan secara eksplisit melalui konfigurasi, referensi aturan, dan fitur yang relevan.

## 3. Prinsip produk yang tidak boleh dilanggar

1. **SaaS multi-tenant:** satu platform melayani banyak lembaga pelanggan dengan batas data yang tegas.
2. **Tenant isolation first:** tidak ada pengguna, proses, API, ekspor, laporan, job, atau file yang boleh mengakses data tenant lain tanpa kewenangan eksplisit yang sah.
3. **Multi-unit:** satu tenant dapat menaungi satu atau beberapa unit pendidikan sesuai model bisnis dan hak akses.
4. **School-type aware:** alur dan data mempertimbangkan jenis lembaga serta jenjangnya.
5. **Configurable, not hard-coded:** aturan yang dapat berbeda antarjenis lembaga, periode, atau kebijakan tidak ditanamkan secara tersebar dalam kode.
6. **Modular monolith first:** batas modul jelas; microservices bukan pilihan awal kecuali ada keputusan arsitektur yang membuktikan kebutuhan.
7. **Auditability:** aktivitas sensitif dan perubahan data penting dapat ditelusuri.
8. **Privacy by design:** data anak/peserta didik, wali, pegawai, dan keuangan dilindungi sesuai kebutuhan dan hukum.
9. **Accessible and responsive:** UI konsisten, mudah dipelajari, dan bekerja pada desktop, tablet, serta ponsel.
10. **Backward-aware:** perubahan tidak boleh merusak data, fitur, atau kontrak API yang sudah digunakan tanpa rencana migrasi.
11. **Tested delivery:** fitur harus melewati pengujian sebelum dirilis.
12. **Documented decisions:** keputusan penting harus memiliki catatan yang dapat ditinjau.

## 4. Prinsip desain dan UX

- Gunakan satu design system dan komponen bersama.
- Navigasi, sidebar, header, formulir, tabel, filter, modal, notifikasi, status, dan pola interaksi harus konsisten.
- Warna, tipografi, ukuran, spacing, radius, ikon, dan elevation ditetapkan sebagai design tokens.
- Prioritaskan kejelasan untuk operator tata usaha, guru, kepala sekolah/madrasah, bendahara, siswa, dan orang tua/wali.
- Hindari variasi komponen tanpa alasan kebutuhan yang terdokumentasi.
- UI harus menampilkan konteks unit/periode aktif agar pengguna memahami ruang data yang sedang dikelola.
- Status tidak boleh dibedakan hanya dengan warna; sertakan teks atau ikon yang bermakna.
- Perubahan desain global harus ditinjau dampaknya terhadap semua modul.

## 5. Prinsip akademik dan regulasi

- Tahun ajaran, semester, kalender pendidikan, kurikulum, mata pelajaran, rombongan belajar, penilaian, dan pelaporan harus memiliki periode/versi yang jelas.
- Dukungan SMK perlu memperhitungkan konsentrasi/program keahlian dan kebutuhan pembelajaran praktik/PKL jika relevan.
- Dukungan madrasah harus memperhitungkan struktur pendidikan dan mata pelajaran khas madrasah yang berlaku.
- Peraturan harus dicatat beserta penerbit, nomor/judul, tanggal penetapan, tanggal berlaku, sumber resmi, ruang lingkup, dan status verifikasinya.
- Jangan mengklaim sistem patuh pada suatu regulasi sebelum sumber resmi dan implementasinya diverifikasi.
- Perubahan regulasi tidak boleh diterapkan diam-diam; lakukan analisis dampak, versi aturan, pengujian, dan komunikasi perubahan.

## 6. Prinsip keamanan

- Terapkan autentikasi yang kuat, otorisasi berbasis role/permission, dan pembatasan berdasarkan tenant serta unit pendidikan.
- Validasi akses pada server untuk setiap operasi; menyembunyikan tombol di UI bukan kontrol keamanan.
- Relasi antar-record harus memeriksa kesesuaian tenant dan, jika relevan, unit sekolah.
- Terapkan least privilege dan pemisahan tugas untuk proses sensitif.
- Catat aktivitas penting tanpa memasukkan kata sandi, token, rahasia, atau data pribadi berlebihan ke log.
- File pribadi harus disimpan secara privat dan diakses melalui pemeriksaan otorisasi.
- Backup, restore, retensi, dan respons insiden harus direncanakan dan diuji.

## 7. Tata kelola data

- Identitas peserta didik dipisahkan dari riwayat pendaftaran/enrollment agar perpindahan dan riwayat pendidikan tidak menghapus sejarah.
- Data historis akademik/keuangan harus tetap dapat ditelusuri.
- Penghapusan data sensitif harus mengikuti kebijakan retensi dan dasar hukum; gunakan soft delete hanya bila sesuai.
- Perubahan nilai yang sudah disahkan, transaksi, dan dokumen resmi harus memiliki jejak audit dan prosedur koreksi.
- Impor/ekspor wajib menjalankan validasi tenant, izin, dan pencatatan aktivitas.

## 8. Aturan pelaksanaan

Jika instruksi atau permintaan fitur bertentangan dengan konstitusi:
1. Hentikan implementasi bagian yang bertentangan.
2. Jelaskan konflik dan risiko.
3. Ajukan opsi yang tetap memenuhi kebutuhan tanpa melanggar prinsip inti.
4. Jika konstitusi memang perlu diubah, buat usulan perubahan dan ADR/keputusan terkait sebelum implementasi.

Konstitusi ini berlaku untuk seluruh anggota tim, agen AI, dan kontributor proyek.
