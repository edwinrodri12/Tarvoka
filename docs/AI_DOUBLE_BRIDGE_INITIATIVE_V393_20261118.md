# TARVOKA v3.9.3 — ¿Por qué el segundo jugador domina el mapa de dos puentes?

**18 de noviembre de 2026. Diagnóstico con IA y reglas OFICIALES, sin cambiar combate, mapa o producción.**

## Hallazgo verificado previo

En la [prueba v3.9.2](https://github.com/edwinrodri12/Tarvoka/actions/runs/44389200174), los 16 shards de partidas 40×30 (8 semillas 634–641 × 2 visibilidades × ambos iniciadores) terminaron con éxito: en **32 casos originales**, la IA actual ganó **12 primero / 20 segundo**. La táctica experimental de presión a relés **también ganó 12 / 20**; solo alteró decisiones en las dos partidas sin niebla de la semilla 641, sin alterar ganadores ni duración. Por tanto no aporta mejora demostrada bajo la apertura oficial. El job agregador v392 falló inicialmente porque ejecutaba `main()` sin definir; se corrigió a `summarize(read(...))`, y se espera su comprobación CI definitiva.

La agrupación por plantilla v392 (datos completos de los 16 shards aprobados) mostró:
- Tipo 0, terreno abierto: **4 victorias del primero, 4 del segundo**.
- Tipo 1, rutas boscosas: **4 del primero, 4 del segundo**.
- Tipo 2, **Puentes de la Cuenca**: **0 del primero, 8 del segundo** (semillas 634 y 638, con niebla sí/no y ambos iniciadores).
- Tipo 3, costa: **4 del primero, 4 del segundo**.

**Interpretación cauta:** el efecto se concentra en el mapa de doble puente y no se explicó con la táctica de relés activada solamente tras alcanzar un empate. Dos semillas de ese tipo NO bastan para declarar que todas las variantes favorecen al segundo. Se necesitan casos realmente nuevos y evidencia de cómo se desarrolla la captura, no solo marcadores finales.

## Nueva investigación v3.9.3

- Mapa 40×30 **tipo 2**, corredor de agua central en X=19/20 y dos pasos terrestres en Y=8/21.
- Ocho semillas tipo2: **634 y 638** como antecedentes + **642, 646, 650, 654, 658, 662** como seis semillas nuevas que no se usaron en el estudio anterior.
- Cada semilla con niebla sí y no, iniciador de ambos colores: **32 situaciones originales** (8 antiguas, 24 nuevas).
- Cada situación se replica en espejo exacto: **64 partidas reales**, sin contabilizar los reflejos como muestras independientes.
- **Solo IA actual**, apertura OFICIAL con iniciador 3 órdenes y respondedor 7–8; **sin opt-in v391, sin cap5 ni ninguna prima económica**, sin alterar el mapa.
- Horizonte de 40 medios turnos; si no hay victoria natural, queda **censurado**, nunca se adjudica empate.
- Auditoría de `Session.end_turn`: cantidad y propietario de los cuatro relés, puntos otorgados después de cada ronda completa y cero pagos indebidos a mitad de ronda, capturas individuales, primera captura por facción, ciudades capturadas, primeras rondas de objetivo, órdenes de cada medio turno y resultados finales.
- Los 16 shards deben coincidir **en todos los estados y decisiones** con sus reflejos. El agregador debe encontrar 32 casos únicos e identificar con claridad las 24 condiciones de semillas nuevas para no confundir reconfirmación con nueva evidencia.

## Qué haremos según los resultados

Si también domina el segundo en los seis mapas inéditos, la siguiente prueba deberá contrastar una hipótesis sobre **el tiempo de acceso a los puentes, ocupación inicial, secuencia de primer movimiento o distribución de fuerza**, mediante reglas y presupuestos idénticos. No aprobar un bonus de dinero o un cuarto movimiento al primero sin medir su efecto en mapas abiertos, boscosos y costeros.

Si los nuevos mapas se equilibran, el problema habrá sido más específico de las semillas 634/638 y no debería generalizarse a toda la plantilla.

**Ningún archivo de producción modificado en v3.9.3.** Solo investigación reproducible, CI y documentación. PR DRAFT apilado sobre #601, sin fusión con main ni nueva APK.
