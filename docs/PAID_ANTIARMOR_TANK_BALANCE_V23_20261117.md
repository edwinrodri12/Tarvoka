# TARVOKA — Auditoría de antiblindaje pagado v2.3

**17 de noviembre de 2026 · DRAFT [PR #507](https://github.com/edwinrodri12/Tarvoka/pull/507)**

**Evidencia de 24 partidas en Godot 4.3, CI PASS:** https://github.com/edwinrodri12/Tarvoka/actions/runs/44044428214. Cuatro jobs (tres mapas y prueba base de daño/costes) aprobados. Smoke adicional de fuego concentrado aprobado en https://github.com/edwinrodri12/Tarvoka/actions/runs/44045072057.

## Pregunta

¿Puede el **Rompedor** con tecnología antiblindaje **+2** contrarrestar el tanque si ambos deben pagar los costes de acceso pertinentes?

### Metodología, sin modificar gameplay comercial

- Comparación de **12 situaciones espejo** (4 configuraciones por mapa × 3 terrenos), con **2 modos** cada una: presión convencional versus presión que investiga. Total **24 partidas**, no 24 mapas aleatorios independientes. La doctrina opuesta es blindados y **siempre paga 650 créditos para desbloquear tanques en nivel II**. Ambas partidas del par mantienen mapa, posicionamiento, rival e iniciativa.
- **Tecnología NO se regala por 450 créditos**: el laboratorio ya definía investigación `antiarmor_v1` en **planta blindada nivel III**. Para el Ejército Rompedor: nivel II **650**, nivel III **1.050**, investigación **450** = **2.150 créditos**; cada una consume una oportunidad de producir en la instalación (tres fases propias, cuando la instalación ya es propia). En el mapa 10×8 la planta blindada empieza neutral; antes debe capturarse.
- Daño de la bonificación solo al iniciar ataque con un `piercer` a vehículos terrestres de `RoleSpecializationV08.ANTI_ARMOR_ROLES`. No aplica a infantería, aire, barcos ni al contraataque enemigo. El golpe usa `Session.attack` original con bono temporal, restaura ataque base después, consume munición real y procesa una respuesta defensiva real si el tanque sobrevive con munición y no ha reaccionado en ese turno.
- La IA de modo investigador prioriza gastar en niveles II/III, investigación; durante las primeras fases sacrifica compras de soldados. Es **una decisión específica de la estrategia experimental**, no una orden del jugador ni optimización demostrada.
- Condición actual de victoria = eliminar todos los soldados enemigos. Las partidas no decididas al cortar 42 medias fases en 10×8 o 52 en 24×18 están **censuradas** y no equivalen a empate. No se simulan XP, comandantes, campamentos, niebla o combate de ocho bandos.
- Contabilidad estricta: **2.500 + ingresos de ciudades – compras – mejoras – investigación = créditos finales** por bando; inversión pagada por los dos lados. El modo control reproduce la partida v2.2 y no crea bonos.

## Exactitud del golpe frente a tanque (un Rompedor con munición)

| Cobertura del tanque | Ataque normal | Tras +2 | Contraataque al Rompedor | HP restante del tanque tras +2 |
|---|---:|---:|---:|---:|
| Pradera | 2 | 4 | 4 | 10 |
| Bosque | 1 | 3 | 4 | 11 |
| Montaña | 1 | 1 | 5 | 13 |

El Rompedor inicia con 8 HP, usa 1 de sus 4 municiones y tras una respuesta del tanque queda con 4 HP en pradera/bosque o 3 HP en montaña. El tanque inicia con 14 HP, 5 municiones y una reacción exitosa le consume una (quedan 4). La defensa de montaña **cancela el beneficio de +2** bajo la fórmula actual.

**Fuego concentrado validado en Godot 4.3:** [smoke ampliado (CI PASS)](https://github.com/edwinrodri12/Tarvoka/actions/runs/44045072057). Cuatro Rompedores rodean un tanque y atacan legalmente en el MISMO turno. El tanque contraataca **una sola vez** y consume exactamente una munición; cada soldado que dispara consume exactamente una suya. El motor aplica también flanqueo, por lo que no debe proyectarse esta secuencia multiplicando el daño del duelo aislado:

| Cobertura | HP tanque tras 4 Rompedores sin tech | HP tanque con tech +2 | Disparos con tech | Contraataques del tanque |
|---|---:|---:|---:|---:|
| Pradera | **2** | **0** | **3** | 1 |
| Bosque | **6** | **0** | **4** | 1 |
| Montaña | **10** | **6** | **4** | 1 |

Por tanto, **el bonus funciona tácticamente con concentración de fuego y flanqueo**: tres golpes potenciados bastan en pradera y cuatro en bosque; sin tecnología el tanque sobrevive cuatro golpes. En montaña la protección sigue siendo alta, aunque la coordinación mejora el total (HP restante 10 → 6). La suma base de reclutamiento de cuatro Rompedores es **1.200 créditos**, MÁS las mejoras e investigación y varias oportunidades de producción; este ensayo táctico no supone que comprar las cuatro unidades fuera instantáneo ni gratuito.

## Resultados integrados de estrategia: 24 partidas

La tabla muestra al **ejército Rompedor (presión)**, 4 partidas por fila y modo. `V/D/C`: victorias, derrotas y partidas censuradas.

| Mapa | Presión normal V/D/C | Presión con investigación V/D/C | Investigación completada | Disparos realmente potenciados | Aumento de daño en esos golpes | Daño total presión normal → investigada | Bajas presión normal → investigada |
|---|---|---|---:|---:|---:|---:|---:|
| 10×8 abierto | 0/4/0 | 0/4/0 | 3/4 | **0** | 0 | 209 → 147 | 25 → 17 |
| 24×18 abierto | 1/0/3 | 0/0/4 | 4/4 | **14** | 25 | 727 → 655 | 79 → 72 |
| 24×18 bosque | 0/0/4 | 0/3/1 | 4/4 | **9** | 14 | 619 → 265 | 72 → 24 |
| **Total** | **1/4/7** | **0/7/5** | **11/12** | **23** | **39** | **1.555 → 1.067** | **176 → 113** |

- A pesar de que el bono funciona, la estrategia que investiga tuvo **63 bajas menos** (−35,8%) y compró **150 soldados frente a 213** (−29,6%). El daño total descendió **488 puntos** (−31,4%). La ventaja de daño de los golpes potenciados (**+39**) no compensó la menor presencia militar en esta IA.
- En los 12 escenarios emparejados hubo **4 cambios en el resultado de la partida** entre control e investigación: ninguno representó una victoria nueva de presión. El pequeño 10×8 fue 0/4 para presión en ambas modalidades.
- La investigación consumió **4.950 créditos directos** (11 × 450) más **18.700 créditos de mejoras** (11 × 1.700) = **23.650 créditos** destinados a conseguir +2, dinero que no pudo reclutar tropas y que también demoró tres oportunidades de producción.
- Los **23 impactos mejorados** consumieron 23 municiones de Rompedor; estos 23 golpes generaron 39 puntos de daño adicional sobre la misma situación sin tecnología. También causaron **28 puntos de daño de contraataque recibido** en total (17 mapa abierto, 11 bosque).
- En el mapa 10×8 tres ejércitos sí investigaron, pero **ninguno logró usar el bonus antes de perder la partida**. Hay que distinguir inversión culminada de utilización táctica efectiva.

## Interpretación práctica y próxima prueba

**NO es una prueba de que +2 antiblindaje sea insuficiente matemáticamente.** Es una prueba más concreta: **el modo de acceso actual (planta III + 450) y la priorización temprana de investigación pueden ser económicamente inviables frente al desarrollo de tanques en II**. Es demasiado caro/temprano para mantener suficiente número de Rompedores. El terreno (sobre todo montaña) puede neutralizar incluso los golpes mejorados.

Recomendación para siguiente A/B aislado:

1. Comparar **planta II + investigación 450** (total 650 + 450, dos fases de producción) frente a **planta III + investigación 450** (2.150, tres fases), manteniendo exactamente el bono +2 y misma IA. Ello prueba **acceso y oportunidad**, NO cambia las estadísticas oficiales; exigir aprobación antes de convertirlo en regla comercial.
2. Probar IA alternativa: reclutar Rompedores primero, investigar después de establecer una línea defensiva, y medir la cantidad de munición real y tropas supervivientes.
3. Evaluar concentración de fuego de múltiples Rompedores por tanque con respuesta única del tanque por turno y coberturas distintas; distinguir precio del pelotón y veteranos si más adelante se añaden.
4. Mantener los cuatro campamentos acordados **solo como especificación**: [INFANTRY_SPECIALISTS_CAMPS_SPEC_20261117.md](INFANTRY_SPECIALISTS_CAMPS_SPEC_20261117.md). No están integrados en estas partidas.

## Rutas para auditoría

- `scripts/experiments/PaidAntiarmorBalanceV23.gd` — costos, niveles de planta por dueño, investigación y contabilidad
- `scripts/experiments/StrategicMatchBalanceV21.gd` — opción de selección IA y sesión real antiarmor sin alterar modo sin bono
- `scripts/experiments/TankUnlockEconomyV22.gd` — transferencia opcional de nuevas reglas y nivel II del rival
- `tests/test_paid_antiarmor_smoke_v23.gd` — daños pradera/bosque/montaña, recarga, contraataques, costes y paridad previa; prueba adicional de fuego concentrado
- `tests/test_paid_antiarmor_pairs_v23.gd` — parejas de partidas comparables, dos iniciativas, dos lados, economía, compras, victorias reales/censuradas
- `.github/workflows/paid-antiarmor-balance-v23.yml` — cuatro jobs: prueba smoke + tres mapas paralelos

**Estado: no mezclado, sin modificación a APK, núcleo, guardados ni efectos de campamentos.**
