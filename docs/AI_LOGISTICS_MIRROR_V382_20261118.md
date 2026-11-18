# TARVOKA v3.8.2 — Desempate de navegación simétrico en camiones de suministro

**18 de noviembre de 2026.** Corrección de IA logística exclusivamente en rama experimental, PR #587. No modificar reglas, turnos, daños, dinero, visibilidad ni APK.

## Causa comprobada con Godot real

CI forense [44333047028](https://github.com/edwinrodri12/Tarvoka/actions/runs/44333047028) **éxito** reprodujo el primer desvío del mapa **40×30, semilla 631, costa, niebla activada**, bajo ambos bandos. Los **301 registros anteriores coincidían** por reflexión.

En el registro 301 (fase 22, orden 5, numeración desde cero), una misma unidad **N21**, `role=logistics`, sin munición y con 54 de combustible, recibió dos movimientos distintos:

- Juego original: `N21 -> (5,12)`.
- Reflejo normalizado: `N21 -> (6,12)`.
- **Motivo en ambos**: `field_supply`.
- Ambos estados anteriores, enemigos visibles y 537 casillas exploradas eran idénticos después de normalizar el espejo.

El responsable es `SupplyNavigation.plan_truck_delivery`: al empatar dos rutas se ordenaba por Y ascendente y luego **menor X global**. Esa última regla no mantiene igualdad al reflejar posiciones. El mismo patrón también existía en `SupplyNavigation.plan` para regreso al depósito, aunque no causó este incidente concreto.

## Cambio mínimo candidato

En `scripts/core/SupplyNavigation.gd` se añade `_prefer_route_tie(cell,current,side,width)`. Conserva la prioridad de Y menor y, si Y empata, usa X **local al bando**: X a la izquierda para facción 0 y `width-1-X` para facción 1. Se aplica a las dos rutas mencionadas. Para facción 0 el orden anterior queda exactamente preservado; para facción 1 ahora refleja de verdad el terreno.

**Sin cambios** de coste de movimiento, consumo de combustible, cantidades de suministros, selección de destinatarios, lista de lugares abastecibles, caminos, propiedad de instalaciones, munición, HP, estadísticas, IA principal o guardados.

## Pruebas de aceptación

1. **Prueba focalizada v3.8.2**: comprobar que las mismas casillas empatan igual bajo reflexión en los tres anchos soportados (10, 24, 40); repetir **seed 631, 40×30, niebla** con ambos iniciadores y sus espejos, hasta 24 medios turnos o ganador. La secuencia entera, las decisiones y los estados deben coincidir.
2. **Matriz extendida v3.8.1**: ejecutar las ocho combinaciones 40×30 de plantillas y niebla, con iniciador 0/1 y cada reflejo. Exigir **16 escenarios originales y 16 reflejos**, agregado completo y todas las métricas de captura, combate, abastecimiento y censura verídica.
3. **CI general Godot**: los flujos existentes de combate, logística y reglas deben seguir pasando. Todos los cambios experimentales deben quedar fuera de `main` y sin fusionar PR por defecto.

### Estado

El diagnóstico de causa ya está comprobado. **La reparación no se considera validada hasta que las pruebas nuevas pasen CI.** No inferir ventajas para el segundo jugador ni finalizar el balance de la IA antes de ese resultado.
