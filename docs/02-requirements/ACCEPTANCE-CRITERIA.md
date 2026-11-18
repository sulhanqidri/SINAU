# Acceptance Criteria — MVP

## Tenant dan unit
- Sistem mendukung tenant bertipe yayasan (foundation) dan sekolah/madrasah mandiri (independent_provider).
- Tenant yayasan dapat menaungi lebih dari satu unit pendidikan, termasuk campuran sekolah umum dan madrasah.
- Tenant mandiri dapat onboarding tanpa yayasan dan terhubung langsung dengan unit pendidikan pertamanya.
- Kedua tipe tenant menggunakan modul akademik, data model, UI, dan aturan keamanan yang sama.
- Jenis dan jenjang pendidikan ditetapkan per unit, bukan dari tipe tenant.
- Pengguna tenant A tidak dapat membaca, mengubah, menghapus, mengekspor, atau mengunduh data tenant B.
- Pengguna unit A tidak dapat mengakses unit B kecuali memiliki membership dan permission.
- Membership tenant tidak otomatis membuka semua unit tanpa aturan permission eksplisit.
- Manipulasi identifier di URL, payload, filter, dan API tidak melewati scope.
- Cache, job, file, dan laporan tidak mencampur data antar scope.
- Transfer unit antar tenant hanya melalui workflow terotorisasi, tercatat, dan menjaga histori.

## Data siswa
- Siswa memiliki identitas dasar yang tidak tergantung pada kelas.
- Riwayat enrollment mencatat unit, tahun ajaran, dan rombel.
- Perpindahan kelas/tahun ajaran tidak menimpa histori sebelumnya.
- Hubungan wali dapat diverifikasi dan dicabut dengan audit.

## Akademik
- Periode akademik memiliki tanggal dan status yang tervalidasi.
- Kurikulum dan konfigurasi memiliki versi/periode efektif.
- Perubahan konfigurasi baru tidak mengubah hasil historis tanpa proses migrasi yang disengaja.
- Penugasan guru membatasi akses presensi dan penilaian.

## Presensi dan nilai
- Record menyimpan siapa, kapan, untuk siapa, unit, kelas/sesi, dan periode.
- Koreksi membutuhkan alasan dan menyimpan nilai sebelum/sesudah.
- Nilai yang sudah disahkan tidak dapat diubah diam-diam; koreksi mengikuti workflow dan audit.
- Rekap sesuai sumber transaksi dan dapat ditelusuri.

## Impor dan ekspor
- File impor dipreview sebelum commit.
- Baris invalid dilaporkan dengan nomor baris dan sebab.
- Impor ulang tidak menggandakan data tanpa aturan matching yang jelas.
- Ekspor hanya memuat kolom yang diizinkan dan tercatat.

## UX
- Semua layar memiliki loading, empty, error, success, dan validation state yang tepat.
- Navigasi dan komponen konsisten pada desktop dan mobile.
- Aksi destruktif meminta konfirmasi.
- Fokus keyboard dan label form dapat digunakan.
