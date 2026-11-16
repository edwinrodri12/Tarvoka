# QA — deterministic save encoding (2026-11-16)

Scope: pure SaveCodec encoding, repeated roundtrip and snapshot isolation. Does not modify gameplay, save format or persisted files.

Run: `godot --headless --path . --script res://tests/test_save_encode_determinism.gd`

Acceptance: 20 identical encodes; state remains unchanged; decoded snapshots equal original and do not alias original units; stable encode-decode-encode. CI checks the PASS marker and exit code.

Status: **NO EJECUTADO** until Godot 4.3 workflow completes. Android physical: **NO EJECUTADO EN DISPOSITIVO**. Existing save corruption PR #416 remains independent. If this regression fails, diagnose serialization stability before changing the codec.

2026-11-16 extension: verify invalid negative-HP encoding fails closed without mutating the supplied dictionary, valid encoding still succeeds afterward, and two independently decoded snapshots cannot share nested unit/terrain data. These assertions run in the same 20-cycle test script; Godot and Android status remain unverified until new CI/device evidence.

2026-11-16: Cada una de las 20 iteraciones ahora modifica también el terreno de la copia recuperada y exige que el estado original, su serialización y una nueva decodificación permanezcan idénticos. Commit de prueba 5f16274e; CI Godot 4.3: NO EJECUTADO en esta actualización; Android: NO EJECUTADO EN DISPOSITIVO. No se modificó SaveCodec ni el formato de guardado.

2026-11-16: Se añadió regresión de inmutabilidad del texto serializado frente a modificaciones posteriores de una copia fuente (unidad y terreno). Exige que el JSON previamente generado restaure el estado original y que la fuente modificada produzca una codificación diferente. Commit de prueba `84da974e`; Godot 4.3: NO EJECUTADO en esta ejecución; Android: NO EJECUTADO EN DISPOSITIVO. No se modificó el codec ni el formato.

2026-11-16 CI evidence for previous head `63b210b4`: deterministic-save workflow [43838021464](https://github.com/edwinrodri12/Tarvoka/actions/runs/43838021464) **PASÓ**; Android export [43838021299](https://github.com/edwinrodri12/Tarvoka/actions/runs/43838021299) **PASÓ** (not device verification); general Godot rules [43838021338](https://github.com/edwinrodri12/Tarvoka/actions/runs/43838021338) **FALLÓ**, root cause not established here. The next workflow revision requires exactly one complete PASS line and rejects unexpected Godot `SCRIPT ERROR`, `Assertion failed`, or `ERROR` diagnostics; its own CI result is **NO EJECUTADO** until Actions finishes. Physical Android: **NO EJECUTADO EN DISPOSITIVO**. Keep PR draft; no merge.


## Regresión adicional — 2026-11-16
Diez intentos consecutivos de serializar HP negativo (−1 a −10), cada uno seguido de codificación y decodificación válidas. Se exige rechazo sin mutación de entrada y conservación íntegra de la batalla activa. Commit de prueba `45d05bd8`. **Godot 4.3 en este commit: NO EJECUTADO; Android físico: NO EJECUTADO EN DISPOSITIVO.** La prueba no cambia el formato de guardado ni el motor.

## Aislamiento de serializaciones hermanas — 2026-11-16
Tras recuperar dos copias independientes, la prueba modifica HP y terreno de la primera, la serializa y exige: JSON distinto del original, roundtrip fiel de la copia modificada, JSON original intacto para la segunda copia y para la batalla activa. Código commit `38a20a7c`. Godot 4.3 del nuevo commit: **NO EJECUTADO**; Android físico: **NO EJECUTADO EN DISPOSITIVO**. Mantener PR #448 DRAFT hasta CI y regresiones pertinentes; no altera SaveCodec ni partidas comerciales.

2026-11-16: Extended aliasing checks to mutate **both opposing units** and **opposite corners of the 10×8 terrain** in recovered snapshots. Expected: original and independently decoded snapshots stay unchanged. Godot 4.3 on this commit: **NO EJECUTADO**; Android physical: **NO EJECUTADO EN DISPOSITIVO**. No gameplay rules or save format changed.
