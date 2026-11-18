#!/usr/bin/env python3
"""Read ONLY real Godot 4.3 v364 mirrored-relay same-policy battles.

Research comparison uses 64 deterministic self-mirrors with two relays
on mirrored x-columns and first-player/camp exchange. The prior diagonal
64-match audit is a separate historical comparison, not mixed into this pool.
"""
import json
import pathlib
import sys
from collections import defaultdict

MARKER = "MIRROR_LAYOUT_V364 "

def parse(folder):
    result = []
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            tag = line.find(MARKER + "{")
            if tag < 0:
                continue
            payload = json.loads(line[tag + len(MARKER):].strip())
            if not isinstance(payload, dict):
                raise SystemExit("Bad real Godot match payload")
            result.append(payload)
    return result

def validate(rows):
    expected = {(level, map_id, fog, first, policy, layout)
                for level in (10, 12)
                for map_id in (0, 2)
                for fog in (False, True)
                for first in (0, 1)
                for policy in ("v35", "v363")
                for layout in ("north", "south")}
    found = []
    for m in rows:
        assert m["balanced_opening"] is True, "Balanced opening missing"
        assert m["fair_round"] is True, "Equal-round scoring missing"
        assert m["round_scoring"] is True, "Round scoring missing"
        assert int(m["relay_nodes"]) == 2, "Two-relay invariant broken"
        assert int(m["v363_side"]) == -1, "Self-mirror incorrectly becomes A/B"
        found.append((int(m["level"]),int(m["map"]),bool(m["fog"]),
                      int(m["first"]),str(m["mode"]),str(m["layout"])))
    if len(found) != 64 or set(found) != expected or len(set(found)) != 64:
        raise SystemExit("INVALID MIRRORED LAYOUT DATA: "
                         f"{len(found)}/64 games, missing={sorted(expected-set(found))} "
                         f"duplicate={len(found)-len(set(found))}")

def metrics(subset):
    counts = {"games":len(subset), "resolved":0, "censored":0,
              "first_wins":0, "second_wins":0,
              "blue_wins":0, "red_wins":0,
              "relay_wins":0, "combat_wins":0,
              "total_phases":0,"total_actions":0}
    for m in subset:
        winner = int(m["winner"])
        first = int(m["first"])
        if winner not in (0,1):
            counts["censored"] += 1
            continue
        counts["resolved"] += 1
        counts["first_wins" if winner == first else "second_wins"] += 1
        counts["blue_wins" if winner == 0 else "red_wins"] += 1
        counts["relay_wins" if m["winner_source"] == "relay" else "combat_wins"] += 1
        counts["total_phases"] += int(m["phases"])
        counts["total_actions"] += int(m["actions"])
    return counts

def main():
    folder = pathlib.Path(sys.argv[1] if len(sys.argv)>1 else ".ci-v364-logs")
    matches = parse(folder)
    validate(matches)
    layouts = {}
    for layout in ("north","south"):
        subset = [m for m in matches if m["layout"] == layout]
        details = metrics(subset)
        details["by_map"] = {
            str(k):metrics([m for m in subset if int(m["map"])==k])
            for k in (0,2)
        }
        details["by_policy"] = {
            k:metrics([m for m in subset if m["mode"]==k])
            for k in ("v35","v363")
        }
        layouts[layout] = details
    baseline = {
        "scenario":"Original diagonals (4,2) and (5,5) with same fair-round scoring",
        "source":"https://github.com/edwinrodri12/Tarvoka/actions/runs/44197455971",
        "same_policy_32":{
            "games":32,"first_wins":10,"second_wins":22,
            "blue_wins":26,"red_wins":6
        }
    }
    # This is NOT proof of balance: 32 deterministic mirrors per layout
    # and the same two prototype maps are not a population estimate.
    assessment = {}
    for layout, data in layouts.items():
        first_skew = abs(data["first_wins"]-data["second_wins"])
        color_skew = abs(data["blue_wins"]-data["red_wins"])
        assessment[layout] = {
            "first_skew":first_skew,
            "color_skew":color_skew,
            "better_color_parity_than_original_diagonal":color_skew < 20,
            "better_first_parity_than_original_diagonal":first_skew < 12,
            "zero_unresolved":data["censored"]==0,
            "merge_approved":False
        }
    report={
        "experiment":"Godot 4.3 mirrored two-relay layout control",
        "source":"64 actual self-play sessions (not invented)",
        "invariants":{
            "same_two_relays":True,
            "balanced_opening":True,
            "fair_round_scoring":True,
            "same_armies_and_maps":True,
            "ai_same_on_both_sides":True,
            "no_main_or_apk_changes":True
        },
        "layouts":layouts,
        "prior_diagonal_control":baseline,
        "screening":assessment,
        "merge_approved":False,
        "caveat":"Two fixed symmetric layouts tested on 2 small maps; other terrain, seed and human play remain untested."
    }
    dest=pathlib.Path("reports")
    dest.mkdir(parents=True,exist_ok=True)
    (dest/"ai_v364_mirrored_relay_control.json").write_text(
        json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    lines=[
        "# TARVOKA v3.6.4 — Geometría de dos relés simétricos",
        "",
        "Se analizaron **64 partidas reales**, ambas IA idénticas en cada partida;",
        "límite inicial de tres órdenes y puntuación por ronda completa.",
        "",
        "| Distribución | Partidas | Primero gana | Segundo gana | Azul gana | Rojo gana | Inconclusas |",
        "|---|---:|---:|---:|---:|---:|---:|"
    ]
    for layout in ("north","south"):
        d=layouts[layout]
        lines.append(f"| {layout} | {d['games']} | {d['first_wins']} | {d['second_wins']} | {d['blue_wins']} | {d['red_wins']} | {d['censored']} |")
    lines.extend(["| Diagonales originales (referencia previa) | 32 | 10 | 22 | 26 | 6 | 0 |",
                  "",
                  "## Detalle por mapa", "",
                  "| Diseño | Mapa | Primero | Segundo | Azul | Rojo |",
                  "|---|---:|---:|---:|---:|---:|"])
    for layout in ("north","south"):
        for map_id in ("0","2"):
            d=layouts[layout]["by_map"][map_id]
            lines.append(f"| {layout} | {map_id} | {d['first_wins']} | {d['second_wins']} | {d['blue_wins']} | {d['red_wins']} |")
    lines.extend(["", "## Lectura y decisión", "",
        "Se calculan por separado **sesgo de iniciativa** y **sesgo de color**,",
        "con el mismo número de enfrentamientos y 2 relés reflejados.",
        "La muestra es exploratoria; ninguna condición autoriza fusionar.",
        "Los 32 juegos de diagonales pertenecen a un **ensayo anterior**",
        "y no se suman a los 64 nuevos.",
        "",
        "**No se han modificado las reglas del juego, mapas oficiales, facciones, IA ni APK.**", ""])
    markdown="\n".join(lines)
    (dest/"ai_v364_mirrored_relay_control.md").write_text(markdown,encoding="utf-8")
    print("MIRROR_V364_ALL "+json.dumps(report,separators=(",",":"),ensure_ascii=False))
    print(markdown)
    print("PASS AI mirrored relay v364 aggregate: exactly 64 unique self-mirror games validated")

if __name__=="__main__":
    main()
