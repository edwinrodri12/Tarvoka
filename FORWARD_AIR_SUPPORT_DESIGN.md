# TARVOKA — Abastecimiento aereo avanzado y construccion de instalaciones (propuesta v0.1)

## Implementado en la rama de jugabilidad
- El camion logistico puede reabastecer **helicoptero de ataque**, **helicoptero de transporte** y **dron de reconocimiento** en su misma casilla o una casilla ortogonal adyacente, usando la accion real `Reabastecer`.
- El helicoptero o dron debe situarse sobre terreno `plain` o `road`, para representar un aterrizaje temporal. **No** se admite `mountain`, `forest` ni `water`.
- Ambos consumen su accion del turno; se descuentan combustible y municion de la carga finita del camion. Esta carga ya se pago en fabrica/instalacion; no se cobra dos veces al transferir.
- Aviones de combate, bombarderos, aeronaves patrulla, UCAV de ala fija y municiones desechables no pueden recargar en camiones; conservan su dependencia de instalaciones.
- La IA puede despachar camiones a unidades aereas compatibles; el boton `Cargar` del HUD Android y las fichas usan la misma validacion de motor.
- La base aerea y el centro de drones existentes pueden reabastecer aeronaves compatibles al ocupar la instalacion. Todo esto mantiene los limites del motor y las partidas guardadas.

## Fase futura: construccion comprable por ingenieros (NO implementada)
Se necesita una accion `Construir` que seleccione un terreno valido, reserve creditos, mantenga obra en progreso y cree un sitio validado por el motor, la IA y SaveCodec. No confundir las instalaciones iniciales fijas con edificios construibles.

1. **Puesto avanzado de abastecimiento:** obra ligera de ingeniero, apta para helicopteros/drones y unidades terrestres. Terreno llano/carretera, vulnerable a captura, costo de construccion y costo adicional por recarga. Propuesta de balance inicial: 450 creditos y 2 turnos de obra.
2. **Aerodromo de campana:** instalacion con pista, permite operar aviones que no pueden aterrizar en un puesto avanzado. Requiere espacio/terreno plano y mas tiempo. Propuesta: 1100 creditos y 3 turnos de obra.
3. **Almacen de municion/combustible:** fuente de recarga terrestre y de camiones. Inventario limitado o gasto por unidad de suministro, a definir tras simulaciones.
4. **Restricciones anti-spam:** propiedad/faccion, limite de construcciones segun tamano de mapa, un constructor activo por obra, zonas no navegables, edificios capturables/atacables, costo y riesgo logistico reales.
5. **IA:** construir cuando bases existentes sean inaccesibles o la distancia implique una reserva de combustible peligrosa; nunca conceder combustible infinito ni revelar zonas en niebla.
6. **UI:** vista de ingeniero con costos y terreno apto, previsualizacion de alcance/zonas de servicio, indicador de obra y confirmacion sin orden accidental.

## QA necesario
- Helicoptero sin combustible junto a camion cargado: reabastece sin teletransporte.
- Camion sin inventario, de otra faccion, usado o alejado: operacion rechazada.
- Caza/bombardero: no puede usar camion en el suelo.
- Montanas, bosque y agua: no hay aterrizaje de campana.
- Niebla, partidas anteriores y movimiento entre aliados: sin cambios en informacion visible o reglas.
- Edificios construibles: pendiente de su propio desarrollo, pruebas economicas y balance de mapas grandes.
