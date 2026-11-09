# Decisions
- Godot 4 and modular GDScript; offline first.
- Tactical board 10 columns by 8 rows.
- Terrain movement uses explicit costs and blocks impassable cells.
- Keep all TARVOKA assets original and separate from other projects.
- TARVOKA is a provisional name; trademark clearance required before release.

2026-11-09: Reject malformed or unknown terrain tiles throughout the board before movement calculation, rather than silently treating invalid cells as obstacles.
