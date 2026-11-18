# TARVOKA — HAT-29 A01 V14.12: unión aerodinámica real raíz–pala

## Decisión de diseño
Auditoría visual realizada sobre el artefacto **Godot 4.3 V14.11** de 71 PNG (run [44254891134](https://github.com/edwinrodri12/Tarvoka/actions/runs/44254891134)). En la inspección desde arriba y de lado, la V14.11 estaba correctamente ubicada, pero a escala de visor su transición de seis estaciones apenas se diferenciaba del bloque previo; el extremo en Z=-0.345 no coincidía en anchura con el barrido positivo X del perfil real V3. Se necesita continuidad física, no más tornillos ni una superficie sobrepuesta.

## Nuevo modelado 3D
`scripts/ui/AttackHelicopterBladeSeamV1412.gd` actúa **después de V14.11** sobre los cuatro mismos `A01V3_BiselRaizAspa_0..3` bajo sus cuatro pivotes `A01_AspaPortante_0..3`:
- Se transforma la malla de cada raíz **en el mismo `MeshInstance3D`**, a un `ArrayMesh` sólido de ocho estaciones, ocho puntos de sección y tapas cerradas, 384 vértices y 128 triángulos. La V14.11 de 288 vértices se conserva como recurso anterior para comparación, y la antigua V3 como recurso todavía anterior.
- El barrido del perfil se aumenta gradualmente en **+X**: el eje de sección va de X=0 a X=+0.025, y el semiancho cambia según el borde de ataque real de V3. De Z=-0.350 a -0.450 la nueva superficie **se sumerge ligeramente en el ala existente**, cuya piel permanece completamente intacta. El espesor final de raíz es 0.030, por debajo de los 0.037 de la pala V3, para evitar intersecciones visibles y z-fighting.
- Todas las posiciones de malla compensan la traslación original `z=-0.225` del nodo V3. No cambian el cabeceo ni la animación del rotor, no se añaden `MeshInstance3D`, no se altera la pintura ni se afectan los 16 asientos biselados/32 pernos existentes.
- Exclusivo de la vista hero (`art_level >=13`); LOD Android 10 y menores quedan intactos.

## Inspector y comparación
En el **mismo visor 3D**: `Unidades → HAT-29 → Detalles`:
- `V14.12: transición de borde`
- `V14.12: perfil desde abajo`
- `Comparar unión V14.11 / V14.12`

Los controles alternan mallas reales, no imágenes. El botón anterior `Comparar raíz V3 / V14.11` funciona con V14.12: si el usuario desactiva V14.11, primero restaura temporalmente el estado anterior y conserva si V14.12 estaba activo para recuperarlo al regresar. El objeto original y sus animaciones no se reconstruyen.

## Pruebas y evidencias
- `tests/test_attack_helicopter_v14.gd`: 8 facciones, cuatro mallas, tamaño de 384 vértices, recurso V14.11 de 288, extensión real a Z=-0.450, barrido X asimétrico, LOD Android, cero nodos añadidos, y comparaciones reversibles.
- `tests/test_attack_helicopter_v9_studio.gd`: 2 cámaras, dos comparadores compatibles, mismo ID de modelo.
- `tests/test_attack_helicopter_v14_capture.gd`: **75 capturas nativas previstas**. Las 71 existentes y cuatro nuevas: dos de ángulo y un par V14.11/V14.12 con cámara/luz/pintura idénticas.
- Workflows A01 y Pages actualizados para incorporar el módulo a Godot y al empaquetado Web del visor unificado.

**Estado:** V14.12 implementada en GitHub, sujeto a ejecución y revisión de los artefactos Godot 4.3. La aprobación artística final permanece pendiente.
