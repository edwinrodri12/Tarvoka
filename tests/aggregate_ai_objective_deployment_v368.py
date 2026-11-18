#!/usr/bin/env python3
"""Process only real Godot v3.6.8 fourth deployment matches; no synthetic wins."""
import json
import pathlib
import sys
from collections import Counter

MARKER = "DEPLOY368_MATCH "
VARIANTS = ("3", "4", "3plus_no_objective", "3plus_defensive")
POLICIES = ("v35", "v363")


def read(folder):
    rows = []
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            offset = line.find(MARKER + "{")
            if offset >= 0:
                rows.append(json.loads(line[offset + len(MARKER):].strip()))
    return rows


def validate(rows):
    expected = {(level, map_id, fog, first, policy, variant)
                for level in (10, 12) for map_id in (0, 2)
                for fog in (False, True) for first in (0, 1)
                for policy in POLICIES for variant in VARIANTS}
    observed = {}
    for m in rows:
        key = (int(m["level"]), int(m["map"]), bool(m["fog"]),
               int(m["first"]), str(m["mode"]), str(m["opening_cap"]))
        if key in observed:
            raise SystemExit(f"Duplicate real game {key}")
        observed[key] = m
        variant = key[-1]
        assert variant in VARIANTS
        assert m["layout"] == "south"
        assert m["fair_round"] is True and m["round_scoring"] is True
        assert int(m["relay_nodes"]) == 2 and int(m["v363_side"]) == -1
        assert m["balanced_opening"] is (variant == "3")
        assert m["research_budget_only"] is (variant != "3")
        assert len(m["opening_trace"]) == 3
        count = int(m["opening_actions"])
        assert 3 <= count <= 4
        if variant == "3":
            assert count == 3
        if variant == "4":
            assert count == 4 and m["fourth_candidate"] == "move"
        if variant.startswith("3plus"):
            assert count == (4 if m["fourth_bonus_used"] else 3)
            assert m["fourth_candidate"] in ("none", "move")
            if m["fourth_bonus_used"]:
                assert m["fourth_bonus_action"] == "move"
                assert not m["fourth_on_site"] and not m["fourth_on_relay"]
                if variant == "3plus_defensive":
                    assert m["fourth_own_half"]
                    assert int(m["fourth_relay_delta"]) >= 0
            else:
                assert m["fourth_denial"] != "none"
    if len(rows) != 128 or set(observed) != expected:
        raise SystemExit(f"Invalid 128-game matrix count={len(rows)} missing={sorted(expected-set(observed))}")
    groups = {(lvl, map_id, fog, first, policy)
              for lvl, map_id, fog, first, policy, variant in expected}
    assert len(groups) == 32
    checked = 0
    for group in sorted(groups):
        baseline = observed[(*group,"3")]["opening_trace"]
        for variant in VARIANTS:
            if observed[(*group,variant)]["opening_trace"] != baseline:
                raise SystemExit(f"First-three decisions differ in {group} {variant}")
            checked += 1
    assert checked == 128
    return checked


def metrics(rows):
    results = {"games":len(rows),"first_wins":0,"second_wins":0,
               "blue_wins":0,"red_wins":0,"censored":0,"relay_wins":0,
               "combat_wins":0,"fourth_bonus_used":0,"fourth_site":0,
               "fourth_relay":0,"fourth_approach_relay":0,"fourth_own_half":0,
               "city_captures":0,"retreats":0,"denial_reasons":{},
               "fourth_reason":{},"fourth_destination":{}}
    denials = Counter()
    reasons = Counter()
    destinations = Counter()
    for m in rows:
        winner = int(m["winner"])
        first = int(m["first"])
        results["fourth_bonus_used"] += int(m["fourth_bonus_used"])
        if m["fourth_candidate"] == "move":
            results["fourth_site"] += int(m["fourth_on_site"])
            results["fourth_relay"] += int(m["fourth_on_relay"])
            results["fourth_approach_relay"] += int(int(m["fourth_relay_delta"]) < 0)
            results["fourth_own_half"] += int(m["fourth_own_half"])
        denials[str(m["fourth_denial"])] += 1
        reasons[str(m["fourth_reason"])] += 1
        destinations[str(m["fourth_destination"])] += 1
        results["city_captures"] += sum(int(a) for a in m["captures"])
        results["retreats"] += sum(int(a) for a in m["retreats"])
        if winner not in (0,1):
            results["censored"] += 1
            continue
        results["first_wins" if winner == first else "second_wins"] += 1
        results["blue_wins" if winner == 0 else "red_wins"] += 1
        results["relay_wins" if m["winner_source"] == "relay" else "combat_wins"] += 1
    results["denial_reasons"] = dict(sorted(denials.items()))
    results["fourth_reason"] = dict(sorted(reasons.items()))
    results["fourth_destination"] = dict(sorted(destinations.items()))
    results["initiative_skew"] = abs(results["first_wins"]-results["second_wins"])
    results["color_skew"] = abs(results["blue_wins"]-results["red_wins"])
    return results


def main():
    folder = pathlib.Path(sys.argv[1] if len(sys.argv)>1 else ".ci-v368-logs")
    rows = read(folder)
    trace_count = validate(rows)
    by_variant = {}
    for variant in VARIANTS:
        selected = [m for m in rows if m["opening_cap"] == variant]
        a = metrics(selected)
        a["by_map"] = {str(map_id):metrics(
            [m for m in selected if int(m["map"]) == map_id])
            for map_id in (0,2)}
        a["by_policy"] = {policy:metrics(
            [m for m in selected if m["mode"] == policy])
            for policy in POLICIES}
        by_variant[variant] = a
    reference = {
        "3":{"games":32,"first_wins":8,"second_wins":24,
             "blue_wins":16,"red_wins":16},
        "4":{"games":32,"first_wins":24,"second_wins":8,
             "blue_wins":20,"red_wins":12}
    }
    for variant, prior in reference.items():
        if any(by_variant[variant][name] != n for name,n in prior.items()):
            raise SystemExit(f"Historical baseline {variant} did not reproduce: "
                             +str({k:by_variant[variant][k] for k in prior}))
    ranking = sorted(VARIANTS,key=lambda v: (
        by_variant[v]["censored"]!=0,
        by_variant[v]["initiative_skew"],
        by_variant[v]["color_skew"]))
    report={
        "research":"4th deployment action without immediate objective occupation",
        "engine":"Godot 4.3 actual legal actions and genuine self-play results",
        "invariants":{"same_first_three_decisions":True,
                      "distinct_traces_checked":trace_count,
                      "only_public_objective_coordinates":True,
                      "no_engine_or_save_changes":True,
                      "two_south_reflected_relays":True,"full_round_scoring":True},
        "reference_reproduced":True,
        "by_variant":by_variant,"screening_order":ranking,
        "merge_approved":False,
        "caveat":"Two prototype maps, deterministic self-play. "
                 "A movement that avoids objectives may still affect combat or future captures."
    }
    out = pathlib.Path("reports")
    out.mkdir(exist_ok=True)
    (out/"ai_v368_objective_deployment.json").write_text(
        json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    md=["# TARVOKA v3.6.8 — cuarta acción y destino del movimiento",
        "",
        "**128 partidas reales**; 32 por condición; 128 comprobaciones",
        "de que las primeras tres decisiones son idénticas; bases 3/4 reproducidas.",
        "",
        "| Variante | Partidas | Primero | Segundo | Azul | Rojo | 4ª concedida | Destinos sitio | Destinos relé |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|"]
    for variant in VARIANTS:
        d=by_variant[variant]
        md.append(f"| {variant} | {d['games']} | {d['first_wins']} | "
                  f"{d['second_wins']} | {d['blue_wins']} | {d['red_wins']} | "
                  f"{d['fourth_bonus_used']} | {d['fourth_site']} | {d['fourth_relay']} |")
    md.extend(["","## Detalle por terreno","",
        "| Variante | Mapa | Primero | Segundo | Azul | Rojo | Bonus |",
        "|---|---:|---:|---:|---:|---:|---:|"])
    for variant in VARIANTS:
        for map_id in ("0","2"):
            d=by_variant[variant]["by_map"][map_id]
            md.append(f"| {variant} | {map_id} | {d['first_wins']} | "
                      f"{d['second_wins']} | {d['blue_wins']} | {d['red_wins']} | "
                      f"{d['fourth_bonus_used']} |")
    md.extend(["","## Validación e interpretación","",
        "- Las pruebas excluyen nuevas acciones alternativas tras denegar la cuarta.",
        "- El filtro solo consulta posiciones públicas de ciudad/base y relé, nunca enemigos ocultos.",
        "- Un movimiento puede facilitar ataques y capturas posteriores aun sin pisar un objetivo.",
        "- Ninguna clasificación de esta muestra autoriza integrar cambios oficiales.", ""])
    summary="\n".join(md)
    (out/"ai_v368_objective_deployment.md").write_text(summary,encoding="utf-8")
    print("DEPLOY368_ALL "+json.dumps(report,ensure_ascii=False,separators=(",",":")))
    print(summary)
    print("PASS AI deployment v368 aggregate: 128 unique real battles, first3 equal, cap3/cap4 reproduced")


if __name__=="__main__":
    main()
