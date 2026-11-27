# SINAU Master Blueprint

**Status:** Draft baseline — belum final dan masih memerlukan validasi kebutuhan rinci  
**Versi:** 0.2.0  
**Tanggal checkpoint:** 2026-11-18  
**Tracker pekerjaan:** [PROJECT-PROGRESS.md](../00-governance/PROJECT-PROGRESS.md)  
**Katalog kelengkapan:** [BLUEPRINT-CATALOG.md](BLUEPRINT-CATALOG.md)

> Dokumen ini menetapkan arah produk dan peta sistem tingkat tertinggi. Spesifikasi rinci per domain, proses, API, data, otorisasi, UX, keamanan, dan operasi harus ditulis pada dokumen turunannya. Jangan menganggap daftar domain sebagai persetujuan bahwa semuanya masuk MVP.

## 1. Visi

Menjadi platform digital terpadu yang membantu sekolah dan madrasah mengelola proses pendidikan, administrasi, komunikasi, dan tata kelola dalam satu sistem yang aman, mudah digunakan, dapat dikonfigurasi, serta berkembang secara bertahap.

**Prinsip produk:** Satu Platform, Seluruh Kebutuhan Pendidikan.

## 2. Cakupan lembaga

Baseline cakupan:
- Sekolah umum: SD, SMP, SMA, dan SMK.
- Madrasah: MI, MTs, MA, dan MAK.
- RA/PAUD merupakan calon perluasan; tidak otomatis termasuk MVP.

Perbedaan jenis lembaga, jenjang, kurikulum, struktur mata pelajaran, penilaian, pelaporan, dan regulasi harus dimodelkan secara eksplisit dan berversi. Jangan mengasumsikan seluruh sekolah umum dan madrasah mempunyai proses yang identik.

## 3. Aktor dan pengguna

### 3.1 Aktor platform
- Platform owner / super administrator.
- Platform operations dan customer support dengan akses terbatas, disetujui, dan diaudit.
- Tim billing/subscription dan compliance sesuai pemisahan tugas.

### 3.2 Aktor tenant dan unit
- Pemilik/pengelola yayasan atau foundation.
- Pengelola tenant mandiri (independent provider).
- Kepala sekolah/kepala madrasah dan wakil.
- Operator/admin lembaga dan tata usaha.
- Guru, wali kelas, guru BK, dan tenaga kependidikan.
- Bendahara dan staf keuangan.
- Pustakawan, pengelola aset, dan staf pendukung.
- Siswa/peserta didik.
- Orang tua/wali.
- Pengawas atau pihak eksternal yang memperoleh akses sah dan terbatas.

Satu identitas pengguna dapat memiliki beberapa membership tenant/unit. Hak akses selalu ditentukan oleh membership, role, relationship, konteks aktif, dan kebijakan server; bukan hanya oleh akun login atau menu UI.

## 4. Model organisasi dan tenant

Model konseptual:

`Platform SINAU → Tenant/Pelanggan → Education Unit → Periode Operasional`

- `foundation`: tenant pelanggan berupa yayasan/badan penyelenggara yang dapat memiliki satu atau banyak unit pendidikan.
- `independent_provider`: tenant pelanggan langsung untuk sekolah/madrasah mandiri tanpa membuat yayasan fiktif.
- Tenant adalah batas kontrak, billing, entitlement, konfigurasi pelanggan, dan isolasi data.
- Education unit adalah batas operasional lembaga pendidikan.
- Jenis lembaga dan jenjang melekat pada education unit, bukan pada tenant.
- Satu pengguna dapat memiliki tenant membership dan unit membership yang berbeda; akses lintas tenant/unit harus eksplisit dan diaudit.
- Kuota unit mengikuti entitlement paket, bukan semata-mata tipe tenant.
- Verification status dipisahkan dari subscription/billing status.
- Downgrade tidak boleh menghapus unit atau data secara otomatis.

Detail normatif berada pada ADR-001 sampai ADR-004 dan spesifikasi tenant lifecycle.

## 5. Domain kemampuan produk

Peta domain berikut adalah inventaris cakupan potensial. Prioritas MVP ditetapkan di `docs/02-requirements/MVP-SCOPE.md` setelah validasi.

### 5.1 Platform SaaS dan tenant administration
- Tenant onboarding, verifikasi, lifecycle, suspension/reactivation.
- Education unit provisioning dan entitlement.
- Paket, subscription, billing, invoicing, payment, usage metering.
- Tenant settings, branding/configuration, feature entitlement.
- Platform operations, support access, audit, incident.

### 5.2 Master data pendidikan
- Profil lembaga, identitas, legalitas, struktur organisasi.
- Kalender pendidikan, tahun ajaran, semester, periode.
- Jenis lembaga, jenjang, program/konsentrasi, ruang, fasilitas.
- Kurikulum, struktur kurikulum, mapel, referensi nilai dan status.
- Register regulasi dan referensi resmi yang memiliki versi/tanggal efektif.

### 5.3 Penerimaan dan siklus peserta didik
- PPDB/PMB, gelombang, pendaftaran, seleksi, daftar ulang.
- Identitas peserta didik dan hubungan orang tua/wali.
- Enrollment per unit/periode, kelas/rombel, mutasi, cuti/nonaktif, kelulusan, alumni.
- Dokumen, persetujuan, riwayat dan audit perubahan data.

### 5.4 Akademik dan pembelajaran
- Kurikulum dan struktur pembelajaran.
- Rombongan belajar, wali kelas, mata pelajaran, penugasan guru.
- Jadwal pelajaran, ruang, kalender, kegiatan belajar.
- Presensi, izin/sakit, koreksi dan rekap.
- Materi, tugas, asesmen, rubrik, nilai, remedial.
- Rapor, transkrip, arsip hasil belajar, pengesahan dan koreksi.
- Kebutuhan khusus SMK/MAK seperti program keahlian, praktik dan PKL bila masuk scope.

### 5.5 SDM dan tata kelola pegawai
- Data guru/pegawai, jabatan, unit, status kepegawaian.
- Penugasan mengajar, beban kerja, kompetensi dan dokumen.
- Presensi pegawai, cuti/izin dan proses terkait sesuai scope.
- Evaluasi kinerja atau pengembangan profesional bila disetujui.

### 5.6 Kesiswaan dan dukungan peserta didik
- Bimbingan konseling, pembinaan, pelanggaran, prestasi.
- Ekstrakurikuler, organisasi, kegiatan, beasiswa dan bantuan.
- Layanan inklusi/dukungan khusus dengan akses dan privasi yang ketat jika disetujui.

### 5.7 Keuangan dan sumber daya
- Tagihan, pembayaran, potongan, beasiswa, tunggakan, rekonsiliasi.
- Kas/bank, jurnal, anggaran, laporan keuangan dan audit.
- Pengadaan, perencanaan, persetujuan, RKS/RKT/RKAS bila relevan.
- Perpustakaan, inventaris, aset, lokasi, pemeliharaan dan mutasi.

### 5.8 Administrasi, komunikasi dan layanan
- Surat masuk/keluar, nomor surat, disposisi, persetujuan, arsip.
- Dokumen privat, template, retensi dan tanda tangan elektronik melalui penyedia sah.
- Pengumuman, notifikasi, pesan, agenda dan komunikasi wali.
- Portal/dasbor untuk guru, siswa, orang tua/wali dan pimpinan.
- Laporan, analitik, ekspor, impor, pencarian dan audit.

## 6. Prinsip lintas domain

Setiap spesifikasi modul harus menyatakan:
1. Tujuan, pengguna, masalah yang diselesaikan, dan batas scope.
2. Prasyarat, aktor, role, tenant/unit scope, dan periode aktif.
3. Alur normal, alternatif, penolakan, pembatalan, koreksi, dan kegagalan.
4. Aturan bisnis, status/lifecycle, approval dan pemisahan tugas.
5. Data ownership, relasi, constraint, audit dan retention.
6. API/event, integrasi, job async, retry, idempotency, dan failure handling.
7. UI/screen, validasi, empty/loading/error/success states dan aksesibilitas.
8. Laporan, ekspor/impor, notifikasi dan kebutuhan pencarian.
9. Acceptance criteria, test cases, risiko, dependensi dan sumber regulasi.

Tidak boleh ada modul yang membuat akses data lintas tenant/unit melalui asumsi dari ID record, parameter request, cache key, file URL, atau job payload.

## 7. Model bisnis SaaS

Arah awal adalah subscription per tenant dengan paket/entitlement yang dapat mengatur jumlah unit, peserta didik, pengguna, storage, dan modul. Harga, masa trial, billing cycle, pajak, payment provider, grace period selain keputusan onboarding yang sudah diterima, serta kebijakan overage belum final.

Verification status dan subscription status adalah dua state machine berbeda. Suspend karena verifikasi, suspend karena billing, pembatalan, downgrade, dan reaktivasi harus memiliki sebab, kewenangan, dampak akses, serta prosedur pemulihan yang jelas.

## 8. Prinsip arsitektur dan teknologi

- Modular monolith sebagai arah awal; batas modul dan ownership data harus jelas.
- PostgreSQL 18 telah dipilih sebagai database utama melalui ADR-006.
- Shared database/shared schema dengan tenant_id/unit_id, composite FK/unique, tenant context dan authorization default-deny adalah baseline MVP sesuai ADR-002/003.
- PostgreSQL RLS dievaluasi sebagai defense-in-depth, bukan pengganti authorization aplikasi.
- Laravel 13 + Vue 3 + Inertia + Tailwind adalah rekomendasi PoC di ADR-005, belum stack final sampai kompatibilitas, versi runtime/dependency, keamanan, dan maintainability dibuktikan.
- API versioning untuk integrasi dan klien lain.
- Queue untuk proses panjang; semua job tenant-aware, idempotent jika perlu, retry-safe, dan memiliki failure handling.
- Cache, search, export, scheduler, storage, dan notifikasi wajib tenant-aware.
- Object storage untuk dokumen privat dengan otorisasi sebelum akses.
- Logging, metrics, tracing, alerting, backup, restore, dan audit sejak awal.
- Hindari ketergantungan vendor tanpa alasan, kontrak, dan rencana exit yang jelas.

## 9. Keamanan, privasi, dan kepercayaan

- Least privilege, default deny, server-side authorization, MFA sesuai risiko.
- Tenant isolation dan unit isolation diuji pada seluruh jalur data.
- Privileged support access memerlukan alasan, persetujuan sesuai kebijakan, waktu terbatas, dan audit.
- Data anak/peserta didik, wali, pegawai, nilai, kesehatan/dukungan khusus, dan keuangan memerlukan klasifikasi dan perlindungan sesuai sensitivitas.
- Data pribadi diminimalkan; consent/legal basis, retention, correction, export, dan deletion ditetapkan sesuai hukum dan kebutuhan.
- Secret tidak boleh masuk repository atau log.
- Perubahan nilai yang disahkan, transaksi, persetujuan dan dokumen resmi harus dapat diaudit.
- Klaim kepatuhan terhadap regulasi tidak boleh dibuat sebelum sumber resmi dan implementasi diverifikasi.

## 10. Pengalaman pengguna dan desain

- Satu design system dengan design tokens dan komponen bersama.
- Konteks tenant, unit, tahun ajaran/semester aktif terlihat jelas.
- Navigasi dan fitur mengikuti role, scope, jenis lembaga, jenjang, dan entitlement.
- Desktop, tablet, dan mobile harus diperhitungkan.
- Form, tabel, pencarian, filter, pagination, notifikasi, dialog, dan status konsisten.
- Accessibility, keyboard navigation, contrast, label, dan error message merupakan persyaratan.
- Sekolah umum dan madrasah dapat menggunakan istilah/konfigurasi yang sesuai tanpa membuat produk terpisah.

## 11. Integrasi dan interoperabilitas

Semua integrasi harus memiliki pemilik, tujuan, dasar akses/data, kontrak, sandbox, credential handling, timeout, retry, idempotency, reconciliation, monitoring, dan fallback. Kandidat integrasi dapat mencakup layanan pendidikan/pemerintah yang resmi, payment gateway, email/SMS/WhatsApp, tanda tangan elektronik, penyimpanan, dan sistem akuntansi. Tidak ada integrasi yang dianggap tersedia atau disetujui sebelum ada spesifikasi dan validasi.

## 12. Pelaporan dan analitik

Laporan harus ditentukan per aktor, unit, tenant, periode, dan tujuan. Ekspor harus memeriksa authorization, meminimalkan data, memiliki audit trail, dan tidak membocorkan data tenant lain. Angka laporan keuangan dan akademik harus memiliki definisi serta sumber data yang konsisten.

## 13. Operasional, deployment, dan continuity

Target operasi mencakup:
- Environment terpisah untuk local/development, CI, preproduction, dan production.
- Deployment online yang idempotent dan offline melalui release bundle terversi.
- Konfigurasi dan secret di luar repository.
- Migration gate, backup sebelum perubahan berisiko, health-check, rollback/forward-fix.
- Backup terenkripsi, restore drill, PITR bila disepakati, RPO/RTO dan disaster recovery.
- Monitoring aplikasi, database, queue, storage, uptime, security events, dan kapasitas.
- Runbook upgrade, patch, incident response, support, dan data retention.

Skrip deployment belum dibuat; dibuat setelah kontrak aplikasi dan environment ditetapkan.

## 14. Kualitas dan kriteria keberhasilan

- Tidak ada akses lintas tenant/unit yang tidak sah.
- Alur utama divalidasi oleh pengguna sekolah umum dan madrasah.
- Data historis dapat ditelusuri dan dikoreksi melalui prosedur sah.
- Proses sensitif memiliki audit trail.
- Proses asynchronous/integrasi aman terhadap retry dan duplikasi.
- UI konsisten, responsif, dan dapat diakses.
- Backup dapat dipulihkan melalui uji restore.
- Modul dapat dirilis bertahap tanpa merusak modul lain.
- Requirement dapat ditelusuri ke acceptance criteria dan test evidence.

## 15. Keputusan yang sudah diterima dan yang masih terbuka

### Sudah diterima
- PostgreSQL 18 sebagai database utama (ADR-006).
- Model foundation dan independent_provider (ADR-001).
- Shared database/shared schema sebagai baseline MVP dengan gerbang PoC (ADR-002).
- Baseline identity/membership/authorization default-deny (ADR-003; implementasi masih perlu PoC).
- Onboarding/verifikasi/entitlement unit sesuai ADR-004.

### Masih perlu validasi atau keputusan
- Final stack dan versi runtime/dependency.
- Prioritas MVP dan modul release pertama.
- Detail subscription, paket, harga, billing, trial, payment, overage.
- Detail domain model, logical/physical ERD, data dictionary dan lifecycle.
- Authorization matrix rinci dan support access workflow.
- API/event, auth/session, queue/cache, search, storage, notification.
- UX prototype, design tokens dan brand direction.
- Integrasi eksternal dan regulatory register.
- Deployment, observability, backup/restore, RPO/RTO, SLA dan support model.

## 16. Dokumen turunan dan cara melanjutkan

Master blueprint harus dibaca bersama [Blueprint Catalog](BLUEPRINT-CATALOG.md), [Project Progress Tracker](../00-governance/PROJECT-PROGRESS.md), requirements, database, security, design system, education domain, testing, operations, dan ADR.

**Next action saat ini:** audit dokumen repository dan lengkapi spesifikasi bisnis/proses/modul secara berurutan. Jangan mulai migration domain produksi atau implementasi modul sebelum Phase 1 dan gerbang PoC yang tercantum dalam tracker disetujui.

