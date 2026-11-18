#!/usr/bin/env python3
"""TARVOKA v3.7.0: 256 actual Godot BattleSession games.

Isolate whether retaining or skipping ONLY the responding player's first
city-income payout changes outcomes. Same rosters, AI, opening rules,
two south relays and full-round scoring, on all four prototype maps.
"""
import json
import pathlib
import sys
from collections import Counter

MARKER = "INCOME370_MATCH "
OPENINGS = ("3","4")
INCOME = ("keep","skip")
POLICIES = ("v35","v363")
MAPS = (0,1,2,3)
INITIAL_CREDITS = 300
FIRST_PAYOUT = 100


def load(folder):
    rows=[]
    for p in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in p.read_text(encoding="utf-8",errors="replace").splitlines():
            i=line.find(MARKER+"{")
            if i>=0:
                row=json.loads(line[i+len(MARKER):].strip())
                if not isinstance(row,dict):
                    raise SystemExit("Invalid Godot match record")
                rows.append(row)
    return rows


def validate(rows):
    expected={(level,map_id,fog,first,policy,cap,income)
              for level in (10,12) for map_id in MAPS
              for fog in (False,True) for first in (0,1)
              for policy in POLICIES for cap in OPENINGS for income in INCOME}
    seen={}
    for m in rows:
        key=(int(m["level"]),int(m["map"]),bool(m["fog"]),
             int(m["first"]),str(m["mode"]),str(m["opening_cap"]),
             str(m["income_variant"]))
        if key in seen:
            raise SystemExit(f"Duplicated real game: {key}")
        seen[key]=m
        cap=key[-2]
        income=key[-1]
        assert cap in OPENINGS and income in INCOME
        assert m["layout"]=="south"
        assert m["fair_round"] is True and m["round_scoring"] is True
        assert m["balanced_opening"] is (cap=="3")
        assert m["research_budget_only"] is (cap=="4")
        assert int(m["relay_nodes"])==2 and int(m["v363_side"])==-1
        assert m["starting_credits"] == [INITIAL_CREDITS,INITIAL_CREDITS]
        assert int(m["responder_first_payout"]) == FIRST_PAYOUT
        assert int(m["responder_income_removed"]) == (
            FIRST_PAYOUT if income=="skip" else 0)
        assert int(m["responder_starting_credits"]) == (
            INITIAL_CREDITS if income=="skip" else INITIAL_CREDITS+FIRST_PAYOUT)
        assert int(m["first_next_turn_income"])>=FIRST_PAYOUT
        assert int(m["opening_actions"])==int(cap)
        assert len(m["opening_trace"])==3
    if len(rows)!=256 or set(seen)!=expected:
        raise SystemExit(f"INVALID v370 match matrix {len(rows)}/256 "
                         f"missing={sorted(expected-set(seen))}")

    groups={(level,mp,fog,first,policy) for
            level,mp,fog,first,policy,cap,income in expected}
    assert len(groups)==64
    first3_checks=0
    for group in sorted(groups):
        baseline=seen[(*group,"3","keep")]["opening_trace"]
        for cap in OPENINGS:
            for income in INCOME:
                record=seen[(*group,cap,income)]
                if record["opening_trace"]!=baseline:
                    raise SystemExit("FIRST THREE DECISIONS CHANGED: "+str((*group,cap,income)))
                first3_checks+=1
    assert first3_checks==256
    return seen, first3_checks


def metrics(rows):
    result={"games":len(rows),"first_wins":0,"second_wins":0,
            "blue_wins":0,"red_wins":0,"censored":0,
            "relay_wins":0,"combat_wins":0,
            "first_city_captures":0,"second_city_captures":0,
            "first_purchases":0,"second_purchases":0,
            "first_retreats":0,"second_retreats":0,
            "mean_phases":0,"total_phases":0,
            "start_first_credit":INITIAL_CREDITS,
            "start_responder_credit":None,
            "responder_initial_payout":FIRST_PAYOUT,
            "responder_payout_removed":None}
    for m in rows:
        winner=int(m["winner"])
        first=int(m["first"])
        second=1-first
        if result["start_responder_credit"] is None:
            result["start_responder_credit"]=int(m["responder_starting_credits"])
            result["responder_payout_removed"]=int(m["responder_income_removed"])
        else:
            assert result["start_responder_credit"] == int(m["responder_starting_credits"])
            assert result["responder_payout_removed"] == int(m["responder_income_removed"])
        result["first_city_captures"]+=int(m["captures"][first])
        result["second_city_captures"]+=int(m["captures"][second])
        result["first_purchases"]+=int(m["buys"][first])
        result["second_purchases"]+=int(m["buys"][second])
        result["first_retreats"]+=int(m["retreats"][first])
        result["second_retreats"]+=int(m["retreats"][second])
        result["total_phases"]+=int(m["phases"])
        if winner not in (0,1):
            result["censored"]+=1
            continue
        result["first_wins" if winner==first else "second_wins"]+=1
        result["blue_wins" if winner==0 else "red_wins"]+=1
        result["relay_wins" if m["winner_source"]=="relay" else "combat_wins"]+=1
    result["mean_phases"]=round(result["total_phases"]/len(rows),2) if rows else None
    result["initiative_skew"]=abs(result["first_wins"]-result["second_wins"])
    result["color_skew"]=abs(result["blue_wins"]-result["red_wins"])
    return result


def main():
    folder=pathlib.Path(sys.argv[1] if len(sys.argv)>1 else ".ci-v370-logs")
    rows=load(folder)
    seen,first3_checks=validate(rows)
    by_opening={}
    for cap in OPENINGS:
        by_income={}
        for income in INCOME:
            selected=[r for r in rows if r["opening_cap"]==cap and r["income_variant"]==income]
            subset=metrics(selected)
            subset["by_map"]={str(mp):metrics([r for r in selected if int(r["map"])==mp])
                              for mp in MAPS}
            subset["by_policy"]={policy:metrics([r for r in selected if r["mode"]==policy])
                                 for policy in POLICIES}
            by_income[income]=subset
        by_opening[cap]=by_income

    # Reproduce the 32 historical two-map v369 baselines, NOT all 4 maps.
    refs={
        "3":{"first_wins":8,"second_wins":24,"blue_wins":16,"red_wins":16},
        "4":{"first_wins":24,"second_wins":8,"blue_wins":20,"red_wins":12}
    }
    for cap,baseline in refs.items():
        actual=metrics([m for m in rows if m["opening_cap"]==cap
                        and m["income_variant"]=="keep" and int(m["map"]) in (0,2)])
        assert actual["games"]==32
        if any(actual[k]!=v for k,v in baseline.items()):
            raise SystemExit(f"Historical v369 cap{cap} not reproduced: "
                             +str({k:actual[k] for k in baseline}))

    pairs={"total":0,"same_winner":0,"winner_changed":0,"uncensored_flips":0,
           "improved_first":0,"improved_second":0,
           "second_purchase_changes":0,"second_capture_changes":0,
           "total_second_purchase_delta_skip_minus_keep":0,
           "by_opening":{},"by_map":{}}
    for cap in OPENINGS:
        pairs["by_opening"][cap]={"pairs":0,"winner_changed":0,"improved_first":0,"improved_second":0}
    for mp in MAPS:
        pairs["by_map"][str(mp)]={"pairs":0,"winner_changed":0}
    for level in (10,12):
        for mp in MAPS:
            for fog in (False,True):
                for first in (0,1):
                    for policy in POLICIES:
                        for cap in OPENINGS:
                            key=(level,mp,fog,first,policy,cap)
                            keep=seen[(*key,"keep")]
                            skip=seen[(*key,"skip")]
                            pairs["total"]+=1
                            pairs["by_opening"][cap]["pairs"]+=1
                            pairs["by_map"][str(mp)]["pairs"]+=1
                            changed=int(keep["winner"])!=int(skip["winner"])
                            if changed:
                                pairs["winner_changed"]+=1
                                pairs["by_opening"][cap]["winner_changed"]+=1
                                pairs["by_map"][str(mp)]["winner_changed"]+=1
                                if int(keep["winner"]) in (0,1) and int(skip["winner"]) in (0,1):
                                    pairs["uncensored_flips"]+=1
                                if int(skip["winner"])==first:
                                    pairs["improved_first"]+=1
                                    pairs["by_opening"][cap]["improved_first"]+=1
                                elif int(skip["winner"])==1-first:
                                    pairs["improved_second"]+=1
                                    pairs["by_opening"][cap]["improved_second"]+=1
                            else:
                                pairs["same_winner"]+=1
                            second=1-first
                            buy_delta=int(skip["buys"][second])-int(keep["buys"][second])
                            pairs["total_second_purchase_delta_skip_minus_keep"]+=buy_delta
                            pairs["second_purchase_changes"]+=int(buy_delta!=0)
                            pairs["second_capture_changes"]+=int(
                                int(skip["captures"][second])!=int(keep["captures"][second]))
    assert pairs["total"]==128

    summary={
        "experiment":"TARVOKA v3.7.0 neutralize first responder city-income windfall",
        "source":"256 genuine Godot 4.3 self-play matches across all 4 prototype maps",
        "verified_facts":{"opening_first_credit":INITIAL_CREDITS,
                          "original_responder_first_credit":INITIAL_CREDITS+FIRST_PAYOUT,
                          "experimental_responder_first_credit":INITIAL_CREDITS,
                          "single_removed_first_reply_payout":FIRST_PAYOUT,
                          "later_city_income_unchanged":True,
                          "first_three_action_comparisons":first3_checks,
                          "baseline_cap3_cap4_on_maps0_2_reproduced":True},
        "by_opening":by_opening,
        "matched_128_scenarios":pairs,
        "merge_approved":False,
        "caveat":"Only two AI policies against themselves and four 10x8 prototype terrains; "
                 "the variant deliberately edits only test state on first responder handoff, "
                 "not production balance. Human/modern/large maps and actual Android UI are untested."
    }
    out=pathlib.Path("reports")
    out.mkdir(exist_ok=True)
    (out/"ai_v370_first_income.json").write_text(
        json.dumps(summary,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    markdown=[
        "# TARVOKA v3.7.0 — pago inicial del segundo jugador",
        "",
        "**256 combates reales de Godot 4.3**, 128 pares de escenarios",
        "que solo difieren por el ingreso de la primera oportunidad del segundo jugador.",
        "",
        "| Apertura | Segundo recibe primer ingreso | Partidas | Primero gana | Segundo gana | Azul | Rojo | Inconclusas |",
        "|---|---|---:|---:|---:|---:|---:|---:|"]
    for cap in OPENINGS:
        for income in INCOME:
            m=by_opening[cap][income]
            markdown.append(f"| {cap} órdenes | {'Sí' if income=='keep' else 'No'} | "
                            f"{m['games']} | {m['first_wins']} | {m['second_wins']} | "
                            f"{m['blue_wins']} | {m['red_wins']} | {m['censored']} |")
    markdown.extend(["","## Pares de escenarios y causalidad controlada","",
        f"- Pares reales: **{pairs['total']}**",
        f"- Cambios de ganador cuando se quita el pago: **{pairs['winner_changed']}**",
        f"- Cambios de compras del segundo jugador: **{pairs['second_purchase_changes']}**",
        f"- Cambios de capturas del segundo jugador: **{pairs['second_capture_changes']}**",
        f"- Secuencias idénticas en las primeras tres órdenes: **{first3_checks}**",
        "- Ingresos posteriores de ambos bandos intactos; 32 casos de contrato de motor.",
        "- Comparación histórica de los mapas 0 y 2 preservada y verificada.",
        "","## Desglose por mapa y apertura","",
        "| Órdenes | Primer ingreso del segundo | Mapa | Primero | Segundo | Azul | Rojo |",
        "|---|---|---:|---:|---:|---:|---:|"])
    for cap in OPENINGS:
        for income in INCOME:
            for mp in MAPS:
                m=by_opening[cap][income]["by_map"][str(mp)]
                markdown.append(f"| {cap} | {'Sí' if income=='keep' else 'No'} | {mp} | "
                                f"{m['first_wins']} | {m['second_wins']} | "
                                f"{m['blue_wins']} | {m['red_wins']} |")
    markdown.extend(["","## Decisión","",
        "Este resultado NO cambia el motor ni confirma equilibrio definitivo.",
        "No fusionar ni publicar APK basada en este ensayo sin evaluar otras",
        "facciones, humanos, más mapas, compatibilidad de guardado y UI.", ""])
    note="\n".join(markdown)
    (out/"ai_v370_first_income.md").write_text(note,encoding="utf-8")
    print("INCOME370_ALL "+json.dumps(summary,ensure_ascii=False,separators=(",",":")))
    print(note)
    print("PASS AI first-income v370 aggregate: 256 genuine games, 128 matched pairs, 256 first3 traces and old baselines")


if __name__=="__main__":
    main()
