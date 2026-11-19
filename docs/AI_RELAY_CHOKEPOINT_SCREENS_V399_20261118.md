# TARVOKA v3.9.9 — IA defensiva en pasos estrechos y relés protegidos

**18 de noviembre de 2026. Mejoras de inteligencia, sin ventajas de dinero, daño, órdenes ni unidades. Investigación opt-in, OFF en partidas normales.**

## Motivo

Los experimentos previos revelaron dos observaciones sólidas:

1. [v3.9.5, 9/9 SUCCESS](https://github.com/edwinrodri12/Tarvoka/actions/runs/44428593629): en ocho mapas 40×30 de doble puente sin niebla, una única cuarta orden del respondedor (compra de Piercer por 300) cambiaba 14/16 desenlaces frente a terminar tras tres órdenes.
2. [v3.9.6 y v3.9.7, pruebas individuales del rerun](https://github.com/edwinrodri12/Tarvoka/actions/runs/44441708520): el Piercer comprado por el respondedor **nunca atacó** en seis partidos; movió entre seis y ocho veces y sobrevivió. En la ablación controlada ([v3.9.7](https://github.com/edwinrodri12/Tarvoka/actions/runs/44441869171)), eliminar su presencia manteniendo el dinero gastado cambió el ganador en **4/6** casos. Se limpiaron también las misiones que quedaban apuntando a esa unidad artificialmente eliminada. Son resultados de shards, agregadores pendientes: no atribuir causalidad exclusiva a ocupación ni convertirlo en una regla.
3. [v3.9.8](https://github.com/edwinrodri12/Tarvoka/pull/614) estudia priorizar carreras hacia relés neutrales mediante distancias de movilidad reales. La ejecución corregida [44450643355](https://github.com/edwinrodri12/Tarvoka/actions/runs/44450643355) aún estaba en cola al redactar este documento, por lo que no se presupone aprobada.

El siguiente paso técnico, **diferente de competir por un relé neutral**, es comprender cuándo defender un relé **ya propio y ocupado** usando una segunda unidad para controlar un cuello de botella que la tropa enemiga observada tendría que atravesar. La IA actual protege el propio relé desocupado bajo una amenaza inmediata, pero no compara de forma explícita el costo de obligar al enemigo a rodear puentes.

## Implementación propuesta

Nuevo módulo puramente táctico `scripts/core/RelayScreensV399.gd` y flag de prueba `_ab_relay_screen_v399` en `BasicAI`, **false por defecto**.

Se activa solamente cuando se verifican todos los siguientes requisitos:

- Existe un **relé de propiedad aliada observable**, **ocupado por una unidad aliada terrestre viva**, cuya guarnición **no abandona el objetivo**.
- Hay un enemigo terrestre **realmente visible** en el estado observado por la facción (sin recuerdos clandestinos de fog), con movimiento disponible y una ruta de terreno conocida al relé en como máximo cuatro turnos aproximados.
- Una **segunda unidad aliada** está disponible para desplazarse LEGALMENTE a una celda que tiene **dos lados opuestos impasables**: es un cuello de botella real, no una montaña transitable ni un bosque que simplemente ralentiza.
- El enemigo tendría que realizar un rodeo **de tres o más puntos de movimiento** si esa celda estuviera ocupada; se comprueba computando de nuevo una ruta ponderada por terreno con la casilla bloqueada. No se supone que cada montaña sea infranqueable ni que un enemigo tenga un destino secreto.
- La segunda unidad no está defendiendo ya otro relé, ni sobre una ciudad capturable que ganaría al finalizar el turno, ni comparte su destino con una tropa viva.

El planificador calcula distancias de terreno sobre **`Visibility.observed_state`**, usa `Weather.traction` y `Logistics.road_fast` para distinguir movimiento rodado/oruga de infantería y consulta únicamente unidades enemigas visibles. El resultado es un **único movimiento `Session.move` autorizado**, revisado por el mismo motor que usa el jugador. No mueve al enemigo, no impone una emboscada invisible, no produce daño y no genera unidades ni dinero.

Con `_ab_relay_screen_v399=false` los comportamientos previos son idénticos. La nueva decisión queda después de los ataques letales, retiros críticos y defensa inmediata de relés, pero antes de invertir en objetivos secundarios o producción. No altera la estrategia de carreras v3.9.8, que también continúa apagada salvo flag explícito.

## Pruebas que deben aprobarse ANTES de considerar activarlo

**Contrato determinista micro (Godot 4.3):** construir mapa real de doble puente 40×30 con relé propio ocupado por guardia, escolta detrás y enemigo visible en el otro lado del puente. Exigir:
- Una segunda unidad llega legalmente a la entrada de puente; el relé **sigue ocupado** y el marcador/créditos no cambian por planificar.
- Un posible bloqueo incrementa de verdad la ruta del enemigo como mínimo tres puntos.
- El plan ejecutado, todas las decisiones iniciales y estados resultantes son equivalentes bajo reflexión horizontal.
- Con niebla, cuando el enemigo desaparece de la visión de ambos aliados, el plan no inventa su presencia.
- Con el flag falso, mismo estado y misma decisión que la versión sin flag; en terreno abierto sin estrangulamiento no se inventa un choke.

**Holdout real con apertura oficial**: cuatro semillas nuevas, **674/678 doble puente y 677/681 bosque**, ambos iniciadores y niebla on/off (16 condiciones originales). IA actual vs screen opt-in; cada condición con espejo exacto: **64 juegos reales**, pero solo 16 comparaciones originales independientes del reflejo. Máximo 36 medios turnos, informe de victoria, censura, cambios de acción, capturas, compras y duración, desglosado por terreno y niebla.

El experimento no debe aprobarse por un único caso, por comprobar que actúa, ni por sumar espejos como partidas independientes. Antes de habilitar una política defensiva se requieren **resultados repetibles, con y sin niebla**, sin sacrificar la economía ni perjudicar sistemáticamente otros mapas.

## Riesgos y aislamiento

- Este es un primer **screen posicional**, no una búsqueda adversarial completa ni una garantía de que el enemigo intentará conquistar el relé: la IA solo observa su posición actual. Un enemigo real aún podría atacar a la pantalla y atravesarla después.
- El costo de ruta del enemigo se calcula ignorando temporalmente la posibilidad de disparar, porque la pantalla solo modela ocupación física, no combate futuro.
- Se preserva la legitimidad de las órdenes, el dinero, las estadísticas, el guardado y las reglas de visibilidad. **No activar si la rama padre v3.9.8 tiene fallos**.
- PR DRAFT basado en [v3.9.8](https://github.com/edwinrodri12/Tarvoka/pull/614), sin merge, sin nueva APK y sin modificar `main`.
