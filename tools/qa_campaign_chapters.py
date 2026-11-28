"""Offline campaign design contract; not a playable-mission test.
Run: python3 tools/qa_campaign_chapters.py [path]
"""
import re
import sys
import unittest
from pathlib import Path

FACTIONS = {"Alianza Norte", "Pacto Escarlata", "Unión Verde",
            "Confederación Solar", "Sindicato Violeta", "Legión Ámbar",
            "Dominio Turquesa", "Orden Ónix"}
SPECIAL = {38: "Alianza Norte + Pacto Escarlata",
           49: "Coalición dinámica", 50: "Coalición dinámica"}

def validate(source):
    errors = []
    ids, titles, seen = [], set(), set()
    for line in source.splitlines():
        if not re.match(r"^\|\s*\d+\s*\|", line):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) != 4:
            errors.append("Malformed chapter row: " + line)
            continue
        number, title, faction, objective = cells
        n = int(number)
        ids.append(n)
        if number != f"{n:02d}":
            errors.append(f"Noncanonical ID: {number}")
        key = title.casefold()
        if not title or key in titles:
            errors.append(f"Missing or duplicate title: {n}")
        titles.add(key)
        if not objective:
            errors.append(f"Missing objective: {n}")
        if n in SPECIAL:
            if faction != SPECIAL[n]:
                errors.append(f"Unexpected special faction: {n}")
        elif faction not in FACTIONS:
            errors.append(f"Unknown faction: {n}")
        else:
            seen.add(faction)
    if ids != list(range(1, 51)):
        errors.append("Expected ordered chapter IDs 01–50 exactly once")
    if seen != FACTIONS:
        errors.append("Not all eight official factions represented")
    return errors

class ContractTests(unittest.TestCase):
    def fixture(self):
        factions = sorted(FACTIONS)
        return "\n".join(f"| {n:02d} | Title {n} | {SPECIAL.get(n, factions[n % 8])} | Objective |" for n in range(1, 51))

    def test_valid(self):
        self.assertEqual(validate(self.fixture()), [])

    def test_missing(self):
        self.assertTrue(validate("\n".join(self.fixture().splitlines()[:-1])))

    def test_duplicate(self):
        self.assertTrue(validate(self.fixture().replace("| 02 |", "| 01 |")))

    def test_unknown_faction(self):
        self.assertTrue(validate(self.fixture().replace("Alianza Norte", "Unknown", 1)))

    def test_missing_objective(self):
        self.assertTrue(validate(self.fixture().replace("| Objective |", "| |", 1)))

    def test_duplicate_title(self):
        self.assertTrue(validate(self.fixture().replace("| Title 2 |", "| Title 1 |")))

if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(ContractTests)
    if not unittest.TextTestRunner().run(suite).wasSuccessful():
        sys.exit(1)
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1] / "CAMPAIGN_STORY_50.md"
    errors = validate(path.read_text(encoding="utf-8"))
    for error in errors:
        print(error, file=sys.stderr)
    if errors:
        sys.exit(1)
    print("PASS: 50 ordered narrative chapter IDs and faction contract")
