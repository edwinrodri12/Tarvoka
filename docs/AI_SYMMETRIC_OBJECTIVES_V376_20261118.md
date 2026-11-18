# TARVOKA v3.7.6 — Diagnóstico aislado de objetivos y orientación

**18 de noviembre de 2026. PR experimental independiente, no fusionado.** No modifica `main`, la APK, las reglas oficiales de captura/combate ni los archivos de producción. El experimento usa copias **solo para pruebas** de `MultiTurnObjectivesV33.gd` y `BasicAI.gd`.

## Evidencia de partida

La [CI v3.7.5 #44238796124](https://github.com/edwinrodri12/Tarvoka/actions/runs/44238796124) concluyó con **18 de 18 trabajos exitosos**. Se ejecutaron 192 parejas de batallas independientes (**384 partidas reales de Godot**), cuatro mapas, niebla sí/no, niveles 10/12, ambos iniciadores, políticas v35/v363 y tres disposiciones de relés.

- Solo **140/192 parejas** acabaron con el ganador equivalente después de reflejar el tablero y cambiar el color.
- **52/192 parejas** cambiaron de ganador: Bosque 12, Puentes 16 y Costa 24; Campo abierto 0.
- La primera divergencia de **192/192** parejas aparece en el estado persistente `ai_objectives` **después de la primera acción de la primera fase**; la acción misma aún coincidía.
- Esto identifica un **campo problemático**, pero no demuestra causalidad de todas las diferencias de ganador.

## Dos fuentes potenciales, verificadas en el código

`scripts/core/MultiTurnObjectivesV33.gd` contiene:

1. `_alive_allies` ordena por **ID textual**. Aunque los ejércitos son equivalentes, las unidades iniciales reciben IDs distintos A/B/C/D/E y X/Y/Z/W/V; invertir el mapa e intercambiar facciones cambia el orden de tareas aunque no cambien las tropas.
2. Al empatar dos destinos de captura, `refresh` favorece la **menor coordenada X absoluta**. Esa coordenada no es invariante bajo reflejo horizontal.

## Implementación de investigación, sin alterar producción

- `tests/ExperimentalObjectivesV376.gd` es una copia del planificador original. Sustituye el orden por perspectiva geométrica: primero Y, después X relativo a la facción, rol e ID únicamente como último desempate. Sustituye también la comparación de dos objetivos con igual puntuación por X relativo a la facción, seguido de Y.
- `tests/ExperimentalBasicAIV376.gd` es una copia intacta de la IA, excepto que carga el planificador de investigación. Combate, movimiento, economías, fog, suministro y cada acción siguen entrando al `BattleSession` verdadero.
- `tests/test_symmetric_objective_contract_v376.gd`: 48 estados iniciales, tres acciones reales cada uno y comparación con el planificador anterior: **144 comparaciones** de planes persistentes, acción y legalidad, incluyendo parejas reflejadas. Una diferencia se registra, no se silencia.
- `tests/test_ai_mirrored_full_battles_v376.gd`: vuelve a ejecutar **192 parejas / 384 batallas independientes**, observando toda la secuencia de movimientos, compras, combate y estado persistente, hasta victoria o límite.
- `tests/aggregate_ai_full_mirror_v376.py`: valida 192 registros únicos y controles de sesión, reproduce el método de análisis de divergencias de la v3.7.5 y coteja con la evidencia histórica **52 pares con ganador diferente y 0 estados equivalentes**, pero **no exige** conservar esos resultados bajo una IA intencionalmente modificada.

Las condiciones económicas (ingreso inicial simétrico opt-in), apertura de tres órdenes, puntos de relé por ronda y cuatro mapas no cambian. La prueba no genera ganancias o movimientos artificiales.

## Decisión de continuación

Si desaparecen las divergencias de objetivos y disminuyen las diferencias de ganador, preparar una implementación revisable en producción **solo en otra rama**, con pruebas de partida humana, mapas grandes, bandos y guardados heredados, sin desplegar directamente. Si no, usar la primera divergencia que persista para aislar la siguiente dependencia. No hacer cambios de balance por preferencias estéticas o por un único resultado.

**No fusionar este PR ni construir APK de esta variante de IA sin completar y revisar los controles.**
