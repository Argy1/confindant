# Release Checklist (Dev/Staging/Prod)

## Runtime Env
- Mobile `API_ENV` set (`dev|staging|prod`) or explicit `API_BASE_URL`.
- Backend `.env` configured for MongoDB and Sanctum.
- `php artisan storage:link` already executed for uploaded assets.

## Backend Readiness
- `php artisan test` green.
- Rate limit enabled on auth and scan-upload/scan-ocr endpoints.
- Rate limit enabled on AI inference endpoints (`/ai/*`) and OCR polling endpoint.
- Retention command available: `php artisan maintenance:cleanup`.
- Failed queue prune scheduled (`queue:prune-failed`).
- Queue worker running for OCR: `php artisan queue:work --queue=default --tries=3`.
- OCR queue health checked (`queue:failed` is empty or handled).
- Dashboard includes cashflow forecast payload and Analytics includes budget recommendations payload.

## Mobile Readiness
- `flutter analyze` and `flutter test` green.
- Auth bootstrap and token persistence verified.
- Camera/gallery flows verified (profile avatar + scan).
- OCR failure state shows actionable message and user can continue manual save.

## E2E Gate
- Register -> auto login -> wallet -> budget -> transaction.
- Scan upload and OCR review/commit both succeed.
- Home/Analytics/Profile data reflects backend updates.
- Home forecast card and Analytics recommendation card render with real backend payload.
- Logout/login again keeps server-side data intact.
