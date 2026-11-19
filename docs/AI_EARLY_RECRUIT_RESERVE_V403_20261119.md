# TARVOKA v4.0.3 — Disciplina económica temprana en la IA (solo investigación)

**19 de noviembre de 2026. PR experimental, flag OFF. NO significa lanzamiento ni cambio de reglas comerciales.**

## Evidencia que motiva esta decisión

- [v4.0.0 CI 18/18](https://github.com/edwinrodri12/Tarvoka/actions/runs/44470015304): la política que compara ciudades, reclutamiento y relés obtuvo 16/16 victorias primer/segundo en autopartidas de 32 condiciones, pero eso **no prueba que sea más fuerte que la IA oficial**.
- [v4.0.1 CI 18/18](https://github.com/edwinrodri12/Tarvoka/actions/runs/44471224226): en **64 partidas originales directas** v400 perdió 28–36 frente a la IA oficial. Iniciando ganó **8/32**, respondiendo **20/32**, con niebla OFF 12/32 y ON 16/32; margen total de puntos de relé **−30**. Por eso el flag v400 sigue OFF.
- [v4.0.2 CI 18/18](https://github.com/edwinrodri12/Tarvoka/actions/runs/44588858115): 64 auditorías originales y 64 espejos exactos de las primeras ocho fases, con asignaciones de política intercambiadas. **En niebla ON, 16/16 pares** tuvieron las mismas primeras decisiones y estados observados hasta fase8. **Sin niebla, 16/16 pares** cambiaron el orden de las tres acciones iniciales, pero el mismo conjunto de acciones; la primera diferencia económica aparece al comenzar la fase 2, segundo turno del iniciador. En esas 16 condiciones v400 gasta **950 créditos** en nuevas tropas durante fase2 (Piercer300 + SPG650), mientras la IA oficial gasta **550**; gasto adicional **400 por comparación**. No se observó una ventaja equivalente de ingreso urbano en esa etapa. La auditoría no prueba causalidad ni permite modificar el precio de las unidades.
- Los resultados v4.0.2 señalan la **apertura sin niebla como escenario específico de gasto excesivo**; no justifican darle unidades gratis al primero, alterar el límite de tres órdenes, ni reducir precios arbitrariamente.

## Hipótesis a falsar

¿Puede v400 vencer con mayor frecuencia si, durante **las dos primeras oportunidades de turno de cada jugador**, evita comprar una unidad que dejaría su tesorería por debajo de una **reserva de liquidez basada en ciudades propias**, salvo que ya haya peligro cercano visible?

Esta es una hipótesis de **estrategia económica**, NO una modificación a economía real. Los créditos, costos, ingreso de ciudades, posición inicial y reglas de producción permanecen idénticos. La reserva de 7 ciclos **no está optimizada ni aprobada**: es una candidata concreta y reproducible para medir sensibilidad. Si empeora resultados, se descarta.

## Implementación opt-in

Nueva pieza pura `scripts/core/RecruitReserveV403.gd` (sin variables globales ni estado persistente) y flag `_ab_recruit_reserve_v403=true` en `BasicAI.gd`.

- **Solo en los cuatro primeros medios turnos de la partida** (fases globales 0,1,2,3), aplica por igual al bando que comienza y al que responde, cuando el motor considere reclutamiento.
- Obtiene la **tesorería real de la propia facción** (no la enemiga) y calcula su **ingreso por ciudades ya poseídas y observables**, con `UrbanEconomy.income_for`. La política establece `reserva = 7 × ingresos actuales por turno`. En los mapas modernos de la prueba con una ciudad inicial, 7×250 = **1750 créditos**.
- Examina un pedido de compra que **ya es válido según la IA y el motor** y pregunta si `saldo actual − costo real de unidad < reserva`. Si lo es, y no hay amenaza cercana observada, **aplaza esa compra**, sin dar reembolso, dinero ni órdenes nuevas.
- Mantiene prioridad de defensa cuando un **enemigo realmente visible** se encuentra a cuatro casillas o menos (distancia Manhattan) de alguna unidad aliada viva o ciudad propia conocida. La IA no inspecciona unidades invisibles, finanzas del adversario ni casillas secretas.
- Si la producción queda aplazada durante el arbitraje v400, prioriza la alternativa **legal** ya calculada para una ciudad; si no, avanza hacia un relé por un movimiento `Session.move` legítimo. En el reclutamiento de reserva normal también rechaza la misma compra e intenta una acción restante de objetivo. No se inventa que un simple avance capture ya un relé.
- Al terminar los cuatro primeros medios turnos o si la facción ha perdido sus ciudades, **cede control a la política v400 anterior**, sin alterar el algoritmo productivo del juego.
- No es un bloqueo permanente a producir una clase particular: aplica igual a cualquier unidad según **su precio real y la tesorería**. El motor `Economy.can_purchase` sigue siendo la autoridad legal. Un jugador humano nunca queda sometido a esta reserva; es una decisión experimental de la IA.

**Compatibilidad estricta:** si el flag `_ab_recruit_reserve_v403` está ausente o vale false, todos los estados y acciones v400 siguen siendo byte por byte iguales. Tampoco cambia el valor por defecto de v398/v399/v400.

## Prueba de microcontrato Godot

`tests/test_ai_recruit_reserve_micro_v403.gd` exige:

1. Ambos bandos: con 2200 créditos y una ciudad propia de 250/turno, una compra legal SPG650 dejaría **1550**, inferior a **1750**; debe aplazarse. Un refuerzo de 200 que deja 2000 debe aprobarse.
2. Si no hay ingreso urbano propio o ya se superaron los cuatro primeros medios turnos, no imponer reserva.
3. Si hay un enemigo **visible** a distancia de peligro, la compra se permite; si el enemigo no está en el estado observado, no se inventa esa amenaza.
4. Sobre el caso real de semilla **698 sin niebla** (ya conocido en el estudio v402): tras el Piercer de 300 de fase2, el siguiente paso de v400 era SPG650. La nueva política debe evitar **ese** gasto prematuro y dar un movimiento o compra distinta, manteniendo el estado anterior inmutable.
5. Con flag false, v400 produce el mismo estado; con flag true, la acción y el estado siguen siendo válidos, y reflejar horizontalmente la batalla con colores intercambiados produce exactamente la misma decisión.

## Enfrentamientos directos nuevos

No se reutilizan las semillas ya estudiadas. **8 semillas nuevas 706–713**, dos por plantilla (abierto, bosque, doble puente, costa), niebla ON/OFF, ambas identidades como iniciadores, ambos bandos como IA candidata, y dos rivales distintos:

- **v403 con reserva contra la IA oficial** sin flags experimentales, para saber si realmente mejora frente a la referencia comercial.
- **v403 con reserva contra v400 sin reserva**, para medir el cambio concreto frente a la política que perdió 28–36 en v401.

Cada rival recibe **64 partidas originales directas**: 8 ×2 nieblas×2 iniciadores×2 bandos. Total **128 partidas originales y 128 reflejos exactos = 256 ejecuciones**, pero los reflejos son pruebas de paridad, NO 128 muestras independientes adicionales. Los mapas de una misma semilla se correlacionan: **64 comparaciones por rival** es el denominador principal.

Máximo 36 medios turnos como en v401. Los resultados sin vencedor se marcan **censurados**, jamás empates inventados ni victorias asignadas por omisión.

El informe estricto incluye ganador por rival, balance con IA candidata iniciando/respondiente, niebla ON/OFF, cuatro terrenos, márgenes de relés, tesorería final, duración, compras totales y censuras. No basta ganar un único mapa ni jugar bien solo como segundo.

## Umbral de aprobación

- Microtest, 16 shards Godot y agregador deben aprobar.
- Verificar que v403 supera robustamente v400 **y** no perjudica contra la IA oficial bajo niebla ni por mapa e iniciativa. En caso contrario, se revisa o descarta la hipótesis.
- No habilitar cambios productivos por anticipado, ni fusionar un DRAFT a `main`, ni construir la APK a partir de experimentos inconclusos. Si la reserva sirve en ciertos mapas pero no en otros, la siguiente prioridad es modelar oportunidades por terreno, no conceder una ventaja de reglas.

Esta PR experimental se apila directamente sobre [#623 v4.0.2](https://github.com/edwinrodri12/Tarvoka/pull/623), ya validada CI18/18, y solo incluye un pequeño módulo opt-in de decisiones más test/CI/docs.
