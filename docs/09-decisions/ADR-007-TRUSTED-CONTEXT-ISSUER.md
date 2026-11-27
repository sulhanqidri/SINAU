# ADR-007: Trusted Context Issuer, Session, dan Transaksi RLS

- **Status:** Proposed — baseline kebijakan revocation disetujui untuk desain awal; implementasi dan penerimaan produksi masih menunggu seluruh security gate.
- **Tanggal:** 2026-11-19
- **Terakhir diperbarui:** 2026-11-27
- **Area:** Authentication, session, tenant/unit context, PostgreSQL RLS, connection lifecycle
- **Terkait:** ADR-003, ADR-005, ADR-006, `TRUSTED-CONTEXT-ISSUER-DESIGN.md`, dan PostgreSQL PoC 005–011.

## 1. Konteks dan masalah

PoC PostgreSQL telah membuktikan dua bagian secara terpisah:

1. Verifier PostgreSQL dapat memvalidasi token bertanda tangan yang terikat pada audience/database, masa berlaku, key ID aktif, dan top-level transaction XID. RLS memperoleh tenant/unit hanya dari klaim terverifikasi.
2. Fixture issuer sintetis dapat menurunkan actor dari session bearer sintetis dan memeriksa status akun, session, tenant membership, unit membership, tanggal berlaku, pasangan tenant/unit, serta entitlement secara terpisah.

Kedua hasil tersebut belum membuktikan alur trusted-context di aplikasi nyata. Repository telah memiliki Laravel scaffold dan baseline autentikasi web pada ADR-005/ADR-008, serta runtime role khusus PoC. Namun, trusted-context service, middleware/guard terintegrasi, pengelolaan transaksi request, pemeriksaan revocation account/session/membership per protected statement, dan key custody produksi belum diimplementasikan atau divalidasi end-to-end.

ADR-003 menetapkan baseline identitas global, tenant membership, unit membership, permission berscope, dan default deny. ADR-005 telah Accepted untuk initial web application bootstrap dengan Laravel 13, PHP 8.4, Vue 3 Composition API, TypeScript, Inertia 3, Tailwind 4, shadcn-vue, Fortify, dan PostgreSQL 18. ADR-008 telah Accepted untuk baseline autentikasi web menggunakan Fortify dan server-side database session. Autentikasi API/client, pilihan signing algorithm produksi, dan key custody tetap terbuka.

ADR ini mendefinisikan kontrak yang harus dipenuhi dan pilihan yang masih perlu persetujuan sebelum signer aplikasi dibangun.


### Bukti PoC lanjutan — runtime dan revocation

Pengujian tambahan yang telah dilaporkan:

- Laravel PDO runtime: 18 pemeriksaan berhasil. Runtime login terpisah, privilege boundary, role switching, koneksi PDO yang sama, transaksi, cleanup, dan fail-closed telah diperiksa.
- Signed-context runtime: 36 pemeriksaan berhasil, termasuk validasi issuer, MAC, expiry, audience, XID, replay lintas transaksi, dan RLS.
- Revocation signing key lintas koneksi pada `READ COMMITTED`: koneksi A melaporkan token ditolak setelah revocation dan jumlah row `academic_years` menjadi 0; XID A tetap. Key sintetis kemudian dipulihkan.
- Dua transaksi PDO bersamaan: 11 pemeriksaan berhasil. XID A `920` dan XID B `921`; token silang ditolak dan RLS mengembalikan 0 row.
- Uji `REPEATABLE READ`: koneksi A dengan XID `924` tetap menerima token dan melihat fixture setelah menunggu revocation. Audit independen sesudahnya menunjukkan key `poc-k1` revoked pada `2026-11-21 10:07:52.081753+07`. Output mentah koneksi B yang menunjukkan `UPDATE 1` dan `COMMIT` tidak tersedia dalam transkrip; keterbatasan bukti ini dicatat secara eksplisit.
- Key sintetis `poc-k1` kemudian dipulihkan. Pemeriksaan akhir menunjukkan `is_revoked = false` dan `is_active = true`.

Seluruh pengujian ini terbatas pada `sinau_design_poc`. Hasilnya merupakan bukti PoC, bukan penerimaan keamanan produksi atau bukti integrasi Laravel/Fortify.

## 2. Prinsip yang tidak boleh berubah

- Login membuktikan identitas, bukan akses tenant, unit, atau resource.
- `actor_id` hanya berasal dari authenticated principal yang dibuat middleware/guard tepercaya. Nilai dari body, route, query, header, atau client state bukan bukti identitas.
- `tenant_id` dan `unit_id` yang dipilih pengguna hanyalah selector. Server wajib membuktikan membership dan hubungan tenant/unit.
- Tenant membership tidak memberi akses otomatis ke semua unit.
- Unit membership adalah grant eksplisit; role/permission dan relasi resource tetap diperiksa pada use case terkait.
- Verification, lifecycle tenant/unit, subscription, entitlement, membership, dan permission adalah state terpisah.
- Token konteks RLS bukan session login, bukan token API client, dan bukan bukti bahwa setiap tindakan diizinkan.
- Database runtime tidak boleh menjadi owner tabel, superuser, atau memiliki `BYPASSRLS`.
- Semua kegagalan validasi harus fail closed. Tidak boleh ada query terlindungi setelah context gagal diterbitkan atau dipasang.
- Token, cookie session, password, signing key, dan session bearer tidak boleh masuk log, trace, telemetry, URL, atau respons browser.

## 3. Kontrak principal autentikasi

Middleware/guard autentikasi harus menghasilkan principal internal yang immutable untuk request saat ini. Secara konseptual:

```text
AuthenticatedPrincipal
- actor_id                  (ID akun global hasil autentikasi)
- authentication_session_ref (referensi sesi server-side; bukan cookie mentah)
- authenticated_at
- assurance_level           (bila policy/MFA menggunakannya)
- auth_epoch_or_version     (opsional; menunggu keputusan revocation)
```

Ketentuan:

1. Principal dibuat dari hasil validasi credential dan session oleh server. Controller tidak boleh membuat principal dari field request.
2. Referensi session yang dikirim ke validator database harus berupa nilai server-side yang tidak dapat dipilih atau diganti oleh pemanggil. Bila memakai bearer/session identifier, simpan/serahkan bentuk hash yang sesuai desain session store; jangan menyimpan raw cookie sebagai data fixture.
3. Account disabled/locked, session expired/revoked, atau session tidak cocok dengan actor harus menolak context.
4. Logout, reset credential, global account disable, dan pencabutan session harus punya kontrak invalidasi yang konsisten. Dampak ke semua session atau hanya session tertentu harus dicatat pada event/audit.
5. Context selection yang disimpan pada session hanya preferensi navigasi. Setiap request/transaction tetap memvalidasi ulang scope terhadap membership dan policy yang berlaku.

**Belum diputuskan:** bentuk session store (database/Redis/alternatif), mekanisme API auth, nilai assurance/MFA, auth epoch, dan detail rotasi session. ADR-005 tetap menjadi sumber status keputusan stack; ADR ini tidak mengunci Sanctum atau library autentikasi.

## 4. Validasi scope sebelum token

Issuer menggabungkan hasil trusted principal, selector tenant/unit, dan policy. Minimum urutannya:

1. **Identity/session:** actor aktif; session server-side aktif, belum expired/revoked, dan terkait dengan actor.
2. **Tenant:** tenant ada dan lifecycle-nya mengizinkan operasi; tenant membership aktif serta berada dalam effective period.
3. **Unit (bila diminta):** unit ada, dimiliki tenant yang dipilih, lifecycle mengizinkan operasi, dan actor memiliki unit membership eksplisit yang aktif serta efektif.
4. **Permission:** permission yang dibutuhkan dievaluasi pada scope platform/tenant/unit yang benar. Nama role saja tidak cukup; inheritance, deny precedence, dan delegation ceiling perlu aturan eksplisit.
5. **Resource relationship:** teacher assignment, guardian/student relationship, ownership, enrollment, dan relasi resource lainnya diperiksa oleh policy/use case. Context token tidak menggantikan pemeriksaan ini.
6. **Entitlement:** feature/quota/subscription diperiksa secara terpisah pada operasi yang memerlukannya. Entitlement bukan membership atau permission.

Validator fixture 010 baru membuktikan sebagian tahap identity/session, membership, unit ownership dan entitlement terpisah. Validator itu belum memeriksa tenant lifecycle produksi, role/permission, delegation, resource relationship, atau seluruh verification/subscription policy.

## 5. Alur transaksi yang diusulkan

Seluruh aktivitas di bawah wajib memakai satu koneksi PostgreSQL yang dipin dari awal sampai akhir. Pada Laravel, implementasi kelak harus memakai satu named connection/PDO instance yang sama; tidak boleh mengandalkan pemilihan koneksi default berulang yang dapat berpindah ke koneksi lain.

1. Middleware mengautentikasi request dan menghasilkan `AuthenticatedPrincipal`.
2. Service membaca tenant/unit selector. Selector tidak diberi status trusted.
3. Service membuka top-level transaction pada koneksi yang akan menjalankan protected SQL.
4. Sebagai perintah transaksi pertama sebelum query lain, koneksi menetapkan isolation level `READ COMMITTED` (`SET TRANSACTION ISOLATION LEVEL READ COMMITTED`). Setelah itu koneksi mengalokasikan dan menyimpan top-level XID dengan `pg_current_xact_id()`. XID tersebut hanya berlaku bagi transaksi itu.
5. Dalam transaksi/koneksi yang sama, issuer meminta pemeriksaan identity/session/membership kepada validator database yang sempit. Validator tidak menerima caller-supplied `actor_id`; ia menurunkan actor dari referensi session tervalidasi.
6. Aplikasi mengevaluasi permission, delegation, resource relationship, lifecycle, dan entitlement untuk operasi yang sedang dilakukan.
7. Backend membuat token baru dengan nonce acak dan waktu terbit/expiry. Token harus terikat ke database audience dan XID transaksi itu. Token PoC maksimum 300 detik; batas produksi harus disetujui dan sebaiknya lebih pendek dari batas request/transaction.
8. Backend memasang token hanya untuk transaksi berjalan, melalui mekanisme transaction-local seperti `set_config('app.context_token', token, true)` atau `SET LOCAL`. Jangan memakai session-level GUC.
9. Backend mengubah role ke query role yang memiliki privilege minimum/RLS, lalu menjalankan protected SQL melalui koneksi yang sama.
10. Pada sukses, commit. Pada exception/timeout/deny, rollback. Context transaction-local harus hilang pada commit/rollback. Koneksi yang akan digunakan kembali tidak boleh membawa transaksi terbuka atau context lama.

**Larangan teknis:**

- Jangan membuat XID pada koneksi A, lalu menandatangani atau menjalankan query pada koneksi B.
- Jangan memakai token dari transaksi sebelumnya, cache, job, request lain, atau read replica.
- Jangan menjalankan protected query sebelum context berhasil dipasang.
- Jangan mengandalkan nested transaction/savepoint untuk membuat konteks XID baru. Context harus mengikuti top-level transaction yang sama.
- Jangan melakukan query protected di luar transaksi eksplisit.
- Jangan mengembalikan token ke browser atau menyimpan token di session/cache.
- Jangan memakai `SET SESSION app.context_token`; hanya state transaction-local yang diterima.
- Jangan menganggap rollback aplikasi otomatis membersihkan state session-level; bila transaksi gagal/connection error, pastikan koneksi dikembalikan dalam keadaan aman atau dibuang dari pool.

## 6. Kontrak token dan verifier

Format PoC v1:

```text
v1|audience|kid|actor_uuid|tenant_uuid|unit_uuid_or_dash|xid8|iat|exp|nonce_hex|mac_hex
```

Verifier PostgreSQL saat ini memeriksa:
- audience sama dengan database yang sedang dipakai;
- syntax dan representasi field kanonis;
- key ID aktif dan belum dicabut;
- masa berlaku serta maksimum lifetime 300 detik;
- XID sama dengan top-level transaction yang sedang berjalan;
- HMAC-SHA256 sesuai payload.

RLS accessor `current_verified_context()` bersifat SECURITY INVOKER dan membaca klaim hanya dari verifier. Token adalah bearer credential dalam transaksi yang sama sampai transaksi berakhir/masa berlaku habis; bukan token satu-query. Pemegang token dalam transaksi yang sama dapat menggunakannya kembali selama masih valid.

HMAC v1 adalah bukti konsep, bukan pilihan final produksi. HMAC berarti signer backend dan verifier database sama-sama membutuhkan material rahasia yang sama. Sebelum produksi, bandingkan:
- HMAC dengan distribusi secret terkontrol, dual custody, key rotation dan revocation; versus
- asymmetric signing, private key hanya pada backend/KMS dan public key pada verifier database, bila dukungan algoritma/verifikasi dan kebutuhan operasional terbukti.

Jangan memilih algoritma hanya karena implementasi PoC sudah tersedia. Ordinary runtime/query role tidak boleh membaca secret/key table atau menjalankan fungsi kriptografi mentah.

## 7. Batas role PostgreSQL yang diusulkan

Nama berikut bersifat konseptual, bukan DDL atau role yang sudah dibuat:

| Role konseptual | Tanggung jawab | Batas |
|---|---|---|
| Schema/table owner | Memiliki schema, tabel, policy, dan fungsi terproteksi | NOLOGIN; bukan role aplikasi; tidak diberikan ke runtime |
| Migration/deployment | Menerapkan migration terotorisasi | Credential terpisah, hanya untuk deployment; tidak dipakai request |
| Connection login | Login koneksi aplikasi dan hanya boleh beralih ke role runtime yang disetujui | NOINHERIT bila sesuai model role; bukan owner, superuser, atau BYPASSRLS |
| Context issuer executor | EXECUTE pada validator sempit untuk session/membership | Tidak mendapat SELECT/INSERT/UPDATE/DELETE langsung pada fixture/membership/key table |
| Runtime query role | DML minimum pada tabel aplikasi dengan RLS; EXECUTE pada accessor/verifier yang diperlukan | Tidak dapat menjalankan membership validator, membaca membership/key secret secara langsung, atau mengubah membership/role |
| Key custodian/verifier owner | Memiliki akses secret melalui fungsi verifier yang dilindungi | NOLOGIN; tidak menjadi runtime login |

Agar XID tetap sama, pergantian role issuer ke query role harus terjadi dengan role transaction-local pada koneksi/transaksi yang sama. Model role membership, `SET LOCAL ROLE`, dan privilege efektif dari connection login belum diuji untuk aplikasi nyata. Pemisahan role ini memberi least privilege pada operasi normal, tetapi bukan pertahanan terhadap aplikasi yang sepenuhnya dikompromikan bila credential login dapat beralih ke kedua role. Threat model SQL injection/compromised application harus dinyatakan secara eksplisit dan privilege validator harus tetap sangat sempit.

Tidak ada role produksi yang dibuat oleh ADR ini. Role PoC `sinau_context_issuer_poc`, `sinau_rls_test`, dan `sinau_context_owner` tetap khusus `sinau_design_poc`.

## 8. Connection pool dan reset

- Mode pooler yang hanya mempertahankan koneksi per statement tidak kompatibel dengan alur XID-bound ini.
- Transaction pooling mungkin kompatibel karena seluruh operasi berada dalam satu explicit transaction, tetapi wajib diuji dengan pooler dan konfigurasi nyata.
- Session pooling juga tetap memerlukan transaksi eksplisit dan transaction-local context.
- Semua protected query memakai primary/authoritative database connection; routing ke read replica tidak boleh memecah XID.
- Setelah commit/rollback, uji pada koneksi yang sama bahwa `current_setting('app.context_token', true)` kosong dan data tenant/unit tidak terlihat tanpa context.
- Uji juga ketika terjadi exception, timeout, cancellation, deadlock, reconnect, pool checkout/check-in, dan koneksi invalid.
- Hasil PoC 009 hanya membuktikan reset transaction-local pada sesi PostgreSQL yang sama. Itu belum membuktikan integrasi PgBouncer, Laravel connection manager, persistent PDO, atau worker queue.

## 9. Revocation dan transaksi berjalan

### 9.1 Keputusan kebijakan yang disetujui — 2026-11-26

Product Owner menyetujui baseline kebijakan revocation berikut untuk desain awal SINAU:

1. Seluruh protected transaction wajib menggunakan isolation level `READ COMMITTED`.
2. Protected SQL statement yang mulai setelah perubahan revocation berhasil di-commit wajib ditolak apabila konteks tersebut sudah tidak berwenang.
3. Statement yang sudah mulai berjalan sebelum commit revocation boleh menyelesaikan eksekusinya. Kebijakan ini tidak menjanjikan pembatalan paksa statement, rollback otomatis transaksi lain, atau penarikan data yang sudah dibaca.
4. `REPEATABLE READ` dilarang untuk protected transaction karena snapshot lama dapat tetap melihat status key sebelum revocation.
5. `SERIALIZABLE` bukan bagian baseline ini dan membutuhkan review serta persetujuan keamanan terpisah sebelum digunakan untuk protected transaction.
6. Transaksi harus singkat, mempunyai batas waktu yang terukur, tidak dibiarkan idle, dan tidak mempertahankan context melewati request/job yang membentuk transaksi.
7. Hasil pemeriksaan revocation tidak boleh di-cache lintas protected SQL statement.

### 9.2 Semantik statement

- Pada `READ COMMITTED`, setiap protected SQL statement memperoleh snapshot statement yang baru.
- Verifier atau authorization guard harus memeriksa state revocation authoritative ketika setiap protected statement dievaluasi.
- Statement yang sudah berjalan ketika revocation di-commit boleh selesai; protected statement berikutnya harus mengevaluasi ulang dan menolak konteks yang dicabut.
- Token tetap terikat ke satu top-level transaction XID. `READ COMMITTED` tidak berarti token boleh digunakan pada transaksi atau koneksi lain.
- Batas numerik maksimum durasi transaksi dan request harus ditetapkan pada konfigurasi/runtime runbook sebelum implementasi produksi. ADR ini belum menetapkan angka yang belum diukur.

### 9.3 Cakupan bukti dan gap implementasi

PoC telah membuktikan pemeriksaan revocation signing key melalui `revoked_at` pada verifier:

- Pada `READ COMMITTED`, pengujian dua koneksi menunjukkan token ditolak setelah revocation dan RLS tidak lagi menampilkan fixture.
- Pada pengujian `REPEATABLE READ`, koneksi dengan XID `924` tetap menerima token lama; audit independen sesudahnya menunjukkan key berstatus revoked. Karena snapshot lama tetap digunakan, perilaku ini menjadi alasan kebijakan `REPEATABLE READ` dilarang. Output mentah koneksi B tidak tersedia dalam transkrip yang diterima.
- Pengujian tersebut tidak membuktikan bahwa statement yang sudah berjalan dapat dihentikan. Baseline justru mengizinkan statement yang sudah mulai berjalan menyelesaikan eksekusinya.

**Gap penting sebelum implementasi produksi:**

Issuer saat ini memvalidasi session dan membership saat context diterbitkan. Verifier PoC memeriksa signature, XID, expiry, audience, dan status signing key; verifier tersebut belum memeriksa status account, session, serta membership pada setiap evaluasi protected statement.

Karena itu, kebijakan revocation yang disetujui belum sepenuhnya terimplementasi untuk account/session/membership. Sebelum produksi, desain harus menyediakan pemeriksaan state atau authorization version/epoch yang authoritative dan segar pada setiap protected statement, atau mekanisme ekuivalen yang memenuhi semantik di atas. Nilai epoch yang hanya disalin ke token tanpa pemeriksaan state terbaru tidak memenuhi persyaratan ini.

Revocation account/session/membership tidak boleh dinyatakan lulus hanya berdasarkan pengujian revocation signing key. Mekanisme tersebut harus memiliki test lintas koneksi, statement boundary, concurrency/race, dan fail-closed tersendiri.

## 10. Opsi dan keputusan yang masih terbuka

| Area | Baseline/rekomendasi sementara | Status |
|---|---|---|
| Web authentication | Fortify dan server-side database session mengikuti ADR-008 | Accepted untuk initial web bootstrap |
| API/client authentication | Evaluasi Sanctum atau mekanisme lain sesuai client dan threat model | Belum final |
| Session store dan revocation | Server-side record dengan lifecycle/revocation yang bisa diuji | Belum final |
| Principal contract | Middleware-created immutable principal; actor tidak boleh berasal dari request | Invarian yang diusulkan |
| Membership validator | Narrow SECURITY DEFINER function dengan fixed search_path dan tanpa direct table grants | Sudah diuji sintetis; kontrak produksi belum final |
| Runtime roles | Owner/migration/issuer/query dipisah; runtime login NOINHERIT dan role switching pada PDO/transaksi yang sama | Runtime PoC, privilege boundary, 18 PDO checks, dan 36 signed-context checks lulus; ownership tabel dan integrasi Laravel masih menjadi gate |
| Signing algorithm | HMAC PoC; evaluasi asymmetric/KMS sebelum produksi | Belum final |
| Connection pooling | Mulai dengan koneksi PostgreSQL langsung; PgBouncer/pooler opsional bila ada kebutuhan kapasitas terukur | Direct psql lifecycle tests lulus; pooler lokal tidak terdeteksi. Tidak perlu server tambahan atau instalasi pooler untuk melanjutkan PoC/bootstrap awal; integrasi pooler ditunda |
| In-flight revocation | `READ COMMITTED`; protected statement baru setelah revocation commit ditolak; statement yang sudah berjalan boleh selesai; `REPEATABLE READ` dilarang | Kebijakan disetujui 2026-11-26; pemeriksaan session/account/membership per statement belum diimplementasikan |
| Tenant/unit lifecycle matrix | Validator harus mengikuti matrix yang disahkan | Belum final |

## 11. Kriteria penerimaan sebelum implementasi signer aplikasi

Tidak ada signer produksi atau migration aplikasi sebelum semua hal berikut memiliki desain, bukti test, dan persetujuan:

1. Auth middleware menghasilkan principal dari credential/session tepercaya; forged `actor_id` dari request tidak berpengaruh.
2. Session aktif, logout, expiry, revoke, account disable, dan auth epoch (bila dipilih) dites.
3. Tenant dan unit selector ditolak untuk membership yang tidak aktif, tidak efektif, suspended/revoked, atau tenant/unit mismatch.
4. Tenant-only context tidak membuka row unit-scoped.
5. Role/permission, delegation ceiling, dan resource relationship diuji terpisah dari membership.
6. Entitlement tidak disamakan dengan membership atau permission.
7. Token untuk XID transaksi A ditolak di transaksi B; audience, expiry, key revoke, malformed token, dan MAC salah ditolak.
8. XID, validator, signing, set_config transaction-local, dan protected query menggunakan satu koneksi.
9. Commit, rollback, exception, timeout, nested transaction, dan connection reuse tidak meninggalkan context.
10. Query role tidak dapat membaca key/session/membership secara langsung atau menjalankan fungsi issuer; issuer executor tidak dapat memutasi data membership.
11. Pooler mode dan worker/queue lifecycle diuji dengan deployment target.
12. Concurrency test menetapkan hasil revoke vs request yang sudah berjalan.
13. Logging, tracing, error handling, metrics, dan audit tidak membocorkan credential/token/secret.
14. Test seluruh tenant/unit isolation, raw SQL, bulk, file, export, queue, scheduler, dan IDOR lulus.
15. Protected transaction menegakkan `READ COMMITTED`; `REPEATABLE READ` tidak dapat digunakan untuk protected SQL.
16. Revocation key, account, session, dan membership diuji terpisah. Protected statement baru setelah revocation commit ditolak; statement yang sudah berjalan boleh selesai.
17. Pemeriksaan authorization version/state untuk account/session/membership dilakukan secara authoritative per protected statement, tanpa cache lintas statement.
18. Batas durasi transaction/request, timeout, idle transaction, dan perilaku saat koneksi dibatalkan ditetapkan serta diuji.
19. Semua trigger/helper function yang berjalan pada protected DML mengunci search_path, schema-qualify seluruh tabel/tipe non-system, dan diuji terhadap temporary-object shadowing.

## 12. Non-goals dan batas keselamatan

- ADR ini tidak memilih final framework, library RBAC, session store, API auth, key algorithm, KMS, pooler, atau kebijakan transaksi in-flight.
- ADR ini tidak membuat migration produksi, tabel users/membership produksi, role database produksi, endpoint login, atau signer Laravel.
- Synthetic fixture 010/011 bukan data user nyata dan tidak boleh dipakai di aplikasi.
- Script 006 dengan actor/tenant/unit statis tetap hanya signer PoC dan tidak boleh dipakai oleh web runtime.
- Semua eksperimen tetap hanya pada `sinau_design_poc`.
- Jangan menyentuh database produksi `sinau`, role `sinau_app`, SQLRadius, atau MikroTik.

## 13. Langkah berikutnya

1. Selesaikan keputusan API/client authentication, assurance/MFA, dan lifecycle session yang belum ditetapkan oleh ADR-008.
2. Evaluasi HMAC versus asymmetric signing/KMS, custody, rotasi, dual control, backup, dan prosedur key recovery. HMAC tetap hanya baseline PoC sampai pilihan produksi disetujui.
3. Selesaikan audit read-only ownership, schema/table privileges, sequence, function, RLS policy, role membership, dan default privileges. Jangan mengubah ownership atau privilege sebelum inventaris serta rencana migrasi disetujui.
4. Audit read-only PoC 018 dan uji dua koneksi PoC 019/020 mengonfirmasi verifier belum memeriksa state account, authentication session, tenant membership, dan unit membership pada protected statement berikutnya. Keempat skenario READ COMMITTED menghasilkan FINDING REPRODUCED; seluruh fixture sintetis telah dipulihkan dan diverifikasi aktif. Gerbang berikutnya adalah merancang token/session binding dan authorization freshness (per-statement authoritative-state check dibanding authorization version/epoch), termasuk race/snapshot semantics dan biaya query, lalu menguji hanya di sinau_design_poc.
5. Implementasikan adapter trusted context Laravel hanya setelah role matrix, session contract, key custody, isolation enforcement, dan revocation implementation disetujui.
6. Uji Laravel/Fortify melalui HTTP/API, termasuk logout, expiry, account disable, session revoke, membership revoke, tenant/unit isolation, IDOR, raw SQL, export, file, queue, dan scheduler.
7. Connection pooling tetap ditunda. Evaluasi hanya apabila pengukuran beban/kapasitas dan persetujuan pemilik menunjukkan kebutuhan.

PoC direct PostgreSQL yang telah lulus merupakan bukti teknis untuk desain awal. PoC tersebut tidak mengesahkan signer produksi, migration domain, role produksi, atau deployment produksi.


## 14. PoC trigger-function search_path hardening — 2026-11-26

A focused read-only audit found two SECURITY INVOKER trigger functions in the PostgreSQL PoC:

- \`public.poc_check_assessment_participant()\`
- \`public.poc_check_attendance_participant()\`

Both are owned by \`sinau_poc\`, had \`proconfig IS NULL\`, and used unqualified \`student_class_placements\` relation and \`%ROWTYPE\` references. The two enabled BEFORE triggers are attached to the expected participant tables. The runtime and query roles cannot create triggers on those tables, but the audited roles have database TEMP privilege.

A controlled, rolled-back session test under \`sinau_rls_test\` confirmed that an empty temporary relation named \`student_class_placements\` shadows the unqualified relation and row type in the caller's default search path: the unqualified relation/type resolved to \`pg_temp_1\`, while \`public.student_class_placements\` remained distinct. This confirms a name-resolution weakness; it does not alone demonstrate a successful data-integrity bypass.

The constraint audit returned 40 validated constraint rows. Composite foreign keys protect tenant, unit, placement, and enrollment relationships. The participant-to-placement \`class_group_id\` comparison and date-within-placement-period checks are not fully encoded in those foreign keys and remain dependent on the trigger functions.

### Remediation baseline

The PoC patch replaces only the two audited trigger-function bodies and:
- qualifies the row type as \`public.student_class_placements%ROWTYPE\`;
- reads from \`public.student_class_placements\` explicitly;
- sets function-level \`search_path = pg_catalog, pg_temp\`, with no application schema implicitly trusted;
- preserves SECURITY INVOKER, function owner, existing trigger attachment, and existing ACLs;
- makes no role, grant, table, policy, or application-row changes.

The regression script creates an empty temporary shadow table and attempts a no-op UPDATE against one existing row in each participant table, causing the attached BEFORE trigger to execute. The test transaction rolls back. A missing fixture row is reported as SKIP, not PASS.

**Execution status at this revision:** remediation and regression SQL scripts are committed as PoC artifacts but have not been run on the PostgreSQL host. Do not mark this gate passed until both trigger tests report PASS after the patch. ADR-007 remains Proposed; this work does not approve production deployment.


### Patch execution correction — 2026-11-26

The first execution of PoC script 015 passed its database/function/trigger preflight and reached both function replacements, but its postflight text assertion failed because it searched a lowercase `pg_get_functiondef()` output using an uppercase `%ROWTYPE` literal. The script's transaction was not committed; after the psql process exited with `ON_ERROR_STOP`, PostgreSQL rolled the transaction back. Script 016 then correctly found that neither function retained the hardened configuration. The postflight comparison was corrected to be case-insensitive. No PoC changes should be considered applied until corrected script 015 completes with COMMIT and script 016 passes both trigger invocations.


### Execution update — trigger function patch committed; regression invocation pending — 2026-11-26

The corrected PoC patch 015 was executed against `sinau_design_poc`. The database/function/trigger preflight passed, both function definitions were replaced, the postflight confirmed the schema-qualified placement row type/relation and `search_path=pg_catalog, pg_temp`, and the transaction committed.

The subsequent script 016:
- created an empty temporary table shadow named `student_class_placements`;
- confirmed the caller's unqualified lookup resolved to `pg_temp_9`, while `public.student_class_placements` remained addressable;
- skipped the assessment trigger invocation because `assessment_participants` had no rows;
- skipped the attendance trigger invocation because `attendance_session_participants` had no rows;
- ended with ROLLBACK.

Consequently, hardening is applied in the PoC, but the trigger-level regression gate remains **incomplete**. Both trigger invocations must be exercised with valid synthetic PoC fixture rows and report PASS before this finding is closed. No production database, application schema, role, service, SQLRadius, or MikroTik was changed. ADR-007 remains Proposed.


### Next regression gate — minimal synthetic fixture transaction — 2026-11-26

A read-only inventory showed the academic tables used by the participant triggers were empty. Script 016 therefore skipped both trigger invocations. Script 017 has been prepared from the committed PoC schema and smoke-test fixture conventions.

The script creates an empty temporary shadow, inserts a minimal synthetic tenant/unit/year/class/enrollment/placement chain, and executes the assessment and attendance triggers through valid INSERT/no-op UPDATE paths. It also verifies that each trigger rejects a participant whose class differs from the placement and a participant date outside the placement period. All fixture work is inside one explicit transaction ending in ROLLBACK.

**Status:** script 017 is prepared but not yet executed on the PostgreSQL host. The trigger hardening is applied in `sinau_design_poc`; the regression gate remains open until every expected PASS is reported. ADR-007 remains Proposed.


## 15. Authorization freshness and session-bound context token — design proposal (2026-11-27)

### 15.1 New evidence

The two-connection test recorded in PoC README section 18 completed all four valid READ COMMITTED scenarios. After Session B committed a change, Session A's next protected statement still saw the protected fixture and reported `FINDING REPRODUCED` for each source: account disabled, authentication session revoked, tenant membership revoked, and unit membership revoked. The exact synthetic rows were restored; the final read-only audit returned one matching active row and `PASS` for every source.

This evidence confirms the installed PoC verifier does not enforce those four authorization-state changes on the next protected statement in the tested flow. It does not demonstrate a production exploit. The session scenario had only one active fixture session and therefore did not establish per-session isolation when an actor has multiple sessions.

### 15.2 Recommended design for review — not yet accepted

Recommend a hybrid model:

1. **Live authoritative checks remain the source of truth.** Every protected statement must verify current account status, exact session status/expiry/revocation, tenant membership, and unit membership when applicable. No authorization result may be cached across protected statements.
2. **Monotonic generations prevent resurrection.** Include account, tenant-membership, and unit-membership generations in the signed token and compare them with current authoritative rows. Revoke/regrant or disable/reenable must advance the relevant generation. Epochs supplement live state; they are not a replacement for it.
3. **Bind one exact session.** Add a non-bearer SHA-256 session reference matching the stored server-side session record. A session reference is immutable and never reused. Revoking session A must leave session B eligible if account and membership state remain valid.
4. **Keep the approved transaction policy.** Protected transactions remain `READ COMMITTED`; a protected statement beginning after a revocation commit must be denied. No cross-statement authorization cache is allowed. The policy does not forcibly cancel statements already in progress.

Live checks alone do not satisfy the proposed "old token remains invalid after reactivation" test unless reactivation advances a generation or replaces the relevant identity. Epoch-only checks are also insufficient because a missed generation increment could leave stale access valid.

### 15.3 Candidate v2 payload

The current v1 contract has no session claim. The candidate v2 payload is:

```text
v2|audience|kid|actor_uuid|session_ref_hex|tenant_uuid|unit_uuid_or_dash|xid8|iat|exp|nonce_hex|account_epoch|tenant_membership_epoch|unit_membership_epoch|mac_hex
```

Every claim must be covered by the MAC and canonicalized. `session_ref_hex` is a 32-byte SHA-256 reference (64 lowercase hex characters) derived from a trusted server-side session reference; it is not a raw cookie or login bearer. The verifier must match both session reference and actor. The reference must never be reused. A separate session epoch is not required in the minimal proposal if the session reference is immutable and unique and the session state is checked live.

For a tenant-only token, both the unit claim and unit generation use the canonical no-unit sentinel. Such a token must not satisfy unit-scoped policy. v1 must not be silently accepted as v2. The exact session-reference derivation, generation column names/types, token lifetime, and canonical field limits remain open.

### 15.4 Verifier contract and privilege constraints

The proposed verifier validates syntax, signature, audience, key status, expiry, XID, current account and generation, exact session and lifecycle, current tenant membership and generation, and unit membership/ownership/lifecycle and generation when the token is unit-scoped. It returns exactly one context only if all applicable checks succeed. Missing/invalid authorization returns no context; unexpected database/privilege failures abort the protected statement rather than falling back to unverified claims.

The verifier continues to be invoked through `sinau_private.current_verified_context()` by RLS. The opaque `app.context_token` GUC remains only a carrier; unsigned tenant/unit GUCs must never determine RLS scope. Keep key and authorization tables inaccessible directly to runtime/query roles, keep function ownership and fixed `search_path` audited, and do not grant broad membership-table privileges as a shortcut. Application permission, delegation, resource relationship, and entitlement checks remain distinct from context membership.

### 15.5 Indexes and performance

Start with existing primary keys for exact lookups: `poc_identities(actor_id)`, `poc_auth_sessions(session_hash)`, `poc_tenant_memberships(actor_id, tenant_id)`, `poc_unit_memberships(actor_id, tenant_id, unit_id)`, `poc_units(tenant_id, unit_id)`, and `context_keys(key_id)`. Do not add low-selectivity status or redundant epoch indexes without `EXPLAIN (ANALYZE, BUFFERS)` evidence. An index on session `actor_id` is only a candidate for bulk logout if the revoke-all plan and data size justify it.

Benchmark signature/XID/key validation, live lookups, generation comparisons, and full RLS separately. Use representative fixture cardinalities and 1/10/50/100 protected statements per transaction. Record median/P95/P99 latency, buffer hits/reads, CPU, query count, rows examined, and query plans. No performance claim or target is accepted until measured.

### 15.6 Snapshot and race questions

The installed verifier is `VOLATILE` and performs internal SQL reads. Do not assume its internal queries have the desired statement-snapshot behavior solely from the volatility label. Before implementation, test a deliberately long-running protected statement while another connection commits revocation. Required cases:

- revocation committed before the protected statement begins: deny;
- revocation committed while a statement is already running: no forced cancellation guarantee; characterize whether it completes or aborts;
- the next protected statement after revocation commit: deny;
- multi-row policy evaluation: detect unexpected mixed visibility within one statement.

Do not change function volatility or snapshot strategy before this evidence and review. The completed 019/020 experiment tested only a revoke commit before the next separate protected SELECT.

### 15.7 Next PoC gates

1. Read-only inventory of exact installed functions, columns, constraints, grants, policies, dependencies, and query plans.
2. Review and settle the session-reference and generation contracts.
3. Propose guarded, disposable-only DDL for synthetic generation fields, if accepted.
4. Implement a v2 verifier only in `sinau_design_poc`, including strict v1 rejection and least-privilege checks.
5. Run multi-session isolation, four source revocations, reactivation/no-resurrection, wrong epoch, malformed/MAC/audience/XID, real RLS, in-flight race, connection reset, and benchmark tests.
6. Review evidence and explicitly update ADR status before considering any application integration.

**Status boundary:** this section is a design proposal, not an implementation approval. No SQL, table, role, credential, RLS policy, Laravel integration, production database, SQLRadius, or MikroTik change is authorized. ADR-007 remains **Proposed**. PR #1 must remain **Open, Draft, and unmerged**. See [PoC authorization-freshness design](../03-database/poc/021-authorization-freshness-design.md) for the complete proposal.


## 16. First read-only runtime inventory — 2026-11-27

The first execution of PoC audit script 022 ran against PostgreSQL 18.7 on `sinau_design_poc` as `postgres` with `transaction_read_only = on`, and reached its final ROLLBACK marker.

The catalog output confirmed:
- the issuer fixture tables, `sinau_private.context_keys`, and `public.tenants` exist;
- no account, tenant-membership, or unit-membership generation columns exist in the four authorization source tables;
- the session table uses a 32-byte `bytea` `session_hash` primary key;
- seven primary-key indexes across the six issuer fixture tables and key store are valid/ready/live; no secondary index was reported on those tables;
- the fixture tables and key store are owned by `sinau_context_owner`, while `public.tenants` is owned by `sinau_poc`;
- 14 public RLS policies use `current_verified_context()`;
- the query role has no direct access to authorization fixture/key tables and cannot execute the issuer validator, while it can execute the current verifier/accessor chain;
- `sinau_app_runtime_poc` is granted SET membership to both issuer and query roles with `inherit_option=false`; its full role attributes/effective privileges need the corrected script output.

**Audit limitation:** the first script's section 6 function metadata query did not match verifier/issuer overloads because of an incorrect `pg_get_function_identity_arguments()` predicate. Section 7 displayed their installed definitions, so those blank rows do not mean the functions are absent. Script 022 was corrected to match by argument count and type OIDs and to include the runtime role in role/privilege inventories. Re-run the corrected script before relying on the affected metadata and role sections.

This inventory is read-only evidence, not security acceptance. No schema, data, role, grant, policy, verifier, application, or production object was changed. ADR-007 remains **Proposed**.


### Runtime role attribute query correction

The second audit run confirmed `sinau_app_runtime_poc` is a member with SET permission to both `sinau_context_issuer_poc` and `sinau_rls_test`, without inherited privileges via those memberships. Its direct effective table/function privileges are false. The role-attribute query in that run omitted this one role because its filter list was not updated. The audit script has now been corrected again; rerun the final pinned script before deciding whether this role is login-capable. No role or membership was changed.


## 17. Corrected verifier metadata and role-grant findings — 2026-11-27

The corrected audit returned all four expected functions. Each is `VOLATILE` and fixed to `search_path=pg_catalog, pg_temp`. Issuer validator and entitlement functions are SECURITY DEFINER owned by `sinau_context_owner` and executable by the issuer role. The verifier is SECURITY DEFINER owned by `sinau_context_owner`; the verified-context accessor is SECURITY INVOKER with EXECUTE grants to the query role. Direct effective privileges show no direct authorization-table/key-store SELECT or DML for the runtime, issuer, and query roles. The query role can execute verifier/accessor but not issuer functions; issuer can execute issuer functions but not read source tables directly.

The role-membership output confirms `sinau_app_runtime_poc` can SET ROLE to issuer and query roles, while not inheriting their privileges. This is a capability boundary that must be understood in the application threat model: arbitrary SQL running as this runtime connection can deliberately switch to a granted capability role. No membership change is authorized by this audit.

The focused read-only query returned the runtime role attributes: `rolsuper=false`, `rolcanlogin=true`, `rolinherit=false`, `rolcreaterole=false`, `rolcreatedb=false`, `rolreplication=false`, and `rolbypassrls=false`. This establishes that `sinau_app_runtime_poc` is a login-capable non-superuser and lacks the listed administrative and RLS-bypass attributes.

The role is nevertheless a member with `SET` permission (but no `INHERIT`) for both `sinau_context_issuer_poc` and `sinau_rls_test`. Explicit `SET ROLE` remains available; `rolinherit=false` only prevents automatic privilege inheritance. Thus, the runtime login can intentionally assume both capability roles, and its lack of direct grants while unswitched is not complete capability isolation. Arbitrary SQL execution through a compromised runtime connection could use the capabilities granted to those roles. This is a trust-boundary finding, not proof of a production exploit.

Before implementation, the role model must explicitly decide whether the runtime credential is trusted with the issuer and query capabilities. If not, reduce the relevant SET memberships in a separately reviewed PoC role-model change and provide a separately controlled capability path. If yes, document the trust assumption and re-audit the full privilege surface after role switching. No role, membership, grant, or other database object was changed by the focused query. The full corrected script 022 was not rerun; the one-row query independently confirms these role attributes.


## 18. Runtime SET ROLE capability test — 2026-11-27

A focused test simulated the runtime session identity from a `postgres` connection in two separate read-only transactions. With `SET LOCAL SESSION AUTHORIZATION sinau_app_runtime_poc`, both `SET LOCAL ROLE sinau_context_issuer_poc` and `SET LOCAL ROLE sinau_rls_test` succeeded.

The reported identity pairs were:
- Issuer switch: `session_user=sinau_app_runtime_poc`, `current_user=sinau_context_issuer_poc`.
- Query switch: `session_user=sinau_app_runtime_poc`, `current_user=sinau_rls_test`.

Both transactions ended with `ROLLBACK`. No role or membership was modified. This confirms the capability is operational under the simulated runtime session identity; `rolinherit=false` does not prevent explicit `SET ROLE`.

**Limitation:** the connection was authenticated as `postgres`; `SET LOCAL SESSION AUTHORIZATION` simulated the runtime identity. The test does not prove that a direct network connection using the runtime credential succeeds, and it does not test password/SCRAM, `pg_hba.conf`, or application connection settings.

This strengthens the threat-model finding: arbitrary SQL execution in a session operating as the runtime role can switch to either granted capability role and exercise the privileges of that role. This is not itself proof of an external exploit or production impact.

Before implementation, the role model must explicitly choose whether the runtime credential is trusted with both capabilities. If not, reduce the SET memberships in a separately reviewed PoC change and provide another controlled capability path. If yes, document the trust assumption and re-audit the post-switch effective privilege surface. No verifier DDL or production change is authorized by this test. ADR-007 remains Proposed. PR #1 remains Open, Draft, and unmerged.


## 19. Issuer capability effective-privilege audit — 2026-11-27

The issuer audit ran in a read-only transaction after simulating `sinau_app_runtime_poc` as the session identity and switching to `sinau_context_issuer_poc`. It confirmed the issuer schema is usable while `sinau_private` is not:

- `session_user=sinau_app_runtime_poc`
- `current_user=sinau_context_issuer_poc`
- issuer schema USAGE = true
- private schema USAGE = false

OID-based relation privilege checks returned false for SELECT, INSERT, UPDATE, DELETE, and TRUNCATE on all of the following: `poc_identities`, `poc_auth_sessions`, `poc_tenant_memberships`, `poc_unit_memberships`, and `sinau_private.context_keys`.

Function EXECUTE checks returned:
- true for `sinau_issuer_poc.validate_context_request(text,uuid,uuid)`;
- true for `sinau_issuer_poc.has_feature_entitlement(uuid,text)`;
- false for `sinau_private.verify_context_token(text)`;
- false for `sinau_private.current_verified_context()`.

The transaction ended with `ROLLBACK`; no role, membership, grant, schema, function, policy, or row was changed.

This supports the intended direct least-privilege separation: the issuer capability can call its two functions but cannot directly read authorization/key tables or invoke the query/verifier capability. It does not isolate the runtime login from issuer capability, because the separately tested runtime session can `SET ROLE` to issuer. Arbitrary SQL through that runtime connection can therefore invoke the two issuer functions after switching. This remains a role-model threat-model decision, not an accepted production design.

The audit used catalog OIDs to check ACL-derived privileges, and did not execute the SECURITY DEFINER functions or validate network authentication with the runtime credentials. ADR-007 remains Proposed; no implementation or production DDL is authorized by this evidence.


## 20. Query capability effective-privilege audit — 2026-11-27

The query audit ran in a read-only transaction after simulating `sinau_app_runtime_poc` as the session identity and switching to `sinau_rls_test`. It confirmed:

- `session_user=sinau_app_runtime_poc`
- `current_user=sinau_rls_test`
- issuer schema USAGE = false
- private schema USAGE = true

OID-based relation privilege checks returned false for SELECT, INSERT, UPDATE, DELETE, and TRUNCATE on all four authorization fixture tables (`poc_identities`, `poc_auth_sessions`, `poc_tenant_memberships`, and `poc_unit_memberships`) and on `sinau_private.context_keys`.

Function EXECUTE checks returned:
- false for `sinau_issuer_poc.validate_context_request(text,uuid,uuid)`;
- false for `sinau_issuer_poc.has_feature_entitlement(uuid,text)`;
- true for `sinau_private.verify_context_token(text)`;
- true for `sinau_private.current_verified_context()`.

The transaction ended with `ROLLBACK`; no role, membership, grant, schema, function, policy, or row was changed.

This supports the intended direct least-privilege split: the query capability can use the private verifier/accessor chain but cannot directly read authorization/key tables or invoke issuer functions. Combined with the issuer audit, the two capability roles have distinct schema/function access and no direct table access to the inspected authorization sources or key store.

The runtime login is not isolated from query capability, because the separately tested runtime session can `SET ROLE` to `sinau_rls_test`. A runtime connection retaining this membership can therefore invoke the verifier/accessor functions after switching. This remains a role-model threat-model decision, not an accepted production design.

The audit used catalog OIDs to check ACL-derived privileges. It did not invoke the verifier/accessor functions, exhaustively test RLS data operations, or validate network authentication with the runtime credentials. ADR-007 remains Proposed; no implementation or production DDL is authorized by this evidence.


## 21. Runtime role boundary audit — 2026-11-27

The read-only runtime boundary script 023 completed on `sinau_design_poc` and reported these role attributes:

| Role | LOGIN | INHERIT | SUPERUSER | BYPASSRLS |
|---|---:|---:|---:|---:|
| `sinau_app_runtime_poc` | true | false | false | false |
| `sinau_context_issuer_poc` | false | false | false | false |
| `sinau_rls_test` | false | true | false | false |
| `sinau_context_owner` | false | false | false | false |
| `sinau_poc` | true | true | false | false |

Membership inventory confirms runtime has SET-only (not inherited) membership in issuer and query, no ADMIN OPTION, and no other reachable role in the recursive SET graph. Runtime has no inherited-role paths, no direct USAGE/CREATE in the three private schemas, and no direct EXECUTE on the four context functions. The inspected functions and private authorization/key relations are owned by the NOLOGIN context owner.

The separate `sinau_poc` login is the PoC database-owner/test identity and inherits issuer/query memberships. It must not be used as the application runtime login.

The existing same-connection PoC test 012 requires issuer → query → issuer role switches within one top-level XID. Therefore the current test architecture intentionally grants runtime SET membership to both NOLOGIN capability roles. The proposed threat model treats runtime as a trusted backend executor whose SQL is controlled by the application; it is not a security boundary against arbitrary SQL execution or SQL injection under that runtime identity. Removing these memberships without replacing the transaction/issuer/query architecture would invalidate the tested flow. This is a proposed interpretation, not a production role approval.

Script 023 ended with ROLLBACK and changed no roles or grants.


## 22. Default function EXECUTE privilege correction — 2026-11-27

Script 023 returned zero `pg_default_acl` entries for `sinau_context_owner`. Review of installed setup source identified an ineffective schema-scoped default privilege command in script 005: a per-schema REVOKE cannot remove PostgreSQL's built-in global default EXECUTE grant to PUBLIC for newly created functions. The installed four context functions each have their own explicit PUBLIC EXECUTE revocation, so the finding concerns future functions created by the context owner.

The official PostgreSQL 18 behavior is documented at [ALTER DEFAULT PRIVILEGES](https://www.postgresql.org/docs/18/sql-alterdefaultprivileges.html): per-schema default privileges are added to global defaults and cannot revoke a global default privilege. The corrected source scripts 005 and 010 now use a global command for `sinau_context_owner`:

```sql
ALTER DEFAULT PRIVILEGES
    FOR ROLE sinau_context_owner
    REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
```

Script 024 was executed successfully against `sinau_design_poc`. The global function default ACL is now `{sinau_context_owner=X/sinau_context_owner}` and contains no PUBLIC EXECUTE. All four existing context functions retained their explicit owner/capability grants and have `public_can_execute=false`. The temporary probe function was created with owner EXECUTE and no PUBLIC EXECUTE, then removed by ROLLBACK. The final persistence audit confirmed the global default ACL remains and the probe function does not. This closes the default-function-ACL PoC gate; it does not approve production ACLs.

No existing function grants, role memberships, schemas, tables, policies, or production objects are modified by the intended script 024 fix. ADR-007 remains Proposed.


## 23. Default ACL verified; snapshot-consistency gate — 2026-11-27

Script 024 completed successfully against `sinau_design_poc`. The global function default ACL for `sinau_context_owner` is `{sinau_context_owner=X/sinau_context_owner}`; PUBLIC EXECUTE is absent. The four existing context functions all retain their exact owner/capability grants and report `public_can_execute=false`. A newly created probe inherited owner EXECUTE only, then was removed by ROLLBACK. The global ACL persisted. The default-function-ACL PoC gate is closed.

The next open gate is snapshot consistency. PostgreSQL 18 documents that VOLATILE functions obtain a fresh snapshot for each internal SQL query, whereas STABLE/IMMUTABLE functions use the calling query's snapshot; READ COMMITTED also gives each top-level statement its own snapshot. See:
- [PostgreSQL 18 function volatility](https://www.postgresql.org/docs/18/xfunc-volatility.html)
- [PostgreSQL 18 SPI visibility](https://www.postgresql.org/docs/18/spi-visibility.html)
- [PostgreSQL 18 transaction isolation](https://www.postgresql.org/docs/18/transaction-iso.html)

The installed verifier and accessor are VOLATILE. The candidate verifier v2 should read the signing-key row and the account, exact session, tenant membership, unit membership, and unit lifecycle rows with one joined SELECT, so all authoritative inputs are evaluated under one internal statement snapshot. Separate internal SELECTs could see different commits within one verifier call and produce a mixed authorization decision.

Script 025 executed successfully with observed sequence `active|disabled`: the first internal SELECT read before Connection B committed, and the second internal SELECT read after that commit, while both ran inside one top-level SELECT statement. The probe function was transaction-scoped and rolled back. Connection B restored the synthetic identity; final audit returned exactly one matching row, one active row, and zero disabled rows.

The present RLS policies still need a plan/runtime inspection. Script 007 constructs separate scalar subqueries for tenant and unit values, each referencing the VOLATILE verified-context accessor. Script 026 was executed successfully; the installed academic_years policy produced two InitPlans and exactly two verifier calls for one protected SELECT. See section 24 for the measured output. The next test is script 027, a rollback-only composite row-subquery candidate. Do not begin v2 verifier DDL before that candidate, the complete policy matrix, and the claim/epoch contract are reviewed. ADR-007 remains Proposed.


## 24. Two verifier invocations confirmed; composite row-policy candidate — 2026-11-27

Script 026 was executed successfully with a valid synthetic token for XID 957. The installed `academic_years` policy had two independent scalar subqueries that extracted `tenant_id` and `unit_id` through separate calls to `current_verified_context()`. EXPLAIN displayed two InitPlans, each containing a Function Scan on the accessor. The protected SELECT returned one row, and the transaction-local function counter recorded exactly two calls to `sinau_private.verify_context_token(text)` (2.790 ms total/self time). The audit transaction rolled back.

This is now a measured behavior: **one protected SELECT triggers two verifier calls** under the existing policy. With a v2 verifier performing live authorization checks, those calls may consult authoritative state using different internal VOLATILE/SPI snapshots. A single coherent scope record is required for both comparisons.

Script 027 has been prepared to temporarily replace the `academic_years` policy inside a transaction with a row-valued single-subquery comparison, `(tenant_id, unit_id) = (SELECT ctx.tenant_id, ctx.unit_id FROM sinau_private.current_verified_context() AS ctx)`. It will inspect EXPLAIN, execute one protected SELECT, measure the actual verifier count, and ROLLBACK to restore the installed policy. It has not yet run. This candidate is not yet approved for other table classes, especially tenant-only tables and `audit_events` with nullable `unit_id`. Do not alter persistent script 007 until the test and full RLS policy matrix pass.


## 25. Composite row-context policy measured once — 2026-11-27

Script 027 passed on `sinau_design_poc` for `public.academic_years`. The transaction temporarily replaced the original two-subquery policy with `(tenant_id, unit_id) = (SELECT ctx.tenant_id, ctx.unit_id FROM sinau_private.current_verified_context() AS ctx)`.

EXPLAIN produced one InitPlan/Function Scan whose output contained both context fields; the protected SELECT returned one row; and the transaction-local counter reported exactly one verifier call (`2.623 ms`). The expected PASS notice appeared. ROLLBACK restored the original two-subquery policy, confirmed by the post-rollback `pg_policies` output.

This validates the composite row-comparison candidate for the ordinary tenant+unit shape on `academic_years` only. It does not approve persistent installation or application to all tables. The next gate is a policy matrix covering tenant-only tables, `audit_events` with nullable `unit_id`, read/write operations, malformed/expired tokens, and cross-scope denial. Script 007 remains unchanged until that matrix passes.
