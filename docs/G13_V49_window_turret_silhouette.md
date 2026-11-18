# G13 V49 — continuidad del modelado 3D de cabina, torreta y techo

**Entrega real:** módulo Godot 4.3 `scripts/ui/G13SeamlessSilhouetteV49.gd` en `edwinrodri12/Tarvoka`. Es geometría `ArrayMesh` creada en el motor, no una imagen ni una maqueta. La V49 no queda aprobada hasta ver las nuevas capturas de Godot.

## Contexto y prioridad

Tras revisar el artefacto de once capturas auténticas del Estudio 3D obtenido en el run exitoso #1508, el usuario insistió en alcanzar el nivel artístico de las unidades ya aprobadas. V48 reemplazó las tres formas principales; V49 pule especialmente **los hombros junto a las ventanillas**, la transición entre cinturón y coronación de torreta y el perfil del techo. Se evitan adornos que no modifiquen la lectura del vehículo a distancia de juego.

## Modificaciones 3D reales (sin nuevos draw nodes)

| Recurso existente | V48 | V49 | Beneficio |
|---|---:|---:|---|
| Cabina cerrada | 6 anillos / 96 triángulos | **8 anillos / 128 triángulos** | Mayor continuidad desde el parabrisas al costado del vidrio y el techo |
| Carcasa de torreta cerrada | 6 anillos / 96 triángulos | **8 anillos / 128 triángulos** | Cinturón blindado escalonado, sin saltos grandes de sección |
| Techo blindado cerrado | 4 anillos / 64 triángulos | **5 anillos / 80 triángulos** | Borde exterior biselado y unión mejor graduada con los refuerzos V37 |

La cabina de V11 tiene cristales laterales originales con X=±0.566 en Y=1.140 y X=±0.516 en Y=1.280. V49 sitúa la superficie lateral del casco cerca de X=±0.556 en Y=1.155 y X=±0.508 en Y=1.280. Así **el vidrio puede sobresalir unos milímetros respecto al acero en lugar de quedar hundido en el volumen opaco**. Las piezas de vidrio, sus vértices y el pivote de cabina no se modifican.

La torreta se remodela manteniendo X máximo=±0.518 para conservar los emblemas ya ajustados en V48 y la base de giro. La cubierta mantiene Y máxima=1.438, por debajo de la arista de refuerzo de techo V37 a Y=1.455.

## Integración y comparación en el mismo modelo

- `scripts/ui/UnitModels3D.gd`: aplica V49 inmediatamente después de V48 en LOD13 y LOD8, dejando intactas las demás unidades, reglas y estadísticas.
- `scripts/ui/BastionStudioAdapter.gd`: selector **G13 V49**, botones **Contornos integrados 3D** y **Comparar con V48**. Intercambian los tres `ArrayMesh` reales sin crear mallas falsas, ni alterar la cámara, el color de facción, dos cañones o radar.
- `tests/test_g13_studio_web_v1.gd`: comprueba 128/128/80 triángulos, compara contra los recursos V48 de 96/96/64, restaura V49, valida materiales y los dos LOD, y sigue protegiendo la versión aprobada de G11.
- `tests/test_g13_v49_visual_capture.gd` y `.github/workflows/tarvoka-3d-pages.yml`: preparan ocho vistas 1280×720 del LOD13, una comparación exacta V48/V49 desde el lateral, y dos capturas del LOD8, con manifiesto. El workflow recoge `build/qa/g13-v49/*.png` en el artefacto **`tarvoka-g13-v49-native-360-design`**. El histórico de V43 se preserva en runs anteriores.

## Restricciones y verificación

La G13 conserva cuatro ruedas, dos autocañones y **cero misiles**, el radar con su articulación, las ocho paletas existentes y las animaciones. No se crean nuevos nodos de dibujo; se reemplazan tres recursos cerrados. **No hay cambios de jugabilidad.**

La existencia del código y de las rutas de integración no prueba que el resultado visual sea perfecto. El ciclo correcto es: comprobar el run de GitHub Actions y las once capturas de V49, corregir cualquier defecto observado (por ejemplo, intersecciones de vidrio y blindaje) y solicitar aprobación antes de cerrar el modelado.
