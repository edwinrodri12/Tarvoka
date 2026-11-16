# TARVOKA — Auditoría v1.7: daños, XP, tecnología y poderes de ocho facciones

**16 noviembre 2026. Investigación reproducible en PR #456. NO modifica reglas oficiales ni balance 0.1.**

## Qué se ha ejecutado

Godot 4.3 en GitHub Actions: **SUCCESS** — https://github.com/edwinrodri12/Tarvoka/actions/runs/43825006267 .

Se creó un laboratorio independiente: `scripts/experiments/FactionPowerBalanceV17.gd`, `tests/test_faction_power_stack_v17.gd` y `tests/test_antiarmor_terrain_breakpoints_v17.gd`. Se repitieron además los tests originales de 32 roles v0.9 y XP v1.4; todos aprobaron.

- **32 roles atacantes × 32 defensores × 3 terrenos × 4 rangos del atacante × 2 rangos del defensor = 24.576 situaciones teóricas.**
- **10.368** permiten ataque según `BattleActions.preview_exchange`, dominios, distancia y munición. Se revisó que el cálculo de daño base del laboratorio coincide con el del motor antes de aplicar cualquier escenario de poder.
- Para **ocho identidades de facción**, se calcularon hipótesis pasivas/poder activado usando redondeo abajo, al entero más próximo y arriba, y efectos de **reemplazo versus suma**. No se convirtió ningún poder en funcionalidad oficial.
- Se compararon defensa de Recluta y Élite, y los cuatro rangos ofensivos Recluta / Regular / Veterano / Élite; **3 consumibles** mantienen siempre nivel base, ya que no acumulan XP.
- `Tech.armor_bonus` es el candidato de +2 contra nueve categorías de vehículos terrestres, no un bonus universal.

**No son partidas simuladas completas, porcentaje de victorias, batallas de ocho facciones, ni evaluación subjetiva de diversión.** La IA, iniciativa, movimiento, contienda de ciudades, duración y compra del poder no intervienen en estos 24.576 casos. Los números porcentuales reproducen las candidatas de facción discutidas; los scripts core contienen arte/identidades visuales, NO reglas activas de ocho poderes. Toda diferencia porcentual es una **proyección de daño directo**, no la implementación de reacciones recalculadas con el poder.

## 1. Hallazgo crítico: redondeo de daño porcentual

Cada fila se calculó sobre **las 10.368 situaciones de ataque legal**; el denominador incluye todas las unidades/terrenos/niveles, no solo escenarios favorables.

| Regla hipotética | Redondeo abajo | Entero cercano | Redondeo arriba |
|---|---:|---:|---:|
| Pacto Escarlata +8 %: impactos cuyo daño final aumenta | 0 | 2.040 | 8.511 |
| Pacto Escarlata +8 %: nuevas eliminaciones de primer golpe | 0 | 573 | 758 |
| Poder ofensivo +15 % que **reemplaza** el +8 %: nuevas eliminaciones de primer golpe frente a base | 573 | 758 | 1.206 |
| +8 % y +15 % **sumados** (23 %): nuevas eliminaciones frente a base | 793 | 1.206 | 1.671 |
| Legión Ámbar −8 % daño recibido: sobreviven cuando base morían | 591 | 550 | 0 |
| Legión Ámbar −15 % poder que reemplaza pasiva: sobreviven cuando base morían | 951 | 591 | 550 |
| Dominio Turquesa poder naval +15 % (reemplaza +8 %): nuevas bajas en un golpe | 160 | 169 | 329 |
| Dominio Turquesa poder +15 % defensa naval: supervivencias adicionales frente a base | 75 | 51 | 51 |

**Interpretación:** Con daño entero de aproximadamente 1 a 10, el +8 % puede ser completamente inoperante al truncar, o equivaler a regalar al menos un punto de daño en casi todos los ataques no saturados si se redondea hacia arriba. El mismo "+8 %" es varias reglas distintas. El mismo problema ocurre con defensa e incluso la supervivencia directa.

En esta matriz el Pacto Escarlata con poder de 15 % genera **758** nuevas eliminaciones en un impacto con redondeo cercano, frente a **1.206** si redondeamos arriba. Si además se permite sumar +8 % pasivo y +15 % activo, con redondeo cercano subiría de 758 a **1.206**. No es recomendable decidir el precio, alcance o frecuencia del poder sin definir primero estas operaciones.

**Propuesta para probar, NO aprobada:** comparar (a) redondeo al entero más cercano por golpe, (b) acumulación determinista de fracciones de daño entre impactos, y (c) aplicar el porcentaje al ataque antes de restar blindaje. Cada regla puede producir umbrales y contrajuegos distintos; no se implementa ninguna en el motor por defecto.

## 2. Veteranía y tecnología: efecto real de los enteros

- En la muestra básica de **1.296** situaciones legales para Recluta contra Recluta en tres terrenos, la versión **Élite atacante** convierte **45** impactos adicionales en eliminaciones inmediatas.
- Con defensor Élite, **83** impactos que eliminaban al Recluta dejan de hacerlo en la comparación correspondiente.
- Los roles sin ataque convencional de este test son `ew`, `logistics`, `uav_recon`, `transport_heli` y `landing_ship`. No tratarlos automáticamente como malos: logística y reconocimiento necesitan métricas de utilidad, mientras EW/transporte/desembarco aún no tienen capacidades funcionales completas.
- El candidato antiblindaje +2 fue aplicable a **216** escenarios de la matriz multirango. No convirtió ninguno en una nueva eliminación de **primer impacto**, pero eso NO significa que sea inútil: reduce cuántos golpes se necesitan para destruir blancos fuertes.

No se sumó automáticamente ataque de veterano al Rompedor ni ataque/defensa de veterano al tanque. El modelo experimental de XP tiene progresiones específicas por rol, no multiplicadores globales.

## 3. Rompedor vs tanque: terreno, munición y supervivencia

Una unidad Rompedor posee 8 HP, 4 ATQ, 4 municiones; un tanque posee 14 HP, DEF 2. `TerrainTactics` suma cobertura forestal +1 o de montaña +2, y −1 ATQ al terrestre que dispara desde llano contra altura.

| Terreno defendido por el tanque | Daño base | Daño con tecnología +2 | Impactos teóricos sin tech → con tech | Munición del Rompedor |
|---|---:|---:|---:|---:|
| Llanura | 2 | 4 | 7 → 4 | 4 |
| Bosque | 1 | 3 | 14 → 5 | 4 |
| Montaña | 1 | 1 | 14 → 14 | 4 |

Así, la inversión antiblindaje crea un umbral **muy favorable** en llanura, pero no permite matar un tanque intacto con una única carga de 4 disparos si se protege en bosque o montaña. En particular, contra montaña +2 no cambia el daño debido a la combinación de defensa/cobertura/altura y mínimo de 1 daño.

**Advertencia:** los golpes restantes asumen objetivo inmóvil que no contraataca, no se retira y no se reabastece. La prueba también ejecutó el contraataque real `RoleSpecialization.preview_antiarmor`: el tanque devuelve **5 HP** en el primer intercambio sin tecnología, **4 HP** con ella. Un Rompedor solo, incluso mejorado, podría morir antes de lograr cuatro disparos. No llamar "4 golpes" a una victoria comprobada.

### Auditoría de nueve vehículos × tres terrenos

| Observación | Casos |
|---|---:|
| Situaciones de enfrentamiento válido y tecnológicamente compatibles | 27 |
| Tecnología que sí aumenta el daño de cada golpe | 26 |
| Tecnología que reduce golpes teóricos necesarios | 21 |
| Pasa de necesitar más de 4 a necesitar ≤4 disparos | 9 |
| Casos donde no cambia el daño (altura/cobertura) | 1 |
| Nuevas eliminaciones de un primer impacto | 0 |

**Recomendación:** conservar +2 como candidata de contrajuego y estudiarla con varios Rompedores, apoyo, costes y posiciones, sin subir por defecto el ataque base.

## 4. Facciones que no deben tratarse falsamente como débiles

| Facción | Qué sí puede compararse | Qué NO puede valorarse aún |
|---|---|---|
| Alianza Norte | catálogo de unidades y reglas de combate compartidas | precisión +5/+10 %: no existe comprobación aleatoria de acierto |
| Pacto Escarlata | proyección del +8/+15 % ofensivo | vulnerabilidad defensiva al iniciar ataque, efecto completo sobre contraataques y reglas de activación |
| Unión Verde | +1 movimiento como supuesto de movilidad | ahorro de turnos en flanqueos, captura y rutas; elegibilidad por clase sin definir |
| Confederación Solar | descuentos de producción como sensibilidad | exclusiones, turnos disponibles, casillas bloqueadas y volumen real comprado |
| Sindicato Violeta | ampliar a distancia 3 un Lanzador, 5 SPG, 6 MLRS cuando el poder esté activo | interferencia electrónica y la ventaja real de esos nuevos disparos en un mapa |
| Legión Ámbar | daño recibido, umbral de supervivencia | recuperación/retroceso/contraataque a largo plazo |
| Dominio Turquesa | daños y defensa navales proyectados | utilidad en mapas sin costa, rutas navales reales, superioridad de varios turnos |
| Orden Ónix | catálogo y objetivos estratégicos comunes | ocultación/sigilo/detección contra la IA real |

**Los ceros de Alianza Norte, Unión Verde, Solar, Violeta y Ónix en la matriz de daño NO significan debilidad**, sino variables que no son comparables con daño directo: probabilidades, economía, movimiento, visibilidad y rango. La matriz no es una clasificación justa de facciones.

### Cota superior de Confederación Solar

Si **todas** las 32 unidades fueran elegibles para descuento, comprar una unidad de cada clase costaría **21.000 créditos** antes de bonificación. El modelo matemático con redondeo cercano ahorraría **1.045** con −5 % pasivo y **3.145** con −15 % activo, antes de cualquier exclusión, restricciones de producción o variaciones de precios. **No es una cesta de compras realizable en una partida**, ni aprobación del descuento sobre las 32 clases.

## Decisiones recomendadas y siguiente ensayo

1. **Congelar** estadísticas base y balance 0.1 de comandantes; no migrar poderes a gameplay mientras falten redondeo, elegibilidad y persistencia.
2. Definir un **criterio de cálculo porcentual reproducible**, con pruebas de daño mínimo, cobertura, contraataque, veterano y tecnologías. Comparar daño acumulativo contra redondeo por golpe.
3. Dar prioridad a **Rompedor/Tanque, Legion Ámbar y Pacto Escarlata**, ya que los umbrales pueden cambiar supervivencia y primeras bajas de manera abrupta.
4. Construir después **simulaciones espejo de partidas completas** con economía y captura: ataque primero vs segundo, distinto mapa/costa, niebla, bloqueo de fábricas, distintas densidades de ciudad y cinco o más decisiones tácticas reales. Medir victorias, duración, daño, capturas, fabricación, turnos ahorrados, progresión XP y estados censurados.
5. Para 8 jugadores todavía falta estado de 8 bandos de verdad: **ocho emblemas/identidades visuales no equivalen a un motor de ocho jugadores**. No afirmar balance competitivo del multijugador.

## Evidencia reproducible

- Comparación cruzada completa: `tests/test_faction_power_stack_v17.gd`.
- Contrajuego antiblindaje y munición: `tests/test_antiarmor_terrain_breakpoints_v17.gd`.
- Reglas de base sin cambios: `scripts/core/Combat.gd`, `BattleActions.gd`, `UnitRoles.gd`, `ModernArsenal.gd`, `TerrainTactics.gd`.
- Progresiones no oficiales: `scripts/experiments/UnitVeterancyV14.gd`, `BuildingProgressionV12.gd`, `RoleSpecializationV08.gd`.
- CI: https://github.com/edwinrodri12/Tarvoka/actions/runs/43825006267 — los cuatro pasos pasaron.
