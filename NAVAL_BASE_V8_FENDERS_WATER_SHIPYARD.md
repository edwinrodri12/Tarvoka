# TARVOKA — Base Naval V8: defensas neumáticas, espuma portuaria y conexión del astillero

## Objetivo visual
Perfeccionar la Base Naval existente en Godot 4.3 sin reemplazar su arquitectura ni sus modelos anteriores. La octava capa se apoya en V1–V7 y solo añade mallas y material originales. **No** implementa física naval ni combate, y no altera producción, economía, navegación o colisiones.

## Cambios en 3D
- **Defensas neumáticas reales:** cilindros de goma con anillos, herrajes de sujeción superior/inferior y cadenas del lado interior de cada espigón. En la fachada del muelle Este se superponen cuidadosamente a las defensas originales V1–V2 y se conservan juntas húmedas. Las defensas se rompen o desaparecen según el estado de daño; ninguna defensa intacta se coloca sobre el espigón que desaparece en daños 3–4.
- **Contacto agua/muelle:** delgadas franjas intermitentes de espuma *sobre la superficie marítima V2* (y=0.061 frente a y=0.046). Nuevo shader espacial `naval_contact_foam_v8.gdshader` con movimiento suave y transparencia controlada; no incluye una segunda superficie marítima masiva, reflexión cara, física de fluidos, nueva iluminación o mapas de sombras.
- **Servicio y drenaje:** canaletas y rejas de drenaje junto al muelle, conexiones de alimentación de la rampa de embarque al circuito de servicios en niveles 2–3. No hay puentes falsos atravesando el canal de navegación. Se degradan de forma progresiva y son escombros si el edificio queda destruido.
- **Zoom táctico:** mallas simplificadas para defensas y líneas de contacto reemplazan microherrajes al alejar la cámara; usa el umbral de `_zoom >= 0.85` ya establecido en V6/V7.
- **Modo nocturno:** emisores muy suaves cerca de las defensas existentes, y espuma atenuada por factor 0.42; el interruptor nocturno de V6 controla ambos sin cambiar las opciones de cámara ni las facciones.

## Integración en el estudio
Selector **Base Naval V8** → nueva casilla **V8 · defensas, espuma y drenajes (comparar V7)**. Mantiene comparación V1–V7, facciones, giro, zoom, vistas desde el mar, niveles 1–3 y daños 0–4. Desactivar V8 recrea la V7 original sin modificaciones.

## Archivos y QA
- `scripts/ui/NavalFendersV8.gd`
- `assets/shaders/naval_contact_foam_v8.gdshader`
- `scripts/ui/CombinedArtStudioWeb.gd`
- `tests/test_naval_base_v8_gpu.gd` y `.github/workflows/naval-base-v8-gpu.yml`: validación Godot 4.3/OpenGL de 40 combinaciones de facción/daño, 3 niveles, cambios con zoom y noche, y ocho capturas del Estudio real.

**No afirmar pruebas aprobadas hasta que GitHub Actions finalice correctamente.** La versión de Android, sus FPS y la interoperabilidad con naves quedan fuera del diseño visual. Siguiente etapa: inspeccionar detalles y ajustar escala/repetición visual tras ver las capturas auténticas.
