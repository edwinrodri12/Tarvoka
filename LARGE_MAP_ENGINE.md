# TARVOKA — primer motor jugable de campos de batalla grandes

Hito: 12 de noviembre de 2026. Rama experimental `feat/large-map-tactics-20261112`, sobre la versión más reciente de `main`.

## Tamaños disponibles

| Opción Android | Casillas | Estado |
| --- | ---: | --- |
| Clásico | 10 × 8 (80) | Comportamiento original sin cambios |
| Grande | 24 × 18 (432) | Reglas, movimiento, IA, niebla, economía y guardado adaptados |
| Estratégico | 40 × 30 (1200) | Misma integración con mayor área y controles de cámara |

Elige el tamaño en «Tamaño del campo de batalla» y luego crea una partida. Las batallas usan los mismos cuatro escenarios originales, incluida costa y río, y mapas simétricos aleatorios con semilla reproducible. En el tamaño grande, `Scenarios` crea una versión extendida y simétrica de la estrategia de caminos, ríos, montañas y costa, preservando los puntos de partida y los objetivos.

## Implementación técnica real

- `Rules.map_size(terrain)`, `Rules.valid_terrain`, `Rules.inside(cell,terrain)`: fuente de límites del motor. Solo se admiten tres tamaños conocidos y nunca mapas arbitrarios mayores de 1200 casillas. La llamada antigua `Rules.inside(cell)` sigue usando 10×8 para no romper las integraciones existentes.
- `Scenarios.terrain(id,size)` y `Scenarios.seeded_terrain(seed,size)`: preservan el resultado histórico para 10×8 y generan de forma determinista los nuevos mapas. Los puntos de salida, instalaciones y relés se proyectan simétricamente.
- `BattleSession`, `MoveActions`, `BattleActions`, `BasicAI`, `TacticalHints`, `SupplyNavigation`: aplican la misma validación y costes de movimiento, ataques, planificación, inspección y logística a casillas fuera del antiguo límite.
- `Visibility`: el alcance de visión, historial de exploración y los últimos contactos distinguen las dimensiones de la matriz; las casillas no exploradas permanecen ocultas para la IA.
- `UrbanEconomy` y `RelayControl`: ubican talleres, centros de drones, astilleros, ciudades y objetivos de forma simétrica y válida en los nuevos escenarios.
- `SaveCodec`: **mismo esquema y versión JSON 1**, sin migración destructiva. Comprueba dimensiones, celdas, niebla y última ubicación conocida; las partidas anteriores de 10×8 siguen cargándose. Las nuevas partidas se restauran sin redimensionarlas.
- `TouchBoard`: el render y las zonas táctiles del tablero clásico siguen el tamaño real; cámara temporal con zoom de 1× a 4×, arrastre táctil que no ejecuta órdenes, y centrado de casillas sin alterar estado. `Main.gd` incorpora selector 10×8 / 24×18 / 40×30 y controles +/-.

## Aceptación automática

`tests/test_large_maps.gd` verifica los tres tamaños con cuatro escenarios, semillas reproducibles, terreno simétrico en los dos tamaños nuevos, accesibilidad de objetivos, movimientos, ataques más allá de x=9, UI y cámara, IA, niebla, y continuidad de guardados. Se ejecuta antes de la batería extensa de reglas en GitHub Actions.

## Qué no está en esta PR

- El **motor de mapas grandes sí es jugable en la vista clásica**, pero el arte isométrico y el minimapa permanecen separados en las PR visuales #139, #142, #144 y #145. Hay que reconciliar sus cambios de `Main.gd`, `TouchBoard.gd`, `IsoRenderer.gd` e `IsoProjection.gd` antes de unirlos con este motor.
- No se han cambiado el balance aprobado de las ocho facciones, el daño, las 32 clases militares, los poderes de comandantes ni la campaña de 50 capítulos.
- Falta perfilar en Android físico los tiempos del ciclo completo de IA en 40×30, visibilidad en pantallas pequeñas y caminos entre los dos ejércitos. Las pruebas automatizadas no sustituyen esos controles.
- No se introducen mapas ilimitados ni multijugador online en este hito.

## Fusión e integración

Esta PR se apoya directamente en `main`, a diferencia de las PR visuales apiladas. Verificar ambos flujos CI (reglas Godot y APK Android ARM64) y después integrar la rama visual **sobre** el código actualizado, preservando nuevas doctrinas de contraataque y la inspección de unidades ya incorporadas por la automatización.
