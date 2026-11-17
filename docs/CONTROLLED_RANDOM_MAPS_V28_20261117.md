# TARVOKA — Mapas aleatorios controlados (v2.8)

**17 de noviembre de 2026 · Prototipo experimental, no integrado en el APK.**

## Decisión de diseño

Usar **aleatoriedad con reglas**, no un tablero completamente caótico. Cada mapa nuevo debe ofrecer caminos, recursos y contramedidas comparables desde ambos lados, pero cambiar lo suficiente como para que los jugadores tengan que explorar, adaptarse y combatir de maneras distintas.

**El generador de TARVOKA ya existe**: `Scenarios.seeded_terrain` produce mapas 10×8, 24×18 y 40×30 con semillas reproducibles; usa cuatro familias geográficas (llanura, bosque, río y costa) y simetría horizontal. Este trabajo es un **certificador previo** sobre ese generador, no una reescritura ni una ruptura de las partidas guardadas.

## Normas del generador y validador

| Aspecto | Reglas obligatorias para un mapa competitivo candidato | Motivo |
|---|---|---|
| Posiciones iniciales | Terreno, propiedades, fábricas iniciales y acceso de captura reflejados horizontalmente | Evitar ventajas inevitables de color |
| Renta inicial | Misma cantidad de ciudades propias y mismo ingreso por turno para ambos | No inclinar la economía antes de actuar |
| Expansión | Al menos 2 ciudades neutrales y 2 instalaciones neutrales disputables | Varias rutas de desarrollo |
| Acceso real | Unidades terrestres deben poder recorrer terreno legal hasta **cada** ciudad e instalación de captura, desde **ambos** bandos | No esconder edificios tras agua o paredes |
| Tiempo de ruta | Utilizar **costes reales ponderados del motor** (carretera 1, bosque 2, montaña 3 para infantería) y comprobar que los objetivos reflejados tengan exactamente el mismo coste | La distancia en casillas no basta |
| Rutas centrales | Mínimo **dos pasos** entre las dos mitades del mapa, separados por al menos 2 filas | Evitar un único puente que decide toda la partida |
| Coberturas | Como filtro inicial, como mucho 50% de casillas terrestres con bosque/montaña y 25% solo montaña | Evitar mapas totalmente impenetrables |
| Instalaciones | Las fábricas/ciudades resultantes deben pasar el `StrategicMapSitesV17.layout` y no solaparse | Controlar producción y captura |
| Guardado y semillas | Una semilla siempre produce el mismo terreno. **Nunca** sustituir silenciosamente la semilla que escribió el usuario | Reproducibilidad, confianza y compatibilidad |

Estos umbrales son **candidatos** y no reglas de equilibrio probadas. La doble conexión del frente no basta por sí sola para impedir un choke point, porque un bosque/puente de una casilla puede permitir bloquear rutas; en otra fase se necesitan análisis de conectividad 2-vértices-disjuntos y pruebas de ocupación con unidades reales.

## Tamaños y distribución fija ya establecida en el laboratorio territorial

| Tamaño | Ciudades totales | Iniciales por bando | Neutrales | Instalaciones iniciales | Instalaciones neutrales |
|---|---:|---:|---:|---|---|
| 10×8 | 4 | 1 | 2 | Cuartel de Infantería | 2 plantas blindadas |
| 24×18 | 12 | 2 | 8 | Cuartel + planta blindada | Pares de artillería, drones y base aérea |
| 40×30 | 16 | 3 | 10 | Cuartel + planta blindada + artillería | Pares de cuartel, planta blindada, drones y base aérea |

Las bases navales aparecen **solo** cuando hay costas/puertos viables y accesibles desde tierra.

**Nota:** esta distribución ampliada es todavía experimental, porque `UrbanEconomy.MAX_SITES` conserva su validador del núcleo comercial y el experimento de ciudades utiliza un contador separado. No afirmar que el juego Android ya usa esta distribución en mapas aleatorios.

## Experiencia del usuario propuesta

En **Nueva partida → Escaramuza aleatoria** agregar *en otra etapa* estas opciones:

- **Mapa clásico por semilla:** igual que hoy; permite guardar/compartir cualquier semilla existente.
- **Mapa equilibrado (certificado):** buscar una semilla que cumpla el filtro, mostrar **la semilla realmente elegida**, su estilo y el tamaño, y permitir volver a tirar.
- **Estilo geográfico:** mixto / abierto / bosque / río / costa. La elección no garantiza la misma apariencia para todas las semillas pero respeta la familia de mapa.
- **Tamaño:** pequeño/mediano/grande, una vez que el HUD y el rendimiento de los escenarios ampliados estén validados.
- **Indicadores visibles:** 2+ rutas de cruce, nº de ciudades neutrales, ingresos por facción y accesibilidad. El selector no deberá ocultar ventajas, cambiar el terreno después de comenzar ni sustituir un mapa guardado.

**Partida casual:** las semillas no certificadas pueden mantenerse disponibles bajo el modo clásico. **Partida competitiva:** solo se ofrecen candidatos aprobados y se congelan sus parámetros antes del primer turno.

## Qué está implementado efectivamente en v2.8

`scripts/experiments/CertifiedRandomMapsV28.gd`:
- `audit(terrain, style)` verifica simetría, entradas de terreno, dos pasos separados, coberturas, distribución `Sites.layout`, igualdad de ingresos y propiedad, puntos de captura y ruta ponderada a **todas** las instalaciones.
- `certify_seed(seed, size, style)` acepta/rechaza una semilla exacta **sin modificarse**.
- `generate(requested_seed,size,style)` busca hasta 36 candidatas con un RNG local determinista y devuelve `seed` efectivo, mapa y métricas. La semilla solicitada sirve para reproducir la *selección*, no se oculta la seleccionada.
- `VERSION=1` para registro del contrato experimental; no cambia `Scenarios.seeded_terrain` o `SaveCodec`.

`tests/test_certified_random_maps_v28.gd`:
- rechazo de semillas inválidas, estilos inválidos, terreno asimétrico, cruce único artificial;
- análisis de 12 semillas por tamaño (36 casos) y selección por estilo con reproducibilidad;
- costes y edificios, compatibilidad del guardado de un mapa 10×8 existente.

**La prueba CI debe aprobarse antes de afirmar que el filtro funciona.** [PR #521](https://github.com/edwinrodri12/Tarvoka/pull/521).

## Próxima prueba posterior a la certificación

Medir con bots adaptativos si el mismo mapa certificado produce resultados parecidos al intercambiar color/iniciativa y escoger diversas estrategias. Filtrar casos de:
- ventaja económica irreversible a partir de un único edificio neutral;
- bot incapaz de explotar dos rutas, aun existiendo físicamente;
- acumulación de posiciones de montaña al lado de un HQ;
- incapacidad de alcanzar la instalación antiblindaje a tiempo;
- mapas certificados pero con partidas interminables.

El validador geográfico **no prueba por sí solo** equilibrio entre facciones o comandantes. La liga de estrategias, poderes y objetivos de HQ siguen siendo etapas independientes.

## No se ha cambiado

No se cambió el generador actual, terreno guardado, identificador de semilla, reglas de producción, APK, poderes de facción ni el modo casual. Todo queda en rama/PR hasta aprobar pruebas y verificar la experiencia Android.
