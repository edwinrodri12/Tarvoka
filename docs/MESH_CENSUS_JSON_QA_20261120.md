# Mesh census JSON validation (2026-11-20)

Run `python3 tools/validate_mesh_census.py --self-test` for ten deterministic structural cases. Run `python3 tools/validate_mesh_census.py path/to/census.json` after generating a report with the Godot mesh census script in draft PR #622. Exit 0 means structural consistency only; exit 2 indicates invalid input. No external packages or network required.

Expected keys: `triangles`, `instances`, `mesh_nodes`, `surfaces`, `largest_mesh_triangles` (nonnegative integers); `largest_mesh_path` (string); `warnings` (list of strings). A nonempty path is required when the largest mesh has triangles. The checker is intentionally read-only and does not alter Godot scenes.

**QA status:** source committed; Python self-test NOT EXECUTED in this run; Godot 4.3 NOT EXECUTED; Android physical NO EJECUTADO EN DISPOSITIVO; visual PENDIENTE DE REVISIÓN VISUAL. No FPS or thermal claims.

**Next:** run self-test and actual Godot census on a production model, compare structural report, then optimize the largest contributor only after recording baseline. This PR is independent of draft #622 and does not merge it.
