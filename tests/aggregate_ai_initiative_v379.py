#!/usr/bin/env python3
"""v3.7.9: matched initiative study from real Godot game logs.

A reflected replay validates equivalence, but is NOT an additional
independent observation in the initiative win-rate denominator.
Large maps use capped observation windows; a timeout is CENSORED,
not a draw, first win, or second win.
"""
import json
import pathlib
import sys
from collections import Counter, defaultdict

PREFIX = "ORDER379_RESULT "
SEEDS = {
    "10x8": (401,402,403,404),
    "24x18": (317,319),
    "40x30": (630,632),
}
CAP = {"10x8": 80, "24x18": 16, "40x30": 8}


def load(root):
    output = []
    for path in sorted(pathlib.Path(root).rglob("*.log")):
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            pos = line.find(PREFIX + "{")
            if pos >= 0:
                output.append(json.loads(line[pos + len(PREFIX):]))
    return output


def main():
    folder = sys.argv[1] if len(sys.argv) > 1 else ".ci-v379-logs"
    rows = load(folder)
    expected = {(size,seed,fog,first)
                for size,seeds in SEEDS.items() for seed in seeds
                for fog in (False,True) for first in (0,1)}
    found = {}
    for r in rows:
        key = (str(r["size"]), int(r["seed"]), bool(r["fog"]),int(r["first"]))
        if key in found or key not in expected:
            raise SystemExit(f"duplicate or unexpected initiative condition: {key}")
        found[key] = r
        first = key[3]
        winner = int(r["winner"])
        terminal = str(r["terminal"])
        assert r["budget_half_turns"] == CAP[key[0]]
        assert int(r["template"]) == key[1] % 4
        assert r["mirrored_equal"] is True
        assert r["mirror_winner_equal"] is True
        assert r["symmetric_initial_income"] is True
        assert int(r["opening_orders"]) == 3
        assert int(r["real_battles"]) == 2
        assert 0 <= int(r["completed_half_turns"]) <= CAP[key[0]]
        assert 3 <= int(r["actions"])
        assert int(r["attacks"]) >= 0 and int(r["purchases"]) >= 0
        assert sum(int(r[a]) for a in ("attacks","purchases","moves","resupplies")) == int(r["actions"])
        assert winner in (-1,0,1) and terminal in ("winner","phase_limit","idle_stalemate")
        assert (winner == -1) == bool(r["censored"])
        assert (terminal == "winner") == (winner in (0,1))
        assert r["winner_is_first"] is (winner != -1 and winner == first)
        assert r["winner_is_second"] is (winner != -1 and winner == 1-first)
        assert int(r["relay_first"]) >= 0 and int(r["relay_second"]) >= 0
    if len(rows) != 32 or set(found) != expected:
        raise SystemExit(f"v379 condition matrix incomplete: {len(rows)}/32; "
                         f"missing={sorted(expected-set(found))}")
    # Each (terrain, fog) has an exactly matched pair of initiators.
    pairs = {}
    for size,seeds in SEEDS.items():
        for seed in seeds:
            for fog in (False,True):
                a = found[(size,seed,fog,0)]
                b = found[(size,seed,fog,1)]
                pairs[(size,seed,fog)] = (a,b)
    by_size = {}
    for size in SEEDS:
        group = [r for r in rows if r["size"] == size]
        completed = [r for r in group if not r["censored"]]
        censored = [r for r in group if r["censored"]]
        outcomes = Counter("first" if r["winner_is_first"] else "second"
                           for r in completed)
        progress = [r for r in censored if
                    r["terminal"] == "phase_limit" and
                    r["completed_half_turns"] % 2 == 0]
        gap = Counter("first_leads" if r["relay_first"] > r["relay_second"]
                      else ("second_leads" if r["relay_second"] > r["relay_first"]
                            else "tied") for r in progress)
        by_size[size] = {
            "conditions":len(group),
            "real_independent_games":2*len(group),
            "decisive":len(completed),
            "censored":len(censored),
            "first_wins":outcomes["first"],
            "second_wins":outcomes["second"],
            "capped_equal_turn_score_comparisons":len(progress),
            "capped_signal_lead":dict(gap),
            "total_actions_original":sum(int(r["actions"]) for r in group),
            "total_attacks_original":sum(int(r["attacks"]) for r in group),
            "total_purchases_original":sum(int(r["purchases"]) for r in group),
            "completed_half_turns_original":sum(int(r["completed_half_turns"]) for r in group),
        }
    complete_pairs = sum(not a["censored"] and not b["censored"] for a,b in pairs.values())
    report = {
        "version":"v3.7.9",
        "source":"32 original independent AI-vs-AI conditions + 32 reflected validation replays",
        "total_actual_authoritative_games":64,
        "unmirrored_conditions":32,
        "initiative_swapped_matched_groups":len(pairs),
        "reflections_ignored_as_independent_win_samples":True,
        "modern_units":True,
        "original_ai":True,
        "symmetric_income":True,
        "first_turn_order_limit":3,
        "factions": "two logical sides, no commander powers under test",
        "by_size":by_size,
        "decisive_two_initiative_groups":complete_pairs,
        "warnings":[
            "Full-length winner data applies only where a winner actually emerged.",
            "24x18 and 40x30 have capped observation windows; censoring is not a draw or winner.",
            "The seed selection is fixed and small; do not generalize win rates to all games.",
            "No balance changes or new bonus orders/money are approved from this diagnostic."
        ],
        "merge_approved":False,
        "production_changed":False,
    }
    out = pathlib.Path("reports")
    out.mkdir(exist_ok=True)
    (out/"ai_v379_initiative.json").write_text(
        json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    md = [
        "# TARVOKA v3.7.9 — Medición contrafactual de iniciativa",
        "",
        "**64 partidas reales de Godot** en total: 32 condiciones originales",
        "y 32 reflejos de validación, en 16 grupos donde solo cambia",
        "quién inicia. Los reflejos NO duplican la muestra de victorias.",
        "",
        "| Tamaño | Condiciones | Con ganador | Censuradas | Gana primero | Gana segundo |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for size in ("10x8","24x18","40x30"):
        m = by_size[size]
        md.append(f"| {size} | {m['conditions']} | {m['decisive']} | "
                  f"{m['censored']} | {m['first_wins']} | {m['second_wins']} |")
    md += ["",
        f"- Grupos emparejados con ambos iniciadores decisivos: {complete_pairs}/16.",
        "- Las partidas censuradas no cuentan como victoria ni derrota.",
        "- En 24x18 se observaron hasta 16 medios turnos y en 40x30 hasta 8.",
        "- Los datos de 10x8 se observaron hasta 80 medios turnos o victoria real.",
        "- Economía inicial simétrica, límite de tres órdenes en apertura, IA y reglas oficiales.",
        "- Ninguna modificación de gameplay, producción, guardados ni APK.",
        "- Precaución: el orden de turno, la niebla y el tamaño son variables distintas; "
          "no inferir equilibrio general por una muestra limitada.",
        ""]
    (out/"ai_v379_initiative.md").write_text("\n".join(md),encoding="utf-8")
    print("ORDER379_ALL "+json.dumps(report,ensure_ascii=False,separators=(",",":")))
    print("\n".join(md))
    print("PASS TARVOKA v379 aggregate: 16 matched initiative pairs, 64 real games, honest censoring")

if __name__ == "__main__":
    main()
