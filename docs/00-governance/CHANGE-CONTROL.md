# Pengendalian Perubahan SINAU

Perubahan diperbolehkan, tetapi harus punya alasan, dampak, dan jejak keputusan. Dokumen ini mencegah scope creep dan perubahan desain/arsitektur yang tidak konsisten.

## Kategori perubahan

- **Editorial:** perbaikan bahasa/penjelasan tanpa mengubah maksud.
- **Fitur dalam scope:** implementasi kebutuhan yang sudah disetujui.
- **Perubahan requirement:** mengubah perilaku, cakupan, atau kriteria penerimaan.
- **Perubahan desain sistem:** mengubah tokens, komponen, pola navigasi, atau layout bersama.
- **Perubahan arsitektur/data:** mengubah batas modul, tenant model, kontrak API, atau skema inti.
- **Perubahan regulasi:** mengubah implementasi karena sumber aturan atau tanggal berlakunya berubah.

## Prosedur

1. Catat masalah/tujuan dan siapa pengguna yang terdampak.
2. Catat jenis lembaga, jenjang, unit, role, dan periode yang terdampak.
3. Analisis dampak pada keamanan, privasi, isolasi tenant, data lama, UI, API, laporan, integrasi, performa, dan biaya.
4. Cantumkan alternatif serta konsekuensi jika tidak dilakukan.
5. Perbarui requirement/spesifikasi dan acceptance criteria.
6. Untuk keputusan arsitektur penting, buat ADR.
7. Minta review sebelum perubahan digabung.
8. Perbarui changelog dan dokumentasi operasional.

## Aturan kompatibilitas

- Perubahan breaking pada API atau database memerlukan strategi migrasi.
- Perubahan UI bersama harus diperiksa pada modul yang menggunakan komponen tersebut.
- Perubahan aturan pendidikan harus memiliki sumber resmi dan versi efektif.
- Jangan menghapus kolom, status, atau alur historis sebelum data dan konsumen lama dipetakan.
- Perubahan darurat tetap harus didokumentasikan setelah mitigasi, disertai alasan dan tindak lanjut.

## Template usulan perubahan

```md
# Usulan Perubahan: [judul]

- Tanggal:
- Pengusul:
- Kategori:
- Status: Proposed

## Masalah dan tujuan
## Pengguna/lembaga/jenjang terdampak
## Perilaku saat ini
## Perilaku yang diusulkan
## Dampak keamanan dan tenant
## Dampak database/API/UI/integrasi
## Alternatif dan risiko
## Acceptance criteria
## Dokumen/ADR yang perlu diperbarui
## Keputusan dan reviewer
```
