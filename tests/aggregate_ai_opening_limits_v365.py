#!/usr/bin/env python3
"""Audit actual Godot OpeningBalance limits 2/3/unlimited with 96 self-mirrors.

The SOUTH mirrored two-relay layout, equal-round relay scoring, both
five-unit rosters, economy, maps, AI and levels are fixed. No fake games.
"""
import json
import pathlib
import sys

MARKER = "OPEN365_MATCH "
CAPS = ("2", "3", "unlimited")
PROFILES = ("v35", "v363")


def load(folder):
    games = []
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            marker = line.find(MARKER + "{")
            if marker < 0:
                continue
            game = json.loads(line[marker + len(MARKER):].strip())
            if not isinstance(game, dict):
                raise SystemExit(f"Not a real match object: {path}")
            games.append(game)
    return games


def validate(games):
    expected = {(level, map_id, fog, first, profile, cap)
                for level in (10, 12)
                for map_id in (0, 2)
                for fog in (False, True)
                for first in (0, 1)
                for profile in PROFILES
                for cap in CAPS}
    observed = []
    for game in games:
        cap = str(game["opening_cap"])
        assert cap in CAPS
        assert str(game["layout"]) == "south"
        assert int(game["relay_nodes"]) == 2
        assert game["fair_round"] is True and game["round_scoring"] is True
        assert game["balanced_opening"] is (cap != "unlimited")
        assert int(game["v363_side"]) == -1, "This audit must be self-mirror only"
        assert int(game["opening_actions"]) >= 0
        if cap != "unlimited":
            assert int(game["opening_actions"]) <= int(cap), "Engine exceeded opening cap"
        observed.append((int(game["level"]), int(game["map"]), bool(game["fog"]),
                         int(game["first"]), str(game["mode"]), cap))
    missing = expected - set(observed)
    if len(observed) != 96 or len(set(observed)) != 96 or missing or set(observed) != expected:
        raise SystemExit(f"INVALID 96-GAME MATRIX: count={len(observed)}, "
                         f"duplicates={len(observed)-len(set(observed))}, "
                         f"missing={sorted(missing)}")


def metrics(games):
    data = {"games":len(games),"first_wins":0,"second_wins":0,
            "blue_wins":0,"red_wins":0,"relay_wins":0,"combat_wins":0,
            "censored":0,"opening_actions_sum":0,"opening_actions_min":None,
            "opening_actions_max":None,"retreats":0,"city_captures":0}
    for m in games:
        actions = int(m["opening_actions"])
        data["opening_actions_sum"] += actions
        data["opening_actions_min"] = actions if data["opening_actions_min"] is None else min(
            data["opening_actions_min"],actions)
        data["opening_actions_max"] = actions if data["opening_actions_max"] is None else max(
            data["opening_actions_max"],actions)
        data["retreats"] += sum(int(v) for v in m["retreats"])
        data["city_captures"] += sum(int(v) for v in m["captures"])
        winner = int(m["winner"])
        if winner not in (0,1):
            data["censored"] += 1
            continue
        data["first_wins" if winner == int(m["first"]) else "second_wins"] += 1
        data["blue_wins" if winner == 0 else "red_wins"] += 1
        data["relay_wins" if m["winner_source"] == "relay" else "combat_wins"] += 1
    data["mean_opening_actions"] = round(data["opening_actions_sum"]/data["games"],2) if games else None
    return data


def main():
    root = pathlib.Path(sys.argv[1] if len(sys.argv)>1 else ".ci-v365-logs")
    games = load(root)
    validate(games)
    variants = {}
    for cap in CAPS:
        sub = [m for m in games if m["opening_cap"] == cap]
        result = metrics(sub)
        result["by_map"] = {str(map_id):metrics(
            [m for m in sub if int(m["map"]) == map_id]) for map_id in (0,2)}
        result["by_policy"] = {profile:metrics(
            [m for m in sub if m["mode"] == profile]) for profile in PROFILES}
        result["initiative_skew"] = abs(result["first_wins"] - result["second_wins"])
        result["color_skew"] = abs(result["blue_wins"] - result["red_wins"])
        result["all_resolved"] = result["censored"] == 0
        variants[cap] = result
    # This exact cap=3 control should reproduce the 32 SOUTH-layout
    # control matches from the previously successful v3.6.4 test.
    historic = {"first_wins":8,"second_wins":24,
                "blue_wins":16,"red_wins":16,"games":32}
    actual = variants["3"]
    replicated = all(actual[k] == value for k,value in historic.items())
    if not replicated:
        raise SystemExit("Historical v364 SOUTH cap=3 control did not reproduce: "
                         +str({k:actual[k] for k in historic}))
    ranking = sorted(CAPS,key=lambda cap:(
        variants[cap]["censored"] > 0,
        variants[cap]["initiative_skew"],
        variants[cap]["color_skew"]))
    summary = {
        "experiment":"Godot v3.6.5 South two-relay first-turn cap audit",
        "match_source":"96 real same-AI Godot BattleSession battles",
        "constants":{"layout":"south","relays":2,"fair_round_scoring":True,
                     "AI_vs_itself":True,"terrain_maps":[0,2],
                     "levels":[10,12],"fog":[False,True]},
        "tested_caps":{"2":"valid built-in opening limit 2",
                       "3":"valid built-in opening limit 3",
                       "unlimited":"legacy engine opt-out; no opening field"},
        "by_cap":variants,
        "historical_south_cap3":historic,
        "cap3_reproduced_prior_v364":replicated,
        "screening_order":ranking,
        "merge_approved":False,
        "warning":"Exploratory deterministic small-map sample. Equal self-play "
                  "wins are not proof of a fair game or a superior AI; "
                  "human sessions, all domains and Android checks remain."
    }
    out = pathlib.Path("reports")
    out.mkdir(exist_ok=True)
    (out/"ai_v365_opening_limits.json").write_text(
        json.dumps(summary,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    md = ["# TARVOKA — límite de apertura con relés simétricos al sur",
          "",
          "**96 partidas completas de control**, IA contra sí misma,",
          "dos relés reflejados, puntuación por ronda completa.",
          "",
          "| Límite inicial | Partidas | Gana primero | Gana segundo | Azul | Rojo | Media acciones iniciales |",
          "|---|---:|---:|---:|---:|---:|---:|"]
    for cap in CAPS:
        m = variants[cap]
        md.append(f"| {cap} | {m['games']} | {m['first_wins']} | "
                  f"{m['second_wins']} | {m['blue_wins']} | {m['red_wins']} | "
                  f"{m['mean_opening_actions']} |")
    md.extend(["","## Desglose por mapa",
               "","| Límite | Mapa | Primero | Segundo | Azul | Rojo |",
               "|---|---:|---:|---:|---:|---:|"])
    for cap in CAPS:
        for map_id in ("0","2"):
            m = variants[cap]["by_map"][map_id]
            md.append(f"| {cap} | {map_id} | {m['first_wins']} | "
                      f"{m['second_wins']} | {m['blue_wins']} | {m['red_wins']} |")
    md.extend(["","## Controles de validez",
       "",
       f"- Referencia sur con límite 3 reproducida: **{replicated}**",
       "- Límite 2 y 3 son estados válidos de la regla de apertura existente.",
       "- Sin límite es el modo de motor preexistente, no un límite inventado de 4 o 5.",
       "- La comparación no autoriza cambiar reglas de juego ni fusionar una APK.",
       "- El orden del cribado es exploratorio; depende de mapas y escenarios utilizados.",
       ""])
    report = "\n".join(md)
    (out/"ai_v365_opening_limits.md").write_text(report,encoding="utf-8")
    print("OPEN365_ALL "+json.dumps(summary,separators=(",",":"),ensure_ascii=False))
    print(report)
    print("PASS AI opening v365 aggregate: 96 unique actual Godot battles and cap=3 baseline reproduced")

if __name__=="__main__":
    main()
