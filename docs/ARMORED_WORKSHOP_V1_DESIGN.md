# TARVOKA — Taller de Blindados V1

## Decisión de dirección

El único nuevo edificio terrestre que se desarrollará en esta etapa es el **Taller de Blindados**. Es una **instalación permanente** para unidades terrestres blindadas y pesadas; su modelado está separado de las mecánicas de batalla. La decisión de si produce unidades, las repara o ambas corresponde a las reglas de juego y deberá implementarse y equilibrarse por separado.

No se agregará un edificio permanente de depósito de suministros, almacén logístico o recarga. **El abastecimiento táctico es responsabilidad de las unidades logísticas móviles**. Estas unidades podrán desplegar **campamentos temporales**, incluyendo un campamento de reabastecimiento, según sus reglas de juego cuando estén implementadas y validadas. El modelo 3D del taller no crea ni modifica campamentos, munición, combustible o movimientos.

Conservar:
- Cuartel General: mando central.
- Cuartel de Infantería: fuerzas de infantería.
- Base Aérea: aeronaves, helicópteros y drones.
- Base Naval: buques; no astillero duplicado.
- Ciudades civiles: ingresos.
- Central Eléctrica V2: arte/escenario, jugabilidad pendiente de decisión.
- Taller de Blindados: nuevo edificio permanente y diferencial.

No crear edificios independientes para astillero, centro de mando, centro de drones, centro de artillería, almacén logístico, depósito de combustible ni depósitos de suministros. No retirar las unidades logísticas existentes.

## Alcance artístico V1

- 1, 2 o 3 bahías de mantenimiento para tres tamaños de instalación.
- Estructuras físicas de pilares, portones enrollables, techumbres, extractores y claraboyas.
- Elevadores hidráulicos y fosas de servicio; herramientas y grúas puente.
- 8 facciones oficiales + paleta neutral gris pizarra diferenciada del amarillo.
- Cinco daños físicos D0–D4, con ruinas sin piezas intactas suspendidas.
- Geometría editable nativa Godot 4.3, compatible con Studio 3D.
- Este diseño se considera **pendiente de aprobación artística**. No afecta el juego ni la APK.

## Estados y controles

- N1 taller blindado compacto: una bahía.
- N2 taller mecanizado: dos bahías.
- N3 complejo de blindados: tres bahías.
- Estados D0 intacto, D1 desgaste leve, D2 moderado, D3 crítico, D4 destruido.
- Vistas de inspección isométrica, frontal, posterior, lateral, segundo costado y superior; giro y zoom.

## Próximos criterios de aceptación

Ejecutar pruebas nativas para las 135 variantes, inspeccionar desde cámaras reales, verificar geometría/detalle/silueta, revisar rendimiento WebGL y Android y comparar acabados con Cuartel de Infantería y Base Naval ya aprobados.
