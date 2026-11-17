# TARVOKA G13 V32 — mecánica de cañones y acentos de facción

**Estado: geometría nativa 3D integrada en ambos LOD y en el Studio; inspección visual y aprobación final pendientes.**

La petición es **un poco más del color de la facción**, no pintar por completo el blindaje. V32 respeta exactamente el color existente de la facción seleccionada para las ocho identidades oficiales y deja el chasis, ópticas, radar y bocas de fuego en su acabado original.

## Diseño

- **LOD13 (alta calidad):** seis pequeñas placas distribuidas en flancos y portón de mantenimiento posterior; cuatro acentos discretos sobre los hombros y borde trasero de la torreta. Se mantiene la escultura V24, los remaches y todas las piezas de la cabina anteriores.
- **LOD8 (táctico):** cuatro placas distribuidas en los dos flancos, cuatro acentos sobre la torreta; los protectores de cañón V31 reciben una mezcla de esmalte de facción al 47 % en lugar del 34 % anterior. El metal principal y el chasis no cambian.
- **Mecánica V32:** diez cabezas de fijación en total; cuatro siguen el giro de la torreta (collares de eje estacionarios), seis acompañan la elevación de las protecciones de cañones. Cada conjunto de tornillos usa un `MultiMesh` de 8 lados y está alojado en el padre original para que siga las animaciones automáticamente.
- **Coste geométrico:** dos nodos de dibujo nuevos en LOD13; cuatro en LOD8. Se reusa una malla cúbica para cada conjunto de placas. No se crean luces ni shaders.
- **No se cambia el armamento:** dos autocañones y cero misiles; ningún cambio en reglas tácticas, daños ni estadísticas.

## Implementación

- `scripts/ui/G13FactionMountFinishV32.gd`: geometría y control de visibilidad; guarda material V31 y permite volver a verlo sin crear una copia de la unidad.
- `scripts/ui/UnitModels3D.gd`: aplicación posterior a V24 en LOD13 o a V31 en LOD8.
- `scripts/ui/BastionStudioAdapter.gd`: nombre V32 y botones **Más color de facción** / **Comparar acabado anterior** en el menú G13. El mismo selector permite pasar entre LOD8 y LOD13.
- El flujo de publicación Web de TARVOKA copia los scripts `G13*.gd` desde el mismo commit de main que `UnitModels3D.gd`; se conserva esa compatibilidad sin alterar flujos ajenos.

## Próxima prioridad de diseño

Revisar la silueta G13 a escala de juego y terminar acabados de las ruedas/pasos de rueda, bisagras de mantenimiento y transición de blindaje entre cabina y chasis. Sin declarar el modelo definitivo ni ejecutar pruebas de rendimiento antes de completar el trabajo de arte solicitado.
