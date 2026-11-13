#!/usr/bin/env python3
"""Create a responsive, offline review page for real TARVOKA Godot captures."""
from __future__ import annotations

import html
import json
import sys
from pathlib import Path

CSS = """
:root {color-scheme:dark;font-family:system-ui,-apple-system,Segoe UI,sans-serif}
*{box-sizing:border-box}
body{margin:0;background:#08131f;color:#f1f5f2}
header{max-width:1320px;margin:auto;padding:30px 24px 18px}
h1{font-size:clamp(1.65rem,4vw,2.5rem);letter-spacing:.08em;margin:0 0 8px}
h1 span{color:#ffd44a}
p{color:#b3cedd;line-height:1.55}
.notice{border-left:3px solid #36c3ff;padding-left:14px;max-width:950px}
.gallery{max-width:1320px;margin:0 auto 60px;padding:12px 24px;
 display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,350px),1fr));gap:22px}
figure{margin:0;background:#102332;border:1px solid #1475a8;border-radius:10px;
 padding:12px;box-shadow:0 8px 20px #0005}
img{max-width:100%;height:auto;max-height:580px;display:block;margin:auto;
 object-fit:contain;border-radius:5px;background:#050c14}
figcaption{margin:10px 3px 4px;font-weight:600;line-height:1.35}
small{display:block;color:#b3cedd;margin-top:4px;font-size:.82rem}
a{color:#82d8ff;text-decoration:none}
a:hover{text-decoration:underline}
footer{padding:0 24px 40px;text-align:center;color:#b3cedd}
"""


def main(folder: Path) -> None:
    manifest = folder / "manifest.json"
    if not manifest.is_file():
        raise SystemExit("Falta manifest.json: Godot no entregó las capturas.")
    data = json.loads(manifest.read_text(encoding="utf-8"))
    shots = data.get("screens", [])
    if len(shots) != 10:
        raise SystemExit(f"Se esperaban 10 capturas, hay {len(shots)}")
    cards = []
    for entry in shots:
        filename = str(entry["file"])
        if Path(filename).name != filename or not filename.endswith(".png"):
            raise SystemExit("Nombre de captura no permitido")
        path = folder / filename
        if not path.is_file() or path.stat().st_size < 1000:
            raise SystemExit(f"Captura faltante o vacía: {filename}")
        with path.open("rb") as inp:
            header = inp.read(24)
        if header[:8] != b"\x89PNG\r\n\x1a\n":
            raise SystemExit(f"No es un PNG: {filename}")
        pixels = (int.from_bytes(header[16:20], "big"),
                  int.from_bytes(header[20:24], "big"))
        expected = (int(entry["width"]), int(entry["height"]))
        if pixels != expected:
            raise SystemExit(f"Dimensiones erróneas en {filename}: {pixels} != {expected}")
        label = html.escape(str(entry["title"]))
        safe = html.escape(filename, quote=True)
        cards.append(
            f'<figure><a href="{safe}" target="_blank" rel="noopener">'
            f'<img src="{safe}" alt="{label}" loading="lazy"></a>'
            f'<figcaption>{label}<small>{pixels[0]} × {pixels[1]}'
            f' · <a href="{safe}" download>PNG completo</a></small></figcaption>'
            f'</figure>'
        )
    page = (
        '<!doctype html><html lang="es"><head>'
        '<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">'
        '<title>TARVOKA · Revisión visual</title>'
        f'<style>{CSS}</style></head><body>'
        '<header><h1>TAR<span>VOKA</span> · Revisión visual</h1>'
        '<p>Diez capturas reales del renderizador Godot en tamaño Android y escritorio.'
        ' Abre cada imagen para inspeccionar botones, escala, retratos y márgenes.</p>'
        '<p class="notice">Vista de QA generada automáticamente; el resultado terminal'
        ' es una demostración visual simulada. Esto no verifica rendimiento táctil,'
        ' notch, FPS ni compatibilidad física con todos los teléfonos.</p>'
        '</header><main class="gallery">'
        + "".join(cards) +
        '</main><footer>Sin APK · Sin recursos externos · Arte oficial TARVOKA</footer>'
        '</body></html>'
    )
    output = folder / "index.html"
    output.write_text(page, encoding="utf-8")
    print(f"PASS review gallery: {len(shots)} verified PNG images + {output.name}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Uso: build_gallery_index.py /ruta/a/capturas")
    main(Path(sys.argv[1]))
