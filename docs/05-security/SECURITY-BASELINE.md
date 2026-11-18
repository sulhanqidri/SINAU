# Baseline Keamanan SINAU

## Prinsip
- Secure by design, privacy by design, least privilege, defense in depth.
- Server-side authorization untuk semua akses.
- Isolasi tenant/unit pada semua jalur pemrosesan.
- Audit untuk tindakan sensitif.
- Secret tidak disimpan di source control.

## Area kontrol
- Authentication, session, password/reset, MFA sesuai risiko.
- RBAC/permissions dan akses berdasarkan tenant/unit.
- Perlindungan IDOR, CSRF, XSS, SQL injection, SSRF, upload berbahaya, dan mass assignment.
- Validasi file, private storage, signed/authorized download.
- Rate limiting dan proteksi brute force.
- Enkripsi transport dan perlindungan data at-rest sesuai desain deployment.
- Logging tanpa token, password, atau data pribadi berlebihan.
- Dependency scanning, patch management, dan secure review.
- Backup terenkripsi, retensi, dan uji restore.
- Incident response dan pencatatan akses istimewa.

## Data anak dan peserta didik

Lakukan minimisasi data, pembatasan akses berdasarkan peran, transparansi penggunaan, retensi yang sah, dan perlindungan khusus untuk data anak. Sebelum peluncuran, tinjau kewajiban hukum Indonesia yang berlaku dan dokumentasikan dasar pemrosesan serta kebijakan privasi.

## Gerbang rilis
Rilis tidak boleh dilanjutkan bila ada temuan kritis tenant isolation, authorization bypass, kebocoran data pribadi, atau kelemahan yang memungkinkan pengambilalihan akun tanpa mitigasi yang disetujui.
