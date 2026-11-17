# TARVOKA — Balance v2.2: ¿Domina el tanque por sus estadísticas o por acceso temprano?

**17 nov 2026 | Investigación A/B aislada, DRAFT [PR #503](https://github.com/edwinrodri12/Tarvoka/pull/503)**

**Godot 4.3 — CI SUCCESS, cuatro jobs:** https://github.com/edwinrodri12/Tarvoka/actions/runs/44039019519

## Diseño experimental

- Mismas reglas tácticas y compras legales de V19/V21, mismos rivales, mismo mapa y misma prioridad de acciones; sin cambios de HP, daño, defensa o coste de tanque.
- Dos escenarios económicos: **instant** (regla v21 sin restricción de planta) y **level2** (cada planta blindada tiene que evolucionar a nivel II por **650 créditos** antes de producir tanque o IFV). Actualizarla consume una oportunidad de compra en ese turno; el primer tanque puede comprarse desde su siguiente turno propio. Su nivel se registra en sidecar con la identidad del dueño y se invalida al cambiar el propietario.
- Dos rivales: expansión de infantería/APC y presión con Rompedores/asaltantes, bajo dos órdenes de iniciativa y dos asignaciones de bando. **8 pares espejo por escenario × 3 escenarios = 24 configuraciones emparejadas × 2 variantes = 48 partidas reales ejecutadas con el motor Godot**.
- En 10×8, las plantas blindadas son neutrales; en 24×18 cada lado tiene una planta desde el comienzo. No confundir capturar planta con su desbloqueo.
- Se mantiene el límite experimental de 42 medias fases en 10×8 y 52 en 24×18. Todos los finales no decididos son **censurados**, no empates.
- Aseveraciones verificadas: saldo final exacto = 2.500 iniciales + ingresos por ciudades – compras de unidades – upgrades; cada tanque en modo `level2` exige una planta que alcanzó nivel II de forma pagada; modo `instant` reproduce exactamente los resultados V21; la mejora no afecta al lado contrario ni surge sin control de la base.
- **Importante**: se prueba **solo el desbloqueo de tanque/IFV**, no el conjunto integral de mejoras I–III para cada fábrica. XP, campamentos, poderes de comandantes y tecnología pagada antiblindaje no actúan en estas partidas.

## Resultados: participación de la doctrina de blindados

Cada fila es la **agregación de ocho partidas para esa modalidad en ese mapa**, no 8 semillas aleatorias distintas.

| Mapa | Acceso | Victorias / derrotas / censuradas | Tanques producidos | Créditos invertidos en nivel II | Daño total | Bajas producidas | Ciudades capturadas* | Bases capturadas* |
|---|---|---|---:|---:|---:|---:|---:|---:|
| 10×8 abierto | inmediato | **7 / 1 / 0** | 30 | 0 | 725 | 92 | 14 | 10 |
| 10×8 abierto | nivel II | **7 / 1 / 0** | 33 | 5.200 | 796 | 93 | 14 | 11 |
| 24×18 abierto | inmediato | **1 / 1 / 6** | 48 | 0 | 1.397 | 164 | 47 | 38 |
| 24×18 abierto | nivel II | **1 / 1 / 6** | 21 | 5.200 | 1.250 | 146 | 33 | 28 |
| 24×18 boscoso | inmediato | **1 / 0 / 7** | 34 | 0 | 1.409 | 175 | 30 | 35 |
| 24×18 boscoso | nivel II | **1 / 0 / 7** | 28 | 5.200 | 1.267 | 147 | 31 | 33 |

*Capturas acumuladas, incluyendo reconquistas, no cantidad única de instalaciones poseídas.*

**Agregados de las 24 apariciones por variante:**

- Victorias: **9** tanto inmediato como nivel II; derrotas **2** en ambos, censuradas **13** en ambos. La igualdad de totales oculta **cuatro partidas individuales con distinto estado final**, dos en cada mapa mediano, entre victoria y censura (ninguna ganadora directa cambió a victoria del rival).
- Tanques: **112 inmediato → 82 tras nivel II** (−26,8%). Gastos extra directos por desbloqueos: **15.600 créditos** repartidos entre las 24 partidas.
- Daño: **3.531 → 3.313** (−6,2%); bajas: **431 → 386** (−10,4%); capturas de ciudades: **91 → 78** (−14,3%); capturas de bases: **83 → 72** (−13,3%).
- En mapa 24×18 abierto: **48 → 21 tanques** (−56,3%), **1.397 → 1.250 daño** (−10,5%), **47 → 33 capturas de ciudades** (−29,8%).
- En bosque: **34 → 28 tanques** (−17,6%), **175 → 147 bajas** (−16,0%).
- En mapa pequeño: aunque se pagaron 650 créditos adicionales por partida, se observaron **7 victorias de 8 en ambos casos**. El ejército invirtió más turnos (96 → 105 turnos propios agregados) y terminó produciendo más tanques (30 → 33), consecuencia posible de la prolongación de batallas y cambios de decisiones; **no interpretar más producción total como que la mejora ofrece tanques gratis**.

### Cuándo surge el primer tanque

- Ejemplo de control reproducible en mapa 24×18 abierto, primeras ocho medias fases: inmediatamente **fase 1**, gated **fase 3**; unidades compradas 4 vs 3; créditos restantes 1.330 vs 930. El modo instant coincide exactamente con V21.
- En las ocho pruebas del mapa 24×18 abierto, media de primera compra de tanque **1,5 medias fases (inmediato)** vs **3,5 (nivel II)**; en el boscoso, el mismo patrón.
- En mapa pequeño, el acceso al tanque depende ante todo de capturar la planta neutral; por eso el efecto en el momento de primer tanque es menor y no necesariamente monotónico entre partidas, debido a cambios de trayectoria y duración.

## Interpretación del balance

El requisito de nivel II **sí impone una desventaja económica y retrasa el primer tanque en mapas medianos**, con reducción real de producción y pérdidas causadas por los blindados. Sin embargo, **no corrigió la tasa de victorias del mapa pequeño**: 7/8 sigue siendo mucho. Por tanto, **no basta aumentar el precio del desbloqueo**.

La fuerza ofensiva y la resistencia del tanque respecto al Rompedor deben estudiarse aparte: el candidato +2 antiblindaje en `RoleSpecializationV08` y `BuildingProgressionV12` cuesta 450 de investigación, y todavía no está integrado como orden auténtica en partidas v2.2.

La victoria actual es por eliminación total; en 24×18 hubo **13 de 16 partidas censuradas en cada variante** sumando abierto (6/8) y bosque (7/8). Sin más semillas ni victoria por objetivos, no hay prueba estadística de que el requisito I→II mejore la equidad de victorias entre doctrinas.

## Próximas prioridades

1. Comparación experimental **Rompedor con bonus antiblindaje +2 tras tecnología pagada de 450 créditos** frente a tanque nivel II, respetando munición, terreno, contraataques y producción real; confrontar alternativas de varios Rompedores y objetivos.
2. A/B de **victoria por instalaciones/HQ** o control territorial, expresamente propuesto y etiquetado para playtest; no reemplazar victoria oficial hasta validar.
3. Repetir mapa 40×30, varias semillas y condiciones de niebla cuando el motor lo permita. Incluir costo de oportunidad del upgrade de instalaciones en todos los roles, no solo tanque.
4. Los campamentos se diseñaron por separado; las **reglas acordadas** están preservadas en [INFANTRY_SPECIALISTS_CAMPS_SPEC_20261117.md](INFANTRY_SPECIALISTS_CAMPS_SPEC_20261117.md). El presente estudio no implementa esos efectos.

**No tocar núcleo, APK ni guardados en esta fase.** Esperar evaluación de competitividad antes de fijar costos o nerfear HP/ataque del tanque.

## Trazabilidad

- Motor v2.2: `scripts/experiments/TankUnlockEconomyV22.gd`
- Extensión opcional sin cambiar comportamiento por defecto: `scripts/experiments/StrategicMatchBalanceV21.gd`
- Smoke y paridad: `tests/test_tank_unlock_smoke_v22.gd`
- Partidas espejo: `tests/test_tank_unlock_pairs_v22.gd`
- CI 4/4: https://github.com/edwinrodri12/Tarvoka/actions/runs/44039019519
