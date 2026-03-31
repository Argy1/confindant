# Confindant Figma Asset Manifest

## Status Legend
- `available-temp-url`: MCP returned temporary asset URL (expires)
- `blocked-or-not-exposed`: URL not exposed in current MCP payload
- `none`: no external asset required

## Asset Inventory by Screen
1. Splash
- Assets: none
- Status: `none`

2. Onboarding 1
- Assets: wallet illustration vectors, chevron-right icon
- Status: `available-temp-url`

3. Onboarding 2
- Assets: trend illustration vectors, chevron-right icon
- Status: `available-temp-url`

4. Onboarding 3
- Assets: budget/pie illustration vectors, chevron-right icon
- Status: `available-temp-url`

5. Onboarding 4
- Assets: shield illustration vector, chevron-right icon
- Status: `available-temp-url`

6. Login
- Assets: wallet logo icon, mail icon, lock icon, eye icon vectors
- Status: `available-temp-url`

7. Register
- Assets: wallet logo icon, user icon, mail icon, lock icon, eye icon vectors
- Status: `available-temp-url`

8. Home
- Assets: avatar image, notification icon, eye icon, nav icons, trending icons, status bar glyphs
- Status: `available-temp-url`

9. Analytics
- Assets: avatar image, notification icon, nav icons, status bar glyphs
- Status: `available-temp-url`

10. Wallet
- Assets: avatar image, notification icon, wallet icon, target icon, plus icon, nav icons, status bar glyphs
- Status: `available-temp-url`

11. Profile
- Assets: avatar/profile image, edit/mail/row icons, logout icon, nav icons, status bar glyphs
- Status: `available-temp-url`

12. Scan
- Assets: back icon, upload icon, flash icon, scan-corner vectors, status bar glyphs
- Status: `available-temp-url`

13. Scan Receipt
- Assets: receipt image, close icon, calendar icon, plus/trash/check icons, status bar glyphs
- Status: `available-temp-url`

14. Add Wallet
- Assets: close (`X`) icon vectors
- Status: `available-temp-url`

15. Manage Category
- Assets: close icon, plus icon, check icon
- Status: `available-temp-url`

16. Manage Category-2
- Assets: close icon, plus icon, trash icon, check icon
- Status: `available-temp-url`

## Asset Handling Decisions
1. Download all `available-temp-url` assets to local project folders:
- `assets/images/`
- `assets/icons/`

2. Replace temporary URL references with stable local asset references.

3. Use semantic naming by screen + role (example: `wallet_manage_limits_icon.svg`), not node-id naming.

4. If any asset URL expires before download:
- mark as `blocked-or-not-exposed`
- include usage location (screen + component)
- add retry step in asset retrieval log

## Current Blockers
1. Figma asset URLs are temporary and expire.
2. Some icons are split into multiple vector fragments and need manual packaging.
3. Font files (notably `Gill Sans MT`) are not provided through current MCP asset export.

