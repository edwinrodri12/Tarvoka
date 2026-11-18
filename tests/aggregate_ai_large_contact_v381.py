#!/usr/bin/env python3
"""TARVOKA v3.8.1: strict aggregate for 40x30 longer-play AI contact research.

Do not count horizontal mirror replays as extra independent samples,
and do not convert capped games to draws or wins. Read only verified
CONTACT381_RESULT lines emitted by Godot and collect inspectable reports.
"""
import json
import pathlib
import sys
from collections import Counter

PREFIX = "CONTACT381_RESULT "
SEEDS = [630,631,632,633]
CHECKPOINTS = (2,4,8,12,16,20,24)

def load(folder):
    records = []
    for file in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in file.read_text(encoding="utf-8", errors="replace").splitlines():
            at = line.find(PREFIX+"{")
            if at >= 0:
                records.append(json.loads(line[at+len(PREFIX):]))
    return records

def positive_or_missing(value):
    return isinstance(value,int) and (value == -1 or value >= 0)

def run(folder):
    rows = load(folder)
    expected = {(seed,fog,starter) for seed in SEEDS
                for fog in (True,False) for starter in (0,1)}
    keyed = {}
    for r in rows:
        key = (r["seed"],r["fog"],r["first"])
        assert key in expected and key not in keyed, f"unexpected/duplicate: {key}"
        keyed[key] = r
        assert r["size"] == "40x30"
        assert r["template"] == r["seed"] % 4
        assert r["fog"] is True or r["fog"] is False
        assert r["first"] in (0,1)
        assert r["half_turn_cap"] == 24
        assert r["mirror_equivalent"] is True
        assert r["actual_authoritative_games"] == 2
        assert 0 <= r["half_turns_completed"] <= 24
        assert r["terminal"] in ("phase_limit","winner","idle_stalemate")
        assert r["winner"] in (-1,0,1)
        assert r["censored"] is (r["winner"] == -1)
        assert (r["terminal"] == "winner") == (r["winner"] >= 0)
        assert r["attacks"] >= 0 and r["moves"] >= 0 and r["purchases"] >= 0
        assert r["resupplies"] >= 0
        assert r["actions"] == (r["attacks"]+r["moves"]+r["purchases"]+r["resupplies"])
        assert len(r["signals_end"]) == 2
        e = r["events"]
        for field in ("first_attack","first_city_capture","first_relay_capture",
                      "first_proximity_le3","first_fog_sighting"):
            assert positive_or_missing(e[field])
            assert e[field] == -1 or e[field] <= r["half_turns_completed"]+1
        assert (e["first_attack"] >= 0) == (r["attacks"] > 0)
        assert e["first_fog_sighting"] == -1 or r["fog"] is True
        assert sum(e["first_attack_by_side"]) == r["attacks"]
        assert e["city_capture_events"] >= 0 and e["relay_capture_events"] >= 0
        assert (e["first_city_capture"] >= 0) == (e["city_capture_events"] > 0)
        assert (e["first_relay_capture"] >= 0) == (e["relay_capture_events"] > 0)
        checkpoints = e["checkpoints"]
        names = [s["half_turns"] for s in checkpoints]
        assert sorted(set(names)) == names
        assert set(names).issubset(set(CHECKPOINTS))
        if r["terminal"] == "phase_limit" and r["half_turns_completed"] == 24:
            assert names == list(CHECKPOINTS), (key,names)
        for s in checkpoints+[r["last"]]:
            assert s["closest_enemy_manhattan"] >= 0
            assert len(s["units_alive"]) == 2 and all(v >= 0 for v in s["units_alive"])
            assert len(s["max_advance_local_x"]) == 2
            assert all(0 <= v <= 39 for v in s["max_advance_local_x"])
            assert len(s["city_owners"]) == 2
            assert len(s["relay_owners"]) == 2
            assert len(s["signal"]) == 2
            assert len(s["credits"]) == 2
            assert len(s["low_fuel"]) == 2
            assert len(s["low_ammo"]) == 2
            assert all(v >= 0 for v in s["low_fuel"]+s["low_ammo"])
        assert r["last"]["half_turns"] == r["half_turns_completed"]
    assert len(keyed) == 16 and set(keyed) == expected, (
        f"matrix incomplete: {len(keyed)}/16; missing={sorted(expected-set(keyed))}")
    per_template = {}
    by_fog = {}
    for grouping,name,values in [
        (per_template,"template",range(4)),
        (by_fog,"fog",(False,True)),
    ]:
        for value in values:
            group = [r for r in rows if r[name] == value]
            assert len(group) == (4 if name == "template" else 8)
            ended = [r for r in group if not r["censored"]]
            group_events = [r["events"] for r in group]
            grouping[str(value).lower()] = {
                "conditions":len(group),
                "finished":len(ended),
                "censored":len(group)-len(ended),
                "first_attacks_observed":sum(e["first_attack"] >= 0 for e in group_events),
                "first_city_captures_observed":sum(
                    e["first_city_capture"] >= 0 for e in group_events),
                "first_relays_observed":sum(
                    e["first_relay_capture"] >= 0 for e in group_events),
                "first_sightings_observed":sum(
                    e["first_fog_sighting"] >= 0 for e in group_events),
                "total_attacks":sum(r["attacks"] for r in group),
                "total_moves":sum(r["moves"] for r in group),
                "total_purchases":sum(r["purchases"] for r in group),
                "total_completed_half_turns":sum(
                    r["half_turns_completed"] for r in group),
                "first_attack_half_turns":sorted(
                    e["first_attack"] for e in group_events if e["first_attack"] >= 0),
                "first_city_capture_half_turns":sorted(
                    e["first_city_capture"] for e in group_events if
                    e["first_city_capture"] >= 0),
                "end_distance":sorted(
                    r["last"]["closest_enemy_manhattan"] for r in group),
                "first_wins":sum(r["winner"] == r["first"] for r in ended),
                "second_wins":sum(r["winner"] == 1-r["first"] for r in ended),
            }
    # Matched-start pairs use exactly the same terrain and fog.
    for seed in SEEDS:
        for fog in (False,True):
            a,b = keyed[(seed,fog,0)],keyed[(seed,fog,1)]
            assert a["template"] == b["template"] and a["fog"] == b["fog"]
    total_original = len(rows)
    report = {
        "version":"v3.8.1",
        "scope":"40x30 four mirrored terrain templates, two fog conditions and two starter orders",
        "half_turn_cap":24,
        "old_half_turn_cap":8,
        "observation_window_multiplier":3,
        "original_conditions":total_original,
        "mirror_validation_replays":total_original,
        "real_authoritative_games":2*total_original,
        "matched_start_groups":8,
        "mirrors_not_independent_balance_samples":True,
        "finished":sum(not r["censored"] for r in rows),
        "censored":sum(r["censored"] for r in rows),
        "total_actions_original":sum(r["actions"] for r in rows),
        "total_attacks_original":sum(r["attacks"] for r in rows),
        "total_purchases_original":sum(r["purchases"] for r in rows),
        "first_attacks_observed":sum(r["events"]["first_attack"] >= 0 for r in rows),
        "first_cities_observed":sum(
            r["events"]["first_city_capture"] >= 0 for r in rows),
        "first_relays_observed":sum(
            r["events"]["first_relay_capture"] >= 0 for r in rows),
        "by_template":per_template,
        "by_fog":by_fog,
        "conditions":sorted(rows,key=lambda r:(r["seed"],r["fog"],r["first"])),
        "production_changed":False,
        "merge_approved":False,
        "warnings":[
            "Results from horizon-limited games are censored, never artificial wins or draws.",
            "Manhattan proximity is only a geometric proxy, NOT confirmed attack range or line of sight.",
            "A first sighting under fog is observed from an end-turn snapshot, not every intermediate action.",
            "Fuel/ammo status is a diagnostic count, not proof of inability to attack.",
            "This experiment adds no game rules or AI optimizations, and may reveal further mirror asymmetries."
        ]
    }
    out = pathlib.Path("reports")
    out.mkdir(exist_ok=True)
    (out/"ai_v381_large_contact.json").write_text(
        json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    md = [
        "# TARVOKA v3.8.1 — Cronología real de contacto en mapas 40×30",
        "",
        f"Pruebas verificadas: **{total_original} condiciones originales** y "
        f"**{total_original} reflejos**; ventana de hasta **24 medios turnos** "
        "(frente a 8 en v3.7.9).",
        "",
        "| Plantilla | Condiciones | Con ganador | Censuradas | Con primer ataque | Con primera captura de ciudad |",
        "|---|---:|---:|---:|---:|---:|"
    ]
    for k,v in sorted(per_template.items()):
        md.append(
            f"| {k} | {v['conditions']} | {v['finished']} | {v['censored']} | "
            f"{v['first_attacks_observed']} | {v['first_city_captures_observed']} |")
    md += [
        "",
        f"- Total: **{report['total_attacks_original']} ataques**, "
        f"**{report['total_purchases_original']} compras**, "
        f"**{report['total_actions_original']} órdenes** en las "
        f"{total_original} condiciones originales.",
        f"- Partidas con al menos un ataque: **{report['first_attacks_observed']}/{total_original}**.",
        f"- Partidas con ciudad capturada: **{report['first_cities_observed']}/{total_original}**.",
        f"- Partidas con relé asegurado: **{report['first_relays_observed']}/{total_original}**.",
        f"- Con ganador: **{report['finished']}**. Sin ganador: "
        f"**{report['censored']}** (censuradas).",
        "",
        "Distancias Manhattan y visibilidad al final de cada medio turno son métricas "
        "indirectas; no equivalen a una oportunidad de disparo legal. "
        "Los resultados de cada condición y sus series de 2, 4, 8, 12, 16, 20 y 24 medios turnos "
        "están en el JSON para inspección.",
        "",
        "**Sin modificación de economía, combate, reglas, código de producción ni APK.**",
        ""
    ]
    (out/"ai_v381_large_contact.md").write_text(
        "\n".join(md),encoding="utf-8")
    print("CONTACT381_ALL " + json.dumps({k:v for k,v in report.items() if k!="conditions"},
        ensure_ascii=False,separators=(",",":")))
    print("\n".join(md))
    print("PASS TARVOKA v381 aggregate: 16 matched long 40x30 original games and 16 mirrors")

if __name__ == "__main__":
    run(sys.argv[1] if len(sys.argv)>1 else ".ci-v381-logs")
