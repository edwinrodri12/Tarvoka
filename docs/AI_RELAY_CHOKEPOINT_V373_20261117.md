# TARVOKA — v3.7.3, la siguiente decisión: objetivos fuera de los cuellos de botella

**18 de noviembre de 2026, UTC.** Investigación reproducible en rama experimental. No modifica el juego oficial, `main`, APK, guardados, economía, IA ni reglas de puntuación.

## Hallazgo comprobado en v3.7.2

[Prueba de 320 partidas](https://github.com/edwinrodri12/Tarvoka/actions/runs/44229809853): **18 de 18 trabajos verdes**. La regla prometedora de cuatro relés simétricos (4,2), (5,2), (4,5), (5,5), meta de 8 puntos, ingresos iniciales simétricos y puntuación por ronda completa produjo **28/64 victorias del primero**, **36/64 del segundo** y color **32/32**. Aun así, los desgloses por terreno fueron muy dispares:

| Mapa | Gana primero (16) | Gana segundo |
|---|---:|---:|
| Campo abierto (0) | 8 | 8 |
| Bosque de las Dos Rutas (1) | 14 | 2 |
| Puentes de la Cuenca (2) | 0 | 16 |
| Costa de las Dos Bahías (3) | 6 | 10 |

Un porcentaje global aproximadamente equilibrado **oculta un sesgo enorme en mapas específicos**. En Puentes de la Cuenca, los cuatro relés centrales están en casillas que conectan o custodian los pasos de agua (filas 2 y 5). Para comprobar si esos cuellos de botella explican el sesgo —sin asumirlo de antemano— es necesario cambiar solo los emplazamientos y la meta en estados de prueba.

## Batería v3.7.3: 320 juegos, cuatro terrenos, cinco configuraciones

Cada configuración incluye **64 batallas reales de Godot 4.3**: 4 mapas × niveles 10/12 × niebla sí/no × quién inicia azul/rojo × IA v3.5 vs v3.5 / v3.6.3 vs v3.6.3. Todas tienen **cuatro relés, apertura oficial de tres órdenes, economía inicial opt-in simétrica y puntos por ronda completa**, igualando tropas, reglas, y AI. La diferencia controlada es **ubicación** y/o **meta**.

| Clave | Casillas de relés | Meta |
|---|---|---:|
| `center_target8` (control anterior) | (4,2), (5,2), (4,5), (5,5) | 8 |
| `center_target10` | Las cuatro casillas centrales | 10 |
| `approach_target8` | (3,2), (6,2), (3,5), (6,5) | 8 |
| `approach_target10` | Las cuatro casillas de acceso a puentes | 10 |
| `flanks_target8` | (3,1), (6,1), (3,6), (6,6) | 8 |

Todas las posiciones son pares reflejados entre facciones y deben ser transitables en los cuatro mapas. **Se prohíben solapamientos de relés con ciudades, fábricas o agua**. El motor real `RelayControl.gd` captura y puntúa; no se emulan esos resultados. Los relés de los accesos a puentes y de los flancos son *hipótesis*, no posiciones aprobadas.

## Instrumentación y criterios estrictos

- `tests/test_ai_relay_chokepoints_v373.gd`: 320 combates, registra secuencia de apertura, dueño de cada relé, primer momento de captura por jugador y casilla, primera ronda de puntuación, puntos y número de propietarios al final de cada ronda, tipo de victoria, compras, bajas y capturas de ciudades.
- `tests/test_relay_chokepoint_contract_v373.gd`: **80 contratos de estado real** (4 mapas × 2 nieblas × 2 primeros × 5 variantes). Verifica 0 puntos tras la primera media ronda, luego 2 puntos a cada bando con dos relés propios, empate sin victoria, superación del objetivo solo después de una ronda completa, guardados correctos y rentas iniciales simétricas.
- `tests/aggregate_ai_relay_chokepoints_v373.py`: rechaza 320 registros ausentes o duplicados, marcadores de ingresos/apertura inconsistentes y puntuaciones que no coinciden con los relés controlados. **Exige reproducir exactamente el histórico anterior del control centro/meta8**, también **por mapa y color**, antes de interpretar las variantes.
- Compara 64 parejas de partidas entre centro/meta8 y meta10, entre accesos/meta8 y meta10, entre centro/meta8 y accesos/meta8 y entre centro/meta8 y flancos/meta8. Reporta qué ganadores cambian, en qué dirección y por qué mapa.

## Criterio de decisión

Nunca aprobar una ubicación basándose únicamente en los resultados agregados. Una mejora debe reducir la diferencia entre quien empieza y quien responde **por mapa**, sin introducir sesgo de color ni partidas excesivamente cortas. La estabilidad con niebla y diferentes políticas también importa.

Si ninguna de las variantes mejora **Puentes** sin perjudicar **Bosque**, la siguiente prioridad será estudiar mapas/posiciones iniciales y la IA en cruces, no añadir ayudas artificiales de ingresos, ataques o movimientos. Habrá que repetir las pruebas en mapas aleatorios, ejércitos modernos y juego humano antes de cualquier integración.

**No hay cambios de producción ni decisión automática de merge/APK.**


## Hallazgos observados en los 320 registros de Godot

Se completaron los **16 grupos de partidas** (20 registros auténticos cada uno). Se contaron las victorias directamente a partir de los archivos de ejecución, sin suponer que un 50/50 global es justicia. [Ejecutados en Actions #44232343257](https://github.com/edwinrodri12/Tarvoka/actions/runs/44232343257).

| Cuatro relés | Primero gana | Segundo gana | Azul / Rojo | Fases promedio |
|---|---:|---:|---:|---:|
| Centro, objetivo 8 | 28/64 | 36/64 | 32 / 32 | 9.81 |
| Centro, objetivo 10 | 28/64 | 36/64 | 32 / 32 | 11.00 |
| Accesos, objetivo 8 | 12/64 | 52/64 | 36 / 28 | 8.94 |
| Accesos, objetivo 10 | 14/64 | 50/64 | 38 / 26 | 10.56 |
| Laterales, objetivo 8 | 18/64 | 46/64 | 38 / 26 | 13.50 |

### Sesgos por mapa: las dos dimensiones importan

| Mapa | Centros/meta8: primero-segundo | Accesos/meta8: primero-segundo | Laterales/meta8: primero-segundo | Laterales/meta8: azul-rojo |
|---|---|---|---|---|
| Campo abierto | 8-8 | 0-16 | 0-16 | 8-8 |
| Bosque | 14-2 | 8-8 | 4-12 | 4-12 |
| Puentes | 0-16 | 0-16 | **8-8** | **16-0** |
| Costa | 6-10 | 4-12 | 6-10 | 10-6 |

**Decisión de diseño:** NO seleccionar los relés laterales de forma universal. Su aparente arreglo de Puentes (iniciativa 8-8) **sustituye el sesgo por uno de color extremo (azul 16-0)**. El resultado agregado de laterales también es peor (primero 18-46). Los accesos equilibran Bosque (8-8 y azul 8-8), pero empeoran Campo abierto y no mejoran Puentes.

**Efecto de la meta:** pasar del objetivo 8 al 10 para relés centrales cambió **cero de 64 ganadores**; aumentó la duración media de 9.81 a 11 fases. En accesos cambió 2/64 ganadores y no resolvió Puentes.

### Siguiente decisión prioritaria

**Investigar la simetría de IA, despliegue de unidades y desempates de rutas bajo reflejo horizontal.** En Puentes, el mismo objetivo de cuatro relés laterales tiene iniciativa equilibrada, pero victoria de azul en **16/16**, aunque el mapa y relés se reflejan en columnas x=3 y x=6. Esta evidencia sugiere que la geometría no es el único factor; hay que aislar bandos, IDs de unidades, orden en arrays, desempates deterministas y rutas propuestas **sin inventar bonificaciones de estadísticas**.

Diseñar un contrato de **metamorfismo** (reflejar mapa, posiciones de las unidades y relés, intercambiar facciones y comparar las acciones legales y las decisiones IA), con pruebas en niebla, ambos niveles y las cuatro clases de mapas. Un sesgo de color no debe «corregirse» mediante una regla especial para un mapa o bando sin descubrir el origen.

**Estado:** hallazgos observados de la salida de los 16 grupos; los checks finales del informe de GitHub son una puerta adicional independiente. No se autoriza fusionar esta investigación ni alterar la APK.
