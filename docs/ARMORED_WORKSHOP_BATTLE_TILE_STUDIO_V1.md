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

## Siguiente prioridad: cambio automático de detalle al hacer zoom

El selector `EDIFICIOS > Taller de Blindados` dispone ahora de la quinta opción **`Android · AUTOMÁTICO por zoom`** en los estudios compartido y separado. Al elegirla, pasa a la vista de nueve casillas; HERO sigue reservado a inspección artística del edificio completo.

- Umbrales de tamaño proyectado reales, no distancias inventadas: al alcanzar **152 píxeles** cambia a **TACTICAL**, al caer a **112 píxeles** cambia a **DISTANT**, conservando el último LOD en el intervalo entre ambos (histéresis de 40 px).
- `ArmoredWorkshopBattleTile3D.set_preview_detail` reconstruye únicamente la malla 3D del taller y mantiene intactos los nueve bloques de terreno, las tres líneas de carretera, posición del edificio, orientación de cámara y sistema de zoom. No se crean casillas nuevas del juego.
- El visor muestra los píxeles proyectados y el perfil activo junto a la cantidad de lotes GPU; los perfiles manuales permanecen manuales.
- `tests/test_armored_workshop_studio_ui.gd` incluye zoom cercano, lejano y de retorno, validación de que el árbol de las nueve casillas y el contenedor de edificio no cambian de identidad, más control de selección manual.
- `tests/capture_armored_workshop_auto_zoom.gd` crea **8 capturas nuevas de Godot OpenGL**, cada una con zoom, LOD, píxeles, lotes GPU y validación de geometría visible en el manifiesto. Pasan de 58 a **66 vistas** en el artefacto de Actions cuando concluya la ejecución.
- Publicación: el flujo general de GitHub Pages ha sido modificado para copiar y verificar los scripts nuevos desde la rama artística. El despliegue de la revisión automática debe completarse antes de afirmar disponibilidad del nuevo selector en la web.

**Estado de validación:** el run anterior `44647769023` publicó con éxito el visor compartido **sin** modo AUTO. La prueba nativa de la lógica AUTO tuvo un run SUCCESS `44653647315`. La exportación visual de ocho zooms y el Pages actualizado siguen sujetos a sus propias comprobaciones, antes de solicitar visto bueno artístico.

## Cierre de la prioridad de publicación y auto-LOD (validado en CI)

**GitHub Pages:** [run #44654258519](https://github.com/edwinrodri12/Tarvoka/actions/runs/44654258519), compilación y despliegue **SUCCESS**. Se construyó el estudio nativo con la nueva opción `Android · AUTOMÁTICO por zoom`.

**Godot nativo:** [run #44656702261](https://github.com/edwinrodri12/Tarvoka/actions/runs/44656702261), **SUCCESS**. El artefacto `armored-workshop-v2-66-camera-auto-zoom-and-battle-evidence` tiene **66 PNG**: 36 cámaras de taller, 8 de escala táctica, 14 de estudio con nueve casillas, y 8 nuevas tomas de zoom.

**Causa y corrección de la prueba bloqueada:** el guion anterior intentaba capturar una `SubViewport` redimensionada por el panel responsive del inspector (resolución dependiente de UI). Para evitar falsos fallos y un proceso Godot retenido, `capture_armored_workshop_auto_zoom.gd` renderiza ahora la misma escena `ArmoredWorkshopBattleTile3D` con `ArmoredWorkshopLODPolicy` en un `SubViewport` independiente de 960 × 720. La interfaz interactiva se verifica por separado en `test_armored_workshop_studio_ui.gd`. El paso de CI incorpora un límite de 150 segundos para terminar con error explícito ante bloqueos.

**Datos observados en el manifiesto de las ocho capturas reales:**

| Zoom | Ancho proyectado | Perfil | Lotes GPU |
| --- | ---: | --- | ---: |
| 0.60 | 271.3 px | Táctico | 10 |
| 0.85 | 191.5 px | Táctico | 10 |
| 1.12 | 145.3 px | Táctico, retenido por histéresis | 10 |
| 1.42 | 114.6 px | Táctico, retenido por histéresis | 10 |
| 1.95 | 83.5 px | Distante | 6 |
| 1.25 | 130.2 px | Distante, retenido por histéresis | 6 |
| 0.90 | 180.8 px | Táctico | 10 |
| 0.60 | 271.3 px | Táctico | 10 |

Las ocho imágenes contienen geometría y verifican la reutilización del terreno y del nodo raíz del edificio. Reducción de lotes de **10 a 6** en la vista distante (**40 %**); no se infiere FPS sin medición real en teléfono.

**Conflicto de integración resuelto:** se sincronizó la definición de publicación en la rama artística con la última versión comprobada en `main`, que también incluye las dependencias y controles del taller. PR #629 volvió a estado `clean`, conservándose como **draft**. No se marcó como aprobado ni se añadió como edificio funcional a `BattleTerrain3D`.
