#!/usr/bin/env python3
"""TARVOKA v3.9.7: exact paired paid-piercer surgical ablation audit.

Three already-studied double bridge seeds, two initiators, cap3 / cap4 /
cap4 with ONLY the purchased Piercer removed before first responder end.
Mirrors verify state/action parity and do not increase outcome sample size.
"""
import json
import pathlib
import sys

PREFIX="ABL397_RESULT "
SEEDS=(634,650,658)
POLICIES=("cap3","cap4","ablated")

def load(directory):
    found={}
    for path in sorted(pathlib.Path(directory).rglob("*.log")):
        for line in path.read_text(encoding="utf-8",errors="replace").splitlines():
            pos=line.find(PREFIX+"{")
            if pos<0:
                continue
            row=json.loads(line[pos+len(PREFIX):])
            key=(row["seed"],row["first"])
            assert key not in found and key[0] in SEEDS and key[1] in (0,1),key
            assert row["version"]=="v3.9.7"
            assert row["fog"] is False and row["template"]==2 and row["size"]=="40x30"
            assert row["horizon"]==40
            assert row["policies"]==["cap3","cap4","cap4_piercer_absent_after_purchase"]
            assert row["experimental_surgical_removal_only"] is True
            assert row["no_production_game_changes"] is True
            assert row["original_samples_per_policy"]==1
            assert row["mirror_validation_per_policy"]==1
            delta=row["at_first_response_end"]
            assert delta["only_difference_one_removed_piercer"] is True
            assert delta["removed_unit_id"]=="N3"
            assert delta["removed_unit_role"]=="piercer"
            assert delta["removed_unit_hp"]>0
            assert delta["paid_credits_unchanged"] is True
            assert delta["workshop_state_unchanged"] is True
            assert delta["unit_count_before"]-delta["unit_count_after"]==1
            assert delta["first_response_credit_responder"]>=0
            for p in POLICIES:
                g=row[p]
                assert g["winner"] in (-1,0,1)
                assert g["starter_wins"] is (g["winner"]==row["first"])
                assert g["responder_wins"] is (g["winner"]==1-row["first"])
                assert g["censored"] is (g["winner"]==-1)
                assert g["terminal"] in ("winner","phase_limit","idle_stalemate")
                assert (g["terminal"]=="winner") is not g["censored"]
                assert 0<g["half_turns"]<=40
                assert len(g["score"])==2
                assert len(g["first_relay_phase"])==2
                assert len(g["first_city_phase"])==2
                assert len(g["opening_3"])==3
                assert len(g["responder_3"])==3
                assert len(g["responder_4"])==(3 if p=="cap3" else 4)
                assert g["actions"]>=0 and g["purchases"]>=0 and g["attacks"]>=0
            assert row["cap3"]["opening_3"]==row["cap4"]["opening_3"]==row["ablated"]["opening_3"]
            assert row["cap3"]["responder_3"]==row["cap4"]["responder_3"]==row["ablated"]["responder_3"]
            assert row["cap4"]["responder_4"]==row["ablated"]["responder_4"]
            assert row["cap4"]["responder_4"][3]["action"]=="produce"
            assert row["cap4"]["responder_4"][3]["role"]=="piercer"
            assert row["cap4"]["responder_4"][3]["cost"]==300
            assert row["cap4"]["responder_wins"] is True
            assert row["cap4"]["half_turns"]==(14 if row["seed"]==650 else 18)
            assert row["cap3"]["starter_wins"] is (row["seed"]!=650)
            assert row["cap4"]["first_relay_phase"][row["first"]]==8
            found[key]=row
    expected={(s,f) for s in SEEDS for f in (0,1)}
    assert set(found)==expected,("wrong 6-condition set",sorted(expected-set(found)))
    return [found[k] for k in sorted(expected)]

def stats(rows,p):
    games=[r[p] for r in rows]
    return {
        "original_conditions":len(games),
        "decisive":sum(not g["censored"] for g in games),
        "censored":sum(g["censored"] for g in games),
        "starter_wins":sum(g["starter_wins"] for g in games),
        "responder_wins":sum(g["responder_wins"] for g in games),
        "mean_half_turns":sum(g["half_turns"] for g in games)/len(games),
        "starter_first_relay":sum(
            (g["first_relay_phase"][r["first"]]>=0) and (
                g["first_relay_phase"][1-r["first"]]==-1 or
                g["first_relay_phase"][r["first"]]<g["first_relay_phase"][1-r["first"]])
            for r,g in zip(rows,games))
    }

def main(folder):
    rows=load(folder)
    report={
        "version":"v3.9.7",
        "status":"test_only_physically_impossible_unit_ablation",
        "hypothesis":"Are cap4 responder wins due to presence of the bought Piercer vs the identical 300-credit payment/factory state?",
        "seeds":list(SEEDS),
        "map_type":"40x30 double bridge no fog",
        "genuine_conditions_per_policy":6,
        "real_games_including_mirrors":36,
        "mirrors_are_not_independent":True,
        "test_only_ablation_after_authoritative_purchase":True,
        "credit_and_factory_state_identical_pre_round_end":True,
        "gameplay_production_modifications":False,
        "by_policy":{p:stats(rows,p) for p in POLICIES},
        "by_seed":{
            str(seed):{p:stats([r for r in rows if r["seed"]==seed],p) for p in POLICIES}
            for seed in SEEDS
        },
        "switches_winner_cap4_to_ablated":sum(
            r["cap4"]["winner"]!=r["ablated"]["winner"] for r in rows),
        "switches_winner_cap3_to_ablated":sum(
            r["cap3"]["winner"]!=r["ablated"]["winner"] for r in rows),
        "notes":[
            "This is a hypothetical removal of a paid unit, NOT a legal TARVOKA action.",
            "All prior actions and the 300-credit expense remain identical to cap4; only a single N3 unit is removed immediately before end_turn.",
            "This isolates unit presence plus downstream AI interactions; it does not distinguish combat impact, path blocking or AI targeting.",
            "The city/factory production flag remains as after purchase; cap3 differs from this experiment in both cash and factory history.",
            "These three seeds were previously studied and should NOT be called new out-of-sample observations.",
            "No altered gameplay rules, default AI, damage, credits, movement costs, save format, main or APK."
        ]
    }
    out=pathlib.Path("reports")
    out.mkdir(parents=True,exist_ok=True)
    (out/"ai_v397_piercer_ablation.json").write_text(
        json.dumps({"summary":report,"cases":rows},ensure_ascii=False,indent=2)+"\n",
        encoding="utf-8")
    md=[
        "# TARVOKA v3.9.7 — ¿Importa la unidad Piercer o solo el gasto de 300?",
        "",
        "**Prueba hipotética:** tras comprar legalmente Piercer N3 en la cuarta orden, "
        "se elimina de un estado de laboratorio ANTES del cierre del turno. "
        "El costo de 300 y el estado del taller permanecen **idénticos**. "
        "Esta eliminación NO es una acción permitida por las reglas.",
        "",
        "| Variante | Gana primero | Gana segundo | Censuradas | Media de medios turnos |",
        "|---|---:|---:|---:|---:|"
    ]
    for p in POLICIES:
        g=report["by_policy"][p]
        md.append(f"| {p} | {g['starter_wins']} | {g['responder_wins']} | "
                  f"{g['censored']} | {g['mean_half_turns']:.2f} |")
    md+=["","## Por semilla","","| Semilla | cap3 primero | cap4 primero | cap4 sin Piercer primero |",
          "|---:|---:|---:|---:|"]
    for seed in SEEDS:
        case=report["by_seed"][str(seed)]
        md.append(f"| {seed} | {case['cap3']['starter_wins']}/2 | "
                  f"{case['cap4']['starter_wins']}/2 | {case['ablated']['starter_wins']}/2 |")
    md += [
        "",
        f"La eliminación del Piercer cambia el ganador respecto de cap4 en "
        f"**{report['switches_winner_cap4_to_ablated']}/6** condiciones originales.",
        "",
        "**No extrapolar a todos los mapas.** Esta manipulación es solo una "
        "prueba de causalidad local; incluso si cambia el ganador, no determina "
        "si la causa fue ataque, bloqueo, presencia o decisiones subsecuentes de IA.",
        "",
        "6 condiciones originales por política, 36 partidas reales contando "
        "reflejos exactos de estados y acciones. Sin cambios al juego oficial.",
        ""
    ]
    (out/"ai_v397_piercer_ablation.md").write_text("\n".join(md),encoding="utf-8")
    print("ABL397_ALL "+json.dumps(report,ensure_ascii=False,separators=(",",":")))
    print("\n".join(md))
    print("PASS TARVOKA v397 aggregate: paid Piercer-only ablation with exact mirrored results")

if __name__=="__main__":
    main(sys.argv[1] if len(sys.argv)>1 else ".ci-v397-logs")
