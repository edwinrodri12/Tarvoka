# TARVOKA · Conquistas y campamentos en batalla (v2.0, laboratorio)

## Cómo abrirlo

En el menú principal de TARVOKA: **Conquistas · prueba**, o desde la barra de controles de batalla: **CONQUISTA · CAMPAMENTOS · PRUEBA**. Este modo es deliberadamente independiente; no reemplaza una batalla normal, no borra el guardado v1 y no usa la IA comercial. Es un experimento 1 vs 1 por turnos locales. El mapa es táctico 2D: no sustituye el mapa oficial 3D ni exporta un APK individual.

## Qué se puede hacer

1. Escoger mapa (campo abierto, bosque, puentes, costa) y tamaño (10×8, 24×18, 40×30). **Nueva prueba** reinicia exclusivamente la sesión experimental.
2. Tocar una ciudad o base fija para inspeccionar propietario, renta de ciudad y captura **0/2 o 1/2 turnos propios**, o control completo tras la segunda fase de ocupación de una misma infantería.
3. Tocar una infantería propia, tocar destino y confirmar **Mover** o **Atacar**. Los botones se activan solo si `TacticalHints` ofrece una acción legal; la transición final pasa por `FixedSiteOrdersV19` y `BattleSession`.
4. Seleccionar **Rastreador** para construir campamento de reconocimiento (100 créditos), o **Ingeniero** para construir campamento defensivo (130). La construcción consume el turno/acción del soldado, dinero y cupo; no crea unidades ni renta. Intendente (Suministros) y Sanitario (Médico) permanecen bloqueados hasta contar con roles implementados.
5. Capturar una base neutral con una infantería durante **dos cierres propios**; despejar la casilla ocupada, volver a inspeccionarla y elegir una unidad en **Producción fija**. Una fabricación por base y turno propio, con presupuesto, rol y dominio verificados por el motor real.
6. Un **astillero** está en agua. La infantería terrestre captura desde la casilla costera marcada, que no permite campamentos; se fabrica en la casilla naval.
7. Guardar/Cargar prueba usa `user://tarvoka_strategic_lab_v20.json`, diferente del guardado y autosave comerciales. Los datos malformados se rechazan sin sustituir la sesión abierta.

## Reglas y números que son hipótesis

- Los **únicos edificios construibles** durante una partida son campamentos; ciudades y productores militares son fijos, conquistables y con cupos por tamaño.
- 10×8: 4 ciudades, 2 campamentos máximos por facción; 24×18: 12 ciudades, 4 campamentos; 40×30: 16 ciudades, 6 campamentos.
- Rentas individuales de ciudades: 250 / 83 / 62 en mapas pequeño/mediano/grande (la renta total del mapa se aproxima a mil); ingresos iniciales por facción: 250 / 166 / 186, sujetos a balance.
- Los umbrales, costos y progreso son **provisionales**. No se ha demostrado equilibrio para 8 facciones ni diversión en partidas largas.
- No hay IA adaptada, niebla de guerra, efectos de campamentos, progreso I–III de instalaciones, mejoras de tecnologías, salvado universal >16 instalaciones ni integración con arte 3D oficial.
- Pese a usar movimientos, ataques y producción reales del motor, este experimento todavía requiere integración a la pantalla comercial, migración SaveCodec, HUD, mapa de facciones y QA en teléfonos Android.

## Archivos y pruebas

- `scripts/ui/FixedSiteBattleV20.gd`: pantalla Android horizontal y controlador de órdenes.
- `scripts/ui/FixedSiteMapV20.gd`: renderizador del terreno, unidades, campamentos, edificios y controles táctiles.
- `scripts/ui/Main.gd` + `HomeMenu.gd`: entrada voluntaria al laboratorio; nunca alteran el tablero activo.
- `tests/test_fixed_site_battle_ui_v20.gd`: ruta completa de acceso, campamento, pantalla, guardado, captura y compra.
- `tests/test_fixed_site_orders_v19.gd`: pruebas de regresión de las reglas, re-ejecutadas por `.github/workflows/fixed-site-battle-v20.yml`.

**No fusionar:** #449 se apila sobre #446 y #394. Validar la CI específica, resolver el bloqueo general previo de `BastionStudioAdapter.gd` → `CombinedArtStudioWeb.gd` en un cambio separado y revisar Android con controles reales antes de declarar integración comercial.
