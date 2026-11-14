# TARVOKA — Fase 10: paisaje como regiones continuas

**Alcance:** solo arte ambiental de mapa. No toca `Rules`, rutas jugables, defensa por elevación, niebla táctica, batallas, UI, modelos de unidades o edificios ni guardado.

## Implementación

- `scripts/ui/LandscapeRegions.gd` define perfiles espaciales estables de relieve y vegetación basados en las coordenadas del mundo, no en el turno ni el reloj. Incluye la fuerza de las cumbres de un macizo, densidad de pinos, textura verde de sotobosque y bandas de transición entre biomas.
- `LandscapeDetailPainter.gd`: los macizos conectados tienen **pocas cumbres dominantes y muchas estribaciones bajas**, con nieve reservada para algunos picos principales. El bosque integra una cubierta del suelo con conectores a los vecinos conocidos, grupos de árboles de tamaño/densidad variables y vegetación pequeña.
- `WorldArt.gd` y `IsoRenderer.gd`: las transiciones pradera/bosque/montaña se pintan solo dentro de la casilla actual y **solo** cuando el tipo y color del vecino está disponible según la niebla de guerra. Agua y carreteras conservan sus pinturas especiales y su legibilidad.
- `tools/export_environment_preview.gd`: el laboratorio 2.5D utiliza los mismos perfiles y colores que una batalla jugable. No usa una ilustración independiente.
- `Terrain3DMesh.gd`: la altura real del terreno 3D y sus tonos de roca/nieve varían a escala de región; la deformación añadida se anula en todos los límites de las casillas para no producir grietas.
- `tools/terrain3d_lab.gd`: reusa la densidad regional de pinos respetando los vecinos visibles. Cada árbol tiene dos pisos de copa renderizados en un `MultiMesh` por calidad para moderar consumo de GPU.

## Validación automatizada

- `tests/test_landscape_regions.gd`: pruebas de combinaciones 0–15 de vecindad y distintos lugares, variación regional determinista, predominio de estribaciones, densidades forestales diferentes, mezcla de suelo dentro del diamante y ausencia de filtración de vecinos no observados.
- `.github/workflows/map-art-previews.yml`: ejecuta la prueba regional y exporta PNG de calidad completa/media desde Godot; archivos `tarvoka-environment-preview`.
- `.github/workflows/godot-rules.yml`: integra la prueba regional en la batería general.
- `.github/workflows/native-terrain3d-preview.yml`: mantiene la escena 3D real con tests de malla, cámaras e integración del modo experimental.
- `android-debug-apk.yml`: debe compilar de nuevo antes de fusionar; el proyecto mantiene la vista 2.5D como predeterminada.

**Limitaciones reconocidas:** las montañas 2.5D aún utilizan facetas geométricas y la interfaz móvil puede cubrir unidades en el borde inferior. La capa 3D tiene iluminación y geometría real, pero sus materiales y árboles son todavía low-poly. Mejorar estas áreas y QA en dispositivo antes de llamar al juego comercialmente terminado.

## Continuidad y seguridad

El borde geométrico de cada casilla y sus coordenadas `Vector2i` siguen intactos; todas las diferencias son visuales. Si una casilla vecina está oculta, el pintor no conoce ni deduce su material. Los enlaces visuales de bosque, montaña y agua se derivan exclusivamente de máscaras de vecindad visibles. Mantener PR #183 en borrador hasta completar revisión de conflictos con `main`, capturas de batalla y CI.
