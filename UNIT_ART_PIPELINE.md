# TARVOKA — segunda pasada artística isométrica (32 unidades)

Fecha: 2026-11-12. Implementación experimental apilada sobre PR #139. El prototipo de batalla usa las mismas coordenadas 10×8, las mismas normas de fog y el mismo formato de guardado.

## Lo implementado

- **32 siluetas originales y escalables**: cinco clases fundamentales (`line`, `scout`, `bulwark`, `piercer`, `artillery`) y 27 contemporáneas (`ModernArsenal.ORDER`). Cada combinación familia/variante es única. `scripts/ui/UnitArt.gd`.
- Siluetas visuales diferenciables: equipo de infantería (escudos, armas y herramientas), vehículos de ruedas/orugas (torretas, lanzaderas, sensores y antenas), drones, helicópteros, cazas, bombarderos, embarcaciones y submarino. **No son aún renders 3D ni sprites definitivos de estudio**.
- **Terreno**: variaciones deterministas de árboles, nieve/roca en cumbres, carreteras y agua con ondas; `scripts/ui/WorldArt.gd`.
- **Siete edificios productivos**: ciudades, talleres, blindados, depósito de artillería, centro de drones, aeródromo y astillero, con color por propietario conocido. Relés representados como torres.
- **Animación**: interpolación visual de movimiento de 0,32 s, ondas y hélices; destellos de combate anteriores se mantienen. Ninguna animación retrasa el turno ni añade estado a la partida.
- **Galería Android**: botón «Vista previa: 32 unidades», con todas las figuras generadas por el mismo código usado en el campo; `UnitArtIcon.gd`, `UnitArtGallery.gd`.
- **Culling sencillo** de casillas fuera de la cámara; se mantiene el renderizado de 80 casillas para el tablero 10×8, sin afirmar soporte optimizado de mapas grandes.
- CI: `tests/test_unit_art.gd` cubre 32 identificadores distintos, siete edificios, dibujo efectivo, estado sin cambios, animación y visibilidad oculta. Los tests de la vista clásica se mantienen intactos.

## Restricciones de producto

1. Emblemas y retratos de las ocho facciones siguen siendo referencias autorizadas; **no se reemplazan ni se consideran importados** en esta PR.
2. Los colores pertenecen a la capa de identidad, no a estadísticas ni bonificaciones v0.1.
3. Bajo niebla, un movimiento de enemigo solo se anima si ambos extremos eran visibles para el jugador; el render final sigue filtrando enemigos ocultos.
4. Las figuras se dibujan como elementos gráficos 2D con profundidad simulada; los 32 roles tienen siluetas propias pero requieren una futura revisión artística individual y ajustes de escala para móviles.
5. No se añade mecánica de transporte, sonar, reparación, área de ataque, ni reglas especiales a clases que todavía no las tengan.
6. Conserva la opción de vista clásica hasta aprobar pruebas de control táctil en hardware Android.

## Próximos controles

- Evaluación visual a 720p/1080p en Android real, en particular discriminación de drones, antiaéreos, buques y vehículos de apoyo.
- Preparar sprites exportables de producción (PNG/WebP por unidad o atlas raster) con animaciones por estado y variantes de facción, una vez aprobada esta dirección.
- Construir sistema de nivel de detalle, cámara libre y minimapa para mapas mayores.
- Mantener prioridad en campaña de 50 capítulos, partidas aleatorias y online futuro, sin expandir roles redundantes.

La implementación es una base de arte vectorial procedimental original que ya se dibuja dentro de Godot, **no un paquete de 32 modelos 3D terminados**.
