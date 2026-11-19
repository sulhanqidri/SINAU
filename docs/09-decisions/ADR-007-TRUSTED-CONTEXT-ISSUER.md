# ADR-007: Trusted Context Issuer, Session, dan Transaksi RLS

- **Status:** Proposed — kontrak teknis untuk PoC berikutnya; belum menjadi persetujuan implementasi produksi.
- **Tanggal:** 2026-11-19
- **Area:** Authentication, session, tenant/unit context, PostgreSQL RLS, connection lifecycle
- **Terkait:** ADR-003, ADR-005, ADR-006, `TRUSTED-CONTEXT-ISSUER-DESIGN.md`, dan PostgreSQL PoC 005–011.

## 1. Konteks dan masalah

PoC PostgreSQL telah membuktikan dua bagian secara terpisah:

1. Verifier PostgreSQL dapat memvalidasi token bertanda tangan yang terikat pada audience/database, masa berlaku, key ID aktif, dan top-level transaction XID. RLS memperoleh tenant/unit hanya dari klaim terverifikasi.
2. Fixture issuer sintetis dapat menurunkan actor dari session bearer sintetis dan memeriksa status akun, session, tenant membership, unit membership, tanggal berlaku, pasangan tenant/unit, serta entitlement secara terpisah.

Kedua hasil tersebut belum membuktikan alur aplikasi nyata. Repository belum memiliki aplikasi Laravel, middleware autentikasi, session store, role database runtime, connection pool, atau service yang menggabungkan principal autentikasi dengan transaksi PostgreSQL.

ADR-003 sudah menetapkan baseline identitas global, tenant membership, unit membership, permission berscope, dan default deny. ADR-005 masih Proposed: Laravel 13 + Vue 3 + Inertia merupakan kandidat PoC; session direkomendasikan untuk web, sedangkan autentikasi API/client pihak pertama (termasuk evaluasi Sanctum) belum final.

ADR ini mendefinisikan kontrak yang harus dipenuhi dan pilihan yang masih perlu persetujuan sebelum signer aplikasi dibangun.

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
4. Koneksi mengalokasikan dan menyimpan top-level XID dengan `pg_current_xact_id()`. XID tersebut hanya berlaku bagi transaksi itu.
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

Baseline yang diusulkan:
- transaksi baru tidak boleh menerima context setelah pencabutan account/session/membership telah committed;
- transaksi berjalan memiliki batas waktu pendek dan token berumur pendek;
- pencabutan harus membatalkan grant pada transaksi berikutnya serta session/cache terkait.

**Belum diputuskan:** apakah transaksi yang sudah berjalan boleh selesai setelah membership dicabut, atau harus diputus segera. Jika perlu immediate revocation di tengah transaksi, verifier memerlukan authorization epoch/revocation check (atau kontrol database setara) dengan desain concurrency/locking dan pengujian race. PoC saat ini tidak membaca membership pada setiap evaluasi RLS sehingga tidak membuktikan immediate revocation.

## 10. Opsi dan keputusan yang masih terbuka

| Area | Baseline/rekomendasi sementara | Status |
|---|---|---|
| Web authentication | Server-side session sebagai arah ADR-005 | Belum final |
| API/client authentication | Evaluasi Sanctum atau mekanisme lain sesuai client dan threat model | Belum final |
| Session store dan revocation | Server-side record dengan lifecycle/revocation yang bisa diuji | Belum final |
| Principal contract | Middleware-created immutable principal; actor tidak boleh berasal dari request | Invarian yang diusulkan |
| Membership validator | Narrow SECURITY DEFINER function dengan fixed search_path dan tanpa direct table grants | Sudah diuji sintetis; kontrak produksi belum final |
| Runtime roles | Owner/migration/issuer/query dipisah; role switching dalam satu transaksi diuji sebelum dipakai | Role switching issuer/query dan XID continuity lulus pada satu direct PostgreSQL session; pooler/app runtime belum diuji |
| Signing algorithm | HMAC PoC; evaluasi asymmetric/KMS sebelum produksi | Belum final |
| Connection pooling | Satu koneksi + satu top-level transaction dari XID sampai protected SQL | Invarian teknis; pooler belum diuji |
| In-flight revocation | New transactions denied; policy untuk transaksi yang sudah berjalan | Menunggu keputusan keamanan/produk |
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

## 12. Non-goals dan batas keselamatan

- ADR ini tidak memilih final framework, library RBAC, session store, API auth, key algorithm, KMS, pooler, atau kebijakan transaksi in-flight.
- ADR ini tidak membuat migration produksi, tabel users/membership produksi, role database produksi, endpoint login, atau signer Laravel.
- Synthetic fixture 010/011 bukan data user nyata dan tidak boleh dipakai di aplikasi.
- Script 006 dengan actor/tenant/unit statis tetap hanya signer PoC dan tidak boleh dipakai oleh web runtime.
- Semua eksperimen tetap hanya pada `sinau_design_poc`.
- Jangan menyentuh database produksi `sinau`, role `sinau_app`, SQLRadius, atau MikroTik.

## 13. Langkah berikutnya

1. Product Owner/security menyetujui pilihan auth web/API, session lifecycle, revocation semantics, dan key custody.
2. Finalisasi role matrix dan kontrak principal/session dalam ADR terpisah atau revisi ADR ini.
3. Selesai: `012-test-issuer-query-role-switch.sql` lulus pada direct PostgreSQL session; issuer → query → issuer mempertahankan XID 890 dan ROLLBACK membersihkan transaction-local probe. Bukti belum mencakup real signed-token issuance atau pooler.
4. Jalankan `docs/03-database/poc/013-test-context-and-role-cleanup.sql` pada `sinau_design_poc` untuk menguji bahwa `app.context_token` dan `SET LOCAL ROLE` dibersihkan setelah COMMIT maupun ROLLBACK, lalu transaksi baru tetap fail-closed tanpa token.
5. Setelah direct-session cleanup test lulus, tambahkan simulasi connection pooling/connection reuse serta exception/rollback tests pada topology yang dipilih.
6. Setelah application stack disetujui dan bootstrap Stage E dimulai, implementasikan adapter Laravel yang memenuhi kontrak ini tanpa menyalin fixture sintetis ke schema produksi.
