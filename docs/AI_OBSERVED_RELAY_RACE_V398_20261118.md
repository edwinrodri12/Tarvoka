# TARVOKA v3.9.8 — Planificador experimental de carreras por relés visibles

**18 de noviembre de 2026. Primera mejora estratégica real de IA posterior al estudio de iniciativa.**

## Problema verificado y objetivo

- [v3.9.2 17/17](https://github.com/edwinrodri12/Tarvoka/actions/runs/44418543642): bajo apertura oficial la IA actual ganó 12 veces con iniciador y 20 con respondedor en 32 condiciones; la táctica opt-in de presionar relés tras empate no aumentó victorias.
- [v3.9.3 17/17](https://github.com/edwinrodri12/Tarvoka/actions/runs/44419382374): en ocho semillas tipo doble puente sin niebla ganó el segundo en 16/16; con niebla no ocurrió siempre. Es razonable estudiar toma de decisiones además del orden de turnos.
- [v3.9.4 9/9](https://github.com/edwinrodri12/Tarvoka/actions/runs/44425512681): reducir la primera respuesta del segundo a tres órdenes produjo 14 victorias del iniciador; cinco órdenes mantuvieron 16 victorias del respondedor. No es una solución universal cambiar el presupuesto de órdenes.
- [v3.9.5 9/9](https://github.com/edwinrodri12/Tarvoka/actions/runs/44428593629): responder con cuarta compra de Piercer por 300 créditos conserva 16 victorias del segundo aunque el primero capture el primer relé; una quinta orden de avance acelera el resultado. La simple primera captura de relé NO garantiza victoria.
- **CI pendientes previas:** las pruebas v3.9.6 y v3.9.7 fallaron en el *harness* y quedaron sin agregado válido; no se usan para justificar cambios de IA.

Esto sugiere que la IA necesita evaluar **objetivos en riesgo y oportunidad a varios turnos**, no recibir automáticamente bonos de dinero, daño o unidades. Esta v3.9.8 añade un primer planificador de movimiento preventivo sobre relés, aislado y opt-in.

## Implementación

Nuevo flag `_ab_relay_race_forecast_v398` en `BasicAI.step`, **desactivado por defecto**. No crea ningún campo nuevo en partidas, guardados o perfiles de los usuarios.

El planificador `_forecast_relay_race_v398` solo actúa cuando:

1. La partida incluye relés y está en los primeros 12 medios turnos de puntuación.
2. Existe un relé **neutral conocido** y desocupado; no predice propietarios ocultos.
3. Hay **una unidad enemiga efectivamente visible**, terrestre y con una ruta conocida al objetivo. La IA desconoce la ubicación de enemigos ocultos, sus recursos privados y las casillas aún no exploradas.
4. El ETA aproximado del enemigo hacia el relé es como máximo ocho turnos de desplazamiento, y una unidad aliada disponible puede disputar ese objetivo razonablemente cerca del mismo horizonte.
5. La unidad aliada no tiene que abandonar un relé ya propio ni una ciudad que capturaría al cerrar el turno. Las muertes seguras, contraataques, retirada de supervivencia, suministros y defensa inmediata de relés conservan prioridad sobre el nuevo análisis.

El algoritmo usa distancias por terreno, gasto de movimiento público y distancia proyectada de los dos bandos para ordenar objetivos. Emite **una única acción `Session.move` legal** y vuelve a evaluar el estado en el siguiente paso. Etiqueta el movimiento `observed_relay_race_forecast_v398`; los números estimados no son una simulación omnisciente del siguiente turno enemigo.

Si no hay enemigos observables, mapa válido u objetivo realmente disputable, sale sin decisión y la IA anterior sigue **exactamente** como antes. Se ha insertado **antes** de la política de capturar ciudades y de comprar unidades, pero **después** de las decisiones tácticas urgentes. No modifica ingresos, puntuación, órdenes, unidades, combate ni fog.

## Pruebas reproducibles y método de aprobación

- Un microcontrato en Godot comprueba el default OFF byte-a-byte, acciones equivalentes en espejo, estados de guardado válidos, y el rechazo a inventar enemigos al evaluar un escenario sin unidades enemigas observadas.
- Holdout **ocho semillas nuevas 666–673**, dos por cada una de cuatro plantillas (abierta, bosque, doble puente y costa), tablero 40×30, ambas nieblas y ambos iniciadores.
- **32 condiciones originales** comparadas con IA anterior e IA nueva; cada partida se refleja exactamente, dando **128 partidas reales**, pero los reflejos **no se tratan como muestras independientes**.
- Horizonte 36 medios turnos; partidas inconclusas son **censuradas**, nunca victorias automáticas del segundo ni empates inventados.
- Informe de éxito por iniciador/respondedor, duración, capturas de relés, ciudades, compras, ataques, condiciones que realmente cambian acciones, divergencia inicialmente observada con o sin niebla, y desgloses por plantilla.

**Regla de decisión:** el flag no se activará en producción hasta aprobar **todas las pruebas de Godot** y observar una ventaja repetible en condiciones nuevas, sin daños de balance relevantes por mapa/niebla ni fugas de información. Un simple movimiento distinto o un ganador distinto en una única semilla no basta.

## Aislamiento

El cambio productivo agrega únicamente una estrategia **opt-in** a `scripts/core/BasicAI.gd`, sin alterar el comportamiento oficial al mantener el flag en false. Los restantes archivos son test, CI y documentación. PR **DRAFT** basado en la rama ya validada v3.9.5; no cambia `main`, APK ni reglas aprobadas.
