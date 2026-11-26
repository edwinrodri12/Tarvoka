# V48–V49 — experimental branch, not playable integration

Parent is V47 art candidate, PR #710. No production calls have been changed. Do not merge either branch on the strength of unexecuted tests.

## V48 crossings
The reference graph accepts canonical road-cell records (integer x/y and ew/ns deck direction). On a bridge, the naval channel is perpendicular to the deck; aircraft remain independent. Occupancy keys allow one ground, one naval and one air unit on a crossing, with ordinary surface occupancy elsewhere. Ground and naval routes use the existing entry-cost/weather rules. The independent art model has a closed elevated deck, parapets and a clear opening; no ramp or unit animation integration yet.

Next integrate versioned metadata into SaveCodec and scenario validation (including JSON number normalization); exclude strategic sites on bridge cells; replace shared-surface occupancy logic in MoveActions, AI, supply, production and combat selection; adapt fog bridge knowledge, directional road/sea connectivity, picking and rendering. Keep legacy scenarios and saves identical. Ship model clearance and bridge approaches must be checked with actual units. The experimental graph must not be used for authoritative gameplay before parity and migration tests.

## V49 regions
Version 1 has two distinct selected biomes, mirrored north/south regions and a seeded two-row transition. Integer blend weights 0–1000, derived from seed and dimensions. Public projections only contain observed cells. This is a region field, not a new generated terrain or rendering integration. Next route the same versioned geography through preview and game, mix terrain/vegetation/shore materials consistently across sectors, preserve fog and saves, and verify independent region access. Existing single-biome maps remain unchanged.

## QA
Targeted test contains bridge movement and occupancy cases, model bounds, and 216 ordered biome-pair/map-size combinations. No measured performance or rendered visual approval yet.
