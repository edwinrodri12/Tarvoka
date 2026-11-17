#!/usr/bin/env python3
"""Unit tests for log extraction, not fabricated battle outcomes."""
import json

from aggregate_ai_v362_matches import parse_match_line, quality_assessment

def main():
    commands = [
        "2026-11-17T20:43:00Z test \"$(grep -c '^AB362_MATCH ' /tmp/test.log)\" -eq 4",
        "2026-11-17T20:43:00Z grep -Fq 'AB362_MATCH ' /tmp/test.log",
        "2026-11-17T20:43:00Z command prints the literal AB362_MATCH word",
        "2026-11-17T20:43:00Z AB362_MATCH ",
    ]
    for line in commands:
        assert parse_match_line(line) is None
    payload = {"v362_side": 1, "level": 12, "map": 2, "fog": True, "first": 0}
    row = "2026-11-17T20:43:00Z AB362_MATCH " + json.dumps(payload)
    assert parse_match_line(row) == payload
    broken = "AB362_MATCH {\"v362_side\":1, bad}"
    try:
        parse_match_line(broken)
    except ValueError:
        pass
    else:
        raise AssertionError("Malformed actual JSON must fail")
    totals = {
        "finished": 32, "censored": 0, "v362_wins": 17, "v35_wins": 15,
        "v362_captures": 61, "v35_captures": 60,
        "v362_initial_survivors": 90, "v35_initial_survivors": 88,
        "v362_retreats": 22, "v362_questionable_anticipatory": 0,
        "v362_abandoned_nonlethal_capture": 0,
    }
    good = quality_assessment(totals)
    assert good["status"] == "candidate_for_broader_testing"
    assert good["merge_approved"] is False
    totals["v362_wins"] = 10
    assert quality_assessment(totals)["status"] == "needs_tuning"
    print("PASS AI v362 log parser and advisory quality gate")

if __name__ == "__main__":
    main()
