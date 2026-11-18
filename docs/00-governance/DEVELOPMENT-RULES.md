# Aturan Pengembangan SINAU

## 1. Urutan kerja wajib

Untuk setiap fitur:
1. Pahami kebutuhan pengguna dan jenis lembaga/jenjang yang terdampak.
2. Periksa konstitusi, blueprint, dan spesifikasi modul.
3. Buat atau perbarui requirement dan acceptance criteria.
4. Analisis dampak tenant, role, privasi, database, API, UI, laporan, integrasi, dan migrasi.
5. Implementasikan pada branch kerja, bukan langsung di `main`.
6. Tambahkan pengujian otomatis dan manual yang relevan.
7. Perbarui dokumentasi, diagram, kamus data, dan changelog.
8. Uji di preproduction sebelum production.

## 2. Aturan arsitektur dan kode

- Pertahankan batas domain/modul dan hindari ketergantungan silang yang tidak perlu.
- Letakkan business rules pada lapisan aplikasi/domain yang tepat, bukan tersebar dalam controller atau komponen UI.
- Gunakan transaksi database untuk operasi multi-langkah yang harus atomik.
- Gunakan idempotency untuk proses yang dapat diulang, terutama pembayaran, webhook, sinkronisasi, dan job.
- Job harus membawa konteks tenant/unit secara eksplisit dan memvalidasinya kembali saat dieksekusi.
- Jangan menambahkan dependency tanpa alasan, evaluasi pemeliharaan, lisensi, dan keamanan.
- Hindari optimasi prematur; ukur bottleneck terlebih dahulu.

## 3. Aturan database

- Semua tabel yang menyimpan data milik tenant harus memiliki batas kepemilikan yang jelas.
- Tentukan apakah data berscope tenant, sekolah/unit, global referensi, atau pengguna platform.
- Buat foreign key, unique constraint, dan index yang sesuai.
- Pastikan relasi tidak bisa menghubungkan record milik tenant berbeda.
- Migration harus dapat ditinjau, aman untuk data yang sudah ada, dan memiliki strategi rollback atau forward-fix yang jelas.
- Jangan mengubah data production secara manual tanpa prosedur perubahan yang tercatat.
- Perubahan skema wajib memperbarui ERD dan data dictionary.

## 4. Aturan keamanan

- Server selalu menjadi sumber keputusan otorisasi.
- Uji akses lintas tenant, lintas unit, perubahan ID (IDOR), ekspor, unduhan berkas, API, pencarian, laporan, dan job.
- Jangan pernah menyimpan secret dalam repository.
- Gunakan environment variables/secret manager dan contoh konfigurasi tanpa secret.
- Jangan menampilkan data pribadi lebih banyak dari yang diperlukan.
- Catat audit event untuk perubahan sensitif, persetujuan, nilai, pembayaran, dokumen, dan konfigurasi akses.

## 5. Aturan UI/UX

- Gunakan design tokens dan komponen bersama.
- Jangan membuat warna, ukuran, tombol, tabel, atau pola navigasi baru tanpa alasan desain.
- Sediakan state loading, empty, error, success, disabled, dan validation.
- Form harus memberi label, validasi, pesan kesalahan yang jelas, dan pencegahan submit ganda.
- Tabel harus mendukung kebutuhan responsif, pencarian/filter yang relevan, dan paginasi untuk data besar.
- Periksa tampilan pada lebar desktop dan mobile.
- Jangan menggunakan warna sebagai satu-satunya penanda status.

## 6. Pengujian minimum

- Unit test untuk business rules.
- Feature/integration test untuk alur pengguna dan API.
- Tenant isolation test untuk semua pola akses data.
- Authorization test per role dan ruang lingkup unit.
- Regression test untuk fitur yang terdampak.
- Validasi migration dan data integrity.
- Accessibility dan responsive UI checks untuk perubahan UI.
- Uji idempotency, retry, dan kegagalan parsial untuk proses asynchronous/integrasi.

## 7. Dokumentasi wajib

Setiap perubahan yang relevan harus memperbarui:
- Requirement dan acceptance criteria.
- Spesifikasi modul.
- ERD dan data dictionary untuk perubahan data.
- API contract untuk perubahan endpoint.
- Design system untuk perubahan pola UI bersama.
- ADR untuk keputusan arsitektur penting.
- Changelog untuk perubahan produk yang terlihat.

## 8. Larangan

- Jangan memasukkan fitur di luar scope secara diam-diam.
- Jangan menyalin kode SQLRadius tanpa pemeriksaan kesesuaian dan lisensi; SINAU adalah produk/repository terpisah.
- Jangan melemahkan isolasi tenant demi mempercepat implementasi.
- Jangan membuat bypass otorisasi untuk menyelesaikan bug.
- Jangan menyimpan data nyata siswa/pegawai ke fixture, screenshot publik, log, atau repository.
- Jangan mengklaim integrasi/regulasi telah sesuai tanpa verifikasi.
