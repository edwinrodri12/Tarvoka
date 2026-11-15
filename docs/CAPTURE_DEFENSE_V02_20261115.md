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
