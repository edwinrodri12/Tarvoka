# TARVOKA v4.0.0 (investigación) — IA que compara costo de oportunidad

**19 de noviembre de 2026. Nuevo experimento de estrategia, NO lanzamiento v4.0 oficial.**
Todas las reglas de combate, economía, iniciativa, facciones, puntuación, producción, niebla y guardados permanecen intactas. El candidato solo actúa con el flag **`_ab_economic_arbitration_v400=true`**.

## Diagnóstico con resultados validados

- [v3.9.8 CI 18/18](https://github.com/edwinrodri12/Tarvoka/actions/runs/44450643355) validó las reglas y simetrías en 32 condiciones originales con ocho semillas nuevas, cuatro tipos de mapa, niebla sí/no y ambos iniciadores. **IA predeterminada primero 10/32, segundo22/32; IA que anticipa relés primero8/32, segundo24/32** (0 censuras). En niebla OFF empeoró victorias del primero de 6/16 a 2/16; en niebla ON mejoró de 4/16 a 6/16; en costa bajó de 2/8 a 0/8. La carrera mejoró el indicador *primero en capturar un relé* de 10 a22, pero redujo compras de 796 a746 y relés capturados de108 a102. No aprobar v398 por defecto.
- [v3.9.9 CI 10/10](https://github.com/edwinrodri12/Tarvoka/actions/runs/44455781949) comparó defender pasos estrechos con la misma apertura oficial en 16 nuevas condiciones. Ambas estrategias dieron **0 victorias iniciador, 16 respondedor**, 0 censuras; solo 4/16 decisiones cambiaron, todas con niebla, duración media 16.0→16.25 medios turnos. El screen es legal, pero no aporta mejora global en esta muestra. No activarlo.
- [v3.9.7 CI 4/4](https://github.com/edwinrodri12/Tarvoka/actions/runs/44441869171) aisló en laboratorio el cuerpo del Piercer comprado por el respondedor en doble puente, y 4/6 resultados regresaron a la situación con tres órdenes del respondedor aunque el gasto siguió pagado. [v3.9.6 CI4/4](https://github.com/edwinrodri12/Tarvoka/actions/runs/44441708520) observó que el Piercer nunca atacó en esos seis casos. Esto evidencia el peso de posición y decisiones inducidas sin justificar ningún bono artificial.

**Conclusión para el diseño:** no basta con correr hacia un relé. La IA debe decidir si adelantar ese movimiento vale la ciudad que puede capturar, el ingreso futuro o el refuerzo legal que dejará de comprar.

## Implementación opt-in

El módulo puro `OpportunityCostV400.gd` revisa tres **acciones legales ya calculadas por los sistemas reales**, sobre el mismo estado observado:

1. **Carrera por relé**: `_forecast_relay_race_v398` con enemigos *efectivamente visibles*, ruta de terreno real y presupuesto de movimiento propio/enemigo. Solo produce un `Session.move` legal.
2. **Captura urbana**: `_capture_urban_site` de la IA ya existente. Si el movimiento propuesto llega **este turno** a una ciudad conocida no poseída por la facción, la alternativa de ingresos tiene prioridad salvo una emergencia real de relé. No se cuenta como ingreso una ciudad lejana ni una ciudad de dueño desconocido bajo fog. El cálculo reporta el valor **de hasta tres ciclos futuros** (250 por ciudad/turno en moderno, 750 máximo en esos ciclos), como diagnóstico, NO como dinero recibido.
3. **Reclutamiento**: `_produce_reinforcements` original, con `Economy.can_purchase`, costo real de cada rol, propietarios y presupuestos existentes; puede mantener un refuerzo si la carrera no permite capturar un relé de inmediato y el rival está a más de un turno.

La carrera recibe prioridad **si existe una emergencia con enemigo observado** que puede llegar al relé en **≤1 turno**, nuestra unidad también llega en **≤1 turno**, y el movimiento elegido termina sobre el **relé mismo**. No se inventa un escenario futuro; es solo una decisión con información visible.

Fuera de esa emergencia, si hay ciudad capturable ahora, elegir ciudad; si hay refuerzo legal y el rival no llega en un turno, elegir refuerzo; si solo queda un progreso urbanístico legal, conservarlo. Si las alternativas no son válidas, la carrera sigue siendo candidata. Todas las decisiones devuelven la acción real `Session.move` o `Session.purchase`; no se inyectan unidades, no se regalan turnos ni se cambia ninguna regla.

**Código aislado:** `BasicAI.gd` solo entra a esa comparación si se recibe `_ab_economic_arbitration_v400=true`. Los flags predeterminados siguen OFF. El flag antiguo `_ab_relay_race_forecast_v398` sin el nuevo sigue EXACTAMENTE su comportamiento anterior, así podemos comparar los tres.

## Pruebas y criterio de éxito

### Contrato micro

- La ciudad capturable inmediatamente puede representar tres ingresos futuros (750 créditos en modo moderno), pero nada se transfiere al estado durante la predicción.
- La producción válida cuesta 300 y es preferida cuando no hay una emergencia visible en el relé.
- La captura inmediata de un relé que el enemigo visible puede alcanzar en un turno supera al proyecto de ciudad o producción.
- El flag OFF produce el mismo estado/acción que el comportamiento anterior.
- Bajo niebla se mantiene oculta la tesorería rival; decisiones originales reflejadas conservan simetría, los guardados son válidos y la propuesta no muta el estado original.

### Holdout de 3 políticas

**Ocho semillas nuevas: 682–689**, dos por tipo de mapa (abierto, bosque, doble puente, costa) × niebla ON/OFF × iniciador0/1 = **32 condiciones originales**. Cada condición enfrenta:
- IA oficial (sin flags),
- carrera por relé v3.9.8 sin filtrar,
- nuevo árbitro de costo de oportunidad v4.0.0.

Se ejecuta cada juego y su reflejo horizontal exacto: **32 × 3 × 2 = 192 partidas reales**, pero los espejos sirven como comprobación y **no incrementan las 32 condiciones originales**. Horizonte 36 medios turnos, censuras explícitas, controles de apertura de tres órdenes, guardados, economía, misma visibilidad, simetría y reporte JSON/Markdown.

**Criterio:** no aprobar por microtest ni cambio de acción. Debe mostrar ganadores mejores o menos sesgados que la IA oficial y v398, sin degradar sistemáticamente ningún tipo de mapa o niebla ni añadir información oculta. Si los beneficios son marginales o ambiguos, mantener la opción desactivada y estudiar errores de estrategia más específicos antes de fusionar.

## Alcance

**PR DRAFT** sobre la rama v398 **ya verificada con CI**, dejando fuera de dependencias a v399 (la pantalla de paso estrecho no mejoró victorias). El planificador v399 no se incorpora por defecto ni a esta investigación. Ningún cambio a `main` o APK, sin una ventaja fija para ningún jugador ni alterar la apertura oficial.
