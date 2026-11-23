# Initiative paired-match diagnostic (2026-11-23)

Standalone offline QA utility; does not change the tactical engine, save format, or faction balance.

Run: `python3 -m unittest discover -s tools -p 'test_check_initiative_pairs.py'`

Input is a JSON array with exactly two results per `pair_id`: one `starter: blue` and one `starter: red`. `winner` is `blue`, `red` or `draw`. Example:

```json
[
  {"pair_id":"seed-001","starter":"blue","winner":"blue"},
  {"pair_id":"seed-001","starter":"red","winner":"blue"}
]
```

Run: `python3 tools/check_initiative_pairs.py results.json`.

Reports starter/second wins, draws, blue/red wins and starter win rate among decisive matches. Rejects incomplete pairs instead of silently treating unmatched games as balanced. Inputs must be produced by actual mirrored scenarios; this utility does not generate games or prove map symmetry. No change to eight-faction v0.1 values. CI/Godot/Android physical: NOT EXECUTED at creation; run tests before merge.

## Mirrored pair interpretation (2026-11-23)
The `pair_patterns` object distinguishes five mutually exclusive pair outcomes:
`starter_sweep` (both first movers win), `second_sweep` (both second movers win),
`blue_sweep` / `red_sweep` (same faction wins both legs), and
`draw_involved` (at least one draw). Their counts always sum to `pairs`.
A faction sweep is **not** evidence of initiative advantage. A starter sweep
suggests a possible initiative advantage but needs multiple independent seeds,
map/faction swaps, and uncertainty analysis before balance decisions.

QA: one new repository unittest checks all five patterns; two local isolated
classification smoke checks PASSED (all nine winner combinations and five-pattern
fixture). The complete repository unittest suite, Godot CI and Android device
were NOT EXECUTED in this run because local GitHub DNS resolution failed.
Do not treat isolated smoke checks as execution of repository tests.

## Uncertainty reporting (2026-11-23)
The CLI now returns `starter_win_rate_wilson95`: a two-element Wilson-score
95% interval for starter wins among **decisive matches**, or `null` when all
matches draw. This interval is descriptive and assumes independent Bernoulli
observations; two legs of one seed are correlated, so it must **not** be treated
as a statistically valid independent-sample confidence claim for paired matches.
For decisions, inspect pair patterns and multiple independent seeds/maps; avoid
balance adjustments based on a narrow interval or a tiny deterministic sample.
Two added unittests cover 0%, 50%, 100% and all-draw cases.
Status: GitHub publication verified; full Python test suite, Godot CI and
Android device **NOT EXECUTED** during this update (local GitHub DNS failed).

## Malformed-input regression (2026-11-23)
`starter` and `winner` must be strings, not JSON arrays or objects. Invalid collection values now raise `ValueError` with a match index rather than an uncaught `TypeError` during dictionary lookup. `test_unhashable_input_rejected_as_value_error` covers six malformed values. GitHub commits published; full Python/Godot/Android CI NOT EXECUTED, Android physical NO EJECUTADO EN DISPOSITIVO. No gameplay changes.

## 2026-11-23 — Canonicalización de identificadores de pareja
El analizador elimina espacios iniciales/finales de `pair_id` antes de agrupar. `"map-a"` y `" map-a "` son el mismo escenario, no dos escenarios independientes; dos registros con el mismo iniciador tras normalización se rechazan como duplicados. Dos regresiones nuevas cubren la pareja válida y la duplicada. Estado: código publicado; batería Python completa NO EJECUTADA, Godot/Android físico NO EJECUTADO. No se modifica el motor ni el balance.
