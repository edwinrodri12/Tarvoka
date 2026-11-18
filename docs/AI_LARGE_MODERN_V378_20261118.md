# TARVOKA v3.7.8 — Integración en mapas grandes, unidades modernas, facciones visuales y guardados

**18 de noviembre de 2026.** Suite experimental de regresión, no fusionada. Se basa en la v3.7.7, cuya [CI oficial](https://github.com/edwinrodri12/Tarvoka/actions/runs/44248358413) terminó con **18/18 trabajos exitosos**, 192 parejas / 384 batallas completas en simetría, y el contrato de 144 objetivos válido.

## Qué se comprueba realmente

Se proponen cuatro shard de Godot 4.3: 24×18 con/sin niebla y 40×30 con/sin niebla. Cada shard usa una semilla fija diferente, para cubrir los cuatro estilos de terreno de los prototipos oficiales. En cada uno se validan dos opciones de primer jugador, con los ocho esquemas de facción aprobados para cada bando, para un total de **64 secuencias de integración**.

Cada secuencia:
1. Genera el terreno oficial con semilla y proyecta el plantel moderno (infantería, rastreador, tanque, antiaéreo, dron y helicóptero) con los métodos originales.
2. Crea una sesión real con economía moderna, relés, regla de tres órdenes iniciales e ingreso de respuesta simétrico (opción de partida).
3. Coloca dos identidades visuales distintas de las ocho facciones aprobadas, verificando el guardado.
4. Ejecuta una **compra manual legal de infantería** en el edificio del jugador que tiene iniciativa, y la compara contra otra compra independiente en el campo reflejado/intercambiado.
5. Termina el turno manual con `BattleSession.end_turn` y valida que el siguiente bando no recibe un ingreso extra ilegítimo.
6. Guarda y carga el estado oficial v1, luego ejecuta una acción genuina de `scripts/core/BasicAI.gd` en ambas versiones.
7. Exige igualdad de acción y estado tras normalizar el espejo, compara las decisiones entre las ocho apariencias, y comprueba que guardados con objetivos y los antiguos sin `ai_objectives` ni `visual_factions` se puedan cargar y reanudar.

La suite no modifica el juego: solo agrega un script en `tests/`, un agregador y un workflow.

## Límites estrictos de interpretación

- Las ocho facciones actualmente son **identidades de presentación** del motor de dos bandos. Los poderes de comandante y el balance especial de las facciones necesitan implementación/pruebas separadas antes de afirmar que son funcionales.
- Estas **64 secuencias NO son 64 batallas completas**, no aportan tasas de victoria ni miden calidad del AI contra humanos reales.
- La partida de prueba simula la decisión humana con una compra explícita y legal, no una sesión interactiva real.
- No prueba una distribución estadística aleatoria de semillas, ni validación de rendimiento Android en dispositivo físico.
- El balance del orden de turno sigue pendiente de campañas amplias y no se justifica dar dinero, HP, movimientos ni producción gratuitos.
- No fusionar hasta pasar CI e inspeccionar regresiones de 40×30, visibilidad, compras, guardados y capacidad de respuesta.

[Workflow de validación](https://github.com/edwinrodri12/Tarvoka/blob/experiment/ai-v378-modern-large-map-factions-saves-20261118/.github/workflows/ai-large-modern-v378.yml)

**Prohibido mezclar a `main` automáticamente. No publica APK ni cambia las reglas aprobadas.**
