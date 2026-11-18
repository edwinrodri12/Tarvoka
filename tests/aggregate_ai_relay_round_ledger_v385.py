#!/usr/bin/env python3
"""TARVOKA v3.8.5: inspectable round-by-round relay accounting from actual battles.

Strict exact 4 templates x fog yes/no x starter 0/1 matrix. One original
game per condition, plus its reflection for parity; reflected games never
double independent outcome or capture sample counts.
"""
import json
import pathlib
import sys

PREFIX = "RELAY385_RESULT "
SEEDS = (630, 631, 632, 633)

def load(folder):
    data = []
    for file in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in file.read_text(encoding="utf-8", errors="replace").splitlines():
            p = line.find(PREFIX + "{")
            if p >= 0:
                data.append(json.loads(line[p+len(PREFIX):]))
    return data

def count_to(changes, side):
    return sum(t["to"] == side for t in changes)

def inspect_condition(g):
    assert g["size"] == "40x30" and g["seed"] in SEEDS
    assert type(g["fog"]) is bool and g["first"] in (0, 1)
    assert g["template"] == g["seed"] % 4
    assert g["winner"] in (0, 1) and g["terminal"] == "winner"
    assert g["winner_is_first"] is (g["winner"] == g["first"])
    assert g["winner_is_responder"] is (g["winner"] == 1-g["first"])
    assert g["mirror_equal"] is True
    assert g["actual_games"] == 2 and g["independent_outcome_samples"] == 1
    assert 0 < g["half_turns"] <= 24 and g["half_turns"] % 2 == 0
    assert g["actions"] >= 0 and g["attacks"] >= 0 and g["purchases"] >= 0
    t = g["timeline"]
    rows = t["rounds"]
    assert len(rows) == g["half_turns"] // 2
    assert t["first_turn_orders"] == 3
    assert t["first_response_orders"] >= 3
    assert len(rows) >= 1
    first = g["first"]
    responder = 1-first
    prev_score = [0, 0]
    prev_owned = [0, 0]
    cap_starter = 0
    cap_responder = 0
    cap_responder_stolen = 0
    by_side = [0, 0]
    for i, r in enumerate(rows):
        assert r["round"] == i+1
        assert r["first_actor"] == first
        assert r["responder"] == responder
        assert r["at_start"] == prev_owned
        assert r["score_before"] == prev_score
        assert r["score_after_starter"] == prev_score, (
            "first actor got extra signal before paired settlement", g["seed"], i)
        assert len(r["after_starter"]) == 2
        assert len(r["before_scoring"]) == 2
        assert sum(r["before_scoring"]) <= 4
        assert r["score_after_reply"] == [
            r["score_before"][s] + r["before_scoring"][s] for s in (0, 1)]
        assert r["actual_payout"] == r["before_scoring"]
        assert r["winner_after_round"] in (-1,0,1)
        for who, key, start, end in (
            (first, "starter_captures", r["at_start"], r["after_starter"]),
            (responder, "response_captures", r["after_starter"], r["before_scoring"]),
        ):
            changes = r[key]
            expected = end[who]-start[who]
            stolen_from_other = sum(c["from"] == 1-who for c in changes)
            # Capture to a tile already owned by the enemy changes both counts.
            assert expected == len(changes)
            assert end[1-who] == start[1-who]-stolen_from_other
            for c in changes:
                assert c["to"] == who
                assert c["from"] in (-1,1-who)
                assert c["neutral_taken"] is (c["from"] == -1)
                assert c["stolen"] is (c["from"] == 1-who)
                by_side[who] += 1
        starter_cap = len(r["starter_captures"])
        reply_cap = len(r["response_captures"])
        cap_starter += starter_cap
        cap_responder += reply_cap
        cap_responder_stolen += sum(x["stolen"] for x in r["response_captures"])
        if i < len(rows)-1:
            assert r["winner_after_round"] == -1
        else:
            assert r["winner_after_round"] == g["winner"]
            assert r["score_after_reply"][g["winner"]] > r["score_after_reply"][1-g["winner"]]
        prev_score = r["score_after_reply"]
        prev_owned = r["before_scoring"]
    assert cap_starter == t["starter_capture_events"]
    assert cap_responder == t["responder_capture_events"]
    assert cap_responder_stolen == t["responder_takeovers"]
    assert by_side == t["capture_events_by_color"]
    assert t["last_round"] == rows[-1]
    assert t["responder_wins_with_capture_same_round"] in (0,1)
    assert t["responder_wins_with_capture_same_round"] == int(
        g["winner"] == responder and bool(rows[-1]["response_captures"]))
    return {
        "starter_capture_events":cap_starter,
        "responder_capture_events":cap_responder,
        "responder_steals":cap_responder_stolen,
        "last_round_reply_captured":len(rows[-1]["response_captures"]) > 0,
        "last_round_reply_points":rows[-1]["actual_payout"][responder],
        "last_round_starter_points":rows[-1]["actual_payout"][first],
    }

def main(folder):
    games = load(folder)
    expected = {(seed,fog,first) for seed in SEEDS
                for fog in (False,True) for first in (0,1)}
    seen = {}
    derived = {}
    for game in games:
        key = (game["seed"],game["fog"],game["first"])
        assert key in expected and key not in seen, ("invalid/duplicate",key)
        seen[key] = game
        derived[key] = inspect_condition(game)
    assert len(games) == 16 and set(seen) == expected, (
        "incomplete 16-game independent matrix", len(games),sorted(expected-set(seen)))
    for seed in SEEDS:
        for fog in (False,True):
            a = seen[(seed,fog,0)]
            b = seen[(seed,fog,1)]
            # Both starters see the same terrain, fog and roster, but
            # opposite colors can win. This check alone does not assert
            # which order should be favored.
            assert a["template"] == b["template"]
    summaries = {}
    for group,label,values in [
        ("fog","fog",(False,True)),
        ("template","template",(0,1,2,3)),
    ]:
        summaries[group] = {}
        for value in values:
            selected = [(key,g) for key,g in seen.items() if g[group] == value]
            assert len(selected) == (8 if group=="fog" else 4)
            summaries[group][str(value).lower()] = {
                "original_games":len(selected),
                "first_wins":sum(g["winner_is_first"] for _,g in selected),
                "responder_wins":sum(g["winner_is_responder"] for _,g in selected),
                "starter_capture_events":sum(derived[k]["starter_capture_events"] for k,_ in selected),
                "response_capture_events":sum(derived[k]["responder_capture_events"] for k,_ in selected),
                "response_steals":sum(derived[k]["responder_steals"] for k,_ in selected),
                "response_winner_with_last_round_capture":sum(
                    g["winner_is_responder"] and derived[k]["last_round_reply_captured"]
                    for k,g in selected),
                "total_scored_rounds":sum(len(g["timeline"]["rounds"]) for _,g in selected),
                "total_first_turn_orders":sum(g["timeline"]["first_turn_orders"] for _,g in selected),
                "total_first_reply_orders":sum(g["timeline"]["first_response_orders"] for _,g in selected),
                "winning_side_score_margin_total":sum(
                    g["timeline"]["last_round"]["score_after_reply"][g["winner"]] -
                    g["timeline"]["last_round"]["score_after_reply"][1-g["winner"]]
                    for _,g in selected),
            }
    reply_advantage_rounds = []
    for key,g in seen.items():
        first = g["first"]
        second = 1-first
        for round_info in g["timeline"]["rounds"]:
            if round_info["response_captures"]:
                reply_advantage_rounds.append({
                    "seed":key[0],"fog":key[1],"first":key[2],
                    "round":round_info["round"],
                    "responder_captured":len(round_info["response_captures"]),
                    "starter_owned_before":round_info["after_starter"][first],
                    "responder_owned_before":round_info["after_starter"][second],
                    "starter_owned_at_payoff":round_info["before_scoring"][first],
                    "responder_owned_at_payoff":round_info["before_scoring"][second],
                    "scored":[round_info["actual_payout"][first],
                              round_info["actual_payout"][second]],
                    "winner_after_round":round_info["winner_after_round"]
                })
    report = {
        "version":"v3.8.5",
        "study":"round-by-round actual relay ownership and payout within real AI battles",
        "scope":"40x30 x 4 map templates x 2 fog states x 2 starters",
        "max_half_turns":24,
        "original_games":16,
        "mirror_validation_replays":16,
        "actual_games_executed":32,
        "independent_outcome_samples":16,
        "mirrors_not_independent_samples":True,
        "no_gameplay_or_balance_changes":True,
        "all_scores_check_against_actual_round_end_ownership":True,
        "all_first_half_turns_have_zero_signal_payout":True,
        "original_first_wins":sum(g["winner_is_first"] for g in games),
        "original_responder_wins":sum(g["winner_is_responder"] for g in games),
        "total_scored_rounds":sum(len(g["timeline"]["rounds"]) for g in games),
        "total_response_capture_events":sum(x["responder_capture_events"] for x in derived.values()),
        "total_starter_capture_events":sum(x["starter_capture_events"] for x in derived.values()),
        "total_response_steals":sum(x["responder_steals"] for x in derived.values()),
        "rounds_with_responder_capture":len(reply_advantage_rounds),
        "by":summaries,
        "response_capture_rounds":reply_advantage_rounds,
        "games":sorted(games,key=lambda x:(x["seed"],x["fog"],x["first"])),
        "warnings":[
            "Every game was run using the existing asymmetric three-order starter opening; this isolates real baseline timing, not a matched-opening causal change.",
            "A responder can capture at end of its half turn just before the scoring boundary, but this is NOT an automatic score bonus.",
            "Captures on a final round cannot by themselves establish causal victory; outcomes also depend on past rounds and held relay income.",
            "Fixed seeds and one deterministic AI policy are too small to estimate a universal second-player win rate.",
            "Mirrored replays confirm parity only and are not extra statistical observations.",
            "No live rules, opening orders, incomes, terrain, APK or main branch were modified."
        ]
    }
    out=pathlib.Path("reports")
    out.mkdir(parents=True,exist_ok=True)
    (out/"ai_v385_relay_round_ledger.json").write_text(
        json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    md=[
        "# TARVOKA v3.8.5 — Capturas antes del cierre de ronda",
        "",
        f"**{report['original_games']} partidas originales** y "
        f"**{report['mirror_validation_replays']} reflejos** validados "
        "(no se duplican muestras).",
        "",
        f"**Ganador:** primero {report['original_first_wins']}, "
        f"respondedor {report['original_responder_wins']}. "
        f"Rondas contadas: {report['total_scored_rounds']}.",
        "",
        "| Grupo | Partidas | Gana primero | Gana segundo | Capturas iniciador | Capturas respondedor | Arrebatos respondedor |",
        "|---|---:|---:|---:|---:|---:|---:|",
    ]
    for key,v in summaries["fog"].items():
        md.append(f"| Niebla {key} | {v['original_games']} | "
            f"{v['first_wins']} | {v['responder_wins']} | "
            f"{v['starter_capture_events']} | {v['response_capture_events']} | "
            f"{v['response_steals']} |")
    for key,v in summaries["template"].items():
        md.append(f"| Plantilla {key} | {v['original_games']} | "
            f"{v['first_wins']} | {v['responder_wins']} | "
            f"{v['starter_capture_events']} | {v['response_capture_events']} | "
            f"{v['response_steals']} |")
    md += [
        "",
        f"- Capturas en turno inicial de ronda: **{report['total_starter_capture_events']}**.",
        f"- Capturas en respuesta antes del cierre: **{report['total_response_capture_events']}**.",
        f"- Arrebatos directos al otro color en la respuesta: **{report['total_response_steals']}**.",
        f"- Rondas que incluyeron al menos una captura de quien responde: "
        f"**{report['rounds_with_responder_capture']}**.",
        "- En cada ronda se comprobó que el puntaje del primer medio turno "
        "no aumentó y que el puntaje al cierre fue exactamente el número "
        "de relés poseídos por cada color después de la respuesta.",
        "",
        "El archivo JSON contiene cada ronda con la propiedad al comienzo, "
        "después del primer turno y al liquidar tras la respuesta; registra "
        "cambios de propiedad y suma contable exacta.",
        "",
        "**Los arrebatos son oportunidades tácticas reales, no una bonificación "
        "automática del sistema. Correlación no demuestra causalidad.**",
        "",
        "**Sin cambiar la IA, reglas, ingresos, turnos, APK ni rama principal.**",""
    ]
    (out/"ai_v385_relay_round_ledger.md").write_text("\n".join(md),encoding="utf-8")
    print("RELAY385_ALL "+json.dumps({k:v for k,v in report.items()
        if k not in ("games","response_capture_rounds")},
        ensure_ascii=False,separators=(",",":")))
    print("\n".join(md))
    print("PASS TARVOKA v385 aggregate: 16 actual games, 16 exact mirrors, complete scored-round ownership ledger")

if __name__=="__main__":
    main(sys.argv[1] if len(sys.argv)>1 else ".ci-v385-logs")
