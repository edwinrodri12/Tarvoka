# TARVOKA — v3.6.7: cuarta orden de apertura condicionada (solo investigación)

**17 de noviembre de 2026, Atlanta; fecha UTC de ejecución: 18/11.** No modifica `main`, APK, `OpeningBalance.gd` ni las partidas guardadas.

## Resultado previo y error técnico corregido

La [batería v3.6.6 de 128 partidas](https://github.com/edwinrodri12/Tarvoka/actions/runs/44215654610) ejecutó todas las batallas y pasó los 9 trabajos de Godot; el agregador calculó las métricas pero falló después por un **nombre de archivo desalineado** entre el informe generado (`ai_v366_opening_limits.md`) y el workflow (`ai_v366_opening_budgets.md`). Se corrigió en `tests/aggregate_ai_opening_budget_v366.py`. La [repetición](https://github.com/edwinrodri12/Tarvoka/actions/runs/44218134511) finalizó completamente en verde.

| Primer turno | Victorias primer bando | Segundo bando | Azul | Rojo |
|---|---:|---:|---:|---:|
| 3 órdenes oficiales | 8/32 | 24/32 | 16 | 16 |
| 4 órdenes experimentales | 24/32 | 8/32 | 20 | 12 |
| 5 órdenes experimentales | 26/32 | 6/32 | 18 | 14 |
| Sin límite | 26/32 | 6/32 | 22 | 10 |

En **Campo abierto**, con 3 órdenes ganó primero **0/16**, con cuatro **12/16**. En **Puentes de la Cuenca**, ganó primero 8/16 con tres y 12/16 con cuatro. Una sola orden ofensiva adicional parece demasiado poderosa para ambos mapas en la muestra reducida.

## Nueva hipótesis: una cuarta orden no ofensiva, solo si la IA ya la propone

No se inventan atributos, armas, descuentos ni bonificaciones. Se utiliza la recomendación **real de `BasicAI.step`** para la cuarta orden, sin buscar una acción alternativa si se rechaza:

- **`3`**: regla oficial de tres órdenes, creada con `balanced_opening=true`.
- **`4`**: cuatro órdenes legales sin restricción de tipo, como control experimental.
- **`3plus_move`**: tres órdenes completas; una cuarta **solo si** la siguiente acción que la IA ya quería realizar era `move`. No se permiten ataques, compras ni suministros como cuarta orden.
- **`3plus_support`**: tres órdenes completas; cuarta acción solo si `BasicAI` propuso `move`, `produce` o `resupply`. Se prohíbe `attack` como cuarta orden.

**Importante:** mover una unidad puede facilitar una captura al finalizar el turno, y comprar una unidad puede conferir ventaja estratégica. Por eso «no ofensiva» en este experimento significa **no ejecutar directamente una acción `attack`**; no significa que esa acción carezca de efecto competitivo.

Las restricciones `3plus_move` y `3plus_support` están implementadas en **`tests/OpeningBonusPolicyV367.gd`**, no en el motor ni en la UI. El `BattleSession` de juego permite sus acciones legales, pero el *programa de pruebas* termina la primera fase después de tres o cuatro órdenes según la recomendación y su categoría. No agrega ni almacena `opening.limit=4`, valor actualmente prohibido por las reglas de guardado.

## Batería de control y reglas de aceptación

**128 partidas originales reales**, 32 por condición: dos terrenos, niveles 10/12, niebla con/sin, ambos bandos iniciales y dos políticas idénticas en cada partida (v3.5 contra v3.5 y v3.6.3 contra v3.6.3).

En todos los grupos son constantes: dos relés reflejados al sur (4,5) y (5,5), la puntuación por ronda completa, cinco unidades por facción, economía, combate y logística. El *harness* anota:
- Las **primeras tres decisiones completas** de la IA como secuencia reproducible. El agregador rechaza el ensayo si los cuatro tratamientos no tienen **la misma secuencia inicial** dentro de cada combinación de mapa, niebla, nivel, facción y política.
- La recomendación de cuarta acción, si efectivamente fue autorizada como bonus, si fue ataque/movimiento/producción/suministro y cuántas acciones reales se ejecutaron.
- Victorias del primero/segundo, azul/rojo, por mapa/versión, tipo de victoria, capturas y retiradas.

**Controles obligatorios:** el grupo `3` debe repetir exactamente 8/32 victorias del primer jugador y 16/32 del azul; el grupo `4` debe repetir 24/32 del primer jugador y 20/32 del azul. El agregador verifica 128 combinaciones únicas, sin asumir resultados que no estén en los logs.

Un contrato Godot prueba la política pura (el bonus de movimiento jamás admite ataque, y el bonus de apoyo tampoco) y que, usando movimientos oficiales, el motor **continúa bloqueando la cuarta acción** después de tres órdenes legales. Los cuatro movimientos de control solo son posibles en un estado de pruebas inicializado sin apertura oficial.

## Interpretación y límite de este paso

El experimento **no autoriza integrar** esta mecánica. Si ambos bonus se quedan siempre en tres órdenes o siempre dan una cuarta, habrá que investigar el tipo concreto de decisión en esa fase. Si alguno reduce tanto sesgo de iniciativa como de color, se diseñará una implementación futura completamente opt-in y compatible con guardados, sujeta a otros mapas, composiciones modernas, pruebas Android y usuarios reales.

PR DRAFT; no modificación de código de producción, lanzamiento ni APK.


## RESULTADO VERIFICADO — CI en verde

[128 partidas y contratos v3.6.7, GitHub Actions #44218514038](https://github.com/edwinrodri12/Tarvoka/actions/runs/44218514038): **10/10 trabajos correctos** (ocho grupos de 16 partidas, contrato de motor y agregación). El agregador verificó **128 registros de partidas únicas**, **512 comprobaciones de equivalencia de las primeras tres órdenes**, reproducibilidad exacta de cap3 y cap4, y cero partidas inconclusas.

| Régimen probado | Primero gana | Segundo gana | Azul / Rojo | Cuarta adicional concedida |
|---|---:|---:|---:|---:|
| 3 órdenes reales | 8/32 | 24/32 | 16 / 16 | 0 |
| 4 órdenes de prueba | 24/32 | 8/32 | 20 / 12 | 32 órdenes, cuarta sin restricción |
| 3 + cuarto movimiento | 24/32 | 8/32 | 20 / 12 | 32/32 |
| 3 + cuarto apoyo | 24/32 | 8/32 | 20 / 12 | 32/32 |

**Observación determinante:** en los **32 inicios cruzados**, la cuarta decisión de la IA era `move` **en todos los casos**. Por ello los filtros `3plus_move` y `3plus_support` aceptaron la cuarta orden siempre. Son experimentos **operativamente idénticos a cap4 en esta matriz**, no una mejora del equilibrio. No hay evidencia para aprobar ninguno.

Los controles de cuatro acciones también siguieron favoreciendo al primero en **Campo abierto 12/16** y **Puentes 12/16**. El equilibrio por color del cap3 es mejor que el de las opciones de cuatro órdenes. No ampliar `OpeningBalance.MAX_FIRST_ORDERS` ni alterar juego, APK o guardados con esta evidencia.

**Próxima hipótesis fundamentada:** el exceso de ventaja no lo causa directamente la clase `attack` de la cuarta acción, sino **a qué casilla y con qué objetivo se mueve una unidad**. Antes de proponer una regla comercial, instrumentar `unit_id`, motivo del movimiento, destino, distancia al objetivo y si captura relé/ciudad al finalizar turno, y estudiar un cuarto desplazamiento solo de despliegue (sin otorgar captura inmediata), aislándolo del control cap3/cap4.

