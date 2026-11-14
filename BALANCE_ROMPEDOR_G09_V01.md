# TARVOKA · Balance Rompedor G01 vs G09 (v0.1)

**Fecha:** 14 de noviembre de 2026 · **PR #328**, rama independiente de los trabajos de reparación y navegación del Ingeniero. **Estado:** ajuste implementado para pruebas, aún no aprobado para equilibrio comercial ni fusionado en main.

## Decisión numérica

- Se conserva la ficha del **Rompedor**: 8 HP, ATQ 4, DEF 0, movimiento 3, alcance 1, precio **300 créditos**.
- Se conserva la ficha del **Tanque principal G09**: 14 HP, ATQ 8, DEF 2, movimiento 4, alcance 1, precio **750 créditos**.
- Se mantiene +4 ATQ del Rompedor **únicamente contra Baluarte**, sin cambios.
- Se añade **+2 ATQ del Rompedor únicamente contra el rol G09**. No se modifica ataque global, defensa, coste, munición, probabilidad de daño, facciones, tecnología, experiencia ni efectos visuales.
- Este modificador utiliza el **mismo `Roles.role_bonus`** consumido por `BattleActions.preview_exchange`, `BattleSession.attack` y el HUD de predicción. Sin código independiente en interfaz/IA y sin campos nuevos en los guardados.
- Se actualizan las fichas cortas del Rompedor, el G09 y las fortalezas/debilidades de su doctrina para que el texto explique exactamente el contraataque que está programado.

## Evidencia A/B (Godot 4.3; 120 combates efectivos de seis tipos de objetivo × cinco posiciones × cuatro alternativas)

Los datos se generaron con **la ruta real del motor**: `BattleActions.preview_exchange` y `BattleSession.attack` sobre copias temporales de estados con combustible/munición/economía. Los 120 casos validaron daño, contraataque y guardado. El archivo `tests/test_piercer_g09_sensitivity.gd` exporta la matriz completa como JSON desde CI.

| G09 contra Rompedor | Bono +0 (antes) | Bono +1 | Bono +2 (propuesto) | Bono +4 |
|---|---:|---:|---:|---:|
| Daño Rompedor a G09 en llano | 2 | 3 | **4** | 6 |
| Posibles disparos para eliminar G09, sin reacción | 7 | 5 | **4** | 3 |
| Respuesta G09 al primer ataque en llano | 5 | 4 | **4** | 3 |
| HP Rompedor tras el primer intercambio | 3 | 4 | **4** | 5 |
| Daño al G09 en bosque | 1 | 2 | **3** | 5 |
| Daño al G09 en montaña | 1 | 1 | **1** | 3 |
| Daño al G09 en ciudad | 1 | 2 | **3** | 5 |

**Justificación del +2:** permite que el Rompedor produzca una amenaza real contra blindados pesados, pero sigue necesitando varios impactos, la montaña conserva su fortificación, y el tanque que inicia el combate puede eliminar de un disparo a la unidad antiblindaje. El +4 contra G09 resultaría mucho más intenso (6 de daño frente a 14 HP) y reduciría demasiado el número de respuestas tácticas; +1 seguiría requiriendo cinco impactos sin reacción. Estos juicios son relativos a los microduelos y no prueban todavía victoria/equidad a escala de partidas completas.

### Costos y contrajuego

- **1 Rompedor = 300 créditos**, 1 G09 = **750 créditos**, 2 Rompedores = **600 créditos**.
- Cuando dos Rompedores atacan un tanque desde dos casillas adyacentes en una fase, causan **4 + 4 = 8 HP**. El tanque queda a **6/14 HP**; la primera reacción causa **4 HP** al primer Rompedor y la segunda no causa daño (una reacción por turno). No es una eliminación instantánea.
- Si inicia el tanque contra un Rompedor sano y expuesto, golpea por **8 HP** y lo destruye, sin permitir respuesta. Esto conserva una contramedida importante.
- El costo por daño no considera todavía posicionamiento, tiempo de compra, cobertura, combustible, alcance de fábrica, nuevas unidades ni objetivos de captura. NO extrapolar esos duelos a tasas de victoria.

## Cobertura numérica y verificaciones para este PR

1. **120 escenarios experimentales**: roles G09, Baluarte, IFV, APC, Guardia y artillería autopropulsada; llano, carretera, bosque, montaña y ciudad; hipótesis +0/+1/+2/+4. En los cinco objetivos que **no** son G09 el daño es idéntico con los cuatro bonos simulados.
2. **15 combates reales con regla oficial +2** en cinco terrenos y tres climas (despejado, lluvia y nieve). Clima afecta movimiento, no añade daño táctico oculto. Verificar previsión y ejecución, munición, contrafuego y persistencia.
3. **Economía y diferencias de turno**: enfrentamiento de dos Rompedores contra un tanque; comienza G09 y viceversa; el tanque responde como máximo una vez; costo sin cambios; alternancia de facción y combate después de mover.
4. **Rangos/domínios y guardados**: no se habilita ataque antiaéreo/naval por ser antiblindaje; no se modifica la unidad de Baluarte (+4); la tabla para 32 roles conserva sin cambios todos los demás emparejamientos. JSON de guardado v1 reversible.
5. **Compilación Android y regresión Godot completa** deben confirmarse antes de cerrar la revisión. La compilación automática no equivale a haber probado el rendimiento Android físico.

## Criterios pendientes para considerar balance comercial

- Partidas completas de IA con **composiciones antitanque variadas**, posiciones de inicio intercambiadas, tres mapas, terreno aleatorio, clima, diferentes niveles de cobertura y economía urbana real.
- Medir si un Rompedor se compra excesivamente y reemplaza a vehículos IFV/APC/Tanque; tiempo hasta destruir G09; pérdidas por inversión; municiones, contraataques; posibles remontadas y turno de primera captura.
- Pruebas humanas sobre claridad de iconos y vista previa de daño en Android. La nueva bonificación no cambia la captura (solo Guardia, Rastreador, Asaltante e Ingeniero capturan); la unidad Rompedor sigue sin capturar.
- **Multijugador:** este cambio es simétrico para los dos bandos actuales. No implica implementar partidas en línea ni ocho jugadores tácticos; eso requiere arquitectura separada.

**Política:** mantener como PR en borrador si cualquier regresión sigue fallando. El bono +2 es un valor seleccionado con evidencia controlada, todavía sujeto a revisiones A/B más amplias.
