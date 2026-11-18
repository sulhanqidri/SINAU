# SINAU Blueprint Catalog & Completeness Matrix

**Status:** Working catalog — baseline, belum seluruh spesifikasi selesai  
**Tanggal:** 2026-11-18  
**Pemilik keputusan:** Product owner SINAU  
**Tracker utama:** [PROJECT-PROGRESS.md](../00-governance/PROJECT-PROGRESS.md)  
**Master blueprint:** [MASTER-BLUEPRINT.md](MASTER-BLUEPRINT.md)

Dokumen ini menetapkan seluruh kelompok blueprint yang wajib tersedia sebelum implementasi domain utama. Daftar ini adalah inventaris kebutuhan dokumentasi, bukan klaim bahwa seluruh fitur telah disetujui atau akan masuk MVP.

## 1. Aturan status

- **Existing baseline:** dokumen tersedia, tetapi kedalaman/validasinya masih perlu ditinjau.
- **In progress:** sudah ada sebagian isi atau keputusan, tetapi belum memenuhi acceptance.
- **Not started:** artefak rinci belum dibuat atau belum diaudit.
- **Accepted:** disetujui pemilik produk dan dicatat sebagai keputusan; bukan sekadar sudah ditulis.

Sebuah blueprint dianggap lengkap bila memuat tujuan, ruang lingkup, aktor, alur utama/alternatif/gagal, aturan bisnis, data, otorisasi, audit, integrasi, laporan, acceptance criteria, risiko, dependensi, dan sumber aturan bila relevan.

## 2. Product, business & governance blueprint

| Artefak | Lokasi target | Status awal |
|---|---|---|
| Project constitution dan prinsip produk | `docs/00-governance/PROJECT-CONSTITUTION.md` | Existing baseline |
| Development rules dan Definition of Done | `docs/00-governance/DEVELOPMENT-RULES.md` | Existing baseline |
| Change control | `docs/00-governance/CHANGE-CONTROL.md` | Existing baseline |
| Project progress dan session handoff | `docs/00-governance/PROJECT-PROGRESS.md` | Existing baseline — dibuat 2026-11-18 |
| Product vision, positioning, target market | `docs/01-blueprint/MASTER-BLUEPRINT.md` | In progress |
| Product Requirements (SRS/PRD) | `docs/02-requirements/PRODUCT-REQUIREMENTS.md` | Existing baseline; perlu validasi |
| MVP scope dan release boundary | `docs/02-requirements/MVP-SCOPE.md` | Existing baseline; perlu persetujuan |
| Persona, jobs-to-be-done, user journey | `docs/02-requirements/PERSONAS-AND-JOURNEYS.md` | Not started/audit path |
| Acceptance criteria dan traceability | `docs/02-requirements/ACCEPTANCE-CRITERIA.md` | Existing baseline; perlu kelengkapan |
| Peta proses bisnis end-to-end | `docs/02-requirements/BUSINESS-PROCESS-MAP.md` | Draft baseline v0.1.0; perlu validasi dan spesifikasi turunan |
| Spesifikasi proses organisasi dan peserta didik BP-ORG-01/02, BP-STD-01/02 | `docs/02-requirements/ORGANIZATION-AND-STUDENT-PROCESS-SPECIFICATIONS.md` | Draft 0.1.0; perlu validasi stakeholder, aturan pendidikan, dan keputusan terbuka |
| Spesifikasi proses akademik, presensi, dan asesmen BP-ACA-01—03, BP-ATT-01, BP-ASM-01—02 | `docs/02-requirements/ACADEMIC-ATTENDANCE-ASSESSMENT-PROCESS-SPECIFICATIONS.md` | Draft 0.1.0; perlu validasi stakeholder, kebijakan nilai/presensi, dan verifikasi regulasi |
| Spesifikasi proses PPDB dan HR BP-ADM-01, BP-HR-01 | `docs/02-requirements/ADMISSIONS-AND-HR-PROCESS-SPECIFICATIONS.md` | Draft 0.1.0; perlu validasi stakeholder, regulasi penerimaan, kebijakan kepegawaian, dan privasi |
| Spesifikasi proses platform/tenant BP-PLT-01—06 | `docs/02-requirements/PLATFORM-TENANT-PROCESS-SPECIFICATIONS.md` | Draft 0.1.0; BP-PLT-01—06 terinci sebagai draft; validasi stakeholder dan keputusan terbuka |
| Audit konsistensi spesifikasi proses | `docs/02-requirements/PROCESS-SPECIFICATION-CONSISTENCY-AUDIT.md` | Draft 0.1.0; temuan dan remediasi menunggu keputusan pemilik produk |

| Business glossary dan terminology | `docs/02-requirements/BUSINESS-GLOSSARY.md` | Not started/audit path |
| Assumptions, constraints, risks, dependencies | `docs/02-requirements/ASSUMPTIONS-RISKS-DEPENDENCIES.md` | Not started |
| Stakeholder, RACI, decision rights | `docs/02-requirements/STAKEHOLDERS-AND-RACI.md` | Not started |

### 2.1 Business process map dan spesifikasi proses

- [x] Peta proses bisnis end-to-end tingkat baseline tersedia di `docs/02-requirements/BUSINESS-PROCESS-MAP.md`.
- [ ] Validasi process register, aktor, urutan, pengecualian, dan scope MVP dengan stakeholder.
- [x] Audit konsistensi lintas process map, PRD, MVP Scope, spesifikasi proses, ADR, katalog, dan tracker; temuan dicatat di `docs/02-requirements/PROCESS-SPECIFICATION-CONSISTENCY-AUDIT.md`.
- [x] Selaraskan ID proses platform: BP-PLT-01—06. AUD-01/AUD-02 resolved pada level dokumentasi; BP-PLT-06 kini memiliki spesifikasi rinci draft.
- [ ] Remediasi temuan audit setelah keputusan pemilik produk; jangan renumber ID atau mengubah scope tanpa persetujuan.
- [x] Turunkan BP-PLT-01 sampai BP-PLT-05 ke spesifikasi proses platform/tenant draft di `docs/02-requirements/PLATFORM-TENANT-PROCESS-SPECIFICATIONS.md`.
- [x] Turunkan BP-PLT-06 (lifecycle tenant/unit) menjadi spesifikasi rinci draft pada §14 Platform/Tenant Process Specifications.
- [ ] Validasi spesifikasi BP-PLT-01—05 dengan stakeholder dan tutup OPEN-PLT-01 sampai OPEN-PLT-10.
- [x] Spesifikasikan BP-PLT-06 (lifecycle tenant/unit) dan selaraskan batasnya terhadap BP-PLT-02—05.
- [ ] Putuskan OPEN-PLT-11—18; transfer lintas tenant tetap diblokir sampai legal/privacy/data/teknis disahkan.
- [x] Turunkan BP-ACA-01—03, BP-ATT-01, dan BP-ASM-01—02 ke spesifikasi proses akademik/presensi/asesmen draft di `docs/02-requirements/ACADEMIC-ATTENDANCE-ASSESSMENT-PROCESS-SPECIFICATIONS.md`.
- [x] Turunkan BP-ADM-01 dan BP-HR-01 ke spesifikasi proses PPDB/HR draft di `docs/02-requirements/ADMISSIONS-AND-HR-PROCESS-SPECIFICATIONS.md`.
- [ ] Turunkan proses prioritas lain (keuangan dan layanan pendukung) menjadi business process specification/swimlane per proses.
- [ ] Lengkapi business rules, state machine, approval matrix, SLA, exception/recovery, dan acceptance criteria.
- [ ] Buat traceability requirement → process → module → data/API → permission → screen → test.

## 3. Organization, tenant, identity & SaaS blueprint

| Artefak | Lokasi target | Status awal |
|---|---|---|
| Tenant/customer model | `docs/09-decisions/ADR-001-TENANT-CUSTOMER-MODEL.md` | Existing; accepted |
| Tenant/unit isolation strategy | `docs/09-decisions/ADR-002-DATABASE-ISOLATION-STRATEGY.md` | Existing; baseline accepted, PoC required |
| Identity, membership, role scope | `docs/09-decisions/ADR-003-AUTHORIZATION-SCOPE.md` | Existing; baseline perlu PoC |
| Onboarding, verification, entitlement | `docs/09-decisions/ADR-004-ONBOARDING-VERIFICATION-AND-UNIT-ENTITLEMENTS.md` | Existing; accepted |
| SaaS plan, subscription, billing, usage metering | `docs/06-saas/SAAS-BILLING-AND-ENTITLEMENTS.md` | Not started/audit path |
| Platform operations and support access | `docs/06-saas/PLATFORM-OPERATIONS-AND-SUPPORT.md` | Not started |
| Tenant lifecycle, suspension, downgrade, cancellation | `docs/06-saas/TENANT-LIFECYCLE.md` | Not started |

## 4. Education domain blueprint

**Pemisahan status wajib:** keberadaan Business Process Specification (BPS) draft hanya berarti alur/kontrol bisnis telah dideskripsikan. Itu tidak berarti module blueprint, data model, UI, API, test plan, regulasi, atau implementasi domain telah selesai/diterima. Status `Not started` tetap benar untuk module blueprint yang belum dibuat meskipun BPS terkait tersedia. Scope MVP mengikuti `MVP-SCOPE.md` dan checkpoint Phase 4 di `PROJECT-PROGRESS.md`, bukan sekadar daftar domain atau kelengkapan BPS.


Setiap domain di bawah perlu memiliki module specification tersendiri, bukan hanya daftar fitur. Semua alur harus memperhatikan foundation multi-unit dan independent provider, sekolah umum/madrasah, jenjang, periode efektif, dan kewenangan.

| Domain | Cakupan minimum | Status awal |
|---|---|---|
| Organization & institution master | Profil lembaga, unit, struktur, identitas dan legalitas | In progress |
| Academic calendar & periods | Tahun ajaran, semester, kalender, hari efektif, periode | Not started |
| Curriculum & learning structure | Kurikulum berversi, struktur, mapel, kelompok mapel, program | Not started |
| Admission / PPDB | Gelombang, pendaftaran, seleksi, daftar ulang, enrollment | Not started — process spec draft tersedia; post-MVP, module blueprint belum dimulai |
| Student master & enrollment | Identitas, wali, enrollment, status dasar, riwayat; mutasi/alumni lanjutan | In progress — process spec draft tersedia; minimum MVP dipisah dari lifecycle lanjutan, module blueprint belum lengkap |
| Parent/guardian relationship | Relasi wali, hak akses, komunikasi, persetujuan | Not started |
| Class & homeroom | Rombel, wali kelas, kapasitas, perpindahan | Not started |
| Teacher & staff HR | Profil pegawai minimum, status, penempatan; HRIS lanjutan terpisah | Not started — process spec draft tersedia; hanya subset HR minimum kandidat MVP, module blueprint belum dimulai |
| Timetable & scheduling | Jadwal ruang, guru, rombel, benturan | Not started — process spec draft tersedia; timetable engine post-MVP, module blueprint belum dimulai |
| Attendance | Presensi siswa, koreksi, audit, rekap sederhana | Not started — process spec draft tersedia; scope minimum MVP belum menjadi module blueprint |
| Learning delivery | Sesi minimal untuk konteks transaksi; materi/tugas/LMS lanjutan | Not started — process spec draft tersedia; learning delivery lengkap post-MVP, module blueprint belum dimulai |
| Assessment & grading | Penilaian dasar terkonfigurasi dan rekap sederhana; workflow lanjutan | Not started — process spec draft tersedia; module blueprint belum dimulai |
| Report cards & academic records | Rapor formal, transkrip, publikasi, arsip, koreksi | Not started — process spec draft tersedia; formal report workflow post-MVP, module blueprint belum dimulai |
| Student affairs & counseling | BK, pelanggaran, prestasi, kegiatan, pembinaan | Not started |
| Internship / vocational | PKL/praktik kerja, mitra, pembimbing, penilaian SMK/MAK | Not started |
| School finance | Tagihan, pembayaran, potongan, beasiswa, kas, jurnal, anggaran | Not started — Candidate/post-MVP; belum ada spesifikasi rinci atau keputusan prioritas |
| Procurement & budget planning | Pengadaan, persetujuan, RKS/RKT/RKAS sesuai kebutuhan | Not started |
| Library | Koleksi, eksemplar, sirkulasi, denda, katalog | Not started |
| Inventory & assets | Aset, lokasi, kondisi, pemeliharaan, mutasi | Not started |
| Correspondence & records | Surat masuk/keluar, nomor, disposisi, arsip, retensi | Not started |
| Approval & e-signature | Alur persetujuan, delegasi, tanda tangan via penyedia sah | Not started |
| Communication & announcements | Pengumuman, pesan, target audiens, delivery status | Not started |
| Parent/student/teacher portals | Dashboard dan self-service sesuai akses | Not started |
| Reporting & analytics | Laporan akademik, operasional, keuangan, ekspor | Not started |

### 4.1 Education-specific variants

- [ ] Sekolah umum SD/SMP/SMA/SMK: variasi proses, kurikulum, penilaian, dan pelaporan.
- [ ] Madrasah MI/MTs/MA/MAK: struktur dan kebutuhan khas madrasah, termasuk sumber aturan Kemenag.
- [ ] SMK/MAK: konsentrasi/program keahlian, praktik, PKL, mitra industri, asesmen kompetensi jika disetujui.
- [ ] Pendidikan inklusif/kebutuhan dukungan khusus: kebutuhan privasi dan akses, bila masuk scope.
- [ ] RA/PAUD: tetap di luar baseline sampai ada discovery dan keputusan eksplisit.

Tidak boleh menganggap seluruh jenis lembaga memakai daftar mapel, struktur nilai, kalender, atau format rapor yang sama. Aturan kurikulum/regulasi harus memiliki sumber resmi, versi, dan tanggal efektif.

## 5. Data, database & information architecture

| Artefak | Lokasi target | Status awal |
|---|---|---|
| Domain model | `docs/03-database/DOMAIN-MODEL.md` | Existing baseline; perlu elaborasi |
| ERD conceptual/logical/physical | `docs/03-database/ERD-CONCEPTUAL.md` dan diagram lanjutan | Existing conceptual; logical/physical not started |
| Data dictionary | `docs/03-database/DATA-DICTIONARY-BASELINE.md` | Existing baseline; perlu kelengkapan |
| Data integrity and lifecycle | `docs/03-database/DATA-INTEGRITY.md` | Existing baseline; perlu audit |
| Data classification and privacy | `docs/05-security/DATA-CLASSIFICATION-AND-PRIVACY.md` | Not started/audit path |
| Retention, archive, deletion | `docs/03-database/DATA-RETENTION-AND-ARCHIVING.md` | Not started |
| Master/reference data governance | `docs/03-database/REFERENCE-DATA-GOVERNANCE.md` | Not started |
| Import/export contracts | `docs/03-database/IMPORT-EXPORT-SPECIFICATION.md` | Not started |
| Database PoC plan and evidence | `docs/01-blueprint/DATABASE-POC-PLAN.md` | Existing; partial execution |

## 6. Application, integration & platform architecture

- [ ] Context diagram dan system boundary.
- [ ] Logical application architecture dan modular boundaries.
- [ ] Module dependency map dan ownership data.
- [ ] API catalog, versioning, authentication, error model, pagination, rate limit.
- [ ] Event catalog, webhook contract, retry, idempotency, dead-letter handling.
- [ ] Queue/scheduler design dan tenant/unit propagation.
- [ ] Cache/search strategy dan tenant-aware key/index.
- [ ] File/object storage, malware scanning, signed URL, retention.
- [ ] Notification channels dan provider abstraction.
- [ ] External integration inventory: pemerintah/pendidikan, payment, email/SMS/WhatsApp, e-signature, identity, accounting/export.
- [ ] Vendor assessment, legal basis, credentials, failure mode, reconciliation, sandbox/UAT.
- [ ] Mobile/PWA strategy dan offline behavior bila dibutuhkan.
- [ ] ADR untuk stack, auth/session, queue/cache, storage, observability, deployment.

Existing starting points: `docs/01-blueprint/SYSTEM-ARCHITECTURE.md`, `docs/01-blueprint/TECHNOLOGY-OPTIONS.md`, dan ADR di `docs/09-decisions/`.

## 7. Security, privacy, compliance & trust

- [ ] Threat model dan abuse cases.
- [ ] Authentication, MFA, password/session/device lifecycle.
- [ ] Authorization matrix per role, tenant, unit, resource, action, relationship.
- [ ] Privileged support/break-glass access dengan approval dan audit.
- [ ] Tenant isolation test matrix untuk API, UI, SQL, bulk, export, file, cache, search, queue, scheduler.
- [ ] RLS decision, policy, connection pooling, context reset, bypass/owner model.
- [ ] Data classification, minimization, consent/legal basis, retention, subject rights.
- [ ] Encryption in transit/at rest, secret management, key rotation.
- [ ] Audit event catalog, tamper resistance, log redaction.
- [ ] Vulnerability management, dependency/SBOM, patch policy, incident response.
- [ ] Regulatory register dengan sumber resmi, versi, effective date, status verifikasi.
- [ ] Security test plan, penetration test scope, remediation gate.

Starting points: `docs/05-security/SECURITY-BASELINE.md`, `TENANT-THREAT-MODEL.md`, `TENANT-ISOLATION-TEST-PLAN.md`.

## 8. UX, design system & accessibility

- [ ] Information architecture dan navigation map.
- [ ] Persona dan role-based journey.
- [ ] Screen inventory untuk setiap modul/role.
- [ ] Wireframe/prototype untuk alur kritis.
- [ ] Design tokens: color, typography, spacing, radius, elevation, motion.
- [ ] Component library dan interaction patterns.
- [ ] Responsive behavior desktop/tablet/mobile.
- [ ] Accessibility target, keyboard navigation, contrast, semantic forms.
- [ ] Empty/loading/error/success/permission-denied states.
- [ ] Localization, Indonesian terminology, date/number/currency conventions.
- [ ] Usability review dengan operator sekolah/madrasah dan wali.

Starting points: `docs/03-design-system/` dan screen inventory/UX patterns yang sudah ada.

## 9. Testing, delivery & operations

- [ ] Test strategy dan traceability requirement-to-test.
- [ ] Unit, feature, integration, API contract, E2E, regression.
- [ ] Tenant isolation, permission, concurrency, idempotency tests.
- [ ] Load, stress, soak, query performance, capacity model.
- [ ] Backup, restore, PITR, RPO/RTO, disaster recovery.
- [ ] CI/CD, artifact/release versioning, migration gates.
- [ ] Environments: local, CI, development, preproduction, production.
- [ ] Observability: structured logs, metrics, tracing, alerting.
- [ ] Deployment online/offline, install, health-check, rollback, backup/restore scripts.
- [ ] Release checklist, change log, runbook, support/incident response.
- [ ] Upgrade and backward compatibility policy.

## 10. Cross-document traceability

Setiap requirement harus memiliki ID stabil dan dapat ditelusuri ke:
`Requirement → Business Process → Module Spec → API/Data Model → Authorization → UI → Test Case → Release Note`.

Setiap keputusan arsitektur penting harus memiliki ADR dengan status Proposed/Accepted/Deprecated/Superseded. Perubahan yang belum disetujui tidak boleh dianggap sebagai perilaku final.

## 11. Exit criteria blueprint lengkap

Blueprint dinyatakan siap menjadi baseline implementasi hanya jika:
1. Semua domain in-scope dan out-of-scope ditetapkan.
2. Aktor, hak akses, alur normal/alternatif/gagal, serta approval terdefinisi.
3. Batas modul, dependensi, ownership data, dan integrasi jelas.
4. Model tenant/unit dan authorization tidak memiliki celah yang diketahui.
5. ERD logis, dictionary, constraint, lifecycle, dan retensi ditinjau.
6. Perbedaan sekolah umum, madrasah, jenjang, dan periode efektif terakomodasi.
7. Kebutuhan keamanan, privasi, audit, operasional, dan pemulihan terdokumentasi.
8. Requirement memiliki acceptance criteria dan hubungan ke test plan.
9. Keputusan yang masih terbuka tercatat sebagai blocker/assumption dengan owner dan target penyelesaian.
10. Pemilik produk menyetujui baseline dan gerbang PoC teknis lulus.

**Peringatan:** keberadaan dokumen atau checklist tidak berarti fitur sudah dibangun, regulasi sudah diverifikasi, atau produk sudah siap produksi. Status aktual selalu mengacu pada PROJECT-PROGRESS.md dan bukti pengujian.
