#!/usr/bin/env python3
"""TARVOKA v4.0.1: head-to-head candidate v400 versus official AI.

8 genuinely unseen seeds x 2 fog states x 2 starting factions x
2 candidate-faction assignments = 64 ORIGINAL cross-policy games.
Each match is independently mirrored with faction swap: 128 games.
Mirrors confirm exact action/state parity; they are NOT extra samples.
"""
import json
import pathlib
import sys

PREFIX="HEAD401_RESULT "
SEEDS=tuple(range(690,698))
EXPECTED={(seed,fog,first,side) for seed in SEEDS
          for fog in (False,True) for first in (0,1) for side in (0,1)}

def load(folder):
    found={}
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8",errors="replace").splitlines():
            idx=line.find(PREFIX+"{")
            if idx<0:
                continue
            row=json.loads(line[idx+len(PREFIX):])
            key=(row["seed"],row["fog"],row["first"],row["candidate_faction"])
            assert key not in found and key in EXPECTED,("bad key",key)
            assert row["version"]=="v4.0.1" and row["size"]=="40x30"
            assert row["template"]==row["seed"]%4
            assert type(row["fog"]) is bool and row["max_half_turns"]==36
            assert row["baseline_faction"]==1-row["candidate_faction"]
            assert row["candidate_started"] is (
                row["first"]==row["candidate_faction"])
            assert row["match_type"]=="candidate_v400_vs_official_AI"
            for prop in (
                "candidate_flag_active_only_for_candidate",
                "official_opening_3_orders",
                "exact_reflected_policy_assignment",
                "rules_and_income_unchanged"
            ):
                assert row[prop] is True,prop
            assert row["original_games"]==1 and row["mirrored_games"]==1
            g=row["outcome"]
            assert g["winner"] in (-1,0,1)
            assert g["censored"] is (g["winner"]==-1)
            assert g["candidate_started"] is row["candidate_started"]
            assert g["candidate_wins"] is (
                g["winner"]==row["candidate_faction"])
            assert g["baseline_wins"] is (
                g["winner"]==row["baseline_faction"])
            assert g["winner_was_starter"] is (
                g["winner"]==row["first"])
            assert g["terminal"] in ("winner","phase_limit","idle_stalemate")
            assert (g["terminal"]=="winner") is (not g["censored"])
            assert 0<g["completed_half_turns"]<=36
            assert g["symmetric_first_income"] is True
            assert len(g["terminal_state_relay_scores"])==2
            assert g["candidate_score"]==g[
                "terminal_state_relay_scores"][row["candidate_faction"]]
            assert g["baseline_score"]==g[
                "terminal_state_relay_scores"][row["baseline_faction"]]
            assert all(g[k]>=0 for k in (
                "actions","attacks","purchases","moves","resupplies",
                "candidate_score","baseline_score"))
            found[key]=row
    assert set(found)==EXPECTED,(
        "not exactly 64 match conditions",
        "missing",sorted(EXPECTED-set(found)),
        "extra",sorted(set(found)-EXPECTED))
    return [found[k] for k in sorted(EXPECTED)]

def outcome(rows):
    games=[r["outcome"] for r in rows]
    n=len(games)
    assert n>0
    candidates=sum(g["candidate_wins"] for g in games)
    baseline=sum(g["baseline_wins"] for g in games)
    censored=sum(g["censored"] for g in games)
    assert candidates+baseline+censored==n
    return {
        "original_games":n,
        "candidate_wins":candidates,
        "official_ai_wins":baseline,
        "censored":censored,
        "candidate_decisive_win_fraction":(
            candidates/(candidates+baseline) if candidates+baseline else None),
        "candidate_score_total":sum(g["candidate_score"] for g in games),
        "official_score_total":sum(g["baseline_score"] for g in games),
        "candidate_score_margin_total":sum(
            g["candidate_score"]-g["baseline_score"] for g in games),
        "half_turns_mean":sum(g["completed_half_turns"] for g in games)/n,
        "total_purchases":sum(g["purchases"] for g in games),
        "total_attacks":sum(g["attacks"] for g in games)
    }

def main(folder):
    rows=load(folder)
    ref=outcome(rows)
    by_fog={str(fog).lower():outcome(
        [r for r in rows if r["fog"]==fog]) for fog in (False,True)}
    by_first={str(first):outcome(
        [r for r in rows if r["first"]==first]) for first in (0,1)}
    by_role={role:outcome([r for r in rows
        if r["candidate_started"] is (role=="first")])
        for role in ("first","second")}
    by_template={str(t):outcome(
        [r for r in rows if r["template"]==t])
        for t in range(4)}
    by_seed={str(seed):outcome(
        [r for r in rows if r["seed"]==seed])
        for seed in SEEDS}
    assert ref["original_games"]==64
    assert all(x["original_games"]==32 for x in by_fog.values())
    assert all(x["original_games"]==32 for x in by_first.values())
    assert all(x["original_games"]==32 for x in by_role.values())
    assert all(x["original_games"]==16 for x in by_template.values())
    assert all(x["original_games"]==8 for x in by_seed.values())
    report={
        "version":"v4.0.1",
        "question":"Does the economic opportunity arbiter actually defeat the official AI in mixed-policy games, with both initiative and faction assignments?",
        "status":"experimental_cross_play_not_an_auto_deployment",
        "previous_self_play_ci":"44470015304",
        "seeds":list(SEEDS),
        "unseen_relative_to_v400":True,
        "map_templates":[0,1,2,3],
        "fog":[False,True],
        "candidate_factions":[0,1],
        "starting_factions":[0,1],
        "original_independent_match_conditions":64,
        "actual_games_with_mirror_replays":128,
        "mirror_replays_counted_as_samples":False,
        "candidate_only_one_faction_each_game":True,
        "official_ai_controls_opponent":True,
        "faction_swapped_reflection_preserves_policy":True,
        "starting_cities_and_cash_exactly_same":True,
        "opening_turn_three_orders_unchanged":True,
        "no_production_rules_modified":True,
        "result":ref,
        "by_candidate_starts":by_role,
        "by_fog":by_fog,
        "by_starter_color":by_first,
        "by_template":by_template,
        "by_seed":by_seed,
        "limitations":[
            "Tests show head-to-head effectiveness against this particular deterministic baseline, not optimal play.",
            "The two starting sides, matched same-seed games, and mirror reflections are correlated; 128 executions are only 64 original conditions.",
            "A winner within 36 half-turns is decisive; an unfinished game is CENSORED, not a tied match.",
            "A strong overall win rate must be checked for one-sided color, fog and map-template harm, not treated as automatic authorization to activate.",
            "The candidate uses no additional information, moves, purchases, damage, money, map reveals, or powers.",
            "This research harness is not part of the packaged Android game.",
            "The parent v400 self-play and this cross-play must both pass full CI before considering any default AI change."
        ]
    }
    folder_out=pathlib.Path("reports")
    folder_out.mkdir(parents=True,exist_ok=True)
    (folder_out/"ai_v401_head_to_head.json").write_text(
        json.dumps({"summary":report,"original_conditions":rows},
                   ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    md=[
        "# TARVOKA v4.0.1 — Primera prueba directa de fuerza entre IA",
        "",
        "**64 partidas originales de enfrentamiento cruzado** entre la "
        "IA oficial y la IA de evaluación económica v400. Cada partida "
        "tiene un espejo horizontal con facciones y políticas intercambiadas. "
        "**128 partidas ejecutadas, no 128 muestras independientes**.",
        "",
        "| Rivalidad | Gana v400 | Gana IA oficial | Censuras | Duración media |",
        "|---|---:|---:|---:|---:|"
    ]
    md.append(f"| Total | {ref['candidate_wins']} | "
              f"{ref['official_ai_wins']} | {ref['censored']} | "
              f"{ref['half_turns_mean']:.2f} |")
    md += ["","## Según quién empieza","","| v400 juega | Gana v400 | Gana IA oficial | Censuras |",
           "|---|---:|---:|---:|"]
    for role in ("first","second"):
        s=by_role[role]
        md.append(f"| {role} | {s['candidate_wins']} | "
                  f"{s['official_ai_wins']} | {s['censored']} |")
    md += ["","## Niebla","","| Niebla | Gana v400 | Gana IA oficial | Censuras |",
           "|---|---:|---:|---:|"]
    for fog in ("false","true"):
        s=by_fog[fog]
        md.append(f"| {fog} | {s['candidate_wins']} | "
                  f"{s['official_ai_wins']} | {s['censored']} |")
    md += ["","## Plantilla","","| Terreno | Gana v400 | Gana IA oficial | Censuras |",
           "|---:|---:|---:|---:|"]
    for t in range(4):
        s=by_template[str(t)]
        md.append(f"| {t} | {s['candidate_wins']} | "
                  f"{s['official_ai_wins']} | {s['censored']} |")
    md += [
        "",
        "La interpretación de ganadores debe esperar los informes de "
        "autopartidas del padre v400, la paridad exacta de este estudio "
        "y la inspección por mapa/niebla/iniciativa. No habilitar la IA "
        "por resultados preliminares, ni inventar empates.",
        ""
    ]
    (folder_out/"ai_v401_head_to_head.md").write_text(
        "\n".join(md),encoding="utf-8")
    print("HEAD401_ALL "+json.dumps(report,ensure_ascii=False,separators=(",",":")))
    print("\n".join(md))
    print("PASS TARVOKA v401 aggregate: 64 true mixed-policy matches, 128 verified mirrored game executions")

if __name__=="__main__":
    main(sys.argv[1] if len(sys.argv)>1 else ".ci-v401-logs")
