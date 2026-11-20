# TARVOKA Taller de Blindados — revisión de color de facción (noviembre 2026)

## Objetivo visual

El usuario aprobó la arquitectura, acabados mecánicos, evolución N1–N3 y daños D0–D4, pero pidió aumentar **un poco** el color de las facciones para que el edificio sea más identificable en perspectiva isométrica y en el mapa Android.

Se conservan los ocho colores oficiales de `VisualStyle.faction_color` y el neutral original `ArmoredWorkshop3DV2.NEUTRAL`: **no se inventa una tonalidad distinta por facción**, y no se repinta todo el edificio. En particular el neutral sigue siendo gris azulado y no se confunde con la facción amarilla.

## Modificaciones aplicadas al modelo detallado HERO V2

| Parte | Antes | Ahora |
| --- | --- | --- |
| Franja superior frontal | 76 % de ancho, altura 0,15 | 82 % de ancho, altura 0,22 |
| Placa por bahía | 32 % del ancho de bahía, altura 0,25 | 44 % de ancho, altura 0,30 |
| Perfil lateral | 0,11 de alto, 72 % de longitud | 0,18 de alto, 82 % de longitud, color oficial sin oscurecer |
| Identificador lateral superior | No existía | Insignia alta pequeña por lado |
| Franja posterior | 68 % de anchura, altura 0,14 | 78 % de anchura, altura 0,21 |
| Techo | Sin placa continua por bahía | Placa de facción opaca de 62 % de ancho por bahía, sobre las nervaduras y fuera de la ventilación |
| Ruinas D3/D4 | Cartel caído | Cartel caído un poco más visible y placa menor de facción apoyada sobre el suelo |

En los estados D0–D2, las placas del techo son opacas y elevadas por encima de las nervaduras, **sin agujeros ni interferencias con ventanales**. D3/D4 no mantienen emblemas aéreos flotantes ni cubiertas completas.

## Android táctico y distante

- Frente por bahía: franja **60 % → 73 %** de ancho; altura **0,17 → 0,24**.
- Techo por bahía: placa **44 % → 63 %** de ancho, ligeramente más larga; usa material de facción existente.
- Costados: franja **7 % → 11 % de la altura** y **24 % → 34 % del fondo**.
- Posterior: franja **63 % → 78 %** de ancho, colocada por encima de los ventanales.
- Remate de techo frontal: **73 % → 82 %** de ancho.
- Ruinas: emblema caído un poco más grande pero siempre apoyado en el piso.

El aumento **no agrega una nueva categoría de material** ni un lote GPU extra al modelo Android: utiliza el MultiMesh `Lote_faction` existente. Se mantienen los límites estructurales de `tests/test_armored_workshop_mobile_lod.gd`.

## Control de calidad

- `test_armored_workshop_v2_native.gd`: verifica las placas frontales, posteriores, laterales y una por bahía en las **135 variantes detalladas** (3 niveles × 9 paletas × 5 daños), además del emblema caído D3/D4.
- `test_armored_workshop_mobile_lod.gd`: verifica que **270 variantes Android** (135 × 2 perfiles) preservan el color oficial y las dimensiones mínimas de las placas y que los MultiMesh conservan sus límites.
- `capture_armored_workshop_faction_colors.gd`: **27 capturas nativas de Godot**, los nueve colores en N2 D0 desde una cámara comparable, en HERO, Android táctico y distante.
- `armored-workshop-v2-art-qa.yml`: genera **114 capturas** cuando termine el flujo (87 vistas generales, evolución y daños + 27 comparaciones cromáticas).

## Límites

No toca `BattleTerrain3D.gd`, código de combate, valores de facciones, reglas de reparación, producción, suministro, economía ni APK. La revisión de colores es 3D, no un efecto de imagen plano, y requiere aprobación visual antes de considerar cerrado el arte.
