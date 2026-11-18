# TARVOKA — v3.6.8: cuarta orden de despliegue defensivo (solo experimento)

**Fecha local de investigación: 17 noviembre 2026.** Rama aislada, sin cambiar `main`, APK, balance oficial, guardados ni `OpeningBalance.gd`.

## Evidencia que origina el trabajo

La [última ejecución de v3.6.7](https://github.com/edwinrodri12/Tarvoka/actions/runs/44218832260) terminó con **10/10 trabajos correctos**, 128 partidas reales, 128 comparaciones distintas de sus primeras tres órdenes y repetición de las referencias anteriores:

| Primer turno | Gana primero | Gana segundo | Azul | Rojo |
|---|---:|---:|---:|---:|
| 3 órdenes normales | 8/32 | 24/32 | 16 | 16 |
| 4 órdenes normales | 24/32 | 8/32 | 20 | 12 |
| 3 + cuarto movimiento | 24/32 | 8/32 | 20 | 12 |
| 3 + cuarta acción de apoyo | 24/32 | 8/32 | 20 | 12 |

En cada partida de referencia la cuarta recomendación natural de `BasicAI.step` era un `move`; ambos filtros no ofensivos concedieron **32/32** acciones, por lo que no mejoraron el resultado. El tipo de acción *no* es un criterio selectivo suficiente en esta muestra.

## Hipótesis: la casilla de destino importa

Mantener 3 órdenes legales con la regla existente. Permitir un cuarto movimiento en un laboratorio de Godot *solo si la IA ya lo recomienda*, con dos variantes objetivas:

- **`3plus_no_objective`**: la unidad **no termina** la cuarta orden en un relé o en ninguna casilla de la economía (ciudad, instalación o fábrica). Se rechaza tanto si está ocupado como si aún está neutral o bajo control propio. No se cambia la acción ni se busca otra alternativa.
- **`3plus_defensive`**: además de lo anterior, la unidad permanece en la **mitad propia del mapa** y su distancia Manhattan al relé más cercano **no disminuye**. Esta es una definición experimental de despliegue defensivo, no un nuevo poder del juego.

Controles obligatorios: **`3`** (tres acciones oficiales) y **`4`** (cuatro acciones legales en el motor legado sin límite, pero el bucle de prueba se detiene al cumplir cuatro). Ambas usan acciones auténticas del motor `BattleSession` y sus resultados, sin introducir un `opening.limit=4` que sería inválido.

La decisión sobre la cuarta orden consulta **solo las posiciones públicas de las ciudades, bases y relés, y la ubicación de la unidad propia**. No inspecciona enemigos no visibles bajo niebla. Los nodos de relé están fijados al sur en (4,5) y (5,5), con puntuación por ronda completa; todas las variantes comparten exactamente el mismo mapa, niebla, facciones, recursos, IA y suministros.

## Instrumentación

- `tests/FourthDeploymentPolicyV368.gd`: política determinista y pura para aceptar o rechazar un movimiento propuesto. No la importa el código del juego.
- `tests/test_ai_objective_aware_opening_v368.gd`: **128 partidas reales** de Godot 4.3, 32 por variante, dos mapas, niveles 10/12, niebla sí/no, ambos iniciadores y dos políticas iguales en cada lado.
- Guarda para la cuarta propuesta el ID de la unidad, origen, destino, motivo, casilla de ciudad/fábrica/relé, la mitad del tablero, variación de distancia al relé, y **motivo de rechazo** incluso cuando la acción no se permite.
- `tests/test_ai_objective_deployment_contract_v368.gd`: comprueba ambos bandos, bloqueo de objetivos, desplazamientos defensivos permitidos, guardados intactos y que el motor original deniega una cuarta orden oficial.
- `tests/aggregate_ai_objective_deployment_v368.py`: exige **128 combinaciones únicas**, 128 comprobaciones de equivalencia de las primeras 3 decisiones y reproducción exacta de controles de 3 órdenes (8 victorias del primero, 16 azul) y 4 órdenes (24 victorias del primero, 20 azul). Reporta desgloses por mapa, política, destino, tipo de victoria, color e iniciativa.

## Límites y decisión futura

Un movimiento que no ocupa una ciudad o relé **puede influir en capturas posteriores o en ataques**, por lo que «defensivo» es solo una clasificación experimental. No es seguro asumir que negar el acceso inmediato a relés y ciudades asegure balance. Tampoco es representativo de todos los mapas, partidas humanas, unidades navales/aéreas o rendimiento Android.

**No se aprueba fusión ni APK.** Si el criterio se aplica demasiado poco (o demasiado), se inspeccionarán los destinos y razones de la IA y se investigará una variante más fina antes de tocar reglas jugables.
