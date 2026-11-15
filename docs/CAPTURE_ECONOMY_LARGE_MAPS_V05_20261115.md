# TARVOKA — Auditoría v0.7: compras de unidades y escalamiento de mapas

**15 de noviembre de 2026 · PR #394 (borrador) · Solo investigación; sin cambios en gameplay oficial ni APK Android**

## Pregunta

La IA experimental de rutas seguras redujo las muertes de capturadores (70→48) y las capturas interrumpidas (100→80) en 16 pares de partidas 10×8, pero también registró menos compras (1.031→910, -11,7 %). A la vez hubo el doble de partidas decididas (4→8), por lo que es incorrecto suponer que esta diferencia prueba un problema de economía.

Para distinguir factores se añadieron contadores en tests/test_capture_economy_causal_v05.gd, sin tocar los módulos core. Analizan:
- Compras totales y por **media fase jugable**, para corregir el sesgo de partidas terminadas antes del horizonte.
- Compras de las primeras 20 medias fases con horizonte común.
- Oportunidades comerciales al inicio de fase: instalaciones disponibles, bloqueadas por una unidad en la casilla, que ya produjeron, sin fondos suficientes o restringidas por la reserva de abastecimiento de la IA.
- Crédito invertido en unidades y dinero al cierre; disponibilidad de plantas de producción y presión sobre recursos.
- Mismos 16 escenarios espejo con 48 medias fases máximas, 18 acciones IA por media fase y el mismo mecanismo de captura en ambos brazos.

Se ha instrumentado el entorno, no una regla de compras nueva. Aún hay que distinguir **menos turnos** de **menor demanda de refuerzos**, y no asumir que el segundo factor es malo: menos unidades perdidas podrían ser eficiencia, pero debe demostrarse con datos.

## Pruebas de escalamiento 24×18 y 40×30

**Godot 4.3 SUCCESS:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43770096909

Se utilizaron **6 pares espejo**, 12 partidas, con terrenos aleatorios por semilla, mapas simétricos, unidades y fábricas escaladas a sus posiciones legales, y distintos iniciadores. Los mapas 24×18 usaron niebla activada y desactivada; los 40×30 fueron pruebas de compatibilidad sin niebla. El horizonte fue acotado: **14 medias fases para 24×18 y 6 para 40×30**, con 7/4 decisiones por fase, respectivamente. No pretende medir tasas de victoria ni balance completo.

| Indicador en las 12 partidas | IA conservadora | IA con rutas seguras |
|---|---:|---:|
| Cambios de dueño/completadas | 8 | 8 |
| Capturas interrumpidas | 6 | 4 |
| Compras de unidades | 72 | 72 |
| Desvíos especiales | 0 | 4 |
| Fases activas acumuladas | 68 | 68 |
| Partidas decididas | 0 | 0 |

Las **4 desviaciones** se dieron en mapas 24×18 con niebla. En los dos experimentos 40×30 no hubo capturas ni desvíos debido al horizonte corto y el tamaño de campo. Por ello estas pruebas **validan que el sistema funciona en mapas grandes**, pero todavía no respaldan equilibrio multijugador ni diversión humana.

## Resultados de la auditoría económica

**Workflow:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43770096819

No adoptar una interpretación del descenso de compras hasta verificar los números de turnos activos y oportunidades de compra. Los resultados serán agregados a esta sección después de confirmar SUCCESS y el marcador PASS del registro.

## Criterios para la próxima decisión

Conservar rutas seguras solo si siguen reduciendo bajas e interrupciones en suficientes mapas y horizontes, sin producir bloqueos sistemáticos de fabricación o partidas demasiado lentas. Separar pruebas de compatibilidad 40×30 de simulaciones completas. Falta evaluar escenarios multijugador de hasta ocho facciones (el motor auditado es todavía de dos bandos), calidad de decisiones humanas y persistencia del contador de captura en guardados y HUD.
