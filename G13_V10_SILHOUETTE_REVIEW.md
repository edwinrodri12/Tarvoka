# TARVOKA — G13 V10.4 · Estado de modelado 3D

## Qué cambió
- `scripts/ui/G13SilhouetteV10.gd`: nueva malla facetada con biseles exteriores para la cabina y la torreta, instalada tras la capa PBR V8.
- Tras la inspección de capturas reales, se preservó el **97.5% del ancho del núcleo**, 98% de la altura y 98% de la profundidad: las iteraciones con núcleos reducidos mostraban espacios visualmente desagradables bajo el techo.
- Los materiales de las dos mallas facetadas tienen representación por ambos lados; la cabina mantiene su aspecto sellado.
- `scripts/ui/UnitModels3D.gd` instala la revisión únicamente en G13 con acabado hero (art_level >= 13). LOD8, G11, P06 y demás unidades permanecen sin esta carga.
- `tests/test_g13_silhouette_v10.gd` comprueba los biseles, todas las facciones, el volumen del núcleo, material de doble cara, orden de vértices, animaciones reversibles y aislamiento LOD8.
- `tests/test_g13_v10_silhouette_capture.gd` captura 18 imágenes reales Godot: 8 facciones, 7 perspectivas, aire/tierra y rueda.

## Evidencia
- [QA nativa Godot 4.3 V10.4: SUCCESS, run 43952711715](https://github.com/edwinrodri12/Tarvoka/actions/runs/43952711715)
- Commit probado: `b5394f0fcb3a92a594865357fb415f0c6c0df4e4`
- Artefacto de inspección: `g13-v10-faceted-silhouette-18-actual-godot-frames`, ID `14266614161`.
- [Publicación del estudio compartido: SUCCESS, run 43952684817](https://github.com/edwinrodri12/Tarvoka/actions/runs/43952684817) para código V10.4 antes del último ajuste exclusivo de la prueba.

## Revisión artística
Los nuevos ángulos se aprecian sobre todo en la transición lateral de la cabina y en el contorno de la torreta. No confundir un `SUCCESS` de Godot CI con acabado gráfico final: el chasis, techo y proporción general aún requieren evaluación estética para lanzamiento comercial.

**Estado:** V10.4 integrado, compilación/QA aprobadas y 18 capturas verificadas; aprobado para continuar el modelado, **no** para cerrar arte comercial.

## Continuación recomendada
1. Pulir la unión entre techo, frente y laterales sin volver a disminuir demasiado el núcleo sólido.
2. Revisar la geometría de la parte trasera y la lectura del volumen desde perspectivas superiores.
3. Repetir las mismas capturas comparadas con V9; no modificar estadísticas, alcance, municiones, 8 facciones ni balance v0.1.
