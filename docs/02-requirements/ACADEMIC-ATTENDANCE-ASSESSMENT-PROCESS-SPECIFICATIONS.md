# SINAU — Spesifikasi Proses Akademik, Presensi, dan Asesmen

**ID dokumen:** BP-ACA-ATT-ASM-001  
**Versi:** 0.1.0 — Draft untuk validasi  
**Tanggal:** 2026-11-18  
**Status:** Draft; belum disetujui stakeholder dan bukan izin implementasi  
**Pemilik keputusan:** Product owner SINAU  
**Prasyarat:** [Spesifikasi Organisasi dan Peserta Didik](ORGANIZATION-AND-STUDENT-PROCESS-SPECIFICATIONS.md), khususnya BP-ORG-02, BP-STD-01, BP-STD-02  
**Peta induk:** [Business Process Map](BUSINESS-PROCESS-MAP.md)  
**Katalog:** [Blueprint Catalog](../01-blueprint/BLUEPRINT-CATALOG.md)  
**Tracker:** [Project Progress](../00-governance/PROJECT-PROGRESS.md)

> Dokumen ini menurunkan BP-ACA-01—03, BP-ATT-01, BP-ASM-01—02 menjadi rancangan proses lintas peran. Ketentuan kurikulum, kalender, kehadiran, formula nilai, remedial, dan format rapor yang bergantung pada regulasi atau kebijakan lembaga tetap harus diverifikasi terhadap sumber resmi dan disetujui pemilik proses. Tidak ada formula atau kebijakan lokal yang dianggap final hanya karena dicontohkan di sini.

## 1. Tujuan dan ruang lingkup

### 1.1 Tujuan
- Menetapkan proses penyiapan struktur pembelajaran per unit dan periode.
- Menetapkan proses pencatatan presensi yang konsisten, dapat dikoreksi secara terkendali, dan dapat direkap.
- Menetapkan siklus asesmen sampai nilai disahkan dan hasil belajar dipublikasikan.
- Menjaga keterkaitan setiap transaksi dengan tenant, education unit, tahun ajaran, periode, enrollment, rombel, dan penugasan yang tepat.
- Menjadi dasar validasi kebutuhan, domain model, authorization, API, UI, serta test plan.

### 1.2 Termasuk
- Kelas/tingkat, rombongan belajar (rombel), kapasitas, wali kelas.
- Struktur mata pelajaran/kelompok mata pelajaran dari kurikulum yang berlaku.
- Penawaran mapel per rombel/periode dan penugasan guru.
- Jadwal dan pemeriksaan benturan.
- Sesi pembelajaran sebagai konteks kegiatan akademik.
- Presensi siswa, status kehadiran, koreksi, persetujuan, rekap, dan notifikasi.
- Rencana asesmen, instrumen/komponen, hasil, penilaian, moderasi/review, pengesahan, publikasi, revisi.
- Rekap hasil belajar dan kontrak data untuk rapor.

### 1.3 Tidak otomatis termasuk
- LMS penuh, konferensi video, bank soal adaptif, ujian daring berpengawasan, plagiarism detection.
- Payroll dan presensi kepegawaian.
- Penjadwalan otomatis berbasis optimisasi kompleks.
- Integrasi resmi pemerintah atau sistem eksternal tertentu.
- Penetapan kurikulum, formula nilai, ambang ketuntasan, format rapor, dan kebijakan remedial tanpa keputusan resmi.
- Perangkat biometrik, pengenalan wajah, GPS, QR, NFC, atau pelacakan lokasi sebagai metode presensi default.

## 2. Prinsip dan invarian lintas proses

1. **Scope wajib:** seluruh record akademik memiliki tenant dan unit yang konsisten. Request tidak boleh mempercayai tenant/unit ID dari client tanpa otorisasi server.
2. **Periode eksplisit:** struktur, jadwal, sesi, presensi, asesmen, dan nilai terikat ke tahun ajaran dan term/periode yang berlaku.
3. **Enrollment sebagai konteks siswa:** transaksi siswa mengacu ke enrollment yang relevan, bukan hanya student profile. Enrollment harus aktif/valid pada tanggal kegiatan, kecuali ada aturan historis yang eksplisit.
4. **Penempatan berversi:** keanggotaan rombel dan penugasan guru memiliki rentang tanggal efektif. Perubahan tidak boleh mengubah arti record historis.
5. **Kurikulum berversi:** struktur kurikulum dan aturan penilaian yang sudah digunakan transaksi tidak ditimpa diam-diam.
6. **Ownership data:** modul organisasi memiliki unit; akademik memiliki struktur kelas/mapel/jadwal; presensi memiliki sesi dan catatan kehadiran; asesmen memiliki instrumen dan hasil.
7. **Default deny:** akses guru dibatasi pada penugasan/rombel/mapel/periode; wali kelas hanya pada kelas yang ditugaskan; operator tidak otomatis boleh mengubah nilai final.
8. **Koreksi bukan overwrite:** perubahan presensi/nilai setelah pencatatan menyimpan nilai lama, nilai baru, alasan, pelaku, waktu, dan approval bila diwajibkan.
9. **Idempotency:** import, bulk submission, retry jaringan, event, dan job tidak menggandakan sesi atau hasil.
10. **Tidak ada publikasi prematur:** hasil yang belum disahkan tidak boleh terlihat sebagai hasil resmi oleh siswa/wali.
11. **Timezone:** waktu disimpan secara konsisten (instan UTC atau strategi DB yang disepakati), ditampilkan sesuai zona waktu unit; kalender lokal dan tanggal akademik tetap disimpan sebagai tanggal domain.
12. **Variasi pendidikan:** sekolah umum, madrasah, jenjang, program keahlian, kurikulum, dan periode dapat berbeda. Konfigurasi harus efektif tanggal dan tidak mengasumsikan satu struktur universal.
13. **Human approval:** pembukaan/perubahan struktur penting, koreksi terlambat, pengesahan nilai, dan pembukaan kembali periode mengikuti matriks kewenangan.
14. **Audit dan privasi:** catatan sensitif, akomodasi khusus, alasan izin/sakit, serta informasi wali dibatasi sesuai kebutuhan dan kebijakan privasi.

## 3. Aktor dan tanggung jawab

| Aktor | Tanggung jawab | Batas dasar |
|---|---|---|
| Foundation owner/admin | Melihat status lintas unit sesuai grant | Tidak otomatis melihat data akademik rinci |
| Kepala unit | Menetapkan/menyetujui kebijakan dan hasil resmi | Tidak otomatis melakukan input harian |
| Admin akademik/wakil kurikulum | Menyiapkan kalender operasional, struktur, jadwal, assignment | Scope unit dan periode |
| Operator/TU | Administrasi master data dan bantuan operasional | Tidak otomatis mengesahkan nilai |
| Guru mapel | Mengelola sesi, presensi kelas, asesmen, dan nilai mapel yang ditugaskan | Hanya assignment valid |
| Wali kelas | Memantau kelas, memeriksa rekap, memberi rekomendasi/pengesahan sesuai kebijakan | Hanya rombel yang ditugaskan |
| Petugas presensi | Input presensi jika ditunjuk | Hak khusus dan audit |
| Siswa | Melihat jadwal, presensi, tugas, dan hasil yang dipublikasikan | Data sendiri |
| Orang tua/wali | Melihat informasi siswa yang relasinya terverifikasi | Tidak otomatis melihat saudara/anak lain |
| Reviewer/moderator | Memeriksa anomali dan konsistensi hasil | Tidak boleh mengubah tanpa jejak |
| Platform support | Dukungan teknis terbatas | Akses break-glass, alasan, approval, audit |

Satu pengguna dapat memegang beberapa peran. Konflik kepentingan, pemisahan tugas, dan delegasi harus dievaluasi per unit. Status pegawai tidak otomatis memberikan permission aplikasi.

## 4. BP-ACA-01 — Struktur kelas, rombel, mapel, dan penugasan

### 4.1 Tujuan, pemicu, dan hasil
**Tujuan:** menyiapkan struktur belajar yang valid untuk unit dan periode tertentu.  
**Pemicu:** tahun ajaran/term disiapkan atau ada perubahan struktur.  
**Hasil:** struktur tingkat/kelas, rombel, penempatan siswa, penawaran mapel, assignment guru, dan status persetujuan yang dapat digunakan jadwal, presensi, dan asesmen.

### 4.2 Prasyarat
- Unit aktif dan konteks pengguna sah.
- Tahun ajaran dan periode akademik tersedia.
- Kurikulum/versi struktur yang sesuai unit, jenjang, dan tanggal efektif telah dipilih atau ditetapkan sebagai konfigurasi lokal.
- Enrollment siswa tersedia untuk penempatan rombel.
- Profil pegawai/guru tersedia dan status penugasannya memenuhi kebijakan.
- Permission admin akademik untuk membuat/mengubah struktur.

### 4.3 Alur utama
1. Admin akademik memilih unit, tahun ajaran, dan periode target.
2. Sistem menampilkan tingkat/kelas yang diizinkan untuk bentuk dan jenjang unit.
3. Admin membuat atau menyalin struktur kelas dari periode sebelumnya sebagai draft; salin tidak boleh menyalin record transaksi atau histori siswa.
4. Admin membentuk rombel dengan kode/nama, tingkat, kapasitas, lokasi default bila digunakan, dan tanggal efektif.
5. Admin menempatkan siswa berdasarkan enrollment dan aturan promosi/penempatan yang telah disahkan.
6. Sistem memvalidasi bahwa enrollment berada pada unit/periode yang tepat, tidak memiliki penempatan aktif yang bertentangan, dan kapasitas tidak terlampaui kecuali override disetujui.
7. Admin memilih kurikulum dan menyiapkan penawaran mata pelajaran/kelompok mapel yang berlaku untuk tingkat/program tersebut.
8. Admin menetapkan guru, peran pengajar, beban, dan rentang tanggal efektif untuk setiap penawaran mapel.
9. Sistem memeriksa guru aktif, kecocokan assignment, unit scope, duplikasi, serta batasan beban bila kebijakan tersedia.
10. Admin mengajukan struktur untuk review; reviewer memeriksa kelengkapan, kapasitas, dan anomali.
11. Pejabat yang berwenang mengesahkan struktur untuk periode target.
12. Sistem menerbitkan versi struktur dan mencatat audit; jadwal, presensi, dan asesmen hanya menggunakan versi yang berlaku.

### 4.4 Variasi dan pengecualian
- **Siswa belum ditempatkan:** enrollment tetap ada; siswa tidak muncul dalam daftar presensi rombel sampai penempatan disahkan.
- **Rombel penuh:** sistem menolak penempatan atau meminta override beralasan dan approval.
- **Siswa pindah rombel:** tutup penempatan lama dan buat penempatan baru dengan tanggal efektif; presensi/nilai lama tetap merujuk penempatan saat transaksi terjadi.
- **Guru berubah:** tutup assignment lama, buat assignment baru; jangan mengubah pemilik historis sesi/asesmen.
- **Guru mengajar lintas unit:** perlu assignment eksplisit di masing-masing unit; tenant membership saja tidak cukup.
- **Mapel pilihan/lintas program:** perlu aturan penawaran dan peserta mapel tersendiri; jangan memaksakan satu rombel sebagai satu-satunya konteks keanggotaan.
- **Penggabungan/pemisahan rombel:** transaksi efektif tanggal tertentu, preview dampak, persetujuan, dan audit.
- **Perubahan kurikulum di tengah tahun:** gunakan versi/amendment dengan tanggal efektif; jangan mengubah hasil lama.
- **Pembatalan draft:** boleh dihapus secara logis sebelum dipakai; setelah ada transaksi, lakukan penutupan/retirement, bukan hard delete.

### 4.5 Aturan bisnis
- Kode rombel unik dalam scope yang disepakati (unit + periode, atau kebijakan lain yang diputuskan).
- Kapasitas adalah batas kebijakan, bukan jaminan bahwa seluruh rombel harus berisi kapasitas maksimum.
- Setiap penempatan siswa mempunyai start date dan optional end date; rentang aktif yang tumpang tindih harus ditolak kecuali model multi-program disetujui.
- Setiap penawaran mapel merujuk ke versi kurikulum/struktur yang berlaku.
- Assignment guru harus menyatakan unit, periode, penawaran mapel, rombel atau kelompok peserta, peran, dan rentang efektif.
- Wali kelas adalah assignment tersendiri; jangan menyamakan wali kelas dengan guru mapel.
- Perubahan struktur yang sudah dipakai record akademik harus menghasilkan versi baru atau perubahan efektif ke depan.
- Pengesahan tidak boleh dilakukan oleh pembuat sendiri jika segregation-of-duties diwajibkan oleh kebijakan unit.

### 4.6 State konseptual
- Struktur periode: `draft → submitted → approved → active → closed/archived`.
- Rombel: `draft → active → inactive/archived`.
- Assignment: `draft → active → ended/cancelled`.
- Penempatan siswa: `scheduled → active → ended/transferred`.

Transisi dan nama status final perlu diselaraskan dengan domain model serta kebutuhan laporan.

### 4.7 Data konseptual
- AcademicYear, AcademicTerm, CurriculumVersion, GradeLevel, ClassGroup, ClassEnrollment/Placement, Subject, SubjectOffering, TeachingAssignment, HomeroomAssignment, Room/Location (opsional), StructureVersion, Approval, AuditEvent.
- Semua entitas operasional memiliki scope tenant/unit dan foreign key komposit sesuai strategi database.
- Hindari menaruh daftar siswa/guru sebagai JSON tanpa relasi untuk transaksi yang memerlukan constraint dan query.

### 4.8 Authorization baseline
- Admin akademik: CRUD draft struktur pada unit yang diizinkan; submit.
- Reviewer/kepala: review dan approve sesuai segregation.
- Guru: read struktur dan daftar peserta sesuai assignment.
- Wali kelas: read daftar kelas dan informasi yang relevan untuk kelas yang ditugaskan.
- Operator: administrasi sesuai grant; tidak otomatis mengubah assignment akademik final.
- Siswa/wali: read jadwal/kelas yang terkait enrollment dan relasi terverifikasi.
- Semua endpoint melakukan validasi tenant, unit, periode, status, dan permission di server.

### 4.9 Acceptance criteria
- Sistem menolak rombel atau assignment lintas unit yang tidak berwenang.
- Penempatan siswa tidak dapat menggandakan penempatan aktif yang dilarang.
- Perubahan rombel/guru tidak mengubah histori presensi atau nilai.
- Kapasitas dan benturan assignment ditampilkan sebelum pengesahan.
- Struktur yang disahkan memiliki versi, approver, timestamp, dan audit.
- Pengguna tanpa assignment tidak dapat mengakses daftar siswa/hasil kelas hanya dengan menebak ID.
- Semua operasi bulk memberi hasil per baris dan aman diulang.

## 5. BP-ACA-02 — Penyusunan dan publikasi jadwal

### 5.1 Alur utama
1. Admin akademik memilih unit, periode, dan versi struktur aktif.
2. Admin menetapkan kalender operasional, hari belajar, slot waktu, durasi, jeda, serta pengecualian hari libur.
3. Admin membuat draft jadwal dengan rombel/kelompok, penawaran mapel, guru, slot, ruang/lokasi bila digunakan, dan rentang tanggal.
4. Validator memeriksa benturan:
   - guru pada waktu yang sama;
   - rombel/kelompok peserta pada waktu yang sama;
   - ruang yang sama pada waktu yang sama;
   - jadwal di luar kalender/hari efektif;
   - assignment atau penempatan yang tidak berlaku pada tanggal tersebut.
5. Sistem menampilkan konflik sebagai daftar yang dapat ditindaklanjuti, bukan hanya pesan umum.
6. Admin memperbaiki konflik atau mengajukan pengecualian yang memiliki alasan dan approver.
7. Reviewer/kepala menyetujui jadwal.
8. Sistem memublikasikan versi jadwal dan menyediakan tampilan sesuai role.
9. Perubahan setelah publikasi membuat revisi baru, mencatat alasan, dan mengirim notifikasi kepada audiens terdampak.
10. Jadwal lama tetap dapat ditelusuri untuk menjelaskan sesi dan presensi historis.

### 5.2 Pengecualian
- Jadwal insidental, ujian, kegiatan sekolah, pergantian ruang, guru pengganti, dan pembelajaran lintas rombel harus memiliki tipe kegiatan yang jelas.
- Jadwal berulang harus memperhitungkan hari libur dan tanggal efektif; jangan membuat sesi pada tanggal yang dikecualikan.
- Konflik yang disetujui sebagai pengecualian harus ditandai eksplisit dan tidak dianggap hilang.
- Perubahan mendadak dapat memakai workflow emergency change dengan alasan, otorisasi, dan review setelah kejadian sesuai kebijakan.

### 5.3 Aturan bisnis dan data
- Jadwal adalah rencana; sesi aktual adalah kejadian. Jangan menyamakan keduanya.
- Sesi dapat dibuat dari jadwal atau secara ad hoc oleh role yang berwenang.
- Jadwal menyimpan versi, rentang efektif, timezone unit, dan referensi struktur/assignment.
- Conflict detection wajib berjalan server-side saat submit/approve, bukan hanya di UI.
- Entitas konseptual: TimetableVersion, TimeSlot, TimetableEntry, Room, CalendarException, ScheduleConflict, ScheduleApproval, ScheduleChangeNotice.

### 5.4 Acceptance criteria
- Benturan guru/rombel/ruang terdeteksi dengan pesan yang menyebut record konflik.
- Perubahan jadwal tidak mengubah sesi yang telah berlangsung.
- Pengguna hanya melihat jadwal sesuai unit dan hubungan/assignment.
- Notifikasi hanya dikirim kepada penerima terdampak dan status delivery dapat ditelusuri.
- Kegagalan publikasi tidak meninggalkan jadwal setengah aktif.

## 6. BP-ACA-03 — Pelaksanaan pembelajaran dan sesi

### 6.1 Alur utama
1. Guru membuka daftar jadwal hari ini untuk assignment yang aktif.
2. Guru memilih jadwal dan tanggal; sistem memvalidasi bahwa jadwal, assignment, kalender, dan periode cocok.
3. Sistem membuat atau membuka sesi pembelajaran dengan identitas unik dan status.
4. Guru dapat mencatat materi/topik, tujuan, aktivitas, tugas, sumber belajar, dan catatan kelas sesuai scope produk.
5. Daftar peserta sesi ditentukan dari enrollment dan penempatan/keanggotaan kelompok yang berlaku pada tanggal sesi.
6. Guru menandai sesi terlaksana, dibatalkan, atau dijadwalkan ulang dengan alasan.
7. Sesi yang telah ditutup menjadi sumber konteks presensi dan asesmen bila relevan.
8. Koreksi sesi setelah ditutup mengikuti hak khusus dan audit.

### 6.2 Aturan
- Satu jadwal berulang dapat menghasilkan banyak sesi; setiap sesi mempunyai tanggal dan status sendiri.
- Retry create session harus idempotent dengan kunci yang stabil (misalnya schedule entry + tanggal + occurrence), setelah desain teknis disepakati.
- Sesi yang dibatalkan tidak boleh menerima presensi normal kecuali kebijakan mengizinkan pencatatan pengecualian.
- Catatan pembelajaran tidak boleh menampilkan informasi pribadi siswa yang tidak relevan.
- Learning delivery dapat tetap sederhana pada MVP; fitur LMS yang lebih luas adalah keputusan scope tersendiri.

### 6.3 Acceptance criteria
- Sesi hanya dapat dibuat oleh guru/role dengan assignment yang valid atau petugas berwenang.
- Peserta sesi mencerminkan keanggotaan pada tanggal sesi, bukan daftar rombel terkini.
- Sesi duplikat akibat retry ditolak/dikembalikan sebagai record yang sama.
- Pembatalan dan perubahan sesi tercatat dengan alasan serta pelaku.

## 7. BP-ATT-01 — Presensi siswa, koreksi, dan rekap

### 7.1 Tujuan dan batas
Mencatat status kehadiran siswa untuk sesi atau kegiatan yang ditetapkan unit, menghasilkan rekap yang dapat diperiksa, dan menyediakan mekanisme koreksi dengan audit. Presensi guru/pegawai berada pada domain HR terpisah.

### 7.2 Status kehadiran konseptual
- `present` — hadir.
- `late` — terlambat; aturan batas menit dan pengaruh rekap belum ditentukan.
- `absent` — tidak hadir tanpa keterangan yang diterima.
- `sick` — sakit.
- `permission` — izin.
- `excused` — kategori dispensasi/ketidakhadiran beralasan bila dibutuhkan.
- `not_recorded` — belum dicatat, bukan status final.
- `not_applicable` — sesi/kegiatan tidak mewajibkan presensi siswa.

Daftar status, pemetaan pelaporan, bukti pendukung, dan pengaruhnya pada persentase harus dikonfigurasi/ditetapkan melalui kebijakan resmi. Jangan menyamakan `not_recorded` dengan `absent`.

### 7.3 Prasyarat
- Sesi atau kegiatan presensi valid dan belum dibatalkan.
- Daftar peserta sesi terbentuk dari enrollment/penempatan yang berlaku pada tanggal itu.
- Guru/petugas memiliki assignment dan permission.
- Periode presensi belum dikunci atau terdapat izin koreksi khusus.

### 7.4 Alur utama
1. Guru membuka sesi yang menjadi assignment-nya.
2. Sistem menampilkan daftar peserta yang berlaku pada tanggal sesi, dengan status awal `not_recorded`.
3. Guru menandai status per siswa, dapat menambahkan catatan terbatas, lalu menyimpan draft.
4. Sistem memvalidasi bahwa setiap siswa termasuk peserta sesi, status termasuk enum yang diizinkan, dan request tidak melintasi unit/periode.
5. Guru mengirim/menutup presensi; sistem menyimpan waktu, pelaku, sumber input, dan versi.
6. Sistem menandai peserta yang belum dicatat sebagai belum lengkap; tidak otomatis mengubahnya menjadi absent kecuali aturan yang disetujui secara eksplisit.
7. Jika diperlukan, wali kelas/petugas memeriksa anomali seperti perubahan massal, semua siswa hadir, atau pola tidak wajar.
8. Rekap harian/periode dihitung dari catatan yang valid dengan aturan status yang berlaku.
9. Notifikasi kepada wali/siswa dapat dikirim sesuai preferensi, consent, kebijakan komunikasi, dan hasil verifikasi relasi.
10. Koreksi setelah submit diajukan dengan status yang diusulkan, alasan, bukti bila perlu, dan referensi record asli.
11. Approver memutuskan approve/reject; sistem menyimpan before/after, identitas approver, waktu, dan alasan.
12. Rekap diperbarui secara konsisten dan perubahan dapat ditelusuri.

### 7.5 Metode input
Metode input adalah keputusan produk/keamanan yang harus dipisahkan dari aturan status kehadiran:
- Input manual oleh guru melalui daftar sesi.
- Input oleh petugas/operator yang mendapat assignment khusus.
- QR/kode sesi atau perangkat terdaftar dapat dipertimbangkan setelah threat model dan uji penyalahgunaan.
- Integrasi perangkat atau metode lokasi/biometrik tidak menjadi default; memerlukan dasar hukum, analisis privasi, persetujuan, alternatif non-biometrik, retention, dan security review.
- Import massal hanya untuk data historis/migrasi dengan validasi, preview, dan audit.

### 7.6 Pengecualian
- Siswa pindah rombel setelah tanggal sesi: gunakan keanggotaan pada tanggal sesi.
- Siswa enrollment-nya belum aktif/berakhir pada tanggal sesi: jangan masukkan otomatis.
- Guru salah sesi: tolak jika assignment/periode tidak cocok.
- Jaringan terputus: draft lokal/offline hanya boleh dirancang setelah kebijakan sinkronisasi, conflict resolution, device trust, dan enkripsi disepakati; jangan mengasumsikan offline write tersedia.
- Koreksi setelah periode terkunci: perlu permission khusus dan approval; hasil rekap lama tetap dapat diaudit.
- Bukti sakit/izin: akses dokumen dibatasi; catatan umum tidak boleh membeberkan detail medis.
- Sesi dibatalkan: presensi tidak dihitung sebagai ketidakhadiran siswa.
- Presensi sebagian: sistem menampilkan kelengkapan dan tidak menyimpulkan status siswa yang belum dicatat.

### 7.7 Aturan bisnis
- Unique constraint konseptual: satu status aktif per peserta per sesi (session_id + enrollment_id), dengan riwayat perubahan terpisah.
- Presensi terkait enrollment dan session; jangan hanya mengikat ke student_id dan tanggal.
- Koreksi tidak menghapus record sebelumnya; gunakan attendance revision/history.
- Setiap perubahan bulk harus menyimpan actor, source, request/idempotency key, dan hasil per item.
- Batas waktu input/koreksi, kewajiban approval, dan apakah guru boleh mengubah setelah submit adalah kebijakan terbuka.
- Rekap harus menjelaskan denominator, pengecualian hari libur/sesi batal, dan cara menghitung kategori.
- Data presensi tidak boleh dipakai untuk keputusan disiplin otomatis tanpa review manusia dan dasar kebijakan.
- Audit log tidak boleh memuat alasan medis rinci atau dokumen sensitif secara plaintext.

### 7.8 State konseptual
- Sesi: `scheduled → open → submitted → locked`, dengan `cancelled` atau `reopened` melalui kewenangan khusus.
- Batch presensi: `draft → submitted → reviewed/accepted → locked`.
- Permintaan koreksi: `requested → approved/rejected → applied`.
- Record kehadiran: revisioned; perubahan membuat versi baru.

### 7.9 Data konseptual
AttendanceSession, SessionParticipant, AttendanceRecord, AttendanceRevision, AttendanceCorrectionRequest, AttendancePolicy, AttendanceStatusDefinition, AttendanceSummary, AttendanceEvidence (private), NotificationDelivery, AuditEvent.
Setiap record wajib konsisten tenant/unit dan mempunyai referensi sesi/enrollment. Evidence file disimpan privat dengan kontrol akses, malware scan, retention, dan audit.

### 7.10 Authorization baseline
- Guru: input/submit presensi untuk sesi assignment aktif.
- Petugas presensi: hanya unit/sesi yang diberikan.
- Wali kelas: read/review rekap rombel yang ditugaskan; koreksi hanya jika grant.
- Operator: read dan bantuan koreksi sesuai kebijakan; tidak otomatis mengesahkan.
- Kepala: akses rekap dan approval sesuai matriks.
- Siswa/wali: read data terkait setelah status dipublikasikan dan relasi diverifikasi.
- Platform support: tidak boleh membaca isi presensi secara rutin; break-glass harus dibatasi dan diaudit.

### 7.11 Acceptance criteria
- Siswa di luar daftar peserta sesi tidak dapat diberi presensi.
- `not_recorded` tidak dihitung sebagai `absent` tanpa kebijakan eksplisit.
- Retry submission tidak membuat catatan duplikat.
- Koreksi membutuhkan alasan dan mempertahankan before/after.
- Guru tidak dapat mengubah sesi/record unit lain dengan manipulasi ID.
- Rekap dapat ditelusuri sampai sesi dan record sumber.
- Dokumen bukti tidak dapat diakses melalui URL publik atau oleh pengguna tanpa grant.
- Sesi batal dan tanggal di luar enrollment tidak memengaruhi rekap kehadiran.

## 8. BP-ASM-01 — Perencanaan asesmen dan pengolahan nilai

### 8.1 Tujuan dan batas
Mendefinisikan proses dari rencana asesmen sampai nilai per siswa tersimpan sebagai draft/hasil yang siap direview. Formula nilai tidak ditetapkan universal dalam dokumen ini.

### 8.2 Jenis dan komponen
Jenis asesmen dapat meliputi formatif, sumatif, proyek, praktik, portofolio, ujian, atau jenis lain yang ditetapkan kurikulum/unit. Kategori, bobot, skala, batas nilai, deskripsi capaian, dan keterkaitan kompetensi harus dikonfigurasi per versi kebijakan/kurikulum yang sah.

### 8.3 Alur utama
1. Guru memilih unit, periode, penawaran mapel, rombel/kelompok, dan assignment aktif.
2. Guru membuat rencana asesmen: nama, tujuan/kompetensi, tipe, tanggal, peserta, instrumen/rubrik bila digunakan, skala, bobot, dan kebijakan remedial.
3. Sistem memeriksa kesesuaian kurikulum, periode, peserta, tanggal, dan hak guru.
4. Rencana disimpan sebagai draft dan dapat diajukan untuk review jika kebijakan mensyaratkan.
5. Setelah rencana aktif, guru mencatat hasil per peserta melalui input satuan, bulk, atau import yang disetujui.
6. Sistem memvalidasi peserta, skala, rentang nilai, kelengkapan, dan duplikasi submission.
7. Guru dapat menambahkan feedback yang sesuai dan tidak memuat informasi sensitif yang tidak perlu.
8. Sistem menghitung agregat hanya menggunakan formula/versi aturan yang disetujui dan mencatat versi formula yang digunakan.
9. Guru meninjau hasil, data kosong, nilai ekstrem, dan anomali; nilai yang belum ada tidak otomatis menjadi nol.
10. Guru mengirim nilai untuk review/pengesahan sesuai workflow unit.
11. Reviewer/wali kelas/kepala memeriksa konsistensi sesuai kewenangan.
12. Nilai disahkan atau dikembalikan dengan alasan; sistem mencatat versi dan audit.
13. Hasil resmi dapat dipublikasikan hanya setelah persyaratan pengesahan terpenuhi.

### 8.4 Pengecualian
- Peserta tidak mengikuti asesmen: gunakan status hasil terpisah (misalnya belum dinilai, tidak hadir, susulan) sesuai kebijakan; jangan otomatis memberi nol.
- Asesmen susulan/remedial: relasi ke asesmen asal, attempt number, tanggal, dan kebijakan penggantian/aggregasi harus jelas.
- Nilai di luar skala: ditolak kecuali skala mendukungnya.
- Guru salah assignment: tolak write; jangan menerima hanya karena user memiliki role guru global.
- Peserta pindah rombel: daftar peserta dinilai berdasarkan snapshot/eligibility pada tanggal asesmen.
- Kesalahan input setelah submit: gunakan request revisi dan approval; nilai lama tetap dapat ditelusuri.
- Perubahan formula setelah nilai dibuat: versi formula baru tidak boleh menghitung ulang nilai resmi lama secara diam-diam.
- Nilai tidak lengkap: workflow dapat tetap draft atau memerlukan exception approval; status missing harus eksplisit.

### 8.5 Aturan bisnis
- Setiap assessment terkait unit, periode, subject offering, dan assignment yang berlaku.
- Hasil peserta terkait enrollment; bukan hanya student profile.
- Setiap nilai menyimpan skala/versi rubrik dan versi formula yang digunakan.
- Bobot total dan formula hanya divalidasi sesuai konfigurasi yang disetujui; tidak diasumsikan selalu 100% tanpa keputusan.
- Missing, exempt, absent, pending, dan zero adalah makna berbeda.
- Remedial/retake tidak boleh menghapus attempt awal.
- Feedback dan rubrik mengikuti aturan akses dan retensi.
- Bulk import wajib preview, validasi per baris, konfirmasi, dan idempotency.
- Nilai yang telah disahkan memerlukan proses revisi formal.
- Perubahan nilai tidak boleh terjadi melalui update massal tersembunyi atau direct overwrite tanpa audit.

### 8.6 State konseptual
- Rencana asesmen: `draft → submitted → approved/active → completed → archived`.
- Batch nilai: `draft → submitted → reviewed → approved → published`.
- Revisi: `requested → approved/rejected → applied`.
- Attempt peserta: `pending → scored → reviewed → finalized`, dengan status khusus untuk absent/exempt/retake sesuai kebijakan.

### 8.7 Data konseptual
AssessmentPlan, AssessmentType, AssessmentComponent, RubricVersion, ScoringScaleVersion, GradingPolicyVersion, AssessmentParticipant, AssessmentAttempt, AssessmentResult, ResultRevision, GradeReview, Approval, PublicationBatch, AuditEvent.
Hindari menyimpan formula dinamis yang dieksekusi sebagai kode bebas. Formula harus berupa konfigurasi tervalidasi atau implementasi yang di-versioning dan diuji.

### 8.8 Authorization baseline
- Guru: membuat rencana dan input hasil untuk assignment yang aktif.
- Admin akademik: konfigurasi kebijakan/struktur; tidak otomatis mengedit nilai individual.
- Reviewer: review dan kembalikan hasil; approve sesuai pemisahan tugas.
- Wali kelas: melihat agregat lintas mapel untuk kelas yang ditugaskan; edit hanya jika kebijakan eksplisit.
- Kepala: pengesahan/publikasi sesuai aturan unit.
- Siswa/wali: hanya hasil yang telah dipublikasikan dan terkait enrollment/relasi.
- Operator: bantuan administrasi tanpa hak mengubah nilai resmi kecuali delegated permission dengan audit.

### 8.9 Acceptance criteria
- Nilai hanya dapat dimasukkan untuk peserta dan assignment yang sah.
- Missing tidak disamakan dengan nol.
- Formula dan skala yang digunakan dapat diidentifikasi pada hasil.
- Pengesahan/publikasi ditolak jika persyaratan wajib belum terpenuhi.
- Revisi nilai menyimpan nilai lama, nilai baru, alasan, actor, approver, dan waktu.
- Perubahan policy tidak mengubah hasil historis tanpa proses migrasi/recalculation yang disetujui.
- Import tidak membuat hasil ganda dan memberi laporan error per baris.
- Siswa/wali tidak dapat melihat draft atau nilai unit lain.

## 9. BP-ASM-02 — Review, pengesahan, rapor, dan publikasi hasil belajar

### 9.1 Alur utama
1. Setelah nilai mapel dikirim, sistem memeriksa kelengkapan dan status review.
2. Guru memperbaiki item yang dikembalikan; setiap perubahan dicatat.
3. Wali kelas memeriksa kelengkapan hasil kelas, catatan perkembangan, dan data yang menjadi tanggung jawabnya.
4. Admin akademik memeriksa konsistensi struktur, periode, skala, dan kebijakan.
5. Kepala/pejabat berwenang mengesahkan hasil akhir sesuai matriks.
6. Sistem membentuk snapshot hasil belajar per enrollment dan periode menggunakan versi policy yang tercatat.
7. Rapor/dokumen hasil belajar dirender dari snapshot yang disahkan; template dapat bervariasi per bentuk/jenjang dan kebijakan.
8. Pihak berwenang memublikasikan hasil kepada siswa/wali melalui kanal privat.
9. Sistem mencatat waktu publikasi, penerima, versi dokumen, dan status delivery.
10. Permintaan koreksi setelah publikasi melalui workflow resmi; versi sebelumnya tetap dapat diakses oleh role yang berwenang.
11. Setelah masa koreksi dan penutupan periode, hasil diarsipkan dan hanya dapat dibuka kembali dengan approval khusus.

### 9.2 Pengecualian
- Nilai mapel belum lengkap: publikasi ditahan atau menggunakan status pengecualian yang disetujui; tidak boleh menyembunyikan data kosong secara diam-diam.
- Siswa pindah/keluar sebelum periode berakhir: hasil mengikuti enrollment dan kebijakan periode; perlu aturan dokumen parsial.
- Kesalahan identitas: koreksi identitas dan dokumen harus mempertahankan keterkaitan ke record asal.
- Dokumen salah cetak: terbitkan revisi dengan nomor/versi dan tandai dokumen lama superseded bila sesuai kebijakan.
- Periode dikunci: reopen memerlukan alasan, permission khusus, approval, dan audit.
- Wali belum terverifikasi: jangan memublikasikan ke akun wali yang tidak memiliki hubungan sah.

### 9.3 Aturan bisnis
- Rapor merupakan representasi resmi dari snapshot hasil yang disahkan, bukan query langsung atas nilai draft terkini.
- Snapshot mencatat enrollment, unit, periode, kurikulum/policy version, approver, dan publication version.
- Setiap dokumen resmi memiliki identitas versi dan status (draft, approved, published, superseded, revoked bila kebijakan mengizinkan).
- Koreksi tidak menghapus dokumen lama dari audit.
- Hak cetak/unduh dan watermark/validasi dokumen merupakan keputusan kebijakan dan keamanan.
- Tanda tangan elektronik hanya boleh memakai mekanisme dan penyedia yang sah setelah review legal/teknis; gambar tanda tangan bukan otomatis tanda tangan elektronik yang sah.

### 9.4 Acceptance criteria
- Snapshot hanya dibuat dari hasil yang telah disahkan.
- Dokumen hanya dipublikasikan ke audience yang berwenang.
- Revisi dokumen menautkan versi sebelumnya dan alasan perubahan.
- Periode yang dikunci tidak dapat diubah melalui endpoint biasa.
- Dokumen dapat diverifikasi ke versi data dan policy sumbernya.

## 10. Kontrak lintas modul, API, event, dan laporan

### 10.1 Kontrak data
- Academic structure menyediakan versi struktur, rombel, subject offering, dan assignment.
- Enrollment menyediakan identitas peserta dan status efektif per unit/periode.
- Session menyediakan konteks kejadian belajar.
- Attendance menyediakan catatan dan ringkasan kehadiran; tidak mengubah enrollment.
- Assessment menyediakan hasil dan status pengesahan; tidak mengubah identitas siswa.
- Report card mengonsumsi snapshot hasil sah dan tidak menjadi sumber utama nilai mentah.

### 10.2 Kandidat API konseptual
Nama endpoint hanya contoh untuk diskusi, bukan kontrak final:
- `GET/POST /api/units/{unit}/academic-years/{year}/class-groups`
- `POST /api/class-groups/{group}/placements`
- `POST /api/subject-offerings/{offering}/teaching-assignments`
- `POST /api/timetables/{timetable}/validate`
- `POST /api/timetables/{timetable}/publish`
- `POST /api/sessions/{session}/attendance:submit`
- `POST /api/attendance-corrections`
- `POST /api/assessment-plans/{plan}/results:bulk`
- `POST /api/grade-batches/{batch}/submit`
- `POST /api/grade-batches/{batch}/approve`
- `POST /api/report-cards/{snapshot}/publish`

Semua endpoint wajib memiliki authorization server-side, validasi scope, request validation, rate limit sesuai risiko, audit, idempotency untuk command yang dapat diulang, serta error contract yang tidak membocorkan data lintas tenant.

### 10.3 Kandidat event
`AcademicStructureApproved`, `ClassPlacementChanged`, `TeachingAssignmentChanged`, `TimetablePublished`, `TimetableChanged`, `LearningSessionOpened`, `LearningSessionCancelled`, `AttendanceSubmitted`, `AttendanceCorrectionRequested`, `AttendanceCorrected`, `AssessmentPublished`, `GradeBatchSubmitted`, `GradeBatchApproved`, `ReportCardPublished`, `AcademicPeriodLocked`.
Event harus berversi, memiliki event ID, tenant/unit context, occurred_at, actor/source, correlation ID, dan aturan retry/deduplication.

### 10.4 Laporan minimum untuk discovery
- Daftar rombel, peserta, kapasitas, dan perubahan penempatan.
- Jadwal per guru/rombel/ruang dan konflik.
- Jurnal sesi pembelajaran dan sesi batal.
- Rekap presensi per siswa, rombel, tanggal, dan periode; tampilkan denominator serta status yang belum dicatat.
- Daftar koreksi presensi dan approval.
- Kelengkapan asesmen dan nilai per mapel/rombel.
- Daftar nilai pending/review/rejected/revised.
- Rekap hasil belajar dan status publikasi rapor.
- Audit perubahan struktur, presensi, nilai, dan publikasi.

## 11. Screen inventory awal

| Area | Layar | Pengguna utama |
|---|---|---|
| Struktur akademik | Tahun ajaran/periode dan konfigurasi | Admin akademik |
| Struktur akademik | Tingkat, kelas, rombel, kapasitas | Admin akademik/operator |
| Struktur akademik | Penempatan siswa dan riwayat | Admin akademik |
| Struktur akademik | Kurikulum, mapel, penawaran mapel | Admin akademik |
| Penugasan | Assignment guru/mapel/wali kelas | Admin akademik |
| Jadwal | Kalender, slot, editor jadwal | Admin akademik |
| Jadwal | Konflik, review, publikasi | Admin akademik/kepala |
| Pembelajaran | Jadwal guru dan sesi hari ini | Guru |
| Pembelajaran | Detail sesi dan catatan aktivitas | Guru |
| Presensi | Daftar peserta dan input status | Guru/petugas |
| Presensi | Rekap, anomali, koreksi | Wali kelas/operator |
| Presensi | Approval koreksi dan audit | Kepala/reviewer |
| Asesmen | Rencana asesmen dan rubrik | Guru |
| Asesmen | Input/bulk nilai dan validasi | Guru |
| Asesmen | Review dan pengesahan nilai | Reviewer/kepala |
| Hasil belajar | Preview snapshot dan rapor | Wali kelas/admin akademik |
| Hasil belajar | Publikasi dan histori versi | Kepala/operator |
| Portal | Jadwal, presensi, hasil yang dipublikasikan | Siswa/wali |

Semua layar harus menyediakan empty/loading/error/permission-denied state, akses keyboard, responsive layout, dan penjelasan error yang dapat ditindaklanjuti.

## 12. Minimum test scenarios

### Struktur dan jadwal
1. Admin unit A tidak dapat membuat rombel di unit B.
2. Enrollment unit A tidak dapat ditempatkan ke rombel unit B.
3. Penempatan aktif ganda ditolak sesuai aturan.
4. Kapasitas penuh menghasilkan validasi dan jalur override yang diaudit.
5. Assignment guru yang bentrok ditolak atau ditandai sebagai exception yang disetujui.
6. Guru yang tidak memiliki assignment tidak dapat membuka sesi.
7. Perubahan rombel/guru tidak mengubah histori sesi.

### Presensi
8. Peserta di luar snapshot sesi tidak dapat diberi presensi.
9. Status belum dicatat tidak otomatis menjadi absent.
10. Retry request menghasilkan record yang sama, bukan duplikat.
11. Koreksi tanpa alasan ditolak.
12. Koreksi setelah lock membutuhkan approval khusus.
13. Guru tidak dapat mengubah presensi unit lain dengan IDOR.
14. Sesi batal tidak masuk denominator kehadiran.
15. Evidence privat tidak dapat diakses tanpa permission.

### Asesmen dan rapor
16. Guru tanpa assignment tidak dapat menginput nilai.
17. Peserta yang tidak eligible pada tanggal asesmen ditolak.
18. Nilai di luar skala ditolak.
19. Missing tidak otomatis menjadi nol.
20. Formula/policy version tersimpan pada hasil.
21. Nilai yang sudah disahkan tidak dapat dioverwrite melalui endpoint biasa.
22. Revisi menyimpan before/after, alasan, approver, dan timestamp.
23. Draft tidak terlihat di portal siswa/wali.
24. Snapshot rapor hanya dapat dibuat dari hasil yang sah.
25. Revisi rapor mempertahankan versi sebelumnya.
26. Pengguna tenant/unit lain tidak dapat membaca file, export, event, cache, atau laporan hasil.

## 13. Keputusan terbuka yang harus ditutup

| ID | Pertanyaan | Mengapa penting | Pemilik keputusan yang disarankan |
|---|---|---|---|
| OPEN-ACA-01 | Apakah jadwal, sesi pembelajaran, dan jurnal mengajar masuk MVP? | Batas MVP dan dependency | Product owner |
| OPEN-ACA-02 | Apakah satu siswa dapat memiliki penempatan paralel (program/kelas lintas rombel)? | Constraint dan model peserta | Product owner + akademik |
| OPEN-ACA-03 | Apakah mapel pilihan/lintas rombel didukung pada rilis awal? | Enrollment mapel | Product owner |
| OPEN-ACA-04 | Apakah ruang/lokasi wajib untuk jadwal? | Model konflik | Akademik |
| OPEN-ACA-05 | Apakah penjadwalan otomatis diperlukan? | Kompleksitas dan risiko | Product owner |
| OPEN-ATT-01 | Status presensi final apa yang dibutuhkan tiap jenjang/bentuk? | Rekap dan regulasi | Akademik + stakeholder |
| OPEN-ATT-02 | Apakah presensi dicatat per sesi, per hari, atau keduanya? | Model transaksi dan denominator | Product owner + akademik |
| OPEN-ATT-03 | Siapa boleh input, submit, koreksi, dan approve? | Segregation of duties | Kepala/unit |
| OPEN-ATT-04 | Berapa batas waktu input dan koreksi? | Locking dan workflow | Kepala/unit |
| OPEN-ATT-05 | Apakah QR/kode sesi dibutuhkan pada MVP? | Threat model dan UX | Product owner |
| OPEN-ATT-06 | Apakah notifikasi wali diperlukan, lewat kanal apa, dan dengan consent apa? | Privasi/biaya/provider | Product owner |
| OPEN-ATT-07 | Apakah offline attendance diperlukan? | Konflik sinkronisasi dan keamanan | Product owner |
| OPEN-ASM-01 | Skala, kategori, bobot, formula, dan pembulatan apa yang berlaku? | Perhitungan nilai | Akademik + sumber resmi |
| OPEN-ASM-02 | Bagaimana status absent, exempt, susulan, remedial, dan retake? | Semantik nilai | Akademik |
| OPEN-ASM-03 | Siapa reviewer/approver dan apakah pembuat boleh mengesahkan? | Kontrol internal | Kepala/unit |
| OPEN-ASM-04 | Apakah rapor per term, semester, tahunan, atau kombinasi? | Snapshot dan template | Product owner + akademik |
| OPEN-ASM-05 | Format rapor dan deskripsi capaian berbeda untuk bentuk/jenjang apa? | Template dan regulasi | Akademik + stakeholder |
| OPEN-ASM-06 | Apakah tanda tangan elektronik dan verifikasi dokumen masuk MVP? | Legal/integrasi | Product owner |
| OPEN-CROSS-01 | Kebijakan retensi presensi, nilai, rubrik, dan dokumen bukti? | Privasi dan storage | Product owner/legal |
| OPEN-CROSS-02 | Zona waktu dan kalender lokal unit ditetapkan bagaimana? | Konsistensi jadwal dan audit | Product owner |

## 14. Gerbang sebelum implementasi

Dokumen ini belum menjadi spesifikasi implementasi final. Sebelum migration/domain code dibuat, minimal:
1. Validasi alur dengan perwakilan sekolah umum dan madrasah dari jenjang yang menjadi target rilis.
2. Tetapkan MVP dan keputusan terbuka yang memengaruhi model data.
3. Verifikasi sumber resmi untuk kalender, kurikulum, presensi, penilaian, dan dokumen hasil belajar; catat penerbit, URL, versi, tanggal akses, dan tanggal efektif.
4. Setujui permission matrix dan approval matrix per proses.
5. Sinkronkan domain model, ERD logis, data dictionary, constraint, retention, API/event, dan test plan.
6. Jalankan PoC untuk tenant/unit isolation, concurrency, bulk import, audit, dan private file storage.
7. Dapatkan persetujuan eksplisit product owner atas baseline dan gerbang PoC.

**Larangan sementara:** jangan menganggap metode biometrik/lokasi wajib; jangan mengunci formula nilai universal; jangan mengubah hasil historis secara otomatis; jangan memulai implementasi fitur hanya berdasarkan draft ini.

## 15. Traceability

| Process ID | Requirement/module dependency | Output/data utama | Downstream |
|---|---|---|---|
| BP-ACA-01 | BP-ORG-02, BP-STD-01, BP-HR-01 | Struktur, rombel, penempatan, subject offering, assignment | BP-ACA-02, BP-ACA-03, BP-ATT-01, BP-ASM-01 |
| BP-ACA-02 | BP-ACA-01, kalender | Timetable version, conflict, publication | BP-ACA-03, BP-ATT-01 |
| BP-ACA-03 | BP-ACA-01/02, enrollment | Learning session, participant snapshot | BP-ATT-01, BP-ASM-01 |
| BP-ATT-01 | BP-ACA-03, BP-STD-01/02 | Attendance session/record/revision/summary | Portal, reporting, communication |
| BP-ASM-01 | BP-ACA-01/03, BP-ORG-02 | Assessment plan, attempts, results, grading policy version | BP-ASM-02 |
| BP-ASM-02 | BP-ASM-01, BP-STD-01/02 | Approved result snapshot, report card, publication | Portal, archive, reporting |

## 16. Riwayat perubahan
- 2026-11-18 — Draft 0.1.0 dibuat sebagai spesifikasi proses awal BP-ACA-01—03, BP-ATT-01, BP-ASM-01—02. Belum melalui validasi stakeholder atau verifikasi regulasi.
