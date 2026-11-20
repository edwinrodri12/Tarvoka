# Taller de Blindados — prueba a escala de batalla en el Estudio 3D

## Prioridad terminada en código
El Taller de Blindados dispone de un **modo de vista 3D sobre nueve casillas tácticas** dentro del mismo selector de TARVOKA Estudio 3D. Es render nativo de Godot 4.3, no una imagen, página HTML falsa ni integración jugable.

- Seleccionar `EDIFICIOS > Taller de Blindados`.
- Elegir `MODELO 3D COMPLETO` para inspección artística V1/V2 HERO o Android.
- Elegir `PRUEBA EN CASILLA 3D · 2,4 m` para situar el modelo entre nueve losetas originales de 2,4 m (las tres delanteras parecen una carretera).
- En modo mapa se elige automáticamente **Android táctico** o se puede cambiar a **Android distante** en el selector de acabado. Los HERO no se instancian en el contexto de batalla; esto protege el presupuesto de renderizado.
- Conserva nivel N1–N3, ocho facciones y neutral diferenciado, cinco estados de daño, cámara 360°, perspectivas superior/laterales y zoom.
- El mismo modo existe en `ArmoredWorkshopDesignStudioV1.gd` para la escena independiente.

## Código
- `ArmoredWorkshopBattleTile3D.gd`: nueve `BoxMesh` reales y tres marcas de calzada, con el mismo tipo de escala usado por `BattleTerrain3D`.
- `ArmoredWorkshopBattlePreview3D.gd`: envuelve el LOD Android en una huella de **2,17 m** máxima dentro de una casilla de **2,4 m**, conservando aproximadamente **0,115 m por borde**.
- `ArmoredWorkshopStudioAdapterV1.gd`: opción integrada exclusivamente en la séptima categoría de edificios.
- `ArmoredWorkshopDesignStudioV1.gd`: opción equivalente en el visor individual.
- El ensamblador de Pages en `main` copia las dependencias desde la rama artística para que el estudio central pueda cargar la vista.
- No se modifican `BattleTerrain3D.gd`, `Rules.gd`, `Economy.gd`, sitios del mapa, unidades logísticas ni cambios de turno.

## QA nativa adicional
- `tests/test_armored_workshop_studio_tile.gd`: 270 combinaciones (3 tamaños × 9 colores × 5 daños × 2 perfiles Android); 9 baldosas reales por caso, 3 marcas asfalto, escala, color y ausencia de efectos jugables.
- `tests/capture_armored_workshop_studio_tile.gd`: **14 PNG reales** en contexto de nueve casillas (12 de tamaños/perfiles/perspectivas y 2 de daños D3/D4).
- Junto a las 36 vistas de estudio y 8 capturas previas de escala táctica, el workflow puede producir **58 capturas** descargables cuando finalice.
- El resultado histórico [Actions #44640644688](https://github.com/edwinrodri12/Tarvoka/actions/runs/44640644688) aprobó 135 HERO + 270 Android + 840 LOD y 44 capturas; el nuevo modo 3D interactivo requiere una corrida nueva.

## Límites y aprobación
El taller **todavía no está aprobado ni agregado como estructura funcional a las batallas/APK**. Este modo es una maqueta real 3D en el visor; ninguna operación del estado de juego se altera. Las pruebas de render en OpenGL por software **no son un benchmark de un teléfono Android físico**. Solicitar revisión del modelo antes de activar el edificio en partidas.
