# TARVOKA G13 V40 — revisión de silueta y guardabarros curvos

**Estado:** arte tridimensional nativo creado en Godot 4.3 e integrado en LOD8/LOD13 y el Estudio 3D. Pendientes inspección real de render, despliegue web y aprobación final de la unidad.

## Corrección visual fundamental

El modelo hero LOD13 mantenía dos lotes V16 de guardabarros **rectangulares originales V2** (4 placas + 4 molduras), aunque la V33 ya modelaba arcos de rueda curvos. La V40 oculta solo los dos lotes originales de render `G13_V16_Fenders` y `G13_V16_FenderTrims`, además de sus ocho piezas fuente históricas, y conserva los nombres, materiales, transformaciones y archivos originales para comparar o revertir.

En LOD8 no existen esos lotes V16, por lo que allí se añaden únicamente las piezas nuevas y se mantiene la misma geometría de rueda.

## Geometría nueva

- **4 guardabarros curvos exteriores:** `G13_V40_CurvedOuterFenders`. Un `ArrayMesh` con dos arcos laterales cerrados de 12 segmentos cada uno, instanciados para los ejes de rueda Z=-0.85 y +0.85. Radio interior 0.348 m, radio exterior 0.427 m. En cada sección, X=0.786 a 1.015 (abs); la cara interior solapa los arcos V33 y el exterior no excede la anchura de las viejas placas planas. **Holgura radial interior frente al neumático de referencia: 0.024 m**. La malla compartida tiene 200 triángulos y dos instancias, uno por eje.
- **4 soldaduras/cierres superiores:** `G13_V40_SillFenderWelds` usa un `MultiMeshInstance3D` de cuatro piezas cortas entre el borde del arco V36 y las piezas curvadas nuevas. Los cierres conectan también la línea inferior de cabina V39 en el eje delantero. No se tapan las ruedas ni los logotipos.
- **2 remates de esquina delanteros:** `G13_V40_FrontCornerTransitions`: dos sólidos facetados pentagonales entre los protectores V34 del parachoques y los acabados delanteros V39. Su rango Y=0.563–0.641 está claramente por debajo de los faros (Y≈0.85) y su posición X deja libre la entrada frontal V24. 32 triángulos en una sola malla.

**Impacto en dibujo:** tres nodos 3D nuevos. El LOD13 oculta dos lotes de guardabarros planos anteriores, lo que permite ver el diseño circular sin duplicados. No se sustituye ni modifica ninguna rueda existente.

## Comparación reversible

`G13SilhouetteFinishV40.show_finish(root, enabled)` alterna en la **misma escena**:

- `enabled=true`: muestra V40, oculta los lotes V16 de guardabarros antiguos, y mantiene los demás detalles V33–V39.
- `enabled=false`: oculta solo las tres nuevas mallas V40 y recupera exactamente el estado previo de visibilidad de los dos lotes V16 y sus piezas fuente. En LOD8 no hay piezas V16 que restaurar.

Los colores de las ocho facciones permanecen en los nodos V32. Conserva dos autocañones, ningún misil, radar plegable, ruedas móviles, cinemáticas y reglas tácticas sin cambios. El modelo es **un rol visual** (`aa_mobile`); esta fase no añade una unidad jugable de combate.

## Integración

- `scripts/ui/G13SilhouetteFinishV40.gd` — diseño nativo, comprobaciones de precondiciones y conmutación reversible.
- `scripts/ui/UnitModels3D.gd` — `G13SilhouetteV40.apply(model)` después de V39 en LOD13 y LOD8.
- `scripts/ui/BastionStudioAdapter.gd` — **Guardabarros curvos** y **Comparar con V39** en el Estudio 3D existente.

## Siguiente prioridad propuesta — V41

Priorizar un pase de diseño visual 360° real en el visor (frente, costados, tres cuartos, zaga y vista inferior), con atención a la superficie radial de V40, las zonas de unión y si hay recortes o superficies que se interceptan. Corregir cualquier defecto visible encontrado en el código, y solo entonces evaluar cerrar el modelo. No registrar pruebas Godot/Android ni publicación pública que no se hayan realizado.
