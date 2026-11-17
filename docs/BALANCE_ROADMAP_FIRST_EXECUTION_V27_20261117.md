# TARVOKA — Puesta en marcha del sistema de equilibrio competitivo

**17 de noviembre de 2026 — Plan de ejecución concreto.**
**Estado:** v2.7 código experimental y baterías de pruebas enviadas a [PR #517](https://github.com/edwinrodri12/Tarvoka/pull/517). Hasta confirmar CI y los resultados A/B, no implementar la nueva regla en el APK ni en main.

## Objetivo de producto

Queremos que **un ejército más fuerte porque jugó mejor pueda ganar**, pero **ningún jugador tenga asegurada la victoria por elegir antes un comandante, un color, una apertura, o porque una contramedida básica estaba bloqueada**. La diversidad de estrategias y la posibilidad de respuesta importan más que un 50/50 artificial conseguido con rubber-banding.

## Primera intervención real: Rompedor en el Cuartel I

Implementación experimental **opt-in** en v2.7 con una ruta de compra legal:

`FixedSiteOrdersV19.purchase` → `CapturableProductionV18.purchase` → `BattleSession.purchase` → `UrbanEconomy.purchase`.

Todo el encadenamiento acepta el parámetro experimental explícito, y su valor por defecto es `false`. Con `false`, el Rompedor se produce como antes, en planta blindada. Con `true`, el Rol `piercer` se produce en fábrica/Cuartel I por el mismo **precio 300, HP 8, ataque 4 y movilidad 3**.

**No se inventan fábricas**: el nodo de compra sigue requiriendo instalación fija propia, casilla libre, turno no usado, fondos, dominio válido y producción real. No se cambia `SaveCodec`. El ejercito en simulador **ya posee un Rompedor al inicio**, por lo que este experimento prueba principalmente la capacidad de entrenar **más**.

En la IA de presión, la nueva regla prioriza producir Rompedores en el Cuartel. Este cambio de **política de producción** se ensaya junto con la **disponibilidad de producción**, por lo que no demuestra por sí solo qué factor aislado produce cualquier mejora. Antes de integrar hay que repetir ensayos de doctrina más variada, para evitar convertir la solución en puro spam de bazucas.

## Pruebas que se deben aprobar

1. Smoke en Godot 4.3: compatibilidad por defecto, primera compra legal en mapa 10×8 y 24×18 para ambos colores, débito exacto 300 créditos, sin compra desde fábrica enemiga, sin dos compras desde la misma fábrica en una fase, sin fabricar tanque desde cuartel, unidad generada sin acción extra ese turno.
2. Paridad: un duelo sin indicador produce EXACTAMENTE el mismo informe de v2.2 que con indicador omitido o vacío.
3. **48 combates A/B**: en cada mapa (10×8 abierto, 24×18 abierto, 24×18 bosque), 2 rivales (Presión vs Blindados; Expansión vs Blindados) × 2 iniciadores × 2 permutaciones de lado × 2 modos = 16 partidas/mapa. El rival blindado paga nivel II **650 créditos** antes de construir tanques.
4. Todos los saldos cierran: 2.500 iniciales + ingresos de ciudades – compras – evolución del blindado. Partidas no decididas al corte son **censuradas**, no empates ni victorias por puntos.
5. Documentar victorías, compras totales, Rompedores comprados, daño, pérdidas, ciudades tomadas, tiempo de partida y calidad de respuesta (si el laboratorio no mide todavía ataques al tanque en particular, NO inventar esos datos).
6. Mantener los informes de mapas e iniciativa por separado; evitar conclusiones de equilibrio con ocho partidas deterministas.

## Interpretación de resultados

- **Si presión mejora y expansión no se destruye:** es evidencia preliminar de que la falta de contramedidas tempranas sí contribuía al dominio de blindados. Antes de integrar probar variedad de compras de infantería, no solo comprar Rompedor todos los turnos.
- **Si presión no mejora:** investigar ocupación de fábricas, rutas, posiciones de cobertura, tiempos de captura, IA y apoyo combinado. No aumentar daño ni reducir HP de tanque de inmediato.
- **Si presión gana siempre:** el peligro cambia de bando. Probar límites basados en economía y oportunidades de producción, no nerfs arbitrarios. Mejorar IA para adaptación entre Guardia y Rompedor y artillería.
- **Si grandes mapas siguen estancándose:** pasar a prototipo de victoria HQ, además de mejorar objetivos y buscar progresión táctico-económica; no dar un ganador artificial por expiración de límite.

## Siguientes etapas, ordenadas por dependencia

| Etapa | Cambio experimental | Qué mide | Bloqueo de publicación |
|---|---|---|---|
| E1 | Cuartel I produce Rompedor legal, precio igual | Accesibilidad de counter y primera respuesta | PR #517 CI + pruebas espejo + no regresiones |
| E1b | IA contramedidas dinámicas, mix infantería/ingeniero/bazuca | Si balance proviene de disponibilidad o de spam | Diversidad + counter real y reproducible |
| E2 | Mapas certificados: simetría y tiempo real hasta bases/ciudades; versiones con rutas alternativas | Si las aperturas están predispuestas | 8 facciones no depender del lado |
| E3 | Victoria HQ por captura sostenida con respuesta visible | Terminar batallas medianas sin victoria sorpresiva | Ningún rush de HQ sin posibilidad de respuesta |
| E4 | Liga de bots que encuentra una estrategia ganadora y diseña su mejor contrarrespuesta | Dominancia / diversidad del metajuego | Varias rutas válidas y ningún exploit invencible reproducible |
| E5 | Matriz 8×8 facciones, poderes + clima + terreno + suministro + XP y campamentos | Sinergias especiales y sesgos | Pilotos extensos y playtesting humano |
| E6 | Torneos y calibración con humanos de niveles comparables | Experiencia y justicia percibida | Documentación de casos de frustración/encierro |

## Cambios que NO hacemos en v2.7

- No añadir créditos al segundo jugador: ya cobra primero sus ciudades al iniciar su primer turno.
- No activar universalmente el límite opcional de tres órdenes: en v2.5, combinado con desempates simétricos, generó hasta **10/12** victorias del iniciador en 10×8.
- No cambiar el tanque (750 créditos, 14 HP, ataque 8, defensa 2 en catálogo moderno) ni Rompedor.
- No regalar tecnología +2, ni trasladar todavía su investigación del nivel III al II.
- No insertar nuevas reglas en el APK ni `main` sin completar las verificaciones y revisión de los resultados.
- No afirmar que 48 partidas con 3 mapas y las mismas IA deterministas son una demostración de igualdad competitiva; son un filtro temprano para descubrir problemas.

## Trazabilidad

- [PR experimental v2.7](https://github.com/edwinrodri12/Tarvoka/pull/517)
- `tests/test_barracks_piercer_smoke_v27.gd`
- `tests/test_barracks_piercer_ab_v27.gd`
- `.github/workflows/barracks-piercer-v27.yml`
- [Investigación comparativa v2.6](https://github.com/edwinrodri12/Tarvoka/blob/research/counterplay-fairness-framework-v26-20261117/docs/RESEARCH_COMPETITIVE_COUNTERPLAY_FAIRNESS_V26_20261117.md)
