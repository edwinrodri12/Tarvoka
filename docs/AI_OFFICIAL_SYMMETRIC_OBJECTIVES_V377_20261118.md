# TARVOKA v3.7.7 — Candidato oficial a IA simétrica (revisión, NO desplegado)

**18 de noviembre de 2026.** Rama de revisión basada exclusivamente en el PR experimental v3.7.6 (#579). **No fusionada**, no presente en `main` ni en el APK público. Esta rama conserva las pruebas anteriores sin modificar `BattleSession`, `BasicAI`, economía, captura, reglas, niveles ni el serializador de guardados.

## Razón del cambio

La [v3.7.5](https://github.com/edwinrodri12/Tarvoka/pull/578) ejecutó 384 partidas reales de Godot, emparejadas por reflexión de mapa e inversión de facciones. **192/192 pares** divergieron en objetivos persistentes y **52/192** terminaron con ganadores distintos.

La [v3.7.6](https://github.com/edwinrodri12/Tarvoka/actions/runs/44243137453) aisló la causa en el planificador de objetivos: **18/18 trabajos de CI exitosos; 144/144 comparaciones directas y 192/192 parejas de batallas completas en simetría, 0 ganadores diferentes**. La variante de prueba se mantuvo fuera de la lógica oficial.

## Cambio mínimo del candidato

Sólo `scripts/core/MultiTurnObjectivesV33.gd`:
1. Ordenar unidades elegibles por fila, columna X relativa a facción, rol y finalmente ID, sin depender del orden de nombres A/B... o X/Y....
2. Al empatar puntuación de ciudades/objetivos, resolver por X relativa a la facción y luego Y.

Los objetivos guardados conservan exactamente las mismas claves (`unit_id`, `task`, `kind`, `x`, `y`), las mismas reglas de validez y sus coordenadas de mundo. No cambia el esquema v1 del guardado. Las órdenes persistentes válidas se siguen respetando antes de recalcular. No se añade dinero ni acciones a ningún jugador.

## Bloqueos automáticos propuestos antes de cualquier fusión

- `test_symmetric_objective_contract_v377.gd`: 48 escenarios, 144 decisiones reales del **BasicAI oficial**, objetivos y acciones iguales tras reflejar, equivalencia con la variante de investigación, guardados v1 actuales y guardados antiguos sin `ai_objectives`.
- `test_ai_mirrored_full_battles_v377.gd`: 192 parejas / 384 partidas reales con **BasicAI oficial**, mapas 0–3, dificultad 10/12, niebla con/sin, dos iniciadores, dos políticas tácticas y tres distribuciones de relés.
- `aggregate_ai_full_mirror_v377.py`: bloquear CI si no hay **192/192 secuencias y ganadores completamente simétricos**. Se sigue validando combate, unidades, captura, compra, relés y condiciones económicas.
- Matriz y análisis de CI en `.github/workflows/ai-official-objectives-v377.yml`.

**Importante: simetría por facción NO es equidad por orden de turno.** En v3.7.6 el segundo jugador ganó 128/192 escenarios originales frente a 64/192 del primero. Es un resultado condicionado por este conjunto fijo de mapas y políticas, no una estimación poblacional del juego. Se requiere ensayo adicional con mapas grandes, semillas distintas, partidas humano/IA, las ocho facciones y guardados reales antes de aprobar el despliegue. Evitar compensaciones económicas y acciones gratis sin datos concluyentes.

## Estado de integración

Este PR se basa en #579 y sus dependencias experimentales; **NO se puede aplicar directamente a `main` mientras no estén presentes los componentes de IA y economía previos**. No cambia la APK del usuario y no autoriza su fusión automática.
