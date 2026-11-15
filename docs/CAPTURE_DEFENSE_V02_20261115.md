# TARVOKA — Fase v0.4: proteger conquistadores y no desperdiciar escoltas

**15 de noviembre de 2026 · rama experimental PR #394 · no integrado a Android ni reglas jugables**

## Motivo

En v0.3 el planificador de apoyo pasó 16 pruebas mecánicas y, en 16 parejas de partidas, aumentó las capturas de 40 a 42, **pero también aumentó interrupciones de 40 a 46** y la renta retenida de 3.500 a 4.500 créditos. Era necesario evaluar si el escolta se exponía innecesariamente y si la IA protegía al ocupante antes de enviar refuerzos.

## Implementación aislada

- **CaptureThreatsV02.gd:** riesgo estimado solo con enemigos actualmente observados, sin consultar fichas ocultas, ubicaciones bajo niebla, contactos caducados ni munición enemiga real. Asume prudentemente un arma cargada al evaluar un enemigo visible. Daño dentro de alcance actual se calcula con el mismo motor de intercambio público del combate. La posible amenaza después de moverse se etiqueta explícitamente como **heurística de proximidad**, no como ataque garantizado.
- **CaptureAwareAIV01.gd:** conserva su comportamiento anterior como predeterminado. Un argumento opcional experimental permite rechazar casillas con daño visible letal o de al menos la mitad de la vida y penalizar opciones próximas a amenazas visibles.
- **CaptureDefensiveAIV02.gd:** prioriza una baja enemiga verificable que amenace al capturador, eligiendo preferentemente un escolta armado para preservar la acción del ocupante. Solo ordena fuego si el ataque es legal, mata al enemigo y no expone al tirador a contraataque letal. Después intenta escolta con análisis de riesgo y, si no hay una orden aceptable, utiliza **BasicAI oficial**.
- **CaptureExperimentV01.gd:** asocia el contador al identificador del ocupante inicial (holder_id). Un relevo no hereda puntos de captura, aunque otra infantería pase inmediatamente a la casilla. El reemplazo comienza un contador nuevo y puede recibir apoyo si el ocupante anterior quedó adyacente.

No se editaron scripts/core/BasicAI.gd, BattleSession.gd, UrbanEconomy.gd, SaveCodec ni la interfaz jugable. El progreso continúa **fuera** del guardado y no se puede activar esta función en partidas reales todavía.

## Evidencia inicial

**10 casos de defensa / fog / sustitución aprobados en Godot 4.3:**
https://github.com/edwinrodri12/Tarvoka/actions/runs/43760500959

Los casos comprueban ambos iniciadores, niebla/no niebla, disparo letal legal de un escolta, elección de una casilla alternativa cuando el refuerzo quedaría destruido y reinicio de progreso al relevar al ocupante.

## Pruebas de partidas de mayor duración

**Workflow A/B:**
https://github.com/edwinrodri12/Tarvoka/actions/runs/43760500942

Configuración: 16 pares espejo = 32 partidas, cuatro mapas × dos iniciativas × niebla sí/no, hasta **48 medias fases** por partida. Ambas variantes usan ciudad 4, instalación 3, bloqueo de ingresos desde 2 puntos y la misma economía/clima. Se compara IA de apoyo v0.3 con IA defensiva v0.4. Se registran disparos defensivos, escoltas, cambios de dueño, avances, interrupciones, ocupantes muertos/que abandonan, compras, créditos e ingresos, partidas decididas y victorias del iniciador.

Las victorias solo se informarán si realmente ocurren; no se inventará una tasa de victoria con partidas inconclusas. Una mejora en capturas sin reducción de bajas/interrupciones no bastaría para activar esta IA.

## Limitaciones y siguientes controles

- La amenaza de movimiento enemigo puede diferir de la heurística: se requiere evaluación de rutas reales sin violar niebla.
- Protección táctica no equivale a maximizar estrategia con ocho jugadores ni al equilibrio de facciones.
- Persistencia y HUD requieren solución propia antes de integración: un contador externo se perdería al reiniciar.
- La CI general conserva un problema ajeno a estas reglas, en la importación visual de CombinedArtStudioWeb.gd / BastionStudioAdapter.gd. El SUCCESS experimental no implica aprobación del CI general.


## Resultados comprobados: IA defensiva v0.4 frente a apoyo v0.3

**Godot 4.3 — SUCCESS:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43760500942

16 parejas espejo (32 partidas), hasta 48 medias fases, mismas reglas de captura/economía/clima, ambos bandos y niebla.

| Indicador por 16 sesiones del mismo brazo | Apoyo v0.3 | Defensiva v0.4 |
|---|---:|---:|
| Conquistas efectivas | 66 | 55 |
| Progresos parciales | 187 | 187 |
| Capturas interrumpidas | 94 | 101 |
| Capturadores muertos al perder el contador | 69 | 71 |
| Capturadores vivos que abandonan | 20 | 22 |
| Compras | 1.024 | 1.056 |
| Disparos especiales de defensa | 0 | 25 |
| Escoltas propuestos | 24 | 23 |
| Rentas retenidas | 14.250 | 14.500 |
| Partidas con vencedor | 4 | 3 |
| Victorias del jugador que comenzó | 0 | 0 |

**Hallazgo crítico:** la nueva IA *sí* interviene y el motor aprueba sus órdenes, pero esta parametrización **empeora los indicadores defensivos que pretendía mejorar**, en particular interrupciones y muertes de ocupantes. No se recomienda su integración. Las escasas partidas decididas y el hecho de que ninguna favoreciera al iniciador son una señal para ampliar las pruebas, **no** prueba de ventaja sistemática del segundo jugador.

## Ajuste conservador v0.5 (pendiente de contraste A/B)

- La variante CaptureDefensiveAIV03.gd no sustituye ataques letales ya elegidos por BasicAI.
- Disparo de escolta obligatorio para protección especial (no gastar la acción del capturador).
- Intervenir únicamente si el daño de una amenaza observada **podría matar al ocupante**, no ante un rasguño.
- Un refuerzo especial solo se moviliza si permite **terminar la captura en la fase propia actual**, y nunca a una casilla con daño enemigo visible mayor o igual a la mitad de su vida.
- Mantener intacta BasicAI como decisión normal y continuar con pruebas emparejadas de 48 medias fases antes de considerar integración.

La prueba mecánica está en tests/test_capture_defense_v03.gd y la comparación prolongada en tests/test_capture_defense_long_v03.gd. Sus resultados no deben inferirse del éxito de v0.4: se registrarán de manera independiente cuando GitHub Actions los confirme.


## Resultado verificado de la variante conservadora v0.5

**Godot 4.3 — SUCCESS:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43761141745

**8 casos mecánicos PASS:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43761061321

La comparación repite los **16 escenarios espejo, 32 partidas, hasta 48 medias fases** y las mismas reglas frente a la IA de apoyo v0.3. El flujo de CI terminó sin errores, pero **el análisis de balance no pasó todavía el criterio de mejora**.

| Indicador, total en 16 sesiones por brazo | IA de apoyo v0.3 | IA conservadora v0.5 |
|---|---:|---:|
| Conquistas completadas | 66 | 67 |
| Avances parciales | 187 | 197 |
| Interrupciones de captura | 94 | 100 |
| Muertes del ocupante detectadas al perder el registro | 69 | 70 |
| Abandonos de ocupante detectados al perder el registro | 20 | 23 |
| Compras | 1.024 | 1.031 |
| Movimientos específicos de escolta | 24 | 9 |
| Disparos específicos de protección | 0 | 0 |
| Rentas retenidas durante asedios | 14.250 | 15.250 |
| Partidas con victoria final | 4 | 4 |
| Victorias del bando que inició | 0 | 0 |

Las interrupciones incluyen reemplazos de ocupantes y otras causas, y la clasificación específica de muertes/abandonos se cuenta solo cuando un registro previo desaparece, por lo que no agota todas las causas. Este conjunto tiene muy pocas partidas decididas para inferir ventaja sistemática del segundo jugador o éxito competitivo global.

**Interpretación:** la variante v0.5 reduce intervenciones innecesarias y recupera la cantidad de capturas, pero no mejora supervivencia, pérdidas de progreso ni el número de victorias. Los **0 disparos especiales** sugieren que los ataques letales priorizados por BasicAI ya cubren la mayoría de las situaciones que activa la nueva regla de emergencia. **No integrar ni v0.4 ni v0.5 al juego oficial**.

### Próxima hipótesis de trabajo

En vez de priorizar aún más los ataques y las órdenes de escolta, revisar **selección de objetivos y retirada previa**: no comenzar una captura si la unidad no puede permanecer viva dos turnos propios, estimar riesgo de emboscada con visión parcial sin hacer trampa, y preservar ocupantes valiosos cuando haya rutas legales y seguras. Evaluarlo contra el mismo baseline antes de modificar balance de unidades, costos o habilidades.
