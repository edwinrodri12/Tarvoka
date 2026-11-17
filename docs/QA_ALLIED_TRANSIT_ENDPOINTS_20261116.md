# Allied transit endpoint regression — 2026-11-16

Scope: Godot 4.3, pure `Rules.reachable` contract; no gameplay rule changes.

Positive: a unit at (0,0) can cross a friendly occupied tile at (1,0), reach (1,1) for cost 2 and (2,1) for cost 3, but cannot end on (1,0).

Adversarial: enemies at (0,1) and (2,0) block paths. If (1,0) is also in blocked, the unit is sealed at its origin despite its presence in transit_only. Inputs remain unmodified.

Command: `godot --headless --path . --script res://tests/test_allied_transit_endpoints.gd`

Expected marker: `PASS: allied transit and endpoint isolation`.

Status: source committed; Godot 4.3 **NO EJECUTADO** on this commit, Android physical **NO EJECUTADO EN DISPOSITIVO**. The standalone test is now wired to `.github/workflows/allied-transit-endpoints.yml` on this PR branch, with official Godot 4.3, 90-second timeout, strict unexpected-error detection, and exactly one PASS marker. **CI result remains NO EJECUTADO / pending verification**; wiring is not proof of a passing test. Before merging, inspect the new Actions run, run the full tactical regression suite, and verify no overlapping PR has equivalent coverage.

## Extended corridor coverage (2026-11-16)

Two consecutive allied tiles at (1,0) and (2,0) form the only route from (0,0) to (3,0), while enemy-occupied cells block detours. Assert that (3,0) is reachable at cost 3 with movement budget 3, neither allied tile is a legal endpoint, and budget 2 cannot reach (3,0). Also assert input allied positions remain unchanged. This specifically guards against incorrectly filtering allied transit tiles *before* route expansion and against free transit through allies.

Commit: `2dac21e9583cfd60bc553040e36b2f7467430fd0`. Godot 4.3 **NO EJECUTADO** for this extension; Android **NO EJECUTADO EN DISPOSITIVO**. CI and broader AI/save/victory regressions must be checked before merge. No changes to production movement logic.

## Extensión: ruta ortogonal sin atajos (2026-11-16)
Se añadió una prueba con un aliado al este y un enemigo al sur del origen. Con presupuesto 1, la casilla diagonal sureste no es alcanzable; con presupuesto 2 se alcanza exactamente con coste 2 atravesando al aliado, pero su casilla no puede seleccionarse como destino. También se comprueba la inmutabilidad de las listas de ocupación. Commit de código: `be78f8bf`.

Evidencia anterior: workflow *Allied transit endpoint regression*, run [43945909381](https://github.com/edwinrodri12/Tarvoka/actions/runs/43945909381), SUCCESS sobre `d2b6a63a` (no cubre la extensión). La nueva regresión queda **NO EJECUTADA** hasta confirmar un run del commit nuevo. Android físico: **NO EJECUTADO EN DISPOSITIVO**. No fusionar sin comprobar CI y regresiones completas.

## Motorized road transit regression (2026-11-16)

On a 10×8 plain map, road tiles (1,0) and (2,0) form a two-tile corridor, with an ally on (1,0) and an enemy at (0,1). A motorized ground unit starting (0,0) with movement budget 1 must reach (2,0) at displayed cost 1 (two half-point road entries), but cannot finish on the allied (1,0). A non-motorized ground unit with the same budget cannot reach (2,0). The test also asserts terrain and occupancy inputs remain unchanged. This verifies an existing road-mobility rule without altering production movement or balance.

Code commit: `cfe23b6a831523eb97338705a1afcdac5ad4f2fd`. Godot 4.3 CI for this commit: **NO EJECUTADO / pending verification**; Android: **NO EJECUTADO EN DISPOSITIVO**. Run `godot --headless --path . --script res://tests/test_allied_transit_endpoints.gd`, then full movement/AI/save/victory suites before integration. No merge authorized by this documentation.

## Allied mountain transit regression (2026-11-16)

A ground unit starts at (0,0), with an ally on mountain (1,0) and an enemy at (0,1). The only route to (2,0) crosses the mountain. Budget 3 must NOT reach (2,0); budget 4 must reach it with cost 4 (mountain 3 + plain 1). The mountain ally is never a valid destination, and terrain/occupancy inputs are unchanged. This tests existing terrain costs without changing production rules. Code commit: `a0855786b3d3f494cf6dea857c9f81c94fbd663f`.

Prior standalone CI on commit `cfe23b6a`: [43967487342](https://github.com/edwinrodri12/Tarvoka/actions/runs/43967487342) PASÓ; Android export on the same predecessor: [43967487477](https://github.com/edwinrodri12/Tarvoka/actions/runs/43967487477) PASÓ. General rules CI on that predecessor: [43967487335](https://github.com/edwinrodri12/Tarvoka/actions/runs/43967487335) FALLÓ (cause not yet diagnosed). None of those runs validates this new mountain assertion. New Godot CI: NO EJECUTADO / pending. Android físico: NO EJECUTADO EN DISPOSITIVO. Full IA/save/victory regressions pending before merge.

## Contested motorized road transit (2026-11-16)

A motorized ground unit starts at (0,0), with enemy occupants at (0,1) and (1,0). The road at (1,0) is also listed as allied transit, deliberately creating contradictory occupancy inputs. Even with movement budget 2 and the motorized road discount, the reachable set must contain only the origin; enemy blocking takes precedence. Enemy occupancy input must remain unchanged. This is a regression of existing precedence, not a gameplay-rule change.

Code commit: `74243bd69415dc86b55d28d1a0cb73c01a92f071`. Previous PR head `df8147a9`: standalone Godot CI [43977221628](https://github.com/edwinrodri12/Tarvoka/actions/runs/43977221628) PASÓ; Android export [43977221608](https://github.com/edwinrodri12/Tarvoka/actions/runs/43977221608) PASÓ; general rules [43977221783](https://github.com/edwinrodri12/Tarvoka/actions/runs/43977221783) FALLÓ (root cause not established). These previous runs do not validate the new assertion. New Godot 4.3 CI: NO EJECUTADO / awaiting run; physical Android: NO EJECUTADO EN DISPOSITIVO. Before merge: inspect fresh CI and full movement, AI, save and victory regressions.


## Impassable water with allied occupant (2026-11-16)

New regression commit `6e1446b5`: a ground unit starts at (0,0), the allied transit tile (1,0) is water, and (0,1) is enemy-blocked. Even with movement budget 5, only the origin may be reachable: an allied occupant must not turn impassable water into a valid route. Terrain and both occupancy arrays must remain unchanged. This is a regression of existing `Rules.reachable` semantics, not a gameplay rule change.

Reproduce: `godot --headless --path . --script res://tests/test_allied_transit_endpoints.gd`. Expected single marker: `PASS: allied transit and endpoint isolation`. **Godot CI for this new commit: NO EJECUTADO / not yet confirmed. Android physical: NO EJECUTADO EN DISPOSITIVO.** Before merging, inspect current CI and run the full tactical/AI/save/victory suites. No APK generated.

## 2026-11-16 — Solicitudes inválidas y presupuesto cero
- Regresión añadida: con 0 puntos únicamente el origen es alcanzable, aunque exista un aliado transitable junto a él.
- Origen fuera del tablero y presupuesto negativo deben devolver un diccionario vacío.
- Las tres solicitudes deben preservar terreno y listas de ocupación originales.
- Commit de prueba: `080b3c0418719ba297c026dd52353077fcf0d7b3`.
- **NO EJECUTADO en Godot 4.3/CI para este commit; NO EJECUTADO EN DISPOSITIVO Android.** No se modifica `Rules.gd`.


## 2026-11-16 — Bloqueo enemigo en borde de mapa grande
- Commit `edbba0b6`: escenario 24×18 con aliado en (22,17) y enemigo en (23,17). La salida enemiga debe seguir bloqueada aunque el aliado anterior permita tránsito; ningún destino puede escapar del borde derecho o inferior. Verifica inmutabilidad de los datos de entrada.
- **NO EJECUTADO** en Godot/CI para este commit; la ejecución anterior `44008359620` pasó sobre `89f8a811`, no valida este añadido.
- CI general anterior `44008359522` **FALLÓ** en el paso de sprites HQ V13; CI Android anterior `44008359534` **PASÓ** como exportación, no prueba física.
- **NO EJECUTADO EN DISPOSITIVO**. No fusionar hasta confirmar regresiones pertinentes y revisar el fallo general independiente.

## 2026-11-17 — Independencia del CI de jugabilidad

El workflow de esta rama ahora ejecuta también `test_rules.gd`, `test_battle_session.gd`, `test_basic_ai.gd` y `test_save_codec.gd` después de la regresión de tránsito aliado. Cada suite tiene timeout de 90 segundos, falla ante errores Godot y exige un marcador PASS. La cobertura permite comprobar reglas, victoria, IA y serialización incluso si el workflow general se detiene antes de llegar a las pruebas tácticas.

Diagnóstico reproducible del fallo del workflow general en el commit anterior `77ecea54`: ejecución [44015178678](https://github.com/edwinrodri12/Tarvoka/actions/runs/44015178678), importación HQ V15 abortada porque `scripts/ui/BastionStudioAdapter.gd` no puede resolver `res://scripts/ui/CombinedArtStudioWeb.gd`. El problema no demuestra un fallo de movimiento. Evitar corregir la rama artística en esta PR de movimiento.

Evidencia de base para `77ecea54`: [tránsito aliado 44015178674](https://github.com/edwinrodri12/Tarvoka/actions/runs/44015178674) PASÓ; [exportación Android 44015178689](https://github.com/edwinrodri12/Tarvoka/actions/runs/44015178689) PASÓ (solo compilación). **Nuevo workflow extendido: NO EJECUTADO / pendiente de verificar CI**. **Android físico: NO EJECUTADO EN DISPOSITIVO**. Ninguna PR fusionada.

## 2026-11-17 — Endurecimiento de criterios de CI

Commit `1c67511e`: se sustituyó la búsqueda genérica de `PASS` por la comprobación de **exactamente una línea de cierre esperada por suite** (`test_rules`, `test_battle_session`, `test_basic_ai`, `test_save_codec`). Esto evita falsos positivos cuando un log menciona PASS sin que el test haya alcanzado su final; el código de salida, errores de Godot y timeouts siguen siendo obligatorios. Verificar que cada suite termina con su marcador literal; si cambia su texto, actualizar la tabla `expected` en el workflow y justificarlo. No se alteraron reglas de juego.

Al consultar las ejecuciones asociadas al commit `1c67511e`, GitHub devolvió cero runs; **CI NUEVO NO CONFIRMADO**, no equivale a PASÓ. **Android físico NO EJECUTADO EN DISPOSITIVO**. PR pendiente de revisión; no fusionar hasta CI verde.

## 2026-11-17 — CI failure reproduced and scoped fix
- Run [44036734451](https://github.com/edwinrodri12/Tarvoka/actions/runs/44036734451), job 133881300638: **FAILED** because the SaveCodec negative JSON case emits the expected Godot engine diagnostic `ERROR: Parse JSON failed...` despite printing its exact PASS marker. The transit, rules, session/victory, and AI steps all passed in that run.
- Workflow fix `c60cae0f`: accept exactly one known malformed-JSON diagnostic in `test_save_codec`, continue rejecting all other Godot errors and require the exact suite PASS marker. This changes only CI interpretation, not production code.
- **New workflow CI: PENDING** until a run of the fix completes. Android device: **NO EJECUTADO EN DISPOSITIVO**. No merge authorized on this evidence alone.

## 2026-11-17 — Determinismo ante permutaciones de ocupación
- El escenario de corredor aliado se vuelve a consultar con las listas de aliados y bloqueos en orden inverso y con una segunda consulta idéntica.
- Criterio: ambos diccionarios de casillas/costes deben coincidir exactamente con el resultado original; las listas reordenadas no deben mutarse.
- Código: commit `7059fc677185b09605d0507c38aed6dbb9fc9552`.
- CI confirmado para el commit anterior `16cdf7b4`: [regresión táctica 44043718904](https://github.com/edwinrodri12/Tarvoka/actions/runs/44043718904) PASÓ; [exportación Android 44043718910](https://github.com/edwinrodri12/Tarvoka/actions/runs/44043718910) PASÓ; [workflow general 44043718915](https://github.com/edwinrodri12/Tarvoka/actions/runs/44043718915) FALLÓ. Estas ejecuciones **no** validan el nuevo test.
- Nuevo test: **NO EJECUTADO** hasta obtener CI del commit; Android físico: **NO EJECUTADO EN DISPOSITIVO**. Mantener la PR draft hasta resolver la validación e integración.

## 2026-11-17 — Esquina superior izquierda en mapa 24×18
- Commit de prueba `2b9fadcd46ee8cdc7423d3c0c1cfcd138262ec44`: caso espejo del borde inferior derecho, con origen (0,0), aliado (1,0) y enemigo (0,1). Verifica llegada a (2,0) con coste 2, exclusión del aliado como destino, ausencia de coordenadas negativas e inmutabilidad de entradas.
- Reproducción: `godot --headless --path . --script res://tests/test_allied_transit_endpoints.gd`. Después ejecutar reglas, sesión/victoria, IA y guardado mediante el workflow de la rama.
- **Godot 4.3: NO EJECUTADO** para este commit; **Android: NO EJECUTADO EN DISPOSITIVO**. No se modifica lógica de producción ni se autoriza merge.

## 2026-11-17 — Carretera motorizada en borde 24×18
- Código `cca10ec4b500475dd9c8b5542f590705a57fc53b`: corredor en fila 17, aliado en (22,17), destino libre (23,17), enemigo que bloquea el desvío por (21,16). Las dos casillas de carretera cuestan juntas 1 punto para vehículo motorizado; infantería con presupuesto 1 no llega. El aliado no es destino legal; se comprueba inmutabilidad de mapa y ocupación.
- Reproducir: `godot --headless --path . --script res://tests/test_allied_transit_endpoints.gd`; después ejecutar reglas, sesión/victoria, IA y guardado.
- **Godot 4.3/CI del commit nuevo: NO EJECUTADO/NO CONFIRMADO. Android físico: NO EJECUTADO EN DISPOSITIVO.** No hay cambios de producción, balance ni merge.

## 2026-11-17 — Maximum supported map 40×30

Commit `58a4eff1e5e0cce9f3c4a8fc2005e92a45e08a19` adds a 40×30 corner scenario with two allied occupants at (38,29) and (39,29), enemy at (37,28), and origin (37,29). Verify neither ally is a legal endpoint, (38,28) is reachable for cost 2 via the first ally, no coordinate wraps past x=39/y=29, and terrain/occupancy inputs remain unchanged. No production logic changed.

Run: `godot --headless --path . --script res://tests/test_allied_transit_endpoints.gd`; expected exactly one `PASS: allied transit and endpoint isolation`. Godot 4.3 CI on this commit: **NO CONFIRMADO**. Android físico: **NO EJECUTADO EN DISPOSITIVO**. Prior successful CI runs do not validate this addition. Before merge, verify this suite and the movement/AI/save/victory regression set.
