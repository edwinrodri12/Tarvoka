# Decisions
- Godot 4 + modular GDScript; offline-first Android strategy.
- Board 10x8; terrain-dependent movement, impassable cells.
- Keep TARVOKA independent and original; commercial name pending trademark clearance.
- Test engine rules headlessly in GitHub Actions with official Godot 4.3 Linux binary; no Android builds or deployment in CI yet.
- Avoid merging pending overlapping movement PRs before comparing their diffs and tests.

- Treat successful CI on a draft PR as evidence for that exact head commit only; never infer other PRs or Android work passed. Keep PR #5 draft until integration review.

- Combat calculations are deterministic, bounded by remaining HP, with minimum 1 damage for positive attacks; invalid dead-unit attacks are rejected. This is an initial ruleset, not final balancing.

- Turn state is a pure data transformation; faction owns actions, dead units cannot act, and victory requires exactly one surviving faction.

- Initial attack integration permits only orthogonally adjacent enemy units and consumes the attacker's action; damage is deterministic. Ranged attacks and counterattacks are future work.

- Reject battle actions when unit identifiers are duplicated, empty or missing to avoid targeting an ambiguous combatant.
- Reject attacks with either combatant outside the 10x8 battlefield, even when adjacent.

2026-11-09: Moving consumes the unit's single action for its turn in the initial playable prototype. No move-and-attack in one turn until explicitly redesigned. Living units cannot share cells.

- Reject the entire movement query if any terrain cell has an unknown or non-string type, or if the origin is impassable; avoid silently interpreting corrupted maps.

2026-11-09: BattleSession is a pure RefCounted rules coordinator for two factions (0/1), independent of scene nodes and offline-capable. Each unit has one action per turn; movement consumes that action. No post-victory actions.

2026-11-09: Use lightweight Control._draw() board and _gui_input() for initial Android touch prototype, no art assets or external dependencies. Each successful move/attack consumes the unit action according to BattleSession. Defer animations and gestures until core behavior is verified.

- UI selection is restricted to living, active-faction units with unused actions; tapping an already selected unit cancels selection. Keep rule enforcement in BattleSession as the source of truth.

2026-11-09: Disable Godot's touch-to-mouse emulation for TARVOKA because TouchBoard.gd handles InputEventScreenTouch and InputEventMouseButton independently; processing both can turn one physical tap into two board actions. Preserve direct mouse input for desktop debugging.

2026-11-09: Show a victory message immediately after a decisive attack; preserve immutable BattleSession as the winner authority and block further turn changes.

2026-11-09: Preserve Rules.reachable typed Array[Vector2i] contract. Regression tests must supply explicitly typed empty blocked-cell arrays rather than untyped [] literals. Keep this fix isolated and do not merge stacked PRs without green CI.

2026-11-09: Invalid first_faction on BattleSession.start normalizes to faction 0 rather than creating a permanently inactive match. Keep faction 0/1 invariant for offline two-player prototype; add headless regression.

2026-11-09: Initial offline AI is deterministic, pure, one legal action per call, prioritizes adjacent attacks, then legal moves toward nearest living enemy; caller remains responsible for ending AI turns. No randomness, network or scene dependencies. Avoid conflating a tested planner with a playable AI opponent until connected to UI.

2026-11-09: Faction 0 is the human player by default, faction 1 runs bounded deterministic BasicAI when human ends turn. ai_enabled=false preserves two-human local testing. Stop AI on victory; no further end-turn after a win.

2026-11-09: Optimize deterministic AI planning by computing Rules.reachable once per acting unit, then validating only the selected candidate with Session.move. Preserve authoritative legality and deterministic row-major tie-breaking.

- Save format v1: JSON with explicit [x,y] positions, fixed 10x8 terrain and strict validation. Decode rejects malformed/version-incompatible payloads; filesystem save/load deferred.

2026-11-09: Store saves in user://tarvoka_battle_v1.json, limit 256 KiB, reject non-user paths and invalid codec states; use temporary write and rollback of previous file on rename failure. No encryption or cloud dependency.

2026-11-09: Expose offline save/load via explicit UI buttons; delegate serialization and filesystem validation to SaveStore, clear stale selection after restore, preserve live state when loading fails.

2026-11-10: Explicitly annotate the bounded AI action count as `int` after casting units to `Array` to satisfy Godot 4.3 static inference. Keep original unit-count action cap and gameplay semantics unchanged.

2026-11-10: CI runs each Godot headless test with GNU timeout (TERM at 90s, KILL 5s later), preserving nonzero exit status to expose hangs rather than waiting for the 10-minute job deadline.

2026-11-10: In AI-enabled games, human board taps are accepted only on faction 0 turns; manual two-player mode retains faction 1 input. This also protects restored AI-turn saves.

2026-11-10: Preserve manual two-player selection of faction 1 while denying all board taps during computer-controlled turns; test both sides of this mode boundary.

2026-11-10: A loaded save on computer faction 1 automatically executes the bounded offline AI turn, rather than leaving the input lock permanent. Terminal victory states remain untouched. Pending CI.

2026-11-10: Restored completed games display their victor; no AI continuation on terminal state.

2026-11-10: Treat terminal saved games symmetrically for both factions; never resume AI or accept player actions after a winner is recorded.

2026-11-10: AI step orchestration must be a no-op unless computer mode is enabled, faction 2 owns the turn, and battle has no winner.

2026-11-10: Treat touchscreen gestures as taps only on release within an 18-pixel movement tolerance; do not interpret swipes as tactical actions. Keep mouse click handling for desktop debugging.

2026-11-10: Touch gestures belong to the first active finger until that same index releases. Ignore other finger press/release events to prevent unintended tactical actions; maintain existing 18px movement threshold.

2026-11-10: Once a touch exceeds the tactical tap threshold, do not restore tap eligibility by moving back to the origin.

2026-11-10: Keep touch-board hit testing half-open at board boundaries: taps on or beyond the right/bottom edge and before the left/top edge must not mutate battle state.

2026-11-10: After all 10 Godot headless suites passed, squash-merge consolidated PR #37 to main as 04c22883. Keep historical PRs for traceability until redundancy is checked; no destructive branch deletion. Prioritize post-merge CI, desktop smoke test, Android export configuration and device validation over new features.

2026-11-10: Ship first ARM64-only debug APK from official Godot 4.3 export templates via GitHub Actions, ephemeral per-run signing key, no secrets committed. For test builds, app updates across differently signed runs might require uninstall/reinstall (local save data could be lost). Reuse a stable signing identity securely before recurring field tests/release. Do not commercialize without trademark clearance.

2026-11-10 Android input policy: keep input_devices/pointing/emulate_mouse_from_touch=true so native Godot Buttons receive taps; discard only emulated mouse events (device=InputEvent.DEVICE_ID_EMULATION) in TouchBoard, while preserving native ScreenTouch gesture handling and genuine desktop mouse. PR #39 merged. CI-generated debug signing keys are ephemeral until a stable secure debug signing strategy is established; do not confuse with release signing.

## 2026-11-10 — Decisión de producto y principios de originalidad
Aprobado por el usuario: incorporar un análisis integral de críticas históricas de Advance Wars para mejorar TARVOKA, **sin replicar sus activos, personajes, mapas, UI, narrativa, nombres, música o mecánicas distintivas**. Se adoptan como marco rector `GAME_DESIGN.md`, `DESIGN_ROADMAP.md` y `DESIGN_QA.md`.
1. Obligatorio desde diseño: IA con información honesta, transparencia de reglas, dificultad basada en decisiones, balance con contrajuego, UX táctil accesible, ritmo respetuoso, juego offline y originalidad.
2. Política de desarrollo: P0 experiencia jugable antes de economía, campañas extensas, grandes repertorios de unidades o online. Cada función debe tener criterios y test negativo/adversarial.
3. Aún **hipótesis sin mecánica cerrada**: economía con recuperación, suministros simplificados, control territorial avanzado, deshacer según información oculta, habilidades de comandantes, campaña ramificada, diferentes estilos de arte y multijugador asíncrono.
4. Multijugador local guardable planeado; online, editor y clasificaciones solo después de una versión offline estable y con autorización para cualquier coste.
5. Evitar confundir prueba CI o botón operativo con funcionamiento de flujo completo en móvil; marcar estado con evidencias.
6. Mantener sin microtransacciones pay-to-win; cualquier monetización o lanzamiento exige decisiones posteriores, autorización y revisión legal de marca TARVOKA USPTO/WIPO/PI.

2026-11-10 P0-02 — Problema: cierre de app pierde avances posteriores al guardado manual. Solución incremental: archivo de autoguardado separado del manual, guardado tras acción y turno (después de IA), restauración al abrir; botón Nueva partida sobrescribe solo autosave. Se conserva SaveStore/SaveCodec v1. Tradeoff: acciones se guardan tras ejecutarse, no existe todavía confirmación previa ni rollback de corrupción por copia de respaldo persistente. Casos: reabrir y comparar turno/unidades; autosave corrupto no altera batalla fresca ni guardado manual. No afirmar prueba en teléfono hasta validación real.

2026-11-10 P0 implementation decisions: calculate legal movement and adjacent attack previews by reusing the authoritative Rules/Combat actions; only show actions valid for the selected living, unspent unit. Render movement/costs in green and attack/damage in red, with unit HUD (PR #41); treat preview as advisory and keep rules authoritative. Restore offline autosave on scene launch in a **separate file**; never overwrite manual save automatically, and restart through a dedicated button (PR #42). Support explicit Cancel Selection and disable End Turn when victory ended the match (PR #43). Require a deliberate confirmation before New Game replaces autosave (PR #44). All four changes passed headless Godot and signed Android debug export CI, but mobile UX must be tested physically. Avoid unreviewed changes to completed workflows and further stacked PRs.

2026-11-10 P0 UX decision (PR #45): replace full-screen vertical controls below board with responsive BoxContainer showing a dedicated tactical sidebar in landscape; stack vertically in portrait, with a scrollable panel. Increase status/control font sizes. Keep authoritative battle state and controls identical; show in-scene VICTORIA/DERROTA banner and end-turn lock after battle without blocking map. Don't add a modal overlay that traps end-game interaction. Validate in Godot CI and actual Android before treating visual quality as closed. Signing remains ephemeral until secure stable key configured.

2026-11-10 P0 save reliability UX (PR #47): do not silently ignore failed automatic saves; show a persistent readable sidebar warning until a verified later successful autosave clears it. This does not magically protect against OS termination, disk corruption, uninstall/ephemeral debug-key changes or missing device storage. CI checks warning display/clearing; real-device error handling still requires testing.

2026-11-10 — Liberaciones por lote y seguridad de interacción. Por preferencia explícita del usuario, desarrollar, validar y fusionar cambios pequeños en GitHub, pero entregar APK **solo tras un conjunto importante de avances o para una prueba solicitada**, no una APK por modificación. PR #48 conserva solamente respaldo anterior validado y lo descarta tras nuevo juego confirmado; puede perderse la última acción si se recupera respaldo, no prometer restauración sin pérdida. PR #49 hace que Main exija confirmación de acción táctil: primer toque previsualiza, segundo toque sobre el mismo destino o botón «Confirmar orden» ejecuta después de revalidar; «Cancelar selección» y cambio de turno/partida borran la orden pendiente. Los tableros aislados en pruebas conservan modo inmediato para no reescribir pruebas anteriores. La nueva confirmación debe evaluarse en Android real antes de considerarse UX final. PR #50 informa recuento de acciones IA, sin modificar sus decisiones ni persistencia. PR #51 valida resultados reales de combate en headless Godot, no equivale a juego completo verificado físicamente.

## 2026-11-10 — Escenarios, IA, accesibilidad y equilibrio
Se adoptó mejora incremental de IA por objetivos *de combate* como paso hacia P1: golpes letales antes de daño parcial y rutas transitables calculadas por costos de terreno, manteniendo determinismo, límites de acciones y reglas autoritativas. Esto no equivale a IA completa de captura/defensa/niebla.
Los 3 mapas añadidos son escenarios simétricos originales con caminos, bosques, montañas y agua; se eligen únicamente al confirmar Nueva partida y conservan JSON v1. Los ejércitos se distinguen ahora por forma además de color, y el HUD reduce cómputos redundantes por frame.
Decisión explícita de balance: conservar como **Entrenamiento** la asimetría de inicio azul HP10/ATQ5 versus rojo HP8/ATQ4, pero permitir **Simétrico** con ambos HP10/ATQ5, opción clara para comparar estrategia sin ventaja de fuerza base. Se recupera opción desde el ataque del enemigo, que no cambia con el daño en este prototipo, sin migración de guardado. En seis simulaciones tutorial ganó azul 6/6; en seis simétricas ganó cada bando 3. No confundir esta muestra con pruebas estadísticas extensivas ni afirmar equilibrio de multijugador. Continuar política de **APK agrupadas**, no entrega por PR; preservar el ciclo de CI y pruebas de campo posteriores.
SaveCodec versión 1 ahora requiere terreno admitido, estadísticas no negativas/acotadas y victoria congruente; los respaldos se usan solo si están validados. No romper partidas legítimas previas.

2026-11-10 — Regresión de IA sin alterar motor: ante dos enemigos adyacentes, el primero por ID sano y el segundo vulnerable a eliminación, comprobar que BasicAI prioriza la baja, mantiene intacto el otro enemigo y produce igual resultado con entrada idéntica. Caso adversarial: orden alfabético no debe desplazar la decisión táctica. Tradeoff: no mide estrategia a largo plazo ni visión oculta (niebla no implementada). PR pendiente de CI.

2026-11-10 P1: niebla de guerra es **opcional**, predeterminado desactivado para mantener partidas existentes. Visión por distancia Manhattan (soldados3, exploradores5), con terreno de mapas conocidos visualmente solo al explorar; los obstáculos no ocluyen línea de visión por ahora. Descubrimiento se conserva por bando en guardado versión1 con campos opcionales fog/explored/vision, y no aparece en JSON de partidas clásicas. En niebla, destinos de movimiento deben estar dentro de visión actual; no se permite atacar enemigos ocultos; interfaz, ayudas tácticas y el motor deben concordar. Ejército simétrico añade explorador equivalente por bando HP6/ATQ2/MOV4/VIS5. La IA tiene acceso solamente a enemigos visibles y al terreno descubierto: la máscara de observación considera desconocido como impasable para planificación, sin cambiar terreno real. Movimiento/combate ejecutados por reglas autoritativas. **No prometer IA de niebla competitiva ni visibilidad de memoria de enemigos**, solo primer prototipo integrado y probado automáticamente. El usuario prefiere APK de entregas agrupadas; no cada modificación.

2026-11-10 — Regla P1 posterior: montañas ocluyen las casillas que quedan detrás según un rayo Bresenham entre observador y objetivo; la propia montaña es visible, bosque no bloquea línea de visión aún. Regla simétrica para ambos ejércitos, no afecta partida clásica sin niebla (#66). Las casillas nunca exploradas deben cubrirse con alfa1 completamente opaco para evitar fugas visuales del tipo de terreno, mientras las ya exploradas pueden conservar terreno atenuado sin enemigos ocultos (#67). La aproximación actual no define oclusión súper-cobertura en esquinas diagonales, queda como ajuste de diseño posterior. Tests automáticos pasaron, pendiente usabilidad real Android.
