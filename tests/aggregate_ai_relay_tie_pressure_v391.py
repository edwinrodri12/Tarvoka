#!/usr/bin/env python3
"""Exact two-starter v3.9.1 opt-in AI relay tie comparison.

The only outcome samples are 2 original conditions. Mirrored games are
invariants, not independent samples or a basis for official balance.
"""
import json
import pathlib
import sys

PREFIX="TIE391_RESULT "
def main(folder):
    found={}
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8",errors="replace").splitlines():
            p=line.find(PREFIX+"{")
            if p<0:
                continue
            row=json.loads(line[p+len(PREFIX):])
            first=row["first"]
            assert first in (0,1) and first not in found,("unexpected or duplicate",first)
            assert row["version"]=="v3.9.1"
            assert row["seed"]==636 and row["fog"] is True and row["size"]=="40x30"
            assert row["first_response_cap"]==5 and row["max_half_turns"]==64
            assert row["production_default_unchanged"] is True
            assert row["uses_only_observed_enemy_relays"] is True
            assert row["candidate_opt_in"] is True
            assert row["mirrors_are_validation_not_samples"] is True
            assert row["first_deviation_phase"]==-1 or row["first_deviation_phase"]>=22
            for label in ("control","candidate"):
                game=row[label]
                assert game["winner"] in [-1,0,1]
                assert game["censored"] is (game["winner"]==-1)
                assert game["terminal"] in ("winner","idle_stalemate","phase_limit")
                assert (game["terminal"]=="winner") is (game["winner"]>=0)
                assert 0<game["half_turns"]<=64
                assert len(game["scores"])==2
                assert game["actions"]>=0 and game["attacks"]>=0
                assert game["purchases"]>=0
            assert row["control"]["half_turns"]==34
            assert row["control"]["winner"]==1-first
            assert row["control"]["scores"]==([9,11] if first==0 else [11,9])
            found[first]=row
    assert set(found)=={0,1},("both mirrored starter conditions required",found.keys())
    summary={
        "version":"v3.9.1",
        "status":"experiment_only",
        "scope":"seed636 40x30 fog true cap5, opt-in tactical relay pressure",
        "original_independent_conditions":2,
        "real_games_with_mirrors":8,
        "default_gameplay_untouched":True,
        "censored_control":sum(found[x]["control"]["censored"] for x in (0,1)),
        "censored_candidate":sum(found[x]["candidate"]["censored"] for x in (0,1)),
        "control_first_wins":sum(found[x]["control"]["winner"]==x for x in (0,1)),
        "candidate_first_wins":sum(found[x]["candidate"]["winner"]==x for x in (0,1)),
        "control_responder_wins":sum(found[x]["control"]["winner"]==1-x for x in (0,1)),
        "candidate_responder_wins":sum(found[x]["candidate"]["winner"]==1-x for x in (0,1)),
        "mean_control_half_turns":sum(found[x]["control"]["half_turns"] for x in (0,1))/2,
        "mean_candidate_half_turns":sum(found[x]["candidate"]["half_turns"] for x in (0,1))/2,
        "first_action_deviation_by_starter":{str(x):found[x]["first_deviation_phase"] for x in (0,1)},
        "warnings":[
            "Opt-in flag is OFF by default; no new game rule was enabled.",
            "A tactical option affecting two correlated starts on one map cannot establish broad fairness.",
            "The two mirrored replays per policy are for deterministic parity only.",
            "Never classify a censored state as a draw or fabricate a winner.",
            "Relay owner=-2 under fog cannot authorize targeting an opponent-owned relay.",
            "No score, economy, capture, terrain or opening-limit modifications were made."
        ]
    }
    out=pathlib.Path("reports")
    out.mkdir(parents=True,exist_ok=True)
    (out/"ai_v391_relay_tie_pressure.json").write_text(
        json.dumps({"summary":summary,"games":[found[0],found[1]]},
                   ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    lines=[
        "# TARVOKA v3.9.1 — Presión sobre relés (solo IA opcional)",
        "",
        "**Semilla 636, 40×30, con niebla, respuesta cap5 de investigación.** "
        "Dos iniciadores, IA actual y variante opt-in, ambos reflejados exactamente: "
        "ocho partidas reales, dos condiciones originales por política.",
        "",
        "| Iniciador | Variante | Ganador | Medio turnos | Señal final | Censurada | Primera divergencia desde control |",
        "|---:|---|---:|---:|---|---|---:|"
    ]
    for first in (0,1):
        r=found[first]
        for name in ("control","candidate"):
            game=r[name]
            lines.append(
                f"| {first} | {name} | {game['winner']} | {game['half_turns']} | "
                f"{game['scores']} | {game['censored']} | {r['first_deviation_phase']} |")
    lines.extend([
        "",
        "El candidato solo da prioridad a un **relé de propiedad enemiga "
        "efectivamente visible** cuando ambas señales ya alcanzaron el objetivo "
        "y continúan empatadas. Conserva la defensa existente y nunca retira "
        "a una unidad que custodia un relé propio.",
        "",
        "**Resultado limitado a este mapa; no se aprueba un cambio en la IA "
        "de producción sin estudiar más semillas y condiciones.**",
        ""
    ])
    (out/"ai_v391_relay_tie_pressure.md").write_text("\n".join(lines),encoding="utf-8")
    print("TIE391_ALL "+json.dumps(summary,ensure_ascii=False,separators=(",",":")))
    print("\n".join(lines))
    print("PASS TARVOKA v391 aggregate: two real opt-in comparisons and eight exact mirrored games")

if __name__=="__main__":
    main(sys.argv[1] if len(sys.argv)>1 else ".ci-v391")
