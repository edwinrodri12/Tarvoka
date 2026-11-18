# TARVOKA v3.8.8 — Prueba fuera de muestra de apertura y regresión de logística

**18 noviembre 2026. Rama de investigación, SIN modificación de las reglas o la APK.**

## Evidencia previa: v3.8.3, v3.8.6 y v3.8.7

- [v3.8.6 navegación logística](https://github.com/edwinrodri12/Tarvoka/actions/runs/44360735359): 4/4 regresiones costeras, simetría exacta tras reemplazar el desempate accidental de recorridos por comparación relativa a la facción.
- [v3.8.3](https://github.com/edwinrodri12/Tarvoka/actions/runs/44368832736): 9/9, respuesta inicial oficial de 7–8 órdenes = **2/16** victorias del iniciador; limitarla a **3** = **6/16**.
- [v3.8.7](https://github.com/edwinrodri12/Tarvoka/actions/runs/44368832908): 9/9, **4** órdenes = **0/16** victorias del iniciador; **5** órdenes = **6/16**. Con cinco órdenes, sin niebla gana el iniciador **2/8** y con niebla **4/8**. **No es un efecto monótono**: añadir una orden puede aumentar victorias del iniciador porque cambia la secuencia táctica posterior. No imponer una regla usando solamente cuatro mapas fijos.
- **Advertencia:** [la batería general Godot sobre v3.8.7](https://github.com/edwinrodri12/Tarvoka/actions/runs/44368832649) **falló** en la prueba de suministros `tests/test_supply_strategy.gd:43`: exigía la antigua casilla exacta `(1,2)` después de la corrección de desempate. Hubo también mensajes de índices fuera de rango en `TerrainTactics.tile_at` en otras pruebas: no deben confundirse con una aprobación global del motor. Se conserva por separado la investigación de esos errores.

## Prueba nueva: mapas que no aparecieron en las baterías de calibración

Para evitar ajustar la regla a cuatro plantillas concretas, reservar semillas **634–641**: ocho mapas aleatorios deterministas nuevos, con cuatro tipos de terreno. Las dos políticas ven las **mismas** coordenadas y recursos iniciales en cada caso.

- Cada semilla en 40×30, niebla sí y no, iniciador color 0 y 1: **32 casos originales emparejados**.
- **Respuesta oficial:** primero 3 órdenes, segundo todas sus 7–8 órdenes legales habituales (sin cap adicional).
- **Respuesta experimental:** primero 3 órdenes, segundo **hasta 5** órdenes solo en la primera respuesta. Todos los turnos posteriores son oficiales.
- Dos políticas × partido original y espejo reflejado = **128 partidas autoritativas**, pero únicamente 32 muestras originales por política; los espejos no cuentan dos veces.
- Los estados antes de la intervención deben coincidir, incluidas las primeras tres decisiones del iniciador y las primeras **cinco** del respondedor. Los reflejos deben reproducir **cada decisión y estado**, no solo los resultados.
- Tope **32 medios turnos**; cualquier partida sin ganador natural queda censurada, sin atribuir victoria ni empate.
- El agregador compara cuántas victorias del iniciador aparecen/desaparecen, con desglose por niebla, terreno y semilla. No aceptar muestras faltantes, duplicadas o simetrías divergentes.

## Regresión del contrato de abastecimiento

La prueba heredada verificaba además de la legalidad del repostaje el **destino absoluto de la primera entrega** `(1,2)`. Ese detalle no es una regla del juego: dos casillas adyacentes al tanque necesitado pueden ser legales e igualmente óptimas, y el desempate corregido elegirá una con un criterio geométrico simétrico.

La aserción se sustituye por comprobaciones más fuertes y relevantes al jugador: la casilla final del camión **debe ser adyacente ortogonalmente al tanque**, el tanque debe conservar su posición, la nueva posición debe pertenecer realmente al camión, y **las siguientes aserciones existentes** deben demostrar que la IA entrega el combustible y la munición sin cobro doble, con serialización válida.

**Se cambia un solo archivo de prueba** por esa razón; ni `SupplyNavigation` ni la producción se modifican en la v3.8.8. Un job `supply_smoke` aislado debe aprobar el recorrido completo antes de aceptar el agregado de mapas nuevos.

## Decisiones restringidas

Estas pruebas no autorizan cambiar oficialmente el límite de órdenes, ingresos de nadie, combate, relés, edificios, dificultad IA o APK. Incluso 32 nuevos casos siguen siendo un estudio limitado de mapas generados con un solo tipo de IA. El objetivo es la **robustez fuera de las semillas utilizadas para escoger cap 5**, no ofrecer cifras universales de equilibrio.

**Criterio de éxito:** 16 shards Godot 4.3 (8 semillas × 2 nieblas), 1 suministro aislado y 1 agregado = **18/18 trabajos** con reporte JSON y Markdown. Cualquier fallo debe tratarse como fallo, no como empate ni parcial aprobado. El PR permanece **DRAFT**, sin fusión con `main`.
