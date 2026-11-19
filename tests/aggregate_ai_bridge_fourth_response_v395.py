#!/usr/bin/env python3
"""Research-only audit of fourth first-response order on TARVOKA bridges.

8 seeds x 2 starting sides x 4 response policies. Each game is separately
reflected and verified by Godot. The 64 mirrored runs are not samples.
"""
import json
import pathlib
import sys

PREFIX="BRIDGE395_RESULT "
SEEDS=(634,638,642,646,650,654,658,662)
REFERENCE={634,638}
POLICIES=("official","cap3","cap4","cap5")

def load(folder):
    samples={}
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8",errors="replace").splitlines():
            p=line.find(PREFIX+"{")
            if p<0:
                continue
            row=json.loads(line[p+len(PREFIX):])
            key=(row["seed"],row["first"])
            assert key not in samples and key[0] in SEEDS and key[1] in (0,1), key
            assert row["version"]=="v3.9.5" and row["template"]==2
            assert row["reference"] is (row["seed"] in REFERENCE)
            assert row["size"]=="40x30" and row["fog"] is False
            assert row["limit_half_turns"]==40
            assert row["policies"]==list(POLICIES)
            assert row["original_sample_each_policy"]==1
            assert row["mirror_replay_each_policy"]==1
            assert row["first_three_actions_identical"] is True
            assert row["fourth_action_matches_official"] is True
            assert row["fifth_action_matches_official"] is True
            assert row["no_production_rules_changed"] is True
            assert row["fourth_response_action"] and row["fifth_response_action"]
            for policy,count in (("official",8),("cap3",3),("cap4",4),("cap5",5)):
                g=row[policy]
                assert g["first_response_orders"]==count
                assert g["winner"] in (-1,0,1)
                assert g["winner_starter"] is (g["winner"]==row["first"])
                assert g["winner_responder"] is (g["winner"]==1-row["first"])
                assert g["censored"] is (g["winner"]==-1)
                assert g["terminal"] in ("winner","phase_limit","idle_stalemate")
                assert (g["terminal"]=="winner") is (g["winner"]!=-1)
                assert 0<g["half_turns"]<=40
                assert len(g["final_signal"])==2
                assert len(g["opening_actions"])==3
                assert len(g["response_first_three"])==3
                assert len(g["response_first_five"])==min(count,5)
                assert g["actions"]>=0 and g["attacks"]>=0 and g["purchases"]>=0
                assert len(g["relay"]["starter_first_capture_phase"].__str__())>0
                assert len(g["city_first_phase"])==2
                assert isinstance(g["first_captures"],list)
            original=row["official"]
            assert original["winner_responder"] and original["half_turns"]==12
            assert original["relay"]["responder_first_capture_phase"]==7
            assert row["cap5"]["winner_responder"] and row["cap5"]["half_turns"]==12
            assert row["cap5"]["relay"]["responder_first_capture_phase"]==7
            for policy in ("cap3","cap4","cap5"):
                assert row[policy]["opening_actions"]==original["opening_actions"]
                assert row[policy]["response_first_three"]==original["response_first_three"]
            assert row["cap3"]["response_first_five"]==original["response_first_five"][:3]
            assert row["cap4"]["response_first_five"]==original["response_first_five"][:4]
            assert row["cap5"]["response_first_five"]==original["response_first_five"]
            assert row["fourth_response_action"]==original["response_first_five"][3]
            assert row["fifth_response_action"]==original["response_first_five"][4]
            samples[key]=row
    expected={(seed,side) for seed in SEEDS for side in (0,1)}
    assert set(samples)==expected,("incomplete 16 conditions",sorted(expected-set(samples)))
    return [samples[k] for k in sorted(expected)]

def group(rows,policy):
    games=[r[policy] for r in rows]
    return {
        "original_conditions":len(games),
        "starter_wins":sum(g["winner_starter"] for g in games),
        "responder_wins":sum(g["winner_responder"] for g in games),
        "censored":sum(g["censored"] for g in games),
        "half_turns_total":sum(g["half_turns"] for g in games),
        "half_turns_mean":sum(g["half_turns"] for g in games)/len(games),
        "starter_first_relay":sum(g["relay"]["starter_first"] for g in games),
        "responder_first_relay":sum(g["relay"]["responder_first"] for g in games),
        "starter_ever_captures":sum(g["relay"]["starter_first_capture_phase"]>=0 for g in games),
        "responder_ever_captures":sum(g["relay"]["responder_first_capture_phase"]>=0 for g in games),
        "fourth_order_type_counts":{} if policy=="cap3" else None
    }

def main(folder):
    rows=load(folder)
    new=[r for r in rows if r["seed"] not in REFERENCE]
    reference=[r for r in rows if r["seed"] in REFERENCE]
    assert len(rows)==16 and len(new)==12 and len(reference)==4
    report={
        "version":"v3.9.5","status":"forensic_only_not_a_game_balance_change",
        "goal":"Which fourth responder action bridges the difference between cap3 and cap5?",
        "seeds":list(SEEDS),
        "reference_seeds":sorted(REFERENCE),
        "unseen_seeds":sorted(set(SEEDS)-REFERENCE),
        "fog":False,"map_template":2,
        "original_conditions_per_policy":16,
        "new_seed_conditions_per_policy":12,
        "actual_games_with_exact_mirrors":128,
        "mirrors_counted_as_independent_samples":False,
        "production_rule_changes":False,
        "by_policy":{p:group(rows,p) for p in POLICIES},
        "new_seed_only":{p:group(new,p) for p in POLICIES},
        "per_seed":{
            str(seed):{p:group([r for r in rows if r["seed"]==seed],p)
            for p in POLICIES} for seed in SEEDS
        },
        "fourth_action_types":{
            kind:sum(str(r["fourth_response_action"].get("action",""))==kind for r in rows)
            for kind in sorted(set(str(r["fourth_response_action"].get("action",""))
                                   for r in rows))
        },
        "fifth_action_types":{
            kind:sum(str(r["fifth_response_action"].get("action",""))==kind for r in rows)
            for kind in sorted(set(str(r["fifth_response_action"].get("action",""))
                                   for r in rows))
        },
        "winner_switches_relative_to_official":{
            p:sum(r[p]["winner"]!=r["official"]["winner"] for r in rows)
            for p in ("cap3","cap4","cap5")
        },
        "first_relay_capturer_changed_relative_official":{
            p:sum(r[p]["relay"]["winner_first_relay"]!=r["official"]["relay"]["winner_first_relay"]
                  for r in rows)
            for p in ("cap3","cap4","cap5")
        },
        "warnings":[
            "Voluntary end after 3/4/5 actions applies ONLY to the initial response in test harness.",
            "The actual game still uses 3 opening orders for starter and 8 possible for responder.",
            "This cohort was previously tested for cap3/cap5; only cap4 is newly evaluated.",
            "Each starter identity on same map is correlated and mirrors validate parity only.",
            "A winner flip under cap4 does not establish that four orders is fair in other maps or fog settings.",
            "No code change to gameplay, AI defaults, economy, scoring, terrain, combat, APK or main."
        ]
    }
    out=pathlib.Path("reports")
    out.mkdir(parents=True,exist_ok=True)
    (out/"ai_v395_fourth_order_bridge.json").write_text(
        json.dumps({"summary":report,"cases":rows},ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    md=[
        "# TARVOKA v3.9.5 — Localizar el cambio entre la cuarta y quinta orden",
        "",
        "Mapa de doble puente 40×30 sin niebla. **16 situaciones originales por política**, "
        "96? No: **128 partidas reales incluyendo reflejos**, que no se cuentan como "
        "muestras independientes. La primera respuesta se interrumpe SOLO en pruebas.",
        "",
        "| Primera respuesta | Gana primero | Gana segundo | Censuras | Primero captura primer relé | Medios turnos promedio |",
        "|---|---:|---:|---:|---:|---:|"
    ]
    for p in POLICIES:
        v=report["by_policy"][p]
        md.append(f"| {p} | {v['starter_wins']} | {v['responder_wins']} | "
                  f"{v['censored']} | {v['starter_first_relay']} | {v['half_turns_mean']:.2f} |")
    md+=["","## Solo seis semillas nuevas","",
         "| Política | Primero gana | Segundo gana | Censuras |",
         "|---|---:|---:|---:|"]
    for p in POLICIES:
        v=report["new_seed_only"][p]
        md.append(f"| {p} | {v['starter_wins']} | {v['responder_wins']} | {v['censored']} |")
    md+=["",
         "## Acciones decisivas candidatas (descriptivas, no causales por sí mismas)","",
         f"Cuarta orden: {report['fourth_action_types']}. Quinta orden: {report['fifth_action_types']}.",
         "",
         "La cronología de cada partida guarda la primera captura de cada bando, "
         "la secuencia exacta de las primeras cinco órdenes y las órdenes cuarta "
         "y quinta por separado para evaluar por qué aparece el cambio.",
         "",
         "**No recomienda imponer un límite de cuatro órdenes.**",""]
    (out/"ai_v395_fourth_order_bridge.md").write_text("\n".join(md),encoding="utf-8")
    print("BRIDGE395_ALL "+json.dumps(report,separators=(",",":"),ensure_ascii=False))
    print("\n".join(md))
    print("PASS TARVOKA v395 aggregate: 16 cases x 4 policies with 128 exact mirrored battles")

if __name__=="__main__":
    main(sys.argv[1] if len(sys.argv)>1 else ".ci-v395-logs")
