# TARVOKA v3.8.7 — Sensibilidad de la apertura: respuesta de 4 o 5 órdenes

**18 noviembre 2026 — investigación experimental sobre la IA oficial; ninguna regla nueva está aprobada.**

## Resultado establecido antes de este experimento

La corrección mínima de logística [v3.8.6 PR #593](https://github.com/edwinrodri12/Tarvoka/pull/593) corrigió el desempate entre dos entregas de camión al mismo coste, independientemente del orden de exploración, usando coordenadas relativas a cada facción. Validación verificable:

- [CI focalizada v3.8.6](https://github.com/edwinrodri12/Tarvoka/actions/runs/44360735359): **4/4** casos costeros con/sin niebla y ambos iniciadores.
- [CI completa v3.8.3 sobre la corrección](https://github.com/edwinrodri12/Tarvoka/actions/runs/44360733728): **9/9** (16 parejas independientes; 64 partidas reales contando reflejos); sin divergencias ni censuras.
- [CI regresión 40×30](https://github.com/edwinrodri12/Tarvoka/actions/runs/44360733362): **9/9** y 16 ganadores reales entre las 16 condiciones originales.

La matriz completa v3.8.3 reveló un efecto no uniforme del límite 3 vs respuesta libre:

| Política inicial | Sin niebla: gana primero / segundo | Con niebla: gana primero / segundo | Global primero / segundo |
|---|---|---|---|
| Apertura actual: primero 3 órdenes, respuesta hasta 7–8 | 2 / 6 | 0 / 8 | **2 / 14** |
| Contrafactual de 3 órdenes para ambos | 0 / 8 | 6 / 2 | **6 / 10** |

Limitar a 3 la respuesta reduce la ventaja de quien responde **con niebla**, pero en estas cuatro plantillas favorece todavía más a quien responde **sin niebla**. Por ello, **no proponer una regla general basada solo en cap 3**.

## Pregunta de la v3.8.7

Con las **mismas partidas de 40×30**, semillas, presupuesto y IA, ¿un límite *intermedio* en la primera respuesta de **4 o 5 órdenes** produce resultados menos polarizados entre mapas con y sin niebla?

Este barrido mantiene el límite de **3 órdenes del iniciador** durante su primer turno y prueba solamente cuándo quien responde finaliza **voluntariamente** su primera mitad de ronda:

- **Política A (cap 4):** iniciar 3 órdenes, responder 4, turnos siguientes sin límite adicional.
- **Política B (cap 5):** iniciar 3 órdenes, responder 5, turnos siguientes sin límite adicional.
- Ambas reutilizan la función `Matched._play_equal_response` validada en v3.8.3, ahora con parámetro opcional `response_cap` y valor predeterminado 3. Las llamadas antiguas a esa función preservan el mismo comportamiento.
- **No cambia ninguna regla del motor:** solamente el simulador de la prueba decide llamar antes a `BattleSession.end_turn`.
- Repetir 4 terrenos (semillas 630–633) × niebla sí/no × iniciador 0/1 = **16 condiciones emparejadas**. Para cada condición, dos políticas; para cada política, partida original y partida reflejada. **64 partidas autoritativas; 16 muestras de resultado originales por política**. Espejos no son muestras nuevas.
- Máximo **32 medios turnos**; si falta ganador al límite, resultado **censurado**, nunca empate fabricado.
- Para cada condición, el registro completo del par reflejado debe ser idéntico después de normalizar coordenadas, unidades, decisiones, economía, puntos y exploración. Cualquier divergencia reprueba el estudio.
- Las tres primeras órdenes del iniciador y las **cuatro primeras de quien responde** deben coincidir entre las políticas A y B; de lo contrario no existe una comparación causal válida.
- Informar victorias por momento de iniciativa, niebla, plantilla, duración, ataque, compras, primer enfrentamiento, capturas y señal final. Agregador estricto sin datos duplicados, faltantes ni espejos duplicados.

## Criterios antes de decidir el balance

No se busca artificialmente un 50/50 en cuatro terrenos. Si el cap 4 o 5 mejora las dos condiciones de visibilidad en la muestra y no introduce efectos indeseados, considerar **otras semillas y más configuraciones de IA** antes de seleccionar una política de apertura. Si ninguno mejora ambas, la siguiente investigación debe considerar la interacción de visibilidad, primeras órdenes y capturas de relés (v3.8.5: 24 eventos del primero y 36 del respondedor en 146 rondas).

**No cambiar dinero ni recursos iniciales, otorgar ingresos al segundo, cambiar la captura/contabilidad de relés, IA, combate, dominio, guardados ni APK. PR DRAFT independiente basado en la reparación validada #593, sin merge a main.**
