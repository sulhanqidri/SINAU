# SINAU — Spesifikasi Proses PPDB dan Human Resources

**ID dokumen:** BP-ADM-HR-001  
**Versi:** 0.1.0 — Draft untuk validasi  
**Tanggal:** 2026-11-18  
**Status:** Draft; belum disetujui stakeholder dan bukan izin implementasi  
**Pemilik keputusan:** Product owner SINAU  
**Prasyarat:** BP-ORG-01/02, BP-STD-01/02, BP-ACA-01, serta tenant/unit/membership baseline  
**Peta induk:** [Business Process Map](BUSINESS-PROCESS-MAP.md)  
**Katalog:** [Blueprint Catalog](../01-blueprint/BLUEPRINT-CATALOG.md)  
**Tracker:** [Project Progress](../00-governance/PROJECT-PROGRESS.md)

> Dokumen ini menguraikan proses penerimaan peserta didik baru (PPDB) dan pengelolaan pegawai/guru. Ketentuan seleksi, kuota, afirmasi, zonasi, dokumen wajib, masa simpan, hubungan kerja, beban kerja, dan pelaporan harus diverifikasi terhadap peraturan resmi serta kebijakan masing-masing unit. Contoh alur bukan penetapan kebijakan nasional atau keputusan MVP.

## 1. Tujuan dan ruang lingkup

### 1.1 Tujuan
- Menetapkan lifecycle calon peserta didik dari pendaftaran sampai keputusan penerimaan, daftar ulang, dan pembentukan enrollment.
- Menjamin proses seleksi dapat dijelaskan, diaudit, dan tidak membocorkan data pendaftar.
- Memisahkan data calon peserta didik, identitas student profile, dan enrollment aktif.
- Menetapkan lifecycle pegawai dari pencatatan identitas/riwayat kerja sampai penempatan, penugasan, perubahan, dan akhir hubungan kerja.
- Memisahkan status kepegawaian, assignment operasional, dan permission aplikasi.
- Menyediakan baseline acceptance criteria, test, data, authorization, API/event, dan keputusan terbuka.

### 1.2 Termasuk
- Konfigurasi gelombang PPDB, jalur, kuota, persyaratan, formulir, dan kalender.
- Pendaftaran calon siswa, dokumen, verifikasi, seleksi, ranking bila sah, keputusan, pengumuman privat, daftar ulang, pembatalan, daftar tunggu.
- Deteksi kemungkinan duplikasi, pencocokan student profile, dan konversi menjadi enrollment.
- Data induk pegawai, identitas, kontak, dokumen, status kerja, unit penempatan, jabatan, kompetensi/kualifikasi yang relevan.
- Kontrak/masa kerja dan riwayat penugasan jika disetujui untuk cakupan produk.
- Assignment guru, mata pelajaran, rombel, wali kelas, dan beban kerja per periode.
- Perubahan penempatan, mutasi, cuti/nonaktif, akhir hubungan kerja, dan pencabutan akses.
- Audit, import/export terbatas, laporan, dan notifikasi terkait.

### 1.3 Tidak otomatis termasuk
- Integrasi PPDB pemerintah/daerah atau sinkronisasi dengan sistem eksternal tertentu.
- Pembayaran biaya pendaftaran atau daftar ulang, payment gateway, dan akuntansi penerimaan.
- Algoritma seleksi otomatis yang menentukan nasib pendaftar tanpa review manusia.
- Tes daring, proctoring, psikometri, pengenalan wajah, biometrik, dan penilaian otomatis.
- Payroll, pajak, BPJS, absensi pegawai, cuti terperinci, penilaian kinerja, rekrutmen lengkap, dan HRIS penuh.
- Pengelolaan dokumen kepegawaian berisiko tinggi tanpa kebijakan retensi dan kontrol akses yang disetujui.

## 2. Prinsip dan invarian

1. **Scope:** setiap pendaftaran dan record HR dimiliki tenant/unit yang jelas. Unit tujuan harus eksplisit; tenant membership tidak memberi akses ke seluruh unit.
2. **Separation of concerns:** Applicant/AdmissionApplication bukan StudentProfile; StudentProfile bukan Enrollment. EmployeeProfile bukan UserAccount; EmploymentStatus bukan ApplicationRole.
3. **Konversi terkontrol:** pendaftar diterima tidak otomatis menjadi siswa aktif sebelum daftar ulang dan persyaratan konversi terpenuhi.
4. **Tidak ada duplikasi otomatis:** pencocokan identitas menghasilkan kandidat duplikasi untuk review; sistem tidak menggabungkan profil secara otomatis.
5. **Effective dating:** keputusan, penempatan, assignment, kontrak, dan status memiliki tanggal efektif serta histori.
6. **Fairness:** kriteria seleksi harus dipublikasikan sebelum proses berjalan, konsisten untuk satu jalur/gelombang, dan perubahan harus disetujui serta diaudit.
7. **Human oversight:** hasil seleksi, pengecualian kuota, keberatan, koreksi identitas, dan keputusan kerja yang berdampak penting memerlukan pejabat berwenang.
8. **Minimization:** hanya kumpulkan data dan dokumen yang benar-benar diperlukan. Data sensitif tidak boleh diminta tanpa dasar, tujuan, retensi, dan kontrol yang jelas.
9. **Private by default:** dokumen pendaftar dan pegawai disimpan privat; URL publik permanen dilarang.
10. **Role separation:** panitia PPDB, HR, kepala, guru, operator, dan admin aplikasi memiliki grant berbeda; status pegawai tidak otomatis memberikan akses.
11. **Auditability:** keputusan, perubahan kriteria, skor, review, approval, ekspor, dan akses istimewa dapat ditelusuri.
12. **No silent overwrite:** koreksi menyimpan nilai lama/baru, alasan, actor, timestamp, dan approval sesuai kebijakan.
13. **Idempotency:** submit formulir, import, webhook, conversion, invitation, dan job retry tidak membuat record ganda.
14. **Historical integrity:** perubahan unit, kelas, jabatan, atau assignment tidak mengubah dokumen penerimaan dan transaksi akademik historis.
15. **Policy versioning:** kriteria seleksi, formulir, dan aturan konversi diberi versi; hasil historis mengacu pada versi yang digunakan saat keputusan dibuat.
16. **Data lifecycle:** masa simpan, legal hold, penghapusan, dan anonimisasi ditentukan oleh kebijakan yang sah; jangan menghapus otomatis berdasarkan asumsi.

## 3. Aktor dan batas kewenangan

| Aktor | Tanggung jawab | Batas dasar |
|---|---|---|
| Kepala unit | Menetapkan kebijakan dan mengesahkan hasil sesuai delegasi | Tidak harus mengakses dokumen sensitif tanpa kebutuhan |
| Admin PPDB/panitia | Mengelola gelombang, formulir, verifikasi, seleksi | Hanya unit dan gelombang yang ditugaskan |
| Verifikator dokumen | Memeriksa kelengkapan/keabsahan administratif | Tidak otomatis mengubah skor atau keputusan |
| Reviewer seleksi | Menilai sesuai kriteria dan memberi rekomendasi | Konflik kepentingan harus dideklarasikan |
| Bendahara | Memverifikasi pembayaran bila modul keuangan terintegrasi | Tidak otomatis melihat skor/berkas seleksi |
| Calon peserta didik | Mengisi dan memantau pendaftaran sendiri | Tidak dapat melihat pendaftar lain |
| Orang tua/wali pendaftar | Mengisi/memantau atas dasar relasi/otorisasi yang sah | Relasi perlu diverifikasi dan dapat berbeda menurut usia/kebijakan |
| HR/kepegawaian | Mengelola profil pegawai dan dokumen kerja | Tidak otomatis memberi permission aplikasi |
| Kepala/pejabat SDM | Menyetujui status dan penempatan pegawai | Approval sesuai matriks |
| Admin akademik | Menetapkan kebutuhan pengajar dan assignment akademik | Tidak mengubah dokumen HR yang tidak relevan |
| Guru/pegawai | Melihat data/assignment sendiri sesuai kebijakan | Tidak melihat data HR rekan kerja |
| Admin tenant/foundation | Mengelola keanggotaan lintas unit sesuai grant | Tidak otomatis melihat berkas PPDB/HR semua unit |
| Platform support | Dukungan teknis terbatas | Break-glass, justifikasi, approval, dan audit |

Pemisahan tugas (segregation of duties) harus dapat dikonfigurasi. Pengguna yang membuat kriteria/keputusan tidak boleh otomatis menjadi satu-satunya approver jika kebijakan mengharuskan pemeriksaan independen.

## 4. BP-ADM-01 — PPDB / penerimaan peserta didik

### 4.1 Tujuan, pemicu, hasil
**Tujuan:** mengelola penerimaan peserta didik secara terstruktur, adil, transparan, dan dapat diaudit.  
**Pemicu:** unit membuka penerimaan untuk tahun ajaran/gelombang tertentu.  
**Hasil:** application record dengan status akhir, keputusan yang disahkan, serta enrollment bila calon memenuhi daftar ulang dan persyaratan konversi.

### 4.2 Prasyarat
- Unit pendidikan aktif dan pengguna berada dalam scope unit.
- Tahun ajaran/periode penerimaan dan tanggal pendaftaran ditetapkan.
- Kepala/unit mengesahkan daya tampung, jalur, persyaratan, kriteria, jadwal, dan mekanisme keberatan.
- Privacy notice, consent/acknowledgement, tujuan pemrosesan, akses dokumen, serta retention policy disetujui.
- Penanggung jawab dan approver setiap tahap ditentukan.
- Jika biaya pendaftaran digunakan, modul keuangan dan rekonsiliasi telah ditentukan sebagai dependency terpisah.

### 4.3 Konfigurasi gelombang dan jalur
1. Admin PPDB membuat draft admission cycle untuk unit dan tahun ajaran target.
2. Admin mengisi nama gelombang, tanggal mulai/tutup, jalur, kuota, persyaratan, daftar dokumen, formulir, tahapan seleksi, dan tanggal pengumuman.
3. Setiap jalur memiliki eligibility criteria dan aturan seleksi yang terdefinisi.
4. Sistem memvalidasi jumlah kuota, rentang tanggal, field wajib, versi kebijakan, dan konflik antar gelombang.
5. Kepala/pejabat berwenang mereview dan mengesahkan konfigurasi.
6. Sistem menerbitkan versi konfigurasi; perubahan setelah pendaftaran dibuka memerlukan amendment, alasan, dampak, dan persetujuan.
7. Informasi publik hanya menampilkan informasi yang memang boleh diumumkan; data internal dan kuota sensitif tidak terekspos tanpa keputusan.

### 4.4 Alur pendaftaran utama
1. Calon siswa atau wali membuka portal penerimaan unit dan memilih gelombang/jalur yang tersedia.
2. Sistem menampilkan privacy notice, ketentuan, persyaratan, jadwal, dan penjelasan proses.
3. Pendaftar membuat akun/identitas pendaftaran dengan verifikasi kanal kontak sesuai kebijakan.
4. Pendaftar mengisi formulir bertahap, menyimpan draft, dan mengunggah dokumen yang diwajibkan.
5. Sistem memberi application number yang unik dalam scope kebijakan; nomor tidak boleh mengungkap data pribadi.
6. Pendaftar meninjau ringkasan dan menyatakan data benar sebelum submit.
7. Server memvalidasi field, format dokumen, tanggal, eligibility dasar, batas waktu, dan idempotency key.
8. Application berubah menjadi submitted; pendaftar menerima tanda terima dan dapat memantau status.
9. Setelah submit, perubahan field penting dilakukan melalui request correction atau pembukaan kembali oleh panitia; semua perubahan dicatat.
10. Panitia mengelola antrean verifikasi sesuai unit, gelombang, dan jalur.

### 4.5 Verifikasi administrasi
1. Verifikator membuka aplikasi yang ditugaskan.
2. Sistem menampilkan data minimum dan dokumen yang relevan dengan tugas verifikator.
3. Verifikator memeriksa kelengkapan, keterbacaan, konsistensi, dan persyaratan.
4. Setiap item diberi status accepted, rejected, needs_correction, atau not_applicable sesuai definisi kebijakan.
5. Jika perlu perbaikan, sistem mengirim permintaan spesifik tanpa mengungkap catatan internal.
6. Pendaftar memperbaiki data sebelum tenggat; sistem menyimpan versi dokumen/data.
7. Verifikator meninjau ulang dan menyelesaikan checklist.
8. Sistem menandai application administratively_complete atau ineligible dengan alasan yang dapat dijelaskan.
9. Keputusan ineligible yang berdampak pada hak pendaftar harus dapat ditinjau sesuai mekanisme keberatan.

### 4.6 Seleksi dan penilaian
1. Sistem hanya memasukkan aplikasi yang memenuhi prasyarat jalur ke tahap seleksi.
2. Reviewer menerima daftar tugas dan kriteria versi yang berlaku.
3. Reviewer mengisi hasil pemeriksaan sesuai kriteria; bila ada skor, skala, bobot, dan evidence harus sudah disahkan.
4. Sistem menghitung agregat hanya dari formula tervalidasi dan versi kriteria yang disimpan.
5. Sistem menampilkan anomali, nilai kosong, konflik kepentingan, dan potensi duplikasi.
6. Reviewer memberikan rekomendasi; hasil tidak otomatis menjadi keputusan final.
7. Panitia melakukan moderasi/ranking sesuai aturan yang disetujui dan dapat menambahkan alasan pengecualian.
8. Kepala/komite yang berwenang mengesahkan hasil.
9. Sistem menyimpan snapshot hasil seleksi, versi kriteria, reviewer, approver, timestamp, dan audit.
10. Jika tidak ada scoring (misalnya verifikasi berbasis syarat), sistem tetap menyimpan rule/checklist yang dipakai dan alasan keputusan.

**Kontrol fairness:** perubahan kriteria setelah proses dimulai tidak boleh diterapkan surut tanpa keputusan formal, analisis dampak, dan komunikasi kepada pihak terdampak. Sistem tidak boleh membuat ranking tersembunyi berdasarkan atribut sensitif atau proksi yang tidak disahkan.

### 4.7 Pengumuman dan daftar ulang
1. Hasil final dipublikasikan pada waktu yang ditentukan.
2. Pendaftar melihat hasil melalui autentikasi/tautan token terbatas yang aman; jangan menerbitkan daftar publik berisi nama lengkap, nomor identitas, atau skor rinci tanpa dasar.
3. Pendaftar diterima memilih konfirmasi sesuai tenggat.
4. Panitia memverifikasi persyaratan daftar ulang dan dokumen tambahan yang memang diperlukan.
5. Bila ada biaya, status pembayaran diperoleh dari transaksi keuangan terverifikasi, bukan dari input manual yang tidak diaudit.
6. Setelah seluruh prasyarat terpenuhi, status berubah menjadi accepted_confirmed/ready_to_enroll.
7. Pendaftar yang melewati tenggat mengikuti aturan kehilangan kursi/perpanjangan yang telah dipublikasikan.
8. Kursi kosong dapat ditawarkan ke waiting list sesuai urutan dan aturan yang disetujui.
9. Sistem mencatat offer, response, expiry, dan keputusan setiap calon.

### 4.8 Konversi ke student profile dan enrollment
1. Operator memulai conversion hanya untuk application yang accepted dan telah memenuhi daftar ulang.
2. Sistem mencari kemungkinan student profile yang sudah ada menggunakan atribut pencocokan yang disetujui.
3. Hasil pencarian ditampilkan kepada petugas berwenang; tidak ada auto-merge.
4. Petugas memilih membuat profil baru atau menghubungkan ke profil existing setelah verifikasi identitas dan kewenangan.
5. Sistem membuat/memperbarui relasi guardian yang diverifikasi sesuai workflow terpisah.
6. Sistem membuat enrollment baru pada unit, tahun ajaran, tingkat, dan status masuk yang sesuai.
7. Penempatan rombel dapat dilakukan kemudian melalui BP-ACA-01; penerimaan tidak otomatis menetapkan rombel jika kebijakan tidak menyatakannya.
8. Sistem menautkan application, decision snapshot, student profile, dan enrollment dengan audit.
9. Retry conversion mengembalikan hasil yang sama dan tidak membuat siswa/enrollment ganda.

### 4.9 Variasi dan pengecualian
- **Draft tidak selesai:** kedaluwarsa sesuai aturan; pendaftar diberi pemberitahuan sebelum penghapusan/anonimisasi.
- **Pendaftaran ganda:** tandai possible duplicate; review manual; jangan menolak otomatis hanya karena kemiripan nama.
- **Identitas belum lengkap:** status pending/correction; daftar field yang boleh ditunda ditentukan kebijakan.
- **Dokumen tidak terbaca:** minta unggah ulang dan pertahankan versi sebelumnya.
- **Salah jalur:** pindah jalur hanya jika window, kuota, dan policy mengizinkan; simpan riwayat.
- **Keberatan/banding:** buat case terpisah, reviewer berbeda bila mungkin, keputusan dan alasan dicatat.
- **Konflik kepentingan:** reviewer deklarasi dan dialihkan.
- **Perubahan kuota:** amendment dengan approval dan catatan dampak.
- **Waiting list:** offer memiliki expiry dan urutan; tidak boleh terjadi double-offer di luar aturan.
- **Pendaftar mengundurkan diri:** simpan alasan opsional dan timestamp; data mengikuti retention.
- **Diterima tetapi tidak daftar ulang:** status expired/declined sesuai policy; jangan membuat enrollment aktif.
- **Siswa pindahan:** dapat menggunakan jalur/jenis penerimaan khusus; BP-STD-01/02 tetap mengatur enrollment dan histori.
- **Unit menutup gelombang:** aplikasi yang belum selesai mengikuti aturan transisi yang telah diumumkan.

### 4.10 Aturan bisnis
- AdmissionCycle, AdmissionPath, quota, criteria, form, dan document requirements harus versioned.
- Satu application number unik pada scope yang dipilih dan tidak memuat NIK/NISN atau data sensitif.
- Status draft/submitted/verified/selected/accepted/confirmed tidak boleh dicampur menjadi satu boolean.
- Keputusan final harus memiliki actor/committee, approver, timestamp, policy version, dan reason code.
- Kuota dan waiting list divalidasi secara transaksional untuk mencegah overbooking.
- Perubahan hasil setelah pengumuman memerlukan correction/revision workflow dan pemberitahuan.
- Pendaftar yang ditolak tidak boleh dikonversi ke enrollment aktif melalui endpoint biasa.
- Student profile matching bukan bukti identitas; petugas harus memverifikasi sumber yang sah.
- Relasi wali tidak dianggap sah hanya karena email/nomor telepon dimasukkan pendaftar.
- Dokumen hanya dapat diakses berdasarkan task assignment dan field-level permission.
- Ekspor daftar pendaftar dibatasi, diberi audit, dan tidak memuat kolom yang tidak diperlukan.
- Penghapusan/anonimisasi mengikuti retention schedule dan legal hold.

### 4.11 State konseptual
- Admission cycle: draft → submitted_for_approval → approved → open → closed → archived.
- Application: draft → submitted → under_verification → correction_required → verified/ineligible → under_selection → recommended → accepted/rejected/waitlisted → confirmed/declined/expired → converted.
- Document item: missing → uploaded → under_review → accepted/rejected/correction_required.
- Appeal: requested → under_review → approved/rejected → closed.
- Conversion: pending → matched_or_new_profile_review → converted/failed; operasi harus idempotent.

State final, transisi, dan istilah tampilan perlu disepakati bersama stakeholder.

### 4.12 Data konseptual
- AdmissionCycle, AdmissionPath, AdmissionPolicyVersion, AdmissionQuota, AdmissionFormVersion, AdmissionFieldDefinition, AdmissionApplication, ApplicantIdentity, ApplicantContact, ApplicantGuardian, ApplicationDocument, DocumentReview, EligibilityCheck, SelectionCriterion, SelectionScore, ReviewerAssignment, ConflictOfInterestDeclaration, SelectionDecision, DecisionRevision, WaitingListEntry, ReEnrollmentConfirmation, AppealCase, ConversionRecord, StudentProfile, Enrollment, AuditEvent, NotificationDelivery.
- Data applicant disimpan terpisah dari student profile; conversion memiliki foreign key dan audit yang eksplisit.
- Dokumen privat menggunakan object storage privat, signed URL berumur pendek, malware scan, checksum, dan access log.
- Data scoring harus dapat direkonstruksi dari policy version dan input yang digunakan.

### 4.13 Authorization baseline
- Pendaftar/wali: create/read/update draft sendiri; submit; correction sesuai status; read hasil sendiri.
- Panitia: akses aplikasi pada unit/gelombang yang ditugaskan; tidak otomatis melihat seluruh dokumen sensitif.
- Verifikator: hanya item dokumen dan field yang relevan.
- Reviewer: hanya aplikasi yang ditugaskan; input hasil/rekomendasi; tidak otomatis mengubah konfigurasi policy.
- Approver: melihat ringkasan, evidence relevan, dan mengesahkan; separation of duties jika diwajibkan.
- Bendahara: melihat identitas dan status tagihan yang diperlukan, bukan skor atau catatan seleksi.
- Operator enrollment: konversi accepted/confirmed; tidak mengubah keputusan seleksi.
- Kepala: akses sesuai kewenangan unit dan kebutuhan.
- Foundation admin: laporan agregat lintas unit bila diberi grant; detail applicant memerlukan grant unit yang eksplisit.
- Platform support: metadata teknis minimal; akses konten hanya break-glass.
- Semua endpoint, download, export, search, dan background job memvalidasi tenant/unit serta object-level permission.

### 4.14 Acceptance criteria
- Aplikasi tidak dapat dibaca pendaftar lain dengan mengganti ID.
- Panitia unit A tidak dapat membuka aplikasi unit B tanpa grant.
- Kriteria yang dipublikasikan dan dipakai pada hasil dapat direkonstruksi.
- Perubahan kriteria/kuota setelah dibuka membutuhkan approval dan audit.
- Sistem menolak overbooking pada kondisi concurrent submission.
- Reviewer tanpa assignment tidak dapat mengisi skor.
- Conflict-of-interest yang dinyatakan memblokir penugasan reviewer sesuai policy.
- Hasil final tidak terlihat sebelum publication time/state.
- Pendaftar ditolak/expired tidak dapat dikonversi menjadi enrollment.
- Conversion retry tidak membuat duplikasi profile/enrollment.
- Dokumen privat tidak dapat diakses melalui URL publik atau role yang tidak berwenang.
- Koreksi/appeal menghasilkan keputusan baru tanpa menghapus keputusan sebelumnya.

## 5. BP-HR-01 — Data pegawai dan penugasan

### 5.1 Tujuan dan batas
Menyediakan sumber data pegawai yang terkontrol untuk kebutuhan organisasi dan operasional pendidikan, serta menautkan pegawai dengan assignment yang efektif tanggal. HR bukan identity provider dan bukan pengganti authorization aplikasi.

### 5.2 Prasyarat
- Unit/tenant valid.
- Pengguna HR memiliki grant untuk mengelola data pegawai pada scope tersebut.
- Kebijakan data pegawai, dokumen, akses, retention, dan approval telah ditentukan.
- Kebutuhan jabatan/posisi dan struktur organisasi tersedia atau dapat dibuat.
- Untuk guru, kurikulum, rombel, subject offering, dan periode akademik tersedia sebelum assignment mengajar diaktifkan.

### 5.3 Pembuatan profil pegawai
1. HR/operator membuat draft employee record.
2. Sistem mengumpulkan data minimum: nama legal, identitas internal, kontak kerja, tanggal mulai, unit hubungan kerja, kategori pegawai, dan status awal.
3. Data identitas nasional, alamat rumah, rekening, informasi keluarga, kesehatan, atau dokumen lain hanya dikumpulkan jika ada tujuan dan dasar yang disetujui.
4. Sistem melakukan possible duplicate check berdasarkan atribut yang diizinkan; hasil perlu review manusia.
5. HR memeriksa bukti identitas/kualifikasi yang diperlukan.
6. Pejabat berwenang mengesahkan profil dan status hubungan kerja.
7. Sistem menyimpan versi profil, sumber data, actor, waktu, dan approval.
8. Jika pegawai bekerja pada lebih dari satu unit, setiap penempatan/relasi kerja dicatat terpisah dengan scope dan tanggal efektif.

### 5.4 Penempatan organisasi dan hubungan kerja
1. HR memilih unit, departemen/bagian, jabatan, status hubungan kerja, dan rentang tanggal.
2. Sistem memeriksa apakah posisi tersedia dan apakah tanggal efektif bertentangan dengan penempatan lain sesuai kebijakan.
3. HR mencatat jenis hubungan (misalnya tetap, kontrak, paruh waktu, honorer, relawan, atau kategori lokal) hanya setelah definisi dan konsekuensi hukumnya divalidasi.
4. Dokumen kontrak/keputusan disimpan privat dengan metadata, versi, tanggal berlaku, dan expiry bila relevan.
5. Pejabat berwenang menyetujui penempatan.
6. Perubahan unit/jabatan membuat assignment baru; histori sebelumnya ditutup, bukan ditimpa.
7. Sistem dapat menghasilkan reminder masa kontrak/sertifikasi bila fitur ini disetujui.
8. Akhir masa kerja menutup assignment dan memicu review akses, bukan menghapus employee profile atau histori.

### 5.5 Penugasan guru dan integrasi akademik
1. Admin akademik mengajukan kebutuhan guru berdasarkan struktur kurikulum dan penawaran mapel.
2. Sistem menampilkan pegawai yang memenuhi syarat berdasarkan kualifikasi/kompetensi yang relevan dan status kerja aktif.
3. Admin memilih unit, periode, subject offering, rombel/kelompok, peran, beban, dan tanggal efektif.
4. Validator memeriksa guru aktif, kualifikasi yang disyaratkan, konflik jadwal, batas beban jika tersedia, serta overlap assignment.
5. Kepala/admin akademik mengesahkan assignment.
6. Assignment yang aktif menjadi sumber otorisasi guru untuk sesi, presensi, dan asesmen.
7. Perubahan atau pergantian guru menutup assignment lama dan membuat assignment baru.
8. Wali kelas merupakan assignment khusus yang terpisah dari teaching assignment.
9. Pegawai yang mengajar lintas unit membutuhkan assignment eksplisit pada masing-masing unit.
10. Assignment historis tetap melekat pada sesi/asesmen yang dibuat selama masa berlakunya.

### 5.6 Perubahan status, cuti, nonaktif, dan akhir hubungan kerja
1. HR mencatat peristiwa dan tanggal efektif.
2. Sistem memeriksa dampak terhadap assignment aktif, jadwal, approval queue, dan akses aplikasi.
3. Atasan/pejabat HR menyetujui sesuai jenis perubahan.
4. Sistem menutup atau menangguhkan assignment yang terdampak; pengganti ditetapkan melalui proses akademik.
5. Identity/access administrator menerima task untuk meninjau membership, role, session, API token, dan akses perangkat.
6. Akses dicabut/dibatasi pada tanggal efektif yang ditetapkan; emergency revoke tersedia untuk risiko keamanan.
7. Employee profile dan dokumen historis dipertahankan sesuai retention dan legal hold.
8. Sistem mencatat checklist offboarding dan bukti penyelesaian.

### 5.7 Pengecualian
- **Pegawai lintas unit:** satu orang dapat memiliki satu global identity, tetapi employment/placement/assignment pada setiap unit harus eksplisit.
- **Guru sementara/pengganti:** assignment memiliki tanggal mulai/akhir dan status sementara.
- **Kontrak berakhir:** sistem memberi reminder; status tidak berubah diam-diam tanpa keputusan.
- **Cuti panjang/nonaktif:** definisi apakah assignment ditangguhkan dan siapa pengganti merupakan kebijakan.
- **Mutasi internal:** buat placement baru dan tutup placement lama; jangan mengubah histori.
- **Duplikasi pegawai:** review dan merge hanya dengan approval serta relasi historis yang dipetakan.
- **Pegawai merangkap peran:** permission diberikan terpisah; konflik kepentingan ditangani.
- **Keluar mendadak:** emergency access revoke dapat dilakukan oleh role khusus dengan audit dan review pascakejadian.
- **Data salah:** koreksi profil melalui revision workflow.
- **Guru tanpa assignment akademik:** tidak boleh mengakses daftar siswa/kelas hanya karena kategori pegawainya guru.

### 5.8 Aturan bisnis
- EmployeeProfile tidak harus memiliki UserAccount; akun dibuat hanya bila diperlukan.
- Satu user dapat terhubung ke beberapa employment/placement pada unit berbeda dengan batasan yang disepakati.
- Employee ID unik dalam scope kebijakan (unit/tenant/organisasi), bukan diasumsikan global.
- Status pegawai dan status akses adalah dua state machine berbeda.
- Role aplikasi ditentukan oleh invitation/membership/grant, bukan otomatis dari jabatan HR.
- Assignment guru harus terikat pada unit, periode, subject offering, peserta/rombel, peran, dan tanggal efektif.
- Penugasan yang sudah digunakan sesi/asesmen tidak boleh dihapus.
- Perubahan jabatan tidak otomatis mengubah permission tanpa workflow access review.
- Dokumen kontrak, identitas, rekening, kesehatan, dan keluarga diklasifikasikan sensitif; akses field/document-level.
- Export data HR memerlukan alasan, scope, audit, dan minimisasi.
- Akses mantan pegawai dicabut sesuai tanggal efektif, tetapi histori audit tetap tersedia bagi role sah.
- Payroll tidak dibangun secara implisit dari data kontrak atau assignment.

### 5.9 State konseptual
- Employee profile: draft → pending_verification → active_record → archived.
- Employment relationship: proposed → active → suspended/on_leave → ended.
- Organizational placement: draft → active → transferred/ended.
- Teaching assignment: draft → approved → active → ended/cancelled.
- Access membership: invited → active → restricted/revoked/expired.

State dan istilah legal harus disesuaikan dengan bentuk hubungan kerja yang berlaku; jangan menyamakan status HR dengan status user account.

### 5.10 Data konseptual
EmployeeProfile, EmployeeIdentifier, EmployeeContact, EmploymentRelationship, EmploymentDocument, OrganizationalPosition, OrganizationalPlacement, EmployeeQualification, Certification, TeachingAssignment, HomeroomAssignment, WorkloadAllocation, HRChangeRequest, OffboardingChecklist, UserAccountLink, TenantMembership, UnitMembership, RoleGrant, AccessReview, Approval, AuditEvent.
Dokumen dan field sensitif harus terpisah atau diklasifikasikan agar query/report biasa tidak memuatnya secara default.

### 5.11 Authorization baseline
- HR: CRUD draft dan pengelolaan record pegawai pada unit yang ditugaskan.
- Atasan: melihat informasi kerja minimum bawahan sesuai scope; tidak otomatis melihat dokumen identitas/keluarga.
- Kepala: approval dan laporan sesuai kewenangan.
- Admin akademik: read field yang diperlukan untuk assignment guru; tidak membaca dokumen HR sensitif.
- Guru/pegawai: read profil kerja dan assignment sendiri; mengajukan koreksi melalui workflow.
- Admin akses/IT: mengelola akun, membership, role, token, dan revoke; tidak otomatis melihat dokumen HR.
- Foundation owner: agregat/administrasi lintas unit sesuai grant; detail HR memerlukan grant eksplisit.
- Platform support: metadata minimum; break-glass terkontrol.
- Akses API, export, attachment, search index, cache, dan queue harus mengikuti scope dan permission yang sama.

### 5.12 Acceptance criteria
- Guru tanpa teaching assignment aktif tidak dapat mengakses kelas, presensi, atau nilai.
- HR unit A tidak dapat membaca dokumen pegawai unit B tanpa grant.
- Employee profile dapat ada tanpa user account.
- Pencabutan membership menutup akses pada request berikutnya dan membatalkan sesi/token sesuai kebijakan.
- Perubahan penempatan tidak mengubah histori assignment dan transaksi akademik.
- Dokumen sensitif tidak tampil pada laporan/export umum.
- Akhir hubungan kerja menghasilkan checklist akses dan assignment terdampak.
- Koreksi data HR menyimpan before/after, alasan, actor, approver, dan waktu.
- Data pegawai tidak dihapus hanya karena status hubungan kerja berakhir.

## 6. Integrasi lintas modul dan kontrak konseptual

### 6.1 Ownership
- Admission owns application, admission cycle, selection, decision, appeal, waiting list, and conversion workflow.
- Student domain owns StudentProfile and Enrollment.
- Organization owns education unit, organization structure, and position catalog.
- HR owns employee identity-in-organization, employment relationship, placement, qualification, and work assignment.
- Academic domain owns subject offering, class placement, teaching assignment, timetable, and session.
- Identity/access domain owns user account, membership, role, permission, and session.
- Finance owns invoice/payment status if PPDB fees are supported; admission consumes verified payment state.

### 6.2 Kandidat API konseptual
Contoh endpoint untuk diskusi, belum kontrak final:
- GET/POST /api/units/{unit}/admission-cycles
- POST /api/admission-cycles/{cycle}/publish
- POST /api/admission-applications
- POST /api/admission-applications/{application}/submit
- POST /api/admission-applications/{application}/documents
- POST /api/admission-applications/{application}/reviews
- POST /api/admission-applications/{application}/decision
- POST /api/admission-applications/{application}/appeals
- POST /api/admission-applications/{application}/confirm
- POST /api/admission-applications/{application}/convert
- GET/POST /api/units/{unit}/employees
- POST /api/employees/{employee}/placements
- POST /api/employees/{employee}/employment-changes
- POST /api/teaching-assignments
- POST /api/employees/{employee}/offboarding

Semua command wajib validasi tenant/unit, object-level authorization, status, tanggal efektif, idempotency, audit, dan concurrency.

### 6.3 Kandidat event
AdmissionCyclePublished, AdmissionApplicationSubmitted, ApplicationDocumentReviewed, AdmissionCorrectionRequested, AdmissionSelectionCompleted, AdmissionDecisionApproved, AdmissionResultPublished, AdmissionAppealSubmitted, AdmissionOfferConfirmed, AdmissionApplicationConverted, EmployeeRecordApproved, EmploymentStatusChanged, EmployeePlacementChanged, TeachingAssignmentApproved, TeachingAssignmentEnded, EmployeeOffboardingStarted, EmployeeAccessRevoked.
Event harus berversi, memiliki event ID, tenant/unit context, actor/source, occurred_at, correlation ID, serta aturan retry/deduplication. Hindari memasukkan dokumen atau data sensitif langsung ke payload event.

## 7. Laporan dan layar awal

### 7.1 Layar PPDB
| Layar | Pengguna utama |
|---|---|
| Kalender dan gelombang penerimaan | Admin PPDB |
| Jalur, kuota, kriteria, formulir | Admin PPDB/kepala |
| Portal pendaftaran dan draft formulir | Pendaftar/wali |
| Upload dan status dokumen | Pendaftar/verifikator |
| Antrean verifikasi | Panitia |
| Penugasan reviewer dan deklarasi konflik | Koordinator seleksi |
| Penilaian/rekomendasi dan moderasi | Reviewer/komite |
| Approval keputusan | Kepala/approver |
| Pengumuman privat dan daftar ulang | Pendaftar/panitia |
| Waiting list dan offer management | Panitia |
| Conversion ke student/enrollment | Operator |
| Appeal, koreksi, dan audit | Reviewer/kepala |

Laporan: jumlah pendaftar per jalur/status, kelengkapan, kuota/kapasitas, hasil seleksi sesuai permission, daftar ulang, waiting list, conversion, appeal, serta audit perubahan kriteria/keputusan. Data agregat harus mencegah identifikasi ulang bila jumlah kecil dan kebijakan mensyaratkan.

### 7.2 Layar HR
| Layar | Pengguna utama |
|---|---|
| Direktori pegawai terbatas | HR |
| Profil pegawai dan histori perubahan | HR/pegawai sendiri |
| Dokumen dan kualifikasi | HR dengan grant |
| Struktur jabatan/posisi | HR/kepala |
| Penempatan dan hubungan kerja | HR |
| Penugasan guru/mapel/rombel | Admin akademik |
| Beban dan konflik assignment | Admin akademik/kepala |
| Perubahan status/cuti/akhir hubungan kerja | HR |
| Access review dan offboarding | Admin akses/IT |
| Audit dan laporan agregat | Kepala/HR |

Laporan: headcount agregat, penempatan per unit, masa kontrak/sertifikasi yang perlu tindak lanjut, assignment guru per periode, beban kerja, perubahan status, dan offboarding. Jangan tampilkan NIK, rekening, alamat rumah, atau dokumen sensitif pada laporan umum.

## 8. Minimum test scenarios

### PPDB
1. Pendaftar tidak dapat melihat application milik orang lain dengan mengganti ID.
2. Admin unit A tidak dapat membuka aplikasi unit B.
3. Application number unik dan tidak mengandung identitas sensitif.
4. Submit berulang menghasilkan application yang sama, bukan duplikat.
5. Gelombang tertutup menolak submit baru.
6. Perubahan kriteria setelah publish memerlukan approval dan versi baru.
7. Reviewer yang tidak ditugaskan tidak dapat memasukkan skor.
8. Conflict of interest memblokir reviewer sesuai policy.
9. Kuota tidak dapat terlampaui oleh concurrent decision/confirmation.
10. Hasil belum dipublikasikan tidak terlihat oleh pendaftar.
11. Waiting list offer memiliki expiry dan mencegah double-offer.
12. Pendaftar ditolak/expired tidak dapat dikonversi ke enrollment.
13. Conversion retry tidak membuat StudentProfile/Enrollment ganda.
14. Koreksi keputusan menyimpan versi lama dan baru.
15. Dokumen privat tidak dapat diakses oleh role yang tidak berwenang.
16. Export daftar pendaftar dibatasi dan diaudit.

### HR
17. EmployeeProfile dapat dibuat tanpa UserAccount.
18. Pegawai pada unit A tidak terlihat oleh HR unit B tanpa grant.
19. Guru tanpa assignment aktif tidak dapat mengakses kelas/daftar siswa.
20. Status hubungan kerja berakhir tidak otomatis menghapus profil/histori.
21. Revoke membership memblokir akses dan token sesuai policy.
22. Mutasi unit mempertahankan assignment historis.
23. Perubahan jabatan tidak otomatis memberi permission aplikasi.
24. Dokumen sensitif tidak masuk export umum.
25. Offboarding menghasilkan review seluruh membership, role, token, dan assignment.
26. Koreksi data HR menyimpan before/after dan approval.
27. Import pegawai duplikat ditandai untuk review, tidak auto-merge.
28. Background job dan export tidak melewati tenant/unit scope.

## 9. Keputusan terbuka

| ID | Pertanyaan | Dampak | Pemilik keputusan |
|---|---|---|---|
| OPEN-ADM-01 | Apakah PPDB masuk MVP, atau hanya penerimaan manual/import pada rilis awal? | Scope dan prioritas | Product owner |
| OPEN-ADM-02 | Bentuk/jenjang/unit mana yang menjadi target pertama? | Form dan jalur | Product owner |
| OPEN-ADM-03 | Jalur seleksi dan aturan kuota apa yang wajib didukung? | Policy model | Akademik/stakeholder |
| OPEN-ADM-04 | Dokumen apa yang benar-benar diperlukan pada tiap jalur? | Privasi dan storage | Unit/legal |
| OPEN-ADM-05 | Apakah wali dapat mendaftarkan beberapa calon siswa dari satu akun? | Identity/guardian model | Product owner |
| OPEN-ADM-06 | Bagaimana mekanisme banding, daftar tunggu, dan offer expiry? | State machine | Kepala/unit |
| OPEN-ADM-07 | Apakah biaya pendaftaran/daftar ulang masuk MVP? | Dependency finance | Product owner |
| OPEN-ADM-08 | Apakah integrasi pemerintah/daerah dibutuhkan dan tersedia secara resmi? | API/compliance | Product owner |
| OPEN-ADM-09 | Bagaimana retensi data pendaftar diterima, ditolak, mengundurkan diri, dan draft? | Legal/privacy | Product owner/legal |
| OPEN-ADM-10 | Apakah seleksi memakai skor, ranking, verifikasi syarat, atau kombinasi? | Formula/audit | Akademik |
| OPEN-HR-01 | Apakah HR dasar masuk MVP? Data pegawai minimum apa? | Scope dan data model | Product owner |
| OPEN-HR-02 | Apakah satu pegawai dapat memiliki hubungan kerja di banyak unit/tenant? | Identity/placement | Product owner |
| OPEN-HR-03 | Kategori hubungan kerja apa yang perlu didukung? | Legal/status model | HR/stakeholder |
| OPEN-HR-04 | Apakah kontrak/dokumen kepegawaian disimpan dalam SINAU? | Security/storage | Product owner/legal |
| OPEN-HR-05 | Apakah kualifikasi/sertifikasi dan masa berlaku masuk MVP? | Data dan reminder | Product owner |
| OPEN-HR-06 | Apakah beban kerja guru dihitung dan dilaporkan? | Academic/HR integration | Akademik |
| OPEN-HR-07 | Apakah cuti, presensi pegawai, payroll, dan pajak out of scope? | Boundary | Product owner |
| OPEN-HR-08 | Siapa berwenang membuat user account dan memberikan role setelah pegawai dibuat? | Security/SoD | Product owner |
| OPEN-HR-09 | Apa retention schedule dan prosedur offboarding? | Privacy/security | Product owner/legal |
| OPEN-CROSS-01 | Kebijakan data pribadi anak dan wali, consent/notice, akses, correction, dan deletion? | Legal/privacy | Product owner/legal |
| OPEN-CROSS-02 | Bagaimana data import lama diverifikasi dan deduplikasi? | Migration/data quality | Product owner |

## 10. Gerbang sebelum implementasi

Sebelum migration atau fitur produksi dibuat:
1. Validasi alur PPDB dengan panitia, kepala, operator, calon siswa/wali dari bentuk/jenjang target.
2. Validasi HR dengan HR, kepala, guru, admin akademik, dan admin akses.
3. Verifikasi aturan resmi penerimaan dan pengelolaan pegawai yang relevan; simpan penerbit, URL, versi, tanggal akses, dan tanggal efektif.
4. Putuskan MVP PPDB dan HR; tetapkan out-of-scope payroll/absensi pegawai jika belum diprioritaskan.
5. Tetapkan klasifikasi data, privacy notice, consent/acknowledgement, retention, legal hold, dan proses hak subjek data.
6. Setujui permission matrix, reviewer/approver matrix, conflict-of-interest policy, dan emergency access.
7. Sinkronkan domain model, ERD, data dictionary, constraint, API/event, storage, audit, dan test plan.
8. Uji concurrency kuota, idempotent conversion, tenant isolation, private document access, export, dan revoke access.
9. Dapatkan persetujuan eksplisit product owner atas baseline dan hasil PoC.

**Larangan sementara:** jangan auto-merge identitas; jangan menggunakan atribut sensitif/proksi tanpa dasar; jangan menganggap pegawai otomatis user; jangan menganggap guru otomatis punya akses kelas; jangan membuat payroll atau integrasi eksternal tanpa scope dan persetujuan.

## 11. Traceability

| Process ID | Input/dependency | Output | Downstream |
|---|---|---|---|
| BP-ADM-01 | Unit, periode, kebijakan penerimaan, applicant | Application, decision, waiting list, conversion | BP-STD-01, BP-ORG-02, BP-ACA-01 |
| BP-HR-01 | Unit, posisi, employee identity, employment policy | Employee profile, placement, teaching assignment | BP-ORG-01, BP-ACA-01/02/03, identity/access |
| BP-STD-01 | Accepted confirmed application atau input manual sah | Student profile, enrollment | BP-ACA, BP-ATT, BP-ASM |
| Identity/access | User account dan approval/grant terpisah | Membership, role, session | Semua modul |

## 12. Riwayat perubahan
- 2026-11-18 — Draft 0.1.0 dibuat untuk BP-ADM-01 dan BP-HR-01. Belum divalidasi stakeholder dan belum diverifikasi terhadap peraturan resmi.
