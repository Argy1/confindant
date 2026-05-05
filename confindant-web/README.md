# Confindant Web

Web companion for the Confindant personal finance app — built to mirror the
mobile app feature-for-feature, sharing the same Laravel backend.

**Stack:** Next.js 16 (App Router) · TypeScript · Tailwind CSS v4 ·
shadcn-style UI · TanStack Query · Zustand · Recharts · Zod + RHF · Sonner.

## Features

| Module          | Status | Notes                                              |
| --------------- | ------ | -------------------------------------------------- |
| Auth            | ✅      | Login, Register, session persistence, logout       |
| Home Dashboard  | ✅      | Balance, AI insight, quick actions, recent + budget |
| Transactions    | ✅      | List + filter + pagination + create/edit/delete    |
| Wallets         | ✅      | CRUD + transfer between wallets                    |
| Budgets         | ✅      | Per-category limits with alert threshold           |
| Goals           | ✅      | Targets, contributions, auto-topup                 |
| Recurring       | ✅      | Daily / weekly / monthly schedules                 |
| Scan (OCR)      | ✅      | Upload struk → poll OCR → commit transaksi         |
| Analytics       | ✅      | Recharts: daily, by-category pie, budget perf      |
| Notifications   | ✅      | List, mark-read, unread count badge                |
| Profile         | ✅      | Personal info, password, notification settings     |
| AI Finance Chat | ✅      | Natural-language Q&A backed by Gemini              |
| Help & Legal    | ✅      | FAQ, privacy, terms                                |

## Quick start

```bash
cp .env.example .env.local
# edit NEXT_PUBLIC_API_BASE_URL if your backend isn't on localhost:8000
npm install
npm run dev
# → http://localhost:3000
```

## Environment

| Var                        | Description                            | Example                                        |
| -------------------------- | -------------------------------------- | ---------------------------------------------- |
| `NEXT_PUBLIC_API_BASE_URL` | Confindant Laravel API base (with /v1) | `https://confindant-api.up.railway.app/api/v1` |

## Deploy to Vercel

1. Push this repo to GitHub.
2. Import on [vercel.com/new](https://vercel.com/new).
3. Set the **Root Directory** to `confindant-web`.
4. Add `NEXT_PUBLIC_API_BASE_URL` env var pointing to the production backend.
5. Hit **Deploy**.

Vercel auto-detects Next.js — no further config needed.

## Project layout

```
src/
  app/
    (auth)/       # login + register (no shell)
    (app)/        # authenticated routes (sidebar shell)
    page.tsx      # landing
  components/
    ui/           # shadcn-style primitives
    layout/       # sidebar, topbar, bottom-nav
    transactions/ wallets/   # feature dialogs
  lib/
    api/          # typed axios clients per module
    types.ts      # backend DTOs
    utils.ts      # cn, formatCurrency, etc.
  store/
    auth.ts       # zustand auth store (persisted)
```

## Responsive design

- **Mobile (<lg)**: hamburger menu + bottom nav with 5 items (Home, Tx, Scan
  FAB, Analytics, Profile). Safe-area inset friendly.
- **Tablet/Desktop (≥lg)**: persistent sidebar, full-width topbar, hover
  states, multi-column dashboards.
- All forms use full-width inputs on mobile and 2-column grids ≥sm.
