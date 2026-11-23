import unittest
from check_initiative_pairs import summarize


class PairedInitiativeTests(unittest.TestCase):
    def test_balanced_legs(self):
        self.assertEqual(summarize([
            {"pair_id": "map-a", "starter": "blue", "winner": "blue"},
            {"pair_id": "map-a", "starter": "red", "winner": "blue"},
        ])["starter_win_rate_decisive"], 0.5)

    def test_starter_sweep(self):
        result = summarize([
            {"pair_id": "a", "starter": "blue", "winner": "blue"},
            {"pair_id": "a", "starter": "red", "winner": "red"},
        ])
        self.assertEqual(result["starter_wins"], 2)
        self.assertEqual(result["second_wins"], 0)

    def test_all_draws(self):
        result = summarize([
            {"pair_id": "a", "starter": "blue", "winner": "draw"},
            {"pair_id": "a", "starter": "red", "winner": "draw"},
        ])
        self.assertIsNone(result["starter_win_rate_decisive"])

    def test_pair_patterns_distinguish_biases(self):
        outcomes = [
            ("starter", "blue", "red"),
            ("second", "red", "blue"),
            ("blue", "blue", "blue"),
            ("red", "red", "red"),
            ("draw", "draw", "blue"),
        ]
        rows = [
            {"pair_id": name, "starter": starter, "winner": winner}
            for name, blue_win, red_win in outcomes
            for starter, winner in (("blue", blue_win), ("red", red_win))
        ]
        patterns = summarize(rows)["pair_patterns"]
        self.assertEqual(patterns, {
            "starter_sweep": 1, "second_sweep": 1,
            "blue_sweep": 1, "red_sweep": 1, "draw_involved": 1,
        })
        self.assertEqual(sum(patterns.values()), 5)

    def test_wilson_uncertainty_small_samples(self):
        for winners, expected_rate in [
            (("blue", "red"), 1.0),
            (("red", "blue"), 0.0),
            (("blue", "blue"), 0.5),
        ]:
            with self.subTest(winners=winners):
                result = summarize([
                    {"pair_id": "x", "starter": "blue", "winner": winners[0]},
                    {"pair_id": "x", "starter": "red", "winner": winners[1]},
                ])
                lower, upper = result["starter_win_rate_wilson95"]
                self.assertLessEqual(lower, expected_rate)
                self.assertGreaterEqual(upper, expected_rate)
                self.assertGreater(upper - lower, 0.3)

    def test_wilson_null_for_draws(self):
        result = summarize([
            {"pair_id": "x", "starter": "blue", "winner": "draw"},
            {"pair_id": "x", "starter": "red", "winner": "draw"},
        ])
        self.assertIsNone(result["starter_win_rate_wilson95"])

    def test_missing_leg_rejected(self):
        with self.assertRaises(ValueError):
            summarize([{"pair_id": "a", "starter": "blue", "winner": "red"}])

    def test_duplicate_leg_rejected(self):
        with self.assertRaises(ValueError):
            summarize([
                {"pair_id": "a", "starter": "blue", "winner": "blue"},
                {"pair_id": "a", "starter": "blue", "winner": "red"},
            ])

    def test_invalid_winner_rejected(self):
        with self.assertRaises(ValueError):
            summarize([
                {"pair_id": "a", "starter": "blue", "winner": "unknown"},
                {"pair_id": "a", "starter": "red", "winner": "red"},
            ])


if __name__ == "__main__":
    unittest.main()
