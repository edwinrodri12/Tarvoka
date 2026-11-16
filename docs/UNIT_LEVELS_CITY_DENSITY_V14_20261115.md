# TARVOKA — Balance v1.4: niveles individuales, más ciudades y economía territorial

**16 de noviembre de 2026 UTC · Rama experimental PR #394 · Los valores NO están aprobados ni integrados en Android**

## Dos necesidades identificadas en pruebas

1. El motor tiene cuatro rangos de veteranía definidos en `CombatDoctrine.gd`: **Recluta (0 XP), Regular (15 XP), Veterano (40 XP) y Élite (80 XP)**. Sus bonos de ataque y defensa están en cero. Para equilibrarlos correctamente necesitamos un beneficio **diferente para cada una de las 32 clases** y evitar que todos reciban multiplicadores de daño/defensa acumulados.
2. Hoy hay **cuatro ciudades generadoras de renta**, 250 créditos por ciudad en modo moderno; su número y valor no cambian con el tamaño del mapa. Muchos territorios extensos producen pocos puntos de interés disputables. Se propone probar más ciudades manteniendo ingresos **aproximadamente constantes**, con ubicación y propiedad simétricas.

## 1. Progresión individual de las 32 unidades — hipótesis para pruebas

Los bonos se obtienen por alcanzar el rango nuevo; cada fila muestra el **bono incremental** de Regular, después Veterano, después Élite. **No son mejoras de instalación, ni tecnologías compradas, ni estadísticas finales**. Los incrementos se acumulan entre los tres rangos, excepto en consumibles.

| Unidad / rol interno | Regular (15 XP) | Veterano (40 XP) | Élite (80 XP) |
|---|---|---|---|
| Guardia (line) | +1 vida | +1 visión | +1 ataque |
| Rastreador (scout) | +1 visión | +1 vida | +1 movimiento |
| Baluarte (bulwark) | +1 vida | +1 defensa | +1 vida |
| Rompedor (piercer) | +1 visión | +1 vida | +1 movimiento |
| Lanzador (artillery) | +1 visión | +1 vida | +1 ataque |
| Asaltante (assault) | +1 vida | +1 visión | +1 ataque |
| Ingeniero (engineer) | +1 vida | +1 visión | +1 movimiento |
| Transporte blindado (apc) | +1 visión | +1 vida | +1 movimiento |
| Vehículo de infantería (ifv) | +1 vida | +1 visión | +1 defensa |
| Tanque principal (tank) | +1 visión | +1 vida | +1 visión |
| Artillería autopropulsada (spg) | +1 visión | +1 vida | +1 ataque |
| Lanzacohetes múltiple (mlrs) | +1 visión | +1 vida | +1 visión |
| Antiaéreo móvil (mobile_aa) | +1 visión | +1 vida | +1 ataque |
| Batería SAM (sam) | +1 visión | +1 vida | +1 visión |
| Guerra electrónica (ew) | +1 visión | +1 vida | +1 movimiento |
| Vehículo logístico (logistics) | +1 vida | +1 visión | +1 movimiento |
| Dron reconocimiento (uav_recon) | +1 visión | +1 movimiento | +1 vida |
| Dron FPV (fpv) | No acumula XP | Consumible | Mejoras solo por tecnología futura |
| Munición merodeadora (loitering) | No acumula XP | Consumible | Mejoras solo por tecnología futura |
| Dron de combate (ucav) | +1 visión | +1 vida | +1 ataque |
| Helicóptero de ataque (attack_heli) | +1 visión | +1 vida | +1 ataque |
| Helicóptero de transporte (transport_heli) | +1 vida | +1 visión | +1 movimiento |
| Caza multifunción (fighter) | +1 visión | +1 vida | +1 ataque |
| Bombardero táctico (bomber) | +1 visión | +1 vida | +1 visión |
| Patrullero (patrol) | +1 visión | +1 vida | +1 ataque |
| Lancha misilera (missile_boat) | +1 visión | +1 vida | +1 ataque |
| Corbeta (corvette) | +1 vida | +1 visión | +1 defensa |
| Fragata (frigate) | +1 visión | +1 vida | +1 visión |
| Destructor (destroyer) | +1 visión | +1 vida | +1 visión |
| Submarino (submarine) | +1 visión | +1 vida | +1 movimiento |
| Buque de desembarco (landing_ship) | +1 vida | +1 visión | +1 movimiento |
| Dron naval USV (usv) | No acumula XP | Consumible | Mejoras solo por tecnología futura |

**Principios de balance:** cada rango añade solo un punto de estadística; por unidad, el total de mejoras en ataque y defensa nunca debe superar +1 cada uno, el HP adicional no supera +2 y el movimiento adicional no supera +1. No dar bonificaciones de munición porque el sistema Logistics valida capacidad por rol y podría rechazar guardados o estados ilegales; las mejoras de munición necesitan un cambio de esquema separado. Los roles sin efectos operativos (EW, carga de helicóptero/transporte, etc.) siguen necesitando sus mecánicas verdaderas: +1 visión no sustituye una capacidad no implementada. El Rompedor **no** recibe ataque adicional por experiencia en esta propuesta, para evitar que se acumule con su tecnología antiblindaje +2 que todavía está en evaluación. El Tanque tampoco recibe +1 defensa ni +1 ataque por veteranía, pues ya posee capacidad ofensiva/defensiva elevada.

**Prueba:** `tests/test_unit_veterancy_v14.gd`, `UnitVeterancyV14.gd`, GitHub Actions en workflow `unit-veterancy-city-density-v14.yml`. Compara 32 clases, 29 carreras de veteranía potenciales y 3 consumibles no evolucionables, 1.024 emparejamientos dirigidos de roles en terreno plano, perfiles máximos y daño inicial. No significa que se hayan jugado 1.024 combates completos.

**Necesario antes de producción:** definir cómo se gana XP al atacar, recibir daño, defender, capturar, reparar, apoyar, sobrevivir; impedir agricultura artificial de XP; limitar acumulación con poderes/facciones; asignar la experiencia al `id` real de la unidad, guardarla en SaveCodec y mostrar rango/XP en la interfaz.

## 2. Más ciudades, con ingreso total parecido

El modelo actual paga **250 créditos por cada ciudad**, con cuatro ciudades en 10×8 y también en 24×18/40×30. Su máximo total disponible en el mapa es 1.000, y con una ciudad inicial por facción cada una recibe 250 antes de capturas.

En el laboratorio `CityDensityV14.gd` se propusieron cuatro distribuciones con ciudades iniciales y neutrales en espejo:

| Variante | Ciudades iniciales por jugador | Ciudades neutrales | Paga cada ciudad | Renta inicial por jugador | Renta máxima si se controlaran todas |
|---|---:|---:|---:|---:|---:|
| 4 actuales | 1 | 2 | 250 | 250 | 1.000 |
| 8 | 2 | 4 | 125 | 250 | 1.000 |
| 12 | 3 | 6 | 83 | 249 | 996 |
| 16 | 4 | 8 | 62 | 248 | 992 |

Así el dinero de arranque y la renta posible total permanecen casi intactos, pero el jugador puede disputar/defender más localidades y un cambio de propiedad produce una fluctuación económica **menor por ciudad**. En 12 ciudades, ganar una da 83 créditos adicionales, en lugar de 250. Esto permitiría una guerra territorial gradual.

**Prueba automatizada de ubicación:** `tests/test_city_density_v14.gd` en cuatro escenarios, tamaños 24×18 y 40×30, ciudades 4/8/12/16 = 32 composiciones. La prueba verifica posiciones libres y transitables, simetría, ausencia de solapes, renta inicial de 248–250 por lado, máximo total de 992–1.000 y bonificación correcta tras una conquista hipotética. No presupone que la IA sepa valorar 83 créditos/casilla.

### Limitación de motor que impide integrar ya estas ciudades

`UrbanEconomy.MAX_SITES = 16` limita **todas las instalaciones sumadas**, no solo ciudades. El modo moderno ya incluye 4 ciudades, 2 fábricas tradicionales, 8 instalaciones especializadas y, si el mapa tiene mar navegable, 2 astilleros: **14 o 16 lugares** en total.

| Variante | Total de sitios sin astilleros | Total con astilleros | Compatibilidad de guardado v1 |
|---|---:|---:|---|
| 4 ciudades | 14 | 16 | Sí |
| 8 ciudades | 18 | 20 | No |
| 12 ciudades | 22 | 24 | No |
| 16 ciudades | 26 | 28 | No |

Además, `UrbanEconomy.income_for` sigue devolviendo 250 multiplicados por ciudades poseídas, por lo que **no se puede insertar el nuevo esquema sin actualizar la fórmula de ingresos y todos los validadores**. Las partidas A/B de combate con estas nuevas densidades todavía **no están ejecutadas**; los ensayos actuales son de distribución geométrica y presupuesto.

### Recomendación provisional

**12 ciudades** parece un punto de partida interesante para **24×18** (3 iniciales por bando y 6 neutrales). **16 ciudades** merece probarse en **40×30** (4 iniciales por bando y 8 neutrales). No imponer 16 en 10×8 porque puede saturar el tablero. Para futuros mapas de ocho jugadores se requerirá un algoritmo y validación de propiedad plurifacción adicionales: el motor actual de pruebas usa solamente dos bandos.

Antes de integrar, probar 8 vs 12 vs 16 ciudades en partidas completas con IA consciente de la renta por localidad, comparar duración, ingresos por fase, capturas, rutas, diversión, concentración de frentes y ventaja del primer jugador. Ajustar objetivos de captura progresiva porque invertir varias fases en conquistar una ciudad de 62–83 créditos puede ser muy caro y producir asedios eternos.

## 3. Interacción con edificios de nivel I–III

Distribuir mejor las ciudades NO implica que ya se puedan pagar mejoras más baratas. Una mejora de planta de blindados I→II se está evaluando en 650 créditos, aproximadamente **8 ciudades de 83 créditos durante un turno**. Con 3 ciudades iniciales se obtendrían 249/turno, así que la progresión inicial quedaría casi idéntica a hoy y seguiría compitiendo con crear más unidades.

Las tecnologías de edificios y los poderes de facciones deben mantenerse independientes de la experiencia individual: un Rompedor Veterano no debe activar gratis su tecnología antiblindaje y un tanque Élite no debe ganar automáticamente armadura de edificio. El diseño debe evitar que una ciudad de poco valor se vuelva imposible de capturar por unidades élite sobrepotenciadas.

## Veredicto actual

Esta fase es **análisis e implementación experimental** de candidatos con tests reproducibles, no implementación del juego. Se conservan intactos `scripts/core`, el APK Android, el guardado oficial, IA activa y las ocho facciones balance 0.1. El resultado de ambas baterías y métricas de daño deben tomarse de los logs de la ejecución de GitHub Actions, no declararse aprobadas antes de su PASS.


## Resultados verificados de Godot 4.3 (ejecución base)

**Simulaciones de nivel individual + distribución territorial:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43795761535 — SUCCESS, dos jobs. El análisis de 32 clases y 1.024 pares dirigidos observó **432 ataques legales**, de los cuales **125 aumentan daño con la versión Élite** y **23 se convierten en bajas de primer impacto** que la versión Recluta no conseguía. El ensayo tiene **29 líneas de XP candidatas** y **3 consumibles sin progresión XP**. Los bonos son propuestos, no estadísticas reales, y el defensor aún estaba en nivel básico en esta primera matriz. El test complementario `test_unit_veterancy_defense_v15.gd` estudia por separado resistencia y contraataques de defensores Élite en tres coberturas; requiere su propio SUCCESS para completar evaluación ofensiva/defensiva.

**Ciudad y renta:** se aprobaron **32 disposiciones** (4 terrenos × 2 tamaños × 4 densidades). Las variantes 8/12/16 mantienen 1.000/996/992 ingresos máximos por turno de todo el mapa y 250/249/248 por facción inicial, frente a 1.000 y 250 del esquema de cuatro ciudades. Ninguna de esas variantes cabe hoy en el validador `MAX_SITES=16` con todas las instalaciones militares incluidas. Esta ejecución **no demuestra tasas de victoria** con más ciudades porque el motor oficial rechazaría esos estados.

**A/B de inversión con compras y turnos verdaderos:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43796030916 — SUCCESS. En **cinco turnos propios** por variante y ambos bandos, construir **5 APC cuesta 1.500 y deja 2.000 créditos**, frente a subir la planta de blindados hasta III, producir **1 tanque y 1 Rompedor y comprar tecnología antiblindaje**, que cuesta **3.200 y deja 300**. Las dos recibieron 1.000 créditos en cinco turnos. Se confirmó que los nuevos vehículos deben desocupar la fábrica para volver a producir. No hay combate ni victorias: es una comparación de costos y retrasos, no un A/B de eficacia militar completa.

**Precaución:** el +1 ataque de una unidad veterana podría ser muy poderoso si se combina con una tecnología III o una ventaja permanente del comandante. El ensayo de defensor Élite y futuras simulaciones con rangos mezclados deberán determinar qué 23 nuevas eliminaciones rápidas resultan aceptables y cuáles perjudican contrajuegos.
