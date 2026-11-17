# TARVOKA — IA v3.6: defensa anticipada con pronóstico de movimientos enemigos

**17 de noviembre de 2026 | Implementación experimental | PR borrador #552**
**No integrada en `main` ni distribuida en APK.**

## Estado anterior comprobado

La IA v3.5 ya completó con éxito **11/11 trabajos** en [GitHub Actions 44161490604](https://github.com/edwinrodri12/Tarvoka/actions/runs/44161490604), incluidos el posicionamiento de la artillería sobre montaña, fuego combinado, bosques, captura y niebla. V3.6 añade una etapa de **protección anticipada**, sin tocar esas reglas.

Hasta v3.5, `BasicAI._defensive_retreat` consideraba una amenaza inmediata desde la ubicación actual del rival, no todos los movimientos legítimos que el adversario visible podría realizar **en su próximo turno**. Esto podía dejar una artillería de 8 HP a tres o cuatro casillas de un tanque capaz de avanzar y destruirla, aunque hubiera un refugio.

## Qué hace efectivamente

`NextTurnThreatV36.gd` construye una estimación conservadora para los próximos movimientos de **rivales actualmente visibles**:

1. Obtiene el estado que el bando puede observar mediante `Visibility.observed_state`; los enemigos invisibles no existen para el pronóstico.
2. Considera que cada rival visible podrá iniciar el turno con su velocidad completa y podrá disparar al finalizar un desplazamiento, exactamente como el jugador. El clima, tipo de unidad, tipo de dominio, terreno y alcance siguen las reglas existentes de `Rules.reachable` y `Turns.in_attack_range`.
3. Para cada posible posición de fuego, usa `BattleActions.public_preview_exchange` con cobertura urbana, bosque, montaña, desniveles, defensa del objetivo y armamento real. Los valores privados de **munición, combustible, acción y reacción enemigas** nunca se consultan para decidir: se supone conservadoramente que podrían disponer del equipo.
4. **Nivel 8–10:** mide el mayor impacto individual previsto. **Niveles 11–12:** también mide la suma de dos disparos de **enemigos distintos** contra el mismo objetivo (sobreestimación conservadora, no una predicción perfecta de estrategia).
5. Solo ofrece una orden defensiva cuando el daño anticipado podría **derrotar** a la unidad y existe al menos una casilla accesible con riesgo previsto menor que sus HP.
6. Entre destinos seguros, valora reducción de riesgo, cobertura real, conservación de unidades caras/especializadas, coste de desplazamiento y distancia al enemigo. La infantería que captura **no huye automáticamente** cuando puede sobrevivir; cuando el daño sería letal, sobrevivir pesa más que terminar esa captura.
7. `BasicAI` sigue dando mayor prioridad a remates garantizados, acciones urgentes del turno actual, fuego combinado y posiciones capaces de asegurar una eliminación. El planificador v3.6 interviene antes de invertir un disparo **individual no letal** en una unidad que podría ser destruida al turno siguiente.
8. La ejecución es un único movimiento **autorizado por `BattleSession.move`**, no una acción extra ni una manipulación directa del tablero.

## Lo que no significa

- **No es una predicción exacta del enemigo**: se analiza un envolvente de movimientos legales, no lo que el adversario realmente escogerá. El enemigo podría retirarse, gastar munición en otro blanco, poner una pieza de apoyo o no ser visible cuando comience su turno.
- **No hace trampas**: la IA no conoce posiciones tras la niebla, recursos privados del enemigo ni terreno no explorado; el conocimiento incompleto puede subestimar riesgos, por lo que una casilla «segura» es segura *solo frente a rivales actualmente observados*.
- **No cambia números**: 12 niveles, 11 doctrinas, costes, salud, daños, economía, munición, facciones y tecnologías son idénticos. No se añade un escudo, contrataque, rango ni acción gratuita.
- **No sustituye toda la defensa**: la evaluación de captura, apoyo, suministros y retirada inmediatamente letal sigue en `BasicAI` y misiones v3.3.
- **No usa ya evoluciones ni poderes de comandantes**: estos sistemas siguen pendientes de APIs autoritativas de `BattleSession` ([seguimiento #534](https://github.com/edwinrodri12/Tarvoka/issues/534)).

## Seguridad y rendimiento de la búsqueda

Se examinan como máximo **5 unidades propias**, **6 enemigos visibles** y **9 destinos legales por unidad**, frente al caso explosivo de valorar cada posible posición de todas las tropas en un mapa 40×30. Se reutilizan posiciones de movimiento enemigas durante la evaluación de cada candidato. Eso impone un límite al espacio de decisiones, pero el coste real de CPU y batería debe medirse en Android.

Nunca se prueban movimientos especulativos contra el `BattleSession` autoritativo para averiguar si un enemigo oculto ocupa una casilla. Solo se propone un destino y se intenta una vez.

## Pruebas preparadas

`tests/test_ai_next_turn_threat_v36.gd` debe verificar:
- Artillería SPG de 8 HP que todavía está fuera de alcance, pero podría ser destruida por un tanque de 8 de ataque **tras mover** el próximo turno.
- Efecto cuantitativo del bosque y la montaña (valores del motor, sin escudos inventados).
- Infantería de 10 HP que conserva su ciudad ante ataque previsto de 7; si baja a 6 HP, buscar refugio en lugar de quedarse a morir.
- Baluarte de 12 HP que sobrevive a un tanque pero quedaría destruido por dos distintos; reconocer este riesgo solo en niveles 11–12.
- Cambiar posición/HP de enemigo **oculto**, y manipular munición/combustible/flag de actuación **privados** de enemigo visible: el pronóstico no debe alterarse.
- Búsquedas de tamaño controlado 24×18 y 40×30.
- Guardado válido y mismo dinero/HP antes y después de la orden de movimiento.
- **11 suites anteriores** de IA v3.5, fuego combinado, misiones, dificultad/menu, retiradas, niebla, autojuego, economía y multidominio.

## Evaluaciones necesarias antes de fusionar

1. **Evitar una IA cobarde:** medir cuántas veces el algoritmo renuncia a conquistar o disparar por un riesgo que no se materializa. Los niveles altos deben ser ambiciosos cuando su costo/beneficio lo justifique.
2. **Torneos controlados:** enfrentar v3.5 vs v3.6 en ambos lados, con estrategias variadas y semillas de mapas certificados. Mantener victorias, derrotas, censura y cambios de política por mapa.
3. **Rendimiento y batería:** mediciones en Android 10×8 / 24×18 / 40×30 con mucha visibilidad; no solo simulaciones cortas.
4. **Coordinación real de defensa:** extender de una retirada por movimiento a proteger con interceptores/antiaéreo y sostener posiciones sin sacrificar artillería por la primera escaramuza.
5. **Poderes/evoluciones:** solo después de implementar órdenes legales del motor, probar contraejemplos de tecnologías I/II/III, habilidades y campamentos.

La CI v3.6 debe aprobarse antes de anunciar la funcionalidad como validada. PR #552: https://github.com/edwinrodri12/Tarvoka/pull/552.
