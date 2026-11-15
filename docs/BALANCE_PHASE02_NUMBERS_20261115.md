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
