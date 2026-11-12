# TARVOKA — Iniciativa justa y terreno táctico (v0.1 experimental)

**Fecha:** 12 de noviembre de 2026. **Estado:** reglas en rama experimental, sujetas a pruebas automatizadas de Godot 4.3, Android ARM64, simulaciones emparejadas y validación humana. La dirección original toma ideas generales de estrategia por turnos (coberturas, posiciones defensivas y terreno elevado) sin copiar fórmulas, sprites, mapas ni interfaz de otros juegos.

## 1. Diagnóstico del primer jugador

Las pruebas previas, antes de la modificación, registraron **18 victorias del primer jugador / 24 partidas económicas** y **12 / 12 partidas clásicas simétricas**. La prueba moderna de relés arrojó **8 / 8** victorias del jugador inicial bajo variaciones de créditos, y distintas condiciones de puntuación. Son pruebas automatizadas de dos IA específicas y no un indicador estadístico suficiente de equidad PvP.

**Fallo estructural concreto:** en partidas modernas de relés, una unidad azul podía capturar al concluir su primera fase y sumar **un punto antes** de que la unidad roja capturara al cerrar su propia fase. Incluso si ambas controlaban casillas simétricas al final de la ronda, la ventaja de marcador acumulada por el orden de turnos persistía. El retraso de adjudicación de la victoria hasta el final de dos fases NO eliminaba esa ventaja de puntos.

**Nuevo reloj emparejado (implementado, partidas modernas nuevas):**

- Cada bando sigue moviendo, capturando, comprando, atacando y usando su turno con las reglas normales. Ninguno recibe un sueldo, puntos de vida, ataque o defensa ocultos por ser segundo.
- Los relés se capturan **al terminar el turno de la unidad ocupante**, como antes.
- El marcador de **ambos** bandos solo aumenta **una vez al terminar las dos fases de una misma ronda**, utilizando las instalaciones poseídas en ese instante. Las ocupaciones simétricas de una ronda dan exactamente la misma cantidad de puntos.
- La victoria por señal sigue adjudicándose solo después de una ronda completa; empate en el umbral ⇒ se sigue jugando hasta que haya líder. La aniquilación total sigue terminando el combate inmediatamente.
- El campo optativo `control.round_scoring=true` marca las partidas nuevas con el nuevo reloj. **Guardados anteriores sin el campo conservan el sistema antiguo** para no reinterpretar sus resultados de forma oculta; las partidas clásicas también quedan intactas. Los estados manipulados se rechazan.

**Limitación:** esto corrige una ventaja de *puntuación*, no demuestra por sí solo que la **primera acción o la economía** sean equilibradas. No afirmar 50/50 hasta analizar partidas con facciones, IA, mapas, clima de niebla, composición de tropas y orden inicial cruzados. En competitivo por turnos se recomienda además una serie con posiciones de inicio intercambiadas cuando el modelo no logre aproximarse a paridad.

## 2. Ventajas de terreno — claras, pequeñas y reversibles

Los efectos se resuelven con `TerrainTactics.modifiers(attacker,defender,terrain,economy,units)` desde la **casilla real de cada unidad**. El atacante recibe primero sus modificadores, después se calcula la respuesta desde la posición opuesta. No se almacenan atributos alterados ni se generan bonificaciones en guardados.

| Lugar / posición | Efecto directo | Motivo y contramedida |
|---|---|---|
| Llanura | 0 cobertura y 0 altura | Espacio expuesto, permite maniobra |
| Camino | 0 cobertura y 0 altura; entrar cuesta 1 | Movimiento rápido, poca protección |
| Bosque | **+1 cobertura** contra ataques a unidades terrestres | Abrigo para infantería y vehículos, pero entrar cuesta 2 |
| Montaña | **+2 cobertura** a unidad terrestre, **altura +1** | Fortaleza de altura; entrar cuesta 3 |
| Ciudad | **+1 cobertura adicional** a su ocupante terrestre, incluso neutral | Objetivo táctico valioso; ocupa una casilla |
| Atacar de montaña a terreno más bajo | **+1 ATQ** si ambos son terrestres | Disparo favorable desde altura |
| Atacar desde abajo a una montaña | **-1 ATQ** si ambos son terrestres | Menor eficacia al atacar cuesta arriba |
| Flanqueo por posiciones opuestas | **+1 ATQ** solo para ataque terrestre directo/guiado si otra unidad propia viva está en la casilla opuesta al enemigo | Exige coordinación, puede contrarrestarse evitando el cerco |

- La cobertura del suelo **no se aplica a aeronaves** que vuelen sobre un bosque/montaña/ciudad, ni a buques. Aire ↔ tierra sigue respetando el terreno del defensor **terrestre**, pero no obtiene bonos de altura terrestre.
- La defensa base, los bonos entre roles, la munición, los tipos de blancos y el contrafuego ya existentes siguen calculándose. El daño nunca se vuelve negativo ni supera los HP del objetivo.
- Las bonificaciones de ciudad y bosque/montaña no conceden curación ni captura; no implican inmunidad ante armas terrestres o navales.
- Flanqueo requiere **dos unidades terrestres aliadas en lados exactamente opuestos** de un defensor terrestre; tener un apoyo en diagonal no cuenta. Un lanzacohetes indirecto no obtiene esta mejora.
- Nieblas: el jugador y la IA usan posiciones visibles y terreno conocido. Ninguna bonificación concede acceso a un enemigo oculto; los datos de munición/reacción enemiga permanecen privados.

## 3. Ejemplos reproducibles

- Tanque 14 HP en llanura vs tanque 14 HP en llanura: **6 HP** daño inicial y **3 HP** de respuesta, si hay visibilidad y munición.
- Tanque al pie de montaña atacando tanque encima de montaña: **3 HP iniciales** por la altura contraria y la cobertura, pero el defensor superviviente **responde 4 HP** por su altura a favor. La posición favorable puede hacer peligroso atacar sin apoyo.
- Tanque encima de montaña disparando al mismo tipo abajo: **7 HP iniciales**, respuesta posible **1 HP**. Diferencias por posición, no por facción.
- Tanque golpeando un tanque en bosque o ciudad: **5 HP iniciales** en vez de los 6 de llanura; desde lados opuestos con otro aliado: **7 HP iniciales** en llanura.
- Armas antiaéreas, aeronaves y barcos conservan sus **dominios objetivos permitidos**. Un tanque no puede atacar a un caza porque esté en una montaña.

## 4. Experiencia de usuario e IA

- La ficha de unidad debe explicar la cobertura de su casilla y la ventaja de posición. Antes de confirmar un ataque, la simulación debe mostrar daño real de terreno y un riesgo de respuesta conservador.
- `BattleActions._strike` centraliza el cálculo; las vistas previas `TacticalHints.for_unit` y `BasicAI` lo llaman a través de `BattleActions.public_preview_exchange` con el terreno observado. De este modo no puede haber un daño de vista previa y otro arbitrario al ejecutar la orden.
- El sistema de compra y las ocho facciones permanecen en la versión 0.1 aprobada. No se añaden campos de experiencia, rangos externos ni modificaciones permanentes al arsenal.

## 5. Pruebas de aceptación

- `tests/test_terrain_tactics.gd`: terreno llano, bosque, montaña ascendiendo/descendiendo, ciudades, flanco real y diagonal falsa, armas indirectas, cobertura no aplicable a aeronaves/buques, daño real = vista previa, contraataque y guardado.
- `tests/test_paired_round_scoring.gd`: relojes simétricos para azul/rojo, puntos solo al cerrar dos fases, victoria no prematura, guardados previos sin marcador `round_scoring`, invalidación de marcador corrupto, y ocho pares de escenarios IA con reloj antiguo vs emparejado.
- El resto de la batería de Godot y exportación Android deben continuar verdes; no integrar por una métrica aislada. Revisar también iniciativa económica de 24 encuentros y clásica de 12; **comparar resultados, no prometer que pasará a 50/50 automáticamente.**
