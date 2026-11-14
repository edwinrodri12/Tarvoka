# TARVOKA Estudio 3D — Integración del entorno (fases 1–15)

La galería web del proyecto ahora ofrece tres categorías dentro del **mismo lienzo Godot 4.3**: UNIDADES, EDIFICIOS y ENTORNO Y MAPA 3D.

## Procedencia y fidelidad
- El modo nuevo importa los módulos originales del laboratorio de terreno de la rama `feat/connected-environment-map-20261113`, verificados hasta la revisión `74738489dec482c1565aada5e4ca2f2cb42fcb42`, sin reescribir los modelos de roca, vegetación o ríos con dibujos de muestra.
- Los módulos importados son `Terrain3DMesh`, `Terrain3DChunkCache`, `TerrainTopology`, `LandscapeRegions`, `TerrainRockMaterials`, `TerrainWaterMaterial`, `TerrainShore3D`, `TerrainUnderstory3D`, `Conifer3DMesh`, `tools/terrain3d_lab.gd` y `scenes/Terrain3DLab.tscn`.
- `terrain3d_lab.gd` tiene una nueva opción `embedded_in_studio` para no duplicar la iluminación ni tomar el control de la cámara del visor de unidades/edificios. La malla 3D es la misma del laboratorio de batalla, no una captura PNG ni una reinterpretación visual independiente.
- La app Android y los modelos existentes de unidades/cuatrales no se sobrescriben. El visor del estudio sirve para revisar acabados, no para enviar órdenes tácticas.

## Lo que puedes visualizar
- Montañas de distintas alturas, roca estratificada y relieve continuo, biomas con transiciones orgánicas, carreteras, puentes con río que corre debajo y riberas erosionadas.
- Coníferas de tres perfiles, arbustos de borde, sotobosque por lotes MultiMesh y material de agua con corrientes/reflejos simulados.
- Escenario original de 15×10, dos mapas alternativos (20×14, 24×18) y vista grande de 40×30 para revisar escala.
- Calidad completa (copas con viento y sombras) frente a calidad móvil más austera; demostración de niebla con visibilidad por sectores 8×8; cámara con giro, zoom, reset y enfoque en bosque/río/cordillera.

## Validación y publicación
- `tests/test_web_terrain_studio.gd` exige que una escena de verdad cargue el terreno, su malla de agua y MultiMesh de árboles; cambia los tres estados, hace zoom, cambia calidad/niebla y regresa a los modos Cuartel General y Tanque preservando las ocho facciones.
- `studio-environment-smoke.yml` ejecuta prueba Godot con OpenGL/Xvfb y exporta un Web Studio de Godot 4.3 verificable a un artefacto separado. `web-art-studio.yml` agrega la prueba a las verificaciones de publicación ya existentes, incluyendo los acabados HQ V10.
- El proyecto **sigue en ramas separadas**: los cambios de terreno para Android viven en la PR #183 (no fusionada). El estudio web es una integración visual específica, no una fusión automática con `main`. Los posteriores cambios del terreno deben sincronizarse intencionalmente para evitar sobreescribir los avances paralelos de HQ y unidades.
- Si el sitio de GitHub Pages parece antiguo, actualizar la página con Ctrl+F5 y comparar la revisión GitHub del panel.

**Limitación:** estas geometrías son 3D low-poly originales renderizadas en Godot Compatibility/WebGL; todavía no son materiales comerciales finales ni pruebas de FPS/temperatura de Android físico.
