# E2E Smoke Checklist

## Pre-check
- Backend running (`php artisan serve`)
- MongoDB running
- Mobile run with valid API base URL

## Scenario
1. Register new account.
   - Expected: redirect to Home, token persisted.
2. Kill app and reopen.
   - Expected: auto-login from saved token.
3. Add wallet from Wallet page.
   - Expected: wallet list and balance card update.
4. Add budget/category limit.
   - Expected: limit appears in Wallet and affects Home/Analytics budget sections.
5. Create quick expense from Home.
   - Expected: recent transaction appears and analytics total expense updates.
6. Create quick income from Home.
   - Expected: summary balance/income updates.
7. Save receipt from Scan Receipt page.
   - Expected: backend stores transaction with items and (optional) receipt image URL.
8. Open Analytics page (weekly/monthly toggle).
   - Expected: summary, breakdown, trend, budget progress loaded.
9. Logout from Profile.
   - Expected: token revoked and app returns to Login.
10. Login again.
    - Expected: previous data still visible for that user.

## Contract mismatch checkpoints
- `id` and `_id` mapping: response should expose string `id` for all records.
- `date` field: ISO format accepted and returned consistently.
- `items` payload: must remain array for transaction and scan upload.
