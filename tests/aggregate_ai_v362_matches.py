#!/usr/bin/env python3
"""Aggregate Godot v3.6.2 vs v3.5 REAL full-battle JSON logs.

No simulated victories or changes to battle logic. Fail clearly if
any of the 32 expected paired starts is missing or duplicated.
"""
import json
import pathlib
import sys
from collections import defaultdict

PREFIX = "AB361_MATCH "
METRICS = ("losses", "captures", "retreats", "attacks",
           "buys", "initial_survivors", "remaining_hp",
           "decision_us", "decision_calls")


def main() -> int:
    folder = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".ci-duel-logs")
    games = []
    for path in sorted(folder.rglob("*.log")):
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            marker = line.find(PREFIX)
            if marker < 0:
                continue
            try:
                value = json.loads(line[marker + len(PREFIX):])
            except json.JSONDecodeError as exc:
                raise SystemExit(f"Malformed match entry in {path}: {exc}") from exc
            games.append(value)
    expected = {(level, map_id, fog, first, side)
                for level in (10, 12)
                for map_id in (0, 2)
                for fog in (False, True)
                for first in (0, 1)
                for side in (0, 1)}
    observed = [(int(x["level"]), int(x["map"]), bool(x["fog"]),
                 int(x["first"]), int(x["v362_side"])) for x in games]
    if len(games) != 32 or set(observed) != expected or len(set(observed)) != 32:
        missing = sorted(expected - set(observed))
        duplicate_count = len(observed) - len(set(observed))
        raise SystemExit(
            f"INCOMPLETE A/B: games={len(games)}/32 "
            f"duplicates={duplicate_count}, missing={missing}"
        )
    totals = {"games": len(games), "finished": 0, "censored": 0,
              "v362_wins": 0, "v35_wins": 0,
              "v362_anticipatory": 0, "v362_questionable_anticipatory": 0,
              "v362_abandoned_nonlethal_capture": 0}
    for side in ("v362", "v35"):
        for metric in METRICS:
            totals[f"{side}_{metric}"] = 0
    by_level = defaultdict(lambda: {"games": 0, "v362_wins": 0,
                                    "v35_wins": 0, "censored": 0})
    for match in games:
        new_side = int(match["v362_side"])
        old_side = 1 - new_side
        level = int(match["level"])
        by_level[level]["games"] += 1
        winner = int(match["winner"])
        if winner in (0, 1):
            totals["finished"] += 1
            key = "v362_wins" if winner == new_side else "v35_wins"
            totals[key] += 1
            by_level[level][key] += 1
        else:
            totals["censored"] += 1
            by_level[level]["censored"] += 1
        for metric in METRICS:
            totals["v362_" + metric] += int(match[metric][new_side])
            totals["v35_" + metric] += int(match[metric][old_side])
        totals["v362_anticipatory"] += int(match["anticipatory"])
        totals["v362_questionable_anticipatory"] += int(
            match["questionable_anticipatory"])
        totals["v362_abandoned_nonlethal_capture"] += int(
            match["abandoned_nonlethal_capture"])
    summary = {"run_type": "Godot real BattleSession 3.5 vs 3.6.2",
               "dataset": {"maps": [0, 2], "levels": [10, 12],
                           "fog": [False, True], "swap_first": True,
                           "swap_version_side": True},
               "totals": totals, "by_level": dict(sorted(by_level.items())),
               "previous_v36_experiment": {
                   "wins": 10, "losses": 22, "retreats": 84,
                   "city_captures": 52, "initial_survivors": 84},
               "caveat": "Limited deterministic sample, Linux CPU only; no Android or other maps."}
    out_dir = pathlib.Path("reports")
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "ai_v362_ab_summary.json").write_text(
        json.dumps(summary, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8")
    md = [
        "# TARVOKA IA v3.6.2 — 32 partidas A/B frente a v3.5",
        "",
        "| Métrica | v3.5 (control) | v3.6.2 (experimental) |",
        "|---|---:|---:|",
        f"| Victorias | {totals['v35_wins']} | {totals['v362_wins']} |",
        f"| Partidas inconclusas | {totals['censored']} | {totals['censored']} |",
    ]
    names = {"retreats": "Retiradas", "captures": "Ciudades capturadas",
             "initial_survivors": "Unidades iniciales supervivientes (suma)",
             "losses": "Unidades destruidas (incluidos reclutas)",
             "attacks": "Ataques", "buys": "Compras de unidades"}
    for metric, title in names.items():
        md.append(
            f"| {title} | {totals['v35_'+metric]} | {totals['v362_'+metric]} |"
        )
    md.extend(["", "## Resultados por nivel", "",
               "| Nivel | Partidas | v3.5 | v3.6.2 | Inconclusas |",
               "|---|---:|---:|---:|---:|"])
    for level, row in sorted(by_level.items()):
        md.append(f"| {level} | {row['games']} | {row['v35_wins']} | "
                  f"{row['v362_wins']} | {row['censored']} |")
    md.extend(["",
        f"Retiradas anticipatorias v3.6.2: **{totals['v362_anticipatory']}**.",
        f"Alertas internas: **{totals['v362_questionable_anticipatory']}**. "
        "Su ausencia NO demuestra que todas las retiradas fueran estratégicamente útiles.",
        "",
        "Referencia previa independiente (v3.6 original contra v3.5): "
        "**10/32 victorias v3.6**, **84 retiradas**. "
        "No reinterpretar esa comparación como enfrentamientos directos v3.6.2-v3.6.",
        "",
        "Prueba de laboratorio en Linux Godot 4.3; "
        "no certifica rendimiento Android ni estrategias adicionales.",
        ""])
    report = "\n".join(md)
    (out_dir / "ai_v362_ab_summary.md").write_text(report, encoding="utf-8")
    print("AB361_ALL " + json.dumps(summary, separators=(",", ":"), ensure_ascii=False))
    print(report)
    print("PASS AI v362 aggregate: exact 32 unique starts validated")
    return 0


if __name__ == "__main__":
    sys.exit(main())
