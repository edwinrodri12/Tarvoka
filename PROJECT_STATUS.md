# TARVOKA — Project status
2026-11-09: Dedicated repository accessible; visibility PUBLIC. Main branch contains a minimal Godot 4 scaffold, not the full v1.1 game.
Proposed PR: add GitHub Actions workflow to execute tests/test_rules.gd using official Godot 4.3 headless binary. CI has now been observed running successfully (details below).
The local TARVOKA_autonomous_v1_1.zip archive is accessible (23 entries), but has NOT been imported into GitHub. Its rules/state/AI must be reconciled without overwriting pending movement PRs.
No verified Android APK or device test. No edits to EKANVORA or centro-operativo-atlanta.

2026-11-09 verification: GitHub Actions run 42584227883 completed SUCCESS on PR #5 head a01a1d812b187967babb4745a8b2a7d1ee9d8afd. Both Godot 4.3 download and GDScript rules-test steps completed successfully. This verifies only the minimal scaffold's movement test, not the full v1.1 game or Android. Repository remains PUBLIC; PR #5 is draft, main unchanged.

2026-11-09: Proposed standalone deterministic combat core (scripts/core/Combat.gd) and test suite. CI execution pending; no integration into battle UI yet. No APK verified.

2026-11-09: Added pure faction turn bookkeeping in scripts/core/Turns.gd and tests/test_turns.gd on dedicated branch. Functional execution not yet confirmed; no APK.

2026-11-09: Proposed pure adjacent attack integration (BattleActions.gd) using Combat and Turns, with immutable unit state and victory result. Awaiting CI verification. No Android build.

2026-11-09: Proposed duplicate/invalid unit ID guard for BattleActions; draft PR pending Godot CI validation. No APK.

2026-11-09: Proposed board-boundary validation for adjacent attacks on 10x8 map. Four regression cases added; awaiting CI evidence. No APK.

2026-11-09: Added MoveActions.gd pure movement integration (terrain cost, occupancy, faction/turn guards, immutable state), tests/test_move_actions.gd and CI step. New test execution pending; no APK verified.

2026-11-09: On stacked terrain-grid-integrity branch, Rules.reachable now rejects malformed terrain values anywhere on the 10x8 board and impassable origins. Added four regression assertions. Godot execution NOT VERIFIED; no APK.

2026-11-09: Proposed BattleSession.gd two-faction coordinator on stacked branch automation/battle-session-20261109. Connects move, attack, end turn, victory with immutable state; GDScript tests added but not yet verified. No Android build.

2026-11-09: Proposed first interactive 10x8 touch board (scripts/ui/TouchBoard.gd) connected to BattleSession via scripts/ui/Main.gd. Includes tap selection, movement, attack, end-turn, faction colors and win indicator. Draft branch only; CI/Android NOT VERIFIED. Two-player local prototype, not AI.

2026-11-09: Draft touch selection guard: tapping the selected friendly unit deselects it; already-acted friendly units cannot be selected. Branch-only, headless CI not yet verified. Previous PR #14 workflow run 42671606319 concluded FAILURE; root cause not established because job list returned empty. No APK/device verification.

2026-11-09: Proposed Android touch event deduplication via project.godot input_devices/pointing/emulate_mouse_from_touch=false. Godot touch events remain supported, desktop mouse events remain supported; prevents synthetic mouse press from deselecting a unit immediately after touch selection. Awaiting CI; not device-verified. PR #15 run 42679543043 cancelled, not a test pass.

2026-11-09: Draft stacked UI change: show immediate winner message when the last enemy falls; pending Godot CI. No APK verified.

2026-11-09 CI diagnosis: PR #17 run 42699713939 log confirms Godot 4.3 SCRIPT ERROR in tests/test_rules.gd:23: untyped [] supplied to Rules.reachable fourth parameter Array[Vector2i]. Created isolated follow-up branch fixing test arguments. Await CI validation; main untouched; APK not built.

2026-11-09 18:02 EST: Verified PR #18 commit 5e60d2e GitHub Actions run 42709626139 SUCCESS: all seven Godot 4.3 headless suites, including touch board, passed (job 129475405608). This validates the stacked branch at that SHA, not main or Android. Added separate defensive initial-faction fallback in BattleSession and a regression test in subsequent commits; those newer commits await CI. main unchanged; no verified APK/device.

2026-11-09 19:xx EST: Proposed pure deterministic BasicAI.step(state) on isolated branch. Prioritizes adjacent legal attacks, otherwise chooses a legal move minimizing Manhattan distance to an enemy; returns immutable state and no-op when exhausted. Tests and CI step added. NOT verified in Godot yet; not connected to UI. Latest predecessor commit 42add271 GitHub Actions run 42717331241 SUCCESS (all existing suites), but does not validate new AI. No APK.

2026-11-09 20:xx EST: Draft AI opponent integration in TouchBoard.finish_turn: faction 1 executes at most unit-count deterministic BasicAI steps then returns to human faction 0, unless victory occurs. UI remains lightweight/offline. CI pending on new branch; Android APK/device NOT verified.

2026-11-09 21:xx EST: PR #20 CI run 42733717633 cancelled during touch board suite after preceding suites passed; new AI movement performance optimization proposed in dedicated stacked branch. Godot validation pending; no APK.

2026-11-09 21:xx EST: Added versioned JSON battle state codec in isolated stacked branch; handles Vector2i positions, validation and round-trip. No disk I/O or Android APK yet. New CI pending.

2026-11-09: Proposed SaveStore.gd for bounded offline user:// JSON file persistence with temp write and rollback; draft branch, no verified Godot execution or Android APK. PR #22 CI was cancelled; this change is unverified until CI succeeds.

2026-11-09 23:xx EST: Added save/load buttons and TouchBoard methods on stacked draft branch; keeps state unchanged on failed load, clears selection after successful load. Godot CI and Android unverified; PR #23 run 42746918719 CANCELLED.

2026-11-10: Diagnosed PR #24 run 42753784281: Godot 4.3 parse error at TouchBoard.gd:123 (`var max_actions := state.get(...).size()` cannot infer type). The test script then fails to instantiate the board and hangs until 10-minute cancellation. Explicitly typed AI action bound in dedicated stacked branch; awaiting CI on fix. Six earlier suites passed in that run; Android APK/device unverified.

2026-11-10: Added 90-second per-suite timeout to Godot CI on dedicated branch, so parse failures cannot silently stall an entire job. Execution pending; APK/device unverified.

2026-11-10: Input ownership guard proposed on stacked branch: TouchBoard ignores human taps while AI faction 1 is active. Not Godot-verified; APK/device not tested.

2026-11-10: Expanded headless input-ownership regression to test both human and computer unit taps during an AI turn, plus faction 1 selection in local two-player mode. GitHub commit written; Godot/Android execution pending.

2026-11-10: PR #28 head 6d2ea08d CI run 42780308893 SUCCESS (Godot 4 headless). New stacked branch resumes computer turn automatically when loading a save; regression added, awaiting CI. Android APK/device unverified.

2026-11-10: Added winner feedback when loading completed battles; Godot CI and Android verification pending.

2026-11-10: PR #30 head 0e824fb8 GitHub Actions run 42796752187 SUCCESS. Added follow-up regression for loading faction-2 victory and ensuring terminal battles reject input; awaiting CI. Android APK/device still unverified.

2026-11-10: Added defensive AI-turn entry guard on a stacked branch; CI pending. PR #31 head c7880700 passed Godot workflow run 42804643073. Android APK unverified.

2026-11-10: Proposed touchscreen drag rejection: process ScreenTouch on release only and ignore releases farther than 18 logical pixels from press; desktop mouse path unchanged. New headless regression added. Godot CI and physical Android NOT VERIFIED. Stacked on PR #32; main unchanged.

2026-11-10: Added primary-finger ownership for touchscreen gestures: a second finger cannot replace the press origin or complete a different finger's tap. Draft branch only; Godot CI and Android device unverified. No APK claimed.

2026-11-10: PR #35 proposes permanent cancellation when the primary finger drags beyond 18px then returns. CI/device not verified; no APK.

2026-11-10: Added touch-board boundary regression for taps at the exclusive right edge and outside the left edge. CI pending; Android device and APK not verified.

2026-11-10 CONSOLIDATION COMPLETE: PR #37 merged with squash into main, commit 04c22883860d431f703a12967ac29f91187303d6. Main now contains tactical board, movement/combat/turns, deterministic basic AI, save/load, and 10-suite Godot headless CI workflow. PR #37 head ff21ca270b241217a13c8b1d88ab08118b4d6b5e passed all 10 Godot 4.3 suites: workflow 42855097479. The merged main SHA itself still requires a post-merge CI check. Historical 'main unchanged' statements above are historical, not current. Original draft PRs #1-#36 remain open pending equivalence audit and safe closure; no need to remerge duplicate code. APK and physical Android validation remain NOT EXECUTED. Repo remains PUBLIC.

2026-11-10 APK MILESTONE: first Godot 4.3 ARM64 Android DEBUG APK successfully built, debug signed and uploaded as GitHub Actions artifact 'TARVOKA-Android-debug-arm64' (artifact ID 13781939680, run 42857252711, source commit 4e97ffff). PR #38 merged into main (squash commit c94346f09238f67802cfc60bf91552826067d1e7). Archive was downloaded and APK extracted and verified locally (23.06 MiB; SHA256 3cc01b2fa1d67210dff4805cb1a8cd5ae172c21e82e979a47ab007fbf5dedc6e). Functional installation/device test NOT EXECUTED; this is a prototype/debug APK only, not production.

2026-11-10 Android button hotfix VERIFIED IN CI: PR #39 merged into main as 8da13b651f41be1b7c3f58c9c6e29775d2930da3. Root cause: native Button input on Android failed with input_devices/pointing/emulate_mouse_from_touch=false. Enabled touch-to-mouse emulation and filtered InputEvent.DEVICE_ID_EMULATION synthetic clicks only in TouchBoard to prevent duplicate taps. Godot headless rules and new UI button test PASS (run 42860424633), Android export, signing verification, and artifact upload PASS (run 42860424711). APK artifact 13783744798 (TARVOKA-Android-debug-arm64); device confirmation PENDING. Note debug signing key generated anew per CI run: installations may require uninstalling previous debug APK; could delete saved data.

## 2026-11-10 — Dirección de diseño adoptada
Por decisión del usuario se incorporó la investigación histórica de críticas a Advance Wars como **problemas a evitar, no mecánicas/arte a copiar**. Documentos rectores en main: `GAME_DESIGN.md` (pilares, 30 riesgos AW-01 a AW-30, hipótesis), `DESIGN_ROADMAP.md` (fases P0–P3 con criterios de salida) y `DESIGN_QA.md` (diferencia entre CI, prueba en campo y funcionalidades pendientes). Esta actualización es **solo planificación/documentación**; no implementa 30 sistemas nuevos ni altera la APK.
Confirmación de campo reportada por el usuario: en Android funcionan selección/movimiento, los 3 botones inferiores después del hotfix #39 y el turno automático de la IA con devolución del control. No inferir de esto victoria completa ni integridad de archivos guardados; siguen pendientes pruebas específicas. Prioridad inmediata P0: terminar ciclo de batalla, guardado/reanudación, información táctica visible, claridad/confirmaciones y rendimiento Android. Mantener propiedad intelectual original, offline y no ampliar nuevas facciones, economía ni online prematuramente.

2026-11-10 P0-02 (propuesta, PR pendiente): autosave separado en `user://tarvoka_autosave_v1.json`, recuperación al abrir y botón Nueva partida; no modifica archivo manual. Pruebas Godot/Android de este cambio pendientes. No hay verificación física de cierre/reapertura. PR #41 previo de ayudas tácticas integrado en main SHA 10fd892c, CI Godot run 42871029059 SUCCESS y APK run 42871029033 SUCCESS; dispositivo NO EJECUTADO para overlay.

## 2026-11-10 — P0 delivered (four integrated PRs)
- PR #41 merged to main (10fd892c): `TacticalHints.gd` with green legal movement cells/costs, red adjacent attack targets and compact unit HUD. Godot CI 42871029059 SUCCESS; Android APK CI 42871029033 SUCCESS.
- PR #42 merged (54c001c4): offline autosave **separate** from manual save, restorable on startup, safe handling of terminal/AI turn, New Game button and grouped save/load controls. Godot CI 42872162333 SUCCESS; Android CI 42872162437 SUCCESS. Existing manual save is not overwritten by autosave. Note: CI debug APK signing remains ephemeral; physical upgrade can require uninstall/lose data.
- PR #43 merged (386b448b): attack damage estimate rendered on target and in HUD, Cancel Selection control and End Turn disabled after completed battle. Godot CI 42872921707 SUCCESS; Android CI 42872921656 SUCCESS.
- PR #44 merged (faab7581): ConfirmationDialog prevents accidental New Game from overwriting autosave; reset happens only on confirmation. Godot CI 42873868153 SUCCESS; Android CI 42873868205 SUCCESS.
- Final CI artifact: `TARVOKA-Android-debug-arm64` ID 13791325778 from run 42873868205. Extracted APK 24,202,536 bytes, SHA256 `bee3df7a164aaa36e2f0fac898f392b2d86f642bb353c960ab98092b331168db`.
- Old PR #40 closed as explicitly superseded by #43; original branch/history retained. **Not verified physically yet:** all new on-device overlays, restart dialog, autosave recovery after app termination, victory/defeat UI and performance. No new actual phone confirmation should be claimed before user tests.

## 2026-11-10 — Nueva evidencia de gameplay en Android (video 42 segundos)
**CONFIRMADO POR INSPECCIÓN DE VIDEO DEL USUARIO:** en la APK P0 reciente, el tablero muestra desplazamientos legales verdes con costos, objetivo enemigo adyacente en rojo y daño estimado -5, combate con destrucción visible de las dos unidades enemigas y mensaje «Victoria de facción 1» aproximadamente al segundo 24. «Terminar turno» aparece deshabilitado tras la victoria. «Nueva partida» presenta un cuadro de confirmación y, tras aceptarlo, restaura ambos bandos a sus posiciones iniciales aproximadamente al segundo 32. El tablero vuelve a permitir seleccionar unidades. Estos hallazgos son evidencia de **prueba de campo**, no únicamente CI. SIGUE PENDIENTE: autoguardado después de salir/cerrar completamente la app y volver a entrar, integridad del guardado manual después de reinicio, rendimiento medido y distintos tamaños de pantalla. **Observación UX:** mucho espacio lateral vacío, paneles de texto pequeños y botones demasiado extensos; crear diseño móvil adaptativo, HUD legible y cierre de victoria más visible antes de ampliar mecánicas.

## 2026-11-10 — P0 adaptive mobile UI and terminal result (PR #45)
PR #45 merged into main as `67b2574c3e0f02348d87ab6ae8ad7bb5629f84cf`: reorganized Main.gd into responsive BoxContainer (`vertical` for portrait, horizontal tactical sidebar for landscape), larger HUD/controls, scrollable side panel, visually prominent VICTORIA and DERROTA banners without covering the board, reset-to-hidden on new game. No changes to battle rules, touch board, saved data format or AI. Godot 4.3 headless CI run 42882100062 SUCCESS including new responsive UI/terminal result regression; Android debug export, signing verification and artifact upload run 42882099874 SUCCESS. APK from artifact 13793464227 extracted and validated as ZIP with size 24,210,895 bytes and SHA256 `a6d8d367e0c099aa10027e90172050ebc554b69a687137dd77df15a90a5d5593`. On-phone layout, portrait/landscape rotation and exact winner appearance have NOT BEEN TESTED; require user screen recording. Note ephemeral debug signature requires uninstall for upgrades and may erase existing saves.

## 2026-11-10 — Visible autosave error handling (PR #47)
PR #47 merged into main as `19d89577a0a2c0005229d46620e19b69f87de614`: TouchBoard keeps `autosave_warning` on automatic-save failures, and Main sidebar shows the warning until a subsequent successful write. The save codec and manual-save behavior are unchanged. Godot headless test CI 42882948668 SUCCESS, including explicit invalid autosave destination and successful retry; Android signed APK export CI 42882948397 SUCCESS. APK artifact 13794123171 extracted, ZIP integrity PASS; file 24,210,895 bytes; SHA256 `9564128fad9c932905ee21b39bed1d8611213763d3ef055c00b458807c084b99`. On-phone failure path and resume across relaunch NOT EXECUTED. `main` now includes both responsive P0 UI #45 and autosave warning #47. PR #46 (save backup recovery) is a separate still-open proposal and MUST NOT be described as shipped without merge and CI verification.
