# TARVOKA · G13 V18 — restauración del diseño de dos cañones (sin lanzamisiles)

## Corrección solicitada

La especificación original del antiaéreo G13 es un **vehículo 4×4 con dos cañones automáticos independientes, radar y capacidad de representar ataques aéreos y terrestres**. **No incluye lanzamisiles ni módulos SAM.** La inspección de los scripts G13 V1–V17 actuales no encontró mallas denominadas misil, cohete, lanzador o pod de misil: ya se construían dos cañones reales. Sin embargo, la forma de caja del antiguo `G13_TwinGunReceiver` podía interpretarse visualmente como un lanzador.

### Trabajo real de modelado 3D

- `scripts/ui/G13AutocannonSculptV18.gd` sustituye **la malla de la caja original** por un receptor/bloque de cierre achaflanado de cuatro secciones, con caras cerradas reales mediante `SurfaceTool`, **sobre el mismo pivote de elevación de ambos cañones**.
- Modela dos collares cortos de fijación mecanizados sobre los cañones existentes, dos tapas de expulsión superiores y dos accesos laterales al sistema de alimentación. Estas son piezas de artillería automática, **no contenedores de misiles**.
- Cuatro fijaciones agrupadas en un `MultiMesh` evitan añadir objetos separados por cada remache.
- Preserva las bocas huecas V12, los movimientos de retroceso y fuego V4, los pivotes de torreta/radar, las ocho pinturas de facción y todo el chasis/rejillas/tren de ruedas. **LOD8 Android y estadísticas de combate sin cambios**. El G13 todavía es un prototipo visual del Estudio 3D.
- Metadatos auditable: `tarvoka_g13_v18_weapon_configuration=twin_autocannon_no_missiles`, `tarvoka_g13_v18_launcher_count=0`, `tarvoka_g13_v18_autocannon_count=2`.

### Pruebas nativas

`tests/test_g13_autocannon_sculpt_v18.gd` valida en las ocho facciones 2 cañones cilíndricos, 2 bocas huecas y ninguna pieza de lanzamisiles, sustituye realmente la caja rectangular y comprueba las transformaciones y los ataques tierra/aire sin recrear mallas.

`tests/test_g13_v18_visual_capture.gd` captura **38 imágenes Godot**: ocho facciones, vistas de 360°, bajo carro, cañones apuntando a tierra y aire, radar, juntas, ruedas y tres primeros planos nuevos del bloque de cierre, las tapas de expulsión y los cañones elevados. Estas son escenas del modelo **dentro de Godot 4.3**, no ilustraciones generadas.

### Criterio de aprobación artística

La corrección de la silueta de la torreta y sus dos cañones debe validarse en las capturas y en el **mismo Estudio 3D**, sin cambios de jugabilidad. El modelado no se declara cerrado unilateralmente: el usuario decide si la nueva torreta corresponde al concepto original.
