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
    return {"games":len(rows),"first_wins":first_wins,
            "second_wins":second_wins,"censored":censored,
            "first_win_rate_resolved":round(first_wins/(first_wins+second_wins),3)
                 if first_wins+second_wins else None}

def main():
    folder = pathlib.Path(sys.argv[1] if len(sys.argv)>1 else ".ci-balanced-logs")
    ab = read_rows(folder, "BAL363_MATCH")
    mirrors = read_rows(folder, "BAL363_MIRROR")
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
    by_map=defaultdict(lambda:{"first_wins":0,"second_wins":0})
    for m in mirrors:
        if int(m["winner"]) == int(m["first"]):
            by_map[int(m["map"])]["first_wins"] += 1
        elif int(m["winner"]) == 1-int(m["first"]):
            by_map[int(m["map"])]["second_wins"] += 1
    answer={"run_type":"Godot 4.3 balanced-opening A/B and mirror controls",
            "opening_rule":"first side maximum three legal orders",
            "ab":ab_summary,"same_policy":mirrored,
            "by_map":dict(sorted(by_map.items())),
            "previous_unbalanced_first_wins":{"first_wins":30,"games":32},
            "merge_approved":False,
            "limitations":"Only two prototype maps and classic armies; not Android profiling"}
    root=pathlib.Path("reports");root.mkdir(exist_ok=True)
    (root/"ai_balanced_opening_v363.json").write_text(
        json.dumps(answer,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    md=["# TARVOKA: auditoría de iniciativa, apertura equilibrada",
        "",
        "Primer jugador limitado a **tres órdenes** en su primera fase,",
        "aplicando exactamente el mecanismo del motor que usan las partidas nuevas.",
        "",
        "## Enfrentamiento directo (32 partidas)",
        "",
        "| Métrica | v3.5 | v3.6.3 |","|---|---:|---:|",
        f"| Victorias | {ab_summary['v35_wins']} | {ab_summary['v363_wins']} |",
        f"| Capturas | {ab_summary['v35_captures']} | {ab_summary['v363_captures']} |",
        f"| Retiradas | {ab_summary['v35_retreats']} | {ab_summary['v363_retreats']} |",
        f"| Supervivientes iniciales (acumulado) | {ab_summary['v35_initial_survivors']} | {ab_summary['v363_initial_survivors']} |",
        "",
        "## Ventaja de iniciativa en partidas con ambas IA iguales",
        "",
        "| Política | Partidas | Gana primero | Gana segundo | Inconclusas |",
        "|---|---:|---:|---:|---:|"]
    for policy in ("v35","v363"):
        m=mirrored[policy]
        md.append(f"| {policy} | {m['games']} | {m['first_wins']} | {m['second_wins']} | {m['censored']} |")
    md.extend(["",
        f"En A/B con apertura equilibrada, la facción inicial ganó **{ab_summary['first_wins']}/32**.",
        "En A/B anterior **sin** apertura equilibrada, ganó **30/32**.",
        "",
        "**Los dos conjuntos son muestras deterministas distintas.**",
        "La paridad de resultados no equivale a certificar reglas, IA o APK.",
        "",
        "Estado: solo estudio experimental, sin cambios en stats ni producción."])
    document="\n".join(md)+"\n"
    (root/"ai_balanced_opening_v363.md").write_text(document,encoding="utf-8")
    print("BAL363_ALL "+json.dumps(answer,separators=(",",":"),ensure_ascii=False))
    print(document)
    print("PASS balanced opening v363 audit: 32 genuine A/B and 32 genuine self-mirror matches")
if __name__=="__main__":
    main()
