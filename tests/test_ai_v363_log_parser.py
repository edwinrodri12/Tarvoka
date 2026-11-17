#!/usr/bin/env python3
"""Unit tests for log extraction, not fabricated battle outcomes."""
import json

from aggregate_ai_v363_matches import parse_match_line, quality_assessment

def main():
    commands = [
        "2026-11-17T20:43:00Z test \"$(grep -c '^AB363_MATCH ' /tmp/test.log)\" -eq 4",
        "2026-11-17T20:43:00Z grep -Fq 'AB363_MATCH ' /tmp/test.log",
        "2026-11-17T20:43:00Z command prints the literal AB363_MATCH word",
        "2026-11-17T20:43:00Z AB363_MATCH ",
    ]
    for line in commands:
        assert parse_match_line(line) is None
    payload = {"v363_side": 1, "level": 12, "map": 2, "fog": True, "first": 0}
    row = "2026-11-17T20:43:00Z AB363_MATCH " + json.dumps(payload)
    assert parse_match_line(row) == payload
    broken = "AB363_MATCH {\"v363_side\":1, bad}"
    try:
        parse_match_line(broken)
    except ValueError:
        pass
    else:
        raise AssertionError("Malformed actual JSON must fail")
    totals = {
        "finished": 32, "censored": 0, "v363_wins": 17, "v35_wins": 15,
        "v363_captures": 61, "v35_captures": 60,
        "v363_initial_survivors": 90, "v35_initial_survivors": 88,
        "v363_retreats": 22, "v363_questionable_anticipatory": 0,
        "v363_abandoned_nonlethal_capture": 0,
    }
    good = quality_assessment(totals)
    assert good["status"] == "candidate_for_broader_testing"
    assert good["merge_approved"] is False
    totals["v363_wins"] = 10
    assert quality_assessment(totals)["status"] == "needs_tuning"
    print("PASS AI v363 log parser and advisory quality gate")

if __name__ == "__main__":
    main()
