# TARVOKA: Ingeniero — búsqueda inteligente de rutas de apoyo V2

**Dependencia:** esta mejora se basa en PR #320, que implementa la reparación a 35 créditos/HP. Esta rama NO modifica precios, HP máximos, ataque, defensa, captura, veterania ni niveles de progreso. Esta propuesta se revisa por separado en PR #323.

## Problema observado

Durante 16 partidas de IA en la auditoría del Ingeniero (1.453 órdenes, 281 compras) aparecieron **0 reparaciones espontáneas**. Sin embargo, una prueba focalizada sí demostró que, cuando el Ingeniero está junto a un tanque dañado, la IA realiza una reparación legal por 105 créditos. Esto indica una carencia de **posicionamiento y coordinación**, no únicamente de costes. No se debe declarar resuelto el problema de frecuencia sólo porque las pruebas focalizadas ahora reparen.

## Comportamiento implementado

- Un Ingeniero puede caminar hacia una **casilla libre ortogonal adyacente** a un vehículo terrestre aliado dañado; la reparación es una **orden separada**. Se usan rutas de terreno ponderado y el sistema real de puntos de movimiento.
- Busca trayectos de hasta **6 puntos de movimiento a pie** (3 turnos estándar como máximo); cada paso debe mejorar estrictamente la distancia restante. Sin teletransporte, sin solaparse con un aliado al terminar, sin atravesar aguas impasables.
- Para no convertir al Ingeniero en curador universal, considera objetivos que recuperarían **al menos 2 HP**, a **35 créditos/HP**, y sólo si el valor proporcional de compra recuperado excede el coste en **25 créditos o más**. La IA no inventa recursos ni modifica los mismos precios que se muestran al jugador.
- No abandona casillas de ciudades o relés todavía sin conquistar que una infantería esté capturando. No desplaza a un Ingeniero ya movido o que haya actuado.
- No propone terminar un movimiento en casillas bajo amenazas importantes de unidades **visibles**; los parámetros de peligro se estiman con las estadísticas públicas de los enemigos, no sus reservas privadas de combustible, munición, turno o reacción. Nunca observa unidades enemigas ocultas.
- Evita priorizar una reparación sobre ataques letales, retiradas urgentes, recargas vitales y defensa inmediata del relé.
- Si llega a una casilla adyacente, el siguiente paso de la IA puede efectuar la reparación **en el mismo turno**, porque la regla del juego permite mover y actuar. El Ingeniero gasta **una acción**, y únicamente el paso de reparación paga créditos.
- La lógica es determinista y contiene desempates normalizados a ambos lados del tablero, sin confiar en la nomenclatura de IDs iniciales A..Z.

## Evidencia para exigir antes de integración

1. Prueba multi-escenario de **mover + reparar** con clima despejado, lluvia, nieve y niebla (sin ayudas ocultas).
2. Recorrido de dos etapas antes de reparar, con disminución estricta de distancia, guardado inalterado y costo exactamente registrado.
3. Casos negativos: ciudad neutral que debe conservarse, blindado que no merece el gasto, fondos insuficientes, contacto enemigo peligroso, barrera de agua, ocupación aliada y rival oculto.
4. Partido espejo del bando contrario en el que la maniobra es la misma y la reparación cuesta lo mismo.
5. Regresión de **16 partidas emparejadas**, combate naval moderno y simetría de la IA en 304 decisiones, además de compilación APK y smoke de interfaz.

**Advertencia:** esta función todavía no logra por sí sola que la IA compre Ingenieros cuando conviene o conserve formación de escolta a lo largo de toda una batalla. El objetivo comercial de una reparación realmente frecuente, sin abuso de curación, requiere simulaciones prolongadas y ensayos humanos comparando un escenario con y sin coordinación. Sólo entonces decidiremos si 250 créditos por Ingeniero y 35/HP son valores adecuados.

## Siguiente paso de balance

Cuando la coordinación y economía estén comprobadas con partidas largas, abrir un experimento **independiente** de bonificaciones antiblindaje Rompedor vs G09 Tanque (+0/+1/+2) sobre cobertura, montaña, clima, munición y contrafuego. No aplicar un bonus sólo para coincidir con la descripción de una unidad sin verificar el coste por daño real y las respuestas tácticas.


## Primer resultado de eficacia (medido, no inferido)

Run validado [Engineer repair balance regression 43638904198](https://github.com/edwinrodri12/Tarvoka/actions/runs/43638904198), con nueve casos de movimiento y reparación (incluidos compra real de Ingeniero y tamaño 40×30).

| 16 escenarios pareados IA | Sin ruta V2 | Con ruta V2 |
|---|---:|---:|
| Acciones | 1.453 | 1.447 |
| Compras | 281 | 277 |
| Reabastecimientos | 18 | 20 |
| Reparaciones | **0** | **4** |
| Gasto efectivo en reparaciones | 0 | **350 créditos** |
| Victorias primer/segundo bando | 4 / 4 | 4 / 4 |
| Partidas inconclusas | 8 | 8 |
| Divergencias en 304 decisiones espejo | 0 | 0 |

Es una primera evidencia de uso orgánico de la reparación. Las **4 reparaciones** aún son escasas y no demuestran balance definitivo; con pocas partidas, la misma IA y muchos empates no debe proclamarse 50/50 competitivo. Tampoco es un test de rendimiento físico Android ni multijugador de ocho equipos.

En la suite extensa `test_initiative_experiments.gd` se detectó una aserción antigua que permitía solo cuatro acciones (mover, atacar, comprar, recargar). La corregimos para aceptar **reparaciones pagadas** y comprobar créditos y HP exactos, no para ignorar el gasto. Nueva prueba de 72 escenarios de apertura/iniciativa programada en la CI de esta rama. La CI `Godot 4 headless rules` debe finalizar antes de fusionar.

Añadimos contadores separados `support_moves` y `repair_spend` en la telemetría pareada, y un resumen genérico en la interfaz del turno rival que indica movimientos de Ingenieros de apoyo sin revelar identidades/posiciones bajo niebla.
