# Confindant Route Map

## Primary Routes
1. `/splash`
2. `/onboarding/1`
3. `/onboarding/2`
4. `/onboarding/3`
5. `/onboarding/4`
6. `/login`
7. `/register`
8. `/home`
9. `/analytics`
10. `/wallet`
11. `/profile`
12. `/scan`
13. `/scan-receipt`
14. `/add-wallet` (modal)
15. `/manage-category` (modal, empty-state)
16. `/manage-category-2` (modal, populated-state)

## Inferred Flow
1. `Splash -> Onboarding 1`
2. `Onboarding 1 -> Onboarding 2 -> Onboarding 3 -> Onboarding 4`
3. `Onboarding 1/2/3 Skip -> Login`
4. `Onboarding 4 Get Started -> Login`
5. `Login <-> Register`
6. `Login/Register success -> Home`
7. Bottom navigation switches among `Home | Analytics | Wallet | Profile`
8. Center scan action from shell routes opens `Scan`
9. `Scan` upload/confirm goes to `Scan Receipt`
10. `Wallet -> Add Wallet` modal
11. `Wallet -> Manage Category` modal
12. `Manage Category` may transition to `Manage Category-2` when limits exist

## Routing Constraints
- `Add Wallet`, `Manage Category`, and `Manage Category-2` are modal overlays initiated from `Wallet`.
- Bottom navigation is global only for `Home`, `Analytics`, `Wallet`, and `Profile`.
- `Scan` is launched from center FAB/action and is outside the persistent tab set.

## Limitations
- Prototype connector metadata is not exposed in MCP responses.
- Transition edges are inferred from visible controls, labels, and frame intent.

