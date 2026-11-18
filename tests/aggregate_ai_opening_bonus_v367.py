#!/usr/bin/env python3
"""Aggregate 128 genuine Godot same-policy battles with constrained fourth orders.

Not a synthetic simulator. The two legacy baselines cap=3 and cap=4 must
reproduce previous CI. The first three observed decisions must have exactly
the same action trace in all four interventions within each environment.
"""
import json
import pathlib
import sys
from collections import Counter, defaultdict

MARKER = "BONUS367_MATCH "
CAPS = ("3", "4", "3plus_move", "3plus_support")
POLICIES = ("v35", "v363")


def load(folder):
    games = []
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            index = line.find(MARKER + "{")
            if index >= 0:
                data = json.loads(line[index + len(MARKER):].strip())
                if not isinstance(data, dict):
                    raise SystemExit("Malformed real battle record")
                games.append(data)
    return games


def verify(games):
    expected = {(level, terrain, fog, first, policy, cap)
                for level in (10, 12)
                for terrain in (0, 2)
                for fog in (False, True)
                for first in (0, 1)
                for policy in POLICIES
                for cap in CAPS}
    observed = {}
    for row in games:
        cap = str(row["opening_cap"])
        assert cap in CAPS, f"Unexpected variant {cap}"
        assert row["layout"] == "south"
        assert row["fair_round"] is True and row["round_scoring"] is True
        assert int(row["relay_nodes"]) == 2
        assert int(row["v363_side"]) == -1
        assert row["balanced_opening"] is (cap == "3")
        assert row["research_budget_only"] is (cap != "3")
        assert isinstance(row["opening_trace"], list) and len(row["opening_trace"]) == 3
        count = int(row["opening_actions"])
        assert count in (3, 4), f"Bad first-phase count: {cap} {count}"
        if cap == "3":
            assert count == 3
        if cap == "4":
            assert count == 4
        if cap.startswith("3plus"):
            assert count == (4 if row["fourth_bonus_used"] else 3)
            if row["fourth_bonus_used"]:
                approved = ("move",) if cap == "3plus_move" else (
                    "move", "produce", "resupply")
                assert row["fourth_bonus_action"] in approved
                assert row["fourth_bonus_action"] == row["fourth_candidate"]
        key = (int(row["level"]), int(row["map"]), bool(row["fog"]),
               int(row["first"]), str(row["mode"]), cap)
        if key in observed:
            raise SystemExit(f"Duplicate battle: {key}")
        observed[key] = row
    if len(games) != 128 or set(observed) != expected:
        raise SystemExit(f"INVALID real-game matrix count={len(games)} "
                         f"missing={sorted(expected-set(observed))}")

    trace_matches = 0
    groups = {(level, terrain, fog, first, policy)
              for (level, terrain, fog, first, policy, cap) in expected}
    assert len(groups) == 32
    for (level, terrain, fog, first, policy) in sorted(groups):
        bas = observed[(level, terrain, fog, first, policy, "3")]["opening_trace"]
        for other in CAPS:
            row = observed[(level, terrain, fog, first, policy, other)]
            if row["opening_trace"] != bas:
                raise SystemExit(f"FIRST THREE DECISIONS NOT HELD CONSTANT: "
                                 f"{level,terrain,fog,first,policy,other} "
                                 f"baseline={bas},actual={row['opening_trace']}")
            trace_matches += 1
    return trace_matches


def aggregate(sub):
    result = {"games": len(sub), "first_wins":0, "second_wins":0,
              "blue_wins":0, "red_wins":0, "censored":0,
              "relay_wins":0, "combat_wins":0,
              "city_captures":0, "retreats":0,
              "fourth_bonus_used":0, "fourth_recommendations":{},
              "fourth_approved_actions":{},
              "opening_actions_total":0}
    recommendations = Counter()
    approved = Counter()
    for row in sub:
        first = int(row["first"])
        winner = int(row["winner"])
        result["opening_actions_total"] += int(row["opening_actions"])
        result["city_captures"] += sum(int(v) for v in row["captures"])
        result["retreats"] += sum(int(v) for v in row["retreats"])
        recommendations[str(row["fourth_candidate"])] += 1
        if row["fourth_bonus_used"]:
            result["fourth_bonus_used"] += 1
            approved[str(row["fourth_bonus_action"])] += 1
        if winner not in (0,1):
            result["censored"] += 1
            continue
        result["first_wins" if winner == first else "second_wins"] += 1
        result["blue_wins" if winner == 0 else "red_wins"] += 1
        result["relay_wins" if row["winner_source"] == "relay" else "combat_wins"] += 1
    result["fourth_recommendations"] = dict(sorted(recommendations.items()))
    result["fourth_approved_actions"] = dict(sorted(approved.items()))
    result["initiative_skew"] = abs(result["first_wins"]-result["second_wins"])
    result["color_skew"] = abs(result["blue_wins"]-result["red_wins"])
    result["mean_opening_orders"] = round(
        result["opening_actions_total"]/len(sub),3) if sub else None
    return result


def main():
    games = load(pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".ci-v367-logs"))
    identical_traces = verify(games)
    results = {}
    for cap in CAPS:
        sub = [m for m in games if m["opening_cap"] == cap]
        data = aggregate(sub)
        data["by_map"] = {str(map_id):aggregate(
            [m for m in sub if int(m["map"]) == map_id])
            for map_id in (0,2)}
        data["by_policy"] = {p:aggregate(
            [m for m in sub if m["mode"] == p])
            for p in POLICIES}
        results[cap] = data
    baseline3 = {"first_wins":8,"second_wins":24,"blue_wins":16,"red_wins":16,"games":32}
    baseline4 = {"first_wins":24,"second_wins":8,"blue_wins":20,"red_wins":12,"games":32}
    for cap, ref in (("3",baseline3),("4",baseline4)):
        if any(results[cap][name] != count for name,count in ref.items()):
            raise SystemExit(
                f"BASELINE REPRODUCTION FAILED for cap={cap}: "
                +str({name:results[cap][name] for name in ref}))
    ranking = sorted(CAPS,key=lambda cap: (
        results[cap]["censored"] != 0,
        results[cap]["initiative_skew"],
        results[cap]["color_skew"]))
    output={
        "source":"128 real Godot 4.3 battles, same-AI self-mirrors",
        "experiment":"3+1 restricted movement or support vs 3 and 4 normal orders",
        "invariants":{"two_reflected_relays":True,"fair_round":True,
                      "south_layout":True,"no_gameplay_or_save_rule_modified":True,
                      "first_three_action_traces_identical":True,
                      "matched_traces_checked":identical_traces},
        "historical_baselines":{"3":baseline3,"4":baseline4},
        "by_variant":results,
        "screening_order":ranking,
        "merge_approved":False,
        "caveat":"Test-only rule prototype; two maps, AI against self, not human or Android play."
    }
    folder=pathlib.Path("reports")
    folder.mkdir(exist_ok=True)
    (folder/"ai_v367_opening_noncombat.json").write_text(
        json.dumps(output,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    lines=["# TARVOKA — cuarta orden condicionada: movimiento o apoyo",
           "",
           "**128 partidas reales de Godot 4.3**. Mismo AI vs sí misma,",
           "dos relés simétricos, terreno y puntuación por ronda sin cambios.",
           "",
           "| Variante | Partidas | Primero | Segundo | Azul | Rojo | 4ª concedida | Media órdenes |",
           "|---|---:|---:|---:|---:|---:|---:|---:|"]
    for cap in CAPS:
        d=results[cap]
        lines.append(f"| {cap} | {d['games']} | {d['first_wins']} | "
                     f"{d['second_wins']} | {d['blue_wins']} | {d['red_wins']} | "
                     f"{d['fourth_bonus_used']} | {d['mean_opening_orders']} |")
    lines.extend(["","## Separación por terreno",
                  "","| Variante | Mapa | Primero | Segundo | Azul | Rojo |",
                  "|---|---:|---:|---:|---:|---:|"])
    for cap in CAPS:
        for mp in ("0","2"):
            d=results[cap]["by_map"][mp]
            lines.append(f"| {cap} | {mp} | {d['first_wins']} | "
                         f"{d['second_wins']} | {d['blue_wins']} | {d['red_wins']} |")
    lines.extend(["","## Controles de calidad",
                  f"- Primeras tres acciones comparadas sin discrepancias: **{identical_traces}**",
                  "- Referencias 3 y 4 reproducidas exactamente: **sí**",
                  "- La cuarta recomendación se registra incluso cuando se rechaza.",
                  "- El motor de juego no admite opening.limit>3 en esta rama; "
                  "el límite 4 y las opciones de bonus son únicamente reglas del arnés de prueba.",
                  "- Aun cuando un candidato tenga una menor asimetría, no se autoriza merge o APK.",
                  ""])
    md="\n".join(lines)
    (folder/"ai_v367_opening_noncombat.md").write_text(md,encoding="utf-8")
    print("BONUS367_ALL "+json.dumps(output,separators=(",",":"),ensure_ascii=False))
    print(md)
    print("PASS AI opening v367 aggregate: 128 real matches, 128 mirrored first3 traces and both prior baselines verified")


if __name__=="__main__":
    main()
