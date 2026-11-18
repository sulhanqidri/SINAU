# Roadmap SINAU

Urutan dan estimasi akan ditetapkan ulang setelah discovery kebutuhan dan kapasitas tim. Fase di bawah adalah urutan dependensi, bukan komitmen tanggal rilis.

## Phase 0 — Discovery dan governance
- Validasi persona, alur kerja sekolah umum dan madrasah.
- Kunci model organisasi, cakupan MVP, istilah, dan prioritas.
- Finalisasi ADR stack, arsitektur, database, dan frontend.
- Lengkapi PRD, SRS, ERD awal, RBAC, dan strategi pengujian.

**Gerbang:** blueprint dan kebutuhan MVP disetujui.

## Phase 1 — Platform core
- Identitas, autentikasi, tenant, unit pendidikan.
- Keanggotaan, role, permission, dan audit.
- Konfigurasi lembaga dan periode dasar.
- Isolasi tenant dan test harness keamanan.

**Gerbang:** seluruh tes isolasi tenant dasar lulus.

## Phase 2 — Data pendidikan dan akademik
- Profil peserta didik, wali, guru, dan pegawai.
- Tahun ajaran, semester, kurikulum, mata pelajaran, kelas, dan enrollment.
- Kebutuhan khusus sekolah umum, madrasah, dan SMK.

**Gerbang:** alur inti tervalidasi pada lebih dari satu tipe lembaga.

## Phase 3 — Aktivitas belajar dan presensi
- Jadwal, presensi, jurnal pembelajaran.
- Tugas, asesmen, nilai, rapor, dan promosi.
- Audit untuk perubahan nilai dan koreksi.

## Phase 4 — Keuangan
- Tagihan, pembayaran, alokasi, kas, jurnal, anggaran, realisasi, dan laporan.
- Rekonsiliasi serta idempotency pembayaran.

## Phase 5 — Administrasi dan komunikasi
- Surat masuk/keluar, disposisi, persetujuan, arsip.
- Notifikasi dan portal orang tua/siswa.
- Tanda tangan elektronik melalui penyedia yang memenuhi kebutuhan hukum, setelah kajian.

## Phase 6 — Operasional lembaga
- Kesiswaan, SDM, perpustakaan, aset, perencanaan, kelulusan, alumni.
- RKS/RKT/RKAS atau padanan sesuai kebijakan dan jenis lembaga.

## Phase 7 — Integrasi, hardening, dan peluncuran
- Integrasi eksternal yang telah disetujui.
- Uji keamanan, performa, aksesibilitas, backup/restore, dan pemulihan.
- Uji penerimaan dengan sekolah umum dan madrasah.
- Peluncuran bertahap dan monitoring.

## Aturan perubahan roadmap

Prioritas ditentukan oleh nilai pengguna, risiko, kewajiban regulasi, dependensi, effort, dan kesiapan pengujian. Perubahan urutan atau penghilangan gerbang harus dicatat.
