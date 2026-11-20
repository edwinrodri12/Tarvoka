# TARVOKA — Reparación de niveles N1/N2/N3 del Taller en visor 3D

## Diagnóstico

El Taller V2 siempre tuvo los tres conjuntos de geometría. Las pruebas de 135 variantes HERO y 270 variantes Android validaron su existencia, pero **no comprobaban la selección de N1/N2/N3 dentro del visor compartido exportado a GitHub Pages**.

En `ArmoredWorkshopStudioAdapterV1.gd` el bloque de selectores `workshop_controls` se agregaba **al final** de `building_controls`, después de controles extensos de otros edificios. El visor de ciudades sí mueve sus controles al índice 2, inmediatamente después del selector de edificio. Esa asimetría hacía que los controles del Taller quedaran escondidos muy abajo en el panel y parecía que los niveles no se cargaban.

## Corrección

- El Taller mueve sus controles al **índice 2** del panel exclusivamente mientras está seleccionado. Al volver a Ciudad Civil se restaura su posición aprobada en índice 2. Se preservan también Central Eléctrica, Cuartel General, base aérea, base naval y cuartel de infantería.
- Agrega botones `N1 · 1 bahía`, `N2 · 2 bahías` y `N3 · 3 bahías`, además del selector original de arquitectura. Cada botón invoca la misma reconstrucción nativa que el selector.
- Etiquetas de confirmación `MODELO 3D CARGADO · N# ...` y error visible cuando no se genera un modelo. El usuario puede comprobar el nivel efectivamente mostrado.
- Conserva el nombre **`PruebaTacticaNueveCasillas`** en vista Android: ese nombre es parte del contrato de `ArmoredWorkshopBattleTile3D.set_preview_detail`. Renombrarlo al cambiar de nivel habría roto los cambios automáticos de LOD.
- El visor individual también dispone de `VER N1`, `VER N2` y `VER N3` y pruebas de reconstrucción.
- No cambia geometría aprobada, paletas, reglas de juego, costos, daño, suministros ni APK.

## Pruebas agregadas

`tests/test_armored_workshop_shared_levels_web.gd` corre dentro de la **escena exacta `scenes/UnitArtStudioWeb.tscn`** que la acción `Publish TARVOKA native 3D art studio` ensambla desde sus múltiples ramas.

Comprueba que el Taller aparece en `EDIFICIOS`, que los botones de niveles son visibles y están junto al selector; para N1, N2 y N3 en **HERO** y **MAPA** compara dos imágenes del viewport con el modelo visible y oculto (fallando si no aparecen píxeles reales). Produce seis PNG, confirma que hay un modelo con el número correcto de bahías y que al volver a Ciudad Civil sus controles siguen funcionando.

La publicación Pages ahora ejecuta esa prueba **antes de exportar**. Una compilación con un Taller invisible o un nivel mal seleccionado no podrá marcarse como publicación exitosa.

**Estado:** corrección programada en rama artística; validar la ejecución [del flujo Pages](https://github.com/edwinrodri12/Tarvoka/actions/workflows/tarvoka-3d-pages.yml) antes de asegurar que llegó a la web. Esta nota no sustituye probar una versión real en el navegador del usuario.
