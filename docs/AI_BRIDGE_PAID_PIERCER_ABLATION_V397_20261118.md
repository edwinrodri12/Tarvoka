# TARVOKA v3.9.7 — Experimento quirúrgico: presencia de Piercer frente al gasto de 300 créditos

**18 de noviembre de 2026. Hipótesis experimental — retirar una unidad comprada NO es una acción permitida dentro del juego. Solo simulador de pruebas.**

## Evidencia disponible

1. [v3.9.4, 9/9 CI](https://github.com/edwinrodri12/Tarvoka/actions/runs/44425512681): ocho semillas de doble puente 40×30 sin niebla, ambos iniciadores, 16 condiciones originales por política. Con respuesta oficial (8 órdenes) o respuesta de prueba cap5, el segundo ganó 16/16; con cap3 ganó primero 14/16.
2. [v3.9.5, 9/9 CI](https://github.com/edwinrodri12/Tarvoka/actions/runs/44428593629): cap4 cambia el resultado con respecto de cap3 de 14/16 partidas, aunque el iniciador captura el primer relé en ambos casos; con cap4 gana segundo 16/16, duración media 17,5 medios turnos. La cuarta orden fue siempre fabricar una unidad Piercer `N3` por **300**; la quinta fue un movimiento de `C/Z`. Con cap5 vuelve a 12 medios turnos.
3. [v3.9.6](https://github.com/edwinrodri12/Tarvoka/actions/runs/44430688399) estudia movimientos y combate reales de la unidad N3 en tres semillas contrastantes (634/650/658). Su CI estaba en curso al preparar v3.9.7; **no tratar sus resultados como confirmados antes de cerrar la ejecución**.

**Pregunta v3.9.7:** ¿cuánto del cambio bajo cap4 se debe a la presencia física de la nueva unidad y sus interacciones, en vez de solamente gastar 300 créditos?

## Intervención controlada

En cada mismo mapa, ambos iniciadores, tres variantes:

- **Cap3:** se acaba voluntariamente la primera respuesta tras tres órdenes. La cuarta compra NO ocurre.
- **Cap4 real:** se permiten cuatro órdenes legales; la cuarta es compra de Piercer N3 por 300. Sigue la partida normal.
- **Cap4 sin cuerpo de Piercer:** se realizan exactamente las mismas cuatro órdenes legales, incluido el pago real y el registro de producción en el taller. **Después de la cuarta orden, pero antes de ejecutar `BattleSession.end_turn`, únicamente el simulador ELIMINA del arreglo de unidades el Piercer N3** que acababa de fabricarse. Ningún crédito se devuelve, no se reinicia la fábrica, no se cambia el estado de otra unidad ni se modifican manualmente puntuación, turnos, mapa, niebla o IA.

Esta intervención **es una situación físicamente imposible del juego normal**, señalada en un `research_ablate_piercer_v397` y restringida con un parámetro opcional por defecto **false** en el simulador de pruebas `Matched._play_equal_response`. Es una manera explícita de aislar consecuencias de la presencia de un cuerpo táctico después de comprarlo, conservando el gasto y la fábrica. No sirve como mecánica para jugadores ni como balance propuesto.

## Salvaguardas

- La modificación opt-in solo permite `response_cap == 4`, `phase == 1`, y requiere exactamente una unidad `N3` del respondedor, rol `piercer`. La elimina **una sola vez**.
- Exige `Economy.valid`, `RelayControl.valid` y `SaveCodec.encode` sobre el estado de investigación.
- Antes de esa eliminación, `cap4` y `ablated` tienen exactamente las **mismas tres acciones del iniciador, cuatro del respondedor y todo el mismo estado**. El archivo de prueba construye a partir del estado de cap4 la única diferencia permitida (quitar N3) y exige **igualdad completa** con el estado intervenido: mismas unidades restantes, puntos de vida, créditos, instalaciones, niebla, turnos, objetivos, mapa y puntuación, sin excepciones.
- Después de ese punto, los turnos avanzan por `Session.end_turn`, `BasicAI.step` y reglas oficiales; cada variante y su reflejo horizontal repiten todos los estados y acciones, sin divergencias.
- Se examinan **tres semillas**: 634 y 658 (cap3 cambia ganador), 650 (incluso cap3 gana segundo), ambos colores. **6 condiciones originales por política**, × 3 políticas × reflejo = **36 partidas reales**; reflejos son paridad, no muestras adicionales.
- Horizonte de hasta 40 medios turnos. Partida sin ganador natural se marca censurada, nunca empate inventado.
- Reporte Python estricto JSON/Markdown con ganadores, duración, primera captura y cambios de ganador. CI: **3 shards Godot 4.3 y agregador**, 4 trabajos.

## Interpretación limitada

- Si la ablation revierte el resultado de cap4, la presencia de N3 **y sus consecuencias posteriores** contribuyen al resultado en estos mapas; **no prueba** que su daño de combate sea el mecanismo (podría ser ocupación, amenaza, blanco de IA, retraso o captura).
- Si no revierte el resultado, la compra por 300, su consumo del turno de fábrica, los cambios de objetivos o las decisiones posteriores podrían influir. Necesitaríamos experimentos separados para aislar cada cosa.
- No extrapolar a mapas sin puentes, con niebla, otros niveles de IA ni partidas humanas; las semillas son **ya conocidas**, no una muestra nueva.

**Ningún archivo de producción modificado.** El trabajo se conserva como PR DRAFT basado en #611, sin fusionar con `main`, sin cambios de balances reales ni APK.
