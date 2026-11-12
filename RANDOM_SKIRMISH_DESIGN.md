# TARVOKA — Escaramuzas con mapas aleatorios reproducibles (fase A)

Esta primera implementación añade **mapas variables jugables contra la IA**, no un generador de mundos grandes ni el multijugador online.

## Contrato de generación
- Cuadrícula táctica actual **10 × 8** y cuatro geografías base originales (campo, bosque, cuenca, costa); se escoge la familia base mediante `seed % 4`.
- Una semilla entera de **1 a 999999** controla un `RandomNumberGenerator` local; la misma semilla y versión del juego generan el mismo mapa, sin depender de los turnos ni de la aleatoriedad global de Godot.
- Solo se varían casillas terrestres de la mitad izquierda, reflejando cada cambio a la mitad derecha. El reparto de caminos, bosques, llanuras y montañas no coloca nuevas barreras de agua, no rompe pasos del río ni puertos y preserva acceso a las cuatro parejas modernas de relés.
- No se modifican columnas de inicio y fábricas `0,1,8,9`; tampoco `(2,1)/(7,1)` ciudades propias, `(3,4)/(6,4)` ciudades neutrales, `(4,2)/(5,2)/(4,5)/(5,5)` objetivos modernos, ni el puente/dique central `(4,3)/(5,3)`. La movilidad terrestre sigue costando 1–3 puntos; navegación no permite atravesar tierra.
- El terreno original y los cuatro escenarios fijos permanecen intactos. Las 32 unidades militares y sus estadísticas v0.1 no se alteran; no hay bonos de facción.

## Flujo y persistencia
- En **Nueva partida → Escenario → Escaramuza aleatoria**, el jugador escribe una semilla o pulsa **Otra** para generar otra. El cuadro de confirmación muestra la semilla **antes** de sobrescribir el autoguardado.
- La misma semilla reproduce el mismo tablero; los bandos pueden alternar quién inicia, niebla, relés y economía. La IA usa las reglas comunes de movimiento, defensa, logística y compra.
- Guardado JSON v1 registra opcionalmente `map_seed` en la raíz y el terreno completo. El cargador valida el rango y **regenera para comprobar** que la semilla corresponde al terreno. No se aceptan valores malformados ni mapas manipulados; los archivos anteriores sin `map_seed` siguen cargando sin migración.
- Al recuperar partida manual o autoguardado, la UI recupera el escenario aleatorio y su semilla. No se vuelve a generar mapa mientras se reanuda la batalla.

## QA automatizado
- `test_seeded_random_battles.gd`: 48 semillas de cuatro geografías, simetría celda a celda, puntos de inicio, agua, economía, objetivo y rutas legales, hash de terreno por semilla, archivos malformados, y 8 simulaciones IA con niebla/economía/relevo de turnos.
- `test_seeded_map_ui.gd`: confirmación no destructiva, semilla reproducible/cambiada, botón de semilla aleatoria, fog, partida moderna, apertura roja IA, segundo jugador local y cargar/restaurar.
- La suite anterior debe permanecer verde y compilación Android ARM64 generar un artefacto firmado de depuración.

**Limitaciones todavía abiertas:** mapas grandes, ríos generados desde cero, colocación procedural de ciudades/relés/unidades y validación de balance estadístico con muchos jugadores/estrategias; online PvP; selector de tamaño; firma Android persistente. El alcance deliberadamente conservador permite probar primero la variación de terreno sin romper las mecánicas confirmadas en el teléfono.
