# Threat Model: Tenant dan Unit Isolation

**Status:** Baseline ancaman untuk desain dan pengujian; diperbarui selama implementasi.

## Aset yang dilindungi
- Data identitas dan kontak siswa, wali, guru, dan pegawai.
- Enrollment, presensi, nilai, rapor, dokumen, dan data keuangan.
- Kredensial, sesi, token, file privat, konfigurasi tenant, dan audit trail.
- Integritas relasi tenant-unit dan histori akademik.

## Trust boundary
1. Browser/mobile client → API/web application.
2. Authenticated user → tenant membership.
3. Tenant context → unit context.
4. Application layer → database/query builder/raw SQL.
5. Web request → queue/scheduler/worker.
6. Application → object storage/cache/search/export.
7. Platform support operator → customer data.

## Aktor dan ancaman utama

| Aktor / sumber | Ancaman | Dampak |
|---|---|---|
| User tenant biasa | Mengganti ID tenant/unit pada URL atau payload | IDOR, kebocoran data |
| User unit | Mengakses unit lain dalam yayasan | Akses berlebihan lintas unit |
| User wali/siswa | Menebak ID siswa lain | Kebocoran data anak |
| Developer/query | Lupa filter tenant_id | Kebocoran lintas tenant |
| Background worker | Job kehilangan atau salah membawa context | Data salah tenant |
| Cache/search | Key tidak mengandung scope | Cache poisoning/data silang |
| File/export | Object key atau download URL dapat ditebak | Dokumen terbuka |
| Platform operator | Akses dukungan tanpa alasan/audit | Penyalahgunaan privileged access |
| Tenant administrator | Memberi role terlalu luas | Privilege escalation |

## Skenario serangan yang harus diuji

- Mengganti tenant_id, unit_id, student_id, enrollment_id, file_id, dan export_id.
- Mengirim identifier valid milik tenant lain pada endpoint detail, update, delete, bulk, dan search.
- Mengubah query filter/sort/include untuk mengakses data lintas scope.
- Mengakses endpoint melalui query builder/raw SQL yang tidak memakai global scope.
- Mengulang request setelah membership dicabut atau role diturunkan.
- Memutar ulang signed URL setelah kedaluwarsa atau setelah akses dicabut.
- Menjalankan job dengan tenant context kosong, stale, atau tidak cocok dengan resource.
- Menabrakkan cache key dua tenant untuk resource ID yang sama.
- Memanipulasi webhook, import, scheduled report, dan export lintas tenant.
- Menyalahgunakan impersonation atau akses platform support.

## Mitigasi desain
- Default deny dan authorization server-side per resource.
- Scoped query sebelum load/mutate resource.
- Composite FK/unique constraint untuk tenant-unit consistency.
- Context berasal dari membership tervalidasi.
- Context eksplisit dan immutable dalam job payload; worker memvalidasi ulang.
- Private object storage, opaque key, authorization pada setiap download.
- Cache key dan search filter menyertakan tenant_id/unit_id.
- Rate limit, audit, alert untuk akses lintas scope yang ditolak.
- Test fixture multi-tenant dan test negatif di CI.

## Risiko residual
Shared database/shared schema tidak memberikan isolasi fisik. Kesalahan query aplikasi tetap menjadi risiko utama; constraint dan pengujian mengurangi tetapi tidak menghapus risiko. Kebutuhan isolasi fisik dapat mendorong tenant tertentu ke database tersendiri setelah arsitektur routing siap.

## Gerbang rilis
Tidak boleh rilis bila ada bypass tenant/unit, IDOR lintas tenant, file privat terbuka, job lintas scope, atau akses data anak tanpa otorisasi. Temuan harus diperbaiki dan regression test ditambahkan.
