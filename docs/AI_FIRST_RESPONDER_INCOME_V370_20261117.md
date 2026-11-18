# TARVOKA v3.7.0 — auditoría del ingreso inicial del segundo jugador

**17 de noviembre de 2026 (hora de Atlanta).** Este cambio pertenece únicamente a una rama de pruebas; no modifica `main`, la APK, los guardados ni las reglas de producción.

## Observación del usuario y verificación del código

El usuario señaló una posible ventaja del jugador que responde: **cobra ingresos de ciudades cuando empieza su primer turno**, antes de que el jugador que inició tenga un ingreso equivalente.

Se verificó directamente en el código vigente:
- `scripts/core/UrbanEconomy.gd` define `START_CREDITS=300`, `CITY_INCOME=100`, y una ciudad inicial de cada facción.
- `BattleSession.start` crea la economía inicial y asigna créditos iguales a ambas facciones, sin llamar a `UrbanEconomy.begin_turn` para quien juega primero.
- `BattleSession.end_turn` pasa al oponente y llama a `Economy.begin_turn`. Por ello quien juega **segundo** pasa de 300 a **400 créditos antes de su primera acción**. Quien inicia conserva sus 300 créditos durante su primera fase y cobra al empezar su segunda fase.

Esto **es una asimetría económica verificable**, pero todavía no demuestra que sea la causa principal de la diferencia de victorias: hay efectos de relés, terreno, economía y reglas de apertura que interactúan.

## Experimento aislado: mantener vs eliminar únicamente el primer pago

`tests/FirstReplyIncomeV370.gd` usa exactamente el `BattleSession.end_turn` original para realizar la transición inicial y comprobar el pago legal. En la variante `skip`, **resta exactamente el ingreso de ciudad recién acreditado al segundo jugador** durante la primera transición, dejando intactos todos los demás campos. El modo `keep` es el control original.

No se elimina la ciudad del segundo jugador, ni se reduce su renta futura, ni se alteran las capturas, la IA, los créditos iniciales, las compras o el motor. El jugador que empieza cobra con normalidad al iniciar su siguiente turno; el segundo también cobra normalmente desde su segundo turno.

## Batería completa

**256 partidas reales de Godot 4.3 = 128 parejas comparables**, combinando:
- Cuatro mapas prototipo: 0 (Campo abierto), 1 (Bosque de las Dos Rutas), 2 (Puentes de la Cuenca), 3 (Costa de las Dos Bahías).
- Niebla sí/no, niveles de IA 10/12, dos iniciadores alternados y dos políticas autocontroladas (v3.5-v3.5 y v3.6.3-v3.6.3).
- Dos aperturas: 3 órdenes (límite original de producción) y 4 órdenes (límite experimental del programa de pruebas).
- Dos variantes económicas: `keep` (ingreso original al segundo jugador, 400 créditos) y `skip` (no conceder ese primer ingreso, 300 créditos).

El conjunto sigue empleando dos relés **simétricos al sur**, (4,5) y (5,5), y puntuación al final de la ronda completa. La comparación entre ingresos se hace dentro de cada combinación estrictamente idéntica.

`tests/test_ai_responder_income_v370.gd` registra el pago original, el importe eliminado, el crédito disponible en el primer turno de respuesta, las tres primeras acciones, capturas, compras y resultados. `tests/test_ai_first_income_contract_v370.gd` prueba 32 transiciones reales (4 mapas × 2 condiciones de niebla × 2 bandos iniciales × 2 variantes de ingreso) y asegura que el pago de la **segunda ronda** de ambos bandos sigue funcionando.

`tests/aggregate_ai_first_income_v370.py` exige 256 partidas únicas, 256 comparaciones de secuencias iniciales idénticas y 128 pares de ingresos controlados; también comprueba que las dos configuraciones históricas `cap3` y `cap4` en los mapas 0/2 con ingreso original **reproducen** los resultados de v3.6.9: 8/32 victorias del primero con 3 órdenes, y 24/32 con 4.

## Criterios de decisión

Primero verificar legalidad, ausencia de errores, 100 créditos eliminados **una sola vez**, todos los ingresos posteriores y todas las parejas de datos. Después interpretar cambios de ganador y de compras del segundo bando, separados por apertura, facción, mapa y nivel.

Si quitar el pago inicial reduce de manera consistente la ventaja del segundo y no genera una nueva ventaja sistemática del primero, se considerará una **implementación jugable opt-in** con contratos de guardado, UI y regresiones en otra rama. Si no cambia resultados, no se atribuirá causalidad al mero pago.

Ningún resultado de dos IA contra sí mismas en mapas 10x8 autoriza por sí solo fusionar o lanzar una APK nueva; faltan pruebas humanas, mapas grandes y partidas modernas.

**PR DRAFT. Solo tests/docs/workflow.**


## Resultado observado — auditoría completa

La [ejecución #44226290001](https://github.com/edwinrodri12/Tarvoka/actions/runs/44226290001) terminó con **18 trabajos en verde** (16 grupos de 16 partidas, contrato y agregación). Se validaron **256 partidas reales**, 128 parejas de `keep` vs `skip` y 256 comprobaciones de las primeras tres decisiones.

| Apertura | Ingreso inicial adicional del segundo | Partidas | Primero gana | Segundo gana | Azul / Rojo |
|---|---|---:|---:|---:|---:|
| 3 órdenes | Sí (+100) | 64 | 22 | 42 | 30 / 34 |
| 3 órdenes | No | 64 | 22 | 42 | 30 / 34 |
| 4 órdenes (laboratorio) | Sí (+100) | 64 | 32 | 32 | 36 / 28 |
| 4 órdenes (laboratorio) | No | 64 | 32 | 32 | 36 / 28 |

**Eliminación del primer pago:** cero cambios de ganador en **128 parejas** de escenarios. Cuatro parejas tuvieron cambios en compras del segundo jugador, por un saldo agregado de **cuatro compras menos** en el grupo sin ingreso; cero parejas modificaron las capturas del segundo. Ambas referencias anteriores de los mapas 0 y 2 se reprodujeron exactamente. El estudio confirma que el **desfase económico existe**, pero **no respalda que sea la causa de la ventaja de iniciativa** en estos mapas y estas dos políticas de IA.

Se preparó además la [implementación opcional de prueba PR #573](https://github.com/edwinrodri12/Tarvoka/pull/573), desactivada por defecto y separada de la APK oficial. No se fusionó automáticamente con la rama principal.
