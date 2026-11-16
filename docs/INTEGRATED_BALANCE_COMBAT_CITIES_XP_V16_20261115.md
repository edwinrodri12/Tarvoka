# TARVOKA — Experimento v1.6: combate real + ciudades repartidas + experiencia + inversiones militares

**16 de noviembre 2026 UTC · PR #394 (DRAFT) · Investigación aislada, NO reglas finales**

## Objetivo

El usuario pidió avanzar del análisis estático a **partidas con los tres sistemas interactuando**: niveles individuales de experiencia, tecnologías compradas por instalaciones I–III y ciudades más numerosas cuyo ingreso total no se dispare. Se implementó un **orquestador de combate para pruebas** sin alterar el código principal.

Los módulos anteriores estaban validados por separado, no estaban conectados: un estado con 12 ciudades no era aceptado por `UrbanEconomy.valid` (`MAX_SITES=16`, incluyendo fábricas), y el validador pagaba siempre 250 créditos por cada ciudad. Por otra parte, la experiencia y los niveles de edificios existían en modelos externos al estado oficial.

## Arquitectura del prototipo

**`scripts/experiments/IntegratedBalanceBattleV16.gd`** implementa un laboratorio de partidas de DOS bandos, no una pantalla jugable:

1. `BattleSession.start` crea el estado oficial y las instalaciones ya válidas para el motor, junto a un ejército simétrico compacto de Guardia, Rastreador y Rompedor.
2. `CityDensityV14.layout` construye un registro *externo* de ciudades para la modalidad **4, 12 o 16** y guarda la propiedad real experimental de cada ciudad. Las ciudades adicionales **no se insertan** en `state.economy.sites` porque romperían el límite del motor. Sus ubicaciones se exponen al planificador experimental, no a `BasicAI` oficial.
3. El planificador de referencia utiliza acciones reales de `BattleSession.move`, `BattleSession.attack` y `BattleSession.purchase`, y de `BuildingProgressionV12` para mejorar instalaciones, comprar tecnología y aplicar la bonificación antiblindaje experimental. **No es la IA oficial**: usa una política determinista sencilla de acercarse a las ciudades, disparar cuando el ataque es legal y realizar compras con una estrategia fijada.
4. Las capturas requieren **dos finales de turno propios consecutivos** ocupando la ciudad con la misma unidad de infantería. La fase intermedia del enemigo **no borra** el progreso; la pérdida de ocupación o el cambio de capturador sí lo interrumpen. El mapa de propiedad incluye las cuatro ciudades oficiales y las adicionales; después de `Session.end_turn` se reconcilian los dueños de las cuatro ciudades oficiales, que por defecto el motor habría capturado instantáneamente.
5. Cuando empieza el turno del siguiente bando, el modelo **sustituye** el ingreso estándar ya concedido por `BattleSession.end_turn` por el ingreso total de las ciudades que controla en el registro. Por ejemplo, en 12 ciudades son **3 × 83 = 249** créditos por bando inicial, no 249 + 250 ni 3 × 250.
6. La experiencia es externa al estado comercial y se gana en eventos simulados: impacto **+9 XP**, eliminación adicional **+12 XP**, contraataque con daño **+5 XP**, captura completa **+15 XP**. Esas tasas son hipótesis de balance, no umbrales oficiales aprobados; los rangos usan los umbrales 15/40/80 ya contemplados. Solo se suben las estadísticas propias del perfil y rango de la unidad; no hay buffs generales ocultos ni mejora automática del tanque por evolucionar su fábrica.
7. Cada compra y ascenso de planta sigue los costos experimentales de `BuildingProgressionV12`. La primera estrategia intenta **producción económica** de APC; la segunda intenta **ascender planta, fabricar tanque, comprar nivel III y tecnología antiblindaje y producir Rompedores**. El uso de un único turno de producción por instalación se mantiene y se aplican costos reales.

## Qué se compara y qué no

El ensayo **`tests/test_integrated_strategy_pairs_v16.gd`** ejecuta, cuando apruebe, cuatro variantes por tamaño de economía: iniciador 0/1 × estrategia económica del lado 0 o del lado 1 × terrenos campo abierto/bosque. Son **8 pares espejo, 16 partidas**, de hasta **28 medias fases** en un mapa de 24×18. Los dos regímenes son 4 y 12 ciudades.

Se miden **capturas, interrupciones, ataques, daños, bajas, promociones, unidades fabricadas, ascensos de fábrica, tecnologías compradas, gastos, créditos cobrados, dinero final y victorias reales**. Una partida que llegue al límite sin vencedor se registra como *censurada* y no se presenta como empate definitivo o victoria. La política es **heurística determinista**, no un rival humano ni la IA comercial optimizada.

**`tests/test_integrated_balance_rules_v16.gd`** verifica independientemente:
- Saldo inicial de **2500 créditos** por facción y cobro de **250/249/248** en economías de 4/12/16 sin duplicación de ingresos.
- Que las ciudades adicionales no entran en el estado autoritativo inválido, mientras que el estado base sigue satisfaciendo `UrbanEconomy.valid` y su guardado actual puede hacer un ida/vuelta sin extender formato.
- Que una ciudad neutral **solo cambia de propietario después de dos turnos propios** consecutivos en el laboratorio, y su ingreso adicional se recibe al siguiente turno apropiado.
- Que una captura concede XP a una unidad concreta y activa la subida Regular (15 XP) sin subir gratis todas las unidades del ejército.
- Que la planta de blindados exige **650 + 1050 + 450 créditos** para nivel III y tecnología antiblindaje, y que el ataque +2 contra un tanque se aplica solo a la facción que la compró, conservando el ataque base de Rompedor al acabar.

Las dos suites tienen workflows independientes bajo `.github/workflows/integrated-balance-v16.yml`. **Hasta que Godot marque PASS, sus resultados no se deben declarar probados.**

## Limitaciones graves antes de activar el prototipo en Android

- El **registro de ciudades**, progreso de captura, estadísticas de XP y niveles de fábricas sigue fuera del formato de `SaveCodec`; el archivo guardado comercial **NO** conserva todo el estado experimental, aunque el `state` base sea válido y pueda serializarse.
- La **IA oficial** solo ve cuatro ciudades, 250 por ciudad y producción sin rangos; por eso el orquestador utiliza una política de laboratorio. Una integración real necesita migración de `MAX_SITES`, ingreso por ciudad en `UrbanEconomy`, IA, HUD de ciudades, XP y tecnologías.
- Las ganancias XP por impactos, bajas, capturas y contraataques son supuestos arbitrarios que requieren análisis de explotación (farmear ataques, retiradas, curaciones, XP de unidades de apoyo). En el experimento las unidades consumibles no ganan XP.
- El sistema de captura progresiva investigado antes en PR #394 tiene reglas y umbrales distintos; **las dos fases propias aquí son un aislado experimental simplificado**, no una integración aprobada de ambas implementaciones. Se debe decidir un único mecanismo antes de producción.
- Las partidas solo son **1 contra 1**. El requisito futuro de 8 jugadores no puede afirmarse resuelto con esta simulación.
- Cualquier victoria, duración o aumento de capturas se interpretará únicamente tras verificar el registro de la ejecución, y no prueba diversión de jugadores humanos ni equilibrio definitivo. Los supuestos costos de niveles I–III y tecnologías no están aprobados.

## Siguiente decisión basada en datos

Si pasan ambos grupos, examinar qué combinación de mapa 12/16 ciudades y progresión individual genera más objetivos contestados sin que una IA se quede sin fondos. Ampliar después a horizontes mayores, mapas de costa/puentes y variaciones de clima y niebla. Posteriormente migrar en una PR separada las reglas oficiales **solo si** las pruebas justifican la integración y se garantiza compatibilidad de partidas guardadas.
