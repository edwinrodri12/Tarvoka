# TARVOKA — Fase V5: el terreno 3D dentro de la partida real

## Objetivo cumplido en esta rama

Al iniciar una partida normal de Android, el usuario puede abrir la nueva
opción **Mapa de batalla 3D · inspección** del menú lateral o **Mapa 3D**
del HUD horizontal compacto.

Se abre una ventana 3D sobre la partida activa, no un escenario inventado:

- `BattleTerrain3D.gd` recibe el estado que usa `TouchBoard` y consulta
  únicamente `TerrainVisualMapBridge3D.collect()`, en sectores 8×8.
- La geometría muestra bosques (instancias de malla compartida), montaña,
  planicies, agua, red de carreteras y orillas. Respeta las dimensiones 10×8,
  24×18 y 40×30.
- Muestra las unidades realmente presentes; utiliza los modelos 3D originales
  disponibles hasta un presupuesto de ocho por vista. Las restantes usan
  marcadores ligeros. Los edificios económicos y relés tienen geometría
  provisional, no copias de los acabados comerciales definitivos.
- Con niebla, las casillas no exploradas se dibujan como superficie opaca y
  **no reciben topología, árboles, instalaciones ni enemigos**. Las
  exploradas fuera de visión conservan el tipo de casilla atenuado, sin
  revelar ocupantes/propietarios de instalaciones ocultas.
- `Battle3DMapView.gd` permite girar la cámara, acercar/alejar e inspeccionar
  una celda con el dedo o ratón. **No permite mover ni atacar**: al cerrar
  únicamente solicita centrar la cámara del tablero activo en la celda
  inspeccionada, mediante `TouchBoard.focus_view_cell()`.
- La ventana 3D detiene su renderizador y destruye la escena visual cuando
  se cierra. Nunca se agrega información nueva al estado serializable.

## Arquitectura y garantías

```text
TouchBoard.state  [autoridad: unidades, niebla, IA, combate, economía]
        |
        +---> TerrainVisualMapBridge3D.collect [solo lectura + mascara fog]
                     |
                     +---> BattleTerrain3D.build
                                 |  chunks 8x8, mallas visuales
                                 |  modelos y marcadores V3/V4
                                 +---> Battle3DMapView
                                               | tocar = inspeccionar
                                               | cerrar = enfocar 2D
                                               +---> TouchBoard.focus_view_cell
                                                     (ninguna orden)
```

Esta fase no reemplaza `IsoRenderer.gd`, no altera `Rules.gd`,
`BattleSession.gd`, `TouchBoard.gd`, guardados JSON, combate, costes
de movimiento, defensas por altura ni los comandos de producción.

## Verificación técnica

- `tests/test_battle_terrain_3d_v5.gd`: builds de los tres tamaños reales,
  conservación exacta del estado, recuento de sectores, ausencia de enemigos
  fuera de visión, detalles solo en casillas vistas, y render al ser visible.
- `tests/test_battle_3d_map_ui_v5.gd`: abre la escena Android `Main.tscn`,
  activa la cámara y la UI real, inspecciona en 10×8 y 40×30, comprueba que no
  se alteran órdenes ni selección y produce capturas de GPU:
  `tarvoka_battle_3d_live_10x8.png` y
  `tarvoka_battle_3d_live_40x30.png`.
- `.github/workflows/web-art-studio.yml`: Godot 4.3 con OpenGL de software
  y Xvfb, tests de geometría + UI, exportación WebGL, artefactos PNG.
- Mantiene las pruebas originales de modelos y edificios del Estudio 3D.

## Criterios pendientes antes de vista 3D táctica completa

1. **Picking exacto sobre montaña y modelos**, no solo intersección aproximada
   de rayos con un plano de altura media.
2. Gestos táctiles: pinch de dos dedos, arrastre de cámara con cancelación de
   órdenes, zoom anclado y visibilidad de unidades sobre distintos relieves.
3. Overlays de movimiento/ataque, animaciones, efectos, colores de comandantes
   e instalaciones comerciales finales en un único espacio 3D.
4. LOD/chunks en tiempo real para 1200 celdas, medición de FPS y batería
   en teléfonos y tabletas Android, reciclaje de modelos al panear.
5. Integración cuidadosa con cambios paralelos del tablero y HUD antes de
   fusionar: esta PR está **apilada sobre V4**, no sobre `main`.

**Importante:** la ventana V5 es una vista de inspección de batalla real,
no un reemplazo ya terminado de la interfaz táctil. La separación evita
regresiones en selección y órdenes existentes.
