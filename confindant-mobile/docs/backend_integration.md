# Backend Integration Notes

## Mobile (Flutter)
Single source runtime config:
- `API_ENV` => `dev | staging | prod`
- `API_BASE_URL` (optional override, highest priority)

### Default base URL per `API_ENV`
- `dev` -> `http://10.0.2.2:8000/api`
- `staging` -> `https://staging-api.confindant.app/api`
- `prod` -> `https://api.confindant.app/api`

Run app with explicit backend base URL:

```bash
flutter run --dart-define=API_BASE_URL=http://<YOUR_HOST>:8000/api
```

Run app by environment:

```bash
flutter run --dart-define=API_ENV=dev
flutter run --dart-define=API_ENV=staging
flutter run --dart-define=API_ENV=prod
```

### Platform URL matrix (local backend)
- Android emulator -> `http://10.0.2.2:8000/api`
- Android real device (same WiFi) -> `http://<LAN_IP_PC>:8000/api`
- iOS simulator -> `http://127.0.0.1:8000/api`
- Web/Windows/macOS -> `http://127.0.0.1:8000/api`

## Backend (Laravel + MongoDB)
1. Ensure `.env` exists (`.env.example` already set to MongoDB defaults).
2. Set:
- `DB_CONNECTION=mongodb`
- `MONGODB_URI=mongodb://127.0.0.1:27017`
- `MONGODB_DATABASE=confindant`
- `QUEUE_CONNECTION=database`
- `DB_QUEUE_CONNECTION=sqlite`
- `DB_FAILED_JOBS_CONNECTION=sqlite`
- `NOTIFICATION_RETENTION_DAYS=180`
- `OCR_JOB_RETENTION_DAYS=60`
- `AI_FEEDBACK_RETENTION_DAYS=365`
- `FAILED_JOB_RETENTION_HOURS=168`
3. Generate app key if needed:

```bash
php artisan key:generate
```

4. Run backend:

```bash
php artisan serve
```

5. Ensure queue tables exist on sqlite:

```bash
# create sqlite file if needed
type nul > database/database.sqlite

# migrate queue tables to sqlite connection
php artisan migrate --database=sqlite
```

6. Run OCR queue worker:

```bash
php artisan queue:work --queue=default --tries=3
```

### Backend env matrix
- `APP_ENV=local`:
  - `APP_DEBUG=true`
  - `QUEUE_CONNECTION=database`
  - worker command manual.
- `APP_ENV=staging`:
  - `APP_DEBUG=false`
  - `QUEUE_CONNECTION=database`
  - worker managed by supervisor/systemd.
- `APP_ENV=production`:
  - `APP_DEBUG=false`
  - `QUEUE_CONNECTION=database`
  - worker managed by supervisor/systemd + restart policy.

### OCR queue runbook
- Check pending/failed jobs:
  - `php artisan queue:failed`
- Retry failed OCR jobs:
  - `php artisan queue:retry all`
- Flush failed jobs (careful):
  - `php artisan queue:flush`
- Cleanup operational data manually:
  - `php artisan maintenance:cleanup`
- Dry check schedule list:
  - `php artisan schedule:list`

## Implemented API
- Auth: `/api/v1/register`, `/login`, `/user`, `/logout`
- Wallet/Budget/Transaction CRUD
- Wallet transfer: `POST /api/v1/wallets/transfer`
- Scan upload: `/api/v1/transactions/scan-upload`
- OCR v1: `/api/v1/transactions/scan-ocr`, `/scan-ocr/{id}`, `/scan-ocr/{id}/commit`
- Dashboard: `/api/v1/dashboard`
- Analytics: `/api/v1/analytics`
- Goals + contributions
- Habits + increment/reset
- Profile + avatar + change password + notification settings
- Legal/support: `/api/v1/legal/privacy`, `/legal/terms`, `/support/channels`
- Notifications list/create/mark-read
- Budget alert auto-notification (70% / 90%) generated on expense updates
- Recurring transaction CRUD: `/api/v1/recurring-transactions`
- Recurring processor command: `php artisan recurring:process`
- AI forecast: `/api/v1/ai/cashflow-forecast`
- AI budget recommendation: `/api/v1/ai/budget-recommendations`
