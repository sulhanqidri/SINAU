# Pola UX Global

## Kerangka aplikasi
- Sidebar utama untuk navigasi domain.
- Topbar untuk identitas SINAU, tenant/unit aktif, periode aktif, notifikasi, dan akun.
- Breadcrumb pada halaman bertingkat.
- Page header berisi judul, deskripsi singkat, dan aksi utama.
- Konten memakai lebar dan spacing konsisten.

## Daftar data
Judul → aksi utama → pencarian/filter → tabel/daftar → pagination. Filter aktif harus terlihat dan dapat dihapus. Aksi massal hanya muncul jika permission tersedia.

## Formulir
Kelompokkan field menurut topik; bedakan wajib/opsional; tampilkan validasi dekat field; pertahankan input saat validasi gagal; cegah submit ganda; beri ringkasan hasil setelah tersimpan.

## Dashboard
Dashboard disesuaikan role dan unit aktif. Hindari angka dummy di production. Setiap kartu statistik harus menjelaskan periode dan sumber data.

## Konteks
Jika data dipengaruhi unit, tahun ajaran, semester, atau rombel, konteks tersebut harus terlihat dan divalidasi pada server.
