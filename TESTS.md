# Tests
- Existing tests/test_rules.gd: movement terrain, occupied cells, boundaries. Assertions not yet executed in this run.
- New .github/workflows/godot-rules.yml downloads official Godot 4.3 stable and invokes headless tests on PR/push/manual dispatch.
- Local Godot binary: NO DISPONIBLE (checked 2026-11-09).
- Android compilation/device: NO EJECUTADO; SDK/device not available.
- Manual: godot --headless --path . --script res://tests/test_rules.gd

- PASÓ (GitHub Actions, 2026-11-09): run 42584227883, job 129050054138, Godot 4.3 binary download and `tests/test_rules.gd` headless step both concluded SUCCESS on PR #5 head a01a1d8.
- NO EJECUTADO: full v1.1 game tests, Android APK build, physical-device testing.
- Local Godot binary remains unavailable; CI success is remote and limited to existing scaffold tests.

- Combat test: tests/test_combat.gd covers damage, terrain cover, defeat, survival, and invalid attacker. Status: NO EJECUTADO until GitHub Actions reports result on combat PR.

- Turn tests: tests/test_turns.gd checks faction reset, action ownership, duplicate action, dead units, immutability and winner. NO EJECUTADO pending CI evidence.

- GitHub Actions run 42606343996: SUCCESS for PR #7 head 29865b0 (turn and prior suites); scoped to that commit.
- Battle action integration test: tests/test_battle_actions.gd — NO EJECUTADO pending new CI run.

- New duplicate-ID and missing-ID battle regressions: NO EJECUTADO; await GitHub Actions on new branch.
- Off-board attack regressions (left/right/top/bottom): NO EJECUTADO pending Godot CI on proposed branch.

2026-11-09: Prior PR #10 head 4a2d0de GitHub Actions run 42632584537 PASÓ (success). New tests/test_move_actions.gd added to workflow; NO EJECUTADO/awaiting CI on new branch. Android APK/device NO EJECUTADO.

2026-11-09: Added 4 terrain-integrity assertions (unknown tile, non-string tile, short row, impassable origin) to tests/test_rules.gd. PASÓ: GitHub file writes. NO EJECUTADO: Godot 4 test on new branch, Android build/device. Existing prior-run CI success does not validate this commit.

2026-11-09 BattleSession: tests/test_battle_session.gd added (move, faction switching, consumed action, attack, victory, input immutability). NOT EXECUTED locally: Godot binary unavailable. CI pending; Android/device NOT EXECUTED.

2026-11-09: Added tests/test_touch_board.gd for tap selection, legal movement, action consumption and turn ownership. CI workflow updated. Status: NO EJECUTADO / pending CI; Godot binary not available in current connector environment. APK/device: NO EJECUTADO.

2026-11-09: PR #14 head abd1dd0 workflow run 42671606319: FALLÓ (GitHub Actions conclusion=failure; job listing returned no jobs, so cause unknown). New touch-selection guard regression added: tapped spent unit stays unselected; tapping same friendly unit twice deselects. NO EJECUTADO locally (Godot binary unavailable); awaiting CI. Android APK/device NO EJECUTADO.

2026-11-09: Added ProjectSettings regression assertion to tests/test_touch_board.gd for input_devices/pointing/emulate_mouse_from_touch=false. PASÓ: GitHub file write. NO EJECUTADO: Godot CI and Android device; PR #15 workflow 42679543043 was cancelled.

2026-11-09: Added decisive-attack victory feedback regression to tests/test_touch_board.gd. NO EJECUTADO (Godot CI pending); Android APK/device NO EJECUTADO. Earlier PR #16 run 42689788182 CANCELLED, not passed.

2026-11-09 PR #17 run 42699713939: FALLÓ (GDScript runtime error at tests/test_rules.gd:23: untyped [] does not match Array[Vector2i]); run ended CANCELLED after 10-minute job timeout. Fixed four invalid-terrain assertions to use `var no_blocked: Array[Vector2i] = []` in isolated branch. New Godot CI: NO EJECUTADO/awaiting result. APK/device: NO EJECUTADO.

2026-11-09 18:02 EST: PASÓ — GitHub Actions run 42709626139 on PR #18 commit 5e60d2e; job 129475405608 completed SUCCESS. All seven steps passed: rules, combat, turns, battle actions, movement actions, battle session, touch board. Subsequent initial-faction fallback test is NOT YET VERIFIED by this run. Android APK/device: NO EJECUTADO.

2026-11-09: Existing predecessor PR #18 commit 42add271 run 42717331241 PASÓ (SUCCESS); scope: pre-AI suites only. New tests/test_basic_ai.gd covers attack priority, victory, deterministic movement, action exhaustion, immutability, invalid state. New CI step added; NO EJECUTADO pending GitHub Actions on new PR. Android APK/device: NO EJECUTADO.

2026-11-09 AI UI integration: added test_touch_board regression for automatic AI movement and return to human faction. Status: NO EJECUTADO until CI on new PR. Predecessor PR #19 run 42726224295: SUCCESS (Godot 4.3 headless, reported by GitHub Actions), scoped to predecessor commit bcec1a31. Android APK/device: NO EJECUTADO.

2026-11-09: PR #20 GitHub Actions run 42733717633 CANCELLED; rules/combat/turns/battle actions/movement/battle session PASÓ, touch board CANCELADO, AI tests SKIPPED. New water-wall AI regression and pathfinding optimization: NO EJECUTADO pending CI. Android: NO EJECUTADO.

2026-11-09: Added tests/test_save_codec.gd for JSON round-trip, independent state, invalid payload/version/coordinates/duplicate IDs. NO EJECUTADO pending GitHub Actions. No Android build/device verification.

2026-11-09 SaveStore: regression script tests file roundtrip, invalid state/path, corrupt and missing files. Status NO EJECUTADO at commit creation; PR #22 prior run 42741291627 CANCELLED. Android device test NO EJECUTADO.

2026-11-09: Added board save/load regression (round-trip, cleared selection, missing file preserves live state). NO EJECUTADO: new Godot CI. PR #23 head a7557e8 run 42746918719 CANCELLED, not a pass. Android APK/device NO EJECUTADO.

2026-11-10: PR #24 run 42753784281 CANCELLED after 10-minute timeout. Logs show six suites PASÓ; touch-board FAILED TO COMPILE due to TouchBoard.gd:123 `max_actions` type inference error; remaining AI and save tests SKIPPED. Dedicated fix uses explicit int type; validation NO EJECUTADO until new CI. Android APK/device NO EJECUTADO.

2026-11-10: CI test-suite timeout guard added (90s + 5s kill grace); PASÓ: workflow file updated in GitHub. NO EJECUTADO: GitHub Actions execution for this change, Godot locally, Android APK/device. Timeout is a diagnostic safeguard, not proof that gameplay passes.

2026-11-10: Added regression in tests/test_touch_board.gd for ignored human taps while AI faction 1 owns the turn. PASÓ: GitHub code/test writes. NO EJECUTADO: Godot CI on this commit, APK build, physical Android device.

2026-11-10: Extended touch board assertions for AI-turn taps on both factions and manual faction 1 selection. PASÓ: test source committed; NO EJECUTADO: Godot runtime, CI, Android APK/device.

2026-11-10: PR #28 SHA 6d2ea08d: GitHub Actions 42780308893 PASÓ. New saved-AI-turn resume test: NO EJECUTADO until new branch CI. Android APK/device: NO EJECUTADO.

2026-11-10: Added terminal-save load UI regression. NOT EXECUTED in Godot or Android as of commit creation.

2026-11-10: PASÓ GitHub Actions run 42796752187 for PR #30 commit 0e824fb8 (Godot 4 headless). Added faction-2 victory-load and terminal-action regression on successor branch: NO EJECUTADO pending CI. Android APK/device: NO EJECUTADO.

2026-11-10: PR #31 commit c7880700: PASÓ workflow 42804643073. AI entry guard regression added: NO EJECUTADO until CI. Android APK/device: NO EJECUTADO.

2026-11-10: Added touch-event regression: press alone does not select, release selects, drag release cannot move, second tap deselects. PASÓ: GitHub writes. NO EJECUTADO: Godot 4 runtime/CI for new branch; Android APK/device not available.

2026-11-10: Added multi-touch regression to tests/test_touch_board.gd: secondary finger press/release does not complete primary tap; primary release selects and subsequent tap deselects. PASÓ source commit; NO EJECUTADO Godot runtime and Android/device.

2026-11-10 PR #35: Added synthetic drag-out-and-return regression to tests/test_touch_board.gd. NO EJECUTADO in Godot CI or Android device at commit time; APK NO EJECUTADO.

2026-11-10: Added two synthetic off-board touch regressions (x=800 exclusive right edge and x=-1 left exterior on 800x640 board). PASÓ: source write if committed; Godot CI NO EJECUTADO pending new branch workflow; APK/device NO EJECUTADO.

2026-11-10 consolidation: PR #37 head ff21ca270b241217a13c8b1d88ab08118b4d6b5e, workflow run 42855097479, job 'rules' completed SUCCESS. All ten Godot 4.3 headless suites SUCCESS (rules, combat, turns, battle actions, movement actions, battle session, touch board, basic AI, save codec, save store). PASS: connector confirmed merged PR #37 at main squash SHA 04c22883860d431f703a12967ac29f91187303d6 and main contains UI files. NO EJECUTADO at documentation update: separate post-merge main CI verification, manual graphical playtest, Android APK export, physical Android testing.

2026-11-10 Android CI: run 42857252711 SUCCESS on branch commit 4e97ffff (PR #38). Steps: Android SDK/JDK setup PASS; Godot 4.3 official editor and export templates PASS; ephemeral debug key generation PASS; Godot CLI debug export PASS; apksigner verify PASS; artifact upload PASS. Artifact 13781939680 'TARVOKA-Android-debug-arm64'. Extracted locally into TARVOKA-debug-Android-arm64.apk (23.06 MiB) SHA256=3cc01b2fa1d67210dff4805cb1a8cd5ae172c21e82e979a47ab007fbf5dedc6e. 10 headless Godot suites also PASSED in workflow run 42857252432. No physical Android installation or gameplay test yet (NOT EXECUTED). PR #38 merged to main at c94346f0.

2026-11-10 Android controls hotfix: Godot rules CI run 42860424633 completed SUCCESS after adding tests/test_main_buttons.gd (Button pressed signal integration for End turn, Save, Load) and touch synthetic mouse dedup test. Android export run 42860424711 SUCCESS: SDK/JDK, official Godot 4.3/templates, export, apksigner verify, uploaded artifact TARVOKA-Android-debug-arm64 (ID 13783744798), APK 24,189,580 bytes. PR #39 merged into main SHA 8da13b651f41be1b7c3f58c9c6e29775d2930da3. NO EJECUTADO: Android physical device testing and verification of actual finger taps on all Buttons. CI tests verify wiring/input assumptions, not device touch operation.

## 2026-11-10 — Nuevo marco de pruebas de diseño (solo documentación)
Los documentos GAME_DESIGN.md / DESIGN_ROADMAP.md / DESIGN_QA.md convierten 30 riesgos históricos en requisitos de producto y diez preguntas maestras de calidad. La escritura y presencia de estos documentos **NO implica** que sus funcionalidades estén implementadas. Ningún test Godot adicional se ejecutó para esta actualización documental.
**CONFIRMADO POR USUARIO en Android:** selección y movimiento de unidades observables, botones Terminar turno/Guardar/Cargar responden, la IA ejecuta su turno y devuelve el control. **NO EJECUTADO EN DISPOSITIVO:** validación de integridad de guardar/cargar después de cerrar y abrir; pantalla final de victoria/derrota, niebla, ayudas tácticas, rendimiento medido y funciones futuras.
**PRÓXIMOS TESTS:** (1) partida hasta condición de victoria; (2) salvar/cerrar/reabrir/restaurar; (3) selección, previsualización, confirmación y cancelación; (4) correspondencia exacta motor/alcance UI; (5) IA sin información prohibida en niebla; (6) rendimiento y offline en Android gama media. Especificaciones y métodos en DESIGN_QA.md.

2026-11-10 autosave PR propuesto: `tests/test_autosave.gd` prueba persistencia tras movimiento, cambio de turno, reinicio, reanudación de instancia nueva, corrupción y aislamiento de guardado manual. PASÓ: escritura de fuentes al repositorio. NO EJECUTADO hasta CI: Godot headless, export APK y dispositivo físico; el archivo autosave no implica prueba real de cierre/reapertura Android. Ayudas tácticas PR #41: PASÓ CI Godot 42871029059 y export Android 42871029033, ambos SUCCESS, integrado en main 10fd892c. NO EJECUTADO: prueba física de overlay y HUD.

2026-11-10 P0 four-PR delivery: #41 Godot headless workflow 42871029059 SUCCESS, Android 42871029033 SUCCESS; #42 Godot 42872162333 SUCCESS, Android 42872162437 SUCCESS; #43 Godot 42872921707 SUCCESS, Android 42872921656 SUCCESS; #44 Godot 42873868153 SUCCESS, Android 42873868205 SUCCESS. Automated regression additions: exact legal-move parity and attack-damage calculation in tests/test_tactical_hints.gd, autosave resume/move/AI turn/terminal/missing file tests in tests/test_autosave_resume.gd (plus autosave isolation tests), GUI button count/wiring, non-mutating Cancel Selection and safe New Game confirmation in tests/test_main_buttons.gd. PR #44 initially FAILED test_main_buttons due to dialog internals counted as game buttons; corrected with unique dialog OK label and flexible button count; final runs PASSED. Final APK obtained from run 42873868205 artifact ID 13791325778; ZIP inspected, single APK extracted to TARVOKA-P0-tactica-autoguardado.apk. Size 24,202,536 bytes, SHA256 bee3df7a164aaa36e2f0fac898f392b2d86f642bb353c960ab98092b331168db. GitHub Android export/signing verification passed. **NO EJECUTADO**: physical Android smoke test of new P0 features and final win/loss, ability to install atop older ephemeral-signed APK, cross-device performance, secure release signing. Existing user report only covers earlier APK input and AI behaviors.

2026-11-10 Android P0 gameplay VIDEO — EVIDENCIA DE CAMPO DEL USUARIO (grabación de 42.2s): se observa selector + sobreposición verde de movimiento con costos, sobreposición roja de ataque mostrando daño -5, combate y eliminación de unidades enemigas; hacia ~24s resultado «Victoria de facción 1»; «Terminar turno» desactivado tras el resultado; entre ~30–32s «Nueva partida» abre cuadro de confirmación y al confirmarlo restaura posición inicial de ambas facciones, permitiendo nueva selección. **PASÓ (observación visual, no medición instrumentada):** ciclo de victoria en teléfono, ayudas tácticas, prevención de terminar turno tras victoria, confirmación/reset de partida. **NO EJECUTADO en este video:** cerrar completamente y reabrir app para validar persistencia de autoguardado; comprobar contenido exacto restaurado mediante Guardar/Cargar; orientación y rendimiento cuantificados. La legibilidad del HUD y ocupación del ancho de pantalla son asuntos UX pendientes; no se modificó código por esta inspección.

2026-11-10 PR #45 adaptive main UI: Godot 4.3 headless run 42882100062 SUCCESS, including `tests/test_responsive_ui.gd` assertions for landscape side panel, portrait stacking, victory banner/turn lock, defeat banner and reset to normal game. All pre-existing suites passed on PR SHA badbc11b5192110e6d6d951b5849783c6cbcba1c. Android debug APK workflow run 42882099874 SUCCESS: export/signature verifier/artifact. Artifact 13793464227 `TARVOKA-Android-debug-arm64`, ZIP extracted to 24,210,895-byte APK, SHA256 a6d8d367e0c099aa10027e90172050ebc554b69a687137dd77df15a90a5d5593, APK ZIP integrity passed. PR #45 merged `67b2574c`. **NO EJECUTADO**: physical Android view, rotation, legibility, touch validation of redesigned sidebar; device recovery after force-closing. CI headless only validates nodes/layout configuration, not rendered physical UX.

2026-11-10 PR #47 autosave-failure UI regression: Godot headless CI 42882948668 SUCCESS; test_responsive_ui.gd asserts invalid save path returns false, visible warning contains `no se pudo guardar`, no state mutation, subsequent successful autosave clears warning. Android CI 42882948397 SUCCESS including debug export, signed APK validation and artifact upload. Extracted artifact 13794123171, 24,210,895-byte APK, SHA256 9564128fad9c932905ee21b39bed1d8611213763d3ef055c00b458807c084b99. PR merged into main `19d89577`. **NO EJECUTADO EN TELÉFONO:** autosave storage failure warning or restoring a saved game after force-closing app, as well as real portrait usability of new layout.

2026-11-10 P0 lot-based work: PR #48 SaveStore valid backup recovery + New Game stale-backup protections: Godot 42886758720 SUCCESS, Android build 42886759099 SUCCESS; tests/test_save_recovery.gd. PR #49 touch-stage order preview, same-target/Confirmar orden commitment, cancel, stale enemy rejection, turn lock: Godot 42887793941 SUCCESS, Android 42887793823 SUCCESS; tests/test_confirm_orders.gd. Initial Godot #49 run 42887399941 FAILED with GDScript type-inference for 'legal'; corrected explicitly typed bool, followed by PASS; initial Android run 42887400093 SUCCESS but not proof of failed Godot source. PR #50 enemy-turn report lifecycle: Godot 42888451864 SUCCESS, Android 42888451874 SUCCESS; tests/test_ai_turn_summary.gd and tests/test_responsive_ui.gd. PR #51 actual confirmed player-win and AI-defeat action flow plus terminal save/restore: Godot 42888950461 SUCCESS, Android 42888950576 SUCCESS; tests/test_full_battle_results.gd. All four PRs squash-merged main. **NO EJECUTADO EN TELÉFONO:** staged touch confirmation, backup corruption/recovery, last enemy summary, AI-caused defeat after this update; existing user video confirms only preceding build. User requested no APK per adjustment, so no new artifact delivered in this batch.

## 2026-11-10 — Resultados verificados PR #53–#59
| PR | Alcance | CI Godot 4.3 | CI Android debug |
|---|---|---|---|
| #53 | IA ataques letales, rutas por terreno, evitar oscilación | 42895650103 SUCCESS | 42895650179 SUCCESS |
| #54 | Escenarios originales, simetría, conectividad, selección/guardado | 42896411763 SUCCESS | 42896411666 SUCCESS |
| #55 | Cache HUD y 180 frames ociosos sin recalcular alcance | 42897015006 SUCCESS | 42897014942 SUCCESS |
| #56 | Formas de ejércitos, salud visible y recuentos de bajas | 42897555263 SUCCESS | 42897555273 SUCCESS |
| #57 | Rechazo de archivos dañados (terreno, stats, ganador falso) | 42898117046 SUCCESS | 42898117044 SUCCESS |
| #58 | 6 combates IA×IA en mapas originales | 42898696794 SUCCESS | 42898696652 SUCCESS |
| #59 | Preparación simétrica y 12 simulaciones | 42899630931 SUCCESS | 42899630956 SUCCESS |
**Observado en logs de CI de #59:** Entrenamiento, azul 6 victorias y rojo 0; Simétrico, azul 3 y rojo 3. Se probaron 3 mapas × 2 bandos iniciales × 2 configuraciones. Todos finalizaron sin unidades vivas superpuestas, rutas ilegales, bloqueos de batalla ni acciones post-victoria. Estas pruebas de IA contra IA son diagnósticas y NO pruebas de estadística poblacional ni partidas en Android físico. **NO EJECUTADO:** toque/gesto en nueva interfaz, efectos de terreno perceptibles en dispositivo, recuperación de partidas después de kill de aplicación, FPS/uso de memoria, múltiples orientaciones y múltiples dispositivos. El usuario pidió no entregar APK por cada ajuste; CI generó artefactos internos, sin descargar/entregar nuevas APK en este lote.

2026-11-10: PR #52 CI Android hardening, cabeza `6d504779a37190304f6e49ad8137ba8efe0853ee`, Godot run 42892753979 SUCCESS y Android debug run 42892754084 SUCCESS; check ARM64 native .so y huella SHA-256 pública de firmante, sin claves privadas. Fusionado `main` SHA `204cd07899bfb2ede0e1f97de610d25aac2a1497`. No prueba de instalabilidad sobre APK firmada con otra clave efímera.

2026-11-10 — Regresión propuesta `tests/test_basic_ai.gd`: dos blancos adyacentes, `a_healthy` (HP10) y `z_wounded` (HP3), ataque 5. Esperado: eliminar `z_wounded`, conservar HP de `a_healthy`, entrada original inmutable y misma salida en dos llamadas. Código añadido en rama de PR; **NO EJECUTADO** hasta CI Godot. Exportación Android y prueba física **NO EJECUTADAS** para esta rama al escribir.

## 2026-11-10 — QA de niebla y exploración, cinco PR validados
| PR | Verificación | Godot CI | Android ARM64 |
|---|---|---|---|
| #61 | Visión por facción, exploración, observación limpia, v1 save/legacy | 42915400561 SUCCESS | 42915400554 SUCCESS |
| #62 | IA no sigue enemigos invisibles, explora solo información legal | 42916085450 SUCCESS | 42916085399 SUCCESS |
| #63 | Niebla visible/oculta, scouts, UI Nueva partida, movimiento, guardado/reinicio | 42916908716 SUCCESS | 42916908658 SUCCESS |
| #64 | 12 partidas fog AI×AI, sin ataques invisibles, destinos ocultos, bloqueos | 42917319561 SUCCESS | 42917319443 SUCCESS |
| #65 | Topología sin explorar no influye decisiones de IA, regresión ocultación | 42917859860 SUCCESS | 42917859845 SUCCESS |
Resultados de logs de run 42917319561: 12 combates terminados; Entrenamiento fog azul5 / rojo1; Simétrico fog azul3 / rojo3; se probaron mapas abiertos, bosque y puentes con ambos primeros jugadores. Un número tan pequeño **NO** valida balance competitivo ni IA humana. Los tests nuevos incluyen test_visibility.gd, test_fog_ai.gd, test_fog_ui.gd, test_fog_self_play.gd. Godot headless no ofrece cobertura visual completa en Android. **PENDIENTE:** instalación real, UX táctil y niebla, guardar-reabrir, FPS/temperatura, verificar estado renderizado en móviles con distintas relaciones de aspecto y claves APK persistentes.

2026-11-10 P1 LOS/fog rendering CI: PR #66 (main facb7644) `tests/test_mountain_los.gd` — mountain tile visible but hides cells behind it, symmetric factions, flanking sight reveal, forest nonocclusion, classical all-visible and save roundtrip; Godot run 42918936432 SUCCESS, Android run 42918936216 SUCCESS. PR #67 (main 08a330ae) fog shade alpha regressions in `tests/test_fog_ui.gd`: unexplored alpha=1.0, explored-but-not-visible 0<alpha<1; Godot 42919298522 SUCCESS, Android 42919298370 SUCCESS. No field tests yet; neither color visibility nor physical FPS is measured by headless CI.

2026-11-10 PR propuesto — LOS diagonal simétrica: problema: el desempate de Bresenham puede atravesar celdas distintas según el sentido del rayo y permitir visibilidad asimétrica con montañas. Solución: requerir línea despejada en ambas direcciones, conservando montañas visibles en su propia celda. Caso positivo: dos unidades diagonales se ven en campo abierto; adversarial: montaña intermedia oculta ambas y no filtra unidades en observed_state; la montaña objetivo continúa visible. Tradeoff: oclusión conservadora en diagonales ambiguas, sin resolver aún la supercobertura completa de esquinas. Test tests/test_diagonal_los.gd integrado al workflow Godot. CI Godot/Android: NO EJECUTADO hasta resultados de Actions; dispositivo Android: NO EJECUTADO.
