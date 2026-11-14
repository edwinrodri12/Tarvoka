# TARVOKA — Fase 13: orillas erosionadas y sotobosque 3D

## Implementación comprobable en Godot 4.3

- `scripts/ui/TerrainShore3D.gd` construye bandas 3D de grava y suelo húmedo que siguen la malla **real de alturas** de tierra junto a los ríos. Se deforma la anchura procedimental de cada orilla, con extremos de tamaño cero en las esquinas, para evitar cortes cuadrados. Su geometría es puramente decorativa y se mantiene dentro de la celda terrestre. El borde permanece ligeramente por encima de la superficie del agua para evitar quedar sumergido. Nunca se consulta una casilla de agua que no esté actualmente observada.
- `scripts/ui/TerrainUnderstory3D.gd` añade un tipo nuevo de malla de maleza, hierba y arbustos de bajo perfil. Los arbustos tienen variantes con 7 hojas en calidad completa y 4 hojas en modo móvil. Las posiciones se calculan con semillas reproducibles y se limitan al interior de la celda de bosque, evitando cubrir ríos, carreteras o unidades vecinas.
- `tools/terrain3d_lab.gd` integra ambas mejoras en la vista 3D *real*, incluido el modo experimental de batalla: `MeshInstance3D` para las orillas y un `MultiMeshInstance3D` compartido para todo el sotobosque. En baja calidad genera menos arbustos y menos facetas. La vista 2.5D original sigue intacta.
- `tests/test_native_terrain3d.gd` verifica que las bandas no superan los límites de tierra ni se hunden bajo el agua; prueba que la niebla oculta la geometría y que cambiar un vecino invisible no modifica el resultado. También comprueba geometría y posiciones reproducibles del sotobosque, además de las pruebas anteriores de selección, oleaje, puentes, mallas y tamaños de mapa.
- `.github/workflows/native-terrain3d-preview.yml` vuelve a generar PNG de calidad completa y media y compara la misma batalla en 3D y 2.5D sin necesidad de instalar otra APK.

## Invariantes conservadas

La cuadrícula táctica de `Vector2i`, niebla, movimientos, ataques, edificios, carreteras y guardados no cambian. El sistema no modifica `Rules`, `BattleSession`, `SaveCodec` ni la funcionalidad del selector táctil; solo añade decoración en la cámara 3D opcional.

## QA y prioridades pendientes

1. Renderizar capturas Godot y revisar si la orilla queda demasiado alta o gruesa sobre el terreno en declive; ajustar escala visual si es necesario.
2. Compilar APK Android de la misma rama, comprobar controles táctiles y el rendimiento 10×8, 24×18 y 40×30.
3. Medir **FPS y memoria reales en un Android físico**; CI no representa por sí solo el rendimiento final.
4. Perfeccionar las reflexiones del agua y el borde de espuma sin introducir saltos gráficos en puentes y zonas bajo niebla.
5. Mantener el PR #183 como borrador porque hay cambios simultáneos en la rama principal; revisar conflictos antes de fusionar.
