# TARVOKA v3.9.6 — Verificar qué hace realmente el Piercer producido en la cuarta orden

## Evidencia de partida

- [v3.9.4, 9/9 CI](https://github.com/edwinrodri12/Tarvoka/actions/runs/44425512681): doble puente sin niebla, 16 condiciones originales por política, 0/16 gana el iniciador con apertura oficial de 8 órdenes en primera respuesta, 0/16 con la respuesta detenida tras 5 órdenes, 14/16 con respuesta detenida tras 3.
- Los registros autoritativos de v3.9.4 identifican EXACTAMENTE la **cuarta orden** del respondedor en las 16 condiciones: fabricar un **Piercer** `N3`, por **300 créditos** en fábrica base (0,4) o (39,4). La **quinta orden** es un avance de la unidad `C` / `Z` hacia el puente superior.
- [v3.9.5, CI](https://github.com/edwinrodri12/Tarvoka/actions/runs/44428593629): compare la respuesta de 4 órdenes con las de 3, 5 y 8 para distinguir producción y movimiento. En los primeros tres shards aprobados (semillas 634,650,658; ambos iniciadores), el **cap4 también gana el respondedor (6/6)**, aun cuando el iniciador captura primero un relé. Cap4 tarda 18 medios turnos en las semillas 634 y 658, y 14 en la 650, frente a 12 en la política oficial y cap5. **No generalizar hasta terminar los restantes cinco shards y agregador.**

La hipótesis emergente es que la cuarta orden (producir Piercer) podría habilitar una recuperación posterior del respondedor. No se debe dar por hecho que ese Piercer ataca: la producción también altera dinero, población, bloqueo físico y las decisiones de la IA en rondas siguientes.

## Contraste focal v3.9.6

Se prueban **tres semillas representativas** de las partidas ya observadas, siempre en mapa doble puente 40×30 **sin niebla**:

- **634:** bajo cap3 gana el primero y bajo cap4 gana el respondedor; cap4 puede durar 18 medios turnos.
- **658:** otra variante con el mismo cambio de ganador.
- **650:** excepción donde incluso cap3 no consigue la victoria del iniciador; bajo cap4 dura 14 medios turnos.

En cada semilla, ambos colores como iniciadores. Para cada inicio se ejecuta cap3/cap4 con todas las reglas reales posteriores, cada uno con reflejo horizontal exacto: **6 condiciones originales por política; 24 partidas reales** contando validación reflejada (no son muestras nuevas independientes).

Se comprueba que:
1. Los tres primeros movimientos del primer jugador y los tres primeros del respondedor coinciden exactamente; la única orden nueva de la primera respuesta es fabricar Piercer `N3` en la posición real, por 300.
2. `N3` se sigue en los estados completos: aparición, posición, salud, movimientos posteriores, ataques, supervivencia y si llegó a desaparecer.
3. Se compara primer relé capturado, resultado, duración, marcadores y capturas entre cap3 y cap4. Aunque el iniciador conserve la primera captura de relé bajo ambas políticas, la unidad adicional puede modificar el desenlace.
4. Se repiten todos los estados y decisiones frente al reflejo, con la economía, IA, combate, movimiento y puntuación reales; una censura se registra como tal y jamás se llama empate.

**Limitación:** observar que un Piercer se movió, atacó o sobrevivió no identifica por sí solo cuál de sus efectos es causal. Este test establece una cronología inspectable para elegir la siguiente intervención de manera fundamentada. No modifica la producción ni su precio.

## Riesgos controlados

El estudio NO cambia ningún archivo productivo, no impone cap3/cap4, no cambia la IA predeterminada, no ajusta daños, costos o ingresos, no modifica mapas, no fusiona a `main` ni publica una APK. Se mantiene como PR DRAFT apilado sobre v3.9.5.
