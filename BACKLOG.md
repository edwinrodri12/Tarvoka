# Backlog
- [ ] Review and reconcile open movement PRs without overlapping changes.
- [ ] Import/reconcile the local v1.1 source archive (23 entries), preferably after repository is made private.
- [ ] Validate full battle loop: selection, movement, combat, turns, victory, AI and save/restore.
- [ ] Build Android APK and test on a physical mid-range device.

- [x] Confirm Godot headless CI on PR #5: run 42584227883 succeeded (2026-11-09).
- [ ] Re-run CI after merging/reconciling movement PRs; the current success applies only to PR #5.

- [ ] Integrate standalone combat resolution with unit state and turn controller after CI validation.

- [ ] Verify new turn tests in Godot CI; integrate turns with combat and scene input after green results.

- [ ] Validate BattleActions.gd on Godot CI, then integrate scene input and movement into battle state.

- [ ] Validate duplicate-ID battle guard in Godot CI; review before merging stacked PRs.
- [ ] Confirm CI for off-board attack rejection; integrate board input after validation.

2026-11-09: Verify movement action CI; connect movement and attack to a 10x8 Godot board/controller; add touch selection; then Android export and device tests.

- [ ] Run terrain-integrity regressions in Godot CI on the new stacked PR; then connect movement/attack to board input.

- [ ] Verify BattleSession headless CI and fix any failures; then connect touch board UI to BattleSession. No APK until verified export.

- [ ] Verify touch board GDScript test and fix CI failures; verify on-screen input in Godot and physical Android.
- [ ] Add AI turn, win/lose overlay and persistence after interactive prototype passes.

- [ ] Diagnose failed Godot workflow run 42671606319 on PR #14; verify all headless suites before merging stacked PRs.
- [ ] Verify spent-unit selection and tap-to-deselect regressions in Godot CI on new branch.

- [ ] Validate touch/mouse dedup regression on Godot CI and real Android device; verify tap selects exactly once and desktop mouse still selects. Do not merge without green checks.

- [ ] Validate decisive-attack victory UI regression in Godot headless CI; then review stacked PRs for integration.

- [ ] Confirm CI on typed-blocked-array test fix, inspect any next failing test and fix before integration. Previous PR #17 run 42699713939 was CANCELLED after Godot script type error; do not count as passing.

- [x] Confirm PR #18 typed-array fix via Godot 4.3 CI: run 42709626139 SUCCESS on commit 5e60d2e, all seven suites.
- [ ] Verify newer BattleSession invalid-start-faction regression via GitHub Actions; review and consolidate stacked PRs into main only after latest green checks.

- [ ] Verify BasicAI.gd headless regression tests on its own PR and resolve any Godot 4.3 errors.
- [ ] Connect BasicAI step loop to the enemy turn with a bounded action count, then test full human-vs-AI battle.
- [ ] Consolidate stacked draft PRs #5-#18 after reviewing their green checks; do not treat branch code as integrated into main.

- [ ] Verify bounded AI-turn UI regression on Godot CI, then manually exercise a full human-vs-AI battle.
- [ ] Add save/load state and first Android export after CI is green; physical-device touch verification remains required.

- [ ] Verify optimized AI and water-wall regression in Godot CI; diagnose remaining touch-board timeouts from job logs if still present.

- [ ] Verify SaveCodec JSON round-trip CI and integrate file persistence via user:// after green tests.

- [ ] Verify SaveStore Godot CI; inspect failure logs and correct issues before merging. Then wire save/load buttons into touch board.

- [ ] Verify save/load UI integration on Godot CI and physical Android; diagnose recurrent cancelled CI before merging stacked PRs.

- [ ] Verify Godot CI on 2026-11-10 AI action-count type fix; inspect touch-board test and downstream AI/save tests before merging stacked PRs.

2026-11-10: Verify CI fast-fail branch, inspect any timed-out suite logs, fix root cause, then validate full test set before Android export.

- [ ] Validate AI-turn human-input guard and regression in Godot 4.3 CI; check resumed saves during computer turn. Do not merge stacked changes without green tests.

- [ ] Run expanded input-ownership tests in Godot CI and confirm manual two-player faction 1 remains selectable before merging PR stack.

2026-11-10: Verify saved-AI-turn resume regression in Godot CI; consolidate stacked PRs after verification. First Android export and device testing remain outstanding.

- [ ] Verify completed-battle load feedback regression in Godot CI before merging stacked PRs.

- [ ] Verify faction-2 completed-save restoration and terminal input lock in Godot CI; then consolidate stacked PRs before Android export.

- [ ] Verify defensive AI entry guard in Godot CI, then consolidate stacked PRs and prepare Android export.

- [ ] Verify release-only tap/drag guard in Godot CI and on Android touchscreen; assess swipe/pinch interactions before adding camera navigation. Consolidate stacked PRs after green checks.

2026-11-10: Verify primary-finger multi-touch regression in Godot 4 CI; then validate Android device gestures and prepare first APK. Consolidate stacked PRs before export.

2026-11-10: Verify drag-out-and-return cancellation in Godot CI and Android; then consolidate PR stack and export APK.

- [ ] Verify off-board touch boundary regression in Godot CI and on Android before consolidating stacked PRs.

## Post-consolidation priorities (2026-11-10)
- [x] Consolidate tactical prototype PR #37 into main (squash commit 04c22883; pre-merge 10-suite Godot CI PASS).
- [ ] Verify main push GitHub Actions CI after squash merge.
- [ ] Run graphical/manual complete-match smoke test with human vs basic AI, saving/loading and victory.
- [ ] Configure Godot 4 Android export + secure signing workflow for a debug APK; build and test on actual midrange Android device.
- [ ] Audit PR #1-#36 for redundancy; close obsolete drafts with explanations, preserving branches/history; do NOT blindly merge duplicates.
- [ ] Review ownership/visibility: repository currently PUBLIC.

- [x] Produce first signed TARVOKA ARM64 debug APK (Actions run 42857252711, downloaded/tested as archive, hash recorded).
- [ ] Install and smoke-test debug APK on physical Android ARM64 phone; test movement, attacks, AI turn, victory, save/load, orientations and touch gestures.
- [ ] Establish persistent securely stored signing identity for update-in-place debug builds; never commit keystores/passwords.
- [ ] Improve game UI for mobile and ensure quality before release.

## Android input fix / next validation (2026-11-10)
- [x] Fix nonresponsive Android bottom Buttons (End turn, Save, Load): PR #39 merged in main; 11 headless suites and Android debug APK build PASS.
- [ ] Physically verify all three Buttons on user's Android phone, plus board tap/deselect/swipe and game state persistence.
- [ ] Implement a stable debug-signing arrangement via secure GitHub Actions secrets so future APK updates install without uninstalling and erasing saved games; no secret/private key in Git.
- [ ] Improve release UX after input/device verification.

## Nueva hoja de ruta de producto aprobada 2026-11-10 — críticas históricas
**Documento rector:** GAME_DESIGN.md · **Orden de ejecución:** DESIGN_ROADMAP.md · **QA:** DESIGN_QA.md. Las casillas siguientes son diseño/planificación, NO código implementado.
### P0 — MVP táctico y Android (NO saltar a P1 antes del gate)
- [x] Guardar en main los 3 documentos rectores de diseño, hoja de ruta y QA con 30 riesgos históricos.
- [x] Confirmar por reporte de usuario funcionamiento de selección/movimiento, botones inferiores y ejecución de turno IA en Android.
- [ ] Smoke test físico de una batalla completa hasta victoria/derrota, incluyendo carga tras reiniciar la aplicación.
- [ ] Mostrar alcance legal de movimiento/ataque, coste y estimación de daño sin información oculta.
- [ ] Panel de unidad legible: HP, acciones restantes, rol y efectos de terreno.
- [ ] Diseñar confirmación/cancelación y deshacer seguro sin abusos de niebla/RNG.
- [ ] Autoguardado por turno con recuperación; migraciones/compatibilidad de guardado.
- [ ] Ritmo de IA ajustable, resumen de turno y animaciones saltables.
- [ ] Android: pruebas de orientación, escalado de UI, accesibilidad y rendimiento offline.
- [ ] Firma de depuración persistente y segura para actualizar sin desinstalar.
### P1 — Estrategia y justicia
- [ ] IA centrada en objetivos, defensa, captura, retirada, economía/posición, sin omnisciencia.
- [ ] Niebla de guerra con información compartida, reconocimiento y últimas posiciones conocidas.
- [ ] Dificultades mediante mejor razonamiento, no beneficios secretos.
- [ ] Equilibrio por rol/counter, primer jugador, recursos, IA y condiciones de estancamiento; pruebas reproducibles.
### P2 — Identidad y contenido original
- [ ] Prototipos experimentales de captura/control territorial y suministros ligeros; medir valor vs micromanejo.
- [ ] Facciones, unidades terrestres/aéreas/navales y habilidades con roles originales y contramedidas.
- [ ] Variedad de misiones, varias soluciones, tutorial contextual y campaña coherente.
- [ ] Arte/UI/animación/audio originales y accesibles; modos independientes.
### P3 — Solo tras juego offline estable
- [ ] Guardado multijugador local y posterior online asíncrono, invitaciones y matchmaking.
- [ ] Editor, compartir mapas, repeticiones, clasificaciones y expansiones sustanciales.
- [ ] Verificación legal de marcas TARVOKA y originalidad de PI antes de publicación.
**Criterio de entrada a desarrollo:** problema de jugador + reglas puras + prueba positiva/adversarial + UX móvil + decisión documentada. Evitar agregar todos los puntos de golpe.

2026-11-10 P0-02 autosave/reanudación: [ ] PR propuesto con `tests/test_autosave.gd`; gate de CI Godot y export Android, luego instalación física y cierre forzoso/reapertura. [ ] Diseñar recuperación desde `.bak` cuando archivo principal corrupto y política de retención de backup, con tests adversariales. [ ] Confirmación antes de Nueva partida (puede sobrescribir progreso automático). P0-03/04/05: PR #41 fusionado, overlay y HUD requieren validación de legibilidad en Android.

## P0 checkpoint after 2026-11-10 implementation
- [x] P0-03 Green legal movement highlights and movement-cost labels; parity test with BattleSession rules (PR #41).
- [x] P0-04 Adjacent attack target overlay and deterministic damage estimate, without revealing hidden information (no fog mechanic in current prototype) (PR #41 + #43). Full predictive risk beyond simple deterministic damage is not yet implemented.
- [x] P0-05 Basic unit HUD: HP, attack, defense, movement/action status (PR #41). Role/terrain-effect panel pending.
- [x] P0-02 Separate automatic save after actions/turns, resume on launch, New Game, retain manual save (PR #42); CI tests PASS. Physical reopen/restore still not tested.
- [x] P0-06 Explicit Cancel Selection without changing state, and deliberate New Game confirmation (PR #43 + #44). Movement/attack commit confirmation and secure undo are still pending.
- [x] End Turn UI disabled after victory; obsolete PR #40 closed in favor of merged #43.
- [ ] Device test: latest APK overlay readability, selection, touch input, damages, autosave after closing/reopening, New Game confirm/cancel, victory/defeat, normal old functions.
- [ ] Persistent debug signing via secure GitHub Actions secrets before repeated install-in-place; current ephemeral signatures may require uninstall and erase saves.
- [ ] Movement/attack optional preview-and-confirm flow, robust auto-save write error feedback, explicit victory/defeat playthrough, timing/performance benchmarks on midrange Android.
- [ ] P1/P2 features including strategic AI objectives, fog of war, economy, factions, campaign, and multiplayer remain out of scope until P0 quality gate.

## P0 revisión por gameplay real (video de 42.2s, 2026-11-10)
- [x] Validación en Android de la **victoria del jugador**: tras destruir las unidades enemigas, aparece «Victoria de facción 1».
- [x] Validación visual del botón «Terminar turno» desactivado tras victoria.
- [x] Validación visual de casillas de movimiento verdes + costes y del ataque rojo con daño estimado -5.
- [x] Validación visual de confirmación «Nueva partida» seguida de reinicio exitoso.
- [ ] Mejorar UI responsive: aprovechar espacios laterales, aumentar tablero/HUD legible y reorganizar botones inferiores.
- [ ] Mostrar pantalla clara de resultado de batalla (victoria/derrota) con resumen y opciones.
- [ ] Validar autoguardado en dispositivo tras cerrar y reabrir la aplicación; comprobar estado exacto, no solo respuesta de botones.
- [ ] Validar derrota real, cancelación del modal sin cambiar partida, fluidez/rendimiento e interacción táctil tras cambios de UI.
- [ ] Confirmación opcional antes de movimiento/ataque y deshacer seguro sin revelar información oculta.

2026-11-10 P0 incremental: [x] retain previous valid JSON as `.bak` and fallback on corrupt/missing primary; [ ] validate actual Android force-close and recovery; [ ] make recovery visibly distinguish restored backup vs current autosave and decide stale-backup retention policy before release. Avoid claiming zero-loss durability.
