# TARVOKA — Menú principal, selección de partida y mapas

**Fecha:** 13 de noviembre de 2026  
**Referencia de marca:** `BRAND_IDENTITY_TARVOKA.md` (águila, gran T, planeta ficticio).

## Flujo real implementado

`Inicio` presenta el emblema oficial a escala de **previsualización de 64 px**, el título TARVOKA y opciones táctiles:

| Opción | Acción |
| --- | --- |
| Continuar | Oculta Inicio y devuelve al campo de batalla activo, sin tocar el guardado |
| Modo historia | Ejecuta la transición de campaña existente, de momento Capítulo 01 |
| Escaramuza | Abre `SkirmishSetup`; los cambios de reglas no se aplican hasta la confirmación |
| Partidas guardadas | Abre `SavedMatchesMenu`, con autoguardado y guardado manual reales |
| Arsenal | Abre la galería interactiva de unidades existente |
| Ajustes | Abre la pestaña Ajustes del Centro de mando |
| Multijugador | Deshabilitado; no inventar servidores ni partidas en línea |

**Guardar/cargar:** `SavedMatchesMenu` utiliza `SaveStore.load_report` para comprobar validez de cada archivo, incluida recuperación de `.bak`. Lista información pública del estado de partida (tamaño, condición de victoria, equipo que juega, finalizada/en curso), sin destapar enemigos ni mover unidades. Si no hay archivo válido, el botón está deshabilitado. Solo el acto expreso de cargar invoca `board.load_game(path)`; se rechazan rutas fuera de los dos slots conocidos.

**Escaramuza:** la tarjeta «Reconocimiento del terreno» dibuja la distribución real de `Scenarios.terrain` / `Scenarios.seeded_terrain` con el tamaño seleccionado. Muestra bosque, carretera, montaña y agua, sin unidades; solo es una vista *prebatalla*. No consulta ni sustituye el estado de una escaramuza en curso. La semilla es reproducible.

**Responsive:** panel de marca + menú en dos columnas cuando hay anchura y disposición vertical con scroll en pantallas estrechas. El icono se dibuja a escala próxima a su resolución nativa; el arte maestro aprobado (no la miniatura) todavía debe incorporarse al repositorio para splash, Google Play e icono de launcher de alta calidad.

## Pruebas

- `tests/test_official_brand_menus.gd`: render e icono 64×64, conexiones, slots reales, lectura segura, mapa generado idéntico al motor, semilla, navegación y estado sin modificar hasta acción del jugador.
- Integrado en `.github/workflows/godot-rules.yml`.
- Exportación Android de la rama sujeta a su propio workflow y a inspección física de interfaz.

## Pendientes visuales

- Sustituir en `HomeMenu` la miniatura por un PNG maestro oficial de alta resolución de **la misma imagen aprobada**, sin cambiar el emblema.
- Mejorar tipografía final, localización, foco D-pad y transiciones ligeras con QA táctil.
- Hacer la pantalla dedicada de selección de facción cuando estén integrados los ocho escudos/personajes finales, sin inventar arte nuevo.
- En el futuro, separar guardados por campaña/escaramuza si el motor define formatos adicionales; no exponer slots inexistentes.
