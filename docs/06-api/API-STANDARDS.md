# Standar API SINAU

- API harus memiliki kontrak terdokumentasi dan versioning.
- Semua endpoint melakukan autentikasi dan otorisasi server-side.
- Tenant/unit context ditentukan dan divalidasi dari identitas serta keanggotaan; jangan percaya tenant_id dari body sebagai bukti akses.
- Gunakan validasi input dan skema respons yang konsisten.
- Terapkan pagination dan filter yang dibatasi.
- Gunakan status HTTP secara tepat dan format error yang stabil.
- Operasi sensitif dan pembayaran mendukung idempotency sesuai kebutuhan.
- Webhook memverifikasi signature, timestamp/replay, dan idempotency.
- Jangan mengembalikan field sensitif yang tidak diperlukan.
- Dokumentasikan scopes, permissions, rate limits, pagination, error codes, dan deprecation.
- Perubahan breaking membutuhkan versi/masa transisi dan rencana migrasi.
