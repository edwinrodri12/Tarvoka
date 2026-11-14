# TARVOKA — Cuartel General V12: silueta táctica y noche realmente legible

## Problemas detectados en V11

La observación de las capturas de Godot mostró dos problemas concretos: (1) las curvas y cenefas nuevas solo se distinguían muy de cerca; (2) la escena de noche resultaba demasiado oscura para identificar la arquitectura. Esta revisión aborda ambos con **mallas y luz 3D reales**, sin cambiar las reglas del juego.

## Arquitectura V12

`HeadquartersSilhouetteV12.gd` añade dos grandes perfiles de cubierta extruida, con arco elevado sobre **cada ala**, cornisas continuas de material distinto, ribetes amplios con el color de la facción, ventanas rehundidas debajo, contrafuertes y costillas de cubierta. En la torre se añade una coronación arqueada más elevada y contrafuertes, colocada por detrás del escudo oficial para no taparlo. Los elementos visibles a gran distancia no dependen de remaches diminutos.

Los nuevos elementos, todos basados en la misma malla curvada original y materiales PBR de la V8, siguen siendo reales y editables en Blender. En **Dañado** se ocultan las cuatro piezas intactas del arco izquierdo y aparecen dos fragmentos irregulares, acero y restos. En **Destruido** solo aparecen elementos derrumbados; no se restituye el edificio.

## Estudio 3D

Se añadió el selector **Inspección cercana / Distancia táctica real**; cambia cámara y zoom del modelo 3D, sin confundirlo con el viejo LOD ultrabajo de 49 edificios. El modelo se puede comparar en V11/V12 con cámara y ambiente idénticos. Las ocho tarjetas y nombres oficiales de las facciones siguen operativos en el visor de unidades y edificios.

La **Noche operativa** usa luna fría, luz de relleno y ambiente controlado, junto con tres focos de estudio de mayor alcance sobre fachada y acceso. El cielo permanece oscuro; el edificio deja de quedar casi negro. El escenario está separado del juego real para que los vehículos/edificios no creen muchas luces dinámicas y no afecte al rendimiento de Android.

## Pruebas y exportaciones

`tests/test_headquarters_v12_tactical_night.gd` valida los tres niveles, ocho escudos, las cuatro condiciones, que la cubierta es una malla curva real con cientos de vértices, que la silueta cambia a zoom táctico, que el valor medio de luminosidad nocturna supera un umbral medible y que el visor de tanques se restaura al salir.

Artefactos esperados:
- `tarvoka_hq_v11_vs_v12_tactical_same_camera.png` (comparador desde cámara táctica)
- `tarvoka_hq_v12_eight_tactical_factions.png` (galería 4×2 con los ocho escudos oficiales)
- `tarvoka_hq_v12_tactical_day.png`
- `tarvoka_hq_v12_readable_night.png`
- `tarvoka_hq_v12_night_detail.png`
- `TARVOKA_CuartelGeneral_V12_Nivel3_Editable.glb` (modelo completo para Blender).

Históricos V4/V7/V8/V9/V10/V11 **permanecen congelados**: la V12 es opcional en el constructor. Es trabajo solo visual, no modifica combates, físicas, balance, IA, guardados ni facciones.

## Publicación

No declarar la actualización disponible hasta que el CI de Godot Web/Android sea verde y que el flujo de GitHub Pages ejecute el despliegue correctamente desde la rama V12.
