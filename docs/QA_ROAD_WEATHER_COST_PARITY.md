# Road/weather movement parity QA

14 Nov 2026. Scope: independent Godot 4.3 regression, no changes to gameplay or balance.

`tests/test_road_weather_cost_parity.gd` validates motorized road half-costs, walking costs, allies traversable but not endpoints, enemy blocking, impassable water, and cost-source parity across clear/rain/snow.

Run: `godot --headless --path . --script res://tests/test_road_weather_cost_parity.gd`.

Expected: `PASS: road/weather cost parity` and exit 0. Status at authoring: **NO EJECUTADO** (CI pending); Android physical: **NO EJECUTADO EN DISPOSITIVO**. This test does not certify performance, save/load, AI or victory. Do not merge without green Godot CI and relevant existing regression checks.

2026-11-14 extension: verifies adjacent mountain traversal with one-point budget (without chaining beyond budget), invalid weather rejection, negative budget and blocked-origin rejection. Previous PR head 89dda4c: scoped road/weather workflow, Godot rules and Android export reported SUCCESS; new commit 74de150c requires fresh CI. Android physical: NO EJECUTADO EN DISPOSITIVO. This is a movement regression only, not a defense-height or visual QA certificate.
