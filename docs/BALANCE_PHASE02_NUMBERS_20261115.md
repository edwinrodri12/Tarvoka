# TARVOKA — Auditoría de números y jugabilidad, fase 02 (15-11-2026)

**Estado:** rama de diagnóstico independiente. No se modifican precios, atributos, movimientos, modos, facciones, comandantes, equipos ni partidas guardadas. Se ejecuta con **Godot 4.3**, usando los archivos reales del motor. No se necesitan modelos 3D para evaluar estos cálculos.

## Preguntas que responde el ensayo
1. ¿Las **32 clases de unidades** tienen rangos legales, objetivos válidos, gasto de munición, prestaciones y precios coherentes desde las reglas existentes? ¿Cuáles no atacan y dependen del rol de apoyo?
2. ¿Qué diferencia de movilidad crean los **cuatro mapas de referencia y los tres climas** despejado/lluvia/nieve para infantería, ruedas, orugas, aeronaves y barcos? ¿El mismo mapa da alcance equivalente a los dos bandos?
3. ¿Cuán rápido se transforma **una ciudad extra de ingreso** en poder económico frente a un ejército que no consigue esa ciudad? ¿El reloj de pagos favorece al iniciador?
4. ¿Cuál es la situación al terminar seis rondas aproximadas en **32 aperturas de IA** (4 mapas × 2 nieblas × 2 iniciadores × apertura libre o de tres órdenes), usando combate, compras, ingresos, captura y suministros reales?

## Detalles de prueba
- `tests/test_balance_phase02_numbers.gd`: carga `UnitRoles`, `ModernArsenal`, `CombatDoctrine`, `Logistics`, `Weather`, `Scenarios`, `BattleActions`, `Rules`, `UrbanEconomy`, `BattleSession`, `BasicAI` y `SaveCodec`.
- **32×32 = 1.024 pares** atacante/defensor considerados. Se promedian *solo* los pares legalmente atacables según dominio (tierra/aire/mar) y rango; las armas indirectas se prueban al rango mínimo correcto. Se registran ataques posibles y daño inicial máximo. La zona costera de ensayo combina una franja de agua con tierra, permitiendo posiciones legalmente pertenecientes a cada dominio.
- Los **5 roles sin ataque** se clasifican como apoyo y no como unidades de combate infravaloradas: guerra electrónica, logística, dron de reconocimiento, helicóptero de transporte y barco de desembarco. No presumir que todos tienen ya sus capacidades especiales implementadas.
- En **cada clima** y cada mapa aplicable se comparan casillas alcanzables para el mismo rol desde el este y el oeste, aprovechando la simetría del escenario y las mismas reglas reales de costes de terreno. La lluvia/nieve no deben mágicamente aumentar distancia.
- Economía: 0, 1 o 2 ciudades neutrales adjudicadas adicionalmente a un bando; tres cobros por lado, con exactitud y sin duplicados. Con +1 ciudad = +250 por turno propio; a tres cobros = **+750**, un tanque principal de 750 créditos, antes de considerar combate, captura, mantenimiento o producción. Este es el componente **aislado** de la economía, no una simulación de victoria.
- **32 partidas IA** con compra, ataque, movimiento, reabastecimiento y captura. Se verifican variaciones de créditos producidas por acciones, pago exacto al comenzar el turno del rival y guardados. Se registran bandos iniciadores y cierres sin ganador separados de victorias. Doce medias fases equivalen a aproximadamente seis turnos de cada jugador, no necesariamente a una partida terminada.
- Contramedidas y ataques no implican necesariamente eficiencia real por crédito: el estudio es un primer mapa cuantitativo antes de pruebas de interacción coste/vida/defensa/suministros/visión.

## Restricciones a mantener
- Los `tier=1..4` de CombatDoctrine son **actos narrativos de introducción, NO mejoras implementadas**. No afirmar que ya hay una progresión de niveles de ataque/defensa ni balancearla como si fuera realidad.
- Los poderes únicos de ocho comandantes y el auténtico combate de 4/6/8 participantes todavía requieren motor y pruebas separados. No usar presentaciones gráficas como prueba de funcionalidad.
- Las partidas entre IA son una señal limitada. No decidir nerfs/buffs por tasas de victoria con muestra pequeña.
- La economía de ocho jugadores está fuera del alcance de este ensayo: `UrbanEconomy` todavía tiene bandos 0 y 1.
- No cambiar los números sin un experimento A/B que demuestre que la modificación mejora variedad de estrategias, contrajuego y ritmo en más escenarios.

## Salidas
Las líneas `BALANCE_ROLE`, `BALANCE_MOVE`, `BALANCE_CITY`, `BALANCE_OPENING`, `BALANCE_PHASE02_SUMMARY` y `PASS balance phase 02:` se conservan en el log de GitHub Actions. Tras verificar la CI, registrar las cifras y convertir los casos sospechosos en pruebas de combate con composición y precios controlados.

## Resultados verificados con CI (Godot 4.3, ejecución 43695385829)

**[Prueba completa: SUCCESS](https://github.com/edwinrodri12/Tarvoka/actions/runs/43695385829)**. La prueba ejecutó **1.024 parejas rol-atacante/rol-defensor**, de las cuales **432 permiten disparo real según distancia, tipo de objetivo y armamento**. Todos los perfiles tienen costo positivo, instalación de producción, vida/movimiento/rango legal, reacciones y municiones validadas. Se clasificaron exactamente 5 roles sin ataque convencional: `ew`, `logistics`, `uav_recon`, `transport_heli`, `landing_ship`. **Esto valida consistencia del motor, no garantiza valor estratégico de cada unidad.**

**Movimiento/clima:** 312 combinaciones rol × mapa compatible × clima, comparadas desde ambos extremos del campo. La lluvia redujo casillas alcanzables respecto al cielo despejado en 32 combinaciones de rol y mapa; nieve en 44. No se encontraron ampliaciones espurias por empeorar el clima ni ventajas de posición este/oeste en esta batería. No incluye simulación dinámica de flancos o combustible agotado después de muchos turnos.

**Economía aislada:** una ciudad adicional pasa de 250 a 500 créditos de ingresos por turno propio, lo que añade +750 después de tres pagos, equivalente al costo actual del tanque de 750. Dos ciudades extras suponen 750 contra 250 por turno, +1500 después de tres pagos. Con ingresos simétricos durante seis medias fases, ambos bandos obtuvieron 3250 créditos independientemente de quien iniciara; se verificó que el pago se acredita una sola vez al comienzo de cada turno correspondiente.

**Aperturas de IA:** 32 simulaciones de 12 medias fases (aproximadamente seis rondas completas). Se ejecutaron **607 compras, 122 cambios de control urbano y 36 reabastecimientos**. **Ninguna partida había concluido a la fase 12**: no se puede calcular tasa de victorias ni concluir que el primer jugador o el segundo tiene ventaja decisiva en este horizonte.

**Desigualdades al corte:** créditos sin gastar = caja, **no** poder económico ni valor total del ejército. Los promedios siguientes muestran qué escenarios revisar primero, sin introducir cambios de balance en esta rama:

| Escenario 10×8 | Diferencia media absoluta de créditos | Diferencia media de renta por turno | Diferencia media de unidades vivas | Máxima brecha de caja observada |
|---|---:|---:|---:|---:|
| Campo abierto | 1150 | 125 | 1,3 | 1700 |
| Bosque de dos rutas | 1491 | 375 | 1,4 | 2850 |
| Puentes | 1175 | 375 | 1,3 | 2300 |
| Costa | **1685** | **438** | **3,3** | **3050** |

Son ocho partidas por escenario (dos nieblas × dos primeros jugadores × dos aperturas), con dos bandos de IA idéntica, no muestra humana. Los valores de renta son el **desbalance absoluto de ingresos por ciudades poseídas en el punto de corte**, no una media de renta durante toda la partida. El coste de unidades compradas, daños, posición y composición deben medirse antes de comparar los créditos de cierre. Las medias de muestra reducida, mapas simétricos y IA determinista no extrapolan estadísticamente a partidas humanas.

**A/B apertura libre vs tres órdenes (n=16 cada una):** media de brecha de caja **1417** vs **1334** créditos, y renta desigual **344** vs **313** por turno. Son diferencias descriptivas, **no evidencia suficiente de que el límite mejore el juego**; se estudiarán enfrentamientos completos, alternando iniciador y geografía.

### Prioridades de la fase 03
1. En cada turno medir **riqueza total** (efectivo + valor invertido en unidades vivas ajustado por HP + suministros), no solo dinero disponible, y la probabilidad de remontada tras perder una ciudad.
2. Estudiar la costa y dos rutas con diversas composiciones iniciales; contabilizar adquisiciones, bajas, capturas netas y tiempos hasta victoria, sin ocultar partidas que terminan tras más de seis rondas.
3. Auditar unidades con ataques restringidos (SAM, antiaéreos, submarinos, artillería, unidades de un solo uso) y evitar que precios favorezcan a unidades cuyo papel especial aún está pendiente de programación.
4. Cuando exista un sistema real de mejoras, evaluar **coste por mejora y beneficio efectivo**; `tier` del catálogo actual es solo acto de campaña, y no hay progresión de atributos implementada que se pueda medir como si existiera.
5. Conservar el balance 0.1 de las ocho facciones hasta disponer de poderes y pruebas funcionales que justifiquen una revisión.

**Dictamen de esta fase:** la batería de coherencia pasó, pero todavía NO se certifica que las estadísticas actuales sean competitivamente equilibradas o divertidas. El principal riesgo cuantificable es la ampliación económica por captura, especialmente en mapas que facilitan concentrar ciudades.
