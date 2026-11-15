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
