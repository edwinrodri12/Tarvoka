# TARVOKA — Fase 4 del entorno 3D: puentes, acabados y contrato de mapas

## Qué se implementa (en rama del Estudio Web)

- **Cañón V4:** los dos pasos sobre el río se generan como una sola superficie
  asfaltada por cruce, con transición de altura suavizada entre el centro
  de cada carretera de acceso y la plataforma sobre el agua.
  `TerrainStudioBridge3D.gd` produce un tablero continuo, marcas de carril,
  barandales y pilares en un grupo `MultiMeshInstance3D`.
- **Comparación honesta:** desactivar el interruptor V3 restaura los puentes
  de bloques V2. Con la misma cámara e iluminación, la prueba GPU guarda
  `tarvoka_canyon_v2_v4_same_camera.png`.
- **Materiales ligeros:** `TerrainSurfaceFinish3D.gd` genera tres pequeñas
  texturas reproducibles de **64×64 px**, con mipmaps y variaciones tenues.
  Se aplican a tierra, agua y roca sin sustituir los colores por bioma que
  proceden de los vértices. El objetivo es evitar color plano sin añadir
  descargas pesadas, shaders exclusivos ni dependencias comerciales.
- **Geometría separada:** las rampas y barandales no tienen colisión ni
  etiquetas de movimiento. Son decoración y no crean una ruta jugable.

## Preparación real para usar mapas de partida

Nuevo `TerrainVisualMapBridge3D.gd`: adaptador de lectura sobre las matrices
`Scenarios.terrain()` y `Scenarios.seeded_terrain()` que utiliza `Rules`.

- Acepta los tamaños jugables existentes: **10×8, 24×18 y 40×30**.
- Exposición en fragmentos limitados a **8×8** por defecto, máximo 16×16,
  sin alterar la matriz origen, guardados, RNG ni reglas tácticas.
- Publica `cell`, `kind`, `seen`, `visible`, `details`, conexiones
  de carreteras y bordes de costa *solo de celdas conocidas*.
- **Protección de niebla:** casillas desconocidas devuelven `kind=unknown`,
  sin revelar el relieve; una casilla ya explorada pero actualmente oculta
  conserva el tipo y omite decoración detallada, sin inventar unidades.
- El futuro renderer puede consumir esta salida por bloques en la cámara,
  mientras la lógica de juego sigue consultando `Rules` y el estado real.
- Esto **no habilita todavía** la vista 3D durante la batalla. Faltan:
  elección de LOD, sincronía con cámaras y zoom, edificios y unidades a
  escala de celda, picking táctil sin órdenes accidentales, ocultación por
  niebla en GPU, FPS y memoria reales en Android.

## Validación automatizada

- `tests/test_terrain_studio_bridge_v4.gd`: endpoints del puente al mismo
  nivel de carretera, transición sin saltos/overshoot, dos cruces, barandales,
  pilares agrupados, vuelta reversible a V2 y texturas en caché.
- `tests/test_terrain_visual_map_bridge_v4.gd`: cobertura exactamente una
  vez de cada casilla en los tres tamaños, no mutación de datos, niebla y
  conexión de carreteras/costas sin filtraciones.
- `tests/test_terrain_studio_3d.gd`: tres biomas con captura GPU real,
  comparación V1/V2, V2/V3 y específica V2/V4 del cañón.
- `.github/workflows/web-art-studio.yml`: ejecuta estas pruebas con
  Godot 4.3, exporta WebGL y archiva las capturas.

## Condiciones para integración

1. CI completo verde, incluidos renders y exportación WebGL.
2. Revisión visual de los dos puentes, el corte de las orillas, la textura
   bajo luz diurna/nublada, y la legibilidad de las tropas.
3. Perfil en Android físico para 24×18 y 40×30.
4. Mantener rama dependiente de #203; coordinar con el trabajo concurrente
   del tanque/cuarter general antes de integrar en el estudio.
5. La adaptación en tiempo real a las partidas necesitará un renderer
   dedicado por fragmentos y pruebas de fog/selección. Nunca cambiar
   balances, navegación, daño, economía o guardados al refinar materiales.

**Estado:** código de fase 4 en PR de revisión; no equivale a un arte final
comercial hasta superar las condiciones anteriores.
