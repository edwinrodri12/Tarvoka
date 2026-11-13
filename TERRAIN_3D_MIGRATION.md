# TARVOKA — Primer terreno 3D modular (fase 7)

**Estado:** prototipo gráfico nativo dentro de Godot 4.3. El tablero jugable sigue empleando `IsoRenderer.gd` y su representación 2.5D. Esta fase no reemplaza todavía la cámara, el selector táctil, la niebla de guerra interactiva ni el HUD.

## Arquitectura

- `scripts/ui/Terrain3DMesh.gd`: convierte la cuadrícula estratégica **sin modificarla** en una superficie 3D real (`ArrayMesh` con normales y `StandardMaterial3D`). Los vértices compartidos usan alturas calculadas en las esquinas globales, evitando grietas entre casillas adyacentes. Montañas con volumen, pendientes y estratos de color, sin alterar sus bonificaciones defensivas.
- `Terrain3DMesh.build_water()`: genera la superficie acuática con `ArrayMesh` independiente y borde retraído en los lados que tienen tierra **visible**; si el vecino está oculto no lee ese tipo de terreno. Se puede reemplazar más adelante por un material acuático con animación/normal map, sin tocar las reglas.
- `tools/terrain3d_lab.gd` y `scenes/Terrain3DLab.tscn`: escena ejecutable nativa con cámara ortográfica, luz direccional, vegetación 3D agrupada mediante `MultiMeshInstance3D` y mallas de terreno/agua. `set_terrain(grid, visible, restrict)` acepta la cuadrícula del motor y un diccionario de celdas visibles. La escena no admite estado táctico mutante.
- `tools/export_terrain3d_preview.gd`: exporta capturas de **render 3D real** a detalle completo y móvil, sin instalación Android.
- `tools/terrain3d-gallery.html`: visor sin conexión con comparación frente a los conceptos aprobados de *Operación Río Azul*.
- `.github/workflows/native-terrain3d-preview.yml`: compila y ejecuta los tests de geometría/niebla, rasteriza la escena mediante Godot y publica `tarvoka-native-terrain3d-preview` en GitHub Actions.
- `tests/test_native_terrain3d.gd`: continuidad a través de límites E/O y N/S, superficie acuática, inmutabilidad de la matriz táctica, ocultamiento de terreno bajo niebla y generación para mapas 10×8, 24×18 y 40×30.

## Revisión sin APK

1. Abrir `scenes/Terrain3DLab.tscn` en Godot 4.3 y ejecutar la **escena actual** (no cambiar la escena principal del proyecto).
2. O bien abrir GitHub Actions → **TARVOKA native terrain 3D lab (no APK)** → descargar el artefacto `tarvoka-native-terrain3d-preview`.
3. Descomprimir, abrir `index.html` y alternar la calidad completa/móvil; importar localmente el arte aprobado en el panel derecho.
4. Evaluar la geometría y la iluminación, el corte de riberas, los bosques y el rendimiento. Las capturas 3D **no** demuestran jugabilidad ni equivalencia con el arte final.

## Invariantes

- Los terrenos de la simulación siguen siendo `plain / forest / mountain / road / water`; ningún bioma nuevo se introduce en reglas o guardados.
- Elevaciones 3D son **solo** para representación; combate, cobertura, velocidad, suministro, alcance, construcción y clic táctico permanecen en el motor de reglas actual.
- El render usa únicamente información del conjunto de celdas observadas cuando se habilita `restrict_to_observed`.
- No se han cambiado HUD, unidades, facciones, edificios ni las escenas de campaña.

## Próximos hitos para integración jugable

1. Cámara 3D panorámica y conversión de toques/rayos a la misma casilla `Vector2i`, validada con niebla, pinch zoom y minimapa; mantener la representación actual como fallback.
2. Ríos orgánicos de ancho variable, orillas 3D y puentes físicos **solo gráficos** generados de conexiones verificadas, además de materiales de roca/vegetación más elaborados.
3. Selección automática de LOD según zoom y batería, perfiles de calidad Android, medición de FPS y memoria en mapas 40×30 reales.
4. Integración gradual en la escena de batalla solo tras comparaciones visuales y pruebas de todas las acciones tácticas. No fusionar directamente un visor experimental como sustitución del juego.

**Limitación vigente:** este primer escenario es un prototipo con mallas reales, pero utiliza materiales simples y copas de árbol low-poly. No es aún un paisaje 3D de calidad comercial y no incluye unidades ni edificios.
