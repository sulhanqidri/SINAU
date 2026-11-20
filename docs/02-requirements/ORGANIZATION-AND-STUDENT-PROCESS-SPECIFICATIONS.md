# Spesifikasi Proses Organisasi, Akademik Dasar, dan Peserta Didik

**Versi:** Draft 0.1.0  
**Tanggal:** 2026-11-18  
**Status:** Draft turunan; belum divalidasi stakeholder dan bukan kontrak implementasi final  
**Cakupan:** BP-ORG-01, BP-ORG-02, BP-STD-01, BP-STD-02  
**Rujukan:** [Business Process Map](BUSINESS-PROCESS-MAP.md), [Product Requirements](PRODUCT-REQUIREMENTS.md), [Domain Model](../03-database/DOMAIN-MODEL.md), [Platform/Tenant Process Specifications](PLATFORM-TENANT-PROCESS-SPECIFICATIONS.md), ADR-001 sampai ADR-004.

> Dokumen ini menguraikan proses dan kontrol bisnis. Format dokumen resmi, aturan kurikulum, struktur organisasi baku, formula kenaikan kelas, dokumen penerimaan, dan kebijakan retensi yang bergantung pada aturan pemerintah atau keputusan lembaga tetap harus diverifikasi. Contoh status dan alur di bawah merupakan baseline desain, bukan klaim regulasi.

## 1. Tujuan dan prinsip lintas proses

1. Profil pelanggan SaaS/tenant tidak sama dengan profil operasional education unit.
2. Struktur organisasi lembaga (jabatan, unit kerja, penanggung jawab) tidak sama dengan struktur akademik (tahun ajaran, semester, kelas, rombel, kurikulum).
3. Data siswa adalah identitas jangka panjang; enrollment adalah hubungan siswa dengan unit dan periode tertentu.
4. Siswa dapat memiliki beberapa enrollment historis, tetapi enrollment aktif yang saling bertentangan harus dicegah sesuai kebijakan.
5. Perubahan tahun ajaran, kurikulum, wali kelas, rombel, atau status siswa harus mempertahankan histori dan periode efektif.
6. Sekolah umum, madrasah, SMK/MAK, dan jenjang lain menggunakan konfigurasi/reference data yang sesuai; jangan hard-code satu struktur untuk semua.
7. Semua operasi memakai tenant dan unit context yang tervalidasi server-side. Tahun ajaran/periode harus eksplisit bila proses membutuhkannya.
8. Data pribadi siswa dan wali adalah data berisiko tinggi: minimisasi, akses berbasis kebutuhan, audit, dan pembatasan export wajib.
9. Import dan operasi massal harus memiliki preview, validasi, hasil per baris, idempotency, serta mekanisme koreksi.
10. Proses yang berdampak pada status resmi siswa memerlukan permission dan approval sesuai kebijakan unit.

## 2. Aktor dan swimlane

| Aktor | Peran proses | Batas kewenangan |
|---|---|---|
| Tenant administrator | Menyiapkan tenant dan menugaskan admin unit | Tidak otomatis berhak mengelola data siswa |
| Kepala sekolah/madrasah | Menyetujui struktur, penanggung jawab, dan keputusan siswa sesuai delegasi | Scope unit dan periode yang sah |
| Operator/TU | Mengelola profil lembaga, struktur organisasi, data induk dan enrollment | Tidak otomatis dapat menyetujui keputusan yang menjadi kewenangan kepala |
| Admin akademik/wakil kurikulum | Menyiapkan tahun ajaran, semester, kurikulum, dan referensi akademik | Scope unit/periode |
| Guru/wali kelas | Mengakses siswa/kelas yang ditugaskan | Tidak dapat mengubah identitas legal atau enrollment tanpa grant |
| Panitia penerimaan | Mengelola calon siswa dan hasil seleksi | Data calon dibatasi pada gelombang/penerimaan |
| Orang tua/wali | Memberikan data dan mengakses anak yang relasinya diverifikasi | Tidak otomatis menjadi pengambil keputusan akademik |
| Peserta didik | Memberikan data dan mengakses layanan miliknya sesuai kebijakan | Tidak dapat mengubah record resmi sendiri |
| Platform support/auditor | Bantuan/peninjauan terbatas | Tidak memiliki akses default ke data siswa |

Swimlane konseptual: Kepala/Operator/Admin Akademik → API dan policy engine → layanan referensi/penyimpanan → approval (bila diwajibkan) → audit/notifikasi. Import, scheduler, dan integrasi wajib menggunakan service identity terbatas dan tenant/unit context eksplisit.

## 3. BP-ORG-01 — Setup profil dan struktur lembaga

### 3.1 Tujuan, trigger, dan output

- **Tujuan:** menyiapkan identitas operasional education unit dan struktur tanggung jawab internal.
- **Trigger:** unit telah dibuat dan pengguna berwenang memulai konfigurasi, atau ada perubahan profil/organisasi.
- **Precondition:** tenant dan unit aktif/diizinkan onboarding; pengguna memiliki unit membership dan permission; unit context valid.
- **Output:** profil unit tervalidasi, struktur organisasi berversi/berperiode, jabatan/penugasan yang tercatat, dan audit.

### 3.2 Alur profil lembaga

1. Operator membuka profil unit dari konteks unit yang aktif.
2. Sistem memuat data yang sudah berasal dari onboarding dan menampilkan sumber serta status verifikasinya.
3. Operator melengkapi informasi operasional: nama tampilan/resmi sesuai sumber, alamat, kontak, zona waktu, logo, kanal komunikasi, dan metadata yang telah disetujui.
4. Sistem memvalidasi format, field wajib, panjang, referensi wilayah, dan identifier resmi tanpa mengasumsikan identifier wajib tersedia pada tahap ini.
5. Perubahan yang bersifat operasional dapat disimpan oleh role yang berwenang.
6. Perubahan identitas legal, identifier resmi, bentuk/jenjang, atau informasi yang memengaruhi verifikasi diarahkan ke workflow review; nilai lama tetap tercatat.
7. Kepala/unit approver menyetujui bila policy mengharuskan.
8. Sistem menerapkan perubahan sesuai effective date, mencatat audit, dan mengirim notifikasi kepada pihak terkait.

### 3.3 Alur struktur organisasi

1. Kepala/operator memilih periode berlaku struktur (misalnya mulai tanggal tertentu atau tahun ajaran tertentu bila kebijakan lembaga demikian).
2. Sistem menampilkan struktur aktif dan histori sebelumnya.
3. Pengguna menambah/mengubah unit kerja, jabatan, atasan, penanggung jawab, dan delegasi.
4. Sistem memeriksa duplikasi kode/nama dalam scope yang relevan, siklus pelaporan, tanggal efektif, dan konflik penugasan.
5. Perubahan disimpan sebagai draft.
6. Approver meninjau dampak dan menyetujui atau meminta perbaikan.
7. Struktur baru menjadi berlaku pada effective date; struktur lama ditutup masa berlakunya, tidak dihapus.
8. Assignment pengguna ke jabatan/organisasi diselaraskan tanpa otomatis memberikan permission aplikasi yang tidak disetujui.

### 3.4 Aturan bisnis

- BR-ORG-01-01: profil operasional dimiliki oleh education unit, bukan tenant.
- BR-ORG-01-02: data legal/identifier yang bersumber dari verification case tidak boleh diam-diam diganti melalui form profil biasa.
- BR-ORG-01-03: setiap perubahan atribut penting menyimpan actor, timestamp, alasan, sumber, dan nilai efektif; data sensitif tidak disalin ke log.
- BR-ORG-01-04: struktur organisasi dapat berubah sepanjang waktu; assignment harus memiliki valid_from/valid_to atau mekanisme histori setara.
- BR-ORG-01-05: jabatan struktural tidak otomatis sama dengan role/permission aplikasi. Pemetaan jabatan ke role harus eksplisit dan dapat dicabut.
- BR-ORG-01-06: seorang pengguna dapat memiliki lebih dari satu penugasan bila diizinkan, tetapi konflik kepentingan/approval diperiksa.
- BR-ORG-01-07: unit kerja dan jabatan tidak boleh digunakan sebagai jalan pintas untuk memperoleh akses lintas unit.
- BR-ORG-01-08: perubahan struktur yang telah dipakai dalam dokumen/transaksi historis tidak mengubah makna record lama.
- BR-ORG-01-09: penonaktifan jabatan/unit kerja harus memeriksa assignment aktif dan menyediakan reassign atau penutupan terencana.
- BR-ORG-01-10: logo dan file pendukung disimpan privat/terkontrol dengan validasi tipe, ukuran, dan malware policy.

### 3.5 State

| Aggregate | State | Transisi |
|---|---|---|
| Unit profile change | draft → submitted → approved / requires_changes / rejected → applied | Perubahan sensitif memerlukan approval |
| Organization structure version | draft → submitted → approved → scheduled → active → superseded | Versi aktif tidak ditimpa |
| Position/organization node | draft → active → inactive/archived | Tidak boleh menutup node dengan assignment aktif tanpa penyelesaian |
| Staff assignment | pending → active → ended/cancelled | Periode efektif dan permission tervalidasi |

### 3.6 Data konseptual

EducationUnit, UnitProfileVersion atau audit/version history, OrganizationNode, Position, OrganizationStructureVersion, Staff/Employee, OrganizationAssignment, ApprovalRequest, StoredFile, AuditEvent.

Belum diputuskan apakah organisasi internal memakai model tree generik, tabel unit kerja dan jabatan terpisah, atau gabungan. Logical ERD harus membandingkan kebutuhan multi-parent, hierarki, delegasi, dan periode efektif sebelum skema dipilih.

### 3.7 Acceptance criteria

- AC-ORG-01-01: pengguna hanya dapat membaca/mengubah profil unit yang menjadi scope grant-nya.
- AC-ORG-01-02: profil operasional tidak mengubah tenant legal identity atau verification status tanpa workflow.
- AC-ORG-01-03: perubahan sensitif dapat diajukan, ditinjau, disetujui/ditolak, dan diaudit.
- AC-ORG-01-04: struktur organisasi mendukung versi dan tanggal efektif.
- AC-ORG-01-05: histori struktur lama tetap dapat ditelusuri.
- AC-ORG-01-06: jabatan tidak otomatis memberikan permission aplikasi.
- AC-ORG-01-07: assignment tidak dapat melampaui periode node/jabatan yang berlaku.
- AC-ORG-01-08: file dan data profil tidak dapat diakses lintas tenant/unit.

### 3.8 Test minimum

1. Edit profil operasional dengan role yang tepat.
2. User tenant-level tanpa unit grant mencoba mengubah data siswa/profil unit.
3. Perubahan identifier legal memerlukan review.
4. Approval oleh pembuat sendiri (jika segregation-of-duties berlaku) ditolak.
5. Perubahan struktur dijadwalkan di masa depan dan aktif pada tanggal yang tepat.
6. Histori struktur tidak berubah setelah versi baru aktif.
7. Penutupan jabatan dengan assignment aktif ditolak atau mewajibkan reassign.
8. Assignment bertanggal tumpang tindih dan konflik delegasi.
9. Upload file tidak valid, terlalu besar, atau berbahaya.
10. Cross-tenant/unit IDOR dan export.

## 4. BP-ORG-02 — Setup kalender, tahun ajaran, semester, dan kurikulum

### 4.1 Tujuan dan prasyarat

- **Tujuan:** menyediakan kerangka waktu dan kurikulum yang menjadi referensi transaksi akademik unit.
- **Trigger:** unit mulai onboarding akademik atau admin akademik menyiapkan periode berikutnya.
- **Precondition:** profil unit cukup lengkap; admin akademik memiliki permission; education form/level teridentifikasi; reference catalog tersedia.
- **Output:** tahun ajaran, periode/semester, kalender akademik, versi kurikulum, struktur mata pelajaran dan aturan penerapan yang tervalidasi.

### 4.2 Alur tahun ajaran dan semester

1. Admin akademik memilih unit dan membuat tahun ajaran dengan label, tanggal mulai, tanggal akhir, serta zona waktu/kebijakan kalender.
2. Sistem memeriksa rentang tanggal, benturan dengan periode lain, dan aturan overlap yang diizinkan.
3. Admin membuat semester/term dan periode turunannya.
4. Admin memasukkan hari efektif, libur, kegiatan, ujian, dan tanggal penting sesuai kebutuhan lembaga.
5. Sistem menampilkan kalender dan ringkasan benturan.
6. Kepala/wakil kurikulum meninjau dan menyetujui sesuai policy.
7. Periode dipublikasikan/diaktifkan; transaksi akademik berikutnya harus memilih periode yang berlaku.
8. Perubahan setelah periode berjalan memerlukan revisi/versioning dan audit; bukan mengubah tanggal historis secara diam-diam.

### 4.3 Alur kurikulum dan struktur pembelajaran

1. Admin memilih kurikulum dari catalog atau membuat konfigurasi lokal yang diperbolehkan.
2. Sistem mencatat sumber/versi kurikulum, jenjang, bentuk pendidikan, program/konsentrasi bila relevan, dan effective period.
3. Admin menyusun struktur mata pelajaran/kelompok, alokasi atau beban belajar, serta pemetaan kelas/tingkat.
4. Sistem memvalidasi kombinasi kurikulum, unit, jenjang, program, dan periode.
5. Admin memetakan subject catalog ke mata pelajaran lokal tanpa membuat duplikasi tak terkendali.
6. Reviewer akademik meninjau perbedaan/pengecualian.
7. Kurikulum disahkan dan dipublikasikan untuk periode efektif.
8. Saat tahun ajaran baru, admin membuat versi penerapan baru atau menyalin konfigurasi dengan review; jangan menimpa versi yang sudah dipakai.

### 4.4 Variasi yang wajib didukung

- Sekolah umum dan madrasah memiliki konfigurasi yang dapat berbeda.
- SD/MI, SMP/MTs, SMA/MA, SMK/MAK tidak boleh diasumsikan memiliki struktur mapel dan pelaporan identik.
- SMK/MAK mungkin membutuhkan program/konsentrasi keahlian, praktik, dan pemetaan mitra/PKL; detailnya berada pada spesifikasi vokasi tersendiri.
- Kurikulum dan peraturan dapat berubah; sumber, versi, tanggal berlaku, serta keputusan lokal harus dicatat.
- Unit di bawah tenant foundation boleh memakai kurikulum, kalender, dan struktur akademik yang berbeda dari unit saudaranya.

### 4.5 Aturan bisnis

- BR-ORG-02-01: tahun ajaran dan kalender dimiliki oleh unit, bukan tenant.
- BR-ORG-02-02: periode akademik memiliki tanggal efektif dan validasi overlap yang eksplisit.
- BR-ORG-02-03: satu transaksi akademik harus terikat ke periode yang benar; periode tidak boleh ditebak dari tanggal browser.
- BR-ORG-02-04: kurikulum adalah versi yang memiliki scope jenjang/bentuk/program dan periode berlaku.
- BR-ORG-02-05: perubahan kurikulum tidak mengubah hasil belajar historis.
- BR-ORG-02-06: subject catalog/reference data dibedakan dari subject offering/configuration milik unit.
- BR-ORG-02-07: mata pelajaran dan struktur dapat berbeda per unit meskipun tenant sama.
- BR-ORG-02-08: kalender harus memperhitungkan zona waktu unit; tanggal akademik murni disimpan sebagai date.
- BR-ORG-02-09: periode yang sudah dipakai transaksi tidak dapat dihapus; koreksi menggunakan workflow dan audit.
- BR-ORG-02-10: aturan pemerintah hanya boleh ditandai wajib bila sumber resmi, versi, dan tanggal efektif telah diverifikasi.
- BR-ORG-02-11: kurikulum yang belum disahkan tidak boleh dipakai membuat transaksi akademik resmi.
- BR-ORG-02-12: perubahan massal kalender/kurikulum harus memiliki preview dampak dan mekanisme rollback atau compensating action.

### 4.6 State

| Aggregate | State | Transisi |
|---|---|---|
| Academic year | draft → review → approved → active → closed → archived | Tidak boleh ada dua periode aktif yang bertentangan menurut policy |
| Academic term | draft → approved → active → closed | Harus berada dalam rentang tahun ajaran |
| Academic calendar version | draft → approved → published → superseded | Versi lama tetap tersedia |
| Curriculum version | draft → review → approved → active → retired | Effective period wajib |
| Subject offering | draft → active → inactive | Referensi kurikulum dan periode valid |

### 4.7 Acceptance criteria

- AC-ORG-02-01: unit dapat mengelola tahun ajaran dan semester sendiri.
- AC-ORG-02-02: overlap periode mengikuti policy dan ditolak jika tidak diizinkan.
- AC-ORG-02-03: kalender memiliki tanggal efektif dan revisi historis.
- AC-ORG-02-04: kurikulum memiliki versi, sumber, jenjang, bentuk/program, dan periode efektif.
- AC-ORG-02-05: sekolah umum dan madrasah dapat memakai konfigurasi berbeda.
- AC-ORG-02-06: satu tenant dapat memiliki unit dengan kalender/kurikulum berbeda.
- AC-ORG-02-07: perubahan kurikulum tidak mengubah enrollment/nilai historis.
- AC-ORG-02-08: periode/kurikulum yang belum disetujui tidak dipakai pada transaksi resmi.

### 4.8 Test minimum

1. Membuat tahun ajaran dan dua semester valid.
2. Rentang tahun ajaran tumpang tindih.
3. Semester di luar rentang tahun ajaran.
4. Unit berbeda pada tenant sama memakai kalender berbeda.
5. Unit sekolah dan madrasah memakai kurikulum berbeda.
6. Kurikulum baru berlaku di masa depan tanpa mengubah nilai lama.
7. Perubahan kalender setelah presensi/jadwal dibuat.
8. Scheduler dan timezone boundary.
9. Reference catalog tidak valid atau versi kurikulum tidak berlaku.
10. User mencoba mengakses kalender unit lain.

## 5. BP-STD-01 — Registrasi siswa dan enrollment

### 5.1 Batas dengan PPDB

BP-ADM-01 mengelola calon peserta didik, pendaftaran, seleksi, dan keputusan penerimaan. BP-STD-01 dimulai dari siswa yang akan/ telah dinyatakan diterima atau didaftarkan melalui jalur yang sah, lalu membuat identitas siswa dan enrollment. Jika lembaga tidak menggunakan PPDB di SINAU, operator dapat melakukan registrasi langsung dengan approval yang sesuai. Jangan mencampur data calon pendaftar dengan siswa aktif tanpa transisi yang eksplisit.

### 5.2 Tujuan, trigger, dan output

- **Tujuan:** mencatat identitas peserta didik dan hubungan belajar pada unit/periode tertentu.
- **Trigger:** calon diterima/daftar ulang atau operator melakukan registrasi siswa langsung.
- **Precondition:** unit dan periode akademik tersedia; pengguna memiliki permission; enrollment target valid; data minimal dan dasar pemrosesan telah dikonfirmasi.
- **Output:** student profile, student enrollment, guardian relationship bila ada, kelas/rombel bila telah ditetapkan, dokumen pendukung privat, audit.

### 5.3 Alur utama

1. Operator memilih unit, tahun ajaran, dan jalur masuk.
2. Sistem mencari kemungkinan identitas siswa yang sudah ada menggunakan identifier yang sah dan minimisasi data.
3. Jika ditemukan kandidat duplikat, sistem menampilkan informasi minimum kepada operator berwenang untuk verifikasi; tidak otomatis menggabungkan record.
4. Operator membuat profil baru atau mengaitkan ke profil siswa yang telah diverifikasi.
5. Operator memasukkan data identitas, kontak, alamat, data pendidikan sebelumnya, kebutuhan administratif yang benar-benar diperlukan, dan dokumen sesuai policy.
6. Sistem memvalidasi field, format, referensi, duplikasi, persetujuan/otoritas wali bila dibutuhkan, dan kualitas data.
7. Operator membuat enrollment untuk unit dan tahun ajaran, termasuk tingkat/kelas/rombel bila penempatan sudah dilakukan.
8. Sistem memeriksa tidak ada enrollment aktif yang bertentangan pada unit/periode yang sama, serta validitas kelas/rombel.
9. Approval dilakukan oleh kepala/admin akademik bila policy mensyaratkan.
10. Sistem mengaktifkan enrollment pada tanggal efektif, mengirim konfirmasi, dan menulis audit.
11. Orang tua/wali ditautkan melalui relationship record terpisah; akun portal tidak otomatis dibuat atau diberi akses sebelum verifikasi hubungan dan invitation.

### 5.4 Identitas siswa dan duplikasi

- Identitas siswa tidak boleh dipaksakan unik global berdasarkan nama/tanggal lahir.
- NIS adalah identifier lokal unit/sekolah dan ruang lingkup keunikannya harus jelas.
- NISN atau identifier nasional lain hanya dipakai sesuai sumber resmi dan validasi yang telah ditentukan.
- Kesamaan nama bukan bukti bahwa dua record adalah orang yang sama.
- Merge/resolve duplicate harus menjadi workflow khusus dengan bukti, approval, audit, dan penanganan relasi seluruh enrollment.
- Jika siswa pindah unit/tenant, akses data historis tidak otomatis diberikan ke unit penerima.

### 5.5 Aturan bisnis

- BR-STD-01-01: student profile dipisahkan dari enrollment.
- BR-STD-01-02: enrollment selalu terkait tepat pada satu unit dan periode akademik yang jelas.
- BR-STD-01-03: student profile dapat memiliki beberapa enrollment historis pada unit berbeda.
- BR-STD-01-04: enrollment aktif yang saling bertentangan dicegah berdasarkan kebijakan status dan tanggal efektif.
- BR-STD-01-05: nomor induk lokal memiliki unique scope yang ditentukan (minimal unit + nomor + periode/kebijakan); jangan mengasumsikan global.
- BR-STD-01-06: NISN/identifier nasional boleh nullable bila belum tersedia; validasi format/keunikannya menunggu sumber otoritatif yang disahkan.
- BR-STD-01-07: data siswa tidak digabung otomatis berdasarkan fuzzy match.
- BR-STD-01-08: data wali adalah relasi terpisah dengan jenis hubungan, status verifikasi, periode berlaku, dan hak akses.
- BR-STD-01-09: wali tidak otomatis berwenang atas semua anak yang namanya tercantum; hubungan dan kewenangan harus diverifikasi.
- BR-STD-01-10: pembuatan enrollment dan assignment kelas/rombel harus memeriksa kapasitas/aturan penempatan yang berlaku.
- BR-STD-01-11: koreksi data identitas penting memerlukan alasan dan audit; field tertentu dapat memerlukan approval.
- BR-STD-01-12: import massal memiliki dry-run/preview, validasi per baris, idempotency, dan laporan hasil.
- BR-STD-01-13: akun login siswa/wali terpisah dari student/guardian profile; pembuatan akun tidak otomatis.
- BR-STD-01-14: data sensitif (kesehatan, kebutuhan dukungan, dokumen identitas) dibatasi dan tidak muncul pada daftar umum.

### 5.6 State

| Aggregate | State | Transisi |
|---|---|---|
| Student profile | provisional → verified → inactive/archived | Inactive tidak berarti enrollment historis hilang |
| Enrollment | draft → pending_approval → enrolled/active → completed/withdrawn/transferred | Tanggal efektif dan alasan wajib |
| Guardian relationship | pending_verification → verified → restricted/revoked/ended | Perlu bukti/otoritas dan histori |
| Class placement | unassigned → assigned → changed/ended | Perubahan dicatat sebagai histori penempatan |
| Import batch | uploaded → validating → preview_ready → committed/partially_failed/failed | Commit idempotent dan per baris terlacak |

Status final perlu diselaraskan dengan domain model dan kebijakan lembaga sebelum ERD logis.

### 5.7 Data konseptual

Student, Person (bila model identitas bersama diterima), StudentIdentifier, StudentEnrollment, EnrollmentStatusHistory, Guardian/Person, StudentGuardian, GuardianVerification, ClassGroup, EnrollmentClassPlacement, StoredFile, ImportBatch, ImportRow, ApprovalRequest, AuditEvent.

Data identitas minimal yang dibutuhkan harus ditetapkan berdasarkan use case. Jangan mengumpulkan NIK orang tua/siswa, data kesehatan, agama, atau data sensitif lain tanpa dasar kebutuhan dan kebijakan yang sah.

### 5.8 Acceptance criteria

- AC-STD-01-01: operator dapat membuat student profile dan enrollment secara terpisah.
- AC-STD-01-02: enrollment terikat pada unit dan tahun ajaran yang benar.
- AC-STD-01-03: satu siswa dapat memiliki histori enrollment lintas unit tanpa mencampur akses.
- AC-STD-01-04: duplikasi tidak otomatis di-merge.
- AC-STD-01-05: nomor induk lokal mengikuti unique scope yang disetujui.
- AC-STD-01-06: wali memiliki relasi dan verifikasi terpisah.
- AC-STD-01-07: akun wali/siswa tidak otomatis aktif tanpa proses invitation/verification.
- AC-STD-01-08: import memiliki preview, error per baris, dan aman diulang.
- AC-STD-01-09: data sensitif hanya terlihat oleh permission khusus.
- AC-STD-01-10: semua perubahan identitas/enrollment penting dapat diaudit.

### 5.9 Test minimum

1. Registrasi siswa baru dari proses penerimaan.
2. Registrasi langsung tanpa PPDB dengan approval sesuai policy.
3. Student profile yang sudah ada dan enrollment baru pada unit berbeda.
4. Nama sama tetapi dua siswa berbeda.
5. Duplicate identifier yang sah.
6. Enrollment aktif ganda pada periode sama.
7. Enrollment dengan tahun ajaran tidak aktif/di luar rentang.
8. Penempatan rombel penuh atau tidak sesuai jenjang.
9. Guardian relation belum diverifikasi dan akses portal ditolak.
10. Import batch diulang, sebagian gagal, dan rollback/repair.
11. Cross-tenant/unit IDOR untuk profil, dokumen, export, dan API.
12. User mencoba membaca field sensitif tanpa permission.

## 6. BP-STD-02 — Mutasi, cuti, nonaktif, kenaikan kelas, kelulusan, dan alumni

> **Scope release:** bagian ini adalah spesifikasi lifecycle lanjutan. MVP hanya memerlukan status enrollment aktif/nonaktif, perubahan dasar dengan alasan/tanggal efektif dan histori, serta penutupan enrollment bila diperlukan. Transfer lintas unit, cuti formal, promosi/kenaikan kelas otomatis, kelulusan, dan alumni adalah roadmap/post-MVP.

### 6.1 Tujuan dan trigger

- **Tujuan:** mengelola perjalanan status siswa setelah enrollment, mempertahankan riwayat pendidikan dan dasar keputusan.
- **Trigger:** permohonan mutasi/keluar/cuti, keputusan kenaikan kelas, kelulusan, perubahan status, atau koreksi administratif.
- **Precondition:** siswa dan enrollment teridentifikasi; periode dan kewenangan jelas; dokumen/approval tersedia sesuai policy.

### 6.2 Alur mutasi keluar/pindah

1. Wali/siswa/operator mengajukan mutasi sesuai hak dan prosedur lembaga.
2. Operator memeriksa identitas, status enrollment, kewajiban administrasi, dan dokumen yang diwajibkan.
3. Kepala/pejabat berwenang meninjau dan menyetujui/menolak.
4. Sistem mencatat tanggal efektif, alasan, tujuan bila boleh disimpan, nomor dokumen, dan status.
5. Enrollment lama diakhiri sebagai transferred/withdrawn sesuai keputusan.
6. Dokumen/riwayat yang dapat diberikan disiapkan melalui export terbatas dan tercatat.
7. Enrollment pada unit tujuan tidak dibuat otomatis kecuali ada proses transfer terintegrasi yang kelak disetujui.
8. Akses portal dan wali disesuaikan pada tanggal efektif tanpa menghapus histori.

### 6.3 Alur cuti/nonaktif

1. Permohonan atau dasar keputusan dicatat.
2. Operator memeriksa aturan unit dan status siswa.
3. Approver memutuskan status, rentang tanggal, dan syarat kembali.
4. Sistem menutup/menangguhkan enrollment sesuai status yang dipilih dan membatasi transaksi akademik yang tidak relevan.
5. Saat aktif kembali, sistem membuat transisi/record lanjutan, bukan menghapus periode nonaktif.

Perbedaan status cuti, nonaktif, keluar, dan drop-out harus ditetapkan oleh kebijakan lembaga dan tidak boleh digabung menjadi satu label tanpa definisi.

### 6.4 Alur kenaikan kelas dan kelulusan

1. Admin akademik memilih periode sumber dan periode tujuan.
2. Sistem memeriksa nilai/asesmen, presensi, status administrasi, dan prasyarat lain yang telah ditetapkan lembaga.
3. Sistem membuat daftar calon keputusan (naik kelas, tinggal kelas, lulus, perlu review) tanpa langsung mengubah status.
4. Wali kelas/guru memberi rekomendasi sesuai kewenangan.
5. Kepala/dewan/pejabat yang ditentukan melakukan review dan keputusan.
6. Sistem menyimpan keputusan individual, alasan/kategori, approver, tanggal efektif, dan versi aturan yang digunakan.
7. Setelah disahkan, sistem membuat enrollment/placement periode berikutnya untuk siswa yang naik kelas, atau menutup enrollment dan membuat status alumni untuk yang lulus.
8. Sistem menghasilkan dokumen/rekap sesuai template dan permission.
9. Koreksi keputusan setelah pengesahan menggunakan workflow khusus dengan audit; hasil lama tetap dapat ditelusuri.

### 6.5 Alur alumni

- Alumni merupakan status/relasi historis setelah enrollment selesai karena kelulusan; bukan penghapusan student profile.
- Unit dapat menyimpan informasi kontak alumni jika ada tujuan dan dasar yang sah.
- Alumni tidak memiliki akses portal operasional secara otomatis.
- Akses alumni, tracer study, dan komunikasi alumni adalah fitur terpisah yang harus masuk scope dan persetujuan.
- Retensi data dan penghapusan/anonymization harus mengikuti kebijakan yang kelak ditetapkan.

### 6.6 Aturan bisnis

- BR-STD-02-01: status siswa dan status enrollment adalah dimensi berbeda.
- BR-STD-02-02: setiap transisi memiliki tanggal efektif, alasan, actor, approval bila diwajibkan, dan audit.
- BR-STD-02-03: mutasi keluar menutup enrollment sumber; tidak memindahkan data lintas tenant secara otomatis.
- BR-STD-02-04: unit tujuan hanya memperoleh data melalui transfer/export yang sah dan disetujui.
- BR-STD-02-05: cuti/nonaktif mempertahankan histori dan tidak menghapus nilai/presensi lama.
- BR-STD-02-06: keputusan kenaikan kelas/kelulusan tidak dilakukan hanya oleh scheduler; perlu approval manusia.
- BR-STD-02-07: hasil batch kenaikan kelas harus memiliki preview, exception list, approval, idempotency, dan hasil per siswa.
- BR-STD-02-08: siswa yang lulus tetap memiliki student profile dan histori enrollment.
- BR-STD-02-09: koreksi keputusan resmi tidak menimpa keputusan lama; buat reversal/correction record.
- BR-STD-02-10: penutupan enrollment harus memperhitungkan nilai, rapor, dokumen, pinjaman aset/perpustakaan, dan kewajiban yang relevan tanpa membuka data lintas domain secara berlebihan.
- BR-STD-02-11: akses wali/siswa berakhir atau berubah berdasarkan relasi, enrollment, dan policy; tidak hanya berdasarkan status akun.
- BR-STD-02-12: data alumni dan data siswa aktif harus dibatasi sesuai purpose dan retention.

### 6.7 State konseptual

| Aggregate | State | Transisi |
|---|---|---|
| Enrollment | enrolled → on_leave / inactive / transferred / withdrawn / completed | Transisi berdasar keputusan dan tanggal efektif |
| Student lifecycle | prospective → active_student → inactive_student / graduated_alumni / deceased (bila kebijakan dan kebutuhan sah) | Status profil tidak menggantikan histori enrollment |
| Promotion decision | draft → reviewed → approved → applied / corrected / revoked | Approval dan audit wajib |
| Transfer request | submitted → under_review → approved/rejected → completed/cancelled | Bukti dan dokumen sesuai policy |
| Alumni relationship | not_alumni → alumni → archived | Tidak otomatis memberi login |

Istilah dan state final harus diselaraskan dengan istilah resmi dan praktik sekolah/madrasah; jangan mengimplementasikan label sensitif tanpa definisi dan kebutuhan yang disetujui.

### 6.8 Acceptance criteria

- AC-STD-02-01: mutasi mengakhiri enrollment lama dengan tanggal/alasan dan tidak menghapus histori.
- AC-STD-02-02: export/transfer data memerlukan permission, tujuan, dan audit.
- AC-STD-02-03: cuti/nonaktif dapat dicatat dengan rentang waktu dan alur kembali.
- AC-STD-02-04: kenaikan kelas memiliki preview, rekomendasi, approval, dan keputusan per siswa.
- AC-STD-02-05: batch promotion aman diulang dan tidak membuat enrollment ganda.
- AC-STD-02-06: kelulusan menutup enrollment aktif dan mempertahankan student profile/histori.
- AC-STD-02-07: koreksi keputusan resmi mempertahankan jejak keputusan awal.
- AC-STD-02-08: portal siswa/wali mengikuti status enrollment dan hubungan yang sah.
- AC-STD-02-09: data alumni tidak dapat diakses secara luas tanpa permission/purpose.
- AC-STD-02-10: tenant/unit isolation berlaku untuk semua alur, file, report, export, dan job.

### 6.9 Test minimum

1. Mutasi keluar dengan approval dan tanggal efektif.
2. Transfer ditolak dan enrollment tetap aktif.
3. Export dokumen tanpa permission ditolak.
4. Cuti dengan tanggal mulai/akhir dan reaktivasi.
5. Nonaktif karena alasan administratif tanpa menghapus histori.
6. Kenaikan kelas dengan data belum lengkap masuk exception list.
7. Dua approver atau konflik kepentingan.
8. Batch promotion diulang tanpa enrollment duplikat.
9. Kelulusan dan pembentukan status alumni.
10. Koreksi keputusan kelulusan dengan audit.
11. Wali yang hubungan/otoritasnya berakhir kehilangan akses.
12. Cross-tenant access, export, background job, dan file.

## 7. Authorization baseline lintas proses

| Aksi | Tenant admin | Kepala unit | Operator/TU | Admin akademik | Guru/wali kelas | Wali/siswa |
|---|---|---|---|---|---|---|
| Edit profil unit operasional | Hanya jika diberi unit grant | Ya sesuai policy | Ya sesuai permission | Tidak default | Tidak | Tidak |
| Ubah identitas legal/identifier | Tidak otomatis | Submit/approve sesuai workflow | Submit | Tidak | Tidak | Tidak |
| Kelola struktur organisasi | Tidak otomatis | Approve/kelola | Kelola sesuai grant | Baca bila relevan | Tidak | Tidak |
| Setup kalender/kurikulum | Tidak otomatis | Approve | Tidak default | Kelola | Baca sesuai assignment | Baca informasi yang dipublikasikan |
| Buat student profile | Tidak otomatis | Approve bila policy | Ya | Baca sesuai kebutuhan | Terbatas | Tidak |
| Buat enrollment | Tidak otomatis | Approve bila policy | Ya | Review/approve bila didelegasikan | Tidak default | Ajukan/konfirmasi bila disediakan |
| Mutasi/kelulusan | Tidak otomatis | Approve | Proses administrasi | Rekomendasi/review | Rekomendasi sesuai tugas | Ajukan/lihat status sesuai policy |
| Baca data sensitif siswa | Tidak otomatis | Need-to-know | Need-to-know | Need-to-know | Need-to-know untuk siswa yang ditugaskan | Data anak/milik sendiri yang diizinkan |

Semua permission harus diuji pada API dan background job, bukan hanya disembunyikan pada UI. Jabatan organisasi bukan grant aplikasi otomatis. Hak wali ditentukan melalui relasi terverifikasi dan policy.

## 8. API, event, dan integrasi konseptual

Nama endpoint final menunggu API blueprint. Operasi yang diperlukan:
- unit profile read/update dan submit/review perubahan sensitif;
- organization structure version create/review/publish;
- staff organization assignment create/end;
- academic year/term/calendar create/review/publish/close;
- curriculum version create/review/publish/retire;
- subject catalog mapping dan unit subject offering;
- student search/create/update/resolve-duplicate;
- guardian relationship create/verify/revoke;
- enrollment create/approve/activate/withdraw/transfer;
- promotion batch preview/approve/apply;
- graduation decision and correction;
- student record export with purpose/approval.

Event konseptual:
- `unit.profile.changed`
- `organization.structure.published`
- `organization.assignment.changed`
- `academic_year.activated`, `academic_year.closed`
- `academic_calendar.published`
- `curriculum.published`
- `student.created`, `student.updated`
- `guardian.relationship.verified`, `guardian.relationship.revoked`
- `student.enrollment.created`, `student.enrollment.activated`, `student.enrollment.ended`
- `student.transfer.approved`
- `student.promotion.approved`, `student.graduated`

Setiap event memiliki event ID, schema version, aggregate ID, tenant/unit context, occurred_at, actor/service identity, correlation ID, dan idempotency strategy. Hindari payload yang membawa data siswa sensitif; gunakan reference aman dan otorisasi saat consumer mengambil detail.

## 9. Screen inventory awal

1. Profil unit dan status verifikasi field.
2. Riwayat perubahan profil dan approval.
3. Struktur organisasi visual/list dengan versi dan effective date.
4. Jabatan/penugasan dan konflik periode.
5. Wizard tahun ajaran dan semester.
6. Kalender akademik dan event.
7. Catalog kurikulum dan konfigurasi unit.
8. Struktur mapel/kelompok/program serta pemetaan subject.
9. Daftar siswa dengan filter unit/periode dan akses terbatas.
10. Form profil siswa dan dokumen privat.
11. Pencarian kemungkinan duplikat dan resolusi manual.
12. Relasi orang tua/wali dan verifikasi.
13. Enrollment dan penempatan kelas/rombel.
14. Import siswa: upload, mapping, preview, error per baris, commit.
15. Detail lifecycle siswa, mutasi/cuti/nonaktif.
16. Preview kenaikan kelas, exception, rekomendasi, approval, dan hasil.
17. Kelulusan/alumni dan koreksi keputusan.
18. Riwayat audit dan export sesuai permission.

Semua layar memiliki loading, empty, validation error, permission denied, retry, confirmation untuk tindakan berisiko, serta tampilan responsif.

## 10. Traceability awal

| Process | Requirement group | Data/domain | Permission scope | Test family |
|---|---|---|---|---|
| BP-ORG-01 | UNIT-PROFILE/ORG | EducationUnit, OrganizationNode, Position, Assignment, Audit | Unit-scoped | Profile, approval, history, IDOR |
| BP-ORG-02 | ACADEMIC-CALENDAR/CURRICULUM | AcademicYear, AcademicTerm, CalendarVersion, CurriculumVersion, SubjectOffering | Unit + period | Date boundary, versioning, variant |
| BP-STD-01 | STUDENT/ENROLLMENT | Student, Identifier, Enrollment, GuardianRelation, ClassPlacement | Unit + period + relationship | Duplicate, import, privacy, isolation |
| BP-STD-02 | STUDENT-LIFECYCLE | EnrollmentHistory, Transfer, PromotionDecision, Graduation, Alumni | Unit + approval | State transition, batch idempotency, export |

Requirement IDs final harus disinkronkan dengan SRS/acceptance register sebelum menjadi kontrak stabil.

## 11. Keputusan terbuka

| ID | Pertanyaan | Dampak | Status |
|---|---|---|---|
| OPEN-ORG-01 | Field profil wajib per bentuk/jenjang dan sumber referensi wilayah | Form, validasi, import | Open |
| OPEN-ORG-02 | Struktur organisasi baku atau fleksibel; multi-parent/delegasi | Domain model dan UX | Open |
| OPEN-ORG-03 | Apakah jabatan tertentu memerlukan approval dua pihak/segregation | Authorization | Open |
| OPEN-ORG-04 | Zona waktu unit dan definisi kalender akademik efektif | Scheduler dan periode | Open |
| OPEN-ORG-05 | Sumber resmi dan versi kurikulum/struktur mapel tiap bentuk/jenjang | Catalog dan compliance | Open |
| OPEN-ORG-06 | Model subject catalog nasional vs lokal dan kode referensi | ERD dan import | Open |
| OPEN-STD-01 | Field identitas siswa minimum per jenjang dan kebutuhan lembaga | Privacy dan UX | Open |
| OPEN-STD-02 | Identifier siswa: NIS, NISN, ruang lingkup unik dan validasi resmi | Deduplication dan data integrity | Open |
| OPEN-STD-03 | Definisi enrollment aktif, cuti, nonaktif, keluar, dan overlap lintas unit | State machine | Open |
| OPEN-STD-04 | Dokumen wajib dan approval untuk registrasi/mutasi | Workflow | Open |
| OPEN-STD-05 | Bukti relasi wali dan aturan custody/otoritas akses | Privacy dan portal | Open |
| OPEN-STD-06 | Kebijakan merge duplicate dan kewenangan final | Data integrity | Open |
| OPEN-STD-07 | Formula/prasyarat kenaikan kelas dan keputusan kelulusan per jenis lembaga | Academic rules | Open |
| OPEN-STD-08 | Retensi data siswa/alumni dan export ke unit tujuan | Legal/privacy | Open |
| OPEN-STD-09 | Apakah siswa/wali portal masuk MVP atau release berikutnya | Scope dan auth | Open |
| OPEN-STD-10 | Mekanisme penerimaan: integrasi BP-ADM-01 atau registrasi langsung | Process boundary | Open |

## 12. Gerbang sebelum implementasi

Jangan membuat migration, endpoint produksi, atau UI final dari dokumen ini sebelum:
1. Field minimum dan sumber reference disepakati.
2. State machine enrollment dan student lifecycle disetujui.
3. Aturan kurikulum/kalender yang dipakai memiliki sumber dan tanggal efektif.
4. Matriks akses data siswa/wali disetujui dengan prinsip minimisasi.
5. Kebijakan duplikasi, mutasi, promosi, kelulusan, retensi, dan export diputuskan.
6. Logical ERD, data dictionary, permission matrix, dan test traceability direview.
7. Perwakilan sekolah umum dan madrasah memvalidasi skenario masing-masing.
8. Product owner menerima baseline secara eksplisit.

**Status akhir dokumen: Draft 0.1.0.** Dokumen ini memperjelas kebutuhan dan pertanyaan; bukan bukti bahwa fitur sudah dibangun atau bahwa aturan eksternal telah diverifikasi.


## 13. Batas lifecycle siswa untuk MVP (remediasi AUD-06)

### 13.1 Minimum MVP

BP-STD-01 dan bagian minimum BP-STD-02 harus mendukung:
- StudentProfile terpisah dari StudentEnrollment; satu identitas siswa dapat memiliki riwayat enrollment sesuai kebijakan.
- Enrollment terikat ke tenant, education unit, tahun ajaran/periode, dan rombel bila sudah ditetapkan.
- Status enrollment dasar active/inactive atau state minimal setara yang disepakati, dengan actor, reason, effective date, dan audit.
- Penutupan enrollment jika siswa keluar dari unit atau hubungan belajar harus dihentikan; record lama tidak dihapus.
- Perubahan status dasar tidak menghapus presensi, nilai, dokumen, atau histori akademik yang terkait.
- Koreksi data/status memiliki jejak perubahan dan permission yang jelas.
- Registrasi langsung siswa tanpa PPDB tetap didukung oleh BP-STD-01; ini bukan implementasi workflow PPDB BP-ADM-01.

### 13.2 Roadmap / post-MVP kecuali change request

- Transfer lintas unit/tenant dan orkestrasi ekspor data siswa.
- Cuti formal dengan workflow, pengajuan, approval, dan reaktivasi.
- Kenaikan kelas/promosi massal dengan rule engine, preview, exception list, dan approval.
- Workflow kelulusan formal dan penerbitan dokumen kelulusan.
- Lifecycle alumni, tracer study, portal alumni, dan komunikasi alumni.
- Integrasi pemerintah atau sistem pendidikan eksternal untuk mutasi/kelulusan.

Transfer data siswa lintas unit/tenant tidak boleh disamakan dengan menutup enrollment sumber. Setiap transfer membutuhkan legal basis, consent/authority, minimisasi, keputusan data disposition, dan audit. Jangan membuat enrollment tujuan otomatis pada MVP.

### 13.3 Acceptance criteria tambahan

- AC-STD-SCOPE-01: MVP dapat membuat dan mempertahankan StudentProfile serta StudentEnrollment terpisah.
- AC-STD-SCOPE-02: perubahan status dasar mencatat reason, effective date, actor, dan audit.
- AC-STD-SCOPE-03: penutupan enrollment tidak menghapus histori presensi/nilai/dokumen.
- AC-STD-SCOPE-04: registrasi langsung tidak bergantung pada BP-ADM-01.
- AC-STD-SCOPE-05: transfer lintas unit, cuti formal, promosi massal, kelulusan formal, dan alumni tidak menjadi syarat MVP tanpa change request.
- AC-STD-SCOPE-06: operasi lifecycle dasar tenant/unit scoped dan tidak membocorkan data lintas unit.

Test minimum tambahan:
1. Registrasi siswa langsung dan enrollment tanpa membuat admission application.
2. Menonaktifkan/menutup enrollment dengan tanggal efektif dan alasan.
3. Histori presensi/nilai tetap mengacu ke enrollment lama setelah ditutup.
4. Pembuatan enrollment baru tidak menimpa enrollment sebelumnya.
5. Endpoint transfer/mutasi lanjutan tidak tersedia sebagai fitur MVP tanpa approval scope.
6. Cross-tenant/unit access terhadap profile dan enrollment ditolak.
