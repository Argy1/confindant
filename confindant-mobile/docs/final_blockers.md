# Final Blockers - Confindant

## Compile and Runtime Status
- `flutter analyze`: pass (0 issues)
- `flutter test`: pass
- Route table resolves all primary screens listed in scope.

## Remaining blockers for full visual parity
1. Exact Figma fonts are not bundled as project assets.
- Impact: text metrics (letter width/line-break/weight rendering) can differ from Figma.
- Current state: theme references `Gill Sans MT` and `Inter`, but `pubspec.yaml` has no bundled font files.
- Why blocked: font files were not exported/provided via Figma MCP and may require separate licensing/source packaging.

2. Some UI icons still use Material built-ins on active screens where Figma uses custom vectors.
- Impact: shape/weight can differ slightly from Figma.
- Current examples (active code paths): auth input icons, notification icons, several action icons (add/check/delete/visibility).
- Why blocked: equivalent custom vectors are not consistently mapped for every usage yet.

3. Figma prototype interaction metadata is not fully represented in code-level routing semantics.
- Impact: edge-case transitions may differ from prototype micro-flow.
- Current state: primary routes and navigation are implemented and open correctly.
- Why blocked: prototype connector behavior detail is not fully available in source payload for deterministic mapping.

## Notes
- No blockers remain for compilation or navigation startup.
- Blockers above are parity-focused only, not build-breaking.
