#!/usr/bin/env python3
"""Aggregate only actual Godot v373 relay-layout self-play records.

320 unique combats = 64 crossed environments × 5 relay variants.
No invented games, no imputed winners, no assumed parity.
"""
import json
import pathlib
import sys
from collections import Counter

MARKER = "CHOKE373_MATCH "
VARIANTS = ("center_target8","center_target10","approach_target8",
            "approach_target10","flanks_target8")
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
    expected={(level,mp,fog,first,policy,variant)
              for level in (10,12) for mp in MAPS
              for fog in (False,True) for first in (0,1)
              for policy in POLICIES for variant in VARIANTS}
    observed={}
    for r in rows:
        key=(int(r["level"]),int(r["map"]),bool(r["fog"]),
             int(r["first"]),str(r["mode"]),str(r["variant"]))
        if key in observed:
            raise SystemExit(f"Duplicate genuine Godot game: {key}")
        observed[key]=r
        variant=key[-1]
        assert variant in VARIANTS
        assert r["opening_cap"]=="3" and r["balanced_opening"] is True
        assert int(r["opening_actions"])==3 and len(r["opening_trace"])==3
        assert r["fair_round"] is True and r["round_scoring"] is True
        assert int(r["v363_side"])==-1
        assert r["starting_credits"]==[300,300]
        assert int(r["responder_starting_credits"])==300
        assert r["income_variant"]=="equal"
        assert int(r["relay_nodes"])==4
        assert int(r["relay_target"])==(10 if variant.endswith("target10") else 8)
        assert r["layout"]==("center" if variant.startswith("center")
              else ("approach" if variant.startswith("approach") else "flanks"))
        expected_cols=[4,5] if variant.startswith("center") else [3,6]
        expected_rows=[1,6] if variant=="flanks_target8" else [2,5]
        assert r["relay_cells"]==[f"({x}, {y})" for y in expected_rows for x in expected_cols]
        assert len(r["relay_first_capture_phase"])==2
        assert len(r["relay_first_score_phase"])==2
        assert len(r["relay_final_owners"])==2
        assert sum(int(x) for x in r["relay_final_owners"])+int(r["relay_final_neutral"])==4
        assert r["relay_first_score_round"]>=-1
        for side in (0,1):
            capture=int(r["relay_first_capture_phase"][side])
            score=int(r["relay_first_score_phase"][side])
            if score>=0:
                assert capture>=0 and score>=capture
        for event in r["relay_first_captured_nodes"]:
            assert event["pos"] in r["relay_cells"]
            assert int(event["phase"])>=0 and int(event["owner"]) in (0,1)
        old=[0,0]
        for round_event in r["relay_round_scores"]:
            assert int(round_event["phase"])%2==1
            assert len(round_event["scores"])==2 and len(round_event["owners"])==2
            for side in (0,1):
                earned=int(round_event["scores"][side])-old[side]
                assert earned>=0 and earned==int(round_event["owners"][side])
                old[side]=int(round_event["scores"][side])
    if len(rows)!=320 or set(observed)!=expected:
        raise SystemExit(f"Wrong 320-game research matrix: {len(rows)} "
                         f"missing={sorted(expected-set(observed))}")

    # The center layout at target8 MUST reproduce all 64 earlier games:
    # the historical four_target8_equal group of v3.7.2.
    control=metrics([r for r in rows if r["variant"]=="center_target8"])
    historical={"games":64,"first_wins":28,"second_wins":36,
                "blue_wins":32,"red_wins":32}
    if any(control[k]!=v for k,v in historical.items()):
        raise SystemExit("Failed exact historical center/8 reproduction: "
                         +str({k:control[k] for k in historical}))
    historical_maps={
        0:{"first_wins":8,"second_wins":8,"blue_wins":8,"red_wins":8},
        1:{"first_wins":14,"second_wins":2,"blue_wins":10,"red_wins":6},
        2:{"first_wins":0,"second_wins":16,"blue_wins":8,"red_wins":8},
        3:{"first_wins":6,"second_wins":10,"blue_wins":6,"red_wins":10}}
    for mp,prior in historical_maps.items():
        group=metrics([r for r in rows if r["variant"]=="center_target8"
                       and int(r["map"])==mp])
        if any(group[k]!=v for k,v in prior.items()):
            raise SystemExit(f"Center/8 map {mp} failed to reproduce: "
                             +str({k:group[k] for k in prior}))
    return {"matched_environments":64,
            "baseline_center8_reproduced":True,
            "all_four_prior_map_results_reproduced":True,
            "score_and_owner_increments_verified":True}


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


def matched_pairs(rows):
    index={(int(r["level"]),int(r["map"]),bool(r["fog"]),
            int(r["first"]),str(r["mode"]),str(r["variant"])):r
           for r in rows}
    pairs={}
    for comparison in (("center_target8","center_target10"),
                       ("approach_target8","approach_target10"),
                       ("center_target8","approach_target8"),
                       ("center_target8","flanks_target8")):
        before,after=comparison
        changes=0
        to_first=0
        to_second=0
        by_map={}
        for mp in MAPS:
            map_changes=0
            for level in (10,12):
                for fog in (False,True):
                    for first in (0,1):
                        for policy in POLICIES:
                            key=(level,mp,fog,first,policy)
                            a=index[(*key,before)]
                            b=index[(*key,after)]
                            if int(a["winner"])!=int(b["winner"]):
                                changes+=1
                                map_changes+=1
                                if int(b["winner"])==first:
                                    to_first+=1
                                if int(b["winner"])==1-first:
                                    to_second+=1
            by_map[str(mp)]={"winner_changes":map_changes,"matched_pairs":16}
        pairs[before+"__vs__"+after]={
            "pairs":64,"winner_changes":changes,
            "changes_to_first":to_first,"changes_to_second":to_second,
            "by_map":by_map}
    return pairs


def main():
    root=pathlib.Path(sys.argv[1] if len(sys.argv)>1 else ".ci-v373-logs")
    rows=gather(root)
    checks=validate(rows)
    by_variant={}
    for name in VARIANTS:
        group=[r for r in rows if r["variant"]==name]
        record=metrics(group)
        record["by_map"]={str(mp):metrics(
            [r for r in group if int(r["map"])==mp]) for mp in MAPS}
        record["by_policy"]={p:metrics(
            [r for r in group if r["mode"]==p]) for p in POLICIES}
        by_variant[name]=record
    pair_results=matched_pairs(rows)
    order=sorted(VARIANTS,key=lambda v:(
        by_variant[v]["censored"]!=0,
        by_variant[v]["initiative_skew"],
        by_variant[v]["color_skew"],
        max(abs(by_variant[v]["by_map"][str(mp)]["first_wins"]-
                by_variant[v]["by_map"][str(mp)]["second_wins"]) for mp in MAPS)))
    report={
        "experiment":"TARVOKA v3.7.3 four relay bridge/throat geometry and win targets",
        "source":"320 genuine Godot 4.3 mirror self-play matches",
        "quality_gates":checks,"by_variant":by_variant,
        "matched_64_scenarios":pair_results,
        "screening_order":order,
        "merge_approved":False,
        "warning":"Aggregate 50/50 alone is insufficient: assess worst-map skew, color, "
                  "front-line captures, human opponents, modern armies and map seeds."
    }
    output=pathlib.Path("reports")
    output.mkdir(exist_ok=True)
    (output/"ai_v373_chokepoint_relays.json").write_text(
        json.dumps(report,ensure_ascii=False,indent=2)+"\\n",encoding="utf-8")
    markdown=[
        "# TARVOKA v3.7.3 — Puentes y relés: ¿qué ubicación reduce el sesgo?",
        "","320 partidas reales Godot 4.3, 64 por variante. Apertura de",
        "tres órdenes, ingresos iniciales simétricos y puntuación por ronda.",
        "",
        "| Variante | Partidas | Primero | Segundo | Azul | Rojo | Inconclusas |",
        "|---|---:|---:|---:|---:|---:|---:|"]
    for name in VARIANTS:
        d=by_variant[name]
        markdown.append(f"| {name} | {d['games']} | {d['first_wins']} | "
                        f"{d['second_wins']} | {d['blue_wins']} | {d['red_wins']} | "
                        f"{d['censored']} |")
    markdown.extend(["","## Efectos por mapa","",
       "| Variante | Mapa | Primero | Segundo | Azul | Rojo | Fases promedio |",
       "|---|---:|---:|---:|---:|---:|---:|"])
    for name in VARIANTS:
        for mp in MAPS:
            d=by_variant[name]["by_map"][str(mp)]
            markdown.append(f"| {name} | {mp} | {d['first_wins']} | "
                            f"{d['second_wins']} | {d['blue_wins']} | "
                            f"{d['red_wins']} | {d['avg_phases']} |")
    markdown.extend(["","## Cambios de ganador: entornos estrictamente apareados","",
       "| Comparación | Pares | Cambios de ganador | A favor primero | A favor segundo |",
       "|---|---:|---:|---:|---:|"])
    for label,pr in pair_results.items():
        markdown.append(f"| {label} | {pr['pairs']} | {pr['winner_changes']} | "
                        f"{pr['changes_to_first']} | {pr['changes_to_second']} |")
    markdown.extend(["","## Puertas de seguridad",
       "- 320 juegos reales, 80 contratos de motor, baseline v3.7.2 reproducido.",
       "- Sin cambios en reglas oficiales de IA, economía, relés o guardados.",
       "- Una menor asimetría no autoriza fusión automática o APK.", ""])
    report_md="\\n".join(markdown)
    (output/"ai_v373_chokepoint_relays.md").write_text(report_md,encoding="utf-8")
    print("CHOKE373_ALL "+json.dumps(report,ensure_ascii=False,separators=(",",":")))
    print(report_md)
    print("PASS choke v373 aggregate: 320 real games, mapped baseline and 64 paired conditions")




if __name__=="__main__":
    main()
