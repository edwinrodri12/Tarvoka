# TARVOKA — Visor 3D de batalla V6: selección precisa, gestos y alcances

## Resultado funcional

La vista **Mapa de batalla 3D · inspección** de V5 continúa siendo de
solo lectura: ningún toque de la ventana ejecuta movimiento, ataque,
producción, cambio de turno o selección autoritativa.

### Selección exacta en relieve

`BattleTerrainPicker3D.gd` sustituye la intersección previa con el plano
Y=0.18 por intersección rayo-triángulo (Möller–Trumbore bilateral) con
los **mismos cuatro triángulos y alturas** que genera
`BattleTerrain3D.gd`. Para agua y niebla usa los dos triángulos planos
realmente dibujados. Devuelve el impacto más cercano con:
`cell` (Vector2i), `position` (Vector3), `distance`, `kind` y
`seen`, sin leer datos tácticos desconocidos.

La conversión entre coordenadas del `SubViewportContainer` y el
`SubViewport` corrige las pantallas que escalan el render en modo
horizontal o tablet. Los rayos son del motor Godot, sin crear
colisiones 3D para unidades o estructuras.

### Mando de cámara sin órdenes

- **Un dedo:** tocar brevemente inspecciona; arrastrar desplaza la
  cámara proyectando ambos puntos a un plano de navegación.
- **Dos dedos:** distancia controla zoom con anclaje en el punto medio;
  trasladar el par desplaza la cámara; rotar los dedos gira el azimut.
- Al soltar los dedos tras un gesto, se **suprime el tap final**.
- Los clicks de ratón se confirman en release, no press; arrastrar
  con ratón desplaza sin seleccionar; rueda hace zoom anclado.
- Se ignoran los clicks sintéticos procedentes de eventos Android
  táctiles para no seleccionar dos veces.
- Se mantienen botones `+`, `−`, `Girar` y `Cerrar`.

### Alcances basados en el motor real

`BattleRanges3D.gd` **no contiene reglas propias de movimiento o
armamento**. Solo consume las funciones de interfaz oficiales:

- `TacticalHints.for_unit(state, unit_id).moves`: **azul** (celdas
  donde la unidad puede terminar movimiento ahora).
- `TacticalHints.friendly_weapon_coverage()`: **naranja**
  (huella potencial tras mover o desde la posición actual; no
  autoriza ataque sin una orden y no significa fuego inmediato).
- `TacticalHints.for_unit().attacks`: **rojo**
  (enemigos a los que se puede atacar en el estado actual).

Prioridad de pintura: rojo sobre azul sobre naranja. Un mismo terreno
puede pertenecer a varias categorías del cálculo oficial pero se
colorea una sola vez para no oscurecer el terreno. Las capas visuales
son mallas transparentes siguiendo la altura real de cada casilla y
**solo se dibujan si esa casilla está visible**. No se filtra
información de enemigos ni del terreno no explorado.

El usuario puede tocar un aliado para cambiar el objetivo de guías
**localmente en el visor 3D**, sin tocar `TouchBoard.selected_id`.
El botón **Alcances** activa/desactiva el resultado.

## Comprobaciones automatizadas

- `tests/test_battle_3d_picking_v6.gd`: 10×8, 24×18 y 40×30,
  rayos en centros y puntos fuera del centro, montaña, agua, niebla y
  rayos oblicuos; las alturas de impacto deben igualar la malla.
- `tests/test_battle_3d_ranges_v6.gd`: compara conjuntos/costes con
  las salidas de `TacticalHints`; niebla, objetivos y no mutación.
- `tests/test_battle_3d_gestures_v6.gd`: ejecución con Godot GPU,
  pantalla horizontal y eventos de toque y ratón reales simulados;
  valida pinch, giro, paneo, selección precisa y captura
  `artifacts/tarvoka_battle_3d_v6_ranges.png`.
- El pipeline también conserva todas las pruebas V1–V5, WebGL,
  APK Android y motor táctico.

## Restricciones de lanzamiento

Esta fase sigue siendo una **vista de inspección**, no un controlador
de órdenes 3D. La futura selección de acciones necesita su propia
confirmación explícita, identificación de capas tierra/aire, objetivos
múltiples, reglas de ocupación y decisiones de seguridad en niebla.

Antes de fusionar o declarar calidad comercial deben verificarse
capturas de GPU, perfiles FPS/memoria en Android físico y convivencia
con los PR paralelos de modelos/edificios y HUD. La PR V6 está apilada
sobre V5 #224, V4 #219 y V3 #203, sin portar código antiguo sobre main.
