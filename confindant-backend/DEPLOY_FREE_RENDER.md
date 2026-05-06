# Deploy Gratis Confindant Backend (Render + MongoDB Atlas)

Dokumen ini khusus untuk backend `confindant-backend` agar bisa diakses semua device tanpa laptop lokal.

## 1) Prasyarat

- Repo backend sudah ada di GitHub.
- MongoDB Atlas sudah aktif.
- Database user sudah dibuat.

## 2) Format `MONGODB_URI` yang benar

Gunakan format ini:

```env
MONGODB_URI=mongodb+srv://<user>:<password>@cluster1.5qaminc.mongodb.net/?retryWrites=true&w=majority&appName=Cluster1
MONGODB_DATABASE=confindant
```

## 3) Buat Web Service di Render

1. Buka Render -> New -> Web Service.
2. Connect repo GitHub kamu.
3. Pilih root service ke folder backend (kalau monorepo, set `Root Directory` = `confindant-backend`).
4. Pilih runtime: `PHP`.

## 4) Isi Build & Start Command

Build Command:

```bash
composer install --no-dev --optimize-autoloader
php artisan config:clear
php artisan route:clear
php artisan view:clear
```

Start Command:

```bash
php artisan serve --host 0.0.0.0 --port $PORT
```

## 5) Environment Variables wajib (Render)

```env
APP_NAME=Confindant
APP_ENV=production
APP_DEBUG=false
APP_URL=https://<nama-service>.onrender.com
APP_KEY=<isi dari php artisan key:generate --show>

DB_CONNECTION=mongodb
MONGODB_URI=<atlas-uri>
MONGODB_DATABASE=confindant

SESSION_DRIVER=file
CACHE_STORE=file
QUEUE_CONNECTION=sync

FILESYSTEM_DISK=public
LOG_CHANNEL=stack
LOG_LEVEL=info
```

Jika OCR/AI dipakai:

```env
GEMINI_API_KEY=<gemini-key>
GEMINI_MODEL=gemini-2.5-flash
GEMINI_API_BASE=https://generativelanguage.googleapis.com/v1beta
GEMINI_TIMEOUT_SECONDS=45
```

## 6) Verifikasi setelah deploy

Tes endpoint health:

```text
GET https://<nama-service>.onrender.com/api/v1/health
```

Respons normal:

```json
{
  "success": true,
  "message": "Confindant backend is healthy",
  "data": {
    "status": "ok"
  }
}
```

## 7) Hubungkan mobile ke backend cloud

Di Flutter jalankan:

```bash
flutter run --dart-define=API_BASE_URL=https://<nama-service>.onrender.com/api
```

Atau build APK:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://<nama-service>.onrender.com/api
```

## 8) Catatan free-tier

- Service bisa cold start saat lama idle.
- Request pertama bisa lebih lambat.
- Ini normal untuk plan gratis.
