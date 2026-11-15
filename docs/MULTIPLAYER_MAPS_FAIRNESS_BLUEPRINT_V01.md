# TARVOKA — Catálogo masivo de mapas y equidad 2–8 jugadores (prototipo v0.1)

**Fecha:** 2026-11-15. **Estado:** diseño y pruebas puras de geometría; no es multijugador 4–8 implementado. No sustituye `Scenarios.seeded_terrain`, no altera archivos de guardado, parámetros de facciones, generador Android ni el motor que sigue limitado a dos jugadores.

## Objetivo de producto

El mapa debe crear **decisiones diferentes** en cada partida, no solo una textura distinta. Queremos gran variedad de geometrías, biomas, elevaciones, relieve, ciudades, bases y rutas, con compatibilidad prevista para **2, 4, 6 y 8 participantes** (FFA, 2v2, 3v3, 4v4 y equipos asimétricos cuando las reglas los admitan). La jugabilidad de ocho personas exige motor, economía, niebla, diplomacia/equipos, IA, online/local, guardado y tiempos de turno multibando; una distribución de ocho puntos de inicio NO equivale a esas funciones.

## Qué se añadió realmente

`scripts/core/MapBlueprintLab.gd` es un prototipador **no conectado a las partidas**. Produce un borrador determinista por (jugadores, arquetipo, semilla, tamaño), con:
- Terreno Godot legal para 24×18 (2 y 4 puntos de inicio) y 40×30 (2, 4, 6 y 8 puntos).
- Posiciones explícitas de inicio, una ciudad inicial por plaza, una ciudad neutral de proximidad y un objetivo por plaza, sin ocupar la misma casilla.
- Ocho familias estructurales: **frentes abiertos**, **doble cordillera**, **río y puentes**, **lagunas interiores**, **laberinto forestal**, **costa**, **corredores urbanos** y **cuenca de altura**.
- Semillas repetibles: no se crean mapas idénticos con el mismo ID por accidente. Estos son borradores combinables; no hay promesa de miles de mapas jugables o validados.
- Auditoría de costos reales de desplazamiento terrestre hasta la ciudad propia, ciudad neutral, objetivo y enemigo próximo, accesibilidad global y distribución de llanura, bosque, caminos, montaña y agua.

`tests/test_multiplayer_map_blueprints.gd`: matriz inicial de **64 geometrías** = 4 números de participantes × 8 arquetipos × 2 semillas. El script registra `MAP_BLUEPRINT_SAMPLE` y `MAP_BLUEPRINT_SUMMARY` para revisar resultados de GitHub Actions. Los experimentos no inician partidas multibando; no alteran el juego actual.

## Modelo de calidad: equidad + diversión

**Equidad NO es solo simetría gráfica ni 50/50 calculado en una muestra pequeña.** Mediremos seis capas:

| Capa | Variables/telemetría necesaria | Riesgo a impedir |
|---|---|---|
| Geografía | Distancia/costo al objetivo y ciudad neutral, múltiples rutas, accesibilidad, puentes críticos, ventajas de altura | Un bando gana su ciudad/posición clave gratis |
| Economía | Ingresos iniciales por participante/equipo, tiempo hasta primeras compras, bases productivas y reabastecimiento, capacidad de remontada | Bola de nieve con ventaja urbana irreversible |
| Combate | Alcances desde spawn, cobertura, posibilidad de ataque en turno uno, contramedidas y artillería | El primer jugador elimina la respuesta enemiga antes de actuar |
| Clima y dominios | Velocidad por ruedas/orugas/infantería, paso terrestre, navegación, bases aéreas y marinas, tormenta/nieve | Mapas que invalidan clases enteras sin advertir |
| Comandantes y facciones | Identidades v0.1 cuando estén activas, sinergias contra composición/mapa, poderes y recarga | Una sola combinación gana siempre en un bioma |
| Experiencia multijugador | Tiempo por turno, eliminación temprana, bloqueos, alianzas/equipos, número de decisiones, desconexiones y duración | Jugadores esperan demasiado o quedan fuera durante gran parte de la partida |

**Guardrails (hipótesis para playtests, no promesas automáticas):**
- Ninguna base debe quedar aislada de todos los recursos/objetivos de su dominio.
- Igual cantidad de ciudades iniciales y categorías productivas por jugador/equipo cuando el modo sea simétrico.
- Distancia al objetivo más cercano y a primera ciudad neutral similar por bando en competitivas; alertar si la diferencia excede **3 puntos de movimiento terrestre** para ciudad o **5 puntos** para objetivo. No convertir la alerta automáticamente en 'no publicable': clima, movimiento de motor, visibilidad y producción pueden modificarla.
- Detectar si un rival aparece al alcance de ataque indirecto sin tiempo de respuesta.
- Cada mapa debe permitir más de una ruta ofensiva/defensiva útil, y medir posiciones que puedan bloquear una partida entera.
- En mapas de ocho, revisar economía y producción según `jugadores activos`, que no dependa del orden del array o color, y victoria por equipos o último superviviente. El límite de **3 órdenes iniciales** no puede asumirse adecuado para todas las escalas.
- Medir duración **en rondas completas y en tiempo real**, con umbrales distintos para partida rápida, estándar y épica. Evitar turnos individuales de duración excesiva cuando haya 8.
- A/B con todos los iniciadores, rotación de posiciones y facciones, niebla, meteorología, composición inicial, modo de victoria y estilos IA; después playtests humanos.

## Limitaciones técnicas detectadas en el motor actual

- `BattleSession.gd`, `Turns`, `UrbanEconomy.gd`, `RelayControl.gd`, `Visibility.gd` y `SaveCodec.gd` están diseñados con bandos **0 y 1**, no soportan una tercera facción real.
- `UrbanEconomy.MAX_SITES=16`: una maqueta de 8 participantes con 8 ciudades propias + 8 neutrales ya usa 16 **antes de bases**, por lo que **NO** cabe en la economía actual.
- `Rules.supported_size` solo acepta 10×8, 24×18 y 40×30. La expansión a mapas mayores debe acompañarse de benchmarks de memoria, pathfinding, render, IA y batería en Android.
- Ocho retratos/facciones disponibles son **opciones visuales de dos bandos**; no constituyen online o un motor de 8.
- El generador de semillas actual está ligado a partidas guardadas v1; **no alterar el resultado de una semilla antigua**. Nuevas geometrías requieren versión propia y metadatos de colocación de instalaciones.

## Siguiente ruta de implementación

1. **Diseño/telemetría sin romper el juego:** validar 64 borradores, guardar métricas y estudiar advertencias. Expandir variedad de topologías manteniendo rutas legales.
2. **Contrato de mapa versionado:** separar terrain, `slots`, economía, instalaciones, puertos, bases aéreas, objetivos y equipos, con IDs estables y un validador propio. Cada inicio recibe acceso económico comparable en mapas competitivos.
3. **Unificar datos de facción 2–8:** eliminar dependencias fijas de 0/1 en turnos, visibilidad, IA, economía, scoring, selección, guardados y pruebas, bajo feature flag aislada; primero 4 participantes offline, luego 6 y 8.
4. **Batería de simulaciones multibando:** comparar 2/4/6/8 con varios niveles de tamaño de mapa, jugadores/IA mixtos, activos/equipos, poder de comandante habilitado solo cuando exista. Medir resultados por asiento, no solo tasa agregada.
5. **Interfaz y Android:** mapa general, minimapa, pantalla de facciones/turnos, avisos, rendimiento real y largos turnos; modo online posterior con reanudación y desconexiones.

**Política:** no integrar un mapa competitivo si la ruta a ciudades, la producción, la visibilidad o la regla de victoria no son verificables; no prometer una partida de ocho jugadores hasta que motor + UI + guardados + IA + tests humanos demuestren que es real.
