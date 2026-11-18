# TARVOKA — Investigación territorial y de puntuación de relés v3.7.2

**Fecha del proyecto: 17 noviembre 2026. Rama exclusiva de investigación; no fusionar ni sustituir la APK del juego.**

## Motivo de esta prioridad

Las [256 partidas de v3.7.0](https://github.com/edwinrodri12/Tarvoka/actions/runs/44226290001) probaron que eliminar los 100 créditos que el segundo recibía inicialmente **no cambió al ganador en ninguna de 128 parejas**; el nuevo ingreso simétrico está implementado como regla **opt-in**, desactivada por defecto, en [PR #573](https://github.com/edwinrodri12/Tarvoka/pull/573), con 32 contratos y SaveCodec verificados.

La apertura oficial de **tres órdenes** sigue siendo el control. Por mapa, el primer jugador ganó 0/16 en Campo abierto, 8/16 en Bosque de las Dos Rutas, 8/16 en Puentes de la Cuenca y 6/16 en Costa de las Dos Bahías. Este patrón aconseja estudiar la geometría de los objetivos antes de cambiar reglas o precios.

## Inspección de implementación actual

El juego usa `scripts/core/RelayControl.gd`:
- Las unidades terrestres vivas capturan el relé **al terminar el turno** de su facción si ocupan la casilla.
- Con `fair_round=true` y `round_scoring=true`, los puntos de relé se depositan **solo cuando ambos bandos han completado turno**: después de una ronda completa, ambos obtienen 1 punto por cada relé poseído.
- La victoria por señal sucede cuando al terminar una ronda completa una facción supera el objetivo y tiene más puntos; si ambas empatan, se continúa.
- El modo clásico sin `fair_round` mantiene la forma antigua, y **este ensayo no cambia ese comportamiento**.

## Comparación nueva: 320 partidas reales

**64 combinaciones de entorno × 5 variantes = 320 partidas completas** en Godot 4.3:

- Mapas prototipo 0/1/2/3, niebla sí/no, niveles de IA 10/12, bandos alternos como primer jugador y v3.5 contra sí misma / v3.6.3 contra sí misma.
- **Todas las variantes usan tres órdenes de apertura**, mismo ejército, ciudad, economía, clima, suministros, reglas de combate, IA y puntuación al final de la ronda.
- Los relés están sobre casillas transitables y geométricamente reflejadas en columnas 4 y 5.
- Solo las variantes "equal" incluyen el nuevo argumento **opt-in** `symmetric_first_income=true`, conservando las dos ciudades y todos los ingresos posteriores; el control "legacy" conserva el juego actual.

| Variante | Relés | Objetivo de puntos | Ingreso inicial del segundo |
|---|---|---:|---|
| `south_legacy` | (4,5), (5,5) | 5 | Sí, +100 |
| `south_equal` | (4,5), (5,5) | 5 | No |
| `north_equal` | (4,2), (5,2) | 5 | No |
| `four_equal` | (4,2), (5,2), (4,5), (5,5) | 5 | No |
| `four_target8_equal` | Las cuatro posiciones anteriores | 8 | No |

Así se controla por separado la economía, la ubicación de los relés, el número de relés y el objetivo de puntos, sin variar el límite de apertura ni la IA en cada comparación.

## Telemetría que exige esta investigación

`tests/test_ai_relay_geometry_v372.gd` ejecuta los combates por medio de `BattleSession` y `BasicAI.step`, y registra:
- Primera fase en la que cada facción **captura un relé**; primera fase en la que comienza a **puntuar**.
- Cambios de propiedad, número de objetivos controlados al finalizar, puntos acumulados **por cada ronda completa**, duración de la batalla y causa de victoria.
- Compras, capturas de ciudades, retiradas y bajas, ganador por bando inicial y por color.
- Primeros tres movimientos del control sur con ingreso legacy y del sur con ingreso simétrico, que deben ser idénticos en cada escenario.

`tests/test_relay_fairness_contract_v372.gd` somete al motor real a **80 contratos**: 5 variantes × 4 mapas × niebla sí/no × ambos iniciadores. Valida que el primer fin de turno **no concede puntos**; que la siguiente transición sí concede 1 o 2 según el número de relés; que un empate en el objetivo no termina la partida, que una ventaja suficiente solo la cierra en ronda completa, que los guardados son válidos y que la economía opcional funciona.

`tests/aggregate_ai_relay_geometry_v372.py` rechaza partidas duplicadas, ausentes o fabricadas. Exige las 320 combinaciones, 64 parejas iguales de apertura entre sur original y sur simétrico, y dos referencias históricas de 64 juegos cada una (primero 22, segundo 42, azul 30, rojo 34 para el escenario sur en ambas variantes). Un resultado por mapa o estilo distinto a esas referencias impide usarlo como comparación válida.

La CI está en `.github/workflows/ai-relay-fairness-v372.yml`.

## Decisión tras las pruebas

**No promover de inmediato** la alternativa con más victorias cerca de 50/50: revisar sesgo de color, mapa individual, derrotas por combate, tiempo hasta puntuar y cambios en el funcionamiento estratégico. Si los cuatro relés crean carreras de puntuación demasiado rápidas, el objetivo de ocho puntos permite probar ese efecto por separado.

El ensayo usa dos políticas de IA contra sí mismas sobre mapas de 10×8, por lo que una variante prometedora necesitará pruebas de mapas aleatorios, ejércitos modernos y jugadores humanos antes de considerarse para la versión comercial.

**No modificar `scripts/core/RelayControl.gd`, `main`, guardados ni APK oficial en esta fase. PR DRAFT.**
