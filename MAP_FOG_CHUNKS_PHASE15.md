# TARVOKA — Fase 15: sombras de coníferas y reconstrucción incremental de niebla

## Alcance
Se modifica **únicamente** el renderizador 3D opcional. La vista 2.5D sigue siendo predeterminada y el estado `Vector2i` de `TouchBoard`, los movimientos, cobertura, combate, combustible, visibilidad táctica y guardados son los mismos.

## Actualizaciones visuales y calidad móvil

- `Conifer3DMesh.gd` contiene tonos de ramas más elaborados: parte inferior oscura, variación de agujas y rugosidad según la capa. Son recursos originales y procedurales; no sustituyen un material PBR de producción.
- `terrain3d_lab.gd` conserva las sombras proyectadas por los árboles y troncos en calidad completa. En calidad móvil desactiva las sombras dinámicas de árboles, troncos y sotobosque; los colores de las caras siguen proporcionando un volumen de sombreado sencillo. Esta elección puede comprobarse mediante `test_incremental_map3d.gd`.

## Sectores 8×8 para la niebla de guerra

- `Terrain3DChunkCache.gd`: obtiene rectángulos de 8×8 y firma exclusivamente las celdas **observadas** de cada sector y un margen de dos casillas para alturas, cauces y puentes.
- `Terrain3DMesh.build_ground()`, `Terrain3DMesh.build_water()` y `TerrainShore3D.build_banks()` aceptan ahora un `Rect2i` opcional; por defecto continúan devolviendo la malla completa existente. Las coordenadas 3D se mantienen globales y no se generan casillas tácticas distintas.
- `terrain3d_lab.gd` genera las mallas por sector **solo en el modo con niebla**. Un sector que no tiene ninguna casilla observada no crea mallas GPU. Al desaparecer bajo la niebla se oculta inmediatamente, sin mostrar un fotograma de geometría antigua. Los sectores con firmas idénticas conservan los mismos objetos `Mesh` de Godot.
- La vegetación y los puentes reutilizan recursos mientras su **vecindad visible** no haya cambiado. Esto evita crear de nuevo miles de árboles cuando el movimiento de una unidad revela solamente una llanura alejada de ellos.
- `Battle3DView.sync_battle()` usa `set_battle_terrain()` para cambiar calidad, terreno y niebla **en una sola reconstrucción**, evitando un doble procesamiento cuando se activa el ahorro de batería.

## Pruebas obligatorias

`tests/test_incremental_map3d.gd` comprueba que:
- La revelación de una llanura remota cambia un subconjunto de sectores, conservando la malla del bosque y del terreno inalterado;
- Cambiar biomas **no observados** no provoca reconstrucción ni filtración visual;
- Cubrir un sector previamente visible lo oculta de inmediato;
- Una modificación real del bosque obliga a regenerar la vegetación;
- Alternar calidades activa/desactiva sombras sin cambiar el terreno táctico;
- Volver al modo sin niebla restaura el renderizador completo y una actualización idéntica no reconstruye nada.

`tools/benchmark_forest3d.gd` añade un escenario sintético de niebla en mapa **40×30** con una revelación localizada: registra cuántos sectores se reconstruyen y cuánto tarda la operación en el runner Mesa, junto con las medidas full/mobile que ya existían. Los tiempos de GitHub Actions **no son FPS ni una garantía de rendimiento en un Android físico**.

### Resultado reproducible del benchmark 40×30

En [GitHub Actions 43555846922](https://github.com/edwinrodri12/Tarvoka/actions/runs/43555846922), con la calidad móvil 3D y un mapa sintético de 40×30:

- Visibilidad inicial: **420 casillas**. Se generaron **9 de 20 sectores** visibles, en **551,071 ms** en el runner.
- Revelación posterior: **una casilla adicional** distante, pasando a 421 visibles. Se reconstruyó **1 de los 20 sectores**, en **20,513 ms**.
- La prueba independiente también verifica la reutilización de la misma malla de un sector lejano y los mismos `MultiMesh` forestales cuando una llanura distante aparece.
- Son tiempos de **un escenario sintético sobre Mesa x86_64**, no medidas de FPS de Android ni estimaciones universales de aceleración. En especial, si la niebla revela muchos sectores a la vez, el coste puede seguir siendo elevado.

La compilación Android, las capturas reales de Godot y las pruebas integrales deben quedar verdes antes de fusionar. La PR #183 continúa en borrador por cambios concurrentes y conflictos con `main`.

## Próximos pasos

1. Medir FPS, tiempo de cuadros, memoria y temperatura en un Galaxy real, incluyendo una batalla de 40×30 con niebla dinámica.
2. Ajustar el tamaño de sector y el sombreado móvil a partir de los datos reales, sin confiar únicamente en las métricas Mesa.
3. Integrar con cuidado las unidades y edificios terminados en las otras ramas de desarrollo.
4. Seguir detallando materiales de corteza, agujas y laderas, sin perder la lectura táctica.
