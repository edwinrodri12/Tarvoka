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
