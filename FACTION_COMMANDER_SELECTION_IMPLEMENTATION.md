# TARVOKA — Selección oficial de facciones y comandantes

Implementada el 13 de noviembre de 2026 para el flujo de **Escaramuza**.

## Recorrido del jugador

`Inicio > Escaramuza > Elegir facciones y comandantes` abre la pantalla táctica con las ocho identidades aprobadas de `VisualStyle.FACTIONS`. Cada tarjeta identifica facción, color y motivo del emblema. Se puede elegir **Jugador (bando 0)** o **Rival (bando 1)**. Si se elige una facción asignada al otro bando, se intercambian ambas, sin duplicación accidental. **Volver** conserva las elecciones anteriores sin aplicar las tentativas; **Confirmar bandos** devuelve las selecciones a Preparar Escaramuza. La creación de la batalla sigue utilizando la confirmación original de reemplazo del autoguardado.

El mundo y la partida siguen teniendo **dos bandos tácticos**. El selector presenta las **ocho identidades visuales** como opciones para esos bandos, no simula combates simultáneos de ocho facciones. No añade poderes, comandantes activos, IA especial ni modificadores de balance (los valores v0.1 definidos permanecen congelados).

Los **primeros cuatro escudos y retratos oficiales** (Alianza Norte, Pacto Escarlata, Unión Verde y Confederación Solar) ya están integrados como un atlas optimizado `assets/factions/official_first_four_atlas.webp`, recortado de las dos imágenes aprobadas. Véase `assets/factions/ART_SOURCES.md` para procedencia y coordenadas. Los otros cuatro muestran **INSIGNIA PENDIENTE** y **Retrato aprobado pendiente de incorporar**; no se inventan retratos. Si aparecen imágenes individuales `assets/factions/<clave>.png` o `assets/commanders/<clave>.png`, tienen prioridad.

## Persistencia y compatibilidad

- Las partidas nuevas que pasan por el selector guardan `visual_factions={"0":"clave","1":"clave"}`.
- Sólo se admiten dos claves válidas y diferentes según el catálogo oficial. Se valida durante `SaveCodec.encode/decode`.
- El campo es **opcional** en el formato actual v1; partidas anteriores siguen funcionando exactamente igual (azul/rojo).
- El motor conserva las identidades entre turnos y al guardar/cargar.
- Las unidades clásicas e isométricas y los objetivos de control usan los colores elegidos; el HUD indica el nombre de la facción.
- El sistema de combate continúa usando IDs internos 0 y 1. La personalización no altera munición, economía, daño, visibilidad ni turnos.

## Verificación

`tests/test_eight_faction_selection.gd` revisa las ocho tarjetas oficiales, la posibilidad de cancelar, el intercambio de bandos, los cambios visuales, que abrir menús no altere partidas, validación de guardados y compatibilidad histórica. Está integrado en CI.

## Pendiente para paridad visual con las artes aprobadas

1. Separar e integrar los cuatro escudos y retratos restantes de las láminas aprobadas. Los primeros cuatro ya están implementados en atlas WEBP.
2. Opcionalmente agregar los archivos maestros individuales de máxima resolución para portadas y marketing. El atlas actual está optimizado para Android; no sustituye al maestro.
3. Conectar las habilidades/ventajas v0.1 al motor **sólo después de confirmar su implementación y probarlas**. El selector actual es visual y funcional, pero todavía no activa bonificaciones.
4. Verificación de la pantalla en teléfono Android real y su legibilidad vertical.
