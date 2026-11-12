# TARVOKA — Capítulo 01: contrato de prototipo vertical [PLAN]

**Fecha:** 2026-11-12. **Estado:** especificación verificable; NO implementado ni probado en Android.
**Referencias:** [CAMPAIGN_STORY_50.md](CAMPAIGN_STORY_50.md), [CAMPAIGN_UNIT_PROGRESSION.md](CAMPAIGN_UNIT_PROGRESSION.md), [GAME_DESIGN.md](GAME_DESIGN.md), [DESIGN_QA.md](DESIGN_QA.md).

## Alcance mínimo

**01 — Escudo compartido**, Alianza Norte. Un ejercicio previo a la crisis de Meridian enseña movimiento, alcance, combate y captura por infantería. Usar una variante de mapa existente 10×8 antes de producir mapas, escenas o arte nuevos. El prototipo puede reutilizar soldados de prueba; **no etiquetarlos como clase G01 Guardia implementada** hasta integrar sus estadísticas y reglas del catálogo. La misión no requiere economía, online, unidades navales, diálogos animados ni nueva facción jugable.

El objetivo debe ser **ocupar un punto de ejercicio con una unidad de infantería y conservarlo hasta el cierre de turno**, no exterminar al rival. Las condiciones de victoria/derrota deben ser explícitas y mutuamente excluyentes. No usar el modo experimental de relés como sustituto silencioso: reutilizar su infraestructura solo si el nuevo contrato de objetivo se implementa y prueba por separado.

## Gate de implementación (antes de habilitar el capítulo en menú)

| Caso | Entrada / acción | Resultado esperado | Estado |
|---|---|---|---|
| C01-01 | Iniciar capítulo 01 desde partida nueva | Escenario determinista y briefing legible, sin afectar escaramuza | NO EJECUTADO |
| C01-02 | Tocar destino legal y cancelar | No se consume acción ni cambia posición | NO EJECUTADO |
| C01-03 | Ordenar movimiento y ataque confirmado | Resuelve según motor; preview coincide con reglas | NO EJECUTADO |
| C01-04 | Unidad no infantería sobre objetivo | No captura; ninguna victoria accidental | NO EJECUTADO |
| C01-05 | Infantería sobre objetivo al cierre del turno | Captura y victoria solo cuando se cumple condición explícita | NO EJECUTADO |
| C01-06 | IA elimina última unidad del jugador | Derrota visible; no aparece turno adicional | NO EJECUTADO |
| C01-07 | Guardar en mitad del capítulo y reiniciar aplicación | Restaura objetivo, turno, HP, unidades y progreso sin duplicar recompensa | NO EJECUTADO |
| C01-08 | Save antiguo sin metadatos de campaña | Sigue cargando como escaramuza compatible | NO EJECUTADO |
| C01-09 | Fog habilitada en variante de test | IA no consulta unidades/terreno ocultos; briefing no filtra enemigos | NO EJECUTADO |
| C01-10 | Android ARM64 real, horizontal/vertical | Controles visibles, sin toques dobles, rendimiento medido | NO EJECUTADO |

## Pruebas adversariales obligatorias

- Intentar capturar con un vehículo o una unidad eliminada; no debe puntuar.
- Repetir cierre de turno y reabrir guardado final; no debe conceder dos victorias ni reactivar una partida terminada.
- Cargar JSON truncado o con objetivo inválido; conservar guardado anterior válido y mostrar aviso.
- Cambiar de capítulo a escaramuza y viceversa; no mezclar autosaves ni desbloqueos.
- Ejecutar suites actuales de reglas, 24 enfrentamientos de relés y 12 de niebla antes de integrar.

## Tradeoffs y secuencia

Primero definir **estado puro de misión** y serialización opcional compatible; luego pruebas headless de victoria/derrota y reanudación; después briefing/debrief táctiles y CI Android; finalmente QA físico. Evitar implementar la campaña completa o 32 unidades para probar este capítulo. El desbloqueo G01 permanece como metadato [PLAN] hasta existir unidad real. No declarar gate superado por exportación exitosa: Godot CI, APK y teléfono son evidencias distintas.
