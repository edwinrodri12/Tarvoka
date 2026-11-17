# TARVOKA — Ensayo A/B de IA v3.5 contra v3.6 (partidas reales)

**17 noviembre 2026. Solo rama experimental.** No modificar `main`, la APK, estadísticas/evoluciones ni economía. Esta prueba nace de la prioridad posterior al PR #552.

## Hipótesis, control y sesgos

Comparar v3.6 con su **antecesora v3.5** manteniendo exactamente el mismo `BasicAI.step`, nivel (10 y 12), doctrina `balanced`, terreno, niebla, inventarios, créditos, unidades, daño y reglas. Un interruptor **exclusivamente interno del ensayo**, `_ab_disable_future_threat_v36`, desactiva el planificador `NextTurnThreatV36.propose` para el bando de control. Todas las fases anteriores (3.1–3.5) y el resto de v3.6 siguen iguales.

Para cada combinación: dos mapas terrestres existentes (0 y 2), niebla activada/desactivada, niveles 10/12, el primer bando 0/1 y la asignación de v3.6 al bando 0/1. Total: **32 sesiones emparejadas** repartidas en ocho trabajos de CI; **4 sesiones por trabajo**. No se altera la iniciativa ni se regalan órdenes.

## Métricas recogidas por partida y versión

- `winner`, `termination`, `phases`, `actions`: resultados, victoria/derrota o partida censurada por 80 fases/empate por inactividad.
- `losses[side]`: destrucciones reales de unidades (incluye reclutas), detectadas al cruzar HP > 0 a HP <= 0 entre dos estados autorizados.
- `initial_survivors[side]`: cuántas de las cinco unidades iniciales originales siguen con vida; aproximación a **unidades conservadas**, no causalidad demostrada.
- `remaining_hp[side]`: HP finales sumados de todas las unidades vivas, incluidos reclutas. Interpretar junto con compras.
- `captures[side]`: cambios reales de propietario de **ciudades**, contados cuando el estado de economía cambia.
- `retreats[side]`: movimientos identificados por motivo de retirada.
- `anticipatory`: decisiones exclusivas v3.6 que ejecutan `anticipatory_defense`.
- `questionable_anticipatory`: alertas si un movimiento anticipatorio se autorizó sin amenaza letal estimada (`threat_before < HP`) o si el pronóstico no mejoró (`threat_after >= threat_before`).
- `abandoned_nonlethal_capture`: abandono de una ciudad disputada pese a riesgo pronosticado no letal. **Indicador estricto**, no equivale a todas las retiradas potencialmente innecesarias.
- `attacks`, `buys`, `decision_us`, `decision_calls`: presión ofensiva, producción y coste acumulado de cálculo, medido en el **runner Linux**, no en Android.

Se registran resultados por partida (`AB_MATCH`, JSON) y subtotales por suite (`AB_SUMMARY`, JSON). El CI exige acciones legales, estado válido, partida reproducible, no mutación del estado de entrada, guardado codificable, niebla y presupuesto autorizado. Las retiradas que no terminan en un ataque **no se clasifican automáticamente como innecesarias**, porque precisamente pueden haber evitado que el rival dispare.

**Precaución:** 32 partidas son un ensayo exploratorio, no una garantía de mejora. Si no se completan los objetivos antes del límite de 80 fases, el resultado queda marcado `censored_at_80_phases` y se excluye del conteo de victorias, no se inventa un ganador. Comparar decisiones y eficiencia por igual nivel/escenario; nunca corregir balance arbitrariamente con una muestra pequeña.

## Cómo ejecutar / validar

`tests/test_ai_v35_v36_full_matches.gd` bajo Godot 4.3 headless. El workflow `.github/workflows/ai-v35-v36-duels.yml` ejecuta matriz con variables `TARVOKA_AB_LEVEL`, `TARVOKA_AB_MAP`, `TARVOKA_AB_FOG`; publica los ocho logs como artifacts. No produce APK ni toca guardados del usuario.

**Antes de autorizar integración:** (1) revisar los 32 logs y sumar únicamente las partidas terminadas, (2) identificar diferencias significativas o estancamiento por exceso de defensa, (3) ampliar a dominios modernos, clima y mapas de 24×18/40×30, (4) medir latencia y batería en Android físico, (5) probar con humanos. La referencia actual es el PR #552, que debe seguir como borrador.
