# TARVOKA — entorno y mapa 3D en el Estudio Web

**Alcance:** prototipo visual nativo de Godot 4.3, independiente de las reglas de combate. Se revisa desde el mismo `UnitArtStudioWeb.tscn` que muestra las unidades y edificios.

## Cómo inspeccionarlo sin APK

Abre el Estudio 3D publicado desde la rama de integración. En **Categoría**, selecciona **ENTORNO Y MAPA 3D**. Elige un escenario (Valle boscoso, Cañón rocoso, Delta costero). Utiliza **Girar**, **Acercar**, **Alejar**, **Restablecer cámara**, y arrastrar o pellizcar sobre el visor. Alterna la cuadrícula para analizar legibilidad de casillas, cambia **Iluminación** para revisar materiales y usa **Ver tanque y edificio en el terreno** para estudiar proporciones.

Las referencias de tanque y edificio son copias de los constructores reales `UnitModels3D.build()` y `Headquarters3D.build()`. Sus escalas en este diorama están reducidas **solo para inspección visual**, y no representan una escala táctica aprobada.

## Implementación

- `scripts/ui/TerrainStudio3D.gd`: generador determinista de 12×10 celdas con volúmenes 3D nativos, cinco clases visuales (llanura, bosque, montaña, agua, carretera), relieve escalonado, vegetación low-poly, orillas y marcas viales.
- `scripts/ui/CombinedArtStudioWeb.gd`: tercera categoría en el visor existente, con opciones de terreno, cuadrícula, modelos de referencia, tres modos de luz y zoom/rotación.
- `tests/test_terrain_studio_3d.gd`: revisa los tres escenarios, conteo de casillas, cambio de categoría, referencias de escala, controles, luz y una captura desde el render real `artifacts/tarvoka_terrain_studio_3d.png`.
- `.github/workflows/web-art-studio.yml`: integra la prueba de terreno en la exportación web y hace fallar el trabajo si no renderiza la captura.

## Límites conocidos — no declarar acabado final

Este primer pase valida composición y la integración del visor. **No sustituye el motor isométrico de batalla actual**, ni modifica `Vector2i`, costes de movilidad, bonificaciones por altura, niebla de guerra, navegación, saves, IA o Android.

Las carreteras tienen continuidad *visual*, no nuevos valores de movimiento; las montañas muestran relieve pero su transitabilidad sigue definida por el motor táctico actual. El agua es una superficie geométrica de prueba sin simulación de oleaje ni puentes funcionales. La cuadrícula contiene exactamente 120 casillas; no se extrapola aún a mapas de 24×18 o 40×30. Faltan UV y materiales/texturas finales, bordes sin discontinuidades para mallas grandes, props diferenciados por bioma, pruebas de FPS/memoria en Android y validación visual manual en navegador.

## Criterio para continuar

No integrar terreno 3D a la batalla hasta que se definan altura por casilla, accesibilidad por tipo de unidad, puentes, costes en carretera, oclusión, LOD/instancing y presupuesto de render para Android. Mantener los mismos datos tácticos del motor existente como fuente única de verdad.
