#!/usr/bin/env python3
"""Strict aggregation of two intermediate opening caps from 16 paired states.

Only original games count as outcome samples. Mirrored replays are
proofs of deterministic parity, never additional independent trials.
"""
import json
import pathlib
import sys

PREFIX="BUDGET387_RESULT "
SEEDS=(630,631,632,633)
CAPS=(4,5)

def read_cases(folder):
    rows=[]
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8",errors="replace").splitlines():
            at=line.find(PREFIX+"{")
            if at>=0:
                rows.append(json.loads(line[at+len(PREFIX):]))
    return rows

def check_game(r,v,cap):
    assert v["response_cap"]==cap
    assert v["winner"] in (-1,0,1)
    assert v["censored"] is (v["winner"]==-1)
    assert v["winner_is_first"] is (v["winner"]==r["first"])
    assert v["winner_is_responder"] is (v["winner"]==1-r["first"])
    assert v["terminal"] in ("winner","phase_limit","idle_stalemate")
    assert (v["terminal"]=="winner") == (v["winner"]>=0)
    assert v["first_turn_orders"]==3
    assert v["responder_first_turn_orders"]==cap
    assert 0<=v["completed_half_turns"]<=32
    assert v["total_actions"]>=0 and v["attacks"]>=0
    assert v["purchases"]>=0 and v["moves"]>=0 and v["resupplies"]>=0
    assert len(v["relay_scores"])==2
    assert len(v["starting_three"])==3 and len(v["responding_four"])==4
    assert v["mirrored_exact"] is True
    for field in ("first_attack_phase","first_relay_phase","first_city_phase"):
        assert int(v[field])>=-1
    return v

def summary(pairs,cap):
    vs=[r[f"cap{cap}"] for r in pairs]
    winners=[v for v in vs if v["winner"]>=0]
    return {
        "conditions":len(vs),
        "decisive":len(winners),
        "censored":len(vs)-len(winners),
        "first_wins":sum(v["winner_is_first"] for v in winners),
        "responder_wins":sum(v["winner_is_responder"] for v in winners),
        "actions":sum(v["total_actions"] for v in vs),
        "attacks":sum(v["attacks"] for v in vs),
        "purchases":sum(v["purchases"] for v in vs),
        "moves":sum(v["moves"] for v in vs),
        "mean_completed_half_turns":round(sum(v["completed_half_turns"] for v in vs)/len(vs),3),
        "real_games_with_attack":sum(v["first_attack_phase"]>=0 for v in vs),
        "real_games_with_relay":sum(v["first_relay_phase"]>=0 for v in vs)
    }

def main(folder):
    rows=read_cases(folder)
    expected={(seed,fog,first) for seed in SEEDS
              for fog in (False,True) for first in (0,1)}
    found={}
    for r in rows:
        key=(r["seed"],r["fog"],r["first"])
        assert key in expected and key not in found,("duplicate/missing",key)
        found[key]=r
        assert r["template"]==r["seed"]%4 and r["size"]=="40x30"
        assert type(r["fog"]) is bool and r["cap_starter"]==3
        assert r["half_turn_limit"]==32
        assert r["production_rules_changed"] is False
        assert r["symmetric_initial_income"] is True
        assert r["independent_paired_conditions"]==1
        assert r["mirrored_replays_per_policy"]==1
        a=check_game(r,r["cap4"],4)
        b=check_game(r,r["cap5"],5)
        assert a["starting_three"]==b["starting_three"]
        assert a["responding_four"]==b["responding_four"]
    assert len(rows)==16 and set(found)==expected,(
        "incomplete experimental matrix",len(rows),sorted(expected-set(found)))
    rows=[found[k] for k in sorted(expected)]
    summary_all={str(cap):summary(rows,cap) for cap in CAPS}
    by_fog={}
    for fog in (False,True):
        subset=[r for r in rows if r["fog"]==fog]
        by_fog[str(fog).lower()]={str(cap):summary(subset,cap) for cap in CAPS}
    by_template={}
    for template in range(4):
        subset=[r for r in rows if r["template"]==template]
        by_template[str(template)]={str(cap):summary(subset,cap) for cap in CAPS}
    cases=[]
    changed=0
    for r in rows:
        a,b=r["cap4"],r["cap5"]
        difference=a["winner"]!=b["winner"]
        changed+=int(difference)
        cases.append({
            "seed":r["seed"],"template":r["template"],"fog":r["fog"],"first":r["first"],
            "cap4_winner":a["winner"],"cap5_winner":b["winner"],
            "cap4_first_wins":a["winner_is_first"],
            "cap5_first_wins":b["winner_is_first"],
            "cap4_censored":a["censored"],"cap5_censored":b["censored"],
            "result_changes":difference,
            "cap4_half_turns":a["completed_half_turns"],
            "cap5_half_turns":b["completed_half_turns"],
            "cap4_relay_scores":a["relay_scores"],
            "cap5_relay_scores":b["relay_scores"],
            "cap4_first_attack":a["first_attack_phase"],
            "cap5_first_attack":b["first_attack_phase"],
        })
    report={
        "version":"v3.8.7",
        "status":"research_only",
        "scope":"4 terrain templates x fog on/off x first side0/side1; 40x30",
        "question":"Does a 4- or 5-order FIRST responder half-turn outperform either an equal three-order opening or the original unrestricted responder, without relying on fog-specific bonuses?",
        "starter_first_turn_orders":3,
        "experimental_responder_first_turn_caps":[4,5],
        "rules_modified":False,
        "half_turn_horizon":32,
        "independent_paired_conditions":16,
        "actual_authoritative_games":64,
        "original_outcome_samples_per_cap":16,
        "mirror_replays_per_cap":16,
        "mirrors_not_independent_samples":True,
        "first_three_starter_actions_identical_for_both_policies":True,
        "first_four_responder_actions_identical_for_both_policies":True,
        "conditions_changed_winner_between_caps":changed,
        "by_cap":summary_all,
        "by_fog":by_fog,
        "by_template":by_template,
        "conditions":cases,
        "warnings":[
            "Historical v3.8.3 anchor results (response cap 3 vs unrestricted 7/8) were verified on a different workflow, and are NOT counted as cases in this v3.8.7 run.",
            "All caps apply only to the first response; ordinary later turns use official rules.",
            "These policies are simulations of voluntary early turn-end, NOT approved game mechanics.",
            "A game without a natural winner is censored, never a forced draw.",
            "Reflections verify deterministic symmetry but do NOT increase statistical sample size.",
            "Results from four fixed map templates and one AI policy do not establish a generally fair cap.",
            "No changes to in-game opening orders, combat, relay payout, economy, income, APK or main."
        ]
    }
    out=pathlib.Path("reports")
    out.mkdir(parents=True,exist_ok=True)
    (out/"ai_v387_opening_sensitivity.json").write_text(
        json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    md=[
        "# TARVOKA v3.8.7 — Sensibilidad de órdenes iniciales",
        "",
        "**16 condiciones emparejadas**, dos políticas de 4 y 5 órdenes de la "
        "primera respuesta, cada una también reflejada: **64 partidas autoritativas**; "
        "sólo 16 muestras originales por política.",
        "",
        "| Límite primera respuesta | Ganó primero | Ganó segundo | Sin ganador |",
        "|---|---:|---:|---:|",
    ]
    for cap in CAPS:
        s=summary_all[str(cap)]
        md.append(f"| {cap} órdenes | {s['first_wins']} | {s['responder_wins']} | {s['censored']} |")
    md += [
        "",
        "## Resultados por niebla",
        "",
        "| Niebla | Límite | Primero | Segundo | Censuradas |",
        "|---|---:|---:|---:|---:|",
    ]
    for fog in ("false","true"):
        for cap in CAPS:
            s=by_fog[fog][str(cap)]
            md.append(f"| {fog} | {cap} | {s['first_wins']} | {s['responder_wins']} | {s['censored']} |")
    md += [
        "",
        "## Cambios entre ambos límites",
        "",
        f"**{changed} de 16 condiciones** cambiaron de ganador al pasar de 4 a 5.",
        "",
        "| Semilla | Niebla | Inicia | Ganador cap 4 | Ganador cap 5 |",
        "|---|---|---:|---:|---:|"
    ]
    for c in cases:
        md.append(f"| {c['seed']} | {c['fog']} | {c['first']} | "
            f"{c['cap4_winner']} | {c['cap5_winner']} |")
    md += [
        "",
        "En [v3.8.3](https://github.com/edwinrodri12/Tarvoka/actions/runs/44360733728), "
        "**cap 3** tuvo 6 victorias del primero vs 10 del respondedor; "
        "la apertura actual sin límite adicional a respuesta tuvo 2 vs 14. "
        "Son referencias externas ya validadas, NO pruebas adicionales "
        "en este flujo.",
        "",
        "Los tres primeros movimientos del iniciador y los cuatro primeros "
        "movimientos del respondedor fueron iguales en las dos variantes "
        "antes de la intervención. Las diferencias posteriores solo pueden "
        "atribuirse, bajo la IA determinista y los mapas de prueba, "
        "a la duración voluntaria de la primera respuesta.",
        "",
        "**Investigación, sin cambio de reglas, sin APK, sin merge.**",""
    ]
    (out/"ai_v387_opening_sensitivity.md").write_text("\n".join(md),encoding="utf-8")
    print("BUDGET387_ALL "+json.dumps({k:v for k,v in report.items() if k!="conditions"},
        separators=(",",":"),ensure_ascii=False))
    print("\n".join(md))
    print("PASS TARVOKA v387 aggregate: 16 paired cap4/cap5 states and 64 exact mirrored games")

if __name__=="__main__":
    main(sys.argv[1] if len(sys.argv)>1 else ".ci-v387-logs")
