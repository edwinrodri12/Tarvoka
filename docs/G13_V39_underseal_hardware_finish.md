# TARVOKA — G13 V39: sellos inferiores y herrajes exteriores

**Estado:** la geometría 3D nativa V39 se guardó y se integró en las ramas LOD8/LOD13 de TARVOKA; dispone de comparación en el Estudio 3D. **Pendiente:** comprobación real de renderizado, compilación Godot y publicación pública. No se considera la G13 finalizada.

## Cambios de diseño

La V39 desarrolla acabado mecánico *sin agrandar ni modificar* la silueta previamente acordada.

- **2 sellos inferiores de cabina:** `G13_V39_SealedLowerCabSills`, un único `ArrayMesh` de dos perfiles hexagonales cerrados, extruidos desde Z=-1.070 hasta Z=-0.400, a ambos lados. Las caras interiores (|X|=0.651) penetran el casco de V1 (|X|=0.675). La cota mínima Y=0.775 deja espacio al neumático (radio 0.31 m; centro Y=0.33) y evita las molduras de pasos de rueda V33. Los remates no llegan hasta las franjas de facción V32 ni la parte superior acristalada. 40 triángulos.
- **2 uniones delanteras de parachoques:** `G13_V39_FrontBumperCheekJoints`, piezas cuadrangulares con volumen cerrado (24 triángulos en total). Apoyan sobre la barra delantera V1/V34 entre Z=-1.315 y -1.242 y Y=0.577..0.667, por debajo de los faros V23 y sin tapar la rejilla central V24.
- **2 soportes técnicos posteriores:** `G13_V39_RearServiceMounts`, dos bloques bajos empotrados parcialmente en el refuerzo transversal V34. Quedan por debajo de las insignias y de los escapes posteriores V35. Instancias de una única caja 3D.
- **10 fijaciones de metal:** `G13_V39_FrontRearFasteners`, seis pernos delanteros (cuatro sobre la barra frontal y dos sobre las defensas de esquina) y cuatro posteriores (dos en cada soporte). `MultiMeshInstance3D` de un único cilindro de ocho segmentos, ejes alineados con las caras frontal/trasera. No se duplican los remaches V38 del parachoques posterior.

## Diseño y compatibilidad

- Cuatro nuevos nodos de dibujo: dos `MeshInstance3D` y dos `MultiMeshInstance3D`.
- Validaciones de presencia de V38, jerarquía de casco y dimensiones del parachoques original antes de mutar la escena.
- No se cambian mallas originales, pintura de las ocho facciones, ruedas, radar plegable, torreta ni efectos de disparo.
- Armamento intacto: **dos cañones automáticos, ningún lanzamisiles**.
- Solo geometría artística; sin estadísticas o reglas de batalla nuevas. No está registrada aún como nueva unidad jugable.
- El diseño geométrico está revisado por sus cotas nominales; no equivale a una revisión de imagen renderizada.

## Integración

- `scripts/ui/G13UndersealFinishV39.gd`: generación geométrica y conmutador `show_finish(root, enabled)`.
- `scripts/ui/UnitModels3D.gd`: `G13UndersealV39.apply(model)` tras la V38, en LOD13 y LOD8.
- `scripts/ui/BastionStudioAdapter.gd`: selector de rol V39 y botones **Sellos y herrajes exteriores** / **Comparar con V38**. Conmutan únicamente los cuatro objetos nuevos dentro del mismo modelo, cámara y facción.

## Próxima prioridad de arte — V40

Revisar la coherencia estética y proporciones del vehículo desde cuatro direcciones, especialmente fijaciones frontales, línea de cabina y curva de las cuatro ruedas. Corregir piezas concretas si se observan superposiciones reales. Mantener el modelo en desarrollo y no afirmar rendimiento Android ni publicación sin evidencia.
