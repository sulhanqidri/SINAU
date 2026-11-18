# Pedoman Design System SINAU

**Status:** Prinsip disahkan sebagai baseline; nilai visual final belum diputuskan.

## Tujuan

Membuat semua modul SINAU terasa sebagai satu produk: konsisten, profesional, mudah dipelajari, responsif, dan inklusif.

## Aturan wajib

1. Semua halaman menggunakan design tokens dan komponen bersama.
2. Layout aplikasi memiliki pola navigasi global yang konsisten.
3. Komponen tombol, input, select, date picker, tabel, pagination, tabs, modal, toast, badge/status, dropdown, dan empty state harus memiliki pola baku.
4. Setiap komponen memiliki state normal, hover/focus, active, disabled, loading, dan error jika relevan.
5. Semua aksi dapat dipahami; label aksi mengutamakan kata kerja yang jelas.
6. Form memiliki label, instruksi, validasi, dan pesan kesalahan yang dapat ditindaklanjuti.
7. Tabel data besar mendukung pencarian/filter/paginasi yang tepat dan tetap usable pada layar sempit.
8. Konfirmasi diperlukan untuk tindakan destruktif atau sulit dibatalkan.
9. Status tidak boleh mengandalkan warna saja.
10. Kontras, keyboard navigation, focus indicator, dan label aksesibilitas harus diperhatikan.
11. UI menampilkan tenant, unit pendidikan, dan periode aktif ketika konteks tersebut berpengaruh pada data.
12. Hindari dashboard yang penuh kartu/angka tanpa prioritas dan makna tindakan.

## Token yang harus didefinisikan

- Warna brand, neutral, semantic (success/warning/danger/info), surface, border, text, focus.
- Font family, type scale, line height, weight.
- Spacing scale.
- Radius dan shadow/elevation.
- Breakpoints dan container widths.
- Icon set dan ukuran.
- Z-index/layering.

Nilai konkret belum dikunci. Tentukan melalui eksplorasi visual, uji aksesibilitas, dan ADR/design decision; jangan mengarang nilai berbeda per modul.

## Pola halaman

- Dashboard ringkas sesuai peran.
- Daftar: judul, deskripsi singkat, aksi utama, filter, tabel, pagination.
- Detail: ringkasan, informasi terstruktur, riwayat/audit sesuai izin.
- Form: grouping logis, validasi server, simpan/batal yang jelas.
- Wizard: hanya untuk proses multi-tahap yang benar-benar membutuhkan.
- Empty/error state: jelaskan keadaan dan langkah berikutnya.

## Review visual

Setiap PR UI harus menyertakan screenshot/rekaman pada viewport desktop dan mobile bila relevan, daftar komponen yang digunakan, dan pemeriksaan state utama. Perubahan global harus diuji pada halaman lintas modul.
