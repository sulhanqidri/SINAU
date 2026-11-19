# ADR-008: Authentication Web dan Session Baseline

- **Status:** Accepted for initial web application bootstrap — API authentication and production hardening remain open.
- **Tanggal:** 2026-11-19
- **Area:** Global identity, web authentication, session lifecycle, tenant onboarding boundary
- **Terkait:** ADR-003, ADR-004, ADR-005, ADR-007, BP-PLT-01, BP-PLT-05, SECURITY-BASELINE.md.

## 1. Konteks

SINAU adalah SaaS multi-tenant. Satu akun global dapat menjadi anggota beberapa tenant dan unit. Proses registrasi pelanggan pada BP-PLT-01 dimulai dari akun global, dilanjutkan verifikasi email, pemilihan bentuk pelanggan, pengisian profil tenant/unit, lalu penyelesaian onboarding dan pembentukan membership awal.

Karena itu, autentikasi tidak boleh sekaligus membuat tenant secara implisit, dan akun yang baru dibuat tidak boleh memperoleh role platform atau akses tenant hanya karena berhasil login.

## 2. Keputusan untuk bootstrap web

1. **Authentication framework:** gunakan autentikasi first-party Laravel melalui Laravel Fortify yang disediakan official Laravel Vue starter kit.
2. **Web transport:** gunakan same-origin web session untuk halaman Inertia. Browser tidak menerima token database RLS.
3. **Session backend awal:** gunakan Laravel database session driver pada PostgreSQL aplikasi. Laravel 13 mengonfigurasi database sebagai session driver default; tidak perlu Redis hanya untuk session.
4. **Session table:** `sessions` adalah tabel infrastruktur global, bukan tabel tenant/unit. Jangan pasang RLS tenant pada tabel session. Akses ke record session dibatasi oleh jalur server/framework dan fungsi issuer yang disetujui.
5. **Session timeout awal:** 120 menit idle untuk bootstrap awal. Nilai ini dapat direvisi melalui pengujian dan kebijakan keamanan.
6. **Cookie:** host-only, HttpOnly, SameSite=Lax; Secure wajib pada preproduction/production yang memakai HTTPS. Jangan menaruh session ID pada URL.
7. **Email verification:** aktifkan. Pendaftar harus memverifikasi email sebelum menyelesaikan onboarding tenant/unit sesuai BP-PLT-01.
8. **Password reset dan logout:** gunakan flow Fortify; logout menghancurkan session saat ini. Reset credential, global account disable, atau tindakan revoke-all harus menghapus/mencabut session terkait sehingga request berikutnya memerlukan autentikasi ulang.
9. **Login rate limit:** mulai dengan batas lima percobaan per menit yang dikunci berdasarkan identifier login ternormalisasi dan sumber request; sesuaikan setelah pengujian abuse/rate-limit.
10. **2FA:** sediakan fitur TOTP opsional pada bootstrap. Kewajiban 2FA untuk platform operator, tenant owner, dan tindakan sensitif harus menjadi policy terpisah sebelum production.
11. **API auth:** tidak membuat personal access token atau bearer API pada bootstrap web. Pilihan Sanctum, mobile client, dan integrasi pihak ketiga ditunda sampai kebutuhan client/API dan threat model disetujui.

## 3. Batas registrasi dan onboarding

- Public registration tetap tersedia karena BP-PLT-01 menetapkan calon pelanggan dapat membuat akun sendiri.
- Action pembuatan user dari starter kit hanya membuat **identitas global** (nama, email terverifikasi, password hash, status akun dan atribut autentikasi yang disetujui).
- Action ini **tidak** membuat tenant, education unit, tenant membership, unit membership, role, permission, entitlement, atau platform privilege.
- Email yang belum terverifikasi hanya dapat menyelesaikan langkah pra-onboarding dan verifikasi email.
- Setelah email terverifikasi, onboarding wizard menjalankan validasi dan membuat tenant/unit/membership awal secara atomik sesuai BP-PLT-01, ADR-001, ADR-003, dan ADR-004.
- Pendaftar menjadi tenant member dan hanya unit member pada unit yang dibuat/ditugaskan; pendaftar tidak pernah menjadi platform admin secara otomatis.
- Idempotency dan unique constraints mencegah request registrasi berulang membuat tenant/unit/membership ganda.

## 4. Pemisahan user, tenant, unit, dan role

- `users` tetap identitas global. Jangan menambahkan `tenant_id`, `unit_id`, atau `role` tunggal sebagai sumber authorization pada user.
- Membership dan role assignment tetap mengikuti model terpisah pada ADR-003.
- Tenant/unit selector yang disimpan pada session hanyalah preferensi navigasi. Setiap request/transaction harus memvalidasi ulang tenant lifecycle, unit ownership, membership, permission, dan resource relationship.
- Jangan mengaktifkan fitur **Teams** starter kit sebagai pengganti tenant/unit SINAU. Model Teams Laravel bukan domain Tenant + Education Unit SINAU.
- Session yang valid tidak berarti user memiliki permission untuk semua operasi atau entitlement fitur.

## 5. Trusted principal dan database context

Middleware/guard membangun principal internal yang tidak dapat dibuat oleh controller dari data request. Minimal berisi:
- actor/user ID dari user yang sudah terautentikasi oleh Laravel guard;
- referensi session aktif dari server-side session store;
- waktu autentikasi dan assurance metadata bila tersedia.

Prinsip:
- Jangan menerima `actor_id` dari body, query string, route, cookie tambahan, atau header sebagai bukti identitas.
- Tenant/unit dari route atau form adalah selector tidak tepercaya sampai validator membuktikan membership.
- Context issuer hanya menerima principal dari middleware tepercaya, bukan DTO yang dibentuk controller dari input client.
- Validasi session/account/membership, penerbitan token, alokasi XID, pemasangan context, dan protected SQL harus memenuhi satu-connection/top-level-transaction contract pada ADR-007.
- Token RLS tetap server-side, transaction-bound, dan tidak pernah dikembalikan ke browser, local storage, URL, atau session payload.
- Session middleware dan context issuer harus memakai koneksi PostgreSQL aplikasi yang ditetapkan; implementasi harus membuktikan bahwa sesi yang dicabut sebelum penerbitan tidak dapat memperoleh context pada transaksi baru.

## 6. Pengaturan session awal

Bootstrap harus menggunakan nilai konfigurasi setara berikut (bukan credential):

| Setting | Nilai awal |
|---|---|
| `SESSION_DRIVER` | `database` |
| `SESSION_LIFETIME` | `120` |
| `SESSION_ENCRYPT` | `true` setelah kompatibilitas starter kit diuji |
| `SESSION_HTTP_ONLY` | `true` |
| `SESSION_SECURE_COOKIE` | `true` pada HTTPS preproduction/production |
| `SESSION_SAME_SITE` | `lax` |
| `SESSION_DOMAIN` | kosong/host-only kecuali domain deployment menuntut konfigurasi eksplisit |
| `DB_CONNECTION` | `pgsql` |
| `SESSION_CONNECTION` | koneksi PostgreSQL aplikasi yang sama |

Jangan commit file `.env`, APP_KEY, password database, session secret, mail credential, atau signing key. Hanya `.env.example` yang berisi placeholder yang boleh di-commit.

## 7. Pengujian wajib pada bootstrap

- register membuat satu user global; tidak membuat tenant/membership/role;
- email verification diperlukan untuk melanjutkan onboarding;
- duplicate email ditangani tanpa account enumeration;
- rate limit login dan password reset berjalan;
- login mengubah session ID; logout menghapus session saat ini;
- revoke-all/global account disable menolak session lama;
- sesi user A tidak dapat dipakai untuk mengakses identitas user B;
- tenant/unit selector yang tidak punya membership ditolak;
- user multi-tenant hanya melihat tenant/unit dari membership aktif;
- tenant membership tidak memberi akses otomatis ke semua unit;
- session data tidak masuk tenant RLS dan tidak membocorkan secret ke log;
- CSRF, cookie flags, secure transport, dan 2FA flow diuji;
- request berikutnya setelah revoke tidak memperoleh context RLS.

## 8. Batas dan keputusan yang masih terbuka

ADR ini menetapkan baseline auth web untuk bootstrap, bukan seluruh desain identity/authorization. Hal berikut tetap memerlukan review/PoC:
- implementasi final session store/revocation dan interaksi session handler dengan koneksi transaksi;
- apakah sesi framework database cukup untuk validator atau memerlukan registry session/revocation terpisah;
- auth epoch dan semantic pencabutan pada transaksi yang sudah berjalan;
- kebijakan MFA wajib untuk role/tindakan sensitif;
- Sanctum atau API authentication lain untuk client/mobile;
- password policy final, SSO/passkey, dan recovery policy;
- audit retention dan notifikasi keamanan.

Jangan membuat tabel produksi atau role produksi berdasarkan ADR ini sebelum kontrak database dan gerbang ADR-006/ADR-007 disetujui.

## 9. Non-goals

- ADR ini tidak memberi hak tenant/unit berdasarkan role atau nama akun.
- ADR ini tidak menggunakan Laravel Teams.
- ADR ini tidak mengesahkan WorkOS/AuthKit atau provider identitas eksternal.
- ADR ini tidak membuat bearer token mobile/API.
- ADR ini tidak membuat migration tenant, unit, membership, role, permission, atau entitlement produksi.
- ADR ini tidak mengubah database `sinau_design_poc` atau database produksi yang sudah ada.
