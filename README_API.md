# Confindant Backend API Notes

## Environment
Use `.env.example` as base. MongoDB defaults are preconfigured:
- `DB_CONNECTION=mongodb`
- `MONGODB_URI=mongodb://127.0.0.1:27017`
- `MONGODB_DATABASE=confindant`

Generate app key:

```bash
php artisan key:generate
```

## API Prefix
All APIs are under:

`/api/v1`

## Main Endpoints
- Auth: `register`, `login`, `user`, `logout`
- `wallets` (CRUD)
- `budgets` (CRUD)
- `transactions` (CRUD)
- `transactions/scan-upload`
- `dashboard`
- `analytics`
- `goals`, `goals/{id}/contributions`
- `habits`, `habits/{id}/increment`, `habits/{id}/reset`
- `profile`, `profile/notification-settings`
- `notifications`, `notifications/{id}/mark-read`

## Response Contract
Success:

```json
{
  "success": true,
  "message": "...",
  "data": {},
  "meta": {}
}
```

Error:

```json
{
  "success": false,
  "message": "...",
  "data": null,
  "errors": {}
}
```
