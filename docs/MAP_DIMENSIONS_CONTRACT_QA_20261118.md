# TARVOKA — contrato de dimensiones de mapa (18 noviembre 2026)

## Alcance
La PR #586 incorpora `tests/test_map_dimensions_contract.gd` para tamaños 10×8, 24×18 y 40×30, límites, filas irregulares, terreno desconocido y tamaños no admitidos. No modifica las reglas ni el juego Android.

## Ejecución reproducible
`godot --headless --path . --script res://tests/test_map_dimensions_contract.gd`

El workflow `.github/workflows/map-dimensions-contract.yml` ejecuta el mismo contrato con Godot 4.3, exige un marcador PASS y falla ante errores de script. La presencia del workflow no equivale a una ejecución satisfactoria; consultar Actions para el SHA de esta rama antes de marcar PASÓ.

## Estados de QA
- Código y workflow: propuestos en PR #586, sin merge a main.
- Godot 4.3 del nuevo workflow: PENDIENTE DE CONFIRMACIÓN DE CI.
- Integración de partida, IA, guardado y victoria: NO EJECUTADO por este contrato (regresiones separadas necesarias).
- Android físico: NO EJECUTADO EN DISPOSITIVO.
- QA visual: NO APLICA (contrato lógico).

## Siguiente paso
Confirmar el resultado del workflow sobre el commit más reciente; si falla, corregir la prueba sin alterar las reglas aprobadas. Después trabajar una mejora independiente, evitando conflictos con PR #585 y el terreno #203.
