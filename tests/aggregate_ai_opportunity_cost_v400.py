#!/usr/bin/env python3
"""TARVOKA v4.0.0 strict three-policy opportunity-cost holdout.

8 novel seeds x fog on/off x 2 starting sides = 32 paired ORIGINAL
conditions, three AI policies with exact mirrors = 192 actual games.
Mirror repeats are checks, not statistically independent observations.
"""
import json
import pathlib
import sys

PREFIX="OPPORTUNITY400_RESULT "
SEEDS=tuple(range(682,690))
POLICIES=("baseline","raw_relay","opportunity_guard")

def read(folder):
    samples={}
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8",errors="replace").splitlines():
            pos=line.find(PREFIX+"{")
            if pos<0:
                continue
            row=json.loads(line[pos+len(PREFIX):])
            key=(row["seed"],row["fog"],row["first"])
            assert key not in samples,("duplicate",key)
            assert row["seed"] in SEEDS and type(row["fog"]) is bool
            assert row["first"] in (0,1)
            assert row["template"]==row["seed"]%4
            assert row["version"]=="v4.0.0"
            assert row["size"]=="40x30" and row["max_half_turns"]==36
            for field in (
                "official_opening_unmodified",
                "mirrors_identical",
                "new_strategy_default_off",
                "no_production_rules_changed"
            ):
                assert row[field] is True,field
            assert row["independent_cases_per_policy"]==1
            assert row["mirror_validation_per_policy"]==1
            for policy in POLICIES:
                g=row[policy]
                assert g["winner"] in (-1,0,1)
                assert g["starter_wins"] is (g["winner"]==row["first"])
                assert g["responder_wins"] is (g["winner"]==1-row["first"])
                assert g["censored"] is (g["winner"]==-1)
                assert 0<g["half_turns"]<=36
                assert g["actions"]>=0 and g["attacks"]>=0 and g["purchases"]>=0
                assert len(g["score"])==2
                assert len(g["first_capture_phase"])==2
                assert len(g["relay_captures"])==2
                assert len(g["first_city_phase"])==2
            for field,prior in (
                ("first_divergence_from_default","baseline"),
                ("first_divergence_from_raw","raw_relay")
            ):
                diff=row[field]
                assert type(diff["changed"]) is bool
                if diff["changed"]:
                    assert diff["index"]>=1
                    if not diff.get("trace_size_only",False):
                        assert diff["phase"]>=0
                        assert diff["visible_enemy_count"]>0
                else:
                    assert diff["index"]==-1 and diff["phase"]==-1
                    assert row[prior]==row["opportunity_guard"],(
                        "same trace but different result",key)
            samples[key]=row
    expected={(seed,fog,first) for seed in SEEDS
              for fog in (False,True) for first in (0,1)}
    assert set(samples)==expected,(
        "missing or extra conditions",sorted(expected-set(samples)))
    return [samples[key] for key in sorted(expected)]

def stats(rows,policy):
    games=[r[policy] for r in rows]
    assert games
    return {
        "original_conditions":len(games),
        "starter_wins":sum(g["starter_wins"] for g in games),
        "responder_wins":sum(g["responder_wins"] for g in games),
        "censored":sum(g["censored"] for g in games),
        "mean_half_turns":sum(g["half_turns"] for g in games)/len(games),
        "actions":sum(g["actions"] for g in games),
        "attacks":sum(g["attacks"] for g in games),
        "purchases":sum(g["purchases"] for g in games),
        "relay_captures":sum(sum(g["relay_captures"]) for g in games),
        "starter_first_relay":sum(
            g["first_capture_phase"][r["first"]]>=0 and (
                g["first_capture_phase"][1-r["first"]]<0 or
                g["first_capture_phase"][r["first"]]<
                    g["first_capture_phase"][1-r["first"]])
            for r,g in zip(rows,games))
    }

def changes(rows,older,newer):
    return {
        "changed_winner_or_censor":sum(
            r[older]["winner"]!=r[newer]["winner"] for r in rows),
        "starter_gains":sum(
            not r[older]["starter_wins"] and
            r[newer]["starter_wins"] for r in rows),
        "starter_losses":sum(
            r[older]["starter_wins"] and
            not r[newer]["starter_wins"] for r in rows),
        "newly_censored":sum(
            not r[older]["censored"] and
            r[newer]["censored"] for r in rows)
    }

def main(folder):
    rows=read(folder)
    result={
        "version":"v4.0.0",
        "status":"research_only_do_not_activate_without_benefit",
        "goal":"Compare legal urban income and reinforcement opportunities before contesting neutral relays",
        "unseen_seeds":list(SEEDS),
        "templates":[0,1,2,3],
        "fog":[False,True],
        "starting_sides":[0,1],
        "original_paired_conditions":32,
        "played_games_including_mirrors":192,
        "mirrors_inflating_sample":False,
        "official_first_turn_order_limit_unchanged":True,
        "all_game_rules_untouched":True,
        "default_opportunity_flag_disabled":True,
        "by_policy":{p:stats(rows,p) for p in POLICIES},
        "by_fog":{
            str(fog).lower():{p:stats(
                [r for r in rows if r["fog"]==fog],p) for p in POLICIES}
            for fog in (False,True)
        },
        "by_template":{
            str(t):{p:stats([r for r in rows if r["template"]==t],p)
                    for p in POLICIES}
            for t in range(4)
        },
        "delta_guard_vs_baseline":changes(rows,"baseline","opportunity_guard"),
        "delta_raw_vs_baseline":changes(rows,"baseline","raw_relay"),
        "delta_guard_vs_raw":changes(rows,"raw_relay","opportunity_guard"),
        "guard_actions_differ_baseline":sum(
            r["first_divergence_from_default"]["changed"] for r in rows),
        "guard_actions_differ_raw":sum(
            r["first_divergence_from_raw"]["changed"] for r in rows),
        "safety_notes":[
            "Only AI options change in the comparisons. The starter retains exactly 3 legal opening orders.",
            "All productions spend their own real credits and urban captures use the real Session state.",
            "Fog masking is identical for all policies; no enemy positions or treasury read beyond Visibility.observed_state.",
            "Mirrored games check symmetry; both starters of the same map are correlated.",
            "No gameplay economy, relay scoring, map terrain, combat or save-format changes.",
            "The previous v398 candidate hurt baseline winning results on 32 old cases: baseline starter 10/32 vs raw 8/32.",
            "A 32-condition holdout cannot prove an optimal AI or a guaranteed win rate against human opponents.",
            "Censorship means no terminal winner within 36 half-turns, not a draw or implicit responder victory.",
            "Do not activate the new option without balanced winners across fog and all four templates."
        ]
    }
    output=pathlib.Path("reports")
    output.mkdir(parents=True,exist_ok=True)
    (output/"ai_v400_opportunity_cost.json").write_text(
        json.dumps({"summary":result,"conditions":rows},
                   ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    md=[
        "# TARVOKA v4.0.0 — IA valora relés, ciudades y refuerzos",
        "",
        "32 condiciones originales de ocho semillas NUEVAS 682–689, "
        "ambas nieblas y ambos iniciadores. IA actual contra pronóstico "
        "v398 sin filtro y contra el árbitro económico v400. Cada partida "
        "se reprodujo con espejo exacto: **192 juegos reales** sin "
        "considerar los espejos como nuevas muestras.",
        "",
        "| Política | Primero gana | Segundo gana | Censuras | Media de medios turnos | Compras |",
        "|---|---:|---:|---:|---:|---:|"
    ]
    for p in POLICIES:
        x=result["by_policy"][p]
        md.append(f"| {p} | {x['starter_wins']} | {x['responder_wins']} | "
                  f"{x['censored']} | {x['mean_half_turns']:.2f} | "
                  f"{x['purchases']} |")
    md+=["","## Separación por niebla","","| Niebla | Estrategia | Primero | Segundo | Censuras |",
         "|---|---|---:|---:|---:|"]
    for fog in ("false","true"):
        for p in POLICIES:
            x=result["by_fog"][fog][p]
            md.append(f"| {fog} | {p} | {x['starter_wins']} | "
                      f"{x['responder_wins']} | {x['censored']} |")
    md+=["","## Separación por terreno","","| Plantilla | Estrategia | Primero | Segundo | Censuras |",
         "|---:|---|---:|---:|---:|"]
    for t in range(4):
        for p in POLICIES:
            x=result["by_template"][str(t)][p]
            md.append(f"| {t} | {p} | {x['starter_wins']} | "
                      f"{x['responder_wins']} | {x['censored']} |")
    md+=["","## Divergencias y cautelas","",
         f"- La nueva política cambió acciones respecto a la IA actual en "
         f"{result['guard_actions_differ_baseline']}/32 condiciones.",
         f"- Cambió acciones respecto al antiguo forecast v398 en "
         f"{result['guard_actions_differ_raw']}/32 condiciones.",
         f"- Ganadores cambiados frente a la IA actual: "
         f"{result['delta_guard_vs_baseline']}.",
         f"- Ganadores cambiados frente al v398 antiguo: "
         f"{result['delta_guard_vs_raw']}.",
         "",
         "**No activar todavía:** 18/18 de CI demuestra reproducción, "
         "legalidad y consistencia, no superioridad de estrategia. "
         "Se requiere mejoría robusta por tipo de mapa y visibilidad.",
         ""]
    (output/"ai_v400_opportunity_cost.md").write_text(
        "\n".join(md),encoding="utf-8")
    print("OPPORTUNITY400_ALL "+json.dumps(result,ensure_ascii=False,
        separators=(",",":")))
    print("\n".join(md))
    print("PASS TARVOKA v400 aggregate: 32 genuinely paired outcomes, 192 mirrors-inclusive real games")

if __name__=="__main__":
    main(sys.argv[1] if len(sys.argv)>1 else ".ci-v400-logs")
