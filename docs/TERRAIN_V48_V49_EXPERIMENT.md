# V48–V49 — experimental branch, not playable integration

Parent is V47 art candidate, PR #710. V48.1–V48.3 adds explicit opt-in branches to BattleSession, MoveActions, SaveCodec and BasicAI; ordinary scenarios never enable them. Do not merge either branch on the strength of unexecuted tests.

## V48 crossings
The reference graph accepts canonical road-cell records (integer x/y and ew/ns deck direction). On a bridge, the naval channel is perpendicular to the deck; aircraft remain independent. Occupancy keys allow one ground, one naval and one air unit on a crossing, with ordinary surface occupancy elsewhere. Ground and naval routes use the existing entry-cost/weather rules. The independent art model has a closed elevated deck, parapets and a clear opening; V48.4 now has static ramps and read-only visual integration; unit animation is still pending.

Initial integration now validates versioned metadata, normalizes JSON integer fields, routes real Session.move through layered occupancy, preserves movement and fuel bookkeeping, round-trips layered saves and uses a restricted AI planner. Sandbox sessions explicitly reject fog, economy, relays and seeded maps. Legacy UI load/resume rejects these saves until bridge picking and rendering are integrated. Combat keeps existing domain and range rules, including no same-cell attack. Remaining: strategic sites, supply routes, production, fog bridge knowledge, layered combat design, height-aware picking, actual movement animation and live interface integration. Keep legacy scenarios and saves identical. Ship model clearance and bridge approaches must be checked with actual units. The experimental graph must not be used for authoritative gameplay before parity and migration tests.

## V49 regions
Version 1 has two distinct selected biomes, mirrored north/south regions and a seeded two-row transition. Integer blend weights 0–1000, derived from seed and dimensions. Public projections only contain observed cells. This is a region field, not a new generated terrain or rendering integration. Next route the same versioned geography through preview and game, mix terrain/vegetation/shore materials consistently across sectors, preserve fog and saves, and verify independent region access. Existing single-biome maps remain unchanged.

## QA
Targeted test contains bridge movement and occupancy cases, model bounds, and 216 ordered biome-pair/map-size combinations. No measured performance or rendered visual approval yet.

## V48.3 / V49.1 additions

Public layer-selection records distinguish ground, naval and air IDs at an observed cell, without selecting by array order. The normal touch interface does not consume these records yet. MixedBiomePreviewV49 generates a CPU image with blended region pigments and masks unknown cells; altering hidden terrain does not change the public preview. It is not a mixed-biome battle renderer or a new terrain generator. Tests cover real Session moves, turn transition, codec rejection, legacy save roundtrip, AI move, distinct-cell naval attack, layer choices and public preview. Actual Godot results remain pending.

## V48.4 native read-only bridge inspection

BattleTerrain3D accepts valid experimental layered states. It builds a separate visual terrain copy with water beneath the road-defined bridge, attaches the closed elevated deck and access ramps on plain/road approaches, and positions the existing unit models using their visible mesh envelopes. The native destroyer is oriented along the channel. Ground bottom aligns with the deck; naval bottom aligns with the water plane for inspection (not a final hull draft). Air is above the deck. The scene records vertical and lateral clearance failures without scaling approved unit models. Unsupported approach terrain is counted rather than silently hidden. This is not continuous collision or swept-volume certification. Live board opening and legacy range overlays remain disabled for layered states. Two native OpenGL screenshots and clearance logs are now required by the experimental workflow. Inspect the actual unit dimensions before deciding deck height and channel width; bridges, ramps, and model envelopes may require further design changes.

Remaining: animated path over ramps, layer-aware picking and range overlay, fog/economy/supply/production integration, physical Android QA, and visual approval. No verified screenshot or passing test yet.
