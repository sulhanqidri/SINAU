# Test Plan: Tenant dan Unit Isolation

**Tujuan:** membuktikan user hanya dapat mengakses data sesuai tenant membership, unit membership, permission, dan relasi domain.

## Fixture minimum
- Tenant A: foundation dengan Unit A1 (sekolah umum) dan Unit A2 (madrasah).
- Tenant B: independent_provider dengan Unit B1.
- User platform support, tenant admin A, operator A1, operator A2, user tenant B, guru, wali, dan siswa.
- Buat record siswa, enrollment, kelas, presensi, nilai, file, dan export dengan ID yang diketahui test.

Gunakan identifier yang sengaja mudah dipetakan pada fixture test agar percobaan IDOR dapat direproduksi. Data harus sintetis, bukan data anak nyata.

## Matriks pengujian

| Area | Skenario positif | Skenario negatif wajib |
|---|---|---|
| Onboarding | Foundation punya banyak unit; mandiri tanpa yayasan | Mandiri dipaksa memiliki parent foundation |
| Tenant context | User memilih tenant dari membership aktif | Mengirim tenant_id tenant lain |
| Unit context | User A1 membuka Unit A1 | User A1 membuka Unit A2 tanpa grant |
| Cross-tenant | User B mengakses B1 | User A membuka B1 dan sebaliknya |
| CRUD | CRUD resource dalam scope sah | Read/update/delete resource tenant lain |
| Bulk | Bulk action hanya pada ID dalam scope | Campuran ID sah dan ID tenant lain |
| Search/filter | Hasil hanya dari scope aktif | Filter/include mengungkap data tenant lain |
| Membership | Akses berlaku saat membership aktif | Akses setelah membership dicabut |
| Role | Permission sesuai scope | Role unit dipakai untuk aksi platform/tenant |
| Guardian/student | Wali melihat siswa terverifikasi | Wali menebak ID siswa lain |
| File | Download setelah authorization | URL/key file tenant lain atau expired |
| Export/import | Proses terikat tenant/unit | Export/import memproses record lintas scope |
| Cache/search | Key dan hasil terisolasi | Collision ID antar tenant |
| Queue/scheduler | Job memproses scope payload tervalidasi | Context kosong, stale, atau mismatch |
| Audit | Penolakan dan aksi sensitif tercatat | Secret/PII berlebihan masuk log |
| Database | FK menjaga relasi dalam scope | Insert relasi silang tenant/unit ditolak |

## Lapisan pengujian
1. Unit test untuk TenantContext, UnitContext, membership resolver, dan policy.
2. Feature/API test untuk setiap endpoint list/detail/create/update/delete/bulk.
3. Database integration test untuk composite unique/FK dan transaksi.
4. Worker test untuk job, retry, scheduler, dan idempotency.
5. Storage/cache test untuk object authorization dan key namespace.
6. Security test untuk IDOR, mass assignment, context tampering, session revocation.
7. Regression test setiap kali ada temuan.

## Aturan hasil
- Akses tidak sah harus ditolak konsisten (404 atau 403 sesuai kebijakan disclosure); tidak membocorkan keberadaan resource.
- Tidak boleh ada side effect ketika authorization gagal.
- Tes harus memverifikasi response, perubahan database, file, cache, audit, dan job.
- Semua tes isolasi wajib lulus pada CI sebelum fitur tenant-scoped dapat dirilis.
- Jalankan juga pada database engine yang dipilih, bukan hanya SQLite in-memory, karena perilaku FK/constraint dapat berbeda.

## Exit criteria sebelum fitur akademik
- Semua skenario cross-tenant dan cross-unit wajib lulus.
- Composite FK/constraint telah dibuktikan pada engine database target.
- Tenant context tidak dapat dipalsukan dari client.
- Job/file/cache/export terbukti scope-safe.
- Test suite dapat dijalankan ulang secara deterministik.
