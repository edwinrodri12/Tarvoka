# TARVOKA — Base Naval: cierre artístico V13 e integración jugable

## Decisión de diseño (15 noviembre 2026)
El propietario del juego considera que la Base Naval V13 ya se ve suficientemente bien para cerrar el diseño artístico e incorporarlo a TARVOKA. Se **congela el diseño V13** en esta rama como referencia aprobada para integración. No continuar acumulando detalles decorativos salvo defectos verificables en capturas, errores de geometría, incompatibilidades de navegación o problemas de rendimiento.

### Alcance preciso del cierre
- Modelo nativo Godot 4.3; 8 facciones; 3 niveles arquitectónicos; 5 estados visuales de daño; modo noche; 8 cámaras y detalles adaptados al zoom.
- Pruebas artísticas: [V13 Godot/OpenGL QA](https://github.com/edwinrodri12/Tarvoka/actions/runs/43784186107) comprueba 40 variantes, tres niveles, cámaras y 11 capturas. **Esto no certifica Android, producción, selección táctil, FPS ni reglas de combate.**
- El [Estudio 3D](https://edwinrodri12.github.io/Tarvoka/) contiene la previsualización, pero no es la pantalla de batalla definitiva.

## Hallazgos reales del juego en `main`
El juego ya modela un productor naval como `shipyard` en `scripts/core/UrbanEconomy.gd`, colocado exclusivamente sobre agua navegable en el modo moderno. Su facción, producción, captura, niebla, compra y ciclo de turnos ya son autoritativos en el estado de batalla. El motor principal dibuja sitios con `scripts/ui/WorldArt.gd` y `IsoRenderer.gd`; también existe la representación 3D derivada de estado en `BattleTerrain3D.gd`. El detallado V13 está actualmente en una rama separada de arte/Estudio, no integrado como edificio de batalla.

**Regla esencial:** la Base Naval V13 representa visualmente al `shipyard` existente. NO crear una instalación económica duplicada, otra casilla de astillero ni alterar el rendimiento de barcos o el sistema de compra/captura.

## Ruta de integración sin regresiones

1. **Dependencias y versión:** conservar la rama aprobada como fuente de mallas, materiales, facciones, daños y LOD. Portar las capas V1–V13 necesarias al árbol actual de `main` sin reemplazar sus scripts de batalla ni sobrescribir cambios posteriores.
2. **Escala y terreno:** adaptar tamaño del modelo naval a `BattleTerrain3D.CELL=2.40` y `WATER_LEVEL=-0.17`. Evitar que el puerto sobresalga sobre casillas vecinas o que la espuma del Estudio cubra la superficie marítima real. La huella lógica debe permanecer en **una casilla** hasta que las reglas soporten estructuras multicelda.
3. **Contratos de información:** representar solamente `kind=="shipyard"` de sitios existentes y respetar `visible/explored`; no filtrar propiedad enemiga oculta, selección, unidades, posición de otros puertos o datos de producción.
4. **Adaptación al mapa 2D:** en `IsoRenderer` / `WorldArt` preparar un icono/vista horneada coherente con V13, sin intentar renderizar un hangar 3D completo dentro de `CanvasItem`. Colores según propietario visible; sin agregar botones o hitboxes nuevos.
5. **Adaptación al mapa 3D:** una instancia visual de Base Naval por instalación **visible**, con LOD móvil, y descartarla/ocultarla cuando cambie la información de niebla. No instanciar V13 en cada frame, no crear luces por cada puerto, ni activar efectos caros de agua duplicada.
6. **Daños:** el estado artístico de daño no debe simular que el astillero perdió puntos de vida si el motor aún no tiene una variable de daño propia para edificios. Mientras tanto usar un estado visual íntegro; introducir daño gradual solo cuando el motor defina y serialice salud de estructuras.
7. **Selección/producción:** comprobar que al tocar el mismo tile del `shipyard` sigue funcionando el panel de fabricación naval, los costos, la captura por infantería y el reabastecimiento; sin cambiar permisos de dominio ni economía.
8. **Calidad y aprobación comercial:** medir Android real con varios astilleros, agua, clima, ocho facciones, mapas grandes, niebla, cambios de turno y pantalla horizontal. Realizar regresión de scripts del núcleo, mini mapa, guardados y UI táctil; comparar tiempos y FPS antes y después.

## Criterios para cerrar también la integración
- El sitio de batalla `shipyard` muestra arte alineado con V13 y el motor conserva exactamente los mismos resultados tácticos.
- Se prueban mapas con y sin puertos, fog of war, pérdida de visión, captura, cambio de propietario y reabastecimiento.
- No se duplican modelos en niebla, no se desborda la casilla, no hay agua adicional por cada puerto.
- QA real Godot, inspección visual en la batalla y medición de dispositivo Android aprobadas.

**Estado: diseño visual aprobado; integración al campo de batalla pendiente.** Este documento autoriza cerrar arte y comenzar la incorporación técnica, pero no certifica que ya exista una APK con la Base Naval V13.
