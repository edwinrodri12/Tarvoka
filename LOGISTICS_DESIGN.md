# TARVOKA — Reglas de munición, combustible y suministros (prototipo v0.2)

Estado: módulo funcional de prueba para batallas modernas, sujeto a CI y balance humano. **Las ocho facciones mantienen intacto su balance v0.1.**

## Recursos tácticos
Cada unidad de las 32 clases del catálogo tiene capacidad máxima de munición y combustible definida en `scripts/core/Logistics.gd`. Las cifras son puntos abstractos de juego, no litros ni proyectiles reales. Soldados a pie tienen combustible 0 (no lo consumen). Unidades de reconocimiento/soporte sin armas tienen munición 0 (no pueden disparar).

- **Disparo válido:** consume 1 punto de munición y agota la acción. Sin munición no se habilitan ataques en el motor ni en la interfaz.
- **Movimiento:** consume tantos puntos de combustible como la distancia ponderada del terreno, nunca más de la capacidad de movimiento por turno. El movimiento y ataque siguen siendo acciones independientes; una unidad puede moverse y atacar en el mismo turno.
- **Mantenimiento por turno:** aeronaves y navíos fuera de sus bases apropiadas gastan 1 punto al terminar su propio turno; submarinos gastan 2. Si ya estaban a 0 al finalizar un turno, pierden 2 HP. Al permanecer sobre base aérea/drones o astillero propio no hay desgaste de combustible. Vehículos terrestres gastan solo por desplazamiento.
- **Sin suministros:** con munición 0 no dispara; con combustible 0 un vehículo no se mueve. Una unidad aérea/naval sin combustible puede perder vida en turnos posteriores. La reserva no se regenera gratis ni por terminar el turno.

## Recarga desde base y en campaña
**Instalaciones:** los puntos de suministro sobre una misma casilla deben pertenecer a la facción:
- Terrestre: taller/cuartel, fábrica de blindados, centro de artillería (no en una ciudad de ingresos).
- Aéreo: aeródromo o centro de drones.
- Naval: astillero.

**Camión logístico:** transporte terrestre sin armamento. Capacidad persistente 16 puntos de munición y 36 puntos de combustible. Puede atender **una unidad terrestre adyacente por turno**, siempre que tenga reservas. Se descuenta el inventario transferido, la acción del receptor y la del camión. Solo se repone el inventario del propio camión desde una instalación terrestre aliada. No abastece barcos ni aeronaves en vuelo.

**Precio en créditos de juego:** 12 por unidad de munición, 4 por punto de combustible y 20 como mínimo por servicio. No hay recargas gratuitas. Si no se puede pagar la carga completa o el camión tiene pocas existencias, se ofrece **reabastecimiento parcial**; el presupuesto y la existencia limitan realmente cuánto se transfiere. Si el vehículo está a 0 de combustible, se prioriza recuperarlo; en los demás casos se prioriza munición. El botón debe mostrar los recursos y coste antes de ejecutar.

**Riesgo/contrajuego:** camiones pueden ser destruidos, necesitan protección; ocupar temporalmente una base para recargar impide usar su casilla de producción simultáneamente en la misma capa.

## Interfaz e IA
Al seleccionar una unidad propia el panel muestra munición X/Y, combustible X/Y, existencias del camión y la cotización de recarga si está disponible. Marcadores **M** y **F** ámbar/rojos identifican reservas bajas o agotadas solo para unidades propias: no se revelan reservas ocultas del oponente. El enemigo usa el mismo cálculo de existencias, créditos y acciones. Una IA puede reabastecer unidades críticas, pero no fabricar recursos virtuales ni consultar posiciones enemigas ocultas.

## Guardado y compatibilidad
La estructura JSON v1 preserva campos optativos `ammo` y `fuel`, y para camiones `supply_ammo`, `supply_fuel`, `supply_used`. Se validan rangos y tipos, y se rechazan cargas parciales o falsificaciones de otros roles. Las partidas clásicas sin suministros mantienen su comportamiento anterior. Partidas modernas anteriores a esta versión pueden carecer de inventario de camión; su stock inicial se interpreta de forma compatible con la versión anterior.

## QA y límites conocidos
Pruebas en `tests/test_logistics.gd` y `tests/test_logistics_advanced.gd`, más partidas de IA, Godot headless y exportación Android ARM64. No se debe declarar finalizado el sistema sin resultados CI correctos y pruebas Android físicas.

Sistemas pendientes por separado: destrucción/consumo definitivo de drones FPV, munición merodeadora y USV después de atacar; diferenciación de tipos de munición y ataque; despliegue/transporte de combustible; abastecimiento de unidades cargadas en transportes; inteligencia del retorno preventivo a base y cálculo de rutas; balance de las reservas y costes en partidas largas.
