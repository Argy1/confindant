# Confindant Design Tokens (Inferred from Figma)

## Color Tokens
- `#000314` deep navy
- `#0A2472` royal blue
- `#0E6BA8` accent blue
- `#FFFFFF` white
- `#1E2939` primary text
- `#4A5565` secondary text
- `#6A7282` tertiary text
- `#D1D5DC` input border
- `#E5E7EB` divider/progress background
- `#A6E1FA` light blue panel
- `#EFF6FF` informational tip panel
- Income set: `#00A63E`, `#008236`, background `#F0FDF4`
- Expense set: `#E7000B`, `#C10007`, background `#FEF2F2`

## Gradient Tokens
1. App background: `#000314 -> #0A2472` (diagonal)
2. Primary button: `#000314 -> #0A2472` (horizontal)
3. Scan FAB: `#0A2472 -> #0E6BA8` (vertical)
4. Home income card: green-to-blue gradient
5. Home expense card: red-to-blue gradient

## Radius Scale
- `10`
- `14`
- `16`
- `20`
- `24`
- `30`
- `999` (pill/circle)

## Shadow Scale
- Soft card: `0 4 6` and `0 10 15` with low-opacity black
- Elevated auth card: `0 25 50` with medium-opacity black
- Onboarding icon circle: dual shadow style (`0 8 10` and `0 20 25`)

## Spacing Scale
- Base micro step around `4`
- Frequent spacing: `8, 12, 16, 20, 24, 32`
- Raw Figma decimals: `7.985`, `11.987`, `15.989`, `23.992`
- Implementation guidance: normalize to integer spacing while preserving visual rhythm

## Typography Roles
- Primary family: `Gill Sans MT`
- Secondary family: `Inter` (appears on some labels/meta)
- iOS status bar family: `SF Pro` (system usage)
- Sizes observed: `12, 13, 14, 16, 17, 18, 20, 24, 30, 32`
- Weights observed: regular, medium, bold
- Common line heights: `20, 22, 24, 28, 32, 36`

## Token Caveats
- `Gill Sans MT` font files are not provided by MCP export payload.
- Some visual values are inferred from frame/code metadata and must be visually validated in Flutter.

