#!/usr/bin/env python3
"""Strict experimental direct matches of v403 liquidity buffer.

8 unseen seeds 706-713 x fog 2 x first player 2 x assigned candidate
faction 2 x opponent policy 2 = 128 ORIGINAL competitive battles.
Every one has a reflected policy-swapped replay: 256 real games,
NOT 256 independent samples. At most 36 half-turns per game.
"""
import json
import pathlib
import sys

PREFIX="RESERVE403_RESULT "
SEEDS=tuple(range(706,714))
OPPONENTS=("official","v400")
EXPECTED={
    (seed,fog,first,candidate,other)
    for seed in SEEDS for fog in (False,True)
    for first in (0,1) for candidate in (0,1)
    for other in OPPONENTS
}

def read(folder):
    rows={}
    for file in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in file.read_text(encoding="utf-8",errors="replace").splitlines():
            i=line.find(PREFIX+"{")
            if i<0:
                continue
            row=json.loads(line[i+len(PREFIX):])
            key=(row["seed"],row["fog"],row["first"],
                 row["candidate_side"],row["opponent_policy"])
            assert key in EXPECTED and key not in rows,("unexpected case",key)
            assert row["version"]=="v4.0.3"
            assert type(row["fog"]) is bool
            assert row["template"]==row["seed"]%4
            assert row["size"]=="40x30" and row["horizon"]==36
            assert row["candidate_starts"] is (
                row["candidate_side"]==row["first"])
            assert row["candidate_flags"]=={
                "_ab_economic_arbitration_v400":True,
                "_ab_recruit_reserve_v403":True
            }
            assert row["opponent_flags"]==(
                {"_ab_economic_arbitration_v400":True}
                if row["opponent_policy"]=="v400" else {})
            for key2 in (
                "official_first_three_orders",
                "money_and_game_rules_unchanged",
                "reflections_identical"
            ):
                assert row[key2] is True,key2
            assert row["original_games"]==1 and row["mirror_games"]==1
            game=row["outcome"]
            assert game["winner"] in (-1,0,1)
            assert game["candidate_wins"] is (
                game["winner"]==row["candidate_side"])
            assert game["opponent_wins"] is (
                game["winner"]==1-row["candidate_side"])
            assert game["censored"] is (game["winner"]==-1)
            assert (game["terminal"]=="winner") is not game["censored"]
            assert game["terminal"] in (
                "winner","phase_limit","idle_stalemate")
            assert game["candidate_starts"] is row["candidate_starts"]
            assert game["scores_match_terminal"] is True
            assert game["first_3_orders_preserved"] is True
            assert 0<game["half_turns"]<=36
            assert all(game[k]>=0 for k in (
                "candidate_score","opponent_score","candidate_cash",
                "opponent_cash","actions","purchases","attacks","moves"))
            rows[key]=row
    assert set(rows)==EXPECTED,(
        "missing/excess cases",
        sorted(EXPECTED-set(rows)),sorted(set(rows)-EXPECTED))
    return [rows[key] for key in sorted(EXPECTED)]

def stats(rows):
    assert rows
    games=[r["outcome"] for r in rows]
    wins=sum(g["candidate_wins"] for g in games)
    losses=sum(g["opponent_wins"] for g in games)
    censored=sum(g["censored"] for g in games)
    assert wins+losses+censored==len(games)
    return {
        "original_battles":len(games),
        "v403_wins":wins,"opponent_wins":losses,
        "censored":censored,
        "decisive_win_rate":wins/(wins+losses) if wins+losses else None,
        "v403_signal":sum(g["candidate_score"] for g in games),
        "opponent_signal":sum(g["opponent_score"] for g in games),
        "signal_margin":sum(
            g["candidate_score"]-g["opponent_score"] for g in games),
        "v403_remaining_cash":sum(g["candidate_cash"] for g in games),
        "opponent_remaining_cash":sum(g["opponent_cash"] for g in games),
        "average_half_turns":sum(g["half_turns"] for g in games)/len(games),
        "total_purchases_both_sides":sum(g["purchases"] for g in games)
    }

def group(rows,field):
    return {str(x).lower() if isinstance(x,bool) else str(x):stats(
        [row for row in rows if row[field]==x])
        for x in sorted({row[field] for row in rows})}

def main(folder):
    rows=read(folder)
    overall=group(rows,"opponent_policy")
    by_role={
        opponent:{
            "first":stats([r for r in rows
                if r["opponent_policy"]==opponent and r["candidate_starts"]]),
            "second":stats([r for r in rows
                if r["opponent_policy"]==opponent and not r["candidate_starts"]])
        } for opponent in OPPONENTS
    }
    by_fog={
        opponent:{
            str(fog).lower():stats([r for r in rows
                if r["opponent_policy"]==opponent and r["fog"]==fog])
            for fog in (False,True)
        } for opponent in OPPONENTS
    }
    by_template={
        opponent:{
            str(t):stats([r for r in rows
                if r["opponent_policy"]==opponent and r["template"]==t])
            for t in range(4)
        } for opponent in OPPONENTS
    }
    by_seed={
        opponent:{
            str(seed):stats([r for r in rows
                if r["opponent_policy"]==opponent and r["seed"]==seed])
            for seed in SEEDS
        } for opponent in OPPONENTS
    }
    assert all(overall[p]["original_battles"]==64 for p in OPPONENTS)
    assert all(by_role[p][s]["original_battles"]==32
        for p in OPPONENTS for s in ("first","second"))
    assert all(by_fog[p][x]["original_battles"]==32
        for p in OPPONENTS for x in ("false","true"))
    assert all(by_template[p][str(t)]["original_battles"]==16
        for p in OPPONENTS for t in range(4))
    report={
        "version":"v4.0.3",
        "status":"experimental_only_not_auto_activated",
        "hypothesis":"Deferring expensive early reinforcement to preserve seven cycles of existing city income improves actual head-to-head strength",
        "seed_range":list(SEEDS),
        "map_templates":list(range(4)),
        "fog_modes":[False,True],
        "opponents":list(OPPONENTS),
        "original_competitive_battles":128,
        "genuine_cases_per_opponent":64,
        "games_including_exact_mirrors":256,
        "mirror_replays_are_not_independent":True,
        "official_three_action_opener":True,
        "gameplay_rules_and_actual_income_unchanged":True,
        "reserve_active_for_both_factions_when_assigned":True,
        "candidate_only_receives_opt_in_AI_options":True,
        "overall":overall,
        "by_candidate_starts":by_role,
        "by_fog":by_fog,
        "by_template":by_template,
        "by_seed":by_seed,
        "caveats":[
            "The 7-cycle reserve is a candidate policy choice, not a balance rule, a cash bonus, or a production prohibition for the human player.",
            "Only the candidate's own known city income and credits are inspected; emergencies must be based on visible enemies.",
            "After global half-turn 3 the candidate deliberately falls back to the unmodified economic arbitration policy.",
            "All tests use normal official three-order starter opening and real prices, credits and units.",
            "Mirror games certify parity, and shared-map assignments are correlated. Do not report 256 independent results.",
            "Win rates against deterministic official AI do not prove optimality against humans.",
            "Censored outcomes are NOT assigned to either faction or treated as draws.",
            "Do not deploy unless both reference comparisons and fog/role/template breakdowns support it."
        ]
    }
    out=pathlib.Path("reports")
    out.mkdir(parents=True,exist_ok=True)
    (out/"ai_v403_recruitment_reserve.json").write_text(
        json.dumps({"summary":report,"cases":rows},ensure_ascii=False,indent=2)+"\n",
        encoding="utf-8")
    md=[
        "# TARVOKA v4.0.3 — Disciplina económica de producción",
        "",
        "IA nueva v403 con **reserva de 7 ciclos de ingresos ya existentes** "
        "durante los primeros cuatro medios turnos. Solo evita determinadas "
        "compras costosas que dejen pocos créditos, excepto ante amenaza "
        "enemiga actualmente visible. No cambia precios, ingresos ni "
        "unidades. Flag OFF por defecto.",
        "",
        "**128 combates originales verdaderamente cruzados** en ocho semillas "
        "706–713, dos nieblas, ambos iniciadores, ambas facciones y dos "
        "rivales distintos. Cada uno se reprodujo con un espejo exacto: "
        "**256 partidas ejecutadas; no son 256 muestras independientes**.",
        "",
        "| Rival | Gana v403 | Gana rival | Censuras | Duración media |",
        "|---|---:|---:|---:|---:|"
    ]
    for p in OPPONENTS:
        x=overall[p]
        md.append(f"| {p} | {x['v403_wins']} | {x['opponent_wins']} | "
                  f"{x['censored']} | {x['average_half_turns']:.2f} |")
    md+=["","## Según quien inicia","","| Rival | v403 posición | V403 | Rival | Censuras |",
         "|---|---|---:|---:|---:|"]
    for p in OPPONENTS:
        for side in ("first","second"):
            x=by_role[p][side]
            md.append(f"| {p} | {side} | {x['v403_wins']} | "
                      f"{x['opponent_wins']} | {x['censored']} |")
    md+=["","## Niebla","","| Rival | Niebla | V403 | Rival | Censuras |",
         "|---|---|---:|---:|---:|"]
    for p in OPPONENTS:
        for fog in ("false","true"):
            x=by_fog[p][fog]
            md.append(f"| {p} | {fog} | {x['v403_wins']} | "
                      f"{x['opponent_wins']} | {x['censored']} |")
    md+=["","## Plantilla","","| Rival | Terreno | V403 | Rival | Censuras |",
         "|---|---:|---:|---:|---:|"]
    for p in OPPONENTS:
        for t in range(4):
            x=by_template[p][str(t)]
            md.append(f"| {p} | {t} | {x['v403_wins']} | "
                      f"{x['opponent_wins']} | {x['censored']} |")
    md+=["",
         "**Criterio:** no concluir que la reserva es beneficiosa si solo "
         "gana al jugar segundo, con niebla determinada, o en una plantilla; "
         "validar CI de legalidad y espejo, más resultados de enfrentamiento "
         "directo con ambas identidades. Mantener OFF hasta aprobación.",
         ""]
    (out/"ai_v403_recruitment_reserve.md").write_text(
        "\n".join(md),encoding="utf-8")
    print("RESERVE403_ALL "+json.dumps({k:v for k,v in report.items()
        if k!="by_seed"},ensure_ascii=False,separators=(",",":")))
    print("\n".join(md))
    print("PASS TARVOKA v403 aggregate: 128 true direct competitive battles with 256 mirror-inclusive exact games")

if __name__=="__main__":
    main(sys.argv[1] if len(sys.argv)>1 else ".ci-v403-logs")
