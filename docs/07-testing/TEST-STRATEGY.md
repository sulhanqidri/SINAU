# Strategi Pengujian SINAU

## Tingkatan
- Unit: aturan domain, kalkulasi, validasi.
- Feature/API: alur end-to-end pada server.
- Integration: database, queue, storage, email, dan provider.
- UI: komponen, form, navigasi, responsive, accessibility.
- Security: tenant isolation, authorization, IDOR, input/file handling.
- Acceptance: validasi oleh pengguna sekolah dan madrasah.

## Test matrix
Semua fitur yang relevan diuji pada:
- Tenant berbeda.
- Unit berbeda dalam tenant yang sama.
- Role berbeda.
- Jenis lembaga dan jenjang berbeda.
- Periode akademik yang berbeda.
- Data kosong, normal, batas, duplikat, dan tidak valid.
- Retry, timeout, kegagalan parsial, dan request berulang untuk proses async/integrasi.

## Release gate
- Tidak ada tes kritis yang gagal.
- Tidak ada bypass isolasi tenant/otorisasi yang diketahui tanpa mitigasi tertulis.
- Migration diuji pada data representatif.
- Backup/restore dan observability siap sesuai tahap rilis.
- Acceptance criteria disetujui.
- Dokumentasi dan changelog diperbarui.
