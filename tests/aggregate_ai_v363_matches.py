#!/usr/bin/env python3
"""Aggregate Godot v3.6.3 vs v3.5 REAL full-battle JSON logs.

No simulated victories or changes to battle logic. Fail clearly if
any of the 32 expected paired starts is missing or duplicated.
"""
import json
import pathlib
import sys
from collections import defaultdict

PREFIX = "AB363_MATCH "
METRICS = ("losses", "captures", "retreats", "attacks",
           "buys", "initial_survivors", "remaining_hp",
           "decision_us", "decision_calls")


def parse_match_line(line: str):
    """Ignore Actions shell-command echoes; only parse genuine JSON match rows."""
    marker = line.find(PREFIX + "{")
    if marker < 0:
        return None
    payload = line[marker + len(PREFIX):].strip()
    value = json.loads(payload)
    if not isinstance(value, dict) or "v363_side" not in value:
        raise ValueError("Unexpected AB363_MATCH payload")
    return value


def quality_assessment(totals: dict) -> dict:
    """Advisory game-quality screening; passing tests never authorizes APK merge."""
    checks = {
        "all_32_resolved": totals["finished"] == 32 and totals["censored"] == 0,
        "at_least_win_parity": totals["v363_wins"] >= totals["v35_wins"],
        "city_capture_parity": totals["v363_captures"] >= totals["v35_captures"],
        "initial_survivor_parity": totals["v363_initial_survivors"] >= totals["v35_initial_survivors"],
        "fewer_retreats_than_v362": totals["v363_retreats"] < 34,
        "zero_questionable_retreats": totals["v363_questionable_anticipatory"] == 0,
        "zero_nonlethal_capture_abandons": totals["v363_abandoned_nonlethal_capture"] == 0,
    }
    return {
        "status": "candidate_for_broader_testing" if all(checks.values()) else "needs_tuning",
        "checks": checks,
        "merge_approved": False,
        "note": "Exploratory sample; human playtesting and Android profiling still required."
    }


def main() -> int:
    folder = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".ci-duel-logs")
    games = []
    for path in sorted(folder.rglob("*.log")):
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            try:
                value = parse_match_line(line)
            except (ValueError, TypeError) as exc:
                raise SystemExit(f"Malformed real match entry in {path}: {exc}") from exc
            if value is not None:
                games.append(value)
    expected = {(level, map_id, fog, first, side)
                for level in (10, 12)
                for map_id in (0, 2)
                for fog in (False, True)
                for first in (0, 1)
                for side in (0, 1)}
    observed = [(int(x["level"]), int(x["map"]), bool(x["fog"]),
                 int(x["first"]), int(x["v363_side"])) for x in games]
    if len(games) != 32 or set(observed) != expected or len(set(observed)) != 32:
        missing = sorted(expected - set(observed))
        duplicate_count = len(observed) - len(set(observed))
        raise SystemExit(
            f"INCOMPLETE A/B: games={len(games)}/32 "
            f"duplicates={duplicate_count}, missing={missing}"
        )
    totals = {"games": len(games), "finished": 0, "censored": 0,
              "v363_wins": 0, "v35_wins": 0,
              "v363_anticipatory": 0, "v363_questionable_anticipatory": 0,
              "v363_abandoned_nonlethal_capture": 0}
    for side in ("v363", "v35"):
        for metric in METRICS:
            totals[f"{side}_{metric}"] = 0
    by_level = defaultdict(lambda: {"games": 0, "v363_wins": 0,
                                    "v35_wins": 0, "censored": 0})
    by_first_player = defaultdict(lambda: {"games": 0, "v363_wins": 0,
                                          "v35_wins": 0, "censored": 0})
    for match in games:
        new_side = int(match["v363_side"])
        old_side = 1 - new_side
        level = int(match["level"])
        by_level[level]["games"] += 1
        first = int(match["first"])
        by_first_player[first]["games"] += 1
        winner = int(match["winner"])
        if winner in (0, 1):
            totals["finished"] += 1
            key = "v363_wins" if winner == new_side else "v35_wins"
            totals[key] += 1
            by_level[level][key] += 1
            by_first_player[first][key] += 1
        else:
            totals["censored"] += 1
            by_level[level]["censored"] += 1
            by_first_player[first]["censored"] += 1
        for metric in METRICS:
            totals["v363_" + metric] += int(match[metric][new_side])
            totals["v35_" + metric] += int(match[metric][old_side])
        totals["v363_anticipatory"] += int(match["anticipatory"])
        totals["v363_questionable_anticipatory"] += int(
            match["questionable_anticipatory"])
        totals["v363_abandoned_nonlethal_capture"] += int(
            match["abandoned_nonlethal_capture"])
    assessment = quality_assessment(totals)
    summary = {"run_type": "Godot real BattleSession 3.5 vs 3.6.3",
               "dataset": {"maps": [0, 2], "levels": [10, 12],
                           "fog": [False, True], "swap_first": True,
                           "swap_version_side": True},
               "totals": totals, "by_level": dict(sorted(by_level.items())),
               "by_first_player": dict(sorted(by_first_player.items())),
               "quality_assessment": assessment,
               "previous_v36_experiment": {
                   "wins": 10, "losses": 22, "retreats": 84,
                   "city_captures": 52, "initial_survivors": 84},
               "caveat": "Limited deterministic sample, Linux CPU only; no Android or other maps."}
    out_dir = pathlib.Path("reports")
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "ai_v363_ab_summary.json").write_text(
        json.dumps(summary, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8")
    md = [
        "# TARVOKA IA v3.6.3 — 32 partidas A/B frente a v3.5",
        "",
        "| Métrica | v3.5 (control) | v3.6.3 (experimental) |",
        "|---|---:|---:|",
        f"| Victorias | {totals['v35_wins']} | {totals['v363_wins']} |",
        f"| Partidas inconclusas | {totals['censored']} | {totals['censored']} |",
    ]
    names = {"retreats": "Retiradas", "captures": "Ciudades capturadas",
             "initial_survivors": "Unidades iniciales supervivientes (suma)",
             "losses": "Unidades destruidas (incluidos reclutas)",
             "attacks": "Ataques", "buys": "Compras de unidades"}
    for metric, title in names.items():
        md.append(
            f"| {title} | {totals['v35_'+metric]} | {totals['v363_'+metric]} |"
        )
    md.extend(["", "## Resultados por nivel", "",
               "| Nivel | Partidas | v3.5 | v3.6.3 | Inconclusas |",
               "|---|---:|---:|---:|---:|"])
    for level, row in sorted(by_level.items()):
        md.append(f"| {level} | {row['games']} | {row['v35_wins']} | "
                  f"{row['v363_wins']} | {row['censored']} |")
    md.extend(["", "## Influencia de la iniciativa", "",
        "| Primer bando | Partidas | Victorias v3.5 | Victorias v3.6.3 |",
        "|---|---:|---:|---:|"])
    for first, row in sorted(by_first_player.items()):
        md.append(f"| {first} | {row['games']} | {row['v35_wins']} | {row['v363_wins']} |")
    md.extend(["", "## Dictamen de calidad experimental", "",
        f"**{assessment['status']}** — esta evaluación no autoriza integración en APK.",
        ""])
    for key, passed in assessment["checks"].items():
        md.append(f"- {'OK' if passed else 'PENDIENTE'}: {key}")
    md.extend(["",
        f"Retiradas anticipatorias v3.6.3: **{totals['v363_anticipatory']}**.",
        f"Alertas internas: **{totals['v363_questionable_anticipatory']}**. "
        "Su ausencia NO demuestra que todas las retiradas fueran estratégicamente útiles.",
        "",
        "Referencia previa independiente (v3.6 original contra v3.5): "
        "**10/32 victorias v3.6**, **84 retiradas**. "
        "No reinterpretar esa comparación como enfrentamientos directos v3.6.3-v3.6.",
        "",
        "Prueba de laboratorio en Linux Godot 4.3; "
        "no certifica rendimiento Android ni estrategias adicionales.",
        ""])
    report = "\n".join(md)
    (out_dir / "ai_v363_ab_summary.md").write_text(report, encoding="utf-8")
    print("AB363_ALL " + json.dumps(summary, separators=(",", ":"), ensure_ascii=False))
    print(report)
    print("QUALITY_GATE " + json.dumps(assessment, separators=(",", ":")))
    print("PASS AI v363 aggregate: exact 32 unique starts validated; quality is advisory")
    return 0


if __name__ == "__main__":
    sys.exit(main())
