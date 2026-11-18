# Arsitektur Sistem SINAU

**Status:** Modular monolith adalah proposed baseline. Model tenant diterima; shared database/shared schema adalah baseline MVP yang masih menunggu PoC engine. Stack final belum dikunci.

## Arah arsitektur

SINAU dimulai sebagai **modular monolith**: satu aplikasi yang dapat dirilis dan dioperasikan sebagai satu unit, dengan batas domain, kontrak, dan tanggung jawab modul yang jelas.

Alasan:
- Mengurangi kompleksitas operasional pada tahap awal.
- Memungkinkan transaksi lintas domain yang terkontrol.
- Memudahkan tim kecil menjaga konsistensi.
- Memberi jalur ekstraksi layanan jika kebutuhan skala dan batas domain sudah terbukti.

## Lapisan konseptual

- Presentation: web UI dan API.
- Application: use cases, workflow, command/query.
- Domain: aturan bisnis dan model domain.
- Infrastructure: database, queue, storage, email, integrasi eksternal.
- Shared platform: identity, tenant context, unit context, authorization, audit, observability.

Context tenant/unit adalah layanan platform bersama, bukan implementasi berbeda di setiap modul. Modul domain tidak boleh menentukan tenant dari input client.

## Batas modul

Setiap modul memiliki:
- Tanggung jawab dan ruang lingkup.
- Model data yang dimiliki.
- Use cases/services dan kontrak.
- Kebijakan otorisasi.
- Event/integrasi yang didukung.
- Pengujian dan dokumentasi.

Modul tidak boleh mengakses tabel privat modul lain secara bebas. Gunakan kontrak aplikasi/domain yang jelas.

## Baseline multi-tenant

- Satu tenant adalah satu pelanggan SaaS, bertipe foundation atau independent_provider.
- Tenant dapat memiliki satu atau banyak education unit.
- Tenant adalah batas billing/kontrak; unit adalah batas operasional pendidikan.
- Baseline MVP: shared database/shared schema dengan tenant_id dan unit_id, scoped access, serta composite constraints.
- Tenant resolver harus memiliki abstraksi agar tenant dapat dipindahkan ke database/shard lain kelak tanpa mengubah domain.
- Tenant membership dan unit membership terpisah; tenant membership bukan grant otomatis untuk semua data unit.
- Database Row-Level Security dapat dievaluasi sesuai engine, tetapi bukan pengganti authorization aplikasi dan constraint.

## Alur request dan context

1. Authentication mengidentifikasi user.
2. Tenant resolver memuat tenant membership aktif dan memilih context sah.
3. Unit resolver memvalidasi unit berada di tenant aktif dan user memiliki grant.
4. Authorization memeriksa permission dan relasi domain pada resource yang diminta.
5. Repository/query membatasi scope dan database constraints menjaga integritas.
6. Audit mencatat tindakan sensitif dan scope.
7. Queue/file/cache/export meneruskan scope tervalidasi.

Context hilang, dicabut, stale, atau tidak konsisten harus gagal tertutup.

## Integrasi

- Integrasi eksternal melalui adapter/gateway.
- Webhook diverifikasi, idempotent, dan memiliki pencatatan.
- Job membawa tenant, unit bila relevan, actor/system identity, dan correlation context tervalidasi.
- Worker memvalidasi ulang membership/ownership sebelum menjalankan operasi.
- Kegagalan integrasi tidak boleh menyebabkan status bisnis seolah berhasil.
- Retry harus aman dan dibatasi.

## Keputusan yang masih terbuka

Framework/backend, frontend, database engine, cache/queue, object storage, search, observability, hosting, dan deployment harus dinilai dan disahkan melalui ADR sebelum implementasi dasar dimulai.
