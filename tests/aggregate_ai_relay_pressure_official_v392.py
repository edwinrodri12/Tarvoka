#!/usr/bin/env python3
"""Validate v3.9.2 official-opening AI candidate on 32 holdout conditions.

4 templates x 2 fog states x 2 starters x 2 seeds per template.
Original paired games are counted ONCE; 64 reflection replays validate
exact parity only. An unresolved game is censored, never called a draw.
"""
import json
import pathlib
import sys

PREFIX="OFF392_RESULT "
SEEDS=tuple(range(634,642))
POLICIES=("baseline","candidate")

def read(folder):
    found={}
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8",errors="replace").splitlines():
            i=line.find(PREFIX+"{")
            if i<0:continue
            row=json.loads(line[i+len(PREFIX):])
            key=(row["seed"],row["fog"],row["first"])
            assert key not in found and key[0] in SEEDS,("duplicate or invalid",key)
            assert type(row["fog"]) is bool and row["first"] in (0,1)
            assert row["version"]=="v3.9.2" and row["size"]=="40x30"
            assert row["template"]==row["seed"]%4
            assert row["opening_policy"]=="official_starter3_responder_unrestricted"
            assert row["candidate_only_opt_in"] is True
            assert row["production_rules_changed"] is False
            assert row["observation_half_turns"]==48
            assert row["original_samples_per_policy"]==1
            assert row["mirror_replays_per_policy"]==1
            baseline=row["baseline"]
            candidate=row["candidate"]
            for name,g in (("baseline",baseline),("candidate",candidate)):
                assert g["winner"] in (-1,0,1)
                assert g["censored"] is (g["winner"]==-1)
                assert g["winner_first"] is (g["winner"]==row["first"])
                assert g["winner_responder"] is (g["winner"]==1-row["first"])
                assert len(g["scores"])==2
                assert 0<g["half_turns"]<=48
                assert 5<=g["first_response_orders"]<=1000
                assert g["actions"]>=0 and g["attacks"]>=0 and g["purchases"]>=0
            assert baseline["first_response_orders"]==candidate["first_response_orders"]
            assert not baseline["censored"] and baseline["half_turns"]<=32
            change=row["first_divergence"]
            if change["changed"]:
                assert change["frame"]>=0 and change["phase"]>=0
                assert change["legal_tied_score"] is True
                assert change["scores_before"][0]==change["scores_before"][1]
                assert change["scores_before"][0]>=change["target"]
            else:
                assert change["frame"]==-1 and change["phase"]==-1
                assert change["legal_tied_score"] is False
                assert baseline==candidate,("no action change but results differ",key)
            found[key]=row
    expected={(seed,fog,first) for seed in SEEDS
              for fog in (False,True) for first in (0,1)}
    assert set(found)==expected and len(found)==32,(
        "incomplete 32-condition matrix",len(found), sorted(expected-set(found)))
    return [found[k] for k in sorted(expected)]

def summary(rows,policy):
    games=[r[policy] for r in rows]
    assert games
    return {
        "original_conditions":len(games),
        "completed":sum(not g["censored"] for g in games),
        "censored":sum(g["censored"] for g in games),
        "first_wins":sum(g["winner_first"] for g in games),
        "responder_wins":sum(g["winner_responder"] for g in games),
        "total_half_turns":sum(g["half_turns"] for g in games),
        "total_actions":sum(g["actions"] for g in games),
        "total_attacks":sum(g["attacks"] for g in games),
        "total_purchases":sum(g["purchases"] for g in games)
    }

def summarize(rows):
    baseline=summary(rows,"baseline")
    candidate=summary(rows,"candidate")
    changed=[r for r in rows if r["first_divergence"]["changed"]]
    win_changed=[r for r in rows if r["baseline"]["winner"]!=r["candidate"]["winner"]]
    improved=sum(not r["baseline"]["winner_first"] and r["candidate"]["winner_first"] for r in rows)
    worsened=sum(r["baseline"]["winner_first"] and not r["candidate"]["winner_first"] for r in rows)
    per_fog={str(fog).lower():{k:summary([r for r in rows if r["fog"]==fog],k)
            for k in POLICIES} for fog in (False,True)}
    per_template={str(t):{k:summary([r for r in rows if r["template"]==t],k)
            for k in POLICIES} for t in range(4)}
    report={
        "version":"v3.9.2","status":"research_only",
        "question":"Does opt-in relay tie pressure improve results with the REAL official first-response policy?",
        "unseen_seeds":list(SEEDS),
        "size":"40x30",
        "conditions_original":32,
        "authoritative_games_including_mirrors":128,
        "original_outcome_samples_per_policy":32,
        "mirror_replays_per_policy":32,
        "mirrors_are_not_independent":True,
        "opening_policy_unchanged":True,
        "production_default_flag_off":True,
        "engine_rules_changed":False,
        "half_turn_observation_limit":48,
        "by_policy":{"baseline":baseline,"candidate":candidate},
        "by_fog":per_fog,
        "by_template":per_template,
        "pairs_with_tactical_action_difference":len(changed),
        "pairs_with_different_winner_or_censor":len(win_changed),
        "pairs_switch_responder_to_first":improved,
        "pairs_switch_first_to_responder_or_censor":worsened,
        "first_tactical_deviation_by_case":[{
            "seed":r["seed"],"fog":r["fog"],"first":r["first"],
            "first_phase":r["first_divergence"]["phase"],
            "before_scores":r["first_divergence"].get("scores_before",[]),
            "baseline_winner":r["baseline"]["winner"],
            "candidate_winner":r["candidate"]["winner"],
            "baseline_half_turns":r["baseline"]["half_turns"],
            "candidate_half_turns":r["candidate"]["half_turns"]
        } for r in changed],
        "warnings":[
            "The starter remains capped at three orders by EXISTING game rules; the first response remains unrestricted. We did not use the cap5 counterfactual.",
            "This single self-play AI setup and deterministic seed collection do not prove fair human matchmaking.",
            "The same map with two starting identities is paired and correlated; mirrored games only establish exact parity.",
            "Unresolved at 48 half turns is censored, not a draw or a second-player win.",
            "Changing AI before an observed enemy owner in fog is invalid; all first changes are checked against previously visible tied-at-target scores.",
            "No production flag is enabled; no change in scoring, relay capture, combat, fog, money, opening, save data, APK or main."
        ]
    }
    out=pathlib.Path("reports")
    out.mkdir(parents=True,exist_ok=True)
    (out/"ai_v392_official_pressure_holdout.json").write_text(
        json.dumps({"summary":report,"cases":rows},ensure_ascii=False,indent=2)+"\n",
        encoding="utf-8")
    md=[
        "# TARVOKA v3.9.2 — Prueba de la IA de relés con apertura OFICIAL",
        "",
        "Ocho semillas nuevas 634–641 × niebla sí/no × iniciador 0/1: "
        "**32 condiciones emparejadas**. Cada una se juega con IA actual "
        "e IA opcional, y ambas se reflejan: **128 partidas**, 32 "
        "resultados originales por política.",
        "",
        "| IA | Gana primero | Gana segundo | Inconclusas | Medios turnos totales |",
        "|---|---:|---:|---:|---:|"
    ]
    for p in POLICIES:
        s=report["by_policy"][p]
        md.append(f"| {p} | {s['first_wins']} | {s['responder_wins']} | "
                  f"{s['censored']} | {s['total_half_turns']} |")
    md += ["","## Por visibilidad","","| Niebla | IA | Primero | Segundo | Inconclusas |",
            "|---|---|---:|---:|---:|"]
    for fog in ("false","true"):
        for p in POLICIES:
            s=per_fog[fog][p]
            md.append(f"| {fog} | {p} | {s['first_wins']} | {s['responder_wins']} | {s['censored']} |")
    md += ["", "## Por tipo de mapa","",
            "| Plantilla | IA | Primero | Segundo | Inconclusas |",
            "|---:|---|---:|---:|---:|"]
    for t in range(4):
        for p in POLICIES:
            s=per_template[str(t)][p]
            md.append(f"| {t} | {p} | {s['first_wins']} | {s['responder_wins']} | {s['censored']} |")
    md += ["",
        f"**{len(changed)}/32** condiciones modificaron alguna acción; "
        f"**{len(win_changed)}/32** cambiaron resultado; "
        f"**{improved}** favorecieron al iniciador, **{worsened}** lo perjudicaron.",
        "",
        "Si una condición no cambió ninguna acción, ambas partidas han de tener "
        "exactamente el mismo resultado. Si cambió, su primer cambio debe "
        "producirse únicamente DESPUÉS de que ambos puntajes públicos "
        "alcanzaran el objetivo y estuvieran empatados.",
        "",
        "**Esto es una prueba comparativa, no aprobación para habilitar la opción en el juego.**",
        ""
    ]
    (out/"ai_v392_official_pressure_holdout.md").write_text(
        "\n".join(md),encoding="utf-8")
    print("OFF392_ALL "+json.dumps({k:v for k,v in report.items() if k!="first_tactical_deviation_by_case"},
        ensure_ascii=False,separators=(",",":")))
    print("\n".join(md))
    print("PASS TARVOKA v392 aggregate: 32 real official-opening comparisons with 128 exact mirrored sessions")

if __name__=="__main__":
    main(sys.argv[1] if len(sys.argv)>1 else ".ci-v392-logs")
