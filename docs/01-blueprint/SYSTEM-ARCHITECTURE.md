# Arsitektur Sistem SINAU

**Status:** Proposed baseline; belum menjadi keputusan stack final.

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
- Shared platform: tenant context, identity, authorization, audit, observability.

Hindari menaruh aturan inti di controller, view, atau komponen frontend.

## Batas modul

Setiap modul memiliki:
- Tanggung jawab dan ruang lingkup.
- Model data yang dimiliki.
- Use cases/services dan kontrak.
- Kebijakan otorisasi.
- Event/integrasi yang didukung.
- Pengujian dan dokumentasi.

Modul tidak boleh mengakses tabel privat modul lain secara bebas. Gunakan kontrak aplikasi/domain yang jelas.

## Integrasi

- Integrasi eksternal melalui adapter/gateway.
- Webhook diverifikasi, idempotent, dan memiliki pencatatan.
- Job membawa tenant dan correlation context yang tervalidasi.
- Kegagalan integrasi tidak boleh menyebabkan status bisnis seolah berhasil.
- Retry harus aman dan dibatasi.

## Keputusan yang masih terbuka

Framework/backend, frontend, database, cache/queue, object storage, search, observability, hosting, dan deployment harus dinilai dan disahkan melalui ADR sebelum implementasi dasar dimulai.
