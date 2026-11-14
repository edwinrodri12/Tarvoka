# TARVOKA — Fase 12: agua animada y bosques 3D con silueta natural

Estado: implementación experimental del **renderizador Godot 4.3** en la rama
`feat/connected-environment-map-20261113`. La vista 2.5D permanece como
opción por defecto. La vista 3D es voluntaria y sigue usando el mismo
`TouchBoard`, la misma niebla de guerra y las mismas órdenes.

## Agua 3D

- Nuevo `scripts/ui/TerrainWaterMaterial.gd`: shader espacial original
  (Compatibility/OpenGL) con oleaje y reflejos discretos en coordenadas
  **globales**, dos niveles de detalle y espuma estrecha cerca de orillas
  observadas. No desplaza vértices, no cambia terreno táctico ni simula
  física de fluidos. Los reflejos son aproximaciones procedurales, no
  reflejos físicos dinámicos.
- `Terrain3DMesh.gd` marca con alfa los bordes **de terreno visible** y el
  centro del cauce. El shader utiliza esa marca para mostrar espuma solo
  en orillas conocidas; no deduce costas ocultas bajo niebla. Los
  bordes acuáticos se retraen suavemente hacia el centro de cada casilla
  y conservan extremos compartidos sin huecos.
- En cruces confirmados por `TerrainTopology.bridge_axis`, el agua ahora
  continúa **por debajo del puente**: el suelo gráfico del centro de la
  carretera no tapa el río, y `bridge_water_outline` aporta la
  superficie acuática visual. El valor lógico de la casilla sigue siendo
  `road`, incluidos el movimiento y las órdenes. La transición no se
  dibuja si los vecinos necesarios no son visibles.

## Vegetación 3D

- Nuevo `scripts/ui/Conifer3DMesh.gd`: malla compartida con ramas
  escalonadas, bordes aserrados y copas ligeramente asimétricas; tres
  niveles de ramas en calidad completa y dos en calidad móvil.
- `terrain3d_lab.gd`: usa un `MultiMesh` por bosque para todas las copas
  y otro para los troncos. Escala, rotación y color por árbol provienen
  de semillas estables, no de iteraciones aleatorias. La versión móvil
  utiliza menos geometría, manteniendo la misma máscara de bosque
  y los mismos controles táctiles.
- Esta es una mejora de arte procedural; los pinos todavía NO son
  modelos de producción con texturas PBR o viento físico.

## Pruebas

`tests/test_native_terrain3d.gd` valida mallas de árboles full/mobile,
variación de detalle, shader y parámetros, existencia y privacidad
de espuma en orillas, continuidad del río bajo el puente, preservación
de la casilla `road`, geometría ausente bajo niebla y tamaños
10×8 / 24×18 / 40×30. `native-terrain3d-preview.yml` exporta de
Godot capturas full/mobile y la misma batalla en 3D/2.5D para revisión
sin APK. `godot-rules.yml` y `android-debug-apk.yml` verifican
integridad de reglas y exportación de Android.

**Criterio antes de fusionar:** todas las pruebas verdes en el commit
más reciente; mapa sin costuras y puentes continuos; comprobar FPS,
calentamiento y transparencia del agua en Android físico. Evitar fusionar
PR #183 antes de resolver conflictos con `main` y la integración con
modelos 3D de unidades/edificios que evolucionan en paralelo.
