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

## P0 UI update (2026-11-10, PR #45)
- [x] Implement responsive orientation-aware Main UI: landscape board + tactical sidebar, portrait board + scrollable controls; P0 overlay text more legible. Godot CI and Android signed build passed.
- [x] Add clearly visible in-scene VICTORIA/DERROTA banner, with nonactionable End Turn and recovery after New Game; headless regression passed.
- [ ] **User device test** of new responsive Android layout, victory/defeat banner and buttons; reproduce screen recording at device resolution and when rotated.
- [ ] **Device test** of save, close app completely, reopen, verify same positions and faction; save manual and restart the app; compare.
- [ ] Maintain game-state compatibility and address ephemeral APK debug signatures; secure persistent signing key through GitHub secrets before update-in-place claims.
- [ ] Further improve tactical UX only after device feedback: attack confirmation/undo, turn summaries, accessible UI/terrain, responsive performance and portrait fidelity.

## 2026-11-10 — Autosave feedback delivered
- [x] Show a conspicuous warning in responsive UI if automatic save fails (PR #47, CI Godot + Android PASS).
- [ ] Verify warning, its disappearance after a successful retry and persistence restoration on a physical Android device; CI only models invalid save path.
- [ ] Review PR #46 backup recovery separately; it is NOT integrated until verified and merged, and potential stale backup after intentional New Game must be evaluated.
- [ ] Add stable debug signing through GitHub secrets for update-in-place installation without deleting saves; current builds are signed with new ephemeral keys every time.

## 2026-11-10 — Avances P0 lote sin APK individual
- [x] Respaldo anterior **validado** y recuperación en corrupción/ausencia del archivo principal, aviso al recuperar, borrado de respaldo viejo tras nueva partida (PR #48; Godot/Android CI PASS). PR #46 redundante cerrado sin merge.
- [x] Acciones tácticas de dos pasos en Main: movimiento y ataque con previsualización, confirmación por segundo toque o botón, revalidación de objetivo, cancelar sin consumir acción; sigue pendiente test físico (PR #49; CI PASS).
- [x] Resumen rápido del último turno enemigo: movimientos y ataques, limpieza al iniciar/cargar; sin cambiar IA (PR #50; CI PASS).
- [x] Prueba Godot de victoria causada por ataque confirmado y derrota causada por IA, persistencia de resultados finales y bloqueo de botones (PR #51; CI PASS).
- [ ] Validar en teléfono esta **actualización agrupada**: confirmación de órdenes, lista de movimientos, resumen IA, batalla completa, derrotas, y cierre/reapertura después de guardar.
- [ ] Mantener guardados entre instalaciones mediante firma debug persistente protegida en secrets (no comprometer claves privadas); por ahora no prometer actualización sobre la APK antigua.
- [ ] Una vez confirmado en Android: mejoras de tiempos de IA, legibilidad y terreno, mediciones de memoria/FPS; P1 IA basada en objetivos y niebla justa posteriormente.
- [ ] Continuar desarrollando sin enviar APK por cada PR; entregar una versión agrupada cuando tenga sentido para revisión de campo.

## 2026-11-10 — Checkpoint PR #53–#59 (nueva fase sin APK individual)
- [x] IA prioriza eliminaciones y rodea obstáculos mediante caminos válidos con costos de terreno (#53); **P1 IA estratégica de defensa/captura y niebla aún pendiente**.
- [x] 3 mapas originales transitables, render de terreno y selector de nuevo escenario confirmable (#54).
- [x] Evitar pathfinding de movimiento en 180 frames ociosos de HUD, cachear por estado y selección (#55); **FPS, calor y memoria Android real pendientes**.
- [x] Siluetas distintas por facción, HP numérico, resumen de bajas al terminar (#56); **legibilidad física pendiente**.
- [x] Validación de estados guardados contra datos imposibles/terrenos no definidos (#57).
- [x] Suite de simulación completa IA×IA para 3 escenarios y 2 iniciativas (#58), ampliada a 2 configuraciones (#59), 12 partidas terminadas.
- [x] Configuración de ejércitos iniciales explícita: Entrenamiento y Simétrico (#59). En seis simulaciones cada uno: 6–0 azul (asimétrico) y 3–3 (simétrico).
- [ ] **Próxima APK agrupada**: verificar controles de confirmación, selector de mapa/modo, siluetas HP, resultados, guardados y reinicio físico antes de publicar más contenido.
- [ ] Firmas Android debug persistentes mediante secretos protegidos, sin registrar claves privadas en Git; actuales efímeras y pueden exigir desinstalar/perder saves.
- [ ] Ampliar pruebas de balance a más despliegues, rivales, mapas y decisiones humanas; detectar dominancias y primer turno, no asumir balance por 6 partidas.
- [ ] IA por objetivos estratégicos, niebla de guerra compartida y juego adversarial justo (P1), evitando que el jugador/IA vean información no legal.
- [ ] Mejorar control de cámara/zoom y opciones de accesibilidad en múltiples tamaños de pantalla Android; medir tiempos de IA y uso de memoria.
- [ ] Mantener arte original, no adelantar economía/campaña/online hasta un gate P0 probado físicamente.

- [x] PR #52 integrado: verificación ABI ARM64 real y huella pública del certificado en CI de exportación. **La firma debug persistente sigue pendiente**, requiere secretos seguros sin commit de llave privada.

- [ ] Verificar en CI la nueva regresión de prioridad letal frente a objetivo sano ordenado primero por ID; no confundir con IA estratégica P1 ni QA de dispositivo. Mantener pendientes visión legal, rendimiento y guardado en Android real.

## 2026-11-10 — Hitos P1 fog/recon integrados #61–#65
- [x] Motor de visión con exploración individual acumulativa por facción y guardado compatible con versión 1 (#61).
- [x] Restricción de ataque a enemigos visibles y movimiento solo a destino visible desde motor autoritativo; ayudas y taps coherentes (#61, #63).
- [x] IA de reconocimiento basada en exploración propia, no conoce posición/HP de enemigos invisibles ni topología de casillas sin explorar (#62, #65).
- [x] Modo fog optativo al comenzar nueva partida confirmada, exploradores idénticos S/Z y niebla oscura vs terreno visto atenuado (#63).
- [x] Simular 12 batallas fog completas, 3 mapas × 2 iniciativas × 2 modos, sin acciones fuera de visión ni empates por bloqueo; modo simétrico 3–3 y entrenamiento 5–1 en muestra pequeña (#64).
- [ ] **QA en dispositivo Android:** función fog, nuevo selector, scout, táctil, ocultación sin fugas de información, guardado y relanzamiento, legibilidad y rendimiento de esta versión consolidada.
- [ ] Diferenciar terreno descubierto pero fuera de visión en accesibilidad (patrones), controles de densidad/zoom y texto del HUD más claro.
- [ ] Evaluar oclusión geográfica/altura que limite línea de visión por bosque/montañas; hoy vision diamante sin bloqueo de vista. Necesita reglas claras y pruebas simétricas.
- [ ] Explorar información de posición enemiga recordada (última vez vista) sin permitir ataques contra fantasmas ni almacenar memoria incorrecta.
- [ ] P1 posteriores: objetivos y captura territorial, IA de defensa y retirada, dificultades por planificación justa y balance con muestreo más amplio, no por trampas.
- [ ] Faltan clave de firma persistente y actualización de APK sin borrar progreso; no almacenar claves privadas en repositorio.
- [ ] Mantener APK agrupadas; no generar una entrega al usuario tras cada PR.

## P1 checkpoint adicional — montaña y cobertura de niebla (#66–#67)
- [x] Montaña bloquea visión detrás, casilla propia visible; scouts pueden revelar rodeando; reglas simétricas y guardado v1 correcto (#66, CI PASS).
- [x] Niebla no explorada 100% opaca para no filtrar colores; terreno conocido fuera de visión atenuado (#67, CI PASS).
- [ ] Validar en teléfono reconocimiento alrededor de montañas y que enemigos queden verdaderamente ocultos, no solo en simulación.
- [ ] Revisar visibilidad diagonal entre esquinas y oclusión de bosques/estructuras con reglas claras, pruebas de simetría y balance, no asumir completado.
- [ ] Mantener entregas APK agrupadas; no entregar una APK por cada PR.

## 2026-11-10 — Continuación cerrada PR #68–#71
- [x] LOS diagonal montaña simétrica sin permitir visión desde una facción solamente (#68, CI PASS).
- [x] Últimas posiciones observadas por bando, marcadores `?` no seleccionables ni atacables, invalidados al revelar casilla vacía y conservados opcionalmente en guardados v1 (#69, CI PASS).
- [x] Retirada defensiva IA bajo amenaza letal **solo hacia apoyo aliado**; ataque letal sigue primero; sin huida infinita (#70, CI PASS). La primera versión reveló un estancamiento y se corrigió antes de fusionar.
- [x] IA puede investigar registros históricos `contacts` del propio bando, no la posición actual oculta; pruebas adversariales de información (#71, CI PASS).
- [ ] **Prioridad de versión agrupada:** revisión en Android físico de niebla y montaña, indicador de último avistamiento, confirmación de toques, guardar-reiniciar, resumen IA, modo simétrico, rendimiento y escalado de HUD.
- [ ] **IA estratégica P1:** control/captura de puntos de mapa, defensa con objetivos, repliegue y apoyo coordinado; reglas y condiciones de victoria originales + pruebas antes de conectar UI.
- [ ] Pruebas de balance más amplias con despliegues variados y humanos; las 12 partidas automatizadas no garantizan calidad general.
- [ ] Firma de depuración estable protegida mediante secretos GitHub, sin subir keystore o contraseña al repositorio, para no borrar guardados al actualizar APK.
- [ ] Identidad audiovisual, campaña, tutorial y pruebas de accesibilidad después de una puerta P0 verificada en dispositivo; no sobreexpandir antes.

## 2026-11-10 — Objetivos territoriales opcionales P1/P2 #72–#76
- [x] Reglas puras y originales de control de 2 relés: capturar al concluir turno, propiedad hasta recaptura, señal por turno y victoria a 5; mismo mapa simétrico y sin ventajas ocultas (#72).
- [x] Integración `BattleSession` con victoria territorial, bloqueo post-partida y guardado v1 opcional compatible con partida de eliminación y niebla (#73).
- [x] Selector de modo objetivo confirmado, HUD de puntuación, marcadores de relé sin revelar propiedad fuera de visión, y resultado final veraz (#74).
- [x] IA con desplazamiento a relés neutrales/rivales, ruteo por terreno legal y visión justa; 24 partidas completas IA×IA, 15 victorias por señal y 9 por eliminación (#75).
- [x] Resúmenes de capturas/ganancia real de señal en ambos bandos, sin declarar falsamente que el turno vuelve al humano tras derrota territorial (#76).
- [ ] **QA físico obligatorio:** nueva APK agrupada para partida territorial completa, interruptores clásicos/niebla/relés, UI en teléfono y tablet, cerrar/reabrir, condiciones de victoria y mensajes, contraste/scroll, FPS/consumo.
- [ ] Comparar partidas de eliminación versus control con usuarios reales: evitar bola de nieve de propiedad persistente, captura del primer jugador, partidas cortas o demasiado pasivas; ajustar target/puntaje solo con evidencia.
- [ ] Defensa táctica explícita de relés propios amenazados, bloqueos, contrajuego y posible recuperación de control sin generar micromanejo excesivo.
- [ ] Ampliar IA por misiones de defensa/rescate/escolta y condiciones de estancamiento; NO considerar IA estratégica final.
- [ ] Firma Android persistente mediante secretos/keystore seguro para actualizar sin borrar partidas; no comprometer claves privadas.
- [ ] Solo entregar APK consolidada al usuario cuando sea apropiado, nunca por cada PR.

## 2026-11-11 — Avance agrupado #83–#86
- [x] **P1 Defensa reactiva de relés propios**: la IA guarnece un relé vacío que un enemigo visible puede alcanzar legalmente ese turno; respeta bloqueo de terreno, niebla, prioridad letal y modo clásico (#83).
- [x] **P0 HUD contextual**: rol Soldado/Explorador, terreno, costo exacto para entrar y cobertura real de unidad, sin revelar datos de enemigos invisibles (#84).
- [x] **P0 órdenes pendientes**: botón Terminar turno inactivo mientras una orden espera confirmación; handler adversarial también impide perderla (#85).
- [x] **P0 firma Android — infraestructura preparada**: workflow de compilación manual de `main` puede usar clave persistente protegida por tres secretos, mientras PR genera key efímera (#86).
- [ ] **Firma persistente ACTIVADA / update-in-place:** aún requiere que el propietario configure y custodie los secretos, compile manualmente dos veces, compare huella SHA-256 e instale sobre otra build estable en un Android físico sin perder guardados. No considerar cerrado P0-09 hasta entonces.
- [ ] **QA Android acumulado obligatorio**: diseño, gestos, persistencia al cerrar/reabrir, confirmaciones, resultado, relés, defensa IA y rendimiento. PR CI verde no sustituye el teléfono.
