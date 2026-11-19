# TARVOKA v4.0.1 — Prueba directa de fuerza: IA experimental vs IA oficial

**19 de noviembre de 2026. Protocolo de investigación: sin bonos de dinero, daño, turnos, visibilidad ni unidades. NO es lanzamiento comercial.**

## Por qué hace falta

La IA nueva v4.0.0 compara una carrera por relé con la oportunidad de tomar ciudades que producen ingresos futuros o fabricar refuerzos reales. Su [PR #619](https://github.com/edwinrodri12/Tarvoka/pull/619) contiene un holdout de autopartidas de **tres políticas**: IA oficial contra sí misma, forecast v3.9.8 contra sí misma y árbitro económico v4.0.0 contra sí mismo. Esto mide **sesgo de iniciativa**, capturas y compras, pero **NO demuestra fuerza relativa entre estrategias**.

La v3.9.8 pasó sus [18/18 pruebas](https://github.com/edwinrodri12/Tarvoka/actions/runs/44450643355) y, pese a tomar primero relés más a menudo, cambió el sesgo de 10→8/32 victorias del iniciador (empeoró sin niebla). La v3.9.9 pasó [10/10](https://github.com/edwinrodri12/Tarvoka/actions/runs/44455781949), pero cambió decisiones en solo 4/16 y ganadores en 0/16. No activamos ninguna. La v4.0.0 tampoco debe activarse hasta comprobar su rendimiento frente a un rival diferente.

## Qué hace este experimento v4.0.1

**Por primera vez se enfrenta la IA económica experimental contra la IA oficial dentro de la MISMA partida.** Se usa únicamente la arquitectura actual de Godot 4.3/GDScript en modo de pruebas. No se modifican reglas comerciales, el algoritmo de combate, el motor de ingresos, el sistema de turnos ni el código de Android.

El harness existente `tests/test_ai_initiative_counterfactual_v379.gd::_play` recibe un parámetro FINAL nuevo y opcional, `_research_options_by_faction_v401: Dictionary={}`, que por defecto está vacío. Sin él, la lógica original ejecuta EXACTAMENTE el mismo `AI.step` de siempre. Cuando se usa, selecciona las opciones por `str(side)` del lado cuyo turno se juega, mediante una copia de la configuración anterior y un `merge` de la opción opt-in del candidato. **No modifica nunca el estado real de una partida**. No permite jugar dos órdenes adicionales, gastar dinero enemigo o utilizar información no visible.

Se contrasta la única opción `_ab_economic_arbitration_v400=true` de v4.0.0, habilitada **solo para una de las dos facciones**. La otra siempre usa la IA oficial con su configuración base.

**Fidelidad de simetría:** cada partida se repite sobre su reflejo horizontal con cambio de colores (facción0↔1). La política v400 se asigna **a la facción reflejada**, no se deja arbitrariamente en la facción0, y se exigen igualdad exacta de todos los fotogramas, acciones normalizadas, estados, ganador reflejado y resultado terminal. Esto detecta ventajas ocultas y comparaciones injustas.

## Matriz de partidas

- Ocho semillas **inéditas 690–697**: dos de cada terreno (abierto, bosque, doble puente y costa).
- Con niebla ON/OFF.
- Ambos iniciadores reales, `first=0` y `first=1`.
- IA candidata controlando alternativamente facción0 y facción1.

Total: 8 semillas × 2 nieblas × 2 primeras facciones × 2 asignaciones de IA candidata = **64 partidas originales y genuinamente enfrentadas**. Cada una tiene espejo exacto, para **128 sesiones reales**. **Los espejos no son 64 nuevas observaciones independientes**, y los cuatro casos de una misma semilla están correlacionados.

La apertura mantiene **tres órdenes oficiales para el iniciador**. Los ingresos iniciales son simétricos, el tablero 40×30 y la duración observada máximo 36 medios turnos. Si no aparece vencedor en ese horizonte, la partida queda **censurada**, nunca declarada empatada ni adjudicada al segundo.

## Qué se medirá

- **Victorias de la IA v400 contra la IA oficial**, contando derrotas y partidas censuradas sin inflar denominadores.
- Victórias y marcador según la IA candidata juegue **primero o segundo** (32 partidas originales en cada posición).
- Desgloses por niebla (32/32), plantilla de mapa (16 por tipo), facción inicial (32/32) y semilla.
- Puntos de relé finales de cada IA, margen agregado, duración media, cantidad de ataques y compras realizadas legalmente.
- Verificación de igualdad total de cada partida reflejada, correspondencia de política de facción y apertura oficial.

**Lectura de resultados:** victoria global favorable a v400 no basta si obtiene éxitos únicamente cuando responde segundo; hay que comprobar si gana con ambos órdenes, niebla y mapas. Tampoco podemos concluir invencibilidad de una IA a partir de 64 casos emparejados. El objetivo es discernir si la mejora aprovecha mejor la economía, no fabricar una ventaja artificial para el juego comercial.

## Validación automática

Workflow `ai-opportunity-head-to-head-v401.yml`:

1. Microtest que compara el harness original frente al mismo harness con opciones por facción VACÍAS: las acciones, estados, ganador y estadísticas deben ser idénticos. Después prueba asignaciones de candidato y su correspondiente swap en espejo.
2. **16 shards** de GitHub Actions (8 semillas ×2 nieblas). Cada shard ejecuta dos iniciadores y dos asignaciones de IA candidata, y sus espejos (8 sesiones por shard). Una salida `HEAD401_RESULT` por cada partida original.
3. Agregador Python que exige **exactamente las 64 combinaciones**, cero repeticiones, 3 órdenes iniciales, identidad exacta de configuración y que los resultados no reclasifiquen censuras como victorias. Emite JSON y Markdown con los desgloses.

**Condición de aprobación para activar un cambio de IA**: deben aprobarse por completo el CI del padre v400 y el CI de este PR y haber una mejora sustantiva y equilibrada frente al rival oficial, además de integridad de niebla, fondos y otros estilos de mapa. Hasta ese momento, **todos los flags experimentales permanecen OFF**; no merge, no APK.

## Archivos

El cambio altera **únicamente pruebas, configuración de CI y documentación**. No introduce un solo cambio nuevo en `scripts/core` sobre los de v400. Este PR DRAFT se apila exclusivamente sobre [#619](https://github.com/edwinrodri12/Tarvoka/pull/619); no depende de v399. `main`, lanzamiento de Android y reglas de producción intactos.
