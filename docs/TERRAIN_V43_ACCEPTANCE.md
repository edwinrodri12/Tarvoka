# Terrain V43 — review candidate, not approved

## Review evidence

The existing four-biome GPU workflow now requires 30 comparison files: nine fixed-layout images, nine geographic maps (24×18, seed 1729), nine close-orbit detail images, and three weather frames. It also produces the original delta screenshot and logs of terrain chunk-build time and cached height counts. Desktop OpenGL is a visual regression proxy, not an Android benchmark.

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

## V44 art finish candidate

Nine cached 64×64 grayscale microtextures with mipmaps preserve biome vertex colors. Conifer trunks and foliage skirts are closed; coastal and desert scrub use the broadleaf silhouette. Rock undersides are capped and use the rock texture. Small natural patches remain inside visible plain cells and away from their centers. The same existing terrain and vegetation batches are used, but mesh triangle counts have increased and must be measured on physical devices. Review all nine close-orbit captures before accepting art quality. No claim of completed or approved individual biomes without rendered evidence.

## V45–V47 relief and vegetation refinement

- Dunes: two curved low relief strips per visible desert plain, away from the tile center; original height sampler and unit positions unchanged. 32 triangles per decorated tile (previous three subdivided stripes used 24).
- Ridges: 20 triangles per shared closed mountain mesh (previously 8); silhouette heights vary by biome. Verify steep-slope grounding and unit visibility at close orbit.
- Vegetation: palm fronds are closed creased volumes; reed seed heads are capped. Existing vegetation instance counts and materials remain; foliage geometry increases.
- Shores: paired narrow material bands; sparse foam segments on visible coastal/archipelago water only beside currently visible land. No water displacement or new navigation routes.
- Added regression assertions for bounds, mesh counts, public visibility and flat-surface alignment. These tests must run under Godot before acceptance.

## Next structural work (not implemented)

V48 elevated bridges need explicit public crossing metadata and two-domain occupancy/routing semantics, plus tests for ground and naval movement, attack, AI, supply, fog, save and bridge picking. Do not render a navigable opening while the authoritative map still treats the tile as solid road. Start with an opt-in scenario and preserve previous versioned maps. V49 mixed biomes need versioned per-cell region metadata, deterministic transitions, same preview/save contract and fog-safe rendering. Keep the nine single-biome options unchanged. Do not merge these larger rule changes into the art candidate before baseline validation.
