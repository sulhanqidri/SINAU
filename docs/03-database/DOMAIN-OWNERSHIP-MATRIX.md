# Domain Ownership Matrix SINAU

**Status:** Draft baseline — diturunkan dari MVP-SCOPE yang disetujui 2026-11-18; menunggu review domain dan stakeholder  
**Versi:** 0.1.0  
**Ruang lingkup:** Domain MVP SINAU; domain post-MVP dicatat hanya sebagai batas dependensi  
**Acuan:** `docs/02-requirements/MVP-SCOPE.md`, `BUSINESS-PROCESS-MAP.md`, spesifikasi proses, `DOMAIN-MODEL.md`, ADR-001—006.

## 1. Tujuan dan aturan ownership

Dokumen ini menetapkan *authoritative owner* untuk setiap kelompok data. Domain owner bertanggung jawab atas definisi, validasi, lifecycle, perubahan, dan kualitas data. Domain lain mengonsumsi data melalui kontrak yang disepakati; tidak boleh membuat salinan yang menjadi sumber kebenaran kedua.

Prinsip:
1. Satu kelompok data memiliki satu domain pemilik. Satu domain boleh menerbitkan data untuk banyak consumer.
2. **Tenant** adalah batas pelanggan SaaS, kontrak, billing, dan isolasi; **education unit** adalah batas operasional sekolah/madrasah. Jenis/jenjang pendidikan melekat pada unit.
3. Scope data harus eksplisit: platform, tenant, atau unit. User identity bersifat global; grant akses bersifat tenant/unit.
4. Role/permission tidak sama dengan entitlement. Subscription tidak otomatis memberi akses pengguna; role tidak boleh melewati entitlement.
5. Histori status, assignment, enrollment, presensi, dan nilai tidak ditimpa atau dihapus diam-diam.
6. Data sensitif tidak otomatis dapat dibagikan lintas unit/tenant hanya karena identitas orang sama.
7. Ownership ini adalah baseline konseptual. Field, schema, FK, RLS, API, dan migration menunggu logical design, privacy/security review, PoC, serta ADR.

## 2. Matriks ownership domain

| ID | Bounded context / domain | Authoritative owner (data) | Scope utama | Entitas/aggregate konseptual | Consumer utama | Batas dan aturan |
|---|---|---|---|---|---|---|
| DOM-01 | SaaS Tenant & Organization | Platform/Tenant domain | Platform + tenant | Tenant, FoundationProfile, EducationUnit | Subscription, Verification, Identity, seluruh domain unit | Tenant memiliki unit; satu unit berada pada satu tenant aktif. Tenant type bukan jenis/jenjang pendidikan. |
| DOM-02 | Identity & Authentication | Identity domain | Global/platform | User, credential, authentication factors, session identity | Semua domain yang memerlukan actor identity | User bukan EmployeeProfile/StudentProfile. Akun global tidak berarti akses ke tenant/unit. |
| DOM-03 | Membership & Authorization | Identity & Access domain | Tenant + unit + platform scope terbatas | TenantMembership, UnitMembership, Role, Permission, RoleAssignment, Invitation | Semua endpoint/UI/job dan audit | Membership dan role assignment adalah grant eksplisit; default-deny. Revocation harus berdampak pada akses berikutnya dan job/file terkait. |
| DOM-04 | Subscription & Entitlement | SaaS Commercial domain | Tenant | Plan, Subscription, Entitlement, Usage/Quota | Tenant management, feature gates, unit provisioning | Mengatur hak layanan/kuota; tidak memiliki user role atau verification decision. Downgrade tidak menghapus data/unit. |
| DOM-05 | Tenant/Unit Verification | Verification domain | Tenant atau unit | VerificationCase, EvidenceReference, VerificationDecision, Deadline | Onboarding, tenant operations, compliance support | Status verification terpisah dari subscription dan operational lifecycle. Bukti harus private dan akses terbatas. |
| DOM-06 | Tenant/Unit Operational Lifecycle | Tenant Operations domain | Tenant atau unit | LifecycleCase, Suspension/Closure/Transfer/Restore event | Platform operations, Identity, data export/retention controls | Tidak mengambil alih billing suspension atau membership revocation. Transfer lintas tenant tetap high-impact dan belum disetujui secara legal/privacy/teknis. |
| DOM-07 | Institution Profile & Reference Configuration | Institution Configuration domain | Unit; sebagian katalog platform | InstitutionProfile, EducationType, EducationLevel, official identifiers, address/contact | Academic, verification, reports | Profil institusi dan identitas resmi unit. Reference catalog global/override tenant masih perlu keputusan. |
| DOM-08 | Academic Calendar & Periods | Academic Configuration domain | Unit | AcademicCalendar, AcademicYear, AcademicTerm, EffectivePeriod | Curriculum, enrollment, attendance, assessment | Periode memiliki tanggal efektif dan aturan tidak overlap sesuai kebijakan yang akan ditetapkan. |
| DOM-09 | Curriculum & Subject Structure | Curriculum domain | Unit + versi/periode | CurriculumVersion, Subject, CurriculumSubject, SubjectGroup, GradeLevel | Academic Organization, assessment, reporting | Kurikulum/mapel berversi; jangan mengasumsikan sekolah umum dan madrasah memiliki struktur sama. |
| DOM-10 | Student Profile & Guardian Relationship | Student domain | Unit/tenant sesuai kebijakan identitas; akses sangat terbatas | StudentProfile, GuardianProfile/Person reference, StudentGuardian | Enrollment, attendance, assessment, authorized guardian services | StudentProfile bukan akun login. Identitas lintas unit/tenant, shared Person, wali utama, verifikasi relasi, dan disclosure masih terbuka. |
| DOM-11 | Student Enrollment & Status | Student domain | Unit + academic year/term | StudentEnrollment, EnrollmentStatusHistory | Class, attendance, assessment, student reporting | Enrollment adalah keikutsertaan siswa pada unit/periode/rombel. Histori dipertahankan; aturan multi-enrollment aktif perlu keputusan. |
| DOM-12 | Employee & HR Minimum | HR domain | Tenant/unit sesuai penempatan | EmployeeProfile, EmploymentStatusHistory, EmployeePlacement | Academic Organization, access provisioning bila diberi grant | HR memiliki profil, status kerja, dan penempatan dasar. HR tidak memiliki login, role, atau teaching assignment. HRIS lanjutan post-MVP. |
| DOM-13 | Academic Organization & Teaching Assignment | Academic domain | Unit + periode | ClassGroup, HomeroomAssignment, TeachingAssignment, ClassSubject | Attendance, assessment, timetable future | Academic memiliki rombel dan assignment efektif; merujuk EmployeeProfile milik HR. Tidak menduplikasi profil pegawai. |
| DOM-14 | Attendance | Attendance domain | Unit + enrollment + session context | AttendanceSession/SessionContext, AttendanceRecord, AttendanceCorrection | Academic operations, authorized recap/export | Attendance merujuk enrollment dan sesi/periode yang tepat. Koreksi wajib alasan, actor, timestamp, audit. Session model minimal perlu diputuskan tanpa timetable engine. |
| DOM-15 | Assessment & Basic Scores | Assessment domain | Unit + enrollment + assessment period | AssessmentDefinition, AssessmentCategory, StudentScore, ScoreChangeHistory, AssessmentSummary | Teacher workflows, basic recap/export | Formula dapat dikonfigurasi; tidak mengunci format rapor nasional/madrasah. Formal approval/report-card workflow post-MVP. |
| DOM-16 | Import | Data Import domain | Tenant/unit target | ImportBatch, ImportRow, ValidationIssue, ImportResult | Student, HR, institution, academic domains | Domain target tetap pemilik record; Import domain mengelola staging, validasi, hasil baris, dan audit, bukan menjadi master data. |
| DOM-17 | Export | Data Export domain | Tenant/unit + actor permission | ExportJob, ExportArtifact, ExportAccessEvent | Authorized domain consumers | Export hanya membaca data sesuai permission dan scope; artefak privat, kedaluwarsa, dan tercatat. |
| DOM-18 | Audit | Audit/Platform Security domain | Platform/tenant/unit | AuditEvent, CorrelationContext | Security, support, domain owners | Domain menerbitkan fakta audit; audit service menyimpan jejak immutable/tamper-evident sesuai desain. Hindari menaruh rahasia atau data pribadi berlebihan. |
| DOM-19 | File & Evidence Storage | File/Document Infrastructure domain | Platform/tenant/unit dengan owner reference | StoredFile, FileVersion, AccessGrant, RetentionMetadata | Verification, student, HR, import/export | Menyimpan metadata dan private object reference; domain pemilik tetap menentukan makna dan hak atas dokumen. Malware scan, retention, signed access perlu desain. |
| DOM-20 | Notifications & Delivery | Platform Communication domain | Tenant/unit + recipient | Notification, DeliveryAttempt, Template | Tenant, HR, academic, attendance, verification | Mengirim notifikasi berdasarkan event dan preferensi; bukan sumber kebenaran status domain. Kanal/provider belum dipilih. |

## 3. Data yang tidak boleh memiliki dua sumber kebenaran

| Data | Pemilik | Bukan pemilik |
|---|---|---|
| Login identity, credential, session actor | Identity | HR, Student, Academic |
| Tenant/unit profile dan tenant relationship | SaaS Tenant & Organization | Verification, Academic |
| Subscription, entitlement, quota | SaaS Commercial | Identity, Tenant Operations |
| Verification result/evidence status | Verification | Subscription, Tenant Operations |
| Employment profile/status/placement | HR | Identity, Academic |
| Teaching/homeroom assignment dan class group | Academic | HR |
| Student profile dan guardian relationship | Student | Identity, Attendance |
| Enrollment dan enrollment history | Student | Academic, Attendance |
| Attendance transaction/correction | Attendance | Student, Academic |
| Assessment definition/score | Assessment | Student, Attendance |
| Import batch/row processing | Import | Domain target master data |
| Export job/artifact | Export | Domain sumber data |
| Audit event record | Audit | Domain yang menerbitkan event |

## 4. Kontrak lintas domain yang wajib dijaga

1. **Tenant → Unit:** pembuatan unit memeriksa entitlement server-side; setiap unit memiliki tenant aktif tepat satu.
2. **Identity → domain:** consumer menerima actor context dan membership/permission result, bukan menafsirkan profil pegawai/siswa sebagai hak akses.
3. **HR → Academic:** Academic merujuk employee identifier dan effective placement; perubahan status pegawai tidak menghapus assignment historis. Perubahan assignment dilakukan oleh Academic dengan effective date dan audit.
4. **Student → Academic:** Student menerbitkan enrollment yang valid; Academic menempatkan enrollment pada rombel sesuai periode dan aturan yang kelak disahkan.
5. **Student → Attendance/Assessment:** transaksi merujuk enrollment yang benar, bukan hanya student identifier global.
6. **Academic → Attendance:** session context menyediakan kelas/periode yang sah; Attendance tetap pemilik catatan hadir dan koreksi.
7. **Verification → Tenant Operations:** verification dapat memicu kebijakan akses sesuai keputusan; tidak boleh menulis subscription status.
8. **Subscription → entitlement enforcement:** entitlement menjadi input feature/quota gate; tidak mengubah role/membership.
9. **Domain → Audit:** aksi sensitif menerbitkan audit event dengan actor, scope, target, timestamp, dan correlation reference yang cukup tanpa menyimpan secret.
10. **Domain → Import/Export:** proses bulk harus menjalankan validasi/authorization domain yang sama dengan operasi biasa.

## 5. Scope MVP versus roadmap

Ownership DOM-01—05, DOM-07—20 berlaku untuk kemampuan minimum MVP sesuai MVP-SCOPE.md. DOM-06 hanya mencakup kontrol lifecycle yang telah didefinisikan dalam process specifications dan tidak berarti seluruh transfer/restore otomatis siap diimplementasikan. Area post-MVP tetap memiliki calon owner konseptual, tetapi tidak boleh dibuat detail schema atau migration tanpa discovery/change request:

- PPDB end-to-end dan admission payment.
- HRIS lanjutan: kontrak terperinci, cuti, presensi pegawai, payroll, offboarding.
- Timetable engine lengkap dan room scheduling.
- Learning delivery/LMS.
- Formal report card workflow, transcript, publication/archive.
- Advanced student lifecycle: transfer lintas unit, formal leave, mass promotion, graduation, alumni.
- Finance, procurement, accounting, budget.
- Counseling, library, inventory/assets, correspondence, full portals, external integrations.

## 6. Keputusan terbuka dan risiko

| ID | Pertanyaan/keputusan | Risiko bila diputuskan terlalu dini | Tindak lanjut |
|---|---|---|---|
| OWN-01 | Apakah `Person` menjadi shared master siswa, wali, pegawai? | Deduplikasi salah, akses lintas konteks, paparan data anak | Privacy review dan identity lifecycle analysis |
| OWN-02 | Apakah siswa dapat memiliki lebih dari satu enrollment aktif bersamaan? | Constraint dan transaksi presensi/nilai ambigu | Validasi proses dengan sekolah/madrasah |
| OWN-03 | Bagaimana identitas dan histori siswa lintas tenant dikelola? | Pengungkapan data lintas pengendali | Legal/privacy review dan transfer policy |
| OWN-04 | Apakah employee dapat ditempatkan lintas unit/tenant? | Assignment dan akses pegawai salah scope | Validasi HR dan tenant governance |
| OWN-05 | Apa model session context minimum untuk presensi? | Presensi tidak konsisten tanpa timetable | Validasi guru/operator dan acceptance criteria |
| OWN-06 | Bagaimana relasi wali, wali utama, verifikasi, dan akses portal? | Wali salah melihat data siswa | Privacy-by-design dan stakeholder review |
| OWN-07 | Reference catalog mana yang platform-global dan mana yang tenant-configurable? | Konfigurasi tidak konsisten atau sulit dikembangkan | Domain configuration design |
| OWN-08 | Retention, archive, pseudonymization, deletion, legal hold untuk data anak/pegawai? | Risiko hukum dan operasional | Data classification & retention blueprint |
| OWN-09 | Apakah satu tenant dapat memiliki pegawai/identity yang dipakai di banyak unit dengan grant terpisah? | Duplikasi HR dan kebocoran akses | HR/identity cross-domain review |
| OWN-10 | Bagaimana audit immutable/tamper-evident dan privileged support access? | Perubahan sensitif tidak dapat ditelusuri | Security architecture dan ADR |

Tidak ada jawaban pada tabel ini yang boleh diasumsikan final. Keputusan yang mengubah kontrak lintas domain dicatat pada ADR atau change request.

## 7. Acceptance criteria

- [ ] Setiap entitas MVP pada logical ERD memiliki tepat satu authoritative owner.
- [ ] Scope setiap entitas (platform/global, tenant, unit, atau user-global) ditetapkan.
- [ ] Setiap consumer memiliki tujuan penggunaan dan kontrak akses yang jelas.
- [ ] Tidak ada duplikasi sumber kebenaran antara HR/Academic/Identity/Student/Attendance/Assessment.
- [ ] Lifecycle dan histori untuk status, enrollment, assignment, attendance, dan score ditentukan.
- [ ] Semua relasi unit-scoped menjaga konsistensi tenant dan unit.
- [ ] Data anak, guardian, employee, file, dan export memiliki klasifikasi serta policy akses/retensi.
- [ ] Semua keputusan terbuka berdampak tinggi memiliki owner dan rencana penyelesaian.
- [ ] Matriks ditinjau bersama spesifikasi proses dan disetujui sebelum logical ERD dianggap baseline.

## 8. Riwayat perubahan

| Tanggal | Versi | Perubahan |
|---|---|---|
| 2026-11-18 | 0.1.0 | Draft ownership matrix pertama diturunkan dari MVP baseline dan process specifications. |


## 9. Klarifikasi ownership untuk remediation logical design v0.2.0

Bagian ini memperjelas batas domain untuk proposal AUD-LD-001; tidak menggantikan persetujuan owner final.

- **Student domain** tetap authoritative owner untuk StudentEnrollment dan lifecycle keikutsertaan siswa.
- **Academic domain** tetap authoritative owner untuk ClassGroup, CurriculumSubject, HomeroomAssignment, dan TeachingAssignment.
- **StudentClassPlacement** adalah relasi yang menghubungkan StudentEnrollment dengan ClassGroup. Candidate ownership ditempatkan pada Student karena placement merupakan bagian dari lifecycle enrollment; Academic menyediakan referensi ClassGroup dan memvalidasi struktur/periode/grade. Keputusan ini harus dikonfirmasi Product Owner dan domain owner sebelum logical design diterima.
- **Attendance domain** memiliki AttendanceSessionParticipant snapshot, AttendanceRecord, AttendanceRecordRevision, dan AttendanceCorrection. Snapshot dibentuk dari enrollment/placement yang disediakan Student/Academic; sumber master tidak disalin.
- **Assessment domain** memiliki AssessmentParticipant snapshot, AssessmentDefinition, StudentScore, dan ScoreRevision/History. Snapshot memakai enrollment/placement serta struktur kurikulum dari owner masing-masing.
- Snapshot peserta pada Attendance/Assessment adalah fakta transaksi domain tersebut, bukan master enrollment atau class placement baru.
- HR tetap memiliki EmployeeProfile, EmploymentStatusHistory, dan EmployeePlacement; Academic memiliki assignment mengajar/wali kelas. Validasi tanggal efektif adalah kontrak lintas domain.

### Kontrak lintas domain yang diperjelas

1. Student menerbitkan enrollment dan placement efektif tanggal.
2. Academic menerbitkan class group, grade, curriculum subject, dan teaching assignment.
3. Attendance/Assessment membaca snapshot enrollment + placement yang berlaku pada tanggal transaksi dan menyimpan referensi sumber.
4. Perubahan data master sesudah transaksi tidak mengubah snapshot historis.
5. Tidak ada domain consumer yang menulis master domain lain; perubahan dilakukan melalui owner domain dan dicatat audit.

