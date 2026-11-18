#!/usr/bin/env python3
"""Aggregate 192 × 3 REAL Godot BasicAI mirror/reordered-unit decisions.

The research deliberately records, rather than asserts away, failed
equivariance. Matching game states/actuators are checked inside Godot.
No fake matches or outcomes, no calls to the production AI from Python.
"""
import json
import pathlib
import sys
from collections import Counter, defaultdict

MARKER = "MIRROR374_MATCH "
MAPS = (0,1,2,3)
LEVELS = (10,12)
POLICIES = ("v35","v363")
LAYOUTS = ("center","approach","flanks")


def load(folder):
    rows=[]
    for f in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in f.read_text(encoding="utf-8",errors="replace").splitlines():
            pos=line.find(MARKER+"{")
            if pos>=0:
                val=json.loads(line[pos+len(MARKER):].strip())
                if not isinstance(val,dict):
                    raise SystemExit("A nonobject Godot match record is invalid")
                rows.append(val)
    return rows


def validate(rows):
    expected={(level,mp,fog,first,policy,layout)
              for level in LEVELS for mp in MAPS
              for fog in (False,True) for first in (0,1)
              for policy in POLICIES for layout in LAYOUTS}
    by_key={}
    seen_events=0
    for row in rows:
        key=(int(row["level"]),int(row["map"]),bool(row["fog"]),
             int(row["first"]),str(row["mode"]),str(row["layout"]))
        if key in by_key:
            raise SystemExit("Duplicate real mirrored opening "+str(key))
        by_key[key]=row
        if key not in expected:
            raise SystemExit("Unexpected game "+str(key))
        events=row["actions"]
        assert int(row["evaluated"])==3 and len(events)==3
        assert sum(not e["same_mirrored"] for e in events)==int(row["mirror_decision_mismatches"])
        assert sum(not e["same_unit_order"] for e in events)==int(row["unit_order_mismatches"])
        assert sum(int(e["visibility_unmirrored_cells"]) for e in events)==int(row["visibility_cell_mismatches"])
        assert sum(bool(e["exploration_repaired"]) for e in events)==int(row["mirrored_exploration_repairs"])
        for index,event in enumerate(events):
            assert int(event["phase"])==index
            assert event["source"]["action"]!="none"
            assert event["source"]==event["mirror"] if bool(event["same_mirrored"]) else event["source"]!=event["mirror"]
            assert event["source"]==event["reversed_unit_order"] if bool(event["same_unit_order"]) else event["source"]!=event["reversed_unit_order"]
            assert int(event["visibility_unmirrored_cells"])>=0
            seen_events+=1
    if len(rows)!=192 or set(by_key)!=expected or seen_events!=576:
        raise SystemExit(f"Invalid v374 experiment: openings={len(rows)} "
                         f"mirror_calls={seen_events}, missing={sorted(expected-set(by_key))}")
    return {"unique_real_openings":192,"real_action_pairs":576,
            "original_actions":576,"mirrored_actions":576,
            "reordered_actions":576,"states_involution_and_save_validated":True}


def measure(rows):
    events=[(r,e) for r in rows for e in r["actions"]]
    reason=Counter()
    causes=Counter()
    by_phase=Counter()
    type_pairs=Counter()
    first_examples=[]
    for r,e in events:
        src=e["source"]
        mirrored=e["mirror"]
        if not e["same_mirrored"]:
            key=(str(src["action"]),str(mirrored["action"]))
            type_pairs[str(key)]+=1
            reason[str(e["source_reason"])] += 1
            by_phase[str(e["phase"])]+=1
            if src["action"]!=mirrored["action"]:
                causes["different_action_type"]+=1
            elif src.get("unit")!=mirrored.get("unit"):
                causes["different_unit"]+=1
            elif src.get("destination")!=mirrored.get("destination"):
                causes["different_destination"]+=1
            elif src.get("defender")!=mirrored.get("defender"):
                causes["different_defender"]+=1
            else:
                causes["other_metadata"]+=1
            if len(first_examples)<10:
                first_examples.append({
                    "map":r["map"],"level":r["level"],"fog":r["fog"],
                    "first":r["first"],"mode":r["mode"],"layout":r["layout"],
                    "step":e["phase"],"source":src,"mirror":mirrored,
                    "reason":e["source_reason"]})
    return {
        "openings":len(rows),"comparisons":len(events),
        "mirror_exact":sum(bool(e["same_mirrored"]) for _,e in events),
        "mirror_mismatches":sum(not e["same_mirrored"] for _,e in events),
        "order_exact":sum(bool(e["same_unit_order"]) for _,e in events),
        "order_mismatches":sum(not e["same_unit_order"] for _,e in events),
        "mirror_missing_actions":sum(int(r["mirrored_missing_actions"]) for r in rows),
        "visibility_cell_mismatches":sum(int(r["visibility_cell_mismatches"]) for r in rows),
        "exploration_repaired":sum(int(r["mirrored_exploration_repairs"]) for r in rows),
        "by_first_step_mismatch":dict(sorted(by_phase.items())),
        "mismatch_primary_reason":dict(reason.most_common()),
        "causes":dict(sorted(causes.items())),
        "action_type_pairs":dict(type_pairs.most_common()),
        "first_ten_verified_mismatches":first_examples
    }


def main():
    src=pathlib.Path(sys.argv[1] if len(sys.argv)>1 else ".ci-v374-logs")
    rows=load(src)
    guarantees=validate(rows)
    by_layout={name:measure([r for r in rows if r["layout"]==name]) for name in LAYOUTS}
    by_map={str(mp):measure([r for r in rows if int(r["map"])==mp]) for mp in MAPS}
    by_first={str(i):measure([r for r in rows if int(r["first"])==i]) for i in (0,1)}
    by_policy={i:measure([r for r in rows if r["mode"]==i]) for i in POLICIES}
    by_fog={str(i).lower():measure([r for r in rows if bool(r["fog"])==i])
            for i in (False,True)}
    overall=measure(rows)
    report={
        "experiment":"TARVOKA v3.7.4 initial BattleSession state horizontal reflection plus faction exchange",
        "source":"576 real original BasicAI decisions, 576 reflected legal decisions, "
                 "576 reversed-unit-order legal decisions",
        "quality_gates":guarantees,
        "overall":overall,
        "by_map":by_map,
        "by_layout":by_layout,
        "by_first":by_first,
        "by_policy":by_policy,
        "by_fog":by_fog,
        "merge_approved":False,
        "interpretation":"Mismatch is a reproducible symptom, NOT proven causal "
                         "explanation of win-rate gaps. Additional isolated controls required."
    }
    output=pathlib.Path("reports")
    output.mkdir(exist_ok=True)
    (output/"ai_v374_mirror_audit.json").write_text(
        json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    lines=[
        "# TARVOKA v3.7.4 — Auditoría de reflejo horizontal y orden interno",
        "",
        "**192 escenarios de apertura / 576 pares reales de decisiones de IA**.",
        "Cada estado fue reflejado horizontalmente con cambio de facción,",
        "y probado también con las mismas unidades enumeradas al revés.",
        "",
        "| Categoría | Decisiones | Reflejo coincide | Reflejo difiere | Orden coincide | Orden difiere |",
        "|---|---:|---:|---:|---:|---:|"]
    for label,part in [("Total",overall)]+[(f"Mapa {mp}",by_map[str(mp)]) for mp in MAPS]:
        lines.append(f"| {label} | {part['comparisons']} | {part['mirror_exact']} | "
                     f"{part['mirror_mismatches']} | {part['order_exact']} | {part['order_mismatches']} |")
    lines.extend(["","## Posiciones de relés","",
        "| Distribución | Comparaciones | Fallos de reflejo | Fallos por orden interno |",
        "|---|---:|---:|---:|"])
    for name,p in by_layout.items():
        lines.append(f"| {name} | {p['comparisons']} | {p['mirror_mismatches']} | "
                     f"{p['order_mismatches']} |")
    lines.extend(["","## Causas de diferencia de decisión",""])
    for key,v in overall["causes"].items():
        lines.append(f"- {key}: {v}")
    lines.extend(["",
        "Los resultados NO modifican la IA ni autorizan compensaciones artificiales.",
        "La auditoría registra decisiones de apertura; no reproduce toda una batalla",
        "espejada ni prueba por sí sola el origen causal de las victorias por color.", ""])
    markdown="\n".join(lines)
    (output/"ai_v374_mirror_audit.md").write_text(markdown,encoding="utf-8")
    print("MIRROR374_ALL "+json.dumps(report,ensure_ascii=False,separators=(",",":")))
    print(markdown)
    print("PASS AI mirror v374 aggregate: 192 real matched states, 576 original/mirror/reorder comparisons")

if __name__=="__main__":
    main()
