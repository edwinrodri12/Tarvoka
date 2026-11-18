#!/usr/bin/env python3
"""Holdout aggregation: 8 unseen 40x30 seeds x 2 fog x 2 starters.

Official baseline and test-only first-response cap5, each with its exact
mirror. Count exactly ONE original outcome per seed/fog/starter/policy.
"""
import json
import pathlib
import sys

PREFIX="HOLD388_RESULT "
SEEDS=tuple(range(634,642))

def read_logs(folder):
    rows=[]
    for p in sorted(pathlib.Path(folder).rglob("*.log")):
        for ln in p.read_text(encoding="utf-8",errors="replace").splitlines():
            index=ln.find(PREFIX+"{")
            if index>=0:
                rows.append(json.loads(ln[index+len(PREFIX):]))
    return rows

def verify_policy(r,g,policy):
    assert g["policy"]==policy
    assert g["winner"] in (-1,0,1)
    assert g["censored"] is (g["winner"]==-1)
    assert g["winner_first"] is (g["winner"]==r["first"])
    assert g["winner_responder"] is (g["winner"]==1-r["first"])
    assert g["terminal"] in ("winner","phase_limit","idle_stalemate")
    assert (g["terminal"]=="winner") is (g["winner"]>=0)
    assert g["first_orders"]==3
    assert (g["first_response_orders"]==5 if policy=="response5"
            else g["first_response_orders"]>=5)
    assert 0<g["half_turns"]<=32
    for k in ("actions","attacks","purchases","resupplies"):
        assert isinstance(g[k],int) and g[k]>=0
    assert len(g["relay_signal_final"])==2
    assert len(g["starter_first_three_actions"])==3
    assert len(g["responder_first_five_actions"])==5
    assert g["mirror_exact"] is True
    return g

def stats(rows,policy):
    games=[r[policy] for r in rows]
    assert games
    return {
        "original_conditions":len(games),
        "decisive":sum(not g["censored"] for g in games),
        "censored":sum(g["censored"] for g in games),
        "first_wins":sum(g["winner_first"] for g in games),
        "responder_wins":sum(g["winner_responder"] for g in games),
        "total_actions":sum(g["actions"] for g in games),
        "total_attacks":sum(g["attacks"] for g in games),
        "total_purchases":sum(g["purchases"] for g in games),
        "total_resupplies":sum(g["resupplies"] for g in games),
        "first_attack_observed":sum(g["first_attack_phase"]>=0 for g in games),
        "first_relay_observed":sum(g["first_relay_capture_phase"]>=0 for g in games),
        "total_half_turns":sum(g["half_turns"] for g in games)
    }

def main(folder):
    rows=read_logs(folder)
    expected={(seed,fog,first) for seed in SEEDS
              for fog in (False,True) for first in (0,1)}
    seen={}
    for r in rows:
        key=(r["seed"],r["fog"],r["first"])
        assert key in expected and key not in seen,("bad or duplicate case",key)
        assert type(r["fog"]) is bool
        assert r["size"]=="40x30"
        assert r["template"]==r["seed"]%4
        assert r["max_half_turns"]==32 and r["starter_initial_orders"]==3
        assert r["responder_trial_cap"]==5
        assert r["symmetric_first_income"] is True
        assert r["production_rules_changed"] is False
        assert r["original_samples_per_policy"]==1
        assert r["mirror_replays_per_policy"]==1
        a=verify_policy(r,r["baseline"],"official")
        b=verify_policy(r,r["response5"],"response5")
        assert a["starter_first_three_actions"]==b["starter_first_three_actions"]
        assert a["responder_first_five_actions"]==b["responder_first_five_actions"]
        seen[key]=r
    assert len(rows)==32 and set(seen)==expected,(
        "incomplete exact out-of-sample matrix",len(rows),sorted(expected-set(seen)))
    ordered=[seen[k] for k in sorted(expected)]
    summary={name:stats(ordered,name) for name in ("baseline","response5")}
    per_fog={
        str(fog).lower():{
            name:stats([r for r in ordered if r["fog"]==fog],name)
            for name in ("baseline","response5")
        } for fog in (False,True)
    }
    per_template={
        str(template):{
            name:stats([r for r in ordered if r["template"]==template],name)
            for name in ("baseline","response5")
        } for template in range(4)
    }
    per_seed={
        str(seed):{
            name:stats([r for r in ordered if r["seed"]==seed],name)
            for name in ("baseline","response5")
        } for seed in SEEDS
    }
    outcomes=[]
    improved=worsened=same=0
    for r in ordered:
        a,b=r["baseline"],r["response5"]
        changed=a["winner"]!=b["winner"]
        improved+=int(not a["winner_first"] and b["winner_first"])
        worsened+=int(a["winner_first"] and not b["winner_first"])
        same+=int(not changed)
        outcomes.append({
            "seed":r["seed"],"template":r["template"],
            "fog":r["fog"],"first":r["first"],
            "baseline_winner":a["winner"],"response5_winner":b["winner"],
            "baseline_censored":a["censored"],
            "response5_censored":b["censored"],
            "baseline_first_wins":a["winner_first"],
            "response5_first_wins":b["winner_first"],
            "changed_winner":changed,
            "baseline_half_turns":a["half_turns"],
            "response5_half_turns":b["half_turns"],
            "baseline_first_response_orders":a["first_response_orders"]
        })
    report={
        "version":"v3.8.8","status":"holdout_research_only",
        "condition":"40x30, seeds 634..641 never used by previous v383/v387",
        "seed_list":list(SEEDS),
        "map_templates":4,
        "fog_conditions":2,
        "starter_conditions":2,
        "original_independent_cases":32,
        "games_executed_including_mirrors":128,
        "outcome_samples_per_policy":32,
        "mirror_only_for_parity":True,
        "symmetric_starter_initial_credits":True,
        "starters_three_orders":True,
        "responder_first_five_actions_identical_before_policy_change":True,
        "gameplay_rules_changed":False,
        "half_turn_cap":32,
        "by_policy":summary,
        "by_fog":per_fog,
        "by_template":per_template,
        "by_seed":per_seed,
        "conditions_where_cap5_changes_responder_win_to_first":improved,
        "conditions_where_cap5_changes_first_win_to_responder":worsened,
        "conditions_same_winner":same,
        "outcomes":outcomes,
        "warnings":[
            "Results for fixed generated seeds and a single AI style are not representative of all human play or enough to ship a new opening rule.",
            "First-player and second-player runs on the same terrain/fog are paired and correlated; mirrored replays only validate equivalence.",
            "A response capped at 5 is an opt-in TEST-only voluntary early turn end, not an approved engine change.",
            "The official responder currently uses all legal orders during its first response and the initiator has the existing three-order restriction.",
            "No outcome is forced at the 32-half-turn observation limit: unresolved games are censored, not draws.",
            "Do not compare rates across the old and new seed cohorts as a randomized causal trial; causal comparisons occur only WITHIN each seed/fog/starter pair.",
            "Gameplay AI, combat, relay scoring, visibility, initial income, opening rules, main and APK remain unchanged."
        ]
    }
    output=pathlib.Path("reports")
    output.mkdir(exist_ok=True,parents=True)
    (output/"ai_v388_holdout.json").write_text(
        json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    md=[
        "# TARVOKA v3.8.8 — Validación fuera de muestra de apertura",
        "",
        "**Semillas nuevas 634–641:** 32 condiciones iniciales, 2 políticas y "
        "un espejo por política = 128 partidas, 32 muestras originales por política.",
        "",
        "| Política | Gana primero | Gana segundo | Censuradas |",
        "|---|---:|---:|---:|"
    ]
    for name,label in [("baseline","Actual (respuesta libre)"),
                       ("response5","Experimental (respuesta 5)")]:
        x=summary[name]
        md.append(f"| {label} | {x['first_wins']} | {x['responder_wins']} | {x['censored']} |")
    md += ["", "## Por niebla", "",
           "| Niebla | Política | Primero | Segundo | Censuradas |",
           "|---|---|---:|---:|---:|"]
    for fog in ("false","true"):
        for name,label in [("baseline","Actual"),("response5","Cap 5")]:
            x=per_fog[fog][name]
            md.append(f"| {fog} | {label} | {x['first_wins']} | {x['responder_wins']} | {x['censored']} |")
    md += ["", "## Por tipo de mapa", "",
           "| Plantilla | Política | Primero | Segundo | Censuradas |",
           "|---|---|---:|---:|---:|"]
    for template in range(4):
        for name,label in [("baseline","Actual"),("response5","Cap 5")]:
            x=per_template[str(template)][name]
            md.append(f"| {template} | {label} | {x['first_wins']} | {x['responder_wins']} | {x['censored']} |")
    md += [
        "",
        f"Al limitar la primera respuesta a cinco órdenes, **{improved}** "
        "resultados cambiaron a favor de quien inicia, y **"
        f"{worsened}** cambiaron en su contra. **{same}** conservaron "
        "el mismo ganador.",
        "",
        "Todas las partidas reflejadas deben reproducir exactamente cada "
        "decisión y estado. Todas las primeras cinco acciones del respondedor "
        "se comparan entre ambas políticas antes de cerrar el turno de prueba.",
        "",
        "**Sin cambios de reglas ni APK.** Una diferencia observada solo "
        "apoya nuevas pruebas, no una regla universal.",""
    ]
    (output/"ai_v388_holdout.md").write_text("\n".join(md),encoding="utf-8")
    print("HOLD388_ALL "+json.dumps({k:v for k,v in report.items() if k!="outcomes"},
        separators=(",",":"),ensure_ascii=False))
    print("\n".join(md))
    print("PASS TARVOKA v388 aggregate: 32 paired unseen conditions, 128 real mirrored games and no duplicate outcomes")

if __name__=="__main__":
    main(sys.argv[1] if len(sys.argv)>1 else ".ci-v388-logs")
