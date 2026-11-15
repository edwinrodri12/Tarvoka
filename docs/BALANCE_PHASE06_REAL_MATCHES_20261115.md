# TARVOKA — Fase 06: desempeño real de todas las 32 unidades en partidas

**Fecha:** 15 noviembre 2026. **Decisión:** ¿cuántas clases de infantería y de apoyo justifican su costo y qué balance debe revisarse antes de completar los 32 roles del catálogo?

**Motor utilizado:** Godot 4.3, `main`, `BattleSession` y `BasicAI` reales, escenarios 10×8 de TARVOKA. No estamos reproduciendo un juego inventado ni evaluando solo DPS abstracto. **Sin pruebas humanas todavía; las partidas son simuladas entre dos IA deterministas.**

## Metodología ejecutable

`tests/test_balance_phase06_real_match_value.gd` mide tres fuentes de evidencia, separadas para no confundir oportunidades con eficacia:

1. **48 partidas naturales** de dos IA: cuatro mapas oficiales × dos colores que empiezan × niebla sí/no × despejado/lluvia/nieve. Cada una dura hasta **32 medias fases**, salvo victoria previa. Se registran compras espontáneas por rol, capturas efectivas, ataques y daño, destrucciones, movimientos, suministros, resultado y material militar. No se atribuyen los errores de compra a la fuerza de la unidad.
2. **156 comparaciones A/B emparejadas** de dos partidas cada una, total **312 partidas**:
   - **32 roles × 2 bandos espejo × 2 estados de niebla = 128 comparaciones** en la costa. Cada variante se inicia con una orden auténtica `BattleSession.purchase` para un rol y la control guarda esos créditos. Se verifica el productor correcto, costo legal, propiedad, unidad nueva y guardado; después **20 medias fases** de IA sin cambiar su código.
   - **7 roles de soldados × 2 bandos espejo × 2 terrenos × 1 niebla = 28 comparaciones** adicionales: bosque nevado o puentes lluviosos, con **28 medias fases**. Se incluyen todas las siete clases y sus roles de apoyo, no solo Guardia/Asaltante/Ingeniero.
   - La diferencia **(material del comprador menos material del enemigo)_comprando − (material del comprador menos material del enemigo)_ahorrando** mide el efecto marginal de invertir en la unidad y la respuesta de IA rival, **no la tasa estadística de victorias ni una clasificación definitiva de poder**.
   - Para cada unidad comprada se rastrea por ID: movimientos, disparos, daño infligido, daño recibido, muertes, capturas realizadas, supervivencia final y la economía propia/rival. Se reconoce que realizar la compra al comienzo consume la instalación una vez y puede desplazar otras compras que la IA habría realizado. Esa sustitución también forma parte del costo estratégico de la elección.
3. **Matriz de 32×32** roles atacante/defensor, con disparos válidos según tierra, aire, mar, alcance mínimo/máximo y **tres terrenos defensivos**. Para cada par posible se estima valor neto del intercambio inmediato `costo_objetivo×(HP_infligidos/HP_máx)` menos `costo_atacante×(HP_recibidos/HP_máx)`, o el **costo completo** cuando el atacante es un misil de un solo uso. Es **una muestra artificial uniforme de objetivos**, separada expresamente de las partidas reales y de la utilidad de visión/suministros/captura.

**Material al cierre** = créditos no gastados + suma (precio del rol × fracción de HP de cada unidad superviviente). Esta proxy incluye el capital invertido en unidades, pero **NO** el valor del alcance, la ubicación, la niebla, la defensa de ciudades, el rendimiento de munición, ni el gasto de tiempos de producción. Se reportan por separado capturas e ingresos; no sumar otra vez reservas de munición/fuel sobre el precio de una unidad.

### Restricciones conocidas

- La rama `main` no contiene la reparación real de Ingeniero, que existe como [PR #320](https://github.com/edwinrodri12/Tarvoka/pull/320) más movimiento IA [#323](https://github.com/edwinrodri12/Tarvoka/pull/323), ambas draft. **No interpretamos "Ingeniero no cura" como razón permanente para eliminarlo.**
- Los cambios del Rompedor contra tanque se desarrollan en [#328](https://github.com/edwinrodri12/Tarvoka/pull/328) y su adquisición específica en [#333](https://github.com/edwinrodri12/Tarvoka/pull/333). No están en main.
- Transportes APC e IFV están implementados en ramas apiladas [#335](https://github.com/edwinrodri12/Tarvoka/pull/335) y [#339](https://github.com/edwinrodri12/Tarvoka/pull/339) pero todavía no fusionados. Su utilidad de llevar infantería y conquistar ciudades **no aparece en este baseline**.
- `main` sí tiene el camión logístico que repone munición/combustible, no salud, y drones FPV/merodeadores/USV consumibles al disparar. EW, submarino sigiloso, helicóptero transporte y buque desembarco tienen capacidades centrales pendientes.
- En `main`, captura Guardia, Rastreador, Asaltante e Ingeniero. La captura de Rompedor se corrige en [#156](https://github.com/edwinrodri12/Tarvoka/pull/156), pendiente. Baluarte y Lanzador no capturan. Esto debe revisarse como **regla de diseño de infantería**, no automáticamente atribuírsele una habilidad ficticia.
- **No es multijugador real de ocho participantes**; las partidas aquí se ejecutan a dos bandos de IA, como soporta `BattleSession`.
- No evaluar aún los 50 capítulos, poderes especiales de ocho facciones ni veterancia como habilidades funcionales. Las mejoras futuras de nivel 2/3 no están medidas.
- Todas las compras forzadas se hacen en el turno del mismo bando que comienza; los pares reflejan colores, niebla, mapas y clima. Sigue habiendo un **único estilo de IA**, sujeto a reservas de dinero, prioridades preprogramadas y tamaño pequeño de mapa. Los resultados con daño sin conseguir atacar no indican necesariamente que una unidad sea inútil.

## Criterios de interpretación

- Una clase se considera **subutilizada por la IA** si sus compras naturales son raras y no desempeña acciones, pero un buen resultado en A/B puede demostrar valor latente pese a su escasa compra.
- Una clase con **valor marginal negativo** no se considera automáticamente demasiado cara; puede requerir mapas de su especialidad, cargas/escoltas o habilidades todavía en PRs.
- Una clase de infantería aporta una decisión distinta solo si cambia resultados de al menos un **problema militar concreto** (captura, niebla, desgaste, asedio, defensa, antitanque, fuego de apoyo, ingeniería) en comparación con Guardia como referente de costo/HP.
- Cambios de precio/poder se presentarán como hipótesis con A/B reproducibles, no como nerfs/buffs automáticos.
- El objetivo es conservar unidades que abren caminos estratégicos genuinos, evitar compras improductivas y no reducir diversidad antes de integrar los roles ya desarrollados en otras ramas.

## Archivos y resultados

La CI `.github/workflows/balance-phase06-real-match.yml` ejecuta la batería completa. Los registros `REALMATCH_NATURAL`, `REALMATCH_ROLE`, `REALMATCH_EXPOSURE`, `REALMATCH_COUNTER` y `REALMATCH_SUMMARY` permiten reconstruir métricas por rol, terreno y evento. Los números observados y conclusiones se anexarán aquí **solo cuando la ejecución sea verde**; la existencia del test no demuestra por sí sola resultados.
