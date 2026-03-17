# Unila Helpdesk Frontend (Flutter)

Frontend Flutter untuk aplikasi helpdesk Unila.

## Prasyarat

- Flutter SDK 3.24+ (disarankan gunakan versi terbaru yang kompatibel)
- Dart SDK sesuai versi Flutter
- Backend API aktif (lokal atau staging)

## Struktur Konfigurasi Environment

Project menggunakan dua sumber konfigurasi runtime:

1. `assets/config/runtime.env` untuk default build/deploy
2. `.env` untuk override lokal saat mode debug

Prioritas pembacaan nilai:

1. `--dart-define` (paling tinggi)
2. `.env` (debug lokal)
3. `assets/config/runtime.env`

## Setup Cepat

1. Install dependency:

```bash
flutter pub get
```

2. Salin file env contoh:

Windows (PowerShell):

```powershell
Copy-Item .env.example .env
```

Linux/macOS:

```bash
cp .env.example .env
```

3. Isi minimal nilai `.env`:

- `ENVIRONMENT=development|staging|production`
- `API_BASE_URL=http://localhost:8080` (opsional, untuk override manual)
- Variabel Firebase web sesuai project jika menjalankan web push notification

## Menjalankan Aplikasi

### Local backend (disarankan untuk development)

```bash
flutter run --dart-define=ENVIRONMENT=development --dart-define=API_BASE_URL=http://localhost:8080
```

### Staging

```bash
flutter run --dart-define=ENVIRONMENT=staging
```

### Production-like

```bash
flutter run --dart-define=ENVIRONMENT=production
```

Catatan:

- Jika memakai HP fisik, `localhost` mengarah ke perangkat, bukan laptop. Gunakan IP LAN komputer, contoh `http://192.168.1.10:8080`.
- Jika `API_BASE_URL` tidak di-set, aplikasi fallback ke URL berdasarkan `ENVIRONMENT`.

## Integrasi dengan Backend Lokal

1. Jalankan backend di `http://localhost:8080`.
2. Jalankan frontend dengan `ENVIRONMENT=development`.
3. Jika dari perangkat fisik, ganti `API_BASE_URL` ke IP LAN mesin backend.

## Quality Checks

Jalankan analisis static:

```bash
flutter analyze
```

Jalankan test:

```bash
flutter test
```

## Build

Contoh build web:

```bash
flutter build web --dart-define=ENVIRONMENT=production
```

## Troubleshooting Singkat

- Error `ENVIRONMENT belum di-set`: isi `.env` atau kirim `--dart-define=ENVIRONMENT=...`.
- Error server tidak bisa diakses: pastikan backend aktif, URL benar, dan port `8080` terbuka.
- Push notification web tidak aktif: cek variabel Firebase web dan VAPID key di environment.
