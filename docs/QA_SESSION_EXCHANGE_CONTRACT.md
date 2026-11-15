# BattleSession exchange contract — 2026-11-15

Scope: isolated headless regression against the real BattleSession.attack API on main, not the draft mountain/flanking implementation.

Run: `godot --headless --path . --script res://tests/test_session_exchange_contract.gd` (Godot 4.3).

Acceptance:
- A surviving defender yields the same damage, retaliation and HP as the deterministic BattleActions preview.
- Attack consumes the acting unit's action; replay is rejected.
- Caller state remains unchanged after the attack.
- A lethal opening hit prevents retaliation, declares faction 0 victorious and rejects further attacks/end-turn.
- The pre-attack state remains unchanged.

Evidence: file creation verified in GitHub commit b643d5c2. Godot execution, Android export, physical Android, AI, save/load and UI validation: **NO EJECUTADO** in this run. CI must execute this new test before merging. This does not validate PR #334's mountain-specific modifiers or PR #203's visual terrain.


## CI específico (2026-11-15)
Se añadió `.github/workflows/battle-session-exchange.yml` en esta rama para ejecutar la regresión con Godot 4.3 headless, `timeout` de 90 segundos, búsqueda de errores y marcador PASS obligatorio. Commit del workflow: `cb57760a9dec58bac07fcd69f10701eb1e7da3aa`. **Ejecución del workflow: NO EJECUTADO / sin resultados asociados al commit al consultar GitHub.** Esto no equivale a prueba física Android ni a verificación de IA/guardado. La PR sigue en borrador y no debe fusionarse antes de CI satisfactoria.

## Regresión de persistencia tras intercambio (2026-11-15)
Commit `f73c973d1de8ba6e0c669d5d9c690b7d4eb4a109`: la misma prueba ahora codifica y decodifica el estado después del ataque usando `SaveCodec`, compara HP, bandos y acciones consumidas, rechaza repetir el ataque y comprueba el cambio de turno. Además, guarda y restaura una victoria decisiva y confirma que ni ataques ni cambios de turno vuelvan a habilitarse.

**Alcance:** prueba de serialización en memoria; NO demuestra escritura física `user://`, recuperación de respaldo, cierre/reapertura de Android ni rendimiento. **Godot 4.3: NO EJECUTADO** hasta obtener resultado CI del nuevo commit. **Android físico: NO EJECUTADO EN DISPOSITIVO**. **Regresiones IA y SaveStore: NO EJECUTADO**. No fusionar sin comprobar el nuevo SHA.

## Escritura física y recuperación aislada (2026-11-15)

Commit `4fbc0613bc25105dcdc3d1f3075d6b1c20e0ce83`: la regresión ejecuta `SaveStore.save/load_report` sobre `user://tarvoka_session_exchange_contract_test.json`, confirma lectura del primer guardado, guarda una victoria posterior para crear `.bak`, corrompe deliberadamente solo el archivo de prueba principal y exige recuperar el estado anterior con `recovered=true`. Comprueba que el ataque ya consumido sigue rechazado y elimina los tres archivos temporales de prueba al terminar. **No usa ni borra la partida real** `tarvoka_battle_v1.json`.

**Estado al crear este commit:** implementación registrada; ejecución del nuevo SHA en Godot 4.3/CI **PENDIENTE**. Esta prueba verifica disco del entorno CI, **NO EJECUTADO EN DISPOSITIVO ANDROID**; tampoco demuestra supervivencia al cierre/reapertura del proceso móvil. Regresiones de IA y victoria global pendientes de verificar en el mismo SHA. No fusionar sin CI verde y revisión de fallos externos.

## Corrección CI de recuperación (2026-11-15)

La ejecución [43697584172](https://github.com/edwinrodri12/Tarvoka/actions/runs/43697584172) produjo el marcador PASS y verificó recuperación del respaldo, pero el job falló porque el fixture `{invalid json` emitía `ERROR: Parse JSON failed` en Godot. El gate CI rechaza correctamente cualquier línea `ERROR:`. Commit `0de919373d33cfa9114c7a0997579350b401e035`: reemplaza ese fixture por JSON **sintácticamente válido pero incompatible con el esquema** (`version=999`), manteniendo la prueba de rechazo de principal inválido y recuperación de `.bak` sin ruido de parser. No se cambió SaveStore, SaveCodec ni el formato de partidas.

La ejecución general [43697584025](https://github.com/edwinrodri12/Tarvoka/actions/runs/43697584025) falló por una dependencia artística distinta: `BastionStudioAdapter.gd` no puede resolver `CombinedArtStudioWeb.gd` durante importación HQ V15. Este fallo no es evidencia de una regresión de SaveStore. Pendiente verificar CI de este nuevo commit y resolver el problema de arte en la rama responsable, sin alterar componentes paralelos.

Android físico: **NO EJECUTADO EN DISPOSITIVO**. La recuperación en proceso reiniciado y las regresiones IA/victoria completas siguen pendientes.

## Regresión adicional — ambas copias inválidas (2026-11-15)
El test invalida el principal y el respaldo con JSON sintácticamente correcto pero esquema incompatible. `SaveStore.load_report` debe devolver estado vacío, `SaveStore.load` no debe inventar una partida y el estado previamente recuperado en memoria debe permanecer intacto. Los archivos temporales de la prueba se eliminan al terminar. **Godot 4.3 CI: NO EJECUTADO para este commit; Android físico: NO EJECUTADO.**


## Recuperación sin archivo principal (2026-11-15)

Commit `8623a19be2bcc83d45ce9a7f42489ef49852922d`: caso adicional aislado. Se guardan dos estados sucesivos, se elimina únicamente el archivo principal y se exige recuperar desde `.bak` el estado anterior (HP, acción consumida y facción intactos). Se comprueba que el ataque gastado continúa rechazado y se eliminan los archivos de prueba. No modifica SaveStore ni las partidas reales.

**Estado:** cambio registrado; Godot 4.3 del nuevo SHA **NO EJECUTADO** hasta disponer de CI; Android físico **NO EJECUTADO EN DISPOSITIVO**. La ejecución del SHA anterior `088f9663` pasó la suite específica (run 43707692340), pero falló la suite general (43707692316). No extrapolar esos resultados a este commit. Pendiente: comprobar CI específico y regresiones de IA/guardado/victoria, investigar el fallo general por separado.

## Ranura vacía sin recuperación fantasma (2026-11-15)

Tras eliminar los archivos exclusivos del test, la suite vuelve a invocar `SaveStore.load_report` y `SaveStore.load`. Exige estado vacío, `recovered=false` y ausencia de archivos principal y `.bak`. Esto cubre una instalación nueva o una ranura limpiada, sin modificar el código de producción ni tocar partidas reales. Commit de prueba: `67a78c8984390156f48ca66a96a38a20e18caa81`.

**Godot 4.3 para este cambio: NO EJECUTADO hasta obtener CI del SHA nuevo. Android físico: NO EJECUTADO EN DISPOSITIVO.** El SHA anterior `5f6c778` sí pasó el workflow específico y Android export, pero falló CI general; esos resultados no certifican este cambio.

## Continuación táctica tras recuperar respaldo (2026-11-15)

La regresión de `test_session_exchange_contract.gd` ahora reanuda una partida recuperada de `.bak`: cambia al bando 1, conserva HP de ambos combatientes, impide reutilizar la acción consumida del atacante original, permite un ataque legal del defensor en su turno y bloquea repetir ese ataque. También comprueba que el estado recuperado no se muta al continuar. Commit de prueba `62edfc9efbbd5493bb3e5101bd539f82c6edab20`.

**Estado:** código registrado en rama de PR #356; ejecución Godot 4.3 del nuevo SHA **NO EJECUTADO**, Android físico **NO EJECUTADO EN DISPOSITIVO**. La prueba continúa en un mismo proceso Godot y no certifica cierre/reapertura de la aplicación; se requiere CI verde antes de merge. No modifica reglas ni estadísticas.

## Persistencia entre procesos Godot independientes (2026-11-15)

Se agregó `tests/test_session_cross_process.gd` y se amplió `.github/workflows/battle-session-exchange.yml`. El CI inicia Godot dos veces: `-- --phase=write` guarda una sesión después de atacar; `-- --phase=read` arranca otro proceso, lee el mismo `user://`, verifica HP, facción, acción consumida y continuación legal, y limpia los archivos de prueba. El test no toca la ranura normal del jugador. Si cualquier ejecución genera ERROR, falla una aserción o falta el marcador PASS, el workflow debe fallar.

Commits: `dbdf31525f180e87361f395d396099a2cc516913` (test), `4c50e846d48b61151f3f8b189f73d7d6648d502c` (CI). **Godot/CI del nuevo SHA: NO EJECUTADO hasta comprobar resultado del workflow. Android físico: NO EJECUTADO EN DISPOSITIVO.** Dos procesos Godot en Linux no equivalen a cerrar/reabrir Android. No se modificaron las reglas, estadísticas ni SaveStore.

## Recuperación de respaldo entre procesos (2026-11-15)

Se añadieron fases `backup_write` y `backup_read` a `tests/test_session_cross_process.gd`. Tras el par inicial `write/read`, un nuevo proceso guarda dos estados consecutivos (el segundo crea `.bak`) y reemplaza el principal por JSON sintácticamente válido pero con versión incompatible. Otro proceso independiente debe cargar el respaldo con `recovered=true`, conservar HP, bando y acción gastada, y rechazar repetir el ataque. Las fases limpian únicamente `user://tarvoka_cross_process_contract.json` y sus archivos auxiliares. El workflow ejecuta `write read backup_write backup_read` secuencialmente y falla por errores de Godot o ausencia de cada marcador PASS. Commits `d8c88b4a` y `85bce25f`.

**Estado al registrar:** cambios confirmados en rama PR #356; CI del nuevo SHA sin ejecuciones asociadas al consultar GitHub; prueba física Android **NO EJECUTADO EN DISPOSITIVO**. Esta regresión Linux no valida reinstalación ni firma Android. No fusionar hasta CI satisfactoria y revisión de regresiones generales.


## 2026-11-15 — Respaldo sin archivo principal entre procesos
- `tests/test_session_cross_process.gd` agrega `missing_primary_write` (dos guardados y eliminación del principal) y `missing_primary_read` (nuevo proceso Godot recupera `.bak`, verifica HP, acción consumida y continuación legal del turno).
- `.github/workflows/battle-session-exchange.yml` ejecuta ambas fases después de las anteriores, en el mismo directorio `user://`, con fallo explícito por errores de Godot o ausencia de `PASS`.
- **NO EJECUTADO** en Godot para estos commits hasta obtener CI del SHA correspondiente; **NO EJECUTADO EN DISPOSITIVO** Android. No implica validación de reinicio físico Android ni de firma estable.


## Reanudación persistida después de recuperar respaldo (2026-11-15)

`tests/test_session_cross_process.gd` incorpora `resume_write` y `resume_read`: después de simular la pérdida del principal, otro proceso carga `.bak`, avanza un turno y guarda un nuevo principal; un tercer proceso comprueba que ese turno persistió y que los HP y acciones consumidas no se reiniciaron. El workflow repite `missing_primary_write` para preparar el fixture, sin tocar la ranura real del jugador. Commits de prueba/CI: `122de925`, `211afb50`.

**Estado:** implementación registrada, CI del nuevo SHA **NO EJECUTADO** al documentar; **NO EJECUTADO EN DISPOSITIVO ANDROID**. Requiere validar `Battle session exchange contract`, regresiones IA/victoria y comportamiento de SaveStore antes de merge. No demuestra continuidad de firma APK ni rendimiento móvil.
