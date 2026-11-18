# TARVOKA v3.7.4 — auditoría de simetría horizontal de la IA

**Rama de investigación, 17 de noviembre 2026 (zona America/New_York).** Ninguna mecánica del juego, guardado, APK, modelo 3D ni rama `main` cambia en este ensayo.

## Evidencia verificada que motiva este trabajo

[La última CI v3.7.3](https://github.com/edwinrodri12/Tarvoka/actions/runs/44232803642) completó **320 partidas auténticas**, 80 contratos de puntuación y los informes. El mejor resultado global anterior fue cuatro relés centrales con objetivo 8: primero **28/64**, segundo **36/64**, azul **32/64**, rojo **32/64**. Sin embargo, por mapa:

- Bosque de las Dos Rutas: primero **14/16**.
- Puentes de la Cuenca: segundo **16/16**.
- Situar los cuatro relés en las rutas laterales de Puentes cambió la iniciativa a 8-8, pero produjo **azul 16/16 y rojo 0/16**. Por eso NO se aprobó ninguna posición de relés.

Los mapas y ejércitos de inicio son geométricamente simétricos. Esto no prueba que la IA sea asimétrica: una orientación y el orden interno de evaluación pueden romper la equivalencia aun con las mismas reglas. La prueba debe comparar decisiones de estados *espejados*, no simplemente porcentajes finales.

## Qué se prueba

Se usa **`MirrorBattleV374.gd` exclusivamente en tests** para transformar una partida real de manera reversible:

1. Reflejar horizontalmente todas las filas del terreno y las posiciones de unidades, ciudades/fábricas y relés.
2. Intercambiar facciones 0 y 1, propietarios, créditos, puntos de relé y primera facción.
3. Intercambiar IDs emparejados de las unidades iniciales (A↔X, B↔Y, C↔Z, D↔W, E↔V) sin alterar roles, HP, rango, defensa, munición ni acciones disponibles.
4. Reflejar exploración, contactos y asignaciones del plan táctico persistente de la IA.
5. Probar por separado el **orden inverso del array de unidades** sin cambiar posiciones ni facciones. El juego nunca recibe esas alteraciones; son estados temporales de investigación.

Para cada estado inicial, se solicita una acción real a `BasicAI.step` en el estado original, en el reflejado y en el de orden inverso. Se registran tipo de acción, unidad, destino, oponente, instalación, motivo de decisión y objetivos persistidos; las comparaciones se hacen **después de convertir el resultado reflejado al sistema original**.

Una diferencia es un **hallazgo de comportamiento, no un fallo del motor por sí mismo**. Nunca se inventa una acción alternativa ni se modifican decisiones internas.

## Matriz y contratos de QA

- **192 aperturas reales**: cuatro mapas 10×8 × niebla sí/no × niveles 10/12 × primera facción azul/rojo × dos políticas `v35`/`v363` contra ellas mismas × tres disposiciones de relés `center`, `approach`, `flanks`.
- **576 decisiones originales** con apertura oficial de tres órdenes; por cada una, **576 decisiones reflejadas y 576 decisiones en orden inverso** ejecutadas por la IA real.
- **48 contratos de estado real**: cuatro mapas × dos nieblas × dos primeros jugadores × tres disposiciones. Se exige que reflejar dos veces devuelva el estado inicial, que se conserven legalidad, créditos, objetivos, puntos, apertura y validación con `SaveCodec`.
- La simetría de visibilidad se mide celda por celda. Si el algoritmo de visión no se refleja exactamente y requiere actualizar la exploración para un guardado válido, ese caso queda contabilizado expresamente; nunca se entrega a la IA una posición oculta inventada.

El informe `reports/ai_v374_mirror_audit.{json,md}` exige 192 registros únicos y 576 comparaciones, y desglosa diferencias por mapa, niebla, iniciador, política, disposición y número de acción. Incluye hasta diez casos concretos para reproducir el problema.

## Criterio de próxima decisión

Si hay divergencias, identificar primero su fuente (selección de unidad, objetivo, destino, visibilidad o desempate) y reparar **solo el mecanismo compartido responsable** en una nueva rama con pruebas de regresión, sin conceder ventajas a ningún color ni cambiar los mapas a ciegas.

Si no hay divergencias en estas decisiones iniciales, descartar ese factor para la apertura y estudiar la equivalencia durante capturas, turnos completos, generación de unidades y cambios de propietarios, donde el sesgo también puede surgir.

Esta prueba no autoriza modificar la APK ni implica que las partidas completas sean igual de balanceadas. **PR DRAFT; solo tests, CI y documentación.**


## Resultado verificado — v3.7.4

[GitHub Actions #44234207399](https://github.com/edwinrodri12/Tarvoka/actions/runs/44234207399) completó **192 aperturas auténticas y 576 comparaciones** en Godot 4.3; el agregador pasó los controles de matriz exacta y los 48 contratos de estado reflejado.

| Subconjunto | Pares de decisiones | Diferencias por reflejo/cambio de facción | Diferencias por invertir orden de unidades |
|---|---:|---:|---:|
| Campo abierto | 144 | 0 | 0 |
| Bosque | 144 | 0 | 0 |
| Puentes | 144 | 0 | 0 |
| Costa | 144 | 0 | 0 |
| **Total** | **576** | **0** | **0** |

Las tres disposiciones de relés, los dos niveles de IA, ambos jugadores iniciadores y niebla activada/desactivada coinciden en **cada una de las decisiones iniciales observadas**. Tampoco hubo diferencias de visibilidad, reparaciones de exploración ni acciones que faltaran en el estado reflejado.

**Decisión:** no cambiar ahora la selección de movimientos de apertura, la preferencia de unidades ni los desempates iniciales. La auditoría **no ha encontrado un fallo** en esas operaciones. Estas 576 decisiones son solo las **tres primeras órdenes** en 192 estados de apertura; la simetría en ellas no demuestra que las fases posteriores con combate, compras, relés controlados, objetivos persistidos y tropas nuevas sean simétricas.

**Siguiente prioridad v3.7.5:** ejecutar batallas completas en **pares de estados reflejados e intercambiados**, auditando cada acción durante todos los turnos (incluidas compras y unidades creadas), el momento de las capturas, las metas de relé, el ganador, y **la primera transición exacta donde los estados dejan de corresponderse**. Comprobar en particular quién gana en Puentes con relés laterales y en Bosque con relés centrales, separando orientación, facción e iniciativa. Mantener los cambios experimentales y la APK fuera de `main`.

**No fusionar ni activar nuevas reglas de balance como resultado de esta investigación.**
