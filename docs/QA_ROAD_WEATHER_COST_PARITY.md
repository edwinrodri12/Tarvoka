# Road/weather movement parity QA

14 Nov 2026. Scope: independent Godot 4.3 regression, no changes to gameplay or balance.

`tests/test_road_weather_cost_parity.gd` validates motorized road half-costs, walking costs, allies traversable but not endpoints, enemy blocking, impassable water, and cost-source parity across clear/rain/snow.

Run: `godot --headless --path . --script res://tests/test_road_weather_cost_parity.gd`.

Expected: `PASS: road/weather cost parity` and exit 0. Status at authoring: **NO EJECUTADO** (CI pending); Android physical: **NO EJECUTADO EN DISPOSITIVO**. This test does not certify performance, save/load, AI or victory. Do not merge without green Godot CI and relevant existing regression checks.

2026-11-14 extension: verifies adjacent mountain traversal with one-point budget (without chaining beyond budget), invalid weather rejection, negative budget and blocked-origin rejection. Previous PR head 89dda4c: scoped road/weather workflow, Godot rules and Android export reported SUCCESS; new commit 74de150c requires fresh CI. Android physical: NO EJECUTADO EN DISPOSITIVO. This is a movement regression only, not a defense-height or visual QA certificate.

2026-11-14 follow-up: added 12 repeat route-query checks asserting deterministic results and immutable terrain, allied transit and blocked inputs. Additional clear-weather parity checks run after rain/snow queries to detect state leakage. Previous head bd4751f6: scoped Godot workflow 43630249231 SUCCESS, general Godot 43630249236 SUCCESS, Android export 43630249315 SUCCESS. New head requires fresh CI; Android physical NO EJECUTADO EN DISPOSITIVO. PR remains draft and unmerged.

2026-11-14 additional domain/validation coverage (commit a8efe673): air movement over water, naval-only water occupancy, invalid traction/domain rejection, malformed terrain fail-closed and zero-budget origin behavior. Prior head 9564960a: scoped Godot 43635774718 SUCCESS, general Godot 43635774800 SUCCESS, Android export 43635774648 SUCCESS. These runs DO NOT validate the new commit. New CI: NO EJECUTADO / pending. Physical Android: NO EJECUTADO EN DISPOSITIVO. PR remains draft; no gameplay rule changes.
