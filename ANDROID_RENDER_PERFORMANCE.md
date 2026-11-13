# TARVOKA — optimización de mapas grandes en Android

Fecha: 12 noviembre de 2026. Rama `feat/mobile-large-map-performance-20261112` sobre la integración visual/táctica PR #148.

## Cambios aplicados

**Renderizado isométrico de 40×30**
- `VisualBudget.visible_grid_bounds` calcula un rectángulo conservador de casillas que pueden ocupar la pantalla, con márgenes generosos para edificios, unidades y efectos. El motor mantiene la profundidad de pintado sin recorrer todo el tablero cuando la cámara está ampliada o desplazada.
- Se calcula el origen de proyección solo una vez por cuadro; los centros y rombos de cada casilla se derivan directamente, eliminando cálculos repetidos.
- Las casillas bajo niebla *no exploradas* se pintan opacas **sin dibujar primero vegetación, agua o relieve oculto**, preservando privacidad y reduciendo trabajo gráfico.
- Los edificios, unidades, rutas y zonas de ataque fuera de pantalla se omiten. La lógica y la visibilidad real del juego no cambian.
- El nivel de detalle se adapta automáticamente al tamaño en píxeles de las casillas. Con poco zoom, las unidades se representan mediante marcadores contrastados y legibles; al acercar, vuelven las 128 figuras del atlas. A gran escala, los modelos de terreno decorativo se simplifican antes que las acciones o posiciones.
- `IsoRenderer.last_frame_stats` informa cantidad de casillas candidatas/pintadas, detalles decorativos y tropas en pantalla, para diagnosticar costo de dibujo sin alterar el estado táctico.

**Minimapa**
- El terreno conocido se convierte en una imagen miniatura transparente/coloreada de 10×8, 24×18 o 40×30. La textura se crea **solo cuando cambia el estado**, no cada vez que se arrastra la cámara.
- En cada desplazamiento solo se vuelve a dibujar la textura existente, las unidades e instalaciones visibles y el contorno de la cámara.
- La textura usa filtro de píxel más cercano para conservar las separaciones de casilla cuando se amplía.
- `BattleMinimap.cache_rebuild_count` y `cache_reuse_count` permiten comprobar las actualizaciones. La firma de estado se calcula a partir del dato real, no de un contador de acciones; así un estado restaurado o modificado externamente invalida el caché.
- La textura **jamás** representa posiciones de enemigos invisibles, propietarios no revelados o geografía no explorada. Los marcadores quedan filtrados por `Visibility`.

**Animaciones y batería**
- En mapas pequeños, animaciones ambientales cada 0.12 s; mapas medianos cada 0.20 s; mapas de ≥800 casillas cada 0.30 s.
- Botón **Ahorro de batería**, opcional y reversible, extiende la animación ambiental a 0.50 s y reduce la decoración. El combate y los desplazamientos mantienen su interpolación independiente de 0.32/0.55 s.
- El modo de ahorro y la posición de cámara no se incorporan a los guardados ni cambian ninguna regla.

## Verificación

`tests/test_mobile_visual_performance.gd` comprueba:
1. Que el recorte de pantalla jamás descarte un centro de casilla visible para varios tamaños, escalas y desplazamientos.
2. Que 40×30 simplifica decoración y reduce el número de casillas candidatas al ampliar/desplazar.
3. Que los enemigos desconocidos siguen ocultos y el renderizador no altera el estado.
4. Que el minimapa **reutiliza** su textura durante los movimientos de cámara, pero la reconstruye al cambiar los HP.
5. Que el modo ahorro reduce actualizaciones ambientales sin cambiar reglas ni guardados.
6. Que los controles Android activan/desactivan el modo sin modificar la partida.
7. Una observación de tiempo de dibujo en Godot headless registrada en el log CI; **no es una medición de FPS de móvil**.

## Restricciones

La optimización es independiente de la PR #148 y se mantiene experimental. La compilación Android y la suite de Godot deben estar verdes, pero el rendimiento real **todavía requiere pruebas en un teléfono** a 10×8/24×18/40×30, con y sin niebla, con número realista de unidades y tras 15–30 min de juego. No se declara FPS fijo, consumo de batería ni temperatura hasta hacer esas mediciones.

No se modifica balance, 32 roles, doctrinas de contraataque, alcance, IA, economía, visibilidad, formato de guardado ni identidad de las ocho facciones.
