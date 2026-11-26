# A02 — comparación de evidencia artística

Usar los ZIP originales del workflow nativo, no capturas conceptuales o imágenes recomprimidas. Requiere Python 3 y Pillow.

```sh
python tools/review_a02_art.py anterior.zip candidato.zip --output build/qa/art-review
```

El programa verifica inventario, SHA-256 de cada PNG, resolución 960×680 y las 80 combinaciones de facción/LOD/daño. Genera `comparison.png` (20 vistas equivalentes), `review.json` (huellas de ambos ZIP, diferencias de píxeles y presupuestos medidos), y `macro.png` si el candidato incluye acercamientos adicionales. Los acercamientos sin equivalente anterior están etiquetados como tales. La fracción de píxeles distintos no es una nota artística ni demuestra igualdad de calidad con Bastion. Revisar el acabado junto con la referencia nativa P06, artifact 15156604740. La geometría de partida puede conservarse aunque el coste de texturas cambie; no implica FPS medidos.

Validación local con archivos reales V17 (15157333736) y V18 (15158576987): 52/52 PNG de cada revisión, 80 estados, 20 vistas comparadas, geometría LOD8 estable. Control V18 contra V18: cero diferencias en 20 vistas. Prueba negativa: un PNG alterado es rechazado por huella incorrecta. V19/V20 todavía en cola; las macros de esas revisiones no se han renderizado ni inspeccionado. La norma de acabado de Bastion y aprobación humana sigue vigente.
