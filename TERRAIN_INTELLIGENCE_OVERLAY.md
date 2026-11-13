# TARVOKA — Capa de inteligencia de terreno (HUD Android/PC)

**Estado:** implementación experimental en PR #180, no equivale a QA de hardware.
**Ámbito:** únicamente presentación y controles de terreno; sin cambios de movimiento, ataque, economía, guardado, campaña, arte de facciones ni 3D.

## Controles

- Botón **Capa táctica** del panel expandido, acceso **▤ TERRENO** de la barra de acciones y botón **Mapa / DEF / MOV** del HUD compacto Android.
- Pulsaciones cíclicas: **apagada → DEF → MOV → apagada**.
- **DEF:** valores de cobertura de terreno, solo para tropas terrestres: bosque +1, montaña +2, ciudad +1 sobre el terreno. Un avión o barco nunca recibe una defensa de suelo por estar encima de una casilla.
- **MOV:** coste de entrar a esa casilla, según la **unidad aliada seleccionada**; sin selección se muestra como referencia de infantería a pie. Carretera terrestre motorizada = **½**, infantería = **1**; bosque terrestre = 2; montaña terrestre = 3; agua bloqueada a tierra. Unidades aéreas = 1 y navales solo agua = 1.
- **3\*** en montaña para unidad terrestre de MOV 1 o 2: refleja el coste estándar de 3, con la excepción real de ascenso adyacente que consume toda su capacidad del turno. No permite atravesar varias montañas ni moverse una segunda vez.
- La fuente de verdad para **rutas, alcance, combustible y combate** sigue siendo `Rules.reachable`, `TacticalHints` y `BattleActions`, no los colores de esta capa.
- La capa no se guarda, no consume movimiento, no confirma órdenes y no genera objetivos ni amenazas.
- Casillas nunca exploradas: **sin etiquetas ni tintes informativos**. Casillas exploradas fuera de vista actual: etiqueta atenuada. No informa posición enemiga ni su inventario.
- Las etiquetas se ocultan automáticamente con zoom pequeño y se conserva la señalización por tinte, sin añadir cargas permanentes al render cuando la capa está desactivada.

## Matriz de aceptación

| Caso | Resultado esperado |
|---|---|
| Tanque/APC en carretera | MOV muestra ½; movimiento/fuel real se calcula con motor |
| Infantería en carretera | MOV muestra 1 |
| Montaña lenta | MOV 3*; entrada adyacente gasta todo el movimiento |
| Bosque y montaña para tierra | DEF +1/+2 |
| Ciudad terrestre | DEF añade +1 |
| Helicóptero sobre montaña | Sin bono DEF terrestre; MOV 1 |
| Transporte marítimo frente a tierra | MOV × en tierra, 1 sobre agua |
| Niebla en 10×8 / 40×30 | No revelar terreno oculto |
| Zoom multitáctil y toques | Overlay no intercepta input ni modifica orden |
| Cambio DEF/MOV en una partida | Estado, recursos y guardado inmutables |
| Pantalla horizontal/vertical | Acceso al botón y números legibles sin cubrir acciones |

## QA

`tests/test_terrain_intelligence_overlay.gd` se ejecuta en el workflow `godot-rules.yml`; valida presentación legal, niebla, tres estados, sidebar/Android y estado original. **No sustituye** pruebas de contraste, superposición visual de edificios, FPS o táctiles en dispositivo real.

## Integración

Rama de este cambio: `feat/terrain-intelligence-overlay-20261113`. Si las ramas de laboratorio visual/MBT modifican `TouchBoard.gd` o `IsoRenderer.gd`, reconciliar esa selección con el parámetro opcional final `terrain_overlay_mode` después de fusionar, sin reescribir la geometría del tanque.
