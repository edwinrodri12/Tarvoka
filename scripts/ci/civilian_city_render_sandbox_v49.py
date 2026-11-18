"""Build an isolated Godot 4.3 project with native direct-viewport city art.

The unified military studio uses a separately assembled super-class and cannot
be imported directly from the raw art branch. This is for visual review only.
"""
from pathlib import Path
import re
import shutil

repo = Path.cwd()
sandbox = repo / "build" / "city-v49-sandbox"
sandbox.mkdir(parents=True, exist_ok=True)
queue = [
    "scripts/ui/CivilianCityVisualProofV50.gd",
    "scenes/CivilianCityDesignStudioV43.tscn",
]
reference = re.compile(r"res://([A-Za-z0-9_./@-]+\.(?:gd|tscn|tres|gdshader|png|jpg|jpeg|svg|webp))")
copied = set()
missing = set()
while queue:
    rel = queue.pop()
    if rel in copied:
        continue
    original = repo / rel
    if not original.is_file():
        missing.add(rel)
        continue
    dest = sandbox / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(original, dest)
    copied.add(rel)
    if original.suffix in (".gd", ".tscn", ".tres", ".gdshader"):
        contents = original.read_text(encoding="utf-8")
        for found in reference.findall(contents):
            if found not in copied:
                queue.append(found)

(sandbox / "project.godot").write_text(
    "config_version=5\n"
    "[application]\n"
    'config/name="TARVOKA Ciudades: revision de arte"\n'
    'run/main_scene="res://scenes/CivilianCityDesignStudioV43.tscn"\n'
    "[rendering]\n"
    'renderer/rendering_method="gl_compatibility"\n'
    'renderer/rendering_method.mobile="gl_compatibility"\n',
    encoding="utf-8",
)
evidence = repo / "build" / "city-v44-evidence"
evidence.mkdir(parents=True, exist_ok=True)
(evidence / "v49-project-inventory.txt").write_text(
    "Independent Godot 4.3 civilian city art project\n"
    + "\n".join(sorted(copied)) + "\n", encoding="utf-8"
)
if missing:
    (evidence / "v49-missing-resources.txt").write_text(
        "\n".join(sorted(missing)) + "\n", encoding="utf-8"
    )
    raise SystemExit("Missing art resources: " + ", ".join(sorted(missing)))
for forbidden in (
    "scripts/ui/BastionStudioAdapter.gd",
    "scripts/ui/CivilianCityStudioAdapter.gd",
    "scripts/ui/CombinedArtStudioWeb.gd",
):
    if (sandbox / forbidden).exists():
        raise SystemExit("Unexpected non-city adapter: " + forbidden)
print(f"V49: isolated {len(copied)} required native art resources")
