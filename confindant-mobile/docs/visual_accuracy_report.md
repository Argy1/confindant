# Visual Accuracy Report - Confindant (Refinement Pass)

## Scope
- Audited implemented screens against Figma nodes provided in the project brief.
- Focused on spacing, card sizing, hierarchy, radii, shadows, icon sizing, gradient feel, safe areas, and shell proportions.
- Kept routing and business logic unchanged.

## Corrected In This Pass
- `SplashPage`
  - Removed non-Figma branding content.
  - Matched Figma splash behavior as a pure gradient surface.

- `AppBottomNavBar`
  - Tightened bar height and positioning to closer Figma proportions.
  - Increased nav icon/text scale toward Figma visual weight.
  - Adjusted scan FAB vertical lift and bar corner radius behavior.

- `HomePage`
  - Tightened balance card typography hierarchy (`Your Balance`, main amount, metric cards).
  - Corrected spacing around eye toggle and amount row.
  - Tuned card inner padding and vertical rhythm closer to Figma frame.

- `AnalyticsPage`
  - Removed non-Figma invented chart/cards from this frame.
  - Matched Figma frame intent: top greeting + notification only on gradient background.

- `WalletPage`
  - Rebuilt to Figma structure:
  - Header row (avatar, greeting, notification).
  - Main white wallet card with wallet identity, balance, income/expense pills, category-limit action, and active-limit progress.
  - Separate add-wallet CTA card below.

- `AddWalletPage`
  - Simplified to Figma modal form shape and field set.
  - Removed non-Figma extra fields.
  - Matched title row, wallet name input, color dots, and single primary CTA.

- `ManageCategoryPage`
  - Rebuilt as empty-state modal variant:
  - Category Spending Limits title + subtitle.
  - Add New Limit card with category/limit inputs and plus action.
  - Empty-state message and save CTA.

- `ManageCategoryAltPage`
  - Rebuilt as populated-state modal variant:
  - Same add-limit card as above.
  - Current Limits section with removable row.
  - Save CTA kept in Figma visual language.

- `Category shared UI`
  - Standardized modal shell geometry, header hierarchy, and form card visuals.
  - Added reusable light input and limit form card for both category screens.

- `ProfilePage`
  - Tightened global top spacing and section spacing.
  - Updated logout visual emphasis toward Figma (blue accent instead of red danger style).
  - Adjusted footer copyright wording and opacity treatment.

- `ScanPage`
  - Reworked to black camera-placeholder surface per Figma.
  - Implemented corner frame composition and bottom frosted control panel.
  - Matched upload CTA row layout and tip card styling.

- `ScanReceiptPage`
  - Rebuilt visual flow to Figma layout:
  - Top receipt preview card + close control.
  - White details card with two-column form rows.
  - Receipt item cards, total summary bar, and cancel/save actions.

## Still Different (Known Gaps)
- Typography fidelity is not exact on all devices.
  - Figma uses `Gill Sans MT` heavily.
  - Runtime fallback may occur where the font is unavailable or not bundled.

- Some iconography still uses Material fallback in edge placeholders.
  - This is only used when specific SVG composition is unavailable at runtime.
  - Core custom icons are wired to local exported assets where available.

- iOS status-bar glyph composition is not fully hard-mirrored from Figma on every screen.
  - Current implementation relies on native SafeArea and platform status rendering for stability.

- Analytics frame content is intentionally minimal.
  - The referenced Figma analytics frame is mostly header + shell state.
  - Previously added generic charts were removed to avoid non-Figma invention.

## Differences Caused by Missing Font/Assets/Permissions
- `Gill Sans MT` is referenced by design but not fully guaranteed as bundled licensed asset in this repo.
  - Result: fallback typography can cause minor line-height and glyph-width drift.

- Temporary Figma export URLs were not used as runtime dependencies.
  - All production references remain local assets.
  - Any non-exported/missing vectors are represented with safe local/icon fallback.

## Verification
- `flutter analyze` completed successfully with no issues after refinement.
