# TARVOKA — Auditoría experimental de relés simétricos v3.6.4

**17 noviembre 2026. Esta rama no modifica `main`, las reglas oficiales ni la APK.**

## Diagnóstico medido

[Ensayo de 64 partidas con puntuación clásica de relés igualada por ronda](https://github.com/edwinrodri12/Tarvoka/actions/runs/44197455971):

- En 32 enfrentamientos v3.5 vs v3.6.3, la IA nueva perdió 12–20. El jugador que empezó ganó 8/32.
- En 32 controles espejados (IA contra sí misma), **el bando azul ganó 26/32** y el rojo 6/32, aunque las IA eran idénticas. El primer jugador ganó 10/32.
- El modo de puntuación simétrica evita cobrar puntos antes de una respuesta, pero no garantiza equilibrio de color ni de orden de turno. La geometría de los **dos relés clásicos diagonales** (4,2) y (5,5) no está reflejada horizontalmente, mientras que ejércitos y ciudades sí lo están.

## Hipótesis verificable

La geometría de los relés es un factor confundidor de la aparente ventaja de iniciativa. Para comprobarlo, se mantienen **los dos relés, misma meta de puntos, misma economía, mismas unidades, mapas, niebla, IA, apertura de tres órdenes y puntuación por ronda**. Solo se mueven los nodos en partidas de laboratorio:

- **Norte:** (4,2) y (5,2).
- **Sur:** (4,5) y (5,5).

Cada par es un reflejo exacto respecto del eje central vertical del tablero 10×8 y es transitable tanto en el escenario abierto como en el escenario de puentes. No se añade un tercer relé.

## Validación y métricas

Se ejecutan **64 partidas nuevas de Godot 4.3** (32 norte y 32 sur) con **mismas IA en ambos bandos**: v3.5/v3.5 y v3.6.3/v3.6.3. Hay intercambio de inicio, mapas 0/2, niebla y niveles 10/12. La batería no pretende demostrar superioridad ofensiva de ninguna versión: pretende **aislar la asimetría geométrica**.

- El agregador exige 64 combinaciones únicas y presencia de `balanced_opening`, `fair_round` y exactamente dos relés.
- Informa por separado la diferencia de victorias del primer/segundo jugador, azul/rojo, mapa y versión de IA. Distingue empates/inconclusas y victoria por relés o eliminación.
- Compara los resultados nuevos con el control previo de **26 victorias azules y 10 del primer jugador entre 32 partidas**, sin sumar ambos conjuntos.
- Un contrato de Godot valida las ocho combinaciones mapa/apertura/distribución: mapa transitable, relés reflejados, misma economía/ejércitos y compatibilidad de guardado.

**Criterios indicativos, no autorización de fusión:** menor desviación azul/rojo y primero/segundo frente al diseño diagonal, ninguna partida inconclusa, pruebas técnicas correctas. Una muestra de 32 por geometría no basta para aprobar el balance definitivo.

Si ninguno de los dos diseños se comporta bien, la siguiente hipótesis es el orden real de captura de objetivos o el modo en que la IA los prioriza. No se ajusta el poder de las facciones ni se conceden bonos artificiales.

PR experimental; no fusionar con el juego ni producir APK basado en este ensayo.
