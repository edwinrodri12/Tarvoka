#!/usr/bin/env python3
"""Summarize paired TARVOKA simulations without changing gameplay or balance.

Input: JSON list of {"pair_id": str, "starter": "blue"|"red",
"winner": "blue"|"red"|"draw"}. Each pair must contain one blue-start
and one red-start match. Missing or duplicate legs are rejected.
"""
import argparse
import json
from collections import defaultdict
from pathlib import Path
from math import sqrt


def summarize(rows):
    pairs = defaultdict(dict)
    for index, row in enumerate(rows):
        if not isinstance(row, dict):
            raise ValueError(f"match {index}: expected object")
        pair_id, starter, winner = (row.get(k) for k in ("pair_id", "starter", "winner"))
        if not isinstance(pair_id, str) or not pair_id.strip():
            raise ValueError(f"match {index}: missing pair_id")
        if (not isinstance(starter, str) or starter not in ("blue", "red")
                or not isinstance(winner, str) or winner not in ("blue", "red", "draw")):
            raise ValueError(f"match {index}: invalid starter/winner")
        # Normalize surrounding whitespace so one logical scenario cannot split into two pairs.
        pair_id = pair_id.strip()
        if starter in pairs[pair_id]:
            raise ValueError(f"pair {pair_id}: duplicate {starter} starter")
        pairs[pair_id][starter] = winner
    if not pairs:
        raise ValueError("at least one paired match is required")
    if any(set(legs) != {"blue", "red"} for legs in pairs.values()):
        raise ValueError("each pair requires blue and red starter legs")
    starter_wins = sum(winner == starter for legs in pairs.values()
                       for starter, winner in legs.items())
    second_wins = sum(winner not in ("draw", starter) for legs in pairs.values()
                      for starter, winner in legs.items())
    draws = sum(winner == "draw" for legs in pairs.values() for winner in legs.values())
    blue_wins = sum(winner == "blue" for legs in pairs.values() for winner in legs.values())
    red_wins = sum(winner == "red" for legs in pairs.values() for winner in legs.values())
    # Separate initiative sweeps from faction sweeps in mirrored games.
    patterns = {"starter_sweep": 0, "second_sweep": 0,
                "blue_sweep": 0, "red_sweep": 0, "draw_involved": 0}
    for legs in pairs.values():
        blue_start, red_start = legs["blue"], legs["red"]
        if "draw" in (blue_start, red_start):
            patterns["draw_involved"] += 1
        elif blue_start == "blue" and red_start == "red":
            patterns["starter_sweep"] += 1
        elif blue_start == "red" and red_start == "blue":
            patterns["second_sweep"] += 1
        elif blue_start == red_start == "blue":
            patterns["blue_sweep"] += 1
        else:
            patterns["red_sweep"] += 1
    # Pair-level directional signal: excludes faction sweeps and draw-involved pairs.
    directional_sweeps = patterns["starter_sweep"] + patterns["second_sweep"]
    starter_sweep_share = (patterns["starter_sweep"] / directional_sweeps
                           if directional_sweeps else None)
    decisive = starter_wins + second_wins
    # Wilson 95% interval: descriptive uncertainty, not proof of fairness.
    # Report null for all-draw samples rather than inventing a 50% estimate.
    interval = None
    if decisive:
        z = 1.959963984540054
        p = starter_wins / decisive
        denom = 1 + z * z / decisive
        center = (p + z * z / (2 * decisive)) / denom
        radius = z * sqrt(p * (1 - p) / decisive + z * z / (4 * decisive * decisive)) / denom
        interval = [max(0.0, center - radius), min(1.0, center + radius)]
    return {"starter_sweep_share_directional_pairs": starter_sweep_share,
            "directional_sweep_pairs": directional_sweeps,
            "starter_win_rate_wilson95": interval, "pair_patterns": patterns, "pairs": len(pairs), "matches": len(pairs) * 2,
            "starter_wins": starter_wins, "second_wins": second_wins,
            "draws": draws, "blue_wins": blue_wins, "red_wins": red_wins,
            "starter_win_rate_decisive": (
                starter_wins / (starter_wins + second_wins)
                if starter_wins + second_wins else None)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("matches", type=Path, help="JSON array of paired match results")
    args = parser.parse_args()
    try:
        rows = json.loads(args.matches.read_text(encoding="utf-8"))
        if not isinstance(rows, list):
            raise ValueError("top-level JSON must be an array")
        print(json.dumps(summarize(rows), indent=2, sort_keys=True))
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        parser.exit(2, f"invalid matchup data: {exc}\n")


if __name__ == "__main__":
    main()
