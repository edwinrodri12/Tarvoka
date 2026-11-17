# TARVOKA — Auditoría de iniciativa, desempates y dominancia v2.5

**17 noviembre 2026 · PR borrador [#511](https://github.com/edwinrodri12/Tarvoka/pull/511) · [CI 4/4 PASS](https://github.com/edwinrodri12/Tarvoka/actions/runs/44128185983).**
**TODA la actividad es experimental:** no se ha cambiado `main`, la APK, la UI, el núcleo económico, los poderes de comandantes ni el formato de guardados.

## Hipótesis

No dar por hecha la "compensación" de tres órdenes al primer jugador. Investigar **por separado** si el problema es el turno de iniciativa, el desempate geográfico de la IA o la ausencia de un counter accesible. El segundo jugador ya cobra sus ciudades al entrar en su primera fase; el primero recibe ingresos solo desde su segunda fase. Eso está confirmado por el laboratorio v2.4 en tres tamaños y ambos colores.

### Ensayo reproducible

- Simulador V21 + instalaciones territoriales V19, órdenes reales, caminos, costes, contabilidad, daños y munición: **12 configuraciones estratégicas (tres pares de políticas × 2 órdenes de iniciativa × 2 permutaciones de lado) en cada mapa, con 4 variantes cada una = 48 partidas por mapa; 3 mapas = 144 partidas**.
- Modos A/B: `current` (sin cambios), `cap3` (activa el límite de tres órdenes en apertura que YA existe como clase opcional `OpeningBalance`), `mirror_ties` (resuelve empates de puntuación por coordenadas normalizadas hacia el propio bando, en vez de confiar en orden de búsqueda), `both` (ambos).
- Se mantuvo identidad de mapas, tropas iniciales, secuencia de ingresos, IA estratégica, motor de ataque, ventas de edificios y límites temporales: **42 medias fases** (10×8) y **52 medias fases** (24×18).
- Prueba de humo [PASS](https://github.com/edwinrodri12/Tarvoka/actions/runs/44128185983): exactamente tres órdenes si está activa la regla, recompensa de segundo turno correcta, configuración heredada reproducida idénticamente y claves de desempate iguales para celdas reflejadas.
- **Censurada** significa sin ganador al corte temporal; **NO** igualada, ni victoria parcial. Cuatro variantes no son muestras estadísticamente independientes: son comparaciones pareadas del mismo determinismo.

## Resultados exactos

**V/D/C** para doctrina blindada = victorias/derrotas/censuradas de ocho participaciones en cada mapa. **Inicio** = victorias de quien juega primero entre partidas decididas. **Reflejos** = resultados que contradicen el reflejo de políticas y colores entre 6 pares.

| Mapa | Modo | Decididas / censuradas (12 partidas) | Inicio | Color 0 / color 1 | Reflejos diferentes (de 6) | Blindados V/D/C |
|---|---|---:|---:|---:|---:|---|
| 10×8 abierto | Actual | 12 / 0 | **6/12** | 8/4 | **2** | 7/1/0 |
| 10×8 abierto | Cap 3 órdenes | 11 / 1 | **7/11** | 6/5 | **2** | 7/1/0 |
| 10×8 abierto | Desempates normalizados | 10 / 2 | **6/10** | 5/5 | **0** | **8/0/0** |
| 10×8 abierto | Ambos | 12 / 0 | **10/12** | 6/6 | **0** | 6/2/0 |
| 24×18 abierto | Actual | 3 / 9 | **1/3** | 2/1 | **3** | 1/1/6 |
| 24×18 abierto | Cap 3 órdenes | 3 / 9 | **2/3** | 3/0 | **3** | 1/0/7 |
| 24×18 abierto | Desempates normalizados | **0 / 12** | No evaluable | 0/0 | **0** | 0/0/8 |
| 24×18 abierto | Ambos | 4 / 8 | **2/4** | 2/2 | **0** | 2/0/6 |
| 24×18 bosque | Actual | 3 / 9 | **1/3** | 0/3 | **3** | 1/0/7 |
| 24×18 bosque | Cap 3 órdenes | 1 / 11 | **1/1** | 0/1 | **1** | 0/1/7 |
| 24×18 bosque | Desempates normalizados | **0 / 12** | No evaluable | 0/0 | **0** | 0/0/8 |
| 24×18 bosque | Ambos | **0 / 12** | No evaluable | 0/0 | **0** | 0/0/8 |

Resumen agregado de 36 partidas por modo:
- **Actual:** 18 decididas/18 censuradas; inicio gana **8/18**; discrepancias de reflejo **8/18**.
- **Cap3:** 15 decididas/21 censuradas; inicio gana **10/15**; discrepancias **6/18**.
- **Normalización sola:** 10 decididas/26 censuradas; inicio gana **6/10**; discrepancias **0/18**. ¡Los **24 combates medianos están censurados**! Eliminar diferencias geométricas no equivale a una experiencia jugable mejor.
- **Ambas:** 16 decididas/20 censuradas; inicio gana **12/16**; discrepancias **0/18**. En el mapa pequeño, el iniciador gana **10/12**.

## Diagnóstico

1. **No aplicar cap3 por defecto.** El resultado más claro que sí mide causalidad es pequeño: combinado con desempates simétricos, la victoria del primer jugador sube de 6/12 a 10/12. La regla cap3 podría reducir una ofensiva temeraria del iniciador y facilitarle defenderse; no asumir que limitar movimientos equivale a debilitarlo.
2. **Resolver empates de manera simétrica en la IA eventualmente**, porque quitar orden BFS asimétrico elimina los resultados no especulares (0/18 reflejos discrepantes). Pero la variante actual **no está lista para desplegarse**: en 24×18 estanca todas las partidas dentro de 52 medias fases, puede necesitar mejores objetivos y condiciones de victoria. Se probó un orden de desempate determinista, no un cambio en la geometría del mapa ni un aumento artificial de estadísticas.
3. **El meta pequeño favorece blindados** incluso tras normalizar decisiones: **8/8** victorias contra expansión o presión. Muestra limitada y determinista; es ALERTA de estrategia dominante, no prueba de victoria inevitable contra humanos.
4. **Incompatibilidad concreta con el diseño de infantería acordado:** `UrbanEconomy.producer_for("piercer",true)` devuelve `"armor_plant"` en `main`, mientras que el **Rompedor debe entrenarse en el Cuartel de Infantería nivel I** junto a Guardia. En 10×8 las plantas blindadas son neutrales, así que el ejército no puede producir su counter de infantería desde su cuartel inicial. Esto puede ser una causa importante de la dominancia blindada. Hay que **probar el Rompedor nivel I desde el cuartel** con el mismo precio 300 y su ataque actual ANTES de nerfear HP/ataque de tanque o regalar +2 de investigación.
5. **Apertura económica no es el problema primario confirmado:** ambos arrancan con 2.500; la segunda posición cobra una vez al comenzar su primera acción, con la renta de ciudades que posee. Mantener esos ingresos existentes, evitar un doble bono.
6. **Partidas medianas no se pueden evaluar con solo eliminación total y límite de 52 medias fases**: 75% censuradas en control; normalización 100%. Próximo experimento: objetivos HQ/territorio y/o prolongar partida con límite de acción/trampa validado. No asignar victoria inventada por tener más ciudades al corte hasta diseñar una condición objetiva reproducible.

## Comparación externa útil

- La [guía competitiva de creación de mapas de Advance Wars By Web](https://thegamerasd.github.io/AWBW-Mapmaking-Guide/beginner/introduction_to_fta.html) reconoce que **las contramedidas de iniciativa varían según el número de bases y la distribución del mapa**, no una restricción universal de acciones. El modo competitivo AWBW clasifica además los comandantes por fuerza y aplica restricciones de selección por mapa.
- TARVOKA debería diferenciar reglas de **balance del motor** (idénticas para todos) de **compensaciones por mapa** (solo cuando una prueba reproducible revele ventaja).

## Recomendación final de prioridades

**Primero: counter accesible y legal.** Probar trasladar a `piercer`/Rompedor desde `armor_plant` a `factory` (Cuartel nivel I) en una rama nueva, sin cambiar su coste/HP/ataque. Las políticas de IA deben producirlo desde la fábrica y el motor debe validar compra real; evitar unidades añadidas gratis o por inyección ilegal. A/B emparejado contra nivel II de tanques, así medimos si 8/8 se reduce sin destruir otras doctrinas.

**Segundo: finalizar partidas y corregir estancamientos.** Prototipo de victoria por HQ/captura territorial y mejor priorización de objetivo sin alterar primero los costes. Mantener censurado todo caso que no alcanzó regla explícita de victoria.

**Tercero: desempates imparciales de la IA.** Con mejor resolución de objetivos, repetir 144 partidos; exigir reflejos iguales y menos partidas censuradas, no solamente una tabla de resultados visualmente simétricos.

**Cuarto: investigación antiblindaje.** Después de corregir el acceso al Rompedor, comparar acceso al bono +2 por 450 al nivel II frente a nivel III (la inversión experimental actual era 650+1050+450=2150). Decidir si aún se necesita la tecnología y con qué coste total de oportunidad.

**Quinto: equilibrar las ocho facciones y poderes** con matriz de enfrentamiento 8×8, posiciones intercambiadas, mapas distintos, reglas de terreno y clima, diversidad de decisiones y telemetría; no afirmar que el simulador actual de dos bandos representa todos los comandantes. Mantener alertas de combinación abusiva, curación infinita, acumulación de pasivas y cadenas de ingresos o acciones.

**No cambiar main / APK / guardados en esta fase:** los 144 partidos son pruebas de concepto aisladas. No se puede garantizar matemáticamente que ningún jugador encuentre jamás una estrategia vencedora, pero sí fijar un umbral de revisión, diseñar contramedidas y ampliar los escenarios hasta que ninguna apertura evidente sea dominante.

## Evidencias

- [Ejecución exitosa 4/4 jobs — 144 partidos](https://github.com/edwinrodri12/Tarvoka/actions/runs/44128185983)
- `tests/test_opening_cap_mirror_smoke_v25.gd`: control, tres tamaños, dos iniciadores, ingresos y límite de acciones, desempates reflejados.
- `tests/test_opening_policy_ab_v25.gd`: 12 configuraciones por escenario × 4 variantes × 3 mapas.
- `scripts/experiments/StrategicMatchBalanceV21.gd`: `opening_cap` y `canonical_ties` opcionales, **desactivados por defecto**.
- [PR #511](https://github.com/edwinrodri12/Tarvoka/pull/511) permanece como **borrador**.
