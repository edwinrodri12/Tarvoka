# TARVOKA — A01 Helicóptero de ataque / V8 identificación táctica 3D

**Estado:** V8 en PR #444, no publicado en el Estudio 3D hasta completar validación y revisión.

## Diagnóstico visual de V7.1

La última suite de Godot 4.3 de V7.1 **PASÓ** (A01 V1–V7, marcas de píxeles reales a resolución 320×180, API de dibujo y captura). El reporte auténtico de la prueba comparativa mostró sólo **229 píxeles distintos de 230.400** entre V6/V7 con las cuatro vistas idénticas: es una mejora visual insuficiente a tamaño de juego. Los acercamientos muestran los materiales y las formas, pero la identidad no resulta reconocible en la vista general.

## Escultura V8 — 3D original, no imágenes
`scripts/ui/AttackHelicopterSilhouetteV8.gd`
- **Dos paneles de extremo de ala V3:** casquetes poligonales de pintura de cada facción, sólidos cerrados de 14 mm, directamente sobre la superficie de ala a y≈0.866. Cubren solo el ~30 % exterior de cada ala con bordes estrechos metálicos. Se oculta la pequeña franja superior V3 anterior mientras V8 está activo; se recupera en comparación V7.
- **Dos paneles curvados sobre las nacelas V4:** esmalte metálico sólido construido con `SurfaceTool` y anillos que siguen radios y alturas de las estaciones originales (Z0.40, 0.76, 1.03); el relieve sobresale solamente 10 mm, el interior penetra 4 mm en la piel. No son cajas flotantes ni se colocan sobre los respiraderos.
- **Dos identificadores en la aleta vertical:** placas cerradas, montadas directamente como hijos de la aleta original girada 12 grados para preservar su transformación.
- **8 pinturas de facción** y comparación V7↔V8, reversibles con `set_enabled`.
- Se conservan V1–V7, fuselaje y rotores móviles, armas, cabina, tren y motores.
- Es estrictamente un LOD de exhibición (`finish_enabled && art_level>=13`); el helicóptero Android táctico (`art_level<=10`) no cambia.

## QA verificable
`tests/test_attack_helicopter_v8.gd` comprueba las 8 facciones, piezas de ambos lados, sólidos cerrados, unión a la aleta, convergencia con la curva V4 (<12 mm), restauración V7 y poses sin cambios. `tests/test_attack_helicopter_v8_capture.gd` genera 15 fotogramas reales: 8 orbitales V8 a 320×180, 4 referencias V7 a la misma distancia, iluminación y pose, y 3 primeros planos 960×720 de ala, motor y aleta. La diferencia de píxeles debe aumentar al menos en 80 píxeles sobre el control V7, sin colorear más del 8 % de la imagen.

Workflow `.github/workflows/a01-helicopter-qa.yml` recoge el reporte nativo y los 15 PNG como `tarvoka-a01-v8-320p-review`. No declarar esta V8 validada sin ejecutar la suite, inspeccionar las imágenes y corregir cualquier regresión real.

**Próxima prioridad:** inspección óptica V8/V7 y ajuste fino de proporciones y contrastes. No publicar la rama draft sin terminar este control.
