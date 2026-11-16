# TARVOKA · Base Naval V12: revisión integral de amarres desde el mar

## Objetivo
Completar una inspección 3D orientada a los últimos errores visuales detectables en muelles: uniones caucho-acero-hormigón y cadenas de retención que parecían rectas. Todo está modelado en **Godot 4.3**, no con renders conceptuales ni cambios de reglas.

## Cambios
- **Cadenas:** en V11 los eslabones estaban agrupados eficientemente en MultiMeshInstance3D, pero estaban sobre líneas rectas. V12 conserva el mismo mesh original y usa un perfil con pequeña flecha gravitatoria (`sag<=0.045`), orientando cada eslabón a la tangente local, alternando su giro y conservando exactamente ambos puntos de anclaje V10. No se simula física ni se añaden luces costosas.
- **Sin duplicación:** V12 oculta solamente los eslabones anteriores V11 de esas cadenas en la escena V12; reaparecen al desactivar la casilla V12 y reconstruir V11 desde cero. Piezas de otra función, bolardos, argollas, agua, espuma y fundaciones no se retiran.
- **Juntas finales:** pequeño borde de compresión, protección del extremo inferior, depósitos de sal muy discretos y remates de retención en las caras físicas de muelles y espigones. Las piezas nuevas no pretenden tapar agujeros estructurales ni crear muelles inexistentes.
- **Daños:** 0/1 completos, 2 con desgaste y tramos faltantes de acuerdo con V11, 3 sin cadenas intactas y sin espigón positivo, 4 únicamente escombros. Colores de facción acotados a marcas discretas.
- **LOD:** microrremates a zoom cercano y perfiles tácticos simples desde lejos. Iluminación nocturna nativa existente; sin emisión adicional.
- **TARVOKA Estudio 3D:** Edificios 3D → Base Naval V12. Interruptor `V12 · cadenas curvas y remates (comparar V11)`, todas las cámaras existentes y la nueva octava `Perfil bajo desde el mar` que ayuda a comprobar las paredes a nivel de agua.

## Validación
`scripts/ui/NavalFinalContactV12.gd`, `tests/test_naval_base_v12_gpu.gd` y `.github/workflows/naval-base-v12-gpu.yml`. El flujo Godot 4.3/OpenGL debe confirmar 8 facciones × 5 daños (40 modelos) × niveles 1–3, materiales, cadenas instanciadas, extremos de anclaje, LOD, noche, nueva cámara y ocho capturas auténticas.

No afirmar éxito hasta el resultado de GitHub Actions. Esta revisión **no prueba** la APK Android, FPS, física de olas, colisiones, movimiento de buques ni la funcionalidad jugable de la Base Naval.

## Siguiente etapa después de inspección
Elegir entre terminar definitivamente el arte de muelles y pasar al siguiente edificio o realizar correcciones específicas de fotos/capturas. No añadir decoraciones acumulativas sin revisar la escala y utilidad visual en el Estudio.
