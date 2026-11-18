# TARVOKA v3.8.1 — Por qué tarda el combate en los mapas grandes

**18 noviembre 2026. PR DRAFT de investigación; ninguna regla del juego alterada.**

## Punto de partida verificado

La [regresión v3.8.0](https://github.com/edwinrodri12/Tarvoka/actions/runs/44262106909) aprobó **17/17 trabajos**, 16 condiciones individuales y sus 16 reflejos de la matriz de iniciativa. En las ocho condiciones originales de **40×30**, los ocho casos llegaron al límite de **8 medios turnos** sin ganador. Las partidas contenían **568 órdenes**, **92 compras** y **solamente 2 ataques** entre las ocho condiciones. Esto por sí solo **no demuestra** que la IA sea pasiva ni que el combate de los mapas grandes esté desequilibrado: en un tablero 40×30 puede tomar más turnos llegar al enemigo.

## Experimento extendido v3.8.1

Reutilizar el motor real `BasicAI.step` y `BattleSession`, las compras y la economía auténticas, el mismo roster de seis unidades modernas por bando, los controles de apertura e ingresos iniciales simétricos opt-in, los objetivos de relés, la niebla, suministros y el código de prueba v3.7.9. No crear acciones de combate artificiales.

- **24 medios turnos**, triple de la ventana previa. Cada partida termina si obtiene un ganador auténtico antes del límite; una partida interrumpida por límite o inactividad queda censurada, nunca se transforma en empate o ganador.
- **4 plantillas diferentes** de mapa 40×30: semillas 630 (puentes), 631 (costa), 632 (pradera), 633 (bosques); con niebla activa y desactivada.
- **Dos iniciadores** por semilla y niebla, más **un reflejo por cada partida**, para 16 sesiones originales + 16 validaciones de simetría (=32 sesiones ejecutadas); ocho grupos contrafactuales independientes de iniciativa.
- Contrastar **cada acción, estado y transición** con su reflejo. Cualquier divergencia falla CI, pero los reflejos **no duplican** el tamaño estadístico de la muestra.

## Nuevas observaciones por fase

Se extraen de fotogramas de estados reales después de las acciones y de la finalización de cada turno:

1. Primer ataque legal de IA, ataques por bando y fase; número de movimientos, compras y reabastecimientos.
2. Primera captura real de **ciudad** (ingresos) y primera captura real de **relé** (señal) a través de cambios en `economy.sites` y `control.nodes`.
3. Primera distancia mínima Manhattan de tres casillas o menos entre enemigos: **proxy geométrico**, no equivale a ataque posible, alcance legal ni visión.
4. Primer avistamiento enemigo según `Visibility.visible_cells` cuando **sí** existe niebla, medido en los estados al terminar medio turno.
5. Instantáneas a los medios turnos **2, 4, 8, 12, 16, 20, 24** si la partida sigue activa: número de unidades vivas, avance máximo en coordenadas locales de cada facción, distancia mínima entre ejércitos, ciudades y relés controlados, dinero, marcador de señal y unidades con munición/combustible bajo.
6. Último estado, ganador real si corresponde, cantidad de medios turnos completados y causa explícita de terminación.

El agregador exige matriz exacta (sin duplicados, sin ausencias), coherencia de acciones, captura y avistamiento, muestras temporales, resultados reflejados iguales y no confundir censura con empate.

## Restricciones y expectativas

- La v3.8.1 **no propone todavía modificar el mapa, movimiento, daños, generación de recursos, IA ni incentivos de captura**; es estrictamente diagnóstica.
- No atribuir retrasos en contacto a la IA cuando el terreno, unidades o alcance lo explican. Contrastar cada plantilla con y sin niebla.
- Revisar consumo de CPU/memoria de tests con ventanas mayores y cualquier nueva divergencia después del octavo medio turno. El tiempo de CI es tiempo de test, no un indicador de rendimiento FPS en Android.
- No fusionar, no lanzar una APK ni hacer cambios de balance sin datos completos y revisión.

**CI:** [workflow v3.8.1](https://github.com/edwinrodri12/Tarvoka/blob/experiment/ai-v381-large-map-contact-progression-20261118/.github/workflows/ai-large-contact-v381.yml). El resultado debe comprobarse antes de afirmar que pasa.
