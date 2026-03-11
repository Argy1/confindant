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
3. Generate app key if needed:

```bash
php artisan key:generate
```

4. Run backend:

```bash
php artisan serve
```

## Implemented API
- Auth: `/api/v1/register`, `/login`, `/user`, `/logout`
- Wallet/Budget/Transaction CRUD
- Scan upload: `/api/v1/transactions/scan-upload`
- Dashboard: `/api/v1/dashboard`
- Analytics: `/api/v1/analytics`
- Goals + contributions
- Habits + increment/reset
- Profile + notification settings
- Notifications list/create/mark-read
