# TARVOKA · Cuartel General V15: sprites de alta fidelidad del modelo 3D en Android

## Qué ha cambiado de verdad

La V14 utilizaba un dibujo vectorial 2D de un centro de mando en las dos ciudades iniciales de la partida. Esta **V15 reemplaza ese dibujo a escala legible con PNG transparentes calculados directamente en Godot 4.3 a partir del modelo físico V13**, manteniendo V14 como alternativa de renderización.

**No se utiliza una escena 3D durante las batallas.** El renderizador del tablero isométrico sigue siendo CanvasItem 2D, que ahora dibuja una sola imagen horneada. El juego contiene solo los sprites, no necesita importar `HeadquartersProductionV13.gd` ni sus miles de piezas de la calidad de presentación.

## Origen verificado del arte y reproducción

El workflow `.github/workflows/hq-v15-bake-sprites.yml`:

1. Descarga el motor Godot 4.3 que utiliza TARVOKA.
2. Extrae en una carpeta aislada la rama de arte previamente comprobada `feat/hq-v13-production-ready-runtime-lod-20261114`.
3. Copia el script `tests/bake_hq_3d_sprites_v15.gd` a ese proyecto de arte y **solamente allí** carga el código V13 del renderizador 3D.
4. Renderiza la geometría a través de `SubViewport` con cámara ortográfica, dos luces originales y alfa transparente. Se conserva el emblema oficial ya incorporado físicamente en el V13; no se inventan insignias nuevas.
5. Produce exactamente **nueve PNG de 384×384**, uno por cada facción oficial y uno neutral sin escudo. Verifica que no estén vacíos ni tengan un fondo opaco, y los incorpora a `assets/buildings/hq_v15/` del proyecto jugable.
6. Publica una lámina de verificación y los PNG originales como artefacto inspectable.

Las nueve texturas suman aproximadamente 420 KB de PNG comprimido y, sin compresión GPU, unos 5.3 MB de RGBA8 si todas se cargan simultáneamente. El juego utiliza carga perezosa y caché de hasta nueve variantes.

## Uso en la partida

`HeadquartersSpriteV15.gd` ofrece `sprite(faction)` y `draw_iso`. `IsoRenderer.gd` hace la sustitución solo en las dos ciudades iniciales ya identificadas por V14, por encima de un ancho mínimo de media baldosa de 15 px y **cuando el modo ahorro está desactivado**. En mapas muy alejados, ahorro de energía o ausencia de recurso cargado, se usa la silueta vectorial V14. Las otras ciudades, fábricas y edificios conservan su presentación.

Se mantiene la ordenación de capas original: detrás de las unidades y debajo de los indicadores de captura/propiedad y selección. El dibujo no cambia hitbox ni respuesta táctil.

### Protección de la información

- Propietario conocido: recorte de la facción del archivo V13 ya aprobado.
- Territorio neutral o propiedad explorada con propietario desconocido (`-1` / `-2`): `hq_neutral.png` **sin escudo**, no imagen del último propietario.
- Territorio no explorado: el motor no genera un marcador visible para el enemigo.
- Captura: el edificio permanece en la misma casilla pero usa el color y el escudo del propietario actualmente confirmado.
- Nunca se escriben IDs de arte ni sprites en los guardados.

## QA y artefactos

El workflow `.github/workflows/hq-v15-visual-test.yml` prueba con el Godot 4.3 real:
- presencia, alfa y diferencias de nueve imágenes; ocho diseños oficiales distintos y neutral separado;
- carga de recursos en el proyecto jugable *sin* el código fuente V13 de la rama de arte;
- reglas intactas de dinero, unidades, terrenos, niebla, posiciones de ciudades y selección;
- cambio V14→V15 dentro del mismo renderizador de batalla;
- renderizado a zoom cercano, comparador y montaje de las ocho facciones **de una partida real**;
- criterio de bajo consumo (no usar PNG a zoom bajo ni con ahorro de batería).

Archivos en `artifacts/` de los tests (se descargan desde GitHub Actions, no se insertan en git):
- `tarvoka_hq_v14_vector_vs_v15_real_3d_baked.png`
- `tarvoka_hq_v15_live_android_isometric.png`
- `tarvoka_hq_v15_live_battle_close.png`
- `tarvoka_hq_v15_8_factions_in_real_battle.png`

## Pendientes reales para acabado comercial

Verificación con Android físico de gama baja; perfilar memoria real y potencia de GPU en partidas grandes con lluvia/nieve; mejorar la legibilidad en zoom extremo sin superponer unidades; refinar silueta y colores/materiales de las versiones 3D; evaluar sprites de niveles distintos y estados de daño **cuando existan reglas de juego que lo justifiquen**. No confundir mejora visual con la creación de una nueva instalación tácticamente diferente.
