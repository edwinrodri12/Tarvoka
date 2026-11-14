# TARVOKA HQ V23 — humo con volumen y conexión segura a HP futuros

## Diferencia visual

Se sustituye la apariencia de esferas oscuras independientes de V22 por humo *pseudo-volumétrico* compuesto por elipses 3D con densidad irregular y turbulencia animada calculadas en un shader espacial Godot 4.3 Compatibility. No se promete simulación física de fluidos: su enfoque es arte volumétrico económico, sin GPUParticles, sin emisiones de luz nuevas y sin mapas de ruido externos.

- Daño medio: 3 fuentes de humo × 3 capas = 9 instancias, **1 MultiMesh** y 1 material GPU.
- Daño crítico: 5 fuentes × 3 capas = 15 instancias, **1 MultiMesh** y 1 material GPU. Mantiene 10 llamas 3D en **1 MultiMesh** separado.
- Perfil móvil de 2 capas conserva todas las fuentes (6 / 10 instancias).
- A larga distancia se ocultan estas mallas, se desactiva su _process y se detienen impactos transitorios. El sprite V15 / proxy táctico V13 no incluye las mallas costosas.
- El shader mezcla ruido 3D de dos frecuencias, disuelve el contorno y da deriva vertical. No crea un sistema de partículas por edificio.

Fuentes: `assets/shaders/hq_volumetric_smoke_v23.gdshader`, `scripts/ui/HeadquartersSmokeV23.gd`. Integrado directamente en `CombinedArtStudioWeb.gd`, reutiliza fuego V22 con humo V22 apagado. Se conservan los botones de impactos V21 para balas y explosivos.

## Conexión a eventos de combate y salud

`scripts/ui/HeadquartersCombatVisualV23.gd` es un receptor opcional de **sucesos confirmados por el motor**. Mapea únicamente HP real proporcionado por el juego a 0–4 etapas, clasifica armas reales, reproduce VFX y reconstruye la estructura cuando cruza el umbral. No inventa daño, no consume munición, no cambia balance, ni crea estadísticas nuevas. Rechaza eventos con target incorrecto, niebla de guerra, daño teórico en lugar de pérdida real, HP fuera de rango y armas desconocidas.

Bandas iniciales solo visuales:
- más de 75 %: intacto
- mayor de 50 % y hasta 75 %: antenas caídas (leve)
- mayor de 25 % y hasta 50 %: techo dañado + humo (medio)
- mayor de 0 % y hasta 25 %: ala colapsada + fuego (crítico)
- 0 HP: ruinas

**Limitación clave:** El motor actual `BattleSession` / `UrbanEconomy` solo permite combate por unidades; el Cuartel representa un lugar de tipo *ciudad capturable*, sin HP ni reglas de ataque estructural. Por eso **el adaptador aún no puede mostrar impactos automáticos sobre edificios durante partidas reales** hasta que se autoricen y diseñen reglas completas de edificios atacables. No debe utilizarse el HP de una unidad como si fuese HP del Cuartel. El código que acepta eventos está listo y testeado para el día en que la mecánica exista.

## Rendimiento y medición

Las comprobaciones GPU de Godot/Xvfb prueban construcción de shader, imágenes, movimiento, número de lotes, apagado por LOD y eventos de combate. Estas pruebas no establecen temperatura, rendimiento sostenido ni FPS reales en un teléfono. El benchmark Android físico V20 es útil como línea base, pero no incluye el nuevo shader hasta que se genere un APK específico V23. No afirmar rendimiento probado en una partida de 8 jugadores.

CI: `.github/workflows/hq-v23-smoke-combat-bridge-gpu.yml`, `tests/test_hq_v23_smoke_combat_bridge.gd`.
