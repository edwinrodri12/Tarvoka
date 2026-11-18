# TARVOKA v3.8.5 — Qué ocurre justo antes de cerrar la ronda

**18 de noviembre de 2026 — análisis de partidas REALES, sin modificaciones a las reglas.**

## Estado y origen

La [matriz v3.8.2](https://github.com/edwinrodri12/Tarvoka/actions/runs/44333940336) aprobó **9/9** trabajos con 16 partidas originales modernas 40×30 más 16 reflejos: 14 victorias de quien responde y 2 de quien inicia. La investigación [v3.8.4](https://github.com/edwinrodri12/Tarvoka/actions/runs/44354412561) comprobó en **32 estados con propiedad de relés fijada** que el código no entrega puntos automáticos adicionales al segundo jugador. Sin embargo, esa prueba no incluía capturas reales.

**Advertencia v3.8.3:** la prueba de órdenes iniciales igualados [v3.8.3](https://github.com/edwinrodri12/Tarvoka/actions/runs/44344372688) sólo terminó satisfactoriamente en seis de ocho escenarios. Ambos casos costeros fallaron por **nuevas divergencias de IA entre reflejos** en la condición experimental, y fueron finalmente detenidos por límite de tiempo. Sus resultados no deben agregarse como si hubiesen pasado. Este informe **no usa** ese contrafactual; se basa en el escenario oficial original (ya validado en v3.8.2), sin cambiar el número de órdenes iniciales.

## Pregunta concreta

¿Hasta qué punto el segundo jugador aprovecha el hecho de **actuar después de la primera mitad de la ronda y justo antes de la liquidación de puntos** para capturar, retener o arrebatar relés?

## Método v3.8.5

- Reutilizar el estado real de `BattleSession`, `BasicAI.step`, `RelayControl` y el registro de cada acción de la prueba v3.7.9, con el arreglo logístico probado en v3.8.2.
- Repetir las mismas **16 condiciones independientes**: semillas 630–633 × niebla sí/no × primer jugador de color 0/1. Cada sesión tiene **un espejo de validación**: 32 partidas reales, pero sólo 16 muestras de victoria.
- **Máximo 24 medios turnos**. No atribuir una victoria a partidas que no concluyan naturalmente; el contrato actual exige ganador auténtico, como en la matriz verificada.
- Por cada ronda completa medir las propiedades de relés en tres momentos: *comienzo de ronda*, *después del fin del turno del primero*, y *después del fin del turno del segundo / liquidación*.
- Para cada momento de captura, registrar posición del relé y color propietario anterior/nuevo. Distinguir capturas de nodos neutrales y arrebatos directos al adversario.
- Comprobar que el primer medio turno **no deposita señal**, que la suma tras el segundo corresponde exactamente a los relés retenidos después de la respuesta y que la victoria reportada coincide con la contabilización original.
- Contar órdenes de apertura realmente realizadas. El primero tiene **3** y quien responde usa la secuencia legal sin límite adicional; esta prueba no interviene en ello.
- Entregar JSON exhaustivo con el registro por ronda e informe Markdown con las capturas por fase, mapa y niebla. El agregador no acepta muestras duplicadas, ejecuciones faltantes o discrepancias de puntuación.

## Qué puede demostrar y qué no

Si el segundo adquiere más objetivos en la mitad final de la ronda, el comportamiento es una *oportunidad táctica* que merece estudio, **no** un bono ilegal de la contabilidad. Incluso si sus capturas coinciden con una victoria, una captura aislada no demuestra que fuese la causa exclusiva: cuenta también el historial de señal acumulada.

Esta prueba no cambia puntuación, movimiento, daño, IA, dinero, suministros, visibilidad, tiempos, apertura, reglas de victoria, partidas guardadas ni APK. Ni debe usarse para aprobar inmediatamente nuevas bonificaciones económicas o una limitación de apertura.

**Rama independiente basada en la v3.8.2 validada**, de modo que las dos pruebas fallidas de la intervención de apertura v3.8.3 no contaminan esta auditoría. Requiere CI completa antes de afirmar resultados; PR draft sin fusión.
