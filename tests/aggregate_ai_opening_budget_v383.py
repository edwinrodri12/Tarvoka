#!/usr/bin/env python3
"""Strict 2-arm paired causal test of TARVOKA large-map opening action budgets.

The game engine is not changed. Test-only voluntary end-turn after the
responder's third legal AI order is the sole intervention. Reflections are
verification replays, never independent outcome samples.
"""
import json
import pathlib
import sys

PREFIX="OPEN383_RESULT "
SEEDS=(630,631,632,633)
MODES=("baseline","matched")

def parse(path):
    records=[]
    for file in sorted(pathlib.Path(path).rglob("*.log")):
        for line in file.read_text(encoding="utf-8",errors="replace").splitlines():
            marker=line.find(PREFIX+"{")
            if marker>=0:
                records.append(json.loads(line[marker+len(PREFIX):]))
    return records

def main(folder):
    rows=parse(folder)
    expected={(seed,fog,first) for seed in SEEDS
              for fog in (False,True) for first in (0,1)}
    found={}
    for row in rows:
        key=(row["seed"],row["fog"],row["first"])
        assert key in expected and key not in found,("unexpected/duplicate",key)
        found[key]=row
        assert row["size"]=="40x30" and row["template"]==row["seed"]%4
        assert row["fog"] in (True,False) and type(row["fog"]) is bool
        assert row["symmetric_income"] is True
        assert row["first_orders"]==3 and row["half_turn_cap"]==32
        assert row["original_battles_per_mode"]==1
        assert row["mirror_battles_per_mode"]==1
        base=row["baseline"]
        matched=row["matched"]
        assert base["starter_first_three_actions"]==matched["starter_first_three_actions"]
        assert base["responder_first_three_actions"]==matched["responder_first_three_actions"]
        assert len(base["starter_first_three_actions"])==3
        assert len(matched["responder_first_three_actions"])==3
        for mode,v in [("baseline",base),("matched",matched)]:
            assert v["mode"] in ("starter3_responder_full","both3_first_round")
            assert (mode=="baseline") == (v["mode"]=="starter3_responder_full")
            assert v["mirror_exact"] is True
            assert v["winner"] in (-1,0,1)
            assert v["terminal"] in ("phase_limit","winner","idle_stalemate")
            assert v["censored"] is (v["winner"]==-1)
            assert v["first_wins"] is (v["winner"]==row["first"])
            assert v["second_wins"] is (v["winner"]==1-row["first"])
            assert (v["terminal"]=="winner") == (v["winner"] in (0,1))
            assert 0<=v["half_turns"]<=32
            assert v["opening_first_orders"]==3
            assert v["opening_response_orders"]>=0
            if mode=="matched":
                assert v["opening_response_orders"]==3
            else:
                assert v["opening_response_orders"]>=3
            assert v["total_actions"]>=0 and v["attacks"]>=0
            assert v["purchases"]>=0 and v["resupplies"]>=0
            assert len(v["signal_end"])==2
            assert v["first_attack_half_turn"]>=-1
            assert v["first_relay_capture_half_turn"]>=-1
            assert v["first_city_capture_half_turn"]>=-1
    assert len(found)==16 and set(found)==expected,(
        "missing matched conditions",len(found),sorted(expected-set(found)))
    by_mode={}
    for mode in MODES:
        items=[r[mode] for r in rows]
        decisive=[v for v in items if not v["censored"]]
        by_mode[mode]={
            "conditions":16,
            "decisive":len(decisive),
            "censored":16-len(decisive),
            "first_wins":sum(v["first_wins"] for v in decisive),
            "second_wins":sum(v["second_wins"] for v in decisive),
            "total_actions":sum(v["total_actions"] for v in items),
            "total_attacks":sum(v["attacks"] for v in items),
            "total_purchases":sum(v["purchases"] for v in items),
            "response_orders":sorted(v["opening_response_orders"] for v in items),
            "winner_first_by_fog":{
                str(fog).lower():sum(r["fog"]==fog and r[mode]["first_wins"]
                    for r in rows) for fog in (False,True)
            },
            "winner_second_by_fog":{
                str(fog).lower():sum(r["fog"]==fog and r[mode]["second_wins"]
                    for r in rows) for fog in (False,True)
            }
        }
        assert by_mode[mode]["decisive"]+by_mode[mode]["censored"]==16
        assert by_mode[mode]["first_wins"]+by_mode[mode]["second_wins"]==by_mode[mode]["decisive"]
    changes=[]
    for r in sorted(rows,key=lambda v:(v["seed"],v["fog"],v["first"])):
        base=r["baseline"]
        eq=r["matched"]
        changes.append({
            "seed":r["seed"],"template":r["template"],"fog":r["fog"],
            "first":r["first"],
            "baseline_response_orders":base["opening_response_orders"],
            "matched_response_orders":eq["opening_response_orders"],
            "baseline_winner":base["winner"],"matched_winner":eq["winner"],
            "baseline_half_turns":base["half_turns"],
            "matched_half_turns":eq["half_turns"],
            "first_result_changed":base["first_wins"]!=eq["first_wins"],
            "baseline_censored":base["censored"],
            "matched_censored":eq["censored"],
            "baseline_attacks":base["attacks"],"matched_attacks":eq["attacks"]
        })
    report={
        "version":"v3.8.3","status":"research_only",
        "question":"Does matching the second player's first-round order cap to the starter's three orders reduce the observed second-mover win imbalance?",
        "scope":"four 40x30 seed templates x fog yes/no x two initiators",
        "independent_paired_conditions":16,
        "real_games":64,
        "independent_outcome_samples_per_mode":16,
        "mirror_replays_per_mode":16,
        "mirrors_not_independent_samples":True,
        "intervention":"voluntarily end responder half-turn after third legal BasicAI action, only in test. First and second sides each use three legal actions on their first opportunity.",
        "engine_rules_changed":False,
        "win_cutoff_half_turns":32,
        "baseline_and_matched_first_three_decisions_identical":True,
        "by_mode":by_mode,
        "conditions":changes,
        "warnings":[
            "A test-only change in voluntary turn-ending behavior is not an approved game design change.",
            "Outcome rates on fixed seeds cannot establish a general win-rate or universal unfairness.",
            "A censored game at 32 half-turns is not a draw.",
            "The same AI for both factions is a test environment, not a human gameplay distribution.",
            "No change to damage, money, opening rules, relay settlement or live APK was deployed."
        ]
    }
    root=pathlib.Path("reports");root.mkdir(parents=True,exist_ok=True)
    (root/"ai_v383_opening_budget.json").write_text(
        json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    md=[
        "# TARVOKA v3.8.3 — Control del presupuesto de apertura",
        "",
        "Matriz de 16 condiciones originales emparejadas por terreno/niebla/iniciador, "
        "cada modo reflejado por separado (64 partidas reales, no 64 muestras independientes).",
        "",
        "| Política inicial | Ganó quien inicia | Ganó quien responde | Sin ganador |",
        "|---|---:|---:|---:|",
    ]
    for mode,label in (("baseline","Actual: 3 frente a respuesta libre"),
                       ("matched","Contrafactual: ambos 3")):
        s=by_mode[mode]
        md.append(f"| {label} | {s['first_wins']} | {s['second_wins']} | {s['censored']} |")
    md += [
        "",
        "- En ambos modos, el iniciador conserva sus tres primeras órdenes, "
        "y las tres primeras decisiones reales de respuesta son idénticas.",
        "- El contrafactual solamente finaliza voluntariamente la primera respuesta "
        "después de tres acciones; se ejecuta el mismo `BattleSession.end_turn`.",
        "- La IA, salarios, captura de relés, puntuación y reglas de combate siguen idénticos.",
        "- Las partidas inconclusas al llegar al límite de 32 medios turnos se reportan "
        "como censuradas, nunca como empates.",
        "",
        "## Diferencias por terreno (resumen del resultado)",
        "",
        "| Semilla | Niebla | Inicia | Respuesta basal: órdenes | Ganador basal | Ganador ambos 3 |",
        "|---|---|---:|---:|---:|---:|"
    ]
    for r in changes:
        md.append(f"| {r['seed']} | {r['fog']} | {r['first']} | "
            f"{r['baseline_response_orders']} | {r['baseline_winner']} | "
            f"{r['matched_winner']} |")
    md += ["", "**Investigación experimental; ninguna regla de producción cambiada, ningún merge.**",""]
    (root/"ai_v383_opening_budget.md").write_text("\n".join(md),encoding="utf-8")
    print("OPEN383_ALL "+json.dumps({k:v for k,v in report.items() if k!="conditions"},
        separators=(",",":"),ensure_ascii=False))
    print("\n".join(md))
    print("PASS TARVOKA v383 aggregate: 16 paired counterfactuals and 64 real mirrored games")

if __name__=="__main__":
    main(sys.argv[1] if len(sys.argv)>1 else ".ci-v383-logs")
