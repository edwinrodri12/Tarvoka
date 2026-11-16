# TARVOKA — Auditoría del sistema de captura y experimento A/B

**15 de noviembre de 2026 · Prototipo de diagnóstico, no integrado al juego**

## Diagnóstico del código real en `main`

La ruta real es `BattleSession.end_turn → UrbanEconomy.finish_turn → inicio de turno enemigo y UrbanEconomy.begin_turn`.

- `UrbanEconomy.finish_turn` cambia la propiedad **inmediatamente en el mismo final de turno** cuando una infantería válida está situada en el centro de una instalación.
- Se conquistan **ciudades y productores militares**, no solo ciudades, y ambos tipos se convierten en una sola fase.
- Capturan `line` (Guardia), `scout` (Rastreador), `assault` (Asaltante) y `engineer` (Ingeniero). `piercer` (Rompedor) **aún no**, aunque la [PR #156](https://github.com/edwinrodri12/Tarvoka/pull/156) pretende corregirlo.
- No pueden capturar `bulwark` (Baluarte), `artillery` (Lanzador), ni vehículos, aeronaves y barcos. La política «solo infantería» **debe explicitar cuáles especializaciones** pueden tomar un objetivo, no implicar que todas lo hagan.
- La captura no consume una orden adicional después de ocupar la casilla; en particular una unidad puede moverse y atacar el mismo turno si las reglas permiten ambas acciones.
- Cada ciudad moderna produce **250 créditos por turno propio** del dueño. Un Rastreador cuesta **150**, mueve 4 y ve 5. La ciudad recién tomada da su renta al volver a comenzar el turno propio, y no paga antes.
- En niebla, `Visibility.observed_state` enmascara dueños no visibles; un progreso de captura nuevo deberá ocultarse igual para el adversario.
- El juego `SaveCodec.VERSION=1` **no contiene progreso de captura**. Integrarlo de forma segura exige serializar y validar progreso, separar estado público/privado, mostrar HUD y asegurar que una partida guardada a media conquista se reanude sin reinicios explotables.
- `BasicAI._capture_urban_site` considera la propiedad actual, pero no sabe evaluar progreso, amenaza de contracaptura, cercanía de aliados o un bloqueo de ingresos; deberá adaptarse antes de considerar comercial la prueba.

## Propuesta experimental v0.1

**No se alteran reglas activas, precios, habilidades de facción, balances, pantallas ni APK.** El adaptador `scripts/experiments/CaptureExperimentV01.gd` llama al **verdadero** `BattleSession.end_turn`, usa el estado devuelto por el motor y **solo dentro del experimento** aplaza la transferencia de propiedad. Mantiene contadores fuera del estado de la partida para no simular compatibilidad de guardado inexistente.

| Regla | Captura actual | Propuesta de prueba |
|---|---|---|
| Ciudad neutral o enemiga | Al final de un turno de ocupación | **4 puntos de ocupación, mínimo 2 turnos propios** |
| Fábrica / base militar | Al final del mismo turno | **3 puntos, mínimo 2 turnos propios** |
| Guardia | Conquista instantánea | 2 puntos/turno |
| Asaltante | Conquista instantánea | 2 puntos/turno |
| Rastreador | Conquista instantánea | 1 punto/turno |
| Ingeniero | Conquista instantánea | 1 punto/turno |
| Rompedor | No conquista en `main` | 1 punto/turno, siguiendo PR #156 como hipótesis |
| Baluarte y Lanzador | No conquistan | No conquistan |
| Compañeros | No aportan | **+1 punto por infantería aliada adyacente**, máximo +2; no pueden compartir casilla |
| Salud | Basta con estar vivo | Si la unidad que ocupa tiene **menos del 50 % de HP**, solo aporta 1 punto |
| Pérdida del ocupante | Se mantiene la propiedad actual | **Pierde todo el progreso** si muere, abandona la casilla o pierde su condición de capturador |
| Renta de ciudad atacada | Continúa para dueño hasta que cambia | **Renta pausada a partir de 2 puntos de ocupación**, sin pagar al atacante hasta terminar conquista; un Rastreador solitario con 1 punto NO puede congelar los ingresos |
| Instalación atacada | Sigue siendo del dueño hasta el cambio | **Producción congelada a partir de 2 puntos de ocupación**, sin crear una unidad dentro del enemigo |
| Niebla | No hay contador | El futuro contador NO debe filtrar progresos fuera del campo visual |

La regla de mínimo dos turnos impide que agrupar muchas tropas produzca una conquista instantánea. El objetivo es que **la velocidad y la exploración sigan teniendo valor**, pero que el Rastreador no sea automáticamente el mejor capturador por precio. El Asaltante y la Guardia completarían una ciudad neutral en dos turnos propios; el Rastreador solo necesitaría cuatro, o dos con un aliado junto a él.

**Restricción técnica:** se utiliza un contenedor externo `tracking` que **no se incluye en el guardado v1**. Por eso el test está autorizado a comparar reglas y simular una IA, pero este resultado **no es una modificación lista para publicarse**. La UI tendría que representar los puntos de conquista, el bando ocupante y el contestado, sin filtrar datos de niebla.

## Prueba de reglas y partidas

`tests/test_capture_experiment_v01.gd` mide en Godot:

- Capturas instantáneas **de verdad** de las cuatro infanterías autorizadas por `main`; rechazos de Rompedor, Baluarte, Lanzador, Tanque, Logística y dron FPV; captura real de fábrica enemiga; pago una única vez al comienzo del turno propio.
- Variante progresiva: tiempos de cinco roles, dos bandos, colaboración de uno o dos aliados, límite mínimo de dos turnos, salud dañada, progreso perdido al abandonar, ciudades enemigas en asedio con renta suspendida, fábricas sin nuevas órdenes y turnos intermedios sin pérdida de progreso.
- **16 parejas de partidas IA espejo**, 4 escenarios × ambos iniciadores × niebla sí/no; total **32 partidas**, hasta 20 medias fases cada una, incluyendo lluvia en puentes y nieve en bosque. Un lado se juega con captura instantánea real y el otro con adaptador progresivo, manteniendo sus demás reglas y `BasicAI` inalteradas. Comparan ingresos, dinero, cambios de propiedad y compras, **sin declarar tasas de victoria ni equivalencia con partida humana**.
- Los tests se guardan en su workflow dedicado; **no contar como éxito hasta que GitHub Actions confirme PASS**.

## Qué falta para una propuesta definitiva

1. Comparar **progreso en ciudad neutral frente a enemigo**: decidir si capturar una ciudad enemiga debe tomar más, igual o menos puntos y si la renta suspendida es la medida adecuada para no castigar demasiado al defensor.
2. **Reconstruir y probar la IA**: el planificador actual puede seguir intentando capturas instantáneas, mantener un Rastreador en un lugar inseguro o comprar demasiados Rastreadores aunque la captura sea progresiva.
3. Resolver casos de **captura de fábricas, unidades que entran en medio de captura, muerte y contraocupación, equipo aliado, visibilidad y turnos múltiples** de forma transaccional.
4. Cambiar `SaveCodec` y HUD con compatibilidad estricta de guardados: progreso no puede quedar como propiedad editable que produzca ciudades gratis al reiniciar.
5. Verificar con los PR pendientes: Rompedor que puede capturar (#156); reparaciones de Ingeniero (#320/#323), combate urbano de Asaltante (#384), transporte APC/IFV (#335/#339).
6. Repetir en mapas de 24×18 y 40×30 y en partidas más largas, diversas IA y jugadores reales. En especial, comprobar qué ocurre con una ciudad neutral de renta **250** en relación con el costo **150** del Rastreador y las distancias grandes.

**Recomendación provisional:** probar la captura progresiva con apoyo ortogonal y diferenciar el tiempo de conquista de la movilidad. **No fijar estos 4/3 puntos ni alterar precios hasta tener pruebas A/B suficientes.**
## Resultados medidos tras la salvaguarda anti-bloqueo económico

**Último ensayo verificado:** [GitHub Actions #43742373371 — SUCCESS](https://github.com/edwinrodri12/Tarvoka/actions/runs/43742373371). También pasaron las ejecuciones exploratorias #43742030346 y #43742270984; la versión final añade interrupción por muerte y el umbral de 2 puntos para negar ingresos. Son pruebas del **adaptador experimental**, no validación del juego comercial.

- **52 verificaciones de reglas**, incluyendo ocupante muerto, fuga, apoyo adyacente sin compartir casilla, capturas de fábrica y ciudad en ambos lados, 4 clases de capturadores actuales, 6 rechazos incluyendo Rompedor en `main`, habilitación hipotética de Rompedor, colaboración, bajo HP, pago después de conquista y límite anti-sabotaje temprano.
- **16 pares de partidas de IA = 32 sesiones**, con cuatro mapas, dos órdenes de turno y niebla activada o no; horizonte de 20 medias fases (~10 turnos propios por bando), misma BasicAI, calendario y ejército. No hubo victorias completas en esta ventana y, por tanto, **no se puede evaluar aún la tasa de victorias**.
- Cambios de propiedad **instantánea: 94**, **progresiva: 40** (reducción de **54/94 = 57,4 %**). Estos cambios suman **ciudades y edificios productores**, no solo ciudades.
- Compras de IA: **504** con captura instantánea y **487** en propuesta progresiva (17 compras menos, aproximadamente 3,4 % en esta ventana). **89 pasos parciales de progreso** y **3.500 créditos de rentas retenidas** por disputa acumulados entre las 16 partidas experimentales; **dos** oportunidades de producción militar congeladas por sitios disputados.
- El experimento original, que congelaba rentas apenas entraba cualquier soldado, había retenido **6.000 créditos**. Eso podía incentivar un sabotaje inmediato de 250 créditos por turno con un Rastreador de 150. Se corrigió: **solo hay negación de renta cuando el progreso alcanza 2 puntos**. En la prueba, el Rastreador solitario con solo 1 punto **no niega los 250 créditos del dueño**.
- La IA de base **no está entrenada ni programada para apoyar asedios**: por ello, que la progresión reduzca cambios de propiedad no demuestra por sí solo que sea divertida, justa o que los valores 4/3 sean óptimos.

### Resultados por escenario (cuatro pares por mapa)

| Mapa | Cambios actuales | Cambios progresivos | Interpretación inicial |
|---|---:|---:|---|
| Abierto | 29 | 10 | La captura instantánea produce cambios/recapturas muy frecuentes |
| Bosque | 10 | 8 | Poca diferencia en las capturas completadas al corte |
| Puentes | 27 | 8 | La ocupación por turnos reduce mucho las capturas rápidas en cuellos de botella |
| Costa | 28 | 14 | Menos cambios de control, pero sin probar aún que mejore el resultado económico |

### Recomendación tras las pruebas

**Conservar como candidata** la captura por progreso con la colaboración de soldados **adyacentes**, umbral de bloqueo económico parcial y un mínimo de dos turnos propios, sin aplicarla a las reglas jugables todavía. A continuación, realizar sensibilidad **3/4/5 puntos** de ciudad, comparar pérdida de renta del dueño desde 2 puntos vs solo al terminar captura, estudiar durabilidad y amenaza enemiga y actualizar la estrategia de IA. La variante de Rompedor capturador se debe reconciliar primero con la PR #156.

**Todavía falta** incorporar la barra de captura en HUD Android y la persistencia validada en `SaveCodec`; el registro externo del prototipo no se guarda. Un merge directo de este experimento produciría un comportamiento incompleto al cargar partidas o al usar la IA.
