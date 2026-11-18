# TARVOKA — Investigación de apertura intermedia v3.6.6

**Solo pruebas experimentales. No se cambian las reglas jugables, estadísticas, IA, edificios, `main` ni la APK.**

## Resultado confirmado de v3.6.5

La [comparación de 96 partidas reales](https://github.com/edwinrodri12/Tarvoka/actions/runs/44213791260) completó 10 trabajos de GitHub Actions correctamente y reprodujo la referencia de 3 órdenes.

| Apertura primer jugador | Primero gana | Segundo gana | Azul gana | Rojo gana |
|---|---:|---:|---:|---:|
| 2 órdenes (válido en motor) | 4/32 | 28/32 | 12/32 | 20/32 |
| **3 órdenes, regla vigente** | 8/32 | 24/32 | 16/32 | 16/32 |
| Sin límite, modo heredado | 26/32 | 6/32 | 22/32 | 10/32 |

Todos los encuentros emplearon los mismos **dos relés reflejados al sur**, capturas y puntuación al finalizar cada ronda completa, nivel 10/12, mapas 0/2 y niebla sí/no. La apertura de tres órdenes sigue siendo la menos sesgada de las tres variantes, pero favorece aún al segundo jugador.

## Nueva hipótesis: 4 o 5 acciones iniciales

Las reglas actuales en `OpeningBalance.gd` **solo permiten límites de hasta tres acciones**. Por eso **no se modifica `OpeningBalance.gd` ni se inserta un límite 4/5 en el estado del motor**.

En este experimento se usa el `BattleSession` original, que permite ejecutar movimientos, ataques y compras reales. Para los casos de 4 y 5 acciones, **el programa de pruebas deja de enviar nuevas órdenes legales al terminar la cuarta o quinta orden exitosa del primer turno** y llama a `Session.end_turn`. No se alteran las acciones, sus resultados ni las reglas para las fases siguientes. Esta aproximación permite estudiar el equilibrio de una futura regla sin implementarla prematuramente.

Se comparan cuatro condiciones:

1. **3 órdenes:** límite real del motor, tal como está hoy.
2. **4 órdenes:** presupuesto del programa de pruebas; sin campo `opening` persistente.
3. **5 órdenes:** presupuesto del programa de pruebas; sin campo `opening` persistente.
4. **Sin límite:** modo heredado sin restricción y sin campo `opening`.

## Pruebas

**128 partidas completas de control**, 32 por condición, con la misma IA en ambos bandos y cambios de quién juega primero: dos políticas (v3.5 y v3.6.3), dos mapas, niebla activa/inactiva, nivel 10/12 y los dos lados iniciales.

- `tests/test_ai_opening_budget_v366.gd`: partidas reales con `AI.step`, `BattleSession.move`, ataques y fin de turno. El estado fuente nunca se muta, y las acciones pasan los validadores normales.
- `tests/test_ai_opening_budget_contract_v366.gd`: comprueba ocho configuraciones de inicio, el límite real de tres, los 4/5 movimientos reales legales, la **ausencia de un límite 4/5 en el motor**, guardado y economía sin cambios.
- `tests/aggregate_ai_opening_budget_v366.py`: exige exactamente 128 partidas únicas, sin datos fabricados; separa sesgo de iniciativa, de color, mapas, política y forma de victoria.
- Control de reproducibilidad **obligatorio**: 3 órdenes debe repetir primero 8/32, azul 16/32; sin límite debe repetir primero 26/32 y azul 22/32. Si no, el informe falla y no hay conclusión válida.
- Los resultados son de mapas prototipo y IA vs sí misma. No justifican todavía una regla comercial ni sustituyen QA en Android y personas.

La CI es `.github/workflows/ai-opening-budgets-v366.yml`, el PR permanece **DRAFT** y ningún resultado autoriza fusionar automáticamente.

**Decisión futura:** si 4 o 5 acciones reducen de forma reproducible las diferencias de iniciativa sin introducir una ventaja de color, preparar **una implementación opt-in de reglas realmente compatible con guardados** y ampliarla a otros mapas, composiciones aéreas/navales y semilla de terreno; si ninguno es equilibrado, investigar la condición de victoria por relés antes de cambiar el motor.
