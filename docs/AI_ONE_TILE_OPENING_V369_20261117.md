# TARVOKA — Prioridad v3.6.9: cuarta orden reducida a una casilla

**17 noviembre 2026 (hora de Atlanta).** Este documento describe únicamente un experimento. Ninguna regla oficial, APK, partida guardada o rama `main` se ha cambiado.

## Evidencia directa

La [auditoría v3.6.8 con 128 partidas de Godot 4.3](https://github.com/edwinrodri12/Tarvoka/actions/runs/44221500225) aprobó los diez trabajos de CI y constató que:

| Regla experimental | Gana primero (32) | Gana segundo | Azul / Rojo |
|---|---:|---:|---:|
| 3 órdenes oficiales | 8 | 24 | 16 / 16 |
| 4 órdenes completas | 24 | 8 | 20 / 12 |
| 4ª sin ocupar relés/ciudades/fábricas | 24 | 8 | 20 / 12 |
| 4ª defensiva sin aproximarse a relé | 8 | 24 | 16 / 16 |

La cuarta decisión natural de `BasicAI.step` fue **mover la unidad E desde (1,5) hasta (3,5)**, o simétricamente la V desde (8,5) a (6,5), en todos los 32 entornos. Los movimientos se dirigían hacia relés centrales, pero no terminaban sobre ellos. El filtro de no ocupar objetivos los autorizó todos y el filtro de no acercarse los rechazó todos. Ninguno mejoró la distribución de victorias.

## Hipótesis que se comprueba

La cuarta orden puede ayudar al primer jugador sin otorgarle **dos casillas enteras de avance**. La prueba reduce únicamente su destino, sin reducir el número de órdenes ni alterar el movimiento oficial.

Los tratamientos nuevos son:

- **`3`:** apertura original, `OpeningBalance` autoritativo con tres órdenes.
- **`4`:** cuatro órdenes normales en la rama de investigación, usando el estado legacy sin campo `opening`.
- **`3plus_step`:** si la cuarta acción natural de la IA es un movimiento con destino a **dos o más casillas Manhattan**, elegir solo **una casilla ortogonal** hacia ese destino, preferentemente X cuando hay empate; ejecutar esa orden con `BattleSession.move(state, unit_id, shortened_cell)`.

Es importante distinguir el objetivo original de la orden que realmente se realiza: el estado simulado del movimiento completo de la IA **se descarta**, y `Session.move` valida de nuevo la celda acortada. Si la unidad ya quería avanzar solo una casilla o si el motor rechaza esa celda por obstáculo, coste, ocupación, niebla, clima, suministros u otra regla, **no se ejecuta una cuarta orden**; el programa termina la fase. No se buscan alternativas y no se consulta información de enemigos ocultos.

## Comparación y aceptación

**96 partidas reales, 32 por variante**: los mapas 0 (Campo abierto) y 2 (Puentes de la Cuenca), niebla sí/no, IA nivel 10 y 12, primer jugador azul/rojo, tanto v3.5 vs sí misma como v3.6.3 vs sí misma. Las tres variantes mantienen idénticos mapas, unidades, IA, economía, relés reflejados al sur en (4,5)/(5,5) y puntuación tras la ronda completa.

Pruebas:

- `tests/LimitedFourthStepV369.gd`: selección determinista y pura respecto al estado fuente, solo en investigación; el movimiento reducido pasa por el motor real.
- `tests/test_ai_one_step_opening_v369.gd`: 96 combates, telemetría del ID de unidad, destino original y reducido, distancia inicial y aplicada, motivos de rechazo y secuencia idéntica de las primeras tres decisiones.
- `tests/test_ai_one_step_contract_v369.gd`: ocho entornos en Godot que cruzan dos mapas, niebla activada/desactivada y ambos primeros jugadores; verifican movimientos reales, un paso legal, guardados sin modificaciones y que la apertura de producción aún rechaza la cuarta acción.
- `tests/aggregate_ai_one_step_v369.py`: exige exactamente 96 combates distintos y **96 comparaciones de secuencias iniciales**; valida reproducibilidad de las dos referencias históricas: 3 órdenes, primer bando 8/32 y azul 16/32; 4 órdenes, primer bando 24/32 y azul 20/32. El informe contiene la diferencia de victorias por iniciativa, por color, por mapa, por política, y la fracción de movimientos reducidos realmente ejecutados.

El informe permitirá descartar una regla si no se usa, no es legal o genera el mismo desequilibrio. Un resultado prometedor todavía requeriría **pruebas de más mapas, facciones, niebla, jugadores humanos y Android**, además de una implementación opt-in compatible con guardados.

**Estado:** el diseño no queda aprobado automáticamente por una prueba técnica. PR en borrador; no fusionar ni modificar APK, `main` o mecánicas oficiales.
