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


def summarize(rows):
    pairs = defaultdict(dict)
    for index, row in enumerate(rows):
        if not isinstance(row, dict):
            raise ValueError(f"match {index}: expected object")
        pair_id, starter, winner = (row.get(k) for k in ("pair_id", "starter", "winner"))
        if not isinstance(pair_id, str) or not pair_id.strip():
            raise ValueError(f"match {index}: missing pair_id")
        if starter not in ("blue", "red") or winner not in ("blue", "red", "draw"):
            raise ValueError(f"match {index}: invalid starter/winner")
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
    return {"pairs": len(pairs), "matches": len(pairs) * 2,
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
