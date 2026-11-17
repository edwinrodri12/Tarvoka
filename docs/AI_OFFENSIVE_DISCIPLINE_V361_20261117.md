# TARVOKA IA v3.6.1 — evitar defensividad excesiva (EXPERIMENTO)

**17 noviembre 2026 | Sin merge a main | Sin APK | Sin cambios de estadísticas, recursos ni poderes**

## Evidencia previa: A/B v3.5 vs v3.6

[CI completa — 8/8 trabajos, 32 partidas autoritativas](https://github.com/edwinrodri12/Tarvoka/actions/runs/44167616688). Dos mapas terrestres (0/2), niveles 10/12, con y sin niebla y cambios cruzados de primer bando y versión.

| Métrica agregada | v3.5 | v3.6 |
|---|---:|---:|
| Victorias | **22** | **10** |
| Derrotas | 10 | 22 |
| Retiradas de unidades | 8 | **84** |
| Capturas de ciudades | **61** | 52 |
| Unidades iniciales que sobreviven (suma de 32 juegos) | 84 | 84 |
| Bajas totales de todas las tropas, incluidos reclutas | 111 | 109 |

**Interpretación**: el mayor número de retiradas no produjo una ventaja neta en las victorias ni en la supervivencia de las tropas iniciales. Estos resultados indican una posible penalización ofensiva, NO prueban que cada retirada concreta fuese incorrecta. `questionable_anticipatory=0` solo demuestra que se cumplieron los límites estáticos internos de riesgo, no que la retirada era estratégica.

Corte por dificultad, victorias v3.6: **7/16** en nivel 10 y **3/16** en nivel 12. Esto sugiere especial cautela con la suma pesimista de dos ataques visibles al nivel 11/12.

## Hipótesis de corrección v3.6.1

El riesgo de que dos rivales visibles puedan atacar una misma unidad en el siguiente turno es un **máximo teórico**, no una secuencia obligatoria. Se prueba la siguiente compuerta opt-in sin sustituir `NextTurnThreatV36`:

1. Conservar retirada anticipada de **artillería/armas indirectas** y apoyo crítico (logística, reconocimiento aéreo, sistemas electrónicos y de misiles), así como de capturadores realmente dañados.
2. Para tropas de frente, evitar escapar **solo** por la suma de dos golpes hipotéticos cuando su HP es al menos 8 y ningún golpe individual resulta letal. La doctrina ofensiva conserva el puesto.
3. Si un soldado puede disparar **ya** a un rival visible y producir un daño significativo (≥3 y ≥mitad del HP enemigo), sobreviviendo la contrarrespuesta pública, evitar que el pronóstico futuro lo expulse de esa oportunidad.
4. Todo dato consultado es público: observación del bando, línea/alcance legal y `BattleActions.public_preview_exchange`. No consultar combustible ni munición secreta del rival.
5. Mantener opt-in de laboratorio `_ab_offensive_discipline_v361=true`: el comportamiento v3.6 original permanece por defecto. Ni el menú del juego, ni las unidades, ni la APK cambian.

## Evidencia necesaria

- Contrato unitario `tests/test_ai_anticipation_discipline_v361.gd`: conservar retirada de ART y CAP herido, conservar frente sano ante doble ataque no garantizado y no usar información privada.
- Nuevo A/B v3.5 vs v3.6.1 con **32 sesiones equivalentes** en `tests/test_ai_v35_v361_full_matches.gd`, cuyo workflow entrega `AB361_MATCH` y `AB361_SUMMARY`.
- Confirmar que la nueva defensa no incrementa solo las victorias sino además conserva objetivos y unidades. Si fracasa, mantener v3.5 de referencia sin impulsar v3.6.1.
- No usar una mejora en solo dos mapas como prueba de ajuste general. Posteriormente evaluar otras doctrinas, escenarios, dominios y Android real.

**La configuración sigue siendo de QA**: ningún cambio forma parte del APK de distribución y no se ha fusionado a `main`.
