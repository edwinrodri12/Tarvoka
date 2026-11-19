# TARVOKA v4.0.2 — Forense de la apertura: qué pierde la IA al iniciar

**19 de noviembre de 2026. Investigación diagnóstica, NO nueva IA predeterminada.**

## Resultados anteriores: YA VALIDADOS

- [PR #619 v4.0.0 / run 44470015304](https://github.com/edwinrodri12/Tarvoka/actions/runs/44470015304): **18/18 SUCCESS**. En autopartidas simétricas sobre 32 condiciones originales: IA oficial 14 primero/18 segundo, forecast v398 12/20, IA económica v400 16/16. Aunque el reparto 16/16 parece balanceado, **autopartidas no muestran quién es mejor**. V400 conservó compras cerca de la IA oficial (822 frente a 826) y redujo el daño causado por perseguir relés como v398.
- [PR #621 v4.0.1 / run 44471224226](https://github.com/edwinrodri12/Tarvoka/actions/runs/44471224226): **18/18 SUCCESS**, enfrentamientos *de verdad* con v400 controlando una facción y la IA oficial la otra. **64 condiciones originales**, ambas facciones como iniciadoras y como candidatas, niebla ON/OFF y cuatro tipos de mapa. IA v400 **28 victorias**, oficial **36**, 0 censuras. **V400 comenzando: 8/32**, respondiendo **20/32**. Niebla OFF 12/32, niebla ON 16/32. Costa y bosque 6/16 cada uno, abierto y doble puente 8/16 cada uno. Puntuación de relés 256 vs 286 y margen de señal −30.

**Decisión:** v400 no mejora fuerza total ni robustez cuando inicia. Mantener flag `_ab_economic_arbitration_v400` **OFF**, PR DRAFT; no activar ni modificar reglas.

## Pregunta concreta de la siguiente prioridad

¿La vulnerabilidad del jugador inicial con IA v400 se origina **en sus tres órdenes legales de apertura**, o **después de la respuesta del enemigo**, cuando se acumulan más compras, movimientos, ciudades e ingresos?

No queremos introducir otra táctica no justificada; primero necesitamos observar el estado verdadero tras cada turno y distinguir la *oportunidad económica perdida* de un simple desfase de capturas.

## Diseño de v4.0.2

Se crea un **analizador de decisiones de apertura**, con el mismo Godot 4.3, el mismo algoritmo, las mismas reglas y la misma distribución de lados que las pruebas exitosas v401.

- Semillas **nuevas 698–705**, dos por plantilla (abierto, bosque, doble puente y costa), ambas nieblas.
- Con `first=0` y `first=1`.
- Alterna qué facción controla **v400**; la otra usa la **IA oficial**.
- Observa hasta **8 medios turnos** (cuatro rondas de dos bandos), no 36. El objetivo aquí es **auditar la apertura, no determinar victorias**.
- **64 partidas originales**; cada una se ejecuta además sobre el espejo horizontal, con intercambio correcto de la política de facciones, **128 ejecuciones**. Los espejos comprueban paridad estricta, **no duplican las muestras**.
- Para cada semilla/niebla/iniciador se comparan dos partidas con estado inicial idéntico pero asignaciones distintas de política: **32 comparaciones de las primeras tres órdenes y de la primera respuesta**. No son enfrentamientos con una IA omnisciente.

### Telemetría reproducible

Por fase y bando:

- Cada una de las **3 acciones iniciales legales** (tipo, unidad, rol, destino, gasto), y la secuencia completa de la primera respuesta del segundo jugador.
- Movimientos, ataques, compras y reabastecimientos; créditos consumidos al producir y saldo al cerrar el turno.
- Ciudades de propiedad actual, cambio de propiedad durante el turno y **tasa actual de ingresos por ciudades**. La tasa futura se informa como diagnóstico y **no se abona ni se regala**.
- Relés ocupados, señales acumuladas, diferencia de propiedad, unidades supervivientes y capacidad de producir.
- Estados al terminar dos rondas y cuatro rondas, comparables por IA que inicia o responde, con y sin niebla.

La telemetría la recoge **el auditor externo al terminar la partida**, nunca la IA que decide. Por ello puede conocer las dos tesorerías para comparar el resultado, aunque la **IA sigue viendo únicamente su estado autorizado y enemigos visibles**.

### Contratos de integridad

1. El helper `Study._play` heredado de v401 permite elegir IA por facción, sin modificar ninguna regla productiva.
2. El primero ejecuta **exactamente tres órdenes iniciales**. No se permite cambiar el límite, regalar unidades, alterar costos ni capturar relés sin la regla de terminar turno.
3. Cada historia de decisiones y estado es **idéntica a su reflexión con colores y políticas intercambiadas**. Diferencias detectadas invalidan la prueba.
4. Se valida que las cuatro categorías de acciones sumen el total real de órdenes por fase, y que ingresos de ciudades sean tasas calculadas desde `UrbanEconomy.income_for`, no estimaciones inventadas.
5. El agregado exige **exactamente 64 condiciones** no duplicadas (8 semillas × 2 nieblas × 2 iniciadores × 2 asignaciones). Separa 32 pares útiles para estudiar primeras decisiones.
6. El resultado final no se expresa como una tasa de victorias nueva: **8 medios turnos son una observación deliberadamente incompleta**, y el resultado real de 36 fases ya está en v401.

## Uso de la evidencia

- Si las primeras tres órdenes de v400 son frecuentemente distintas de la IA oficial y la partida queda con menos ciudades, créditos o tropas, investigar prioritariamente el **costo de esas órdenes** y el orden de compra/movimiento.
- Si ambas IA abren igual pero empiezan a divergir después de la respuesta rival, estudiar la **adaptación al segundo turno y la respuesta a presión territorial**, no imponer bonos al primer jugador.
- Si el sesgo persiste sin correlación con decisiones iniciales, investigar el **presupuesto estructural del primer turno** por separado, con pruebas de reglas y IA controladas, sin cambiar lo aprobado anticipadamente.

Ninguna conclusión individual se tomará de una única semilla ni de los reflejos como si fueran observaciones independientes.

## Estado de cambios

**Solo tests, agregador, workflow y documentación**, en una PR DRAFT apilada sobre [#621](https://github.com/edwinrodri12/Tarvoka/pull/621), que ya pasó CI. No hay cambios a `scripts/core`, APK, `main`, daño, salarios, puntuación, niebla, reglas de producción o facciones. Todos los flags v398/v399/v400 permanecen apagados en el juego oficial.
