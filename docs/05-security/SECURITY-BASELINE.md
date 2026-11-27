# Baseline Keamanan SINAU

## Prinsip
- Secure by design, privacy by design, least privilege, defense in depth.
- Default deny dan server-side authorization untuk semua akses.
- Isolasi tenant/unit pada seluruh jalur pemrosesan.
- Audit untuk tindakan sensitif dan akses istimewa.
- Secret tidak disimpan di source control.

## Area kontrol
- Authentication, session, password/reset, MFA sesuai risiko.
- Membership dan RBAC/permissions dengan scope platform, tenant, dan unit.
- Perlindungan IDOR, CSRF, XSS, SQL injection, SSRF, upload berbahaya, dan mass assignment.
- Context tenant/unit tidak dipercaya dari payload, header, atau route tanpa validasi membership.
- Scoped lookup sebelum read/update/delete; tidak mengandalkan global ORM scope saja.
- Composite constraints untuk konsistensi tenant_id dan unit_id.
- Validasi file, private storage, opaque object key, dan authorization pada setiap download.
- Cache/search/export/job/webhook/scheduler selalu membawa scope yang benar.
- Rate limiting dan proteksi brute force.
- Enkripsi transport dan perlindungan data at-rest sesuai desain deployment.
- Logging tanpa token, password, atau data pribadi berlebihan.
- Dependency scanning, patch management, dan secure review.
- Backup terenkripsi, retensi, dan uji restore.
- Incident response dan pencatatan akses istimewa.

## Data anak dan peserta didik

Lakukan minimisasi data, pembatasan akses berdasarkan peran dan relasi, transparansi penggunaan, retensi yang sah, serta perlindungan khusus untuk data anak. Sebelum peluncuran, tinjau kewajiban hukum Indonesia yang berlaku dan dokumentasikan dasar pemrosesan serta kebijakan privasi.

## Akses platform support

Akses operator platform ke data tenant harus least privilege, memiliki alasan dan masa berlaku, serta dicatat. Impersonation wajib terlihat dan tidak boleh melewati audit.

## Pengujian tenant isolation

Gunakan fixture sintetis dengan minimal dua tenant, beberapa unit, dan beberapa jenis pengguna. Jalankan pengujian negatif untuk IDOR, manipulasi context, membership revoke, raw SQL, bulk action, file, export, cache, search, dan queue. Detail: `TENANT-THREAT-MODEL.md` dan `TENANT-ISOLATION-TEST-PLAN.md`.

## Gerbang rilis

Rilis tidak boleh dilanjutkan bila ada temuan kritis tenant isolation, authorization bypass, kebocoran data pribadi, file privat terbuka, atau kelemahan yang memungkinkan pengambilalihan akun tanpa mitigasi yang disetujui.
