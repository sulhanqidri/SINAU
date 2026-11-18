# Panduan Kontribusi SINAU

## Sebelum mengubah kode atau dokumentasi

1. Baca `README.md` dan `docs/00-governance/PROJECT-CONSTITUTION.md`.
2. Periksa blueprint dan spesifikasi modul yang berkaitan.
3. Pastikan perubahan sesuai cakupan dan tidak melemahkan isolasi tenant, keamanan, atau konsistensi UI.
4. Untuk perubahan yang belum tercakup, ajukan catatan perubahan sesuai `CHANGE-CONTROL.md`.

## Alur Git

- `main`: baseline yang stabil dan siap dirilis.
- `preproduction`: integrasi untuk pengujian sebelum production.
- `develop`: integrasi pengembangan aktif.
- `feature/<nama>`: fitur baru.
- `fix/<nama>`: perbaikan bug.
- `hotfix/<nama>`: perbaikan mendesak pada rilis.

Jangan mengembangkan fitur langsung pada `main`. Perubahan masuk melalui pull request dan pemeriksaan.

## Standar pull request

Setiap pull request harus menjelaskan:
- Tujuan dan ruang lingkup.
- Dokumen/spec yang menjadi acuan.
- Dampak terhadap tenant, role, data pribadi, database, API, UI, dan integrasi.
- Migrasi atau perubahan konfigurasi yang diperlukan.
- Pengujian yang dijalankan dan hasilnya.
- Dokumentasi yang diperbarui.

## Definition of Done

Pekerjaan belum dianggap selesai sampai:
- Kriteria penerimaan terpenuhi.
- Pengujian relevan lulus.
- Otorisasi dan isolasi tenant diuji.
- UI konsisten dan responsif jika ada perubahan antarmuka.
- Dokumentasi dan changelog diperbarui.
- Risiko, keterbatasan, dan langkah deployment dicatat.
