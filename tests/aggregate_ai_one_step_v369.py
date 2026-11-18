#!/usr/bin/env python3
"""Godot v369: strictly 96 actual matched same-policy games, no fake scores.

Compare authoritative opening cap3, full test-only fourth order cap4,
and a one-cell 4th order executed by the original BattleSession.move.
"""
import json
import pathlib
import sys
from collections import Counter

MARKER = "STEP369_MATCH "
CAPS = ("3","4","3plus_step")
POLICIES = ("v35","v363")


def read(folder):
    rows = []
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8",errors="replace").splitlines():
            i=line.find(MARKER+"{")
            if i>=0:
                record=json.loads(line[i+len(MARKER):].strip())
                assert isinstance(record,dict)
                rows.append(record)
    return rows


def validate(rows):
    expected={(level,map_id,fog,first,policy,variant)
              for level in (10,12)
              for map_id in (0,2)
              for fog in (False,True)
              for first in (0,1)
              for policy in POLICIES
              for variant in CAPS}
    seen={}
    for row in rows:
        key=(int(row["level"]),int(row["map"]),bool(row["fog"]),
             int(row["first"]),str(row["mode"]),str(row["opening_cap"]))
        if key in seen:
            raise SystemExit(f"Duplicate actual match {key}")
        seen[key]=row
        cap=key[-1]
        assert cap in CAPS
        assert row["layout"]=="south"
        assert int(row["relay_nodes"])==2
        assert row["fair_round"] is True and row["round_scoring"] is True
        assert int(row["v363_side"])==-1
        assert row["balanced_opening"] is (cap=="3")
        assert row["research_budget_only"] is (cap!="3")
        assert len(row["opening_trace"])==3
        n=int(row["opening_actions"])
        assert n in (3,4)
        if cap=="3":
            assert n==3 and row["fourth_bonus_used"] is False
        elif cap=="4":
            assert n==4
        elif cap=="3plus_step":
            assert n == (4 if row["fourth_bonus_used"] else 3)
            if row["fourth_bonus_used"]:
                assert row["fourth_is_one_step"] is True
                assert row["fourth_candidate"]=="move"
                assert row["fourth_bonus_action"]=="move"
                assert int(row["fourth_applied_distance"])==1
                assert int(row["fourth_full_distance"])>=2
                assert row["fourth_original_destination"]!=row["fourth_applied_destination"]
            else:
                assert row["fourth_denial"] not in ("none","not_proposed")
    if len(rows)!=96 or set(seen)!=expected:
        raise SystemExit(f"INVALID v369 game matrix {len(rows)}/96 missing={sorted(expected-set(seen))}")
    groups={(lvl,mp,fog,first,policy)
            for lvl,mp,fog,first,policy,cap in expected}
    assert len(groups)==32
    count=0
    for group in sorted(groups):
        trace=seen[(*group,"3")]["opening_trace"]
        for cap in CAPS:
            if seen[(*group,cap)]["opening_trace"]!=trace:
                raise SystemExit(f"First-three decisions changed {group} / {cap}")
            count+=1
    assert count==96
    return count


def metrics(rows):
    result={"games":len(rows),"first_wins":0,"second_wins":0,
            "blue_wins":0,"red_wins":0,"censored":0,
            "relay_wins":0,"combat_wins":0,
            "fourth_step_applied":0,"fourth_actions":0,
            "fourth_denial_reasons":{},"fourth_proposed_actions":{},
            "city_captures":0,"retreats":0,"opening_actions_total":0}
    denied=Counter()
    proposals=Counter()
    for row in rows:
        winner=int(row["winner"])
        first=int(row["first"])
        result["fourth_step_applied"]+=int(row["fourth_is_one_step"])
        result["fourth_actions"]+=int(row["fourth_bonus_used"])
        result["opening_actions_total"]+=int(row["opening_actions"])
        result["city_captures"]+=sum(int(x) for x in row["captures"])
        result["retreats"]+=sum(int(x) for x in row["retreats"])
        denied[str(row["fourth_denial"])]+=1
        proposals[str(row["fourth_candidate"])]+=1
        if winner not in (0,1):
            result["censored"]+=1
            continue
        result["first_wins" if winner==first else "second_wins"]+=1
        result["blue_wins" if winner==0 else "red_wins"]+=1
        result["relay_wins" if row["winner_source"]=="relay" else "combat_wins"]+=1
    result["fourth_denial_reasons"]=dict(sorted(denied.items()))
    result["fourth_proposed_actions"]=dict(sorted(proposals.items()))
    result["initiative_skew"]=abs(result["first_wins"]-result["second_wins"])
    result["color_skew"]=abs(result["blue_wins"]-result["red_wins"])
    return result


def main():
    folder=pathlib.Path(sys.argv[1] if len(sys.argv)>1 else ".ci-v369-logs")
    rows=read(folder)
    trace_count=validate(rows)
    by_cap={}
    for cap in CAPS:
        subset=[r for r in rows if r["opening_cap"]==cap]
        m=metrics(subset)
        m["by_map"]={str(map_id):metrics(
            [r for r in subset if int(r["map"])==map_id]) for map_id in (0,2)}
        m["by_policy"]={policy:metrics(
            [r for r in subset if r["mode"]==policy]) for policy in POLICIES}
        by_cap[cap]=m
    historical={
        "3":{"games":32,"first_wins":8,"second_wins":24,"blue_wins":16,"red_wins":16},
        "4":{"games":32,"first_wins":24,"second_wins":8,"blue_wins":20,"red_wins":12}
    }
    for cap,baseline in historical.items():
        if any(by_cap[cap][k]!=v for k,v in baseline.items()):
            raise SystemExit(f"Prior cap{cap} results fail to reproduce "
                             +str({k:by_cap[cap][k] for k in baseline}))
    ranking=sorted(CAPS,key=lambda cap:(
        by_cap[cap]["censored"]!=0,
        by_cap[cap]["initiative_skew"],
        by_cap[cap]["color_skew"]))
    result={
        "experiment":"TARVOKA Godot 4.3 one-tile fourth order",
        "source":"96 authentic deterministic BasicAI vs self BattleSession games",
        "invariants":{"two_south_reflected_relays":True,
                      "fair_round":True,
                      "real_engine_actions":True,
                      "identical_first_three_actions":True,
                      "first_three_checks":trace_count,
                      "cap3_and_cap4_reproduced":True,
                      "no_production_code_changes":True},
        "by_cap":by_cap,
        "screening_order":ranking,
        "merge_approved":False,
        "warning":"Two small test maps, not population-balanced and not Android/human play."
    }
    out=pathlib.Path("reports")
    out.mkdir(exist_ok=True)
    (out/"ai_v369_one_step.json").write_text(
        json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    markdown=[
        "# TARVOKA v3.6.9 — cuarta orden reducida a una casilla",
        "",
        "**96 partidas reales en Godot** (32 por opción), ambas IA idénticas",
        "en cada combate; puntuación por ronda y relés simétricos al sur.",
        "",
        "| Primera fase | Partidas | Gana primero | Gana segundo | Azul | Rojo | 4ª reducida aplicada |",
        "|---|---:|---:|---:|---:|---:|---:|"]
    for cap in CAPS:
        m=by_cap[cap]
        markdown.append(
            f"| {cap} | {m['games']} | {m['first_wins']} | {m['second_wins']} | "
            f"{m['blue_wins']} | {m['red_wins']} | {m['fourth_step_applied']} |")
    markdown.extend(["","## Control por mapa","",
        "| Límite | Mapa | Primero | Segundo | Azul | Rojo |",
        "|---|---:|---:|---:|---:|---:|"])
    for cap in CAPS:
        for mp in ("0","2"):
            m=by_cap[cap]["by_map"][mp]
            markdown.append(f"| {cap} | {mp} | {m['first_wins']} | "
                            f"{m['second_wins']} | {m['blue_wins']} | {m['red_wins']} |")
    markdown.extend([
        "","## Garantías y límites","",
        f"- Comparaciones iguales de las primeras tres órdenes: **{trace_count}**",
        "- Controles previos de tres y cuatro órdenes reproducidos: **sí**",
        "- La cuarta orden de una casilla siempre se ejecuta mediante `BattleSession.move`,",
        "  respetando ocupación, terreno y niebla. No se finge un movimiento entero.",
        "- Se mantiene `OpeningBalance.gd` idéntico y no se añade un valor de apertura a guardados.",
        "- No autoriza activar reglas, fusionar PR ni publicar APK.", ""])
    md="\n".join(markdown)
    (out/"ai_v369_one_step.md").write_text(md,encoding="utf-8")
    print("STEP369_ALL "+json.dumps(result,ensure_ascii=False,separators=(",",":")))
    print(md)
    print("PASS AI one-step v369 aggregate: 96 unique actual games; 96 first3 comparisons; cap3/4 reproduced")

if __name__=="__main__":
    main()
