# TARVOKA — Fase 01: auditoría de combate y economía (15-11-2026)

**Estado:** medición inicial en rama aislada. No modifica reglas jugables, números aprobados de las ocho facciones, poderes, mapas, campaña ni guardados. Los resultados de nuevas pruebas se distinguen de las conclusiones de diseño; una compilación o CI verde **no** demuestra diversión ni balance competitivo.

## 1. Qué existe realmente en main

Fuentes de verdad: `scripts/core/UnitRoles.gd`, `ModernArsenal.gd`, `UrbanEconomy.gd`, `BattleActions.gd`, `CombatDoctrine.gd`, `Logistics.gd` y `TerrainTactics.gd`.

- **32 roles jugables en catálogo**: 5 originales y 27 modernos; 16 terrestres, 8 aéreos y 8 navales. El diseño de **24 familias y niveles I/II/III** está en `CAMPAIGN_TECH_LEVELS_V1.md`, pero no debe tratarse como 24 familias ya migradas ni como estadísticas de nivel II/III activas.
- El combate determinista descuenta ataque, defensa y cobertura, con mínimo de 1 HP para ataques positivos; añade terreno, altura, flanqueo, roles, munición y respuesta condicionada por supervivencia y capacidad. Un duelo G09 sin cobertura comienza con **6 HP de daño y 3 HP de contrafuego**. No es porcentaje de salud restante del atacante.
- **Economía moderna**: 2,500 créditos iniciales por bando; **250 créditos por ciudad propia**, una vez al comenzar el turno propio, sin ingreso inicial adicional; cuatro ciudades en mapas de ejemplo (una inicial por bando y dos neutrales). Las instalaciones producen una unidad por fase de instalación, sujetas a ocupación y tipo. El tope de créditos es 100,000. La economía clásica es distinta (300 iniciales / 100 por ciudad).
- **Logística**: la munición y el combustible son inventarios reales; reabastecer en instalación propia consume créditos, el camión usa inventario limitado. Unidades aéreas/navales consumen combustible por turno salvo en instalaciones de servicio apropiadas.
- **Comandantes**: retratos, facciones, escudos y selección visual integrados; poderes no activados. Veteranía (15/40/80 XP) y mejoras específicas **no activas**. No se deben equilibrar poderes como si ya alteraran el daño.
- **Dos jugadores tácticos actuales**, aunque existen ocho identidades; **ocho jugadores conectados** es una meta futura, no una modalidad validada hoy.

## 2. Indicadores cuantitativos iniciales

| Elemento | Precio (cr.) | Turnos de ingreso de **una** ciudad para pagarlo, partiendo de 0 cr. |
|---|---:|---:|
| Rompedor | 300 | 2 |
| Ingeniero | 250 | 1 |
| Asaltante | 250 | 1 |
| APC | 300 | 2 |
| IFV | 500 | 2 |
| G09 tanque | 750 | 3 |
| MLRS | 850 | 4 |
| Bombardero | 1,400 | 6 |
| Destructor | 2,000 | 8 |

Estos **no** son tiempos reales de fabricación: omiten créditos acumulados, instalaciones disponibles, una producción por instalación/fase, desplazamientos, gastos de combustible, reparaciones, munición y captura. Sirven para comparar orden de magnitud del poder adquisitivo.

**Ejemplo de efecto territorial:** 1 ciudad propia da 250 cr./turno, 2 dan 500, 3 dan 750. El salto de 1 a 2 ciudades es **+100 % de flujo recurrente** y dos ciudades extra frente a un rival que mantiene una dan ventaja de **500 cr./turno**, si se conserva su control. La fase 01 verifica que esta renta se acredita solo en el turno siguiente; todavía hay que medir si causa una bola de nieve irreversible.

## 3. Riesgos a investigar (hipótesis, no veredictos)

| Nivel | Riesgo | Evidencia actual | Prueba que falta |
|---|---|---|---|
| P0 | Rentas urbanas y dominio temprano | 250 cr. por ciudad; ingresos de 250/500/750 | Partidas pareadas con dos vs tres ciudades; curvas de ingresos, compras y recuperaciones del bando rezagado |
| P0 | Sesgo de iniciativa | `TERRAIN_INITIATIVE_BALANCE.md` documenta el problema y la apertura de 3 órdenes como mitigación experimental | Partidas con mapa/niebla/bando iniciador intercambiados, pocas y muchas unidades, distintas tácticas |
| P1 | Precio sin funcionalidad de soporte | EW (550 cr., arma 0) todavía no interfiere; helicóptero de transporte (500) y desembarco (900) todavía no cargan unidades | Antes de valorar precio, implementar acción o restringir compra en modos competitivos |
| P1 | APC e IFV | APC 300, IFV 500, carga pendiente; diferencia de ataque y visión existe | Eficacia por coste frente a infantería, G09, apoyo, niebla y terrenos; después probar transporte |
| P1 | Ingeniero contra Asaltante | Ambos cuestan 250; Asaltante tiene 9 HP/5 ATQ frente a 7 HP/2 ATQ del Ingeniero | Medir valor de capturas, reparación y tiempo de desplazamiento tras integración de PR #320/#323 |
| P1 | Rompedor contra tanque | En **main** +4 al Baluarte; PR #328 propone +2 a G09 y PR #333 lo usa | Validar y fusionar dependencias en orden, comparar con precios, cobertura y contrafuego |
| P2 | Tecnología II/III y poderes | Diseño y ocho identidades aprobadas; sin bonificaciones implementadas | Definir costos de oportunidad, límites, lectura en HUD y contrajuego antes de activar |
| P2 | Naval y aéreo especializado | Submarino sin sigilo/sonar; bombardero sin área; lanzaderas y combustible reales | Mapas de agua/costa, escenarios de intercepción y análisis de municiones por daño neto |

## 4. Experimentos para la siguiente iteración

1. **Economía/captura:** 40+ pares por mapa/tamaño de ejército y nivel de niebla, alternando inicio y control inicial de ciudades; registrar ingreso por fase, créditos en caja, compras válidas, reparación/recarga, capturas recuperadas, turnos, bloqueos y ganador. La cantidad es una primera meta de muestras, no una certificación estadística.
2. **Eficiencia de cada familia:** registrar daño infligido/recibido, costo de reposición, reabastecimiento, visión útil, movilidad y capturas por rol, frente a amenazas apropiadas y mapas donde pueda operar; no clasificar como inferior a un transporte solo porque ATQ=0.
3. **Combatir la estrategia dominante:** variar infantería masiva, blindados, artillería, control territorial y economía defensiva; identificar compras ignoradas por la IA y también el juego de un humano.
4. **Comandantes y niveles:** únicamente después de consolidar mecánicas activas, experimentar con los ocho poderes v0.1 sin modificar sus identidades aprobadas y con un modo PvP sin XP persistente adquirido fuera de partida.

## 5. Criterios de aceptación

- **Invariantes duros:** costo real = costo mostrado; IA usa mismos créditos, visión y reglas; ninguna compra o reparación regala recursos; no se cobra ingreso más de una vez; daño previsto no contradice daño real bajo información pública.
- **Indicadores exploratorios:** victoria por iniciador, tasas de empate/estancamiento, mediana de turnos, comeback tras perder una ciudad, tiempo hasta la primera compra útil, economía desperdiciada y roles nunca usados. **Una muestra de 16 partidas de IA no permite afirmar paridad PvP.**
- **Objetivo de diseño, no umbral automático de CI:** aproximarse a 45–55 % de victorias entre iniciadores en cohortes grandes, simétricas y controladas, sin ocultar empates ni forzar este valor con atributos invisibles.
- **Prueba humana obligatoria:** explicar daño, costo, contramedida y finalidad de una unidad desde UI; partidas reales pueden contradecir una matriz perfecta.

## 6. Integración y compatibilidad

Nueva prueba independiente: `tests/test_balance_phase01_economy_combat.gd` y workflow `.github/workflows/balance-audit-phase01.yml`. Generan líneas `BALANCE01_*` y preservan economía, facciones y guardados. **No se fusiona automáticamente** sin verificar CI y rebase, especialmente respecto de PR #320, #323, #328 y #333.

**Próxima decisión después de la línea base:** profundizar el modelo de ventaja urbana (incluyendo captura/recaptura y comportamiento IA) y solo entonces proponer una o dos variantes económicas A/B con indicadores de diversión y justicia. Evitar bajar ingresos o subir precios únicamente por intuición.
