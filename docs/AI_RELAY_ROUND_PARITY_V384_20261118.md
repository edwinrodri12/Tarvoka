# TARVOKA v3.8.4 — ¿El marcador de relés regala puntos al segundo jugador?

**18 noviembre 2026. Experimento pequeño de reglas existentes; SIN modificar producción.**

## Motivo de la prueba

La [v3.8.2](https://github.com/edwinrodri12/Tarvoka/actions/runs/44333940336) validó por reflejo 16 condiciones originales de 40×30. En esos escenarios hubo **2 victorias del iniciador y 14 del segundo**, todas por señal de relés. Este efecto fue observado con la IA oficial en una muestra fija pequeña.

La investigación [v3.8.3](https://github.com/edwinrodri12/Tarvoka/pull/589) compara la regla actual (iniciador limitado a 3 órdenes, respuesta libre) contra un contrafactual de 3 órdenes para ambos en la primera oportunidad. La primera batería parcial indica que esa intervención cambia algunos resultados pero no todos; **no hay decisión de diseño aprobada**.

## Esta v3.8.4: control contable aislado y rápido

Las reglas actuales en `RelayControl.finish_turn` capturan cuando la unidad termina el turno sobre el relé, y con `round_scoring=true` **depositan la señal al finalizar los dos medios turnos de una ronda** (payout al final de la respuesta). El sistema `score_winner` también retrasa una declaración de victoria hasta la liquidación de la ronda completa.

Para distinguir **un bono automático de señal** de **una oportunidad táctica de responder antes de la liquidación**, el nuevo contrato crea *instantáneas válidas de propiedad fija* de los relés, y compara el mismo escenario con primero=0 frente a primero=1:

- Cuatro plantillas de 40×30 (semillas 630–633).
- Cuatro distribuciones de propiedad: todos neutrales, empate 2/2, ventaja de color 0 (3/1), ventaja de color 1 (1/3).
- Ambas identidades de jugador inicial con los mismos propietarios. Son **32 evaluaciones de las reglas**, NO 32 partidas de IA.
- Marcador inicial [4,4], objetivo 5. Verificar que la señal no crezca tras el primer medio turno, y tras los dos medios turnos sea [4+propiedad_0, 4+propiedad_1] para ambas órdenes de iniciativa.
- Verificar quién gana según el marcador tras la ronda completa, que los empates no producen ganador, y que el motor no altera la propiedad ni la entrada de la prueba.

**El resultado de esta prueba NO mide ventaja táctica de respuesta**: en partidas reales la propiedad puede cambiar durante el segundo medio turno. Esta prueba solo responde si, manteniendo idéntica la propiedad, la contabilidad por sí sola da un bono al que juega segundo. Si es neutral (como el código indica), investigar luego *cuántos nodos y relés consigue retener cada bando justo antes de liquidar*, usando capturas y estados reales.

## Restricciones

Solo archivo de prueba, CI aislada y documento. No cambiar las reglas ni el límite de 3 órdenes, ni el dinero inicial, daño, transporte, capturas, población, equilibrio, IA oficial ni el APK. CI debe pasar antes de afirmar que el contrato se verificó.
