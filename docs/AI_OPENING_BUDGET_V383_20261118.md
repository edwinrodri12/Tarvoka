# TARVOKA v3.8.3 — Aislar ventaja de iniciativa por número de órdenes iniciales

**18 noviembre 2026, investigación experimental / NO fusionar.**

## Evidencia v3.8.2

- [CI focalizada v382](https://github.com/edwinrodri12/Tarvoka/actions/runs/44333940211): pasó el escenario costero con niebla con ambos iniciadores y reflejos exactos.
- [CI extendida v381 sobre la reparación](https://github.com/edwinrodri12/Tarvoka/actions/runs/44333940336): **9/9 trabajos exitosos**, 16 condiciones originales + 16 reflejos, todos con ganador real antes de 24 medios turnos, cero divergencias; 190 ataques, 424 compras.
- De las 16 condiciones originales en 40×30, **2 ganadas por el primero y 14 por el segundo**. Sin niebla: 2 vs 6. Con niebla: 0 vs 8. Este resultado NO es una tasa generalizable ni justifica otorgar dinero, producción o bonificaciones automáticas.

### Mecanismo candidato verificable

El modo de apertura existente `OpeningBalance.gd` limita **solamente al primer jugador** a tres órdenes. El inicio del segundo no tiene un límite excepcional; es un turno completo, como todos los turnos posteriores. Por tanto, una interpretación plausible de 14/16 es una diferencia de oportunidad temprana, además de geometría y relés. **No está demostrado aún que sea la causa**.

## Contrafactual

A igualdad exacta de mapa 40×30, seed, unidades, IA nivel 12, relés, niebla, economía `symmetric_first_income`, daño y suministros, ejecutar:

1. **Base sin cambios:** iniciador puede realizar 3 órdenes, respondedor todas las órdenes legales de su primera respuesta.
2. **Apertura igualitaria SOLO en el test:** iniciador usa sus 3 órdenes originales y el respondedor **decide finalizar voluntariamente su primer turno después de su tercera acción legal de `BasicAI.step`**. No se cambia ninguna función del motor; finaliza con `BattleSession.end_turn`. Los turnos posteriores tienen siempre las reglas normales.

La prueba exige que las tres órdenes reales de ambos jugadores **antes de la intervención** sean idénticas en las dos condiciones. Nada más puede explicar una diferencia; la segunda condición actúa como una política de finalización alternativa, no una regla aprobada.

- 4 semillas: 630 puentes, 631 costa, 632 campo abierto, 633 bosque; niebla sí/no; primer bando 0/1.
- 16 situaciones emparejadas, 2 políticas cada una, cada política con una repetición exacta reflejada: **64 partidas reales**, 16 muestras estadísticas por política (los reflejos solo validan simetría).
- Ventana de hasta **32 medios turnos** o ganador natural. Un juego al límite es **censurado**, jamás empate.
- Métricas: número real de órdenes iniciales de ambas partes, victorias del primero/segundo, ataque inicial, primera captura de relés y ciudad, duración, compras, ataques, señal final, censuras.
- Todo se ejecuta mediante `Study._play` o la misma secuencia legal de `BasicAI.step` + `BattleSession.end_turn` y se compara cada acción y estado contra su espejo.
- Agregación con verificación estricta de cardinalidad, condiciones, acciones iniciales idénticas y denominadores correctos.

## Criterios de interpretación

Si igualar a 3 reduce sistemáticamente el resultado favorable al segundo jugador, ello justificaría **considerar** una apertura igualmente limitada como opción de diseño para pruebas. Si no lo reduce, no se debe modificar ninguna regla por intuición: el siguiente candidato serían las capturas de relé y el punto de liquidación al final de la ronda (que en este modo ocurre tras la respuesta del segundo).

Esta prueba no demuestra por sí sola que un diseño sea más divertido o justo con personas reales. Se necesitarían más semillas, otros niveles de IA y partidas humanas antes de dar por finalizado el balance.

**No modifica archivos de producción, ni ingreso inicial, ni balance oficial, ni APK, ni `main`. PR draft, sin auto-merge.**
