#!/usr/bin/env python3
"""TARVOKA v396: strict three-seed fourth-recruit lifecycle audit.

One original per starter and per first-response policy, exact mirrored
replays for invariants only. No observations beyond those six conditions.
"""
import json
import pathlib
import sys

PREFIX="PIERCER396_RESULT "
SEEDS={634,650,658}

def load(folder):
    found={}
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8",errors="replace").splitlines():
            pos=line.find(PREFIX+"{")
            if pos<0:
                continue
            row=json.loads(line[pos+len(PREFIX):])
            key=(row["seed"],row["first"])
            assert key not in found and key[0] in SEEDS and key[1] in (0,1),key
            assert row["version"]=="v3.9.6"
            assert row["template"]==2 and row["fog"] is False and row["size"]=="40x30"
            assert row["response_policies"]==["cap3","cap4"]
            assert row["one_fourth_order_added"]=="produce piercer N3 cost 300"
            assert row["all_later_rules_official"] is True
            assert row["mirrors_parity_exact"] is True
            assert row["production_gameplay_untouched"] is True
            assert row["genuine_samples_per_policy"]==1
            assert row["mirror_validation_replays_per_policy"]==1
            before,after=row["cap3"],row["cap4"]
            for g in (before,after):
                assert g["winner"] in (-1,0,1)
                assert g["winner_first"] is (g["winner"]==row["first"])
                assert g["winner_responder"] is (g["winner"]==1-row["first"])
                assert g["censored"] is (g["winner"]==-1)
                assert 0<g["half_turns"]<=40
                assert g["first_relay_phase"][row["first"]]==8
                assert len(g["score"])==2
                assert len(g["first_city_phase"])==2
                assert isinstance(g["relay_events"],list)
                assert len(g["opening_3"])==3 and len(g["responder_first_3"])==3
                l=g["fourth_piercer"]
                assert l["unit"]=="N3"
                assert isinstance(l["actions"],list)
                assert isinstance(l["position_changes"],list)
            assert before["opening_3"]==after["opening_3"]
            assert before["responder_first_3"]==after["responder_first_3"]
            assert before["fourth_piercer"]["produced_phase"]!=1
            life=after["fourth_piercer"]
            assert life["produced_phase"]==1
            assert life["produced_order"]==3
            assert life["purchase_cost"]==300
            assert life["purchase_cell"] in ("(0, 4)","(39, 4)")
            assert life["first_observed_phase"]>=1
            assert life["first_hp"]>0
            assert life["last_hp"]>=0
            assert life["last_observed_phase"]>=life["first_observed_phase"]
            assert life["post_recruit_action_count"]==len(life["actions"])-1
            assert life["actions"][0]["type"]=="produce"
            assert life["actions"][0]["phase"]==1
            assert life["actions"][0]["order"]==3
            assert len(life["position_changes"])>=1
            assert after["winner_responder"] is True and after["censored"] is False
            assert after["half_turns"]==(14 if row["seed"]==650 else 18)
            assert before["winner_responder"] is (row["seed"]==650)
            assert before["censored"] is False
            found[key]=row
    expected={(seed,first) for seed in SEEDS for first in (0,1)}
    assert set(found)==expected,("missing conditions",sorted(expected-set(found)))
    return [found[key] for key in sorted(expected)]

def main(folder):
    rows=load(folder)
    life=[r["cap4"]["fourth_piercer"] for r in rows]
    summary={
        "version":"v3.9.6",
        "status":"diagnostic_only_no_game_rules_modified",
        "question":"Did the fourth-order Piercer act or survive while the responder recovered even after starter captured the first relay?",
        "seeds":[634,650,658],
        "original_conditions_per_policy":6,
        "actual_games_including_exact_mirrors":24,
        "mirrors_as_samples":False,
        "first_three_actions_matched":True,
        "single_extra_fourth_action":"produce Piercer N3 for 300",
        "both_policies_starter_captures_first_relay":True,
        "cap3_starter_wins":sum(r["cap3"]["winner_first"] for r in rows),
        "cap4_starter_wins":sum(r["cap4"]["winner_first"] for r in rows),
        "cap3_responder_wins":sum(r["cap3"]["winner_responder"] for r in rows),
        "cap4_responder_wins":sum(r["cap4"]["winner_responder"] for r in rows),
        "piercer_born_in_cap4":sum(l["produced_phase"]==1 for l in life),
        "piercer_moves_after_production":sum(
            any(a["type"]=="move" for a in l["actions"][1:]) for l in life),
        "piercer_attacks_after_production":sum(
            any(a["type"]=="attack" for a in l["actions"][1:]) for l in life),
        "piercer_survives_to_terminal":sum(l["exists_at_terminal"] for l in life),
        "piercer_dies_or_disappears":sum(l["death_phase"]>=0 for l in life),
        "mean_post_recruit_actions":sum(l["post_recruit_action_count"] for l in life)/len(life),
        "mean_half_turns_cap3":sum(r["cap3"]["half_turns"] for r in rows)/len(rows),
        "mean_half_turns_cap4":sum(r["cap4"]["half_turns"] for r in rows)/len(rows),
        "per_seed":{
            str(seed):{
                "cap3_starter_wins":sum(r["cap3"]["winner_first"] for r in rows if r["seed"]==seed),
                "cap4_starter_wins":sum(r["cap4"]["winner_first"] for r in rows if r["seed"]==seed),
                "piercer_actions":[r["cap4"]["fourth_piercer"]["actions"]
                                   for r in rows if r["seed"]==seed]
            } for seed in (634,650,658)
        },
        "warnings":[
            "The intervention adds a real purchase at order4 and its downstream AI/unit/cash consequences. It does NOT prove that damage, occupancy or a specific action explains the winner.",
            "Only three already-studied double-bridge maps with no fog: these are not new independent generalization data.",
            "The fourth order is allowed ONLY in the test simulator; no production game-turn budget changes.",
            "Same seeds are paired by starter and mirrored; reflections do not multiply sample size.",
            "No combat, map, score, income, AI default, purchase costs or APK edits."
        ]
    }
    out=pathlib.Path("reports")
    out.mkdir(parents=True,exist_ok=True)
    (out/"ai_v396_piercer_lifecycle.json").write_text(
        json.dumps({"summary":summary,"games":rows},ensure_ascii=False,indent=2)+"\n",
        encoding="utf-8")
    md=[
        "# TARVOKA v3.9.6 — Vida real del Piercer producido en la cuarta orden",
        "",
        "Semillas 634, 650 y 658; ambos iniciadores. **6 condiciones originales "
        "por política**, más reflejos exactos (24 partidas). Todas las "
        "rondas posteriores a la primera respuesta mantienen reglas reales.",
        "",
        "| Semilla | Primero gana con 3 órdenes | Primero gana con 4 órdenes | Acciones del Piercer de la cuarta orden |",
        "|---:|---:|---:|---|"
    ]
    for seed in (634,650,658):
        sub=[r for r in rows if r["seed"]==seed]
        actions=[r["cap4"]["fourth_piercer"]["post_recruit_action_count"] for r in sub]
        md.append(f"| {seed} | {sum(r['cap3']['winner_first'] for r in sub)}/2 | "
                  f"{sum(r['cap4']['winner_first'] for r in sub)}/2 | {actions} |")
    md += [
        "",
        "### Resumen observacional",
        "",
        f"- El Piercer se produjo en {summary['piercer_born_in_cap4']}/6.",
        f"- Se movió después de producirse en {summary['piercer_moves_after_production']}/6.",
        f"- Atacó después de producirse en {summary['piercer_attacks_after_production']}/6.",
        f"- Seguía presente al finalizar en {summary['piercer_survives_to_terminal']}/6.",
        "",
        "**Precaución:** producir la unidad altera dinero, ocupación y el estado "
        "que observa la IA. Aunque el ganador cambie, no atribuirlo a ataques "
        "del Piercer sin comprobar que realmente atacó o movió.",
        "",
        "**No se propone ningún cambio de reglas.**",
        ""
    ]
    (out/"ai_v396_piercer_lifecycle.md").write_text("\n".join(md),encoding="utf-8")
    print("PIERCER396_ALL "+json.dumps({k:v for k,v in summary.items() if k!="per_seed"},
        ensure_ascii=False,separators=(",",":")))
    print("\n".join(md))
    print("PASS TARVOKA v396 aggregate: six paired real Piercer traces and strict mirrored validation")

if __name__=="__main__":
    main(sys.argv[1] if len(sys.argv)>1 else ".ci-v396-logs")
