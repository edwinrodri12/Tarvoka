# TARVOKA v3.8.6 — Resolver la asimetría de entregas de camiones en una apertura igualada

**18 noviembre 2026. PR draft #593 sobre la v3.8.3, no sobre main.**

## Fallos originales y comprobación forense

[Workflow de diagnóstico](https://github.com/edwinrodri12/Tarvoka/actions/runs/44359393153) completó dos partidas pareadas focalizadas (la IA real en Godot 4.3) para 40×30, costa, semilla 631, con **tres órdenes para cada participante en su primera oportunidad**:

| Niebla | Fase | Fotograma | Camión | Movimiento original | Movimiento reflejado normalizado | Motivo AI |
|---|---:|---:|---|---|---|---|
| No | 13 | 174 | N8 | (20,9) | (19,10) | `field_supply` |
| Sí | 27 | 383 | N22 | (22,12) | (22,14) | `field_supply` |

Antes de esas acciones, los estados autoritativos eran **idénticos bajo reflexión**, y `BasicAI.step` reprodujo exactamente ambos movimientos desde los estados anteriores; no fue un error de resumen o normalización. En el caso con niebla, la unidad N22 era de rol `logistics`, tenía 46 unidades de combustible, munición cero y HP 8; en el caso sin niebla N8 era el mismo rol con 42 de combustible, munición cero y HP 8.

## Causa mecánica y cambio mínimo

La v3.8.2 ya había corregido un desempate de destino dentro de cada camino de un camión. Sin embargo, `SupplyNavigation.plan_truck_delivery` conservaba este segundo desempate implícito:

1. Recorrer destinatarios de suministros.
2. Para cada destinatario, recorrer sus casillas de aproximación siguiendo `Rules.DIRECTIONS` (UP, RIGHT, DOWN, LEFT).
3. Elegir una ruta si el coste total es **estrictamente menor** que el mejor actual (`whole >= best_cost` descartaba los empates).
4. En un tablero reflejado, RIGHT y LEFT intercambian su significado, por lo que el primer candidato empatado no es necesariamente el mismo. El orden de destinatarios tampoco constituye un criterio geométrico de desempate.

La corrección candidata v3.8.6:

- Mantiene las verificaciones reales de destinatario, dominio, combustible utilizable, casilla ocupada, visibilidad y alcance. `whole > best_cost` sigue descartando rutas peores.
- Para **costes exactamente iguales**, prioriza una decisión estable y simétrica por destino final, luego casilla de aproximación y finalmente posición del destinatario. Orden de desempate: Y, después X relativa a la facción que mueve. Ninguna decisión depende del orden de `Rules.DIRECTIONS`.
- No altera el cálculo de rutas, las prioridades por menor coste ni los objetivos del motor fuera de los empates. Se conserva `recipient_id` y toda la forma pública del plan.

## Verificación requerida

1. **CI focalizada v3.8.6**, semillas 631, niebla sí/no, primer jugador 0 y 1: cuatro shards × original y espejo. Hasta 32 medios turnos o ganador natural. Todos los registros de acción, fases, estados, ganador y terminal deben ser idénticos tras reflexión. Iniciador y respondedor deben usar tres órdenes iniciales cada uno en este *test*.
2. **CI v3.8.3 completa**, semillas 630–633, niebla sí/no, ambos iniciadores, dos políticas de apertura y cada política con espejo: 64 ejecuciones reales / 16 emparejamientos. Un único error invalida el agregado. Registrar censura como censura, no empate.
3. Regresiones de compatibilidad de la v3.8.1 / v3.8.2, Godot core y APK. **La ejecución satisfactoria del diagnóstico inicial no valida automáticamente esta corrección**: se requieren estos workflows actualizados.

## Restricciones

Ni `OpeningBalance.gd` ni `RelayControl.gd` ni ingresos iniciales ni combate ni el APK ni `main` se han modificado aquí. No se aprueba todavía igualar las aperturas del videojuego; sólo se investiga si la intervención de prueba elimina o reduce el sesgo aparente. Todas las ramas son experimentales y no están fusionadas.
