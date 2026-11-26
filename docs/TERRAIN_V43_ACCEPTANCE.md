# Terrain V43 — review candidate, not approved

## Review evidence

The existing four-biome GPU workflow now requires 21 comparison files: nine fixed-layout images, nine geographic maps (24×18, seed 1729), and three weather frames. It also produces the original delta screenshot and logs of terrain chunk-build time and cached height counts. Desktop OpenGL is a visual regression proxy, not an Android benchmark.

## Acceptance gates

- All Godot import, gameplay rules, save compatibility and GPU tests pass on the exact candidate commit.
- Inspect all nine fixed and geographic screenshots for terrain gaps, building foundations, road/shore continuity, vegetation scale, and legibility of units and faction colors.
- Inspect rain, snow and decorative desert dust frames; ensure tactical orders remain readable and touch passes through.
- Confirm the shared material water motion and weather stop in battery saver, and shadows recover after leaving it.
- On a physical Android device, test 10×8, 24×18 and 40×30 maps (including urban roads, wetland and archipelago), with fog, modern units, zoom, rotation and transitions between turns. Record device model, resolution, FPS, memory and terrain build time; no FPS claims until measured. Aim for stable 30 FPS or better on the target device, subject to device tier.
- Review the nine biomes with the project owner. Do not label the art approved before this review.
- Reconcile the branch with current main without overwriting parallel unit art. Publish the approved candidate to the actual game and shared viewer only after validation.

## Scope limits

Geographic scenarios preserve strategic building anchors and symmetric land corridors. They do not dynamically relocate cities. Crossings have parapets but are not elevated naval passages. Water animation is texture motion, and desert dust is cosmetic; weather rules remain clear/rain/snow. Mixed-biome geography and additional weather mechanics are not implemented. The public studio and Android release are not updated by this draft.
