# TARVOKA v3.7.9 — Estudio contrafactual del orden de inicio

**18 de noviembre de 2026.** Rama de investigación, no fusionada. Conserva intactos los archivos de producción, la economía, `BasicAI`, el juego y la APK.

## Evidencia que motiva el ensayo

La v3.7.6/v3.7.7 logró simetría por reflexión en **192/192** parejas de batallas completas, sin alterar el plan táctico oficial salvo el orden de unidades/objetivos relativo a cada facción. Sin embargo, la v3.7.6 observó **64 victorias del iniciador frente a 128 del respondedor** en un conjunto limitado de mapas pequeños y ejércitos clásicos. Eso no confirma ni cuantifica la ventaja de iniciativa del juego comercial moderno.

La v3.7.8 pasó las **64 secuencias** de integración con ejércitos modernos y mapas 24×18/40×30: [CI](https://github.com/edwinrodri12/Tarvoka/actions/runs/44254950200). No eran batallas completas y no tenían datos de ganador.

## Nuevo experimento controlado v3.7.9

Se usan **16 grupos emparejados** de un terreno exacto, semilla, niebla, plantilla, IA (nivel 12), reglas y ejército moderno. En cada grupo se ejecuta:
1. Partida real con el jugador 0 iniciando.
2. Partida real con el jugador 1 iniciando, sin cambiar unidades, geografía, caja inicial ni reglas.
3. Reflejo horizontal + intercambio de facciones de la primera partida.
4. Reflejo horizontal + intercambio de facciones de la segunda partida.

Se reproducen **64 partidas autoritativas de Godot**, pero los 32 reflejos son exclusivamente **controles de simetría**. El denominador para describir ganadores originales es **32 condiciones**, no 64 muestras independientes.

| Escenario | Semillas | Niebla | Ventana | Juegos originales | Reflejos |
|---|---|---|---|---:|---:|
| 10×8 | 401, 402, 403, 404 | Sí/no | Hasta victoria o 80 medios turnos | 16 | 16 |
| 24×18 | 317, 319 | Sí/no | Hasta victoria o 16 medios turnos | 8 | 8 |
| 40×30 | 630, 632 | Sí/no | Hasta victoria o 8 medios turnos | 8 | 8 |

Cada acción ejecuta `BasicAI.step` y las transiciones reales `BattleSession`, mantiene la limitación de **tres órdenes** para el primer turno, ingresos iniciales simétricos opt-in, puntuación de relés por ronda, compras legales, niebla y suministros modernos. Se verifica cada estado reflejado completo, no solo el ganador.

## Análisis y precauciones

- **Censura estricta**: al llegar al límite sin ganador, marcar censurado, no empate y tampoco victoria por puntaje. Incluir el marcador de relés solo como diagnóstico y, de ser posible, al cerrar una ronda de turnos iguales.
- El estimador descriptivo principal es `iniciador ganó / partidas decisivas`, por tamaño y niebla. Un número pequeño de casos no permite inferir una tasa definitiva ni hacer cambios de balance.
- El contrafactual elimina diferencias sistemáticas de color/terreno dentro de cada grupo, pero no sustituye partidas humanas con diversas estrategias.
- Las ocho facciones son, a la fecha de esta implementación, solo identidades **visuales** con dos bandos lógicos. Las ventajas y poderes de comandante no se ensayan aquí.
- Una ventaja para el segundo jugador no se resolverá con dinero, movimientos, daño, acciones o unidades gratuitas sin demostrar primero el mecanismo causante.
- Los mapas grandes tienen ventanas cortas por coste de cómputo, por lo que sus métricas son indicios tempranos y **no tasas de victoria final**.

**Resultado pendiente hasta que pase CI. Nunca publicar ni fusionar automáticamente.** Si los controles de espejo fallan, investigar primero el primer estado divergente; si el desequilibrio persiste con muestras suficientes, explorar un ensayo de políticas de apertura *solo en otra rama*, sin cambiar la configuración aprobada.
