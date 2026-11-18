# Integritas Data dan Scope

## Tenant/unit integrity
- Record tenant-scoped harus selalu mempunyai tenant_id tervalidasi.
- Record unit-scoped harus mempunyai unit_id dan tenant_id yang konsisten dengan education_units.tenant_id.
- Education unit berada di bawah tepat satu tenant aktif pada satu waktu.
- Tenant foundation maupun independent_provider menggunakan struktur education_units yang sama.
- Tenant mandiri tidak dipaksa memiliki parent foundation.
- Foreign key antar domain memastikan pasangan tenant/unit cocok, bukan hanya ID record cocok.
- Unique constraint memasukkan scope bila nilai hanya unik per tenant/unit.
- Tenant membership dan unit membership adalah grant terpisah; akses unit diperiksa eksplisit.
- Query builder, raw SQL, laporan, search, export, job, webhook, dan cache wajib membatasi scope eksplisit.
- Perubahan tenant_id pada unit tidak dilakukan melalui CRUD biasa; gunakan workflow transfer terotorisasi dan audit.

## Riwayat akademik
- Enrollment adalah histori; jangan menyimpan current_class sebagai satu-satunya sumber.
- Penugasan guru dan konfigurasi kurikulum memiliki periode berlaku.
- Nilai/rapor yang sudah disahkan tidak boleh berubah diam-diam.
- Koreksi membuat jejak perubahan dan alasan.

## Konsistensi operasional
- Gunakan transaksi database untuk perubahan multi-record yang atomik.
- Gunakan unique key/idempotency untuk mencegah presensi, impor, dan nilai ganda sesuai alur.
- Validasi konflik jadwal dan enrollment aktif.
- Operasi bulk harus punya preview, hasil per baris, dan mekanisme kegagalan yang jelas.

## Migrasi
- Migration diuji pada database kosong dan snapshot data sintetis representatif.
- Perubahan besar memakai pola expand/migrate/contract bila diperlukan.
- Hindari migration destruktif tanpa backup, rencana pemulihan, dan persetujuan.


## Referensi kamus data
- `DATA-DICTIONARY-MVP.md` memuat kandidat atribut, tipe PostgreSQL, nullability, klasifikasi, dan validasi per entitas. Dokumen berstatus Draft; belum menjadi izin membuat migration.
- Field SENS/PII, khususnya data anak, wali, dokumen verifikasi, presensi, dan nilai, memerlukan privacy/security review dan purpose/retention yang disetujui.
- Composite FK pada tabel unit-scoped harus membuktikan pasangan tenant_id + unit_id. Validasi aplikasi saja tidak menggantikan constraint database untuk integritas referensial.
- Polymorphic references (audit target, file owner, import result) membutuhkan allowlist entity, scope check, authorization saat akses, dan audit; jangan menganggap UUID target sebagai FK yang aman.


## Invariant akademik MVP — remediation AUD-LD-04

### Enrollment dan penempatan rombel
- student_enrollments tidak menyimpan class_group_id sebagai sumber kebenaran kelas saat ini.
- student_class_placements menjadi relasi effective-dated antara enrollment dan class_group.
- Setiap placement harus berada pada tenant/unit, academic year, dan grade yang cocok pada enrollment dan class_group.
- Untuk enrollment yang sama, rentang placement yang dilarang overlap harus ditegakkan dengan PostgreSQL exclusion constraint atau serialized transaction setelah PoC. Batas tanggal inklusif/eksklusif harus konsisten dan ditetapkan sebelum physical design.
- Histori placement tidak dihapus/ditimpa saat siswa pindah rombel.

### Attendance
- attendance_session_participants membekukan roster yang berlaku pada session_date.
- attendance_records hanya boleh dibuat untuk participant pada sesi tersebut.
- Snapshot peserta tidak berubah karena perubahan placement di kemudian hari.
- attendance_record_revisions append-only; status current merupakan projection dari revision terakhir.
- Correction approval dan apply bukan satu status yang sama. Revision, current projection, applied reference, dan idempotency result harus ditulis dalam satu transaksi.

### Assessment
- assessment_participants membekukan peserta pada assessment_date.
- Assessment, participant, enrollment, placement, class group, academic year/term, curriculum subject, grade, dan unit harus cocok.
- result_status dan score_value harus konsisten: scored memerlukan angka termasuk 0 yang sah; pending/absent/exempt tidak boleh mempunyai angka.
- scoring rule version/snapshot dibekukan untuk hasil yang telah dibuat/finalized; perubahan aturan tidak menghitung ulang hasil lama secara diam-diam.
- Remedial/retake/multiple attempts bukan bagian MVP kecuali change request disetujui.

### HR dan Academic assignment
- Assignment harus berada dalam rentang employee placement yang dirujuk.
- Overlap diperiksa per business key yang relevan, bukan larangan global untuk seluruh assignment pegawai.
- Perubahan status/placement HR tidak menghapus assignment akademik historis; koordinasi lintas domain harus memakai effective date dan audit.

### Enforcement matrix
| Invariant | Database candidate | Domain transaction | Test minimum |
|---|---|---|---|
| Tenant/unit equality | Composite FK | Scope authorization | Cross-tenant/unit negative |
| Enrollment ↔ class placement | Composite FK + candidate composite key | Effective-date validation | Wrong class/year/grade |
| Placement overlap | Exclusion constraint / unique temporal strategy | Row lock if required | Concurrent move |
| Session ↔ participant ↔ placement | Composite FK + unique session/enrollment | Roster snapshot creation | Roster change after close |
| Assessment ↔ participant ↔ placement | Composite FK + unique assessment/enrollment | Rule and date validation | Wrong class/subject/period |
| Assignment ↔ employee placement | Composite FK | Effective-date and employment status check | Expired/inactive placement |
| Correction ↔ revision | FK + unique source correction | Atomic apply + idempotency | Retry/concurrent correction |
| Score status ↔ numeric value | CHECK | Score policy validation | Zero vs absent/exempt/pending |

Database constraint yang memerlukan range/exclusion atau trigger harus diuji pada PostgreSQL 18 dengan transaksi konkuren. Validasi aplikasi saja tidak cukup untuk invariant yang dapat dilindungi database.

## File, audit actor, dan akses — remediation AUD-LD-08/09

- Generic polymorphic file owner adalah metadata, bukan referential integrity atau authorization.
- File scope harus sama dengan owner scope. Re-check permission dan membership saat upload, attach, preview, download, delete, export, retry job, dan background processing.
- File sensitif memerlukan typed association/FK pada domain pemilik; private object storage, server-side MIME detection, malware scanning, short-lived signed URL bila digunakan, audit akses, dan retention policy.
- Audit actor wajib dibedakan: user/support memiliki actor_user_id; system/service memiliki actor_service_code. correlation_id wajib. Support access memerlukan session/reference, reason, approval sesuai policy, dan audit.
- Audit event append-only bagi aplikasi; akses read dan retention terbatas. Tamper-evident sink dan key management tetap bagian security architecture.

