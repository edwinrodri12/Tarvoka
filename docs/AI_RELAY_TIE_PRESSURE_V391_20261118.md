# TARVOKA v3.9.1 — Presión táctica sobre relés en empate (solo prueba opt-in)

**18 de noviembre de 2026 — experimento de IA reversible, sin alterar reglas, puntuación ni APK.**

## Qué aprendimos de las versiones anteriores

- [v3.8.8: 18/18 trabajos](https://github.com/edwinrodri12/Tarvoka/actions/runs/44373996589): en 8 semillas nuevas 40×30, la apertura oficial ganó el iniciador 12/32 vs 10/32 con la respuesta limitada a cinco órdenes (dos casos censurados al medio turno 32). **Cap5 no mejoró el balance**.
- [v3.9.0: 3/3 trabajos](https://github.com/edwinrodri12/Tarvoka/actions/runs/44378941560): en el único mapa censurado (semilla 636 con niebla), ambas variantes cap5 produjeron 9–9 tras medio turno 32. Ambos bandos controlaban un relé cada uno desde 5–5 en la ronda 12 hasta 9–9 en la ronda 16. El respondedor arrebató un relé real en ronda 17 y ganó 11–9 al medio turno 34, para ambas identidades de iniciador. **No hubo error de contabilidad, bloqueo permanente ni motivo para forzar un empate.**

## Hallazgo del código AI

`BasicAI._advance_relay` sirve para acercar unidades de tierra a relés no propios. Actualmente se invoca **después** de buscar capturas urbanas y producir refuerzos, incluso cuando ambos puntajes públicos ya alcanzaron el objetivo y están empatados. En una situación así, tomar un relé rival visible podría resolver la partida; seguir comprando unidades/capturando instalaciones no necesariamente lo hace.

## Cambio experimental v3.9.1

En `scripts/core/BasicAI.gd` se añade la opción **`_ab_relay_tie_pressure_v391`**, **desactivada por defecto**, y nada más se reordena en la IA normal.

Cuando la opción está activada, la IA solo anticipa una ruta de captura de relé ANTES de ciudades y producción si se cumplen **todas** estas condiciones:

1. Existe `round_scoring`, y las puntuaciones públicas de las dos facciones son exactamente iguales y **mayores o iguales** al objetivo de señal.
2. Hay al menos **un relé contrario conocido y visible**, con `owner == opponent` en `Visibility.observed_state`. Los nodos fuera de visión reciben `owner=-2` y nunca se reclasifican como enemigos.
3. Existe un movimiento real, legal y alcanzable de una unidad terrestre hacia ese relé. La IA no fuerza capturas, no cambia distancias ni ignora ocupación.
4. Ninguna unidad seleccionada para la incursión ocupa ya un relé aliado que deba defenderse. Ataques letales, retiradas por supervivencia, reabastecimiento y defensa inmediata de relé conservan prioridad.

Si no se puede efectuar un movimiento legal, el juego usa toda la secuencia de decisiones original. La decisión final es un `BattleSession.move` autoritativo. El indicador `reason=relay_tie_pressure` solo describe la táctica, no modifica el estado.

## Validación con motor real

`tests/test_ai_relay_tie_pressure_v391.gd` contiene dos niveles de prueba:

- **Micro (rápida):** requisitos del marcador, modo de puntuación por ronda, niebla ocultando propiedad enemiga, movimiento realmente legal de acercamiento y no abandonar un guardia de relé propio.
- **Partidas largas:** semilla 636, niebla sí, ambos iniciadores (0 y 1), apertura test cap5 (primero 3, segundo 5), horizonte 64. Cada situación se reproduce **cuatro veces**: control original y control espejo, opción nueva original y opción nueva espejo. Total **8 partidas autoritativas** pero solo **2 situaciones originales por política**; espejos no aumentan el tamaño de muestra. Compara igualdad exacta de acciones y estados del espejo, ganador, marcador, duración, ataques, compras y el primer momento de diferencia entre políticas.

Para permitir ese estudio sin alterar los demás, `Matched._play_equal_response` acepta un argumento final opcional `experimental_options={}`; si está vacío, la configuración de IA y todo el comportamiento anterior se preservan.

El agregador Python exige dos iniciadores y no permite alegar una mejora general partiendo de un solo mapa. Si la opción no cambia nada o empeora la partida, ese resultado también se documenta.

## Decisiones pendientes

**No habilitar esta opción en producción por pasar una única prueba**. Si mejora la captura sin filtración de niebla o regresiones, extender el experimento a **más semillas, 24×18, distintos terrenos y estilos de IA**, y medir también si destruye innecesariamente una defensa existente. Si el efecto es perjudicial, descartarlo o reformularlo.

**PR DRAFT basado en #599, sin fusión a main, sin APK ni cambios de reglas de apertura, ingreso, combat, recursos, objetivo de relés o puntuación.**
