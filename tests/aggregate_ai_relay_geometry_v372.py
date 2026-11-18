#!/usr/bin/env python3
"""Aggregate only actual Godot v372 relay-layout self-play records.

320 unique combats = 64 crossed environments × 5 relay variants.
No invented games, no imputed winners, no assumed parity.
"""
import json
import pathlib
import sys
from collections import Counter

MARKER = "RELAY372_MATCH "
VARIANTS = ("south_legacy","south_equal","north_equal",
            "four_equal","four_target8_equal")
MAPS = (0,1,2,3)
POLICIES = ("v35","v363")


def gather(folder):
    result=[]
    for file in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in file.read_text(encoding="utf-8",errors="replace").splitlines():
            start=line.find(MARKER+"{")
            if start>=0:
                row=json.loads(line[start+len(MARKER):].strip())
                assert isinstance(row,dict)
                result.append(row)
    return result


def validate(rows):
    needed={(level,map_id,fog,first,policy,variant)
            for level in (10,12) for map_id in MAPS
            for fog in (False,True) for first in (0,1)
            for policy in POLICIES for variant in VARIANTS}
    by_id={}
    for row in rows:
        key=(int(row["level"]),int(row["map"]),bool(row["fog"]),
             int(row["first"]),str(row["mode"]),str(row["variant"]))
        if key in by_id:
            raise SystemExit(f"Duplicated Godot record {key}")
        by_id[key]=row
        variant=key[-1]
        assert variant in VARIANTS
        assert row["balanced_opening"] is True and row["opening_cap"]=="3"
        assert int(row["opening_actions"])==3
        assert len(row["opening_trace"])==3
        assert row["fair_round"] is True and row["round_scoring"] is True
        assert int(row["v363_side"])==-1
        assert row["starting_credits"]==[300,300]
        assert int(row["responder_starting_credits"])==(
            400 if variant=="south_legacy" else 300)
        assert int(row["relay_nodes"])==(4 if variant.startswith("four") else 2)
        assert int(row["relay_target"])==(8 if variant=="four_target8_equal" else 5)
        assert row["layout"]==(
            "four" if variant.startswith("four") else
            ("north" if variant=="north_equal" else "south"))
        assert row["income_variant"]==(
            "keep" if variant=="south_legacy" else "equal")
        assert len(row["relay_first_capture_phase"])==2
        assert len(row["relay_first_score_phase"])==2
        assert len(row["relay_final_owners"])==2
        assert sum(row["relay_final_owners"])+int(row["relay_final_neutral"])==int(row["relay_nodes"])
        assert int(row["relay_final_neutral"])>=0
        for i in (0,1):
            first_capture=int(row["relay_first_capture_phase"][i])
            first_score=int(row["relay_first_score_phase"][i])
            if first_score>=0:
                assert first_capture>=0
                assert first_score>=first_capture
        # Every logged scoreboard must be from a FULL round, with no
        # score decrease and nonnegative owned-node counts.
        last=[0,0]
        for entry in row["relay_round_scores"]:
            assert int(entry["phase"])%2==1
            assert len(entry["scores"])==2 and len(entry["owners"])==2
            for i in (0,1):
                current=int(entry["scores"][i])
                assert current>=last[i]
                assert int(entry["owners"][i])>=0
                assert current-last[i]==int(entry["owners"][i])
                last[i]=current
    if len(rows)!=320 or set(by_id)!=needed:
        raise SystemExit(f"Invalid 320-game matrix got {len(rows)}; "
                         f"missing={sorted(needed-set(by_id))}")

    first3_checks=0
    income_pairs=0
    for level in (10,12):
        for mp in MAPS:
            for fog in (False,True):
                for first in (0,1):
                    for policy in POLICIES:
                        group=(level,mp,fog,first,policy)
                        base=by_id[(*group,"south_legacy")]
                        equal=by_id[(*group,"south_equal")]
                        if base["opening_trace"]!=equal["opening_trace"]:
                            raise SystemExit(f"First3 actions changed due only to income: {group}")
                        first3_checks+=1
                        if base["winner"]!=equal["winner"]:
                            income_pairs+=1

    # Historical 4-map cap3 reference: same default income, same original
    # south relays, same AI/terrain, old 256-game v370 experiment.
    historic={"games":64,"first_wins":22,"second_wins":42,
              "blue_wins":30,"red_wins":34}
    baseline=metrics([r for r in rows if r["variant"]=="south_legacy"])
    if any(baseline[k]!=v for k,v in historic.items()):
        raise SystemExit("Historical 4-map south/legacy control failed: "
                         +str({k:baseline[k] for k in historic}))
    equal_expected={"games":64,"first_wins":22,"second_wins":42,
                    "blue_wins":30,"red_wins":34}
    equal=metrics([r for r in rows if r["variant"]=="south_equal"])
    if any(equal[k]!=v for k,v in equal_expected.items()):
        raise SystemExit("Historical south/equal control failed: "
                         +str({k:equal[k] for k in equal_expected}))
    return {"first_three_equal_checks":first3_checks,
            "income_only_winner_flips":income_pairs,
            "historic_legacy_control":historic,
            "historic_equal_control":equal_expected}


def metrics(rows):
    data={"games":len(rows),"first_wins":0,"second_wins":0,
          "blue_wins":0,"red_wins":0,"censored":0,
          "relay_wins":0,"combat_wins":0,
          "capture_first_before_opponent":0,
          "first_capture_phase":{"0":[],"1":[]},
          "first_score_phase":{"0":[],"1":[]},
          "total_ownership_changes":[0,0],
          "total_city_captures":[0,0],
          "total_purchases":[0,0],
          "total_phases":0,"avg_phases":0,
          "victory_score_lead":[],
          "mean_victory_score_lead":None}
    for r in rows:
        first=int(r["first"])
        second=1-first
        winner=int(r["winner"])
        data["total_phases"]+=int(r["phases"])
        for side in (0,1):
            data["total_ownership_changes"][side]+=int(r["relay_ownership_changes"][side])
            data["total_city_captures"][side]+=int(r["captures"][side])
            data["total_purchases"][side]+=int(r["buys"][side])
            for field in ("first_capture_phase","first_score_phase"):
                moment=int(r["relay_"+field.replace("first_","first_")][side])
                if moment>=0:
                    data[field][str(side)].append(moment)
        captures=r["relay_first_capture_phase"]
        if int(captures[first])>=0 and (
                int(captures[second])<0 or int(captures[first])<int(captures[second])):
            data["capture_first_before_opponent"]+=1
        if winner not in (0,1):
            data["censored"]+=1
            continue
        data["first_wins" if winner==first else "second_wins"]+=1
        data["blue_wins" if winner==0 else "red_wins"]+=1
        data["relay_wins" if r["winner_source"]=="relay" else "combat_wins"]+=1
        scores=[int(x) for x in r["relay_scores"]]
        data["victory_score_lead"].append(scores[winner]-scores[1-winner])
    data["avg_phases"]=round(data["total_phases"]/len(rows),2) if rows else 0
    leads=data["victory_score_lead"]
    data["mean_victory_score_lead"]=round(sum(leads)/len(leads),2) if leads else None
    for name in ("first_capture_phase","first_score_phase"):
        for side in ("0","1"):
            vals=data[name][side]
            data[name][side]={
                "observed":len(vals),
                "mean_phase":round(sum(vals)/len(vals),2) if vals else None,
                "earliest":min(vals) if vals else None,
                "latest":max(vals) if vals else None}
    del data["victory_score_lead"]
    data["initiative_skew"]=abs(data["first_wins"]-data["second_wins"])
    data["color_skew"]=abs(data["blue_wins"]-data["red_wins"])
    return data


def main():
    root=pathlib.Path(sys.argv[1] if len(sys.argv)>1 else ".ci-v372-logs")
    rows=gather(root)
    checks=validate(rows)
    by_variant={}
    for v in VARIANTS:
        selected=[r for r in rows if r["variant"]==v]
        summary=metrics(selected)
        summary["by_map"]={str(mp):metrics(
            [r for r in selected if int(r["map"])==mp]) for mp in MAPS}
        summary["by_policy"]={policy:metrics(
            [r for r in selected if r["mode"]==policy]) for policy in POLICIES}
        by_variant[v]=summary
    rank=sorted(VARIANTS,key=lambda v:(
        by_variant[v]["censored"]!=0,
        by_variant[v]["initiative_skew"],
        by_variant[v]["color_skew"]))
    report={
        "experiment":"TARVOKA v3.7.2 relay geometry and score threshold",
        "source":"320 genuine deterministic Godot 4.3 games, identical AI each side",
        "constraints":{"same_three_order_opening":True,
                       "all_four_10x8_maps":True,
                       "full_round_scoring":True,
                       "symmetric_first_income_except_legacy_control":True,
                       "no_core_engine_or_save_changes":True},
        "quality_gates":checks,
        "by_variant":by_variant,"screening_order":rank,
        "merge_approved":False,
        "warning":"Exploratory. A four-node map has a different capture objective and "
                  "does not establish commercial balance without modern armies, seed maps and humans."
    }
    out=pathlib.Path("reports")
    out.mkdir(exist_ok=True)
    (out/"ai_v372_relay_layouts.json").write_text(
        json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    lines=["# TARVOKA v3.7.2 — geometría y puntuación de relés",
           "","320 partidas reales Godot 4.3, 64 por variante.",
           "Dos o cuatro relés, objetivo de 5 u 8 puntos, todas las rondas completas.",
           "","| Variante | Partidas | Primero | Segundo | Azul | Rojo | Empates/inconclusas |",
           "|---|---:|---:|---:|---:|---:|---:|"]
    for v in VARIANTS:
        x=by_variant[v]
        lines.append(f"| {v} | {x['games']} | {x['first_wins']} | "
                     f"{x['second_wins']} | {x['blue_wins']} | {x['red_wins']} | "
                     f"{x['censored']} |")
    lines.extend(["","## Desglose por mapa","",
           "| Variante | Mapa | Primero | Segundo | Azul | Rojo |",
           "|---|---:|---:|---:|---:|---:|"])
    for v in VARIANTS:
        for mp in MAPS:
            x=by_variant[v]["by_map"][str(mp)]
            lines.append(f"| {v} | {mp} | {x['first_wins']} | "
                         f"{x['second_wins']} | {x['blue_wins']} | {x['red_wins']} |")
    lines.extend(["","## Aseguramiento de calidad",
           f"- Comparaciones de primeras tres órdenes por pareja de ingresos: {checks['first_three_equal_checks']}",
           f"- Cambios de vencedor por ingreso inicial solamente: {checks['income_only_winner_flips']}",
           "- Dos controles históricos con cuatro mapas reproducidos exactamente.",
           "- No se altera ni el tiempo de puntuación ni el motor del videojuego.",
           "- Ninguna mejora experimental autoriza fusión automática ni APK.",""])
    (out/"ai_v372_relay_layouts.md").write_text("\n".join(lines),encoding="utf-8")
    print("RELAY372_ALL "+json.dumps(report,ensure_ascii=False,separators=(",",":")))
    print("\n".join(lines))
    print("PASS relay v372 aggregate: 320 real battles, 64 paired first3 controls, original map baselines")

if __name__=="__main__":
    main()
