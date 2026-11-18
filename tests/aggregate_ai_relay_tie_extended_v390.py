#!/usr/bin/env python3
"""Strict two-starter aggregation of extended seed636 fog relay-stalemate study.

One original game per starter and one mirror verification replay. The mirrors
never count as independent samples. A tie after the score threshold is NOT a
victory or a draw, and unresolved 64-half-turn games are censored.
"""
import json
import pathlib
import sys

PREFIX="TIE390_RESULT "
EXPECTED={0,1}

def cases(folder):
    found={}
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8",errors="replace").splitlines():
            pos=line.find(PREFIX+"{")
            if pos<0:
                continue
            row=json.loads(line[pos+len(PREFIX):])
            first=row["first"]
            assert first in EXPECTED and first not in found,("duplicate/unexpected",first)
            assert row["seed"]==636 and row["fog"] is True
            assert row["size"]=="40x30" and row["version"]=="v3.9.0"
            assert row["response_first_turn_orders"]==5
            assert row["starter_first_turn_orders"]==3
            assert row["half_turn_cutoff"]==64
            assert row["previous_32_cutoff_censored"] is True
            assert row["first_actions_and_gameplay_rules_unchanged"] is True
            assert row["mirror_exact"] is True
            assert row["original_game_and_mirror_replay"]==2
            assert row["independent_outcome_samples"]==1
            assert row["winner"] in [-1,0,1]
            assert row["censored"] is (row["winner"]==-1)
            assert row["terminal"] in ("winner","idle_stalemate","phase_limit")
            assert (row["terminal"]=="winner") is (row["winner"]!=-1)
            ledger=row["ledger"]
            steps=ledger["half_turns"]
            assert 32<=steps<=64 and steps%2==0
            assert ledger["first_faction"]==first
            assert ledger["at_half_turn_32"]["relay_scores"]==[9,9]
            assert ledger["at_half_turn_32"]["winner"]==-1
            assert len(ledger["rounds"])==steps//2
            assert ledger["completed_rounds"]==steps//2
            assert ledger["target"]==5
            assert ledger["total_actions"]>=0 and ledger["total_attacks"]>=0
            assert sum(ledger["captures_by_faction"])>=0
            assert ledger["last"]["winner"]==row["winner"]
            assert ledger["rounds"][15]["round"]==16
            assert ledger["rounds"][15]["scores"]==[9,9]
            assert ledger["rounds"][15]["tied_above_target"] is True
            previous=[0,0]
            tie_streak=0
            streak_max=0
            for i,r in enumerate(ledger["rounds"]):
                assert r["round"]==i+1
                holdings=r["holdings_after_response"]
                assert len(holdings)==2 and 0<=sum(holdings)<=4
                expected=[previous[j]+holdings[j] for j in (0,1)]
                assert r["scores"]==expected,("incorrect original relay payout",first,i)
                assert r["leader"] in [-1,0,1]
                if r["leader"]==-1:
                    assert r["scores"][0]==r["scores"][1]
                if r["tied_above_target"]:
                    assert r["scores"][0]==r["scores"][1] and r["scores"][0]>=5
                    tie_streak+=1
                else:
                    tie_streak=0
                streak_max=max(streak_max,tie_streak)
                assert r["first_half_turn_orders"]>=0 and r["responder_orders"]>=0
                assert r["winner"] in [-1,0,1]
                previous=r["scores"]
            assert streak_max==ledger["longest_consecutive_tied_scoring_rounds"]
            assert previous==ledger["last"]["relay_scores"]
            found[first]=row
    assert set(found)==EXPECTED,("incomplete two-starter forensic sample",found.keys())
    return found

def main(folder):
    found=cases(folder)
    results=[found[k] for k in sorted(found)]
    overview={
        "version":"v3.9.0",
        "scope":"seed636, fog true, size 40x30, experimental cap5",
        "previous_32_half_turn_score":"9-9 for both first-side identities",
        "new_max_half_turns":64,
        "original_independent_conditions":2,
        "mirror_validation_replays":2,
        "real_authoritative_games":4,
        "censored_at_64":sum(x["censored"] for x in results),
        "decisive_at_64":sum(not x["censored"] for x in results),
        "winner_is_first":sum(x["winner"]==x["first"] for x in results),
        "winner_is_responder":sum(x["winner"]==1-x["first"] for x in results),
        "first_unique_lead_after_target": {
            str(x["first"]):x["ledger"]["first_round_unique_leader_at_or_above_target"]
            for x in results
        },
        "first_tied_scoring_round": {
            str(x["first"]):x["ledger"]["first_round_tied_at_or_above_target"]
            for x in results
        },
        "longest_tied_streak_rounds":{
            str(x["first"]):x["ledger"]["longest_consecutive_tied_scoring_rounds"]
            for x in results
        },
        "scores_at_64_or_natural_terminal":{
            str(x["first"]):x["ledger"]["last"]["relay_scores"] for x in results
        },
        "relay_holdings_at_64_or_natural_terminal":{
            str(x["first"]):x["ledger"]["last"]["relay_holdings"] for x in results
        },
        "capture_events":{
            str(x["first"]):x["ledger"]["captures_by_faction"] for x in results
        },
        "no_rules_changed":True,
        "no_auto_draw_awarded":True,
        "no_mirrors_counted_as_outcomes":True,
        "warnings":[
            "Two starter identities on one map are correlated, not a general win-rate estimate.",
            "A 64-half-turn timeout without winner is censored, never an artificial draw.",
            "The existing relay win condition deliberately continues past a score tie at/above five.",
            "This work does not propose to break ties by initiative or award any side extra signal.",
            "No alteration to engine, target, opening rules, AI, fog, movement, combat, income, APK or main."
        ]
    }
    path=pathlib.Path("reports")
    path.mkdir(parents=True,exist_ok=True)
    (path/"ai_v390_relay_tie_longitudinal.json").write_text(
        json.dumps({"summary":overview,"games":results},indent=2,ensure_ascii=False)+"\n",
        encoding="utf-8")
    md=[
        "# TARVOKA v3.9.0 — Empate 9–9 de relés después del turno 32",
        "",
        "**Semilla 636, 40×30 con niebla, respuesta experimental limitada a cinco órdenes.**",
        "",
        "Ambas identidades de iniciador reprodujeron el marcador **9–9 tras 32 medios turnos**. "
        "La puntuación no dicta empate automático: hace falta ventaja numérica después "
        "de que ambos jugadores hayan actuado.",
        "",
        "| Iniciador | Resultado después de ampliar horizonte | Medio turnos | Puntos finales | Relés al final | Ronda primera ventaja > objetivo | Racha más larga de empates de ronda |",
        "|---:|---|---:|---|---|---:|---:|"
    ]
    for row in results:
        d=row["ledger"]
        result="Censurado" if row["censored"] else ("Gana primero" if row["winner"]==row["first"] else "Gana segundo")
        md.append(f"| {row['first']} | {result} | {d['half_turns']} | "
            f"{d['last']['relay_scores']} | {d['last']['relay_holdings']} | "
            f"{d['first_round_unique_leader_at_or_above_target']} | "
            f"{d['longest_consecutive_tied_scoring_rounds']} |")
    md += [
        "",
        "**Este resultado aclara la censura de v3.8.8, pero no justifica "
        "cambiar los desempates ni el objetivo de cinco puntos.**",
        "",
        "Todas las rondas incluyen control de los cuatro relés al cerrar, capturas "
        "del primer medio turno y de la respuesta, puntos, tropas restantes, "
        "acciones y verificación de espejo exacto. El JSON adjunto conserva "
        "la cronología para analizar los cambios de propietario.",
        "",
        "**Sin cambios de reglas ni APK.**",
        ""
    ]
    (path/"ai_v390_relay_tie_longitudinal.md").write_text(
        "\n".join(md),encoding="utf-8")
    print("TIE390_ALL "+json.dumps(overview,separators=(",",":"),ensure_ascii=False))
    print("\n".join(md))
    print("PASS TARVOKA v390 aggregate: both starters audited with exact mirrors, genuine 9:9 at half-turn 32")

if __name__=="__main__":
    main(sys.argv[1] if len(sys.argv)>1 else ".ci-v390-logs")
