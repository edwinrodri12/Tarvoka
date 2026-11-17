# TARVOKA — Laboratorio de ejército adaptable v2.9

**17 nov 2026 · PR borrador #523 · CI Godot 4.3 3/3 PASS (36 partidas)**
https://github.com/edwinrodri12/Tarvoka/actions/runs/44138356632

## Hipótesis

En v2.7 el acceso temprano al Rompedor desde el cuartel es legal, pero la política de presión lo fabrica demasiado a menudo y pierde infantería de captura. ¿Mejora conservar un núcleo de conquista y comprar Rompedor **solo** cuando se identifica una amenaza blindada real?

Sin cambiar HP, alcance, daño, defensa, coste de tanque o tecnología, se comparan tres modos de producción:
- `legacy`: Rompedor producido en planta blindada, cuartel compra asaltante/guardia (V21 original);
- `spam`: Rompedor disponible desde Cuartel I y la IA lo compra de forma incondicional (v2.7);
- `adaptive`: Rompedor disponible desde Cuartel I; la IA reserva al menos 3–4 unidades que **sí** pueden capturar, observa solo blindados **visibles** y plantas blindadas conocidas, limita Rompedores a ~34% de ejército (máximo 3) y escoge guardia/asaltante en ausencia de amenaza.

La regla `adaptive_counter_mix` es **opt-in**, no modifica gameplay shipping ni los guardados. El rival tanque paga una mejora de nivel II de **650 créditos**.

## Resultados: 12 partidas por mapa, 4 por modo

**V/D/C** = victorias, derrotas, censuradas (sin resultado dentro del límite). Las cantidades de unidades y capturas son sumas de 4 partidas, **no por partida**.

| Mapa | Modo | V/D/C | Rompedores reclutados | Todas las compras | Ciudades capturadas (incluye reconquistas) | Daño | Bajas causadas |
|---|---|---|---:|---:|---:|---:|---:|
| 10×8 abierto | Anterior | 0/4/0 | 14 | 31 | 6 | 209 | 25 |
| 10×8 abierto | Spam | 0/4/0 | 15 | 15 | 4 | 144 | 18 |
| 10×8 abierto | Adaptable | 0/4/0 | 4 | 17 | 5 | 164 | 20 |
| 24×18 abierto | Anterior | 1/0/3 | 43 | 92 | 15 | 727 | 79 |
| 24×18 abierto | Spam | 0/0/4 | 48 | 77 | 11 | 643 | 63 |
| 24×18 abierto | Adaptable | 0/0/4 | 11 | 79 | **19** | **798** | **80** |
| 24×18 boscoso | Anterior | 0/0/4 | 42 | 90 | 10 | 619 | 72 |
| 24×18 boscoso | Spam | 0/0/4 | 48 | 76 | 1 | 542 | 56 |
| 24×18 boscoso | Adaptable | **1/0/3** | 7 | 81 | 7 | **686** | **81** |

**Interpretación:**
- La política adaptable **sí evita** saturar el cuartel con Rompedores. Frente a `spam`, mejora capturas y bajas en ambos mapas medianos y logra una victoria real en bosque donde las otras opciones quedaron censuradas.
- En 10×8 **no resuelve la dominancia blindada**: las tres variantes pierden 4/4. Sin pruebas humanas distintas, no concluir que el motor de combate esté desequilibrado o que cualquier tanque sea invencible.
- En 24×18 abierto, mejoraron daño y capturas, **pero no victorias** dentro del límite: 4/4 censuradas. Mejorar IA u objetivos de victoria puede ser más importante que un nerfeo.
- Las muestras no son independientes; 4 combinaciones espejo deterministas por modo y mapa. Un resultado CI verde confirma legalidad e integridad, **no demuestra equidad**.

## Diagnóstico nuevo: cuello de botella de fábricas

En la versión anterior, el ejército de presión tenía acceso a **dos vías productivas**: fabricaba infantería en el Cuartel y Rompedores en la planta blindada si lograba controlarla. Al mover Rompedor a Cuartel I y eliminarlo de la planta, la política de presión siguió priorizando en planta blindada `piercer` y `ifv`; pero el primero ya no era elegible allí y el `ifv` se bloqueaba por nivel II sin que esa IA lo mejorara. **El sitio conquistado puede quedar improductivo** aunque tenga fondos.

Esto significa que v2.7 no aisló completamente “disponibilidad de counter”: simultáneamente **redujo la capacidad de producción** del ejército de presión.

**Siguiente experimento necesario:** sin modificar stats ni costos, probar que la política de presión produzca legalmente **APC de nivel I** (300 créditos) en plantas blindadas propias como apoyo, mientras utiliza el Cuartel para Guardia, Asaltante y Rompedor. Comparar con v2.9 y el control original para saber cuánto se debía a la pérdida de producción. La acción de transportar tropas del APC todavía está pendiente, así que no atribuirle capacidades inexistentes. Mantener la IA por dominio/visión sin leer posiciones enemigas ocultas.

## Metodología y límites

- 36 partidas: 4 configuraciones espejo × 3 modos × 3 mapas (10×8 abierto; 24×18 abierto; 24×18 bosque). Godot 4.3, motor real de movimiento, ataque, ciudades y producción.
- Se valida exactamente el saldo, coste de tanques LII y ausencia de compras gratis.
- El número de `tank_kills` no es rastreable con el agregado actual, no afirmar bajas específicas de tanques.
- Faltan reglas reales de comandantes, veteranos, campamentos, poder aéreo/naval y 8 facciones.
- No incorporar la regla a `main` ni APK todavía. Los resultados del filtro de mapas están en [PR #521](https://github.com/edwinrodri12/Tarvoka/pull/521) y permanecen separados.

## Evidencia

- [CI y logs de las 36 partidas](https://github.com/edwinrodri12/Tarvoka/actions/runs/44138356632)
- `scripts/experiments/StrategicMatchBalanceV21.gd`, opción `adaptive_counter_mix`
- `tests/test_adaptive_counter_army_v29.gd`
- `.github/workflows/adaptive-counter-v29.yml`
