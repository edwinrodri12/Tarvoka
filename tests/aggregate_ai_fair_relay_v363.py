#!/usr/bin/env python3
"""Assess first-player advantage under the actual balanced-opening rule.

Only ingests real Godot reports; never invents simulated matches.
"""
import json
import pathlib
import sys
from collections import defaultdict

def read_rows(folder, marker):
    result = []
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            key = marker + " {"
            at = line.find(key)
            if at < 0:
                continue
            payload = line[at + len(marker) + 1:].strip()
            result.append(json.loads(payload))
    return result

def require_matrix(rows, modes):
    observed = []
    expected = set()
    for level in (10, 12):
        for map_id in (0, 2):
            for fog in (False, True):
                for first in (0, 1):
                    for mode in modes:
                        expected.add((level, map_id, fog, first, mode))
    for row in rows:
        assert row["balanced_opening"] is True
        assert row["fair_round"] is True and row["round_scoring"] is True
        assert int(row["relay_nodes"]) == 2
        mode = int(row["v363_side"]) if modes == (0, 1) else str(row["mode"])
        observed.append((int(row["level"]), int(row["map"]), bool(row["fog"]),
                         int(row["first"]), mode))
    if len(observed) != 32 or len(set(observed)) != 32 or set(observed) != expected:
        raise SystemExit(
            f"INVALID {modes}: rows={len(observed)} duplicates={len(observed)-len(set(observed))} "
            f"missing={sorted(expected-set(observed))}")

def summary(rows):
    first_wins = sum(int(x["winner"]) == int(x["first"]) for x in rows)
    second_wins = sum(int(x["winner"]) == 1-int(x["first"]) for x in rows)
    censored = len(rows)-first_wins-second_wins
    relay_victories = sum(x.get("winner_source")=="relay" for x in rows)
    combat_victories = sum(x.get("winner_source")=="combat_or_other" and
                           int(x.get("winner",-1))>=0 for x in rows)
    return {"games":len(rows),"first_wins":first_wins,
            "second_wins":second_wins,"censored":censored,
            "relay_victories":relay_victories,"combat_victories":combat_victories,
            "first_win_rate_resolved":round(first_wins/(first_wins+second_wins),3)
                 if first_wins+second_wins else None}

def main():
    folder = pathlib.Path(sys.argv[1] if len(sys.argv)>1 else ".ci-balanced-logs")
    ab = read_rows(folder, "FAIR363_MATCH")
    mirrors = read_rows(folder, "FAIR363_MIRROR")
    require_matrix(ab, (0,1))
    require_matrix(mirrors, ("v35","v363"))
    ab_summary = summary(ab)
    ab_summary.update({"v363_wins":0,"v35_wins":0,"v363_captures":0,"v35_captures":0,
                       "v363_retreats":0,"v35_retreats":0,"v363_initial_survivors":0,
                       "v35_initial_survivors":0})
    for m in ab:
        v = int(m["v363_side"])
        old = 1-v
        if int(m["winner"])==v:
            ab_summary["v363_wins"]+=1
        elif int(m["winner"])==old:
            ab_summary["v35_wins"]+=1
        for k in ("captures","retreats","initial_survivors"):
            ab_summary["v363_"+k]+=int(m[k][v])
            ab_summary["v35_"+k]+=int(m[k][old])
    mirrored={}
    for policy in ("v35","v363"):
        mirrored[policy]=summary([m for m in mirrors if m["mode"]==policy])
    by_map=defaultdict(lambda:{"first_wins":0,"second_wins":0,
                               "relay_victories":0,"combat_victories":0})
    for m in mirrors:
        if m.get("winner_source") == "relay":
            by_map[int(m["map"])]["relay_victories"]+=1
        elif int(m["winner"]) >= 0:
            by_map[int(m["map"])]["combat_victories"]+=1
        if int(m["winner"]) == int(m["first"]):
            by_map[int(m["map"])]["first_wins"] += 1
        elif int(m["winner"]) == 1-int(m["first"]):
            by_map[int(m["map"])]["second_wins"] += 1
    answer={"run_type":"Godot 4.3 fair-round classic relay A/B and mirror controls",
            "opening_rule":"first side maximum three legal orders",
            "experimental_relay_scoring":"same two classic relay cells; count scores together after both sides end their turns",
            "ab":ab_summary,"same_policy":mirrored,
            "by_map":dict(sorted(by_map.items())),
            "previous_balanced_opening_classic_relay":{
                "ab":{"first_wins":24,"games":32,"v35_wins":16,"v363_wins":16},
                "same_policy_by_map":{"0":{"first_wins":4,"second_wins":12},
                                      "2":{"first_wins":16,"second_wins":0}},
                "source":"https://github.com/edwinrodri12/Tarvoka/actions/runs/44194478920"
            },
            "merge_approved":False,
            "limitations":"Only two prototype maps and classic armies; not Android profiling"}
    root=pathlib.Path("reports");root.mkdir(exist_ok=True)
    (root/"ai_fair_round_relay_v363.json").write_text(
        json.dumps(answer,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    md=["# TARVOKA: auditoría de puntuación simétrica de relés clásicos",
        "",
        "El primer jugador mantiene el límite existente de **tres órdenes**.",
        "Se mantienen los **dos relés originales**, cambiando únicamente",
        "la contabilidad experimental para puntuar tras la respuesta de ambos bandos.",
        "",
        "## Enfrentamiento directo con puntuación igualada (32 partidas)",
        "",
        "| Métrica | v3.5 | v3.6.3 |","|---|---:|---:|",
        f"| Victorias | {ab_summary['v35_wins']} | {ab_summary['v363_wins']} |",
        f"| Capturas | {ab_summary['v35_captures']} | {ab_summary['v363_captures']} |",
        f"| Retiradas | {ab_summary['v35_retreats']} | {ab_summary['v363_retreats']} |",
        f"| Supervivientes iniciales (acumulado) | {ab_summary['v35_initial_survivors']} | {ab_summary['v363_initial_survivors']} |",
        "",
        "## Ventaja de iniciativa, IA contra sí misma, puntuación igualada",
        "",
        "| Política | Partidas | Gana primero | Gana segundo | Inconclusas |",
        "|---|---:|---:|---:|---:|"]
    for policy in ("v35","v363"):
        m=mirrored[policy]
        md.append(f"| {policy} | {m['games']} | {m['first_wins']} | {m['second_wins']} | {m['censored']} |")
    md.extend(["",
        "## Controles por mapa (ambas IA iguales)", "",
        "| Mapa | Primer bando | Segundo bando | Victorias por relés |",
        "|---|---:|---:|---:|"])
    for map_id, row in sorted(by_map.items()):
        md.append(f"| {map_id} | {row['first_wins']} | {row['second_wins']} | {row['relay_victories']} |")
    md.extend(["",
        f"En A/B con puntuación por ronda, el primer bando ganó **{ab_summary['first_wins']}/32**.",
        "Referencia con el mismo límite de tres órdenes, pero **puntuación clásica por turno individual**:",
        "primer bando **24/32** A/B; en controles espejados, mapa 0: **4/16** y mapa 2: **16/16**.",
        "",
        "Son partidas reproducibles del motor con dos condiciones distintas.",
        "Si persiste el desequilibrio, se investigará la geometría de los puentes",
        "y el momento de captura; no se debe activar esto en producción sin pruebas adicionales.",
        "",
        "**Nunca aprobar automáticamente una fusión o APK a partir de esta muestra.**",
        ""])
    document="\n".join(md)+"\n"
    (root/"ai_fair_round_relay_v363.md").write_text(document,encoding="utf-8")
    print("FAIR363_ALL "+json.dumps(answer,separators=(",",":"),ensure_ascii=False))
    print(document)
    print("PASS fair relay v363 audit: exactly 32 A/B plus 32 same-policy matches with two old relay cells")
if __name__=="__main__":
    main()
