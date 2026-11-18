#!/usr/bin/env python3
"""TARVOKA v3.9.4 - strict independent no-fog bridge opening comparison.

Eight type-2 seeds: two previously studied and six holdouts. Each seed has
two initiators, three policy variants, and one deterministic mirror of each.
Mirrors are parity checks only, not outcome observations.
"""
import json
import pathlib
import sys

PREFIX = "BRIDGE394_RESULT "
SEEDS = (634,638,642,646,650,654,658,662)
REFERENCES = {634,638}
POLICIES = ("official","cap3","cap5")

def read(folder):
    results={}
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8",errors="replace").splitlines():
            pos=line.find(PREFIX+"{")
            if pos<0:
                continue
            row=json.loads(line[pos+len(PREFIX):])
            key=(row["seed"],row["first"])
            assert key not in results and key[0] in SEEDS and key[1] in (0,1),key
            assert row["version"]=="v3.9.4"
            assert row["template"]==2 and row["fog"] is False and row["size"]=="40x30"
            assert row["reference"] is (row["seed"] in REFERENCES)
            assert row["horizon"]==40 and row["policies"]==list(POLICIES)
            assert row["original_conditions_per_policy"]==1
            assert row["mirrors_validation_only"] is True
            assert row["baseline_rules_official"] is True
            assert row["candidate_first_response_ends_early_test_only"] is True
            assert row["production_changes"] is False
            for p,orders in (("official",8),("cap3",3),("cap5",5)):
                g=row[p]
                assert g["policy"]==p
                assert g["response_first_orders"]==orders
                assert g["mirrored_exact"] is True
                assert g["winner"] in (-1,0,1)
                assert g["starter_wins"] is (g["winner"]==row["first"])
                assert g["responder_wins"] is (g["winner"]==1-row["first"])
                assert g["censored"] is (g["winner"]==-1)
                assert g["terminal"] in ("winner","phase_limit","idle_stalemate")
                assert (g["terminal"]=="winner") is (g["winner"]!=-1)
                assert 0<g["half_turns"]<=40
                assert g["actions"]>=0 and g["attacks"]>=0 and g["purchases"]>=0
                assert len(g["opening_three"])==3
                assert len(g["responder_first_three"])==3
                assert len(g["responder_first_five"])==min(orders,5)
                led=g["ledger"]
                assert led["completed_phases"]==g["half_turns"]
                assert led["end_scores"]==g["ledger"]["end_scores"]
                assert len(led["end_scores"])==2
                assert len(led["first_capture_phase"])==2
                assert len(led["first_city_phase"])==2
                assert led["captured_relays"]==[
                    sum(e["side"]==side for e in led["first_captures"])
                    for side in (0,1)
                ] or sum(led["captured_relays"])>8 # event list capped to 8
                for e in led["first_captures"]:
                    assert e["side"] in (0,1) and e["phase"]>=0
                for round_entry in led["early_round_signal"]:
                    assert round_entry["round"]>=1
                    assert len(round_entry["scores"])==2
                    assert len(round_entry["owned"])==2
                    assert sum(round_entry["owned"])<=4
            off=row["official"]
            assert off["responder_wins"] and off["half_turns"]==12
            assert off["ledger"]["first_capture_phase"][1-row["first"]]==7
            assert off["ledger"]["first_city_phase"]==[-1,-1]
            assert off["opening_three"]==row["cap3"]["opening_three"]==row["cap5"]["opening_three"]
            assert off["responder_first_three"]==row["cap3"]["responder_first_three"]
            assert off["responder_first_five"]==row["cap5"]["responder_first_five"]
            results[key]=row
    expected={(seed,first) for seed in SEEDS for first in (0,1)}
    assert set(results)==expected,("missing/extra",sorted(expected-set(results)))
    return [results[key] for key in sorted(expected)]

def reduce(rows,p):
    games=[r[p] for r in rows]
    return {
        "genuine_original_conditions":len(rows),
        "decisive":sum(not g["censored"] for g in games),
        "censored":sum(g["censored"] for g in games),
        "starter_wins":sum(g["starter_wins"] for g in games),
        "responder_wins":sum(g["responder_wins"] for g in games),
        "total_half_turns":sum(g["half_turns"] for g in games),
        "mean_half_turns":sum(g["half_turns"] for g in games)/len(games),
        "starter_ever_captured_a_relay":sum(g["ledger"]["first_capture_phase"][r["first"]]>=0 for r,g in zip(rows,games)),
        "responder_ever_captured_a_relay":sum(g["ledger"]["first_capture_phase"][1-r["first"]]>=0 for r,g in zip(rows,games)),
        "starter_captured_first":sum(
            g["ledger"]["first_capture_phase"][r["first"]]>=0 and
            (g["ledger"]["first_capture_phase"][1-r["first"]]==-1 or
             g["ledger"]["first_capture_phase"][r["first"]] <
             g["ledger"]["first_capture_phase"][1-r["first"]])
            for r,g in zip(rows,games)
        ),
        "responder_captured_first":sum(
            g["ledger"]["first_capture_phase"][1-r["first"]]>=0 and
            (g["ledger"]["first_capture_phase"][r["first"]]==-1 or
             g["ledger"]["first_capture_phase"][1-r["first"]] <
             g["ledger"]["first_capture_phase"][r["first"]])
            for r,g in zip(rows,games)
        )
    }

def main(folder):
    rows=read(folder)
    unseen=[r for r in rows if r["seed"] not in REFERENCES]
    reference=[r for r in rows if r["seed"] in REFERENCES]
    assert len(rows)==16 and len(unseen)==12 and len(reference)==4
    summary={
        "version":"v3.9.4",
        "status":"test_only_counterfactual_not_approved_for_gameplay",
        "question":"Is the observed no-fog double-bridge responder advantage dependent on the 8-action first response?",
        "map_template":2,
        "fog":False,
        "seeds":list(SEEDS),
        "out_of_sample_seeds":sorted(set(SEEDS)-REFERENCES),
        "reference_seeds":sorted(REFERENCES),
        "genuine_conditions_per_policy":16,
        "genuine_out_of_sample_conditions_per_policy":12,
        "authoritative_games_with_mirrors":96,
        "mirror_only_for_parity":True,
        "official_opening_preserved_for_baseline":True,
        "candidate_early_turn_end_only_test":True,
        "production_changes":False,
        "half_turn_cap":40,
        "by_policy":{p:reduce(rows,p) for p in POLICIES},
        "out_of_sample":{p:reduce(unseen,p) for p in POLICIES},
        "reference":{p:reduce(reference,p) for p in POLICIES},
        "per_seed":{
            str(seed):{p:reduce([r for r in rows if r["seed"]==seed],p) for p in POLICIES}
            for seed in SEEDS
        },
        "cases_changed_winner_vs_official":{
            p:sum(r[p]["winner"]!=r["official"]["winner"] for r in rows)
            for p in ("cap3","cap5")
        },
        "cases_changed_first_relay_capturer":{
            p:sum(
                (r[p]["ledger"]["first_capture_phase"][r["first"]] <
                 r[p]["ledger"]["first_capture_phase"][1-r["first"]])
                 !=
                (r["official"]["ledger"]["first_capture_phase"][r["first"]] <
                 r["official"]["ledger"]["first_capture_phase"][1-r["first"]])
                for r in rows if -1 not in r[p]["ledger"]["first_capture_phase"] and
                -1 not in r["official"]["ledger"]["first_capture_phase"])
            for p in ("cap3","cap5")
        },
        "warnings":[
            "The only tested intervention is ending the responder's FIRST turn after 3 or 5 legal orders instead of the official 8. All later turns use identical real rules.",
            "Counterfactual restrictions are NOT recommended as new opening rules; v3.8.8 found cap5 ineffective on broader maps.",
            "N=16 by policy, including 12 out-of-sample mirrored-starter conditions; starter identities on a seed are correlated.",
            "Mirrored runs verify full deterministic parity only and do not multiply sample size.",
            "A 40-half-turn unresolved game remains censored and is not a draw.",
            "No changes to production AI, scoring, terrain, credits, unit stats, battle rules, APK or main."
        ]
    }
    out=pathlib.Path("reports")
    out.mkdir(parents=True,exist_ok=True)
    (out/"ai_v394_bridge_response_budget.json").write_text(
        json.dumps({"summary":summary,"cases":rows},ensure_ascii=False,indent=2)+"\n",
        encoding="utf-8")
    md=[
        "# TARVOKA v3.9.4 — ¿El primer turno largo del respondedor decide los puentes?",
        "",
        "Mapas de dos puentes 40×30 **sin niebla**. Ocho semillas (6 nuevas), "
        "ambos colores iniciadores. Las reglas oficiales se usan en el control; "
        "en experimentos se termina voluntariamente solo la PRIMERA respuesta "
        "después de 3 o 5 órdenes. Se ejecutaron 96 partidas, incluyendo reflejos "
        "que NO cuentan como muestras independientes.",
        "",
        "| Política | Primero gana | Segundo gana | Sin ganador | Primero captura relé primero | Media medios turnos |",
        "|---|---:|---:|---:|---:|---:|"
    ]
    for p in POLICIES:
        stat=summary["by_policy"][p]
        md.append(
            f"| {p} | {stat['starter_wins']} | {stat['responder_wins']} | "
            f"{stat['censored']} | {stat['starter_captured_first']} | "
            f"{stat['mean_half_turns']:.1f} |")
    md += ["","## Solo semillas nuevas (642–662)","",
        "| Política | Primero gana | Segundo gana | Censuradas | Captura primero |",
        "|---|---:|---:|---:|---:|"]
    for p in POLICIES:
        stat=summary["out_of_sample"][p]
        md.append(
            f"| {p} | {stat['starter_wins']} | {stat['responder_wins']} | "
            f"{stat['censored']} | {stat['starter_captured_first']} |")
    md += ["",
        "Las restricciones de 3/5 órdenes son SOLO experimentales; "
        "no se propone incorporarlas al juego. El código guardará las capturas "
        "de cada relé y los abonos de señal por ronda.",
        "",
        "**Conclusiones sobre causalidad limitadas a la primera respuesta, estas "
        "semillas y esta IA; el resultado no aprueba ninguna regla nueva.**",""]
    (out/"ai_v394_bridge_response_budget.md").write_text("\n".join(md),encoding="utf-8")
    print("BRIDGE394_ALL "+json.dumps(summary,ensure_ascii=False,separators=(",",":")))
    print("\n".join(md))
    print("PASS TARVOKA v394 aggregate: 16 original conditions x 3 response policies x exact mirrors")

if __name__=="__main__":
    main(sys.argv[1] if len(sys.argv)>1 else ".ci-v394-logs")
