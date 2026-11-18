# TARVOKA HAT-29 A01 — V14.8: articulaciones reales de paso del rotor

## Continuidad de diseño
Se continúa sobre el HAT-29 V14.7 ya integrado, sin rehacer el helicóptero, ni duplicar el rotor V1/V3, ni sustituir los amortiguadores V14.6/V14.7. **Estado: iteración artística, no aprobación final.**

## Nueva geometría 3D nativa
El módulo `scripts/ui/AttackHelicopterPitchHingesV148.gd` se instala tras V14.7 mediante `UnitModels3D.build("attack_heli", faccion, true, 14)`. Cada una de las cuatro palas recibe dentro del **pivote original** `A01_AspaPortante_0..3`:

- Una base mecánica en la raíz del paso.
- Dos horquillas cortas, cada una conectada a un punto de la raíz.
- Una bieleta exterior continua que une ambos extremos, y un manguito de regulación.
- Dos pasadores, dos arandelas y una funda de goma protectora **modelados en volumen real**.
- Materiales PBR discretos: acero, grafito, arandelas bronce desaturado, caucho mate.

El sistema V14.7 vive en el lado local **+X**, y V14.8 se modela en **−X** para que la bieleta no atraviese el amortiguador. Las dimensiones son de inspección macro, no de representación a escala de ingeniería. Las 8 libreas conservan su tonalidad V14.3, sin pintura nueva ni saturación extra.

## Animación, rendimiento y continuidad
- Los cuatro grupos se mueven con los pivotes y la rotación auténtica existente; **no** se añade reloj de animación.
- El daño y desprendimiento del rotor V13 ocultan el conjunto por herencia de su nodo.
- La restauración V13 sigue usando el mismo rotor, sin efectos ni estados extra.
- El nivel de arte de combate Android `<=10` **no** construye estas piezas.
- No cambian armas, estadísticas, equilibrio, lógica, estadísticas del mapa ni recursos.

## Visor 3D unificado
En **Unidades → Helicóptero HAT-29 → Detalles**:
1. **V14.8: horquillas de paso**: cámara sobre el lado -X de la raíz.
2. **V14.8: pasadores y bieletas**: vista superior de conexiones físicas.

El script está agregado al empaquetado de GitHub Pages en `.github/workflows/tarvoka-3d-pages.yml`.

## Verificación preparada
- `tests/test_attack_helicopter_v14.gd`: ocho facciones; 4 pivotes nativos; cilindros reales; caucho PBR; idempotencia y no inclusión en Android LOD10.
- `tests/test_attack_helicopter_v9_studio.gd`: dos botones nuevos y continuidad de la misma instancia del modelo.
- `tests/test_attack_helicopter_v14_capture.gd`: 45 PNG de Godot previstos, incluidos dos nuevos macros de V14.8.
- `.github/workflows/a01-v14-hat29-visual-qa.yml`: captura y prueba nativa actualizadas.

**Nota:** añadir el código, las pruebas y las acciones de CI no equivale a haber revisado visualmente las 45 imágenes. La aprobación estética requiere revisar la exportación Godot real.
