#!/usr/bin/env python3
"""Validate 64 actual Godot large-map human->AI integrations, not battle wins."""
import json
import pathlib
import sys
from collections import Counter

PREFIX = "LARGE378_RESULT "
FLAGS = ("human_purchase", "mirror_action", "mirror_state",
         "legacy_save", "modern_units", "saved_goals",
         "responder_income_equal")
SIZES = ("24x18", "40x30")

def main():
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".ci-v378-logs")
    rows = []
    for log in sorted(root.rglob("*.log")):
        for line in log.read_text(encoding="utf-8", errors="replace").splitlines():
            idx = line.find(PREFIX + "{")
            if idx >= 0:
                rows.append(json.loads(line[idx + len(PREFIX):]))
    expected = {(size, fog, first, theme)
                for size in SIZES for fog in (False, True)
                for first in (0, 1) for theme in range(8)}
    found = set()
    signatures = {}
    factions = set()
    sources = {}
    for row in rows:
        key = (row["size"], bool(row["fog"]),
               int(row["first"]), int(row["visual_index"]))
        if key in found or key not in expected:
            raise SystemExit(f"duplicate or unexpected v378 scenario: {key}")
        found.add(key)
        if not all(row.get(flag) is True for flag in FLAGS):
            raise SystemExit(f"v378 missing verified contract {key}")
        expected_seed = {("24x18", False):317, ("24x18", True):319,
                         ("40x30", False):630, ("40x30", True):632}[key[:2]]
        if int(row["seed"]) != expected_seed:
            raise SystemExit(f"v378 wrong fixed terrain seed {key}")
        if row["blue"] == row["red"]:
            raise SystemExit(f"v378 identical selected factions {key}")
        factions.add(str(row["blue"]))
        factions.add(str(row["red"]))
        shard = key[:2]
        sources[shard] = sources.get(shard, 0) + 1
        comparison_key = (key[0], key[1], key[2])
        sig = row["signature"]
        if comparison_key in signatures and signatures[comparison_key] != sig:
            raise SystemExit(f"v378 cosmetic faction changed AI action {key}")
        signatures[comparison_key] = sig
    if set(found) != expected or len(rows) != 64:
        raise SystemExit(f"v378 matrix incomplete: {len(rows)}/64, missing={sorted(expected-found)}")
    if len(factions) != 8 or any(v != 16 for v in sources.values()) or len(sources) != 4:
        raise SystemExit(f"v378 missing visual factions or shards: {len(factions)} faction IDs")
    actions = Counter(row["signature"]["action"] for row in rows)
    report = {
        "version": "v3.7.8",
        "scope": "4 seeded large-map/fog shards, 16 legal human-to-AI responses per shard",
        "is_full_battle_balance_study": False,
        "visual_factions_not_commander_powers": True,
        "supported_sizes": list(SIZES),
        "tested_faction_keys": sorted(factions),
        "tested_scenarios": len(rows),
        "successful_shards": len(sources),
        "reflected_gameplay_equivalent": 64,
        "modern_human_purchases": 64,
        "resumable_v1_legacy_saves": 64,
        "current_v1_save_roundtrips": 64,
        "no_extra_first_response_income": 64,
        "official_ai_action_types": dict(actions),
        "merge_approved": False,
        "production_changed": False
    }
    out = pathlib.Path("reports")
    out.mkdir(exist_ok=True)
    (out / "ai_v378_large_modern.json").write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    md = [
        "# TARVOKA v3.7.8 — Regresión de mapas grandes y facciones visuales", "",
        "**64 escenarios reales de Godot con compra humana y respuesta oficial de IA.**",
        "Son secuencias de integración, **no** batallas terminadas ni estadísticas de victoria.", "",
        "| Tamaño | Niebla | Casos correctos |",
        "|---|---|---:|"]
    for size in SIZES:
        for fog in (False, True):
            md.append(f"| {size} | {'Sí' if fog else 'No'} | {sources[(size,fog)]} |")
    md += ["", "- 8 identidades visuales y 2 bandos reales; no se prueban poderes de comandante.",
           "- 64 compras manuales legales seguidas de un turno y una decisión de la IA oficial.",
           "- 64 acciones/estados equivalentes por reflexión.",
           "- 64 reanudaciones de guardados v1 sin objetivos persistentes.",
           "- No se conceden ingresos ni movimientos extra al segundo jugador.",
           "- Se mantienen main, APK, combate, costes, capturas y guardados.", ""]
    (out / "ai_v378_large_modern.md").write_text("\n".join(md), encoding="utf-8")
    print("LARGE378_ALL " + json.dumps(report, ensure_ascii=False))
    print("\n".join(md))
    print("PASS TARVOKA v378 aggregate: 64/64 independent scenarios in 4 matrix shards")

if __name__ == "__main__":
    main()
