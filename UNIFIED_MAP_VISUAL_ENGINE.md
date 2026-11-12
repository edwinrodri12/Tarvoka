# TARVOKA — motor táctico + arte isométrico + minimapa unificados

Fecha de integración: **12 de noviembre de 2026**. Rama `feat/unify-large-maps-isometric-20261112`, PR #148, apilada sobre el motor ampliado de la PR #147.

## Resultado en la app Android

En **Nueva partida** se conserva el selector de mapas, la semilla reproducible y el menú **Tamaño del campo de batalla**:

| Mapa | Casillas | Vistas disponibles |
| --- | ---: | --- |
| Clásico | 10×8 | Clásica / Isométrica |
| Grande | 24×18 | Clásica / Isométrica |
| Estratégico | 40×30 | Clásica / Isométrica |

El botón **Vista isométrica / Vista clásica** cambia la presentación de la **misma partida**. Los botones **+ / − / Centrar** operan sobre la cámara activa. En la vista clásica se puede arrastrar el tablero; en isométrica también, y tocar o arrastrar sobre el **minimapa** centra la cámara sin ejecutar movimientos ni ataques.

En isométrica aparecen siluetas originales rasterizadas y reutilizables de 32 roles con 4 poses (128 fotogramas, por ahora arte técnico), siete tipos de edificios, relieve, agua y marcadores de objetivos. La galería permite ver las unidades en sus distintas poses, ocho direcciones y los ocho colores aprobados.

## Política de implementación

- **La lógica no depende de los sprites**: movimiento, ocupación, daño, contraataque, captura, producción, visión e IA consultan el estado `Vector2i` y las dimensiones del terreno validado.
- **Proyección dinámica**: `IsoProjection.center()`, `diamond()`, `screen_to_cell()` y `half_width()` reciben un tamaño explícito. `IsoRenderer.draw_board()` lo obtiene de la matriz real; `BattleVFX` emplea ese mismo tamaño al trazar proyectiles.
- **Niebla sin filtraciones**: el minimapa usa `Visibility.visible_cells` y `explored_cells`; no muestra unidades enemigas ocultas ni terreno no descubierto. El dibujo de movimiento enemigo comprueba ambos extremos visibles.
- **El minimapa no da órdenes**: `BattleMinimap._focus()` solo llama a `TouchBoard.focus_iso_cell()` y modifica `iso_pan`.
- **Cámaras distintas y no persistentes**: `view_pan/view_zoom` y `iso_pan/iso_zoom` son solo de interfaz; la partida y sus guardados JSON v1 no cambian al alternar, hacer zoom o arrastrar.
- **Se mantienen cambios tácticos recientes**: la PR parte del motor de la #147, basado en `main` después de la introducción de contraataques por roles y de la inspección táctica de unidades. No copiamos el antiguo `TouchBoard.gd` de las ramas visuales por encima de esas reglas.
- **Recursos reproducibles**: en la compilación Android, Godot rasteriza el atlas de 128 fotogramas y lo empaqueta en el APK ARM64. También publica PNG y manifiesto JSON como artefactos descargables.

## Verificación automática

`tests/test_unified_visual_maps.gd` ejecuta las tres dimensiones con niebla, escenario moderno aleatorio, relés y economía. Comprueba: reversibilidad de toque isométrico y proyección; renderizado headless sin mutar el estado; minimapa sin información oculta; centrado táctil; movimiento ordenado por toque sobre la proyección; serialización exacta; alternancia de vista; creación de partidas de 24×18/40×30 desde la interfaz Android.

Además siguen ejecutándose los tests originales de `test_minimap_vfx.gd`, `test_sprite_atlas.gd`, `test_unit_art.gd`, `test_isometric_board.gd` y **toda la batería de simulaciones y reglas del motor actual**. La prueba de vista usa botones de zoom comunes en ambas vistas, evitando una segunda fila de controles duplicados.

## Limitaciones pendientes

1. **Arte técnico, no definitivo**: los emblemas/personajes aprobados de las ocho facciones no se consideran importados por este cambio, y las 32 unidades necesitan una última aprobación artística.
2. **QA en dispositivos reales**: comprobar legibilidad de unidades, desempeño a 40×30, gasto de batería y desplazamiento de la cámara en distintos tamaños de teléfono/tableta.
3. **Rendimiento a gran escala**: el minimapa analiza hasta 1200 casillas; el render isométrico usa culling básico, no atlas de terreno chunked ni nivel de detalle avanzado. No se declara un FPS mínimo hasta medir hardware.
4. **Campaña y multijugador**: los 50 capítulos, futuros mapas en red y servidores no se incorporan con este PR; solo se unifica el motor de escaramuza actual.

## Orden de fusión

PR #147 (motor grande) → **PR #148 (integración)**. Las ramas visuales #139, #142, #144 y #145 son fuentes históricas de esta integración, pero no deben fusionarse después copiando sus versiones antiguas de `Main.gd` o `TouchBoard.gd`, porque sobreescribirían los límites dinámicos y las reglas nuevas. Mantener #148 en borrador hasta la validación completa y prueba Android manual.
