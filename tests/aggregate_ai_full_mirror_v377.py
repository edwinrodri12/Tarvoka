#!/usr/bin/env python3
"""TARVOKA v3.7.6 — 192 pairs of full real Godot battles.

Two independently executed authoritative games per pair, one reflected
horizontally and faction-swapped. Count earliest divergent action/transition,
then compare full winners. The input is emitted by actual AI.step and
BattleSession functions, never synthetic or predicted results.
"""
import json
import pathlib
import sys
from collections import Counter

MARKER="BATTLE377_MATCH "
MAPS=(0,1,2,3)
LAYOUTS=("center","approach","flanks")
POLICIES=("v35","v363")


def load(folder):
    output=[]
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8",errors="replace").splitlines():
            k=line.find(MARKER+"{")
            if k>=0:
                match=json.loads(line[k+len(MARKER):].strip())
                assert isinstance(match,dict)
                output.append(match)
    return output


def validate(rows):
    expected={(level,mp,fog,first,policy,layout)
              for level in (10,12) for mp in MAPS
              for fog in (False,True) for first in (0,1)
              for policy in POLICIES for layout in LAYOUTS}
    observed={}
    for r in rows:
        key=(int(r["level"]),int(r["map"]),bool(r["fog"]),
             int(r["first"]),str(r["mode"]),str(r["layout"]))
        if key in observed:
            raise SystemExit(f"Duplicate real battle pair {key}")
        observed[key]=r
        if key not in expected:
            raise SystemExit(f"Unknown battle scenario {key}")
        assert int(r["opening_orders"])==3
        assert r["income_equal"] is True and r["round_scoring"] is True
        assert int(r["original_frames"])>4 and int(r["mirrored_frames"])>4
        comparison=r["first_divergence"]
        assert isinstance(comparison,dict)
        equal=bool(comparison["equal"])
        if equal:
            assert int(comparison["first_index"])==-1
            assert int(comparison["matched_frames"])==int(r["original_frames"])
            assert int(r["original_frames"])==int(r["mirrored_frames"])
        else:
            assert 0 <= int(comparison["first_index"]) < max(
                int(r["original_frames"]),int(r["mirrored_frames"]))
            assert int(comparison["first_index"])==int(comparison["matched_frames"])
            assert str(comparison["category"])!="none"
        first=int(r["first"])
        assert first in (0,1)
        w=int(r["original_winner"])
        m=int(r["mirrored_winner"])
        mapped=int(r["mapped_mirror_winner"])
        assert w in (-1,0,1) and m in (-1,0,1)
        assert mapped == (1-m if m in (0,1) else -1)
        assert r["winner_equivariant"] is (w==mapped)
        for condition in ("original","mirror"):
            info=r["outcomes"][condition]
            assert int(info["actions"])>=3
            assert int(info["phases"])>=0
            assert int(info["moves"])>=0
            assert int(info["attacks"])>=0
            assert int(info["purchases"])>=0
            assert int(info["resupplies"])>=0
            assert sum(int(info[t]) for t in ("moves","attacks","purchases","resupplies"))==int(info["actions"])
            assert len(info["signal"])==2
            assert info["terminal"] in ("winner","phase_limit","idle_stalemate")
    if len(rows)!=192 or set(observed)!=expected:
        raise SystemExit(f"Invalid v377 matrix: {len(rows)}/192 "
                         f"missing={sorted(expected-set(observed))}")
    # v375 historical outcomes are REFERENCES, not a gate for the
    # intentionally changed research-only planner. Requiring identical
    # winners would incorrectly reject a useful candidate.
    return {
        "full_real_pairs":192,
        "real_independent_battles":384,
        "opening_orders_each":3,
        "uses_official_basic_ai":True,
        "review_branch_only_not_merged":True
    }


def metrics(rows):
    result={
        "pairs":len(rows),"mirrored_action_state_equal":0,
        "first_divergences":0,"winner_equivariant":0,"winner_not_equivariant":0,
        "divergence_category":{},"changed_field":{},
        "first_divergence_by_phase":{},"divergence_at_opening":0,
        "original":{"first":0,"second":0,"blue":0,"red":0,"censored":0,
                    "signal_wins":0,"total_actions":0,"total_purchases":0,
                    "total_attacks":0,"avg_phases":0},
        "reflected":{"mapped_first":0,"mapped_second":0,
                    "mapped_blue":0,"mapped_red":0,"censored":0,
                    "total_actions":0,"total_purchases":0,
                    "total_attacks":0,"avg_phases":0}
    }
    cats=Counter()
    fields=Counter()
    phases=Counter()
    examples=[]
    sum_orig=sum_mirror=0
    for r in rows:
        if r["first_divergence"]["equal"]:
            result["mirrored_action_state_equal"]+=1
        else:
            result["first_divergences"]+=1
            d=r["first_divergence"]
            cats[str(d["category"])]+=1
            fields[str(d.get("changed_field","none"))]+=1
            phases[str(d.get("first_phase",-1))]+=1
            result["divergence_at_opening"]+=int(int(d.get("first_phase",-1))==0)
            if len(examples)<8:
                examples.append({"map":r["map"],"fog":r["fog"],
                    "first":r["first"],"policy":r["mode"],
                    "layout":r["layout"],"difference":d})
        result["winner_equivariant"]+=int(r["winner_equivariant"])
        result["winner_not_equivariant"]+=int(not r["winner_equivariant"])
        first=int(r["first"])
        win=int(r["original_winner"])
        mapped=int(r["mapped_mirror_winner"])
        a=r["outcomes"]["original"]
        b=r["outcomes"]["mirror"]
        sum_orig+=int(a["phases"])
        sum_mirror+=int(b["phases"])
        result["original"]["total_actions"]+=int(a["actions"])
        result["original"]["total_purchases"]+=int(a["purchases"])
        result["original"]["total_attacks"]+=int(a["attacks"])
        result["reflected"]["total_actions"]+=int(b["actions"])
        result["reflected"]["total_purchases"]+=int(b["purchases"])
        result["reflected"]["total_attacks"]+=int(b["attacks"])
        if win in (0,1):
            result["original"]["first" if win==first else "second"]+=1
            result["original"]["blue" if win==0 else "red"]+=1
            result["original"]["signal_wins"]+=int(
                int(r["original_relay_winner"])==win)
        else:
            result["original"]["censored"]+=1
        if mapped in (0,1):
            result["reflected"]["mapped_first" if mapped==first else "mapped_second"]+=1
            result["reflected"]["mapped_blue" if mapped==0 else "mapped_red"]+=1
        else:
            result["reflected"]["censored"]+=1
    result["original"]["avg_phases"]=round(sum_orig/len(rows),2) if rows else 0
    result["reflected"]["avg_phases"]=round(sum_mirror/len(rows),2) if rows else 0
    result["divergence_category"]=dict(cats.most_common())
    result["changed_field"]=dict(fields.most_common())
    result["first_divergence_by_phase"]=dict(
        sorted(phases.items(),key=lambda p:int(p[0])))
    result["examples"]=examples
    return result


def main():
    root=pathlib.Path(sys.argv[1] if len(sys.argv)>1 else ".ci-v377-logs")
    rows=load(root)
    quality=validate(rows)
    result={
        "experiment":"TARVOKA v3.7.6 research-only side-normalized mission planner",
        "source":"192 pairs = 384 real Godot 4.3 games, official BasicAI and unchanged BattleSession",
        "historical_v375": {
            "full_state_equivalent_pairs":0,
            "winner_equivalent_pairs":140,
            "winner_non_equivalent_pairs":52,
            "first_difference_all_pairs":"ai_objectives in opening phase 0, action 0",
            "original_by_layout": {
                "center":{"first":28,"second":36,"blue":32,"red":32},
                "approach":{"first":12,"second":52,"blue":36,"red":28},
                "flanks":{"first":18,"second":46,"blue":38,"red":26}
            }
        },
        "quality_gates":quality,
        "overall":metrics(rows),
        "by_map":{str(mp):metrics([x for x in rows if int(x["map"])==mp]) for mp in MAPS},
        "by_layout":{name:metrics([x for x in rows if x["layout"]==name]) for name in LAYOUTS},
        "by_fog":{str(fog).lower():metrics([x for x in rows if bool(x["fog"])==fog])
                  for fog in (False,True)},
        "by_policy":{policy:metrics([x for x in rows if x["mode"]==policy])
                     for policy in POLICIES},
        "by_first":{str(first):metrics([x for x in rows if int(x["first"])==first])
                    for first in (0,1)},
        "by_map_layout":{str(mp):{layout:metrics([
            x for x in rows if int(x["map"])==mp and x["layout"]==layout])
            for layout in LAYOUTS} for mp in MAPS},
        "merge_approved":False,
        "warning":"Production candidate is unmerged. "
        "A mismatch decrease is encouraging but still requires independent "
        "regression, map seeds, humans and modern squads."
    }
    if result["overall"]["mirrored_action_state_equal"] != 192 or result["overall"]["winner_not_equivariant"] != 0:
        raise SystemExit("v3.7.7 blocked: production planner lost full reflection symmetry")
    output=pathlib.Path("reports")
    output.mkdir(exist_ok=True)
    (output/"ai_v377_full_battle_mirror.json").write_text(
        json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    table=[
        "# TARVOKA v3.7.6 — Simetría durante batallas completas",
        "",
        "**384 partidas auténticas de Godot** (192 originales + 192 reflejadas).",
        "Incluye ingresos, combate, ciudades, producción, objetivos persistentes",
        "y puntuación de relés de ronda completa.",
        "",
        "| Grupo | Pares | Todos los estados coinciden | Primera divergencia | Ganadores coinciden tras invertir color | Ganadores diferentes |",
        "|---|---:|---:|---:|---:|---:|"]
    for label,group in [("Total",result["overall"])]+[
            (f"Mapa {mp}",result["by_map"][str(mp)]) for mp in MAPS]:
        table.append(f"| {label} | {group['pairs']} | "
                     f"{group['mirrored_action_state_equal']} | "
                     f"{group['first_divergences']} | "
                     f"{group['winner_equivariant']} | "
                     f"{group['winner_not_equivariant']} |")
    table+=["","## Por distribución de relés","",
        "| Relés | Pares | Diferencias de acción/estado | Diferentes ganadores |",
        "|---|---:|---:|---:|"]
    for name,group in result["by_layout"].items():
        table.append(f"| {name} | {group['pairs']} | "
                     f"{group['first_divergences']} | "
                     f"{group['winner_not_equivariant']} |")
    table+=["","## Primera divergencia",""]
    for category,n in result["overall"]["divergence_category"].items():
        table.append(f"- {category}: {n}")
    table+=["","## Primer campo que difiere",""]
    for field,n in result["overall"]["changed_field"].items():
        table.append(f"- {field}: {n}")
    table+=["","## Seguridad","",
        "- Reproducción estricta del control anterior en 3 configuraciones.",
        "- Cada batalla es independiente y ejecuta AI.step + BattleSession originales.",
        "- Una ventaja por facción no se corrige regalando dinero o movimientos.",
        "- Sólo una rama de revisión cambia el planificador; main, APK y guardados quedan intactos.", ""]
    md="\n".join(table)
    (output/"ai_v377_full_battle_mirror.md").write_text(md,encoding="utf-8")
    print("BATTLE377_ALL "+json.dumps(result,ensure_ascii=False,separators=(",",":")))
    print(md)
    print("PASS AI symmetric missions v377 aggregate: 192 pairs, 384 battles, compare original historical without enforcing old winners")

if __name__=="__main__":
    main()
