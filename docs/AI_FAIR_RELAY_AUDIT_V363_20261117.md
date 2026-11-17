# TARVOKA — Diagnóstico de relés y ventaja de iniciativa (v3.6.3)

**Experimento de validación, 17 noviembre 2026. No modifica `main`, APK ni las reglas oficiales.**

## Resultados constatados

La [auditoría de apertura equilibrada con 64 partidas](https://github.com/edwinrodri12/Tarvoka/actions/runs/44194478920) terminó con los 10 jobs correctos:

- En 32 A/B: v3.5 **16** victorias; v3.6.3 **16**; primer bando **24** victorias (75 %).
- En 32 partidas con ambas IA iguales, en mapa 0 *Campo abierto* venció primero **4/16** y segundo **12/16**; en mapa 2 *Puentes de la Cuenca* venció primero **16/16** y segundo **0/16**.
- La regla de tres acciones iniciales se usó correctamente; las 32 partidas A/B anteriores sin ella registraron 30/32 victorias del primer jugador.

## Segundo factor verificado en código

`BattleSession.start(...,relay_mode=true, modern_mode=false)` llama `RelayControl.create` con `fair_round=false`. En modalidad clásica, `RelayControl.finish_turn` incrementa el tanteo del bando que acaba de jugar **en cada medio turno**, y `score_winner` permite victoria inmediatamente al superar la meta; el primero puede puntuar/ganar antes de que el segundo responda.

`RelayControl.gd` ya tiene **`round_scoring=true` y `fair_round=true`** para recompensar puntos y evaluar victoria tras una ronda completa. Pero ese modo normalmente también crea **cuatro relés**, así que cambiar a una configuración moderna completa confundiría el diagnóstico.

## Ensayo nuevo: modificar solo cuándo se puntúa

Se mantiene **exactamente la configuración de ambas IA, mapas, cinco unidades por bando, niebla, economía, dos relés clásicos y apertura de tres acciones**. Solo se configura en el estado de *laboratorio*:

```gdscript
state["control"]["fair_round"] = true
state["control"]["round_scoring"] = true
state["control"]["first_faction"] = first
```

Esto conserva las ubicaciones iniciales de los dos relés y usa el motor existente (sin crear reglas artificiales). Se corren otras **64 partidas**: 32 A/B cruzadas y 32 controles espejados con las mismas semillas/dificultades/mapas; el informe contiene victorias, capturas, retiradas, origen de victoria (relés o eliminación) y ventaja del primer turno por mapa.

### Contrato de equivalencia
`tests/test_ai_fair_round_contract_v363.gd` comprueba para cada primer jugador que tras su primera media ronda nadie recibe puntos, tras las respuestas se adjudica exactamente **un punto a cada facción** si ambas tienen su relé, y que el guardado/recarga y ubicaciones permanecen correctos.

### Integración
No se aplica `fair_round` a las partidas existentes. En ausencia de evidencia amplia, **no fusionar**. Si los ensayos indican una mejora significativa y estable, se estudiará cómo ofrecer el modo de puntuación simétrica compatible con guardados, sin romper partidas clásicas; si persiste el sesgo en Puentes, analizar bloqueos de puentes, capturas y balance de unidades.

**Estado:** resultados de esta prueba nuevos pendientes; jamás confundir `PASS` técnico con calidad ya verificada.
