# Confindant Figma Implementation Plan (Flutter)

## Summary
- Figma frame links and canvas structure have been inspected.
- Screen order and route map are inferred from frame controls and intended UX flow.
- Shared design patterns and token candidates are defined for Flutter implementation.
- Asset export availability is documented separately in `docs/figma_asset_manifest.md`.

## Shared Design Patterns

### Global
- Target mobile layout around `402 x 874`
- Main app screens use dark blue diagonal gradient background
- Auth screens use centered white card over gradient background
- Glass/translucent effects appear in bottom navigation and small utility chips

### Reusable Component Inventory
1. `AppGradientBackground`
2. `AuthCardContainer` (24 radius, elevated shadow)
3. `TopBarUserGreeting` (avatar + greeting + notification action)
4. `PrimaryGradientButton` (deep navy -> royal blue)
5. `SecondaryWhiteButton`
6. `SoftTranslucentButton` (onboarding skip)
7. `OutlinedInputField` (optional leading/trailing icon)
8. `BottomNavGlassBar` (with center floating scan action)
9. `SummaryCard` (balance + income/expense highlights)
10. `SectionCard` (blue strip header + list rows)
11. `ModalCardSheet` (Add Wallet / Manage Category variants)
12. `ReceiptItemCard` (item editor block in Scan Receipt)

## Pattern-Level Styling Rules

### Backgrounds
- Gradient from near-black navy to royal blue
- Consistent full-screen gradient treatment for auth/main

### Cards
- White surfaces
- Frequent radii: 16/20/24
- Soft shadow elevation, stronger on auth card

### Text Fields
- Light gray border (`#D1D5DC`)
- Radius 10 or 14 depending context
- Label style around 14
- Value/hint around 16

### Buttons
- Dominant radius: 14
- Primary action uses navy-blue gradient
- Secondary variants in white or muted gray

### Bottom Navigation
- Frosted/glass background
- Top radius around 25
- Center scan action: circular, gradient fill, white border

### Section Headers
- Blue strip with white semibold text

### Icon Usage
- Mostly outline/line iconography
- Some filled variants for active state
- Several icons provided as vector groups instead of single packed files

## Blockers and Explicit Limitations
1. Prototype transition connector metadata is not exposed through current MCP response.
2. Route transitions are inferred from labels and visible controls.
3. Asset URLs from MCP are temporary and must be localized.
4. Font assets (`Gill Sans MT`) are not included in MCP exports.
5. Some icon exports are decomposed vectors requiring manual assembly/packaging.

## Assumptions and Defaults
1. Entry sequence is onboarding/auth-first before tab shell.
2. `Add Wallet` and `Manage Category` are modal overlays from `Wallet`.
3. `Manage Category-2` is the populated-state variant of `Manage Category`.
4. Bottom navigation is scoped to `Home`, `Analytics`, `Wallet`, `Profile`; `Scan` is launched separately.

