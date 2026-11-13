# TARVOKA — Comandantes visibles durante la batalla

**Actualización 13 de noviembre de 2026.** Es una mejora de interfaz, no una implementación de poderes.

## Integración real

- `CommanderIdentityStrip.gd` muestra los **dos retratos oficiales** del enfrentamiento, sus nombres de facción y el color establecido para cada bando. Usa `FactionIdentity.from_state` y `VisualStyle.commander_texture`, no obras nuevas.
- En la **barra del centro táctico** hay una versión legible con dos retratos de mayor tamaño. En **Android compacto** la cinta se integra debajo del estado de batalla con retratos reducidos de 28 px, sin consumir la parte central del mapa.
- Indica quién tiene el turno: jugador, IA o segundo jugador local. Tras la victoria o derrota presenta el estado correspondiente. Es información **pública** y por ello compatible con niebla de guerra.
- Los retratos son de **solo lectura**: no activan poderes ni ejecutan órdenes, y el panel deja pasar los gestos táctiles hacia el tablero.
- En **Resultados** aparecen los dos comandantes, el nombre de la facción ganadora y las métricas con los colores correctos. Para partidas antiguas sin identidad seleccionada, conserva las etiquetas históricas AZUL/ROJO.
- Las partidas que incluyan `visual_factions` muestran las identidades elegidas al recargar. Los guardados anteriores sin el campo mantienen las referencias visuales Alianza Norte / Pacto Escarlata.
- En **Centro de mando**, el encabezado de turno muestra el nombre real de la facción elegida y los iconos de las unidades utilizan el color de la facción activa (incluida producción). Antes estaban limitados incorrectamente a azul/rojo.
- `FactionGallery.gd` lista las ocho insignias **y** los ocho retratos aprobados en la pantalla de referencias.

## Selección y Android

- La ficha de comandantes pasa encima de la lista de facciones al detectar orientación **vertical**, incluso en teléfonos de 1080 px de ancho físico. En horizontal se muestra de lado.
- El retrato y el escudo se reducen en pantallas muy estrechas; `Volver` y `Confirmar bandos` conservan su funcionamiento. Al elegir una facción en vertical se vuelve al inicio de la zona desplazable para mostrar su retrato.
- Las etiquetas ahora hablan de **Bando 1 / Bando 2**; las facciones pueden ser violetas, negras o turquesas, por lo que no deben presentarse erróneamente como países azules y rojos.
- Los toques de tarjetas, colores y retratos no cambian la lógica de turnos ni el progreso guardado. Los poderes y bonificaciones siguen **sin activarse** por esta pantalla.

## Verificación

`tests/test_commander_presentation.gd` comprueba retratos 1–8 en galería, HUD compacto/expandido, colores de facción, turno de IA, duelo local, victoria, compatibilidad con identidades guardadas y orientaciones Android 390×844, 1080×2400 y escritorio 1280×720. CI en `godot-rules.yml`. El workflow Android empaqueta el APK; un chequeo headless **no sustituye** a la inspección visual en un teléfono real.

## Pendientes comerciales

- QA táctil en Android físico (notch/insets, densidad, idioma y accesibilidad).
- Retratos maestros de mayor resolución si se requieren para portada/promocionales; el atlas actual es para pantallas pequeñas.
- Poderes activos de comandantes, sólo después de instrumentar y validar el balance v0.1 vigente.
