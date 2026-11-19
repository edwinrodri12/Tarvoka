#!/usr/bin/env python3
"""TARVOKA v3.9.8 strict holdout for optional observed-only relay-race AI.

8 new seeds spanning four map templates x fog yes/no x both starters.
32 paired ORIGINAL control/candidate results. Their 64 exact mirrors
only test parity, never increase independent outcome sample size.
"""
import json
import pathlib
import sys

PREFIX="RACE398_RESULT "
SEEDS=tuple(range(666,674))
POLICIES=("baseline","candidate")

def load(folder):
    found={}
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8",errors="replace").splitlines():
            pos=line.find(PREFIX+"{")
            if pos<0:
                continue
            row=json.loads(line[pos+len(PREFIX):])
            key=(row["seed"],row["fog"],row["first"])
            assert key not in found,("duplicate",key)
            assert row["seed"] in SEEDS and row["template"]==row["seed"]%4
            assert type(row["fog"]) is bool and row["first"] in (0,1)
            assert row["version"]=="v3.9.8" and row["size"]=="40x30"
            assert row["max_half_turns"]==36
            assert row["opening_official"] is True
            assert row["default_new_planner_disabled"] is True
            assert row["no_rules_changed"] is True
            assert row["baseline_mirrored_exact"] is True
            assert row["candidate_mirrored_exact"] is True
            assert row["one_original_per_policy"]==1
            assert row["one_mirror_per_policy"]==1
            for p in POLICIES:
                g=row[p]
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
            delta=row["first_divergence"]
            assert type(delta["changed"]) is bool
            if delta["changed"]:
                assert delta["index"]>=1
                if not delta.get("trace_size_only",False):
                    assert delta["phase"]>=0
                    assert delta["visible_enemy_count"]>0
                    assert delta["first_side"] in (0,1)
                    assert len(delta["scores_before"])==2
            else:
                assert delta["index"]==-1 and delta["phase"]==-1
                assert row["baseline"]==row["candidate"],(
                    "no frame divergence, but outcome differs",key)
            found[key]=row
    expected={(s,fog,first) for s in SEEDS
              for fog in (False,True) for first in (0,1)}
    assert set(found)==expected and len(found)==32,(
        "incomplete matrix",len(found),sorted(expected-set(found)))
    return [found[key] for key in sorted(expected)]

def policy_stats(rows,p):
    games=[r[p] for r in rows]
    assert games
    return {
        "original_conditions":len(games),
        "completed":sum(not g["censored"] for g in games),
        "censored":sum(g["censored"] for g in games),
        "first_wins":sum(g["starter_wins"] for g in games),
        "responder_wins":sum(g["responder_wins"] for g in games),
        "half_turn_total":sum(g["half_turns"] for g in games),
        "half_turn_average":sum(g["half_turns"] for g in games)/len(games),
        "total_actions":sum(g["actions"] for g in games),
        "total_attacks":sum(g["attacks"] for g in games),
        "total_purchases":sum(g["purchases"] for g in games),
        "relay_captures":sum(sum(g["relay_captures"]) for g in games),
        "first_starter_relay_capture":sum(
            g["first_capture_phase"][r["first"]]>=0 and (
                g["first_capture_phase"][1-r["first"]]<0 or
                g["first_capture_phase"][r["first"]]<
                g["first_capture_phase"][1-r["first"]])
            for r,g in zip(rows,games))
    }

def main(folder):
    rows=load(folder)
    changed=[r for r in rows if r["first_divergence"]["changed"]]
    report={
        "version":"v3.9.8","status":"research_only_not_a_balance_rule",
        "question":"Can the AI anticipate a contest for a neutral relay using visible enemy positions and legal weighted terrain routes?",
        "unseen_seeds":list(SEEDS),
        "map_templates":list(range(4)),
        "size":"40x30",
        "fog":[False,True],
        "first_starters":[0,1],
        "original_independent_conditions":32,
        "real_games_including_exact_mirrors":128,
        "mirrors_counted_as_samples":False,
        "official_opening_unchanged":True,
        "default_planner_disabled":True,
        "only_fog_observed_enemy_paths":True,
        "production_rules_changed":False,
        "max_half_turns":36,
        "by_policy":{p:policy_stats(rows,p) for p in POLICIES},
        "by_fog":{
            str(fog).lower():{p:policy_stats(
                [r for r in rows if r["fog"]==fog],p) for p in POLICIES}
            for fog in (False,True)
        },
        "by_template":{
            str(t):{p:policy_stats([r for r in rows if r["template"]==t],p)
                    for p in POLICIES} for t in range(4)
        },
        "changed_first_action_pairs":len(changed),
        "pairs_changed_winner":sum(
            r["baseline"]["winner"]!=r["candidate"]["winner"] for r in rows),
        "pairs_responder_to_starter":sum(
            not r["baseline"]["starter_wins"] and
            r["candidate"]["starter_wins"] for r in rows),
        "pairs_starter_to_responder_or_censored":sum(
            r["baseline"]["starter_wins"] and
            not r["candidate"]["starter_wins"] for r in rows),
        "changes_by_fog":{
            str(fog).lower():sum(r["fog"]==fog for r in changed)
            for fog in (False,True)
        },
        "first_divergences":[{
            "seed":r["seed"],"fog":r["fog"],"first":r["first"],
            "index":r["first_divergence"]["index"],
            "phase":r["first_divergence"]["phase"],
            "visible_enemy_count":r["first_divergence"].get("visible_enemy_count",-1),
            "baseline_winner":r["baseline"]["winner"],
            "candidate_winner":r["candidate"]["winner"],
            "baseline_turns":r["baseline"]["half_turns"],
            "candidate_turns":r["candidate"]["half_turns"]
        } for r in changed],
        "warnings":[
            "Mirror replays verify exact symmetry only, never independent games.",
            "Starter color swaps on the same seed are correlated and do not establish a human matchmaking win rate.",
            "The AI only predicts approximate reach times for VISIBLE enemies and may choose a poor tradeoff with urban income.",
            "A trace divergence is not evidence of a strategic improvement; require outcome and fog safety before enabling.",
            "Unresolved games are censored, never tied or automatically awarded to the responder.",
            "The planner is explicitly disabled unless passed _ab_relay_race_forecast_v398=true.",
            "No changes to production gameplay, first-turn 3 orders, scoring, money, faction strengths, APK or main."
        ]
    }
    out=pathlib.Path("reports")
    out.mkdir(parents=True,exist_ok=True)
    (out/"ai_v398_observed_relay_race.json").write_text(
        json.dumps({"summary":report,"cases":rows},ensure_ascii=False,indent=2)+"\n",
        encoding="utf-8")
    md=[
        "# TARVOKA v3.9.8 — IA que anticipa la carrera por relés",
        "",
        "Estudio **opt-in**, sin cambiar reglas: 8 semillas nuevas (2 por "
        "plantilla) × dos nieblas × dos iniciadores = **32 comparaciones "
        "originales** entre IA actual y el nuevo planificador. Cada una "
        "reproducida en espejo exacto: 128 partidas en total, sin duplicar "
        "muestras por los espejos.",
        "",
        "| Política IA | Primero gana | Segundo gana | Censuradas | Media de medios turnos |",
        "|---|---:|---:|---:|---:|"
    ]
    for p in POLICIES:
        s=report["by_policy"][p]
        md.append(f"| {p} | {s['first_wins']} | {s['responder_wins']} | "
                  f"{s['censored']} | {s['half_turn_average']:.2f} |")
    md += ["","## Por niebla","","| Niebla | Política | Primero | Segundo | Censuradas |",
           "|---|---|---:|---:|---:|"]
    for fog in ("false","true"):
        for p in POLICIES:
            s=report["by_fog"][fog][p]
            md.append(f"| {fog} | {p} | {s['first_wins']} | "
                      f"{s['responder_wins']} | {s['censored']} |")
    md += ["","## Por tipo de terreno","","| Tipo | Política | Primero | Segundo | Censuradas |",
           "|---:|---|---:|---:|---:|"]
    for t in range(4):
        for p in POLICIES:
            s=report["by_template"][str(t)][p]
            md.append(f"| {t} | {p} | {s['first_wins']} | "
                      f"{s['responder_wins']} | {s['censored']} |")
    md += ["",
        f"En {report['changed_first_action_pairs']}/32 condiciones cambió "
        f"alguna acción. {report['pairs_changed_winner']}/32 cambiaron "
        f"ganador o censura. {report['pairs_responder_to_starter']} "
        f"favorecieron al iniciador; {report['pairs_starter_to_responder_or_censored']} "
        "lo perjudicaron.",
        "",
        "**No activar el planificador por defecto hasta demostrar mejora "
        "robusta y ausencia de fugas de información con niebla.**",
        ""
    ]
    (out/"ai_v398_observed_relay_race.md").write_text(
        "\n".join(md),encoding="utf-8")
    print("RACE398_ALL "+json.dumps({k:v for k,v in report.items()
        if k!="first_divergences"},ensure_ascii=False,separators=(",",":")))
    print("\n".join(md))
    print("PASS TARVOKA v398 aggregate: 32 original paired conditions, 128 exact mirrored games")

if __name__=="__main__":
    main(sys.argv[1] if len(sys.argv)>1 else ".ci-v398-logs")
