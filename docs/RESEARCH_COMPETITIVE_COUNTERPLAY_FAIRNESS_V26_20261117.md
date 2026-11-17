# TARVOKA — Investigación profunda: equilibrio competitivo sin handicaps ni pérdida de jugabilidad (v2.6)

**Fecha: 17 noviembre 2026. Estado: propuesta de investigación y diseño, no reglas integradas en main.**
**Decisión principal:** recomendamos **equilibrio por contrajuego accesible + mapas certificados + pruebas iterativas de contraestrategias (liga de bots)**, nunca una compensación oculta por ir perdiendo, un nerfeo universal del jugador que comienza primero ni la pretensión de igualar todas las estadísticas.

## 1. Qué significa que “todo pueda pasar”

Dos personas de habilidad similar deben tener oportunidades comparables al iniciar una partida, sin que el color, el turno, el comandante o la disposición de edificios garanticen la victoria. Una ventaja obtenida porque alguien tomó una ciudad, defendió bien o coordinó una ofensiva es **merecida** y puede ser decisiva. No se debe diluir esa ventaja regalando créditos, tropas o daño al rezagado.

La meta útil no es que todos los enfrentamientos individuales sean 50/50: una estrategia de blindados puede perder contra una antiblindaje, la antiblindaje contra movilidad/hostigamiento y esta contra una fuerza combinada bien defendida. Lo importante es que existan **varias rutas ganadoras, contramedidas disponibles a tiempo, y decisiones de recuperación creíbles**. Un estado de partida puede estar perdido por errores; lo inaceptable es que **la elección inicial del rival sea una victoria forzosa y sin respuesta viable**.

Un videojuego determinista y finito no permite prometer matemáticamente que jamás exista una estrategia ganadora con juego perfecto. Podemos **buscar y eliminar ventajas explotables, reproducir secuencias abusivas y estudiar la adaptación del metajuego**.

## 2. Evidencia externa contrastada

| Fuente | Qué aporta | Adaptación razonada a TARVOKA |
|---|---|---|
| Advance Wars By Web, FAQ oficial https://awbw.amarriner.com/guide.php | Reconoce FTA; compensa con unidades predesplegadas en ciertos mapas; advierte sobre comandantes sistemáticamente superiores y listas de exclusión competitiva | NO copiar ciegamente compensaciones. Certificar cada mapa y no usar dinero/unidades extra sin causa medida |
| AWBW Mapmaking, FTA https://thegamerasd.github.io/AWBW-Mapmaking-Guide/beginner/introduction_to_fta.html | Diferencia contramedidas según 2 o 3 bases y ubicación de puntos disputados | Evaluar orden de llegada a edificios neutrales y tiempo de captura por bando antes de ajustar créditos |
| AWBW Mapmaking, mapas https://thegamerasd.github.io/AWBW-Mapmaking-Guide/beginner/introduction_to_mapmaking.html | Simetría, demasiadas bases generan estancamiento, bases neutrales disputadas pueden producir efecto bola de nieve, HQ ubicados para cerrar una derrota real | Distribuir bases fijas por acceso comparable; limitar producción por tamaño; investigar victoria por HQ |
| AWBW criterios https://awbw.amarriner.com/mapcat_descriptions.php | Calidad combina balance, dinamismo y decisiones significativas, no solo tasa de victoria | Medir ritmo, calidad de decisiones, diversidad y duración junto al win rate |
| Kavanagh et al., Balancing Turn-Based Games with Chained Strategy Generation (2019/2021), Univ. Glasgow https://eprints.gla.ac.uk/197167/ | Generación de secuencias de estrategias y mejores respuestas; detecta estrategias dominantes y opciones jamás viables | “Liga de contramedidas”: enfrentar cada estrategia ganadora con nuevas estrategias diseñadas para derrotarla |
| Hernandez et al., Metagame Autobalancing for Competitive Multiplayer Games (2020), Univ. York https://pure.york.ac.uk/portal/en/publications/metagame-autobalancing-for-competitive-multiplayer-games/ | El objetivo del metajuego puede representarse como grafo de respuestas y optimizarse más allá de 50% global | Crear una matriz de counters e incentivos; no perseguir que las ocho facciones tengan idéntico daño |
| Rupp & Eckert, Level the Level (2025) https://arxiv.org/abs/2503.24099 | Es posible compensar arquetipos asimétricos **desde el diseño del mapa**, evitando cambiar directamente sus habilidades | Ajustar posiciones y rutas de acceso, topografía, edificios y objetivos antes de quitar identidad a facciones |
| Becker & Görlich, What is Game Balancing? (2020) https://paradigmplus.itiud.org/volume1/number1/becker/ | Viabilidad, contrajuego, decisiones interesantes, percepción de justicia y que ganar por buen juego debe importar | Rechazar rubber-banding invisible y condiciones que producen partidas interminables |
| TrueSkill, Microsoft Research https://www.microsoft.com/en-us/research/project/trueskill-ranking-system/ | Permite estimar habilidad, que puede confundirse con una ventaja de facción al analizar resultados humanos | Una vez exista PvP, comparar por habilidad; no cambiar stats basándose solo en win rate bruto |
| Hex, swap rule https://www.mseymour.ca/hex_book/hexstrat0.html | El segundo puede elegir lado tras una jugada inicial; evita ciertas ventajas extremas | **No** trasladar la regla al combate normal (interrumpe identidad/experiencia). Opcional en formato competitivo especial, no necesario de entrada |

## 3. Evidencia comprobada del propio TARVOKA: dónde está el problema

Fuente interna: [informe v2.5](https://github.com/edwinrodri12/Tarvoka/blob/experiment/mirrored-opening-balance-v25-20261117/docs/COMPETITIVE_OPENING_MIRROR_AB_V25_20261117.md); [CI 144 partidas, 4/4 PASS](https://github.com/edwinrodri12/Tarvoka/actions/runs/44128185983).

- Dos bandos arrancan con **2.500 créditos iguales**. El segundo cobra **solo sus ciudades** al entrar en su primer turno y el primero al entrar en el segundo suyo. Ya existe: no añadir doble cobro.
- En 10×8 con políticas expansión/presión/blindados, el blindado ganó **7/8** en control. Normalizando desempates reflejados, ganó **8/8**. Son muestras deterministas y limitadas, NO pronósticos sobre habilidad humana ni poderes de ocho facciones.
- El límite opcional de **3 órdenes** para el primer jugador no resolvió el problema. Con desempates simétricos, el primer jugador ganó **10/12** en 10×8. **No activar este límite automáticamente por balance**.
- Desempates normalizados de la IA dieron **0/18** discordancias entre casos espejo, pero en 24×18 **24/24** partidas terminaron sin ganador en el límite de 52 medias fases. La geometría inicial era simétrica: hay que distinguir IA imparcial de IA que logra partidas dinámicas.
- En `main`, `UrbanEconomy.producer_for("piercer",true) = "armor_plant"`. Esto contradice el diseño aprobado de **Rompedor en Cuartel de Infantería nivel I**. En los ensayos v21, cada bando YA comienza con **un Rompedor**, pero **no puede reclutar más desde su Cuartel**; en 10×8 las plantas de blindados comienzan neutrales. La disponibilidad de reemplazos antitanque es por tanto una barrera concreta.
- El `piercer` actual cuesta **300**, 8 HP, ataque 4; el tanque cuesta **750**, 14 HP, ataque 8, defensa 2. Contra un tanque en pradera, un Rompedor aislado hacía 2 de daño y recibía hasta 4 de contraataque. Con +2 investigado, el golpe hacía 4. Cuatro Rompedores concentrados y flanqueando sí destruyeron un tanque en pradera/bosque con tecnología; esta alternativa no es gratis (cuatro Rompedores = 1.200 de reclutamiento).
- El laboratorio de tecnología requería **650 + 1.050 + 450 = 2.150 créditos** para elevar la planta a nivel III e investigar +2, y tres oportunidades de producción. Fue económicamente tardío: en 24 partidas con investigación la doctrina presión cayó de **1V/4D/7 sin resolver** a **0V/7D/5 sin resolver**. No interpretar el 0V como que +2 no funciona; funciona tácticamente, pero la ruta de acceso consume dinero y producción.

**Hipótesis principal, aún no demostrada causalmente:** reparar el circuito temprano de contramedidas y la progresión de Cuartel tiene más potencial que nerfear tanques o compensar al segundo jugador con extras.

## 4. Método de equilibrio recomendado: arquitectura de 5 capas

### Capa A — Contrajuego disponible a tiempo

Para TODAS las unidades de alto impacto registrar:
- `first_threat_turn`: primer turno propio en que puede aparecer y atacar legalmente la amenaza después de pagar desbloqueos y desplazarla;
- `first_counter_turn`: primer turno propio en que el rival puede obtener y desplegar legalmente al menos una respuesta eficaz;
- `total_counter_cost`: precio de tropas + prerequisitos + oportunidad de producción y de movilidad; NO mirar solo el costo del botón;
- `time_to_engage`: distancia efectiva con terrenos, clima, combustible y munición;
- `terrain_response`: respuesta en llanura, bosque, montaña, puente y urbe;
- `sustained_effect`: daño neto tras contraataques, reabastecimiento y pérdidas.

Ninguna amenaza común debería anular el counter de uso básico por requerir una instalación capturada o una tecnología de varios niveles. Cada amenaza fuerte debe permitir al menos dos clases razonables de respuesta **en distintas condiciones**, por ejemplo: control de zona con bazucas y artillería/hostigamiento aéreo cuando la infraestructura lo permita. No convertir la amenaza en inútil: el tanque debe ser excelente si el rival no responde correctamente.

**Primer experimento obligatorio:** Rompedor `piercer` reclutable legalmente desde `factory` de nivel I por 300 créditos, sin modificar HP, daño ni defensa; espejo con regla actual y tanque nivel II. Comparar reclutamiento legal, turno de disponibilidad, bajas, ciudades, partidas resueltas, pérdidas y victoria.

**Segundo experimento:** si aún faltan counters, investigar la especialización +2 en el **propio Cuartel de Infantería nivel II**, no en planta blindada nivel III. Precio candidato de laboratorio **450** MÁS mejora de nivel II de Cuartel (**400** en V12), total mínimo 850, sin cambiar stats del arma. Separar a/b precio de acceso vs potencia del bono. No aprobar aún estos costes.

### Capa B — Certificación del mapa, sin ayudas secretas

Cada mapa competitivo debe pasar:
- Simetría verificable de terreno, edificios, ciudades inicialmente propias, rutas y ejército inicial (ya existe prueba inicial v24).
- **Tiempo de llegada y captura efectiva** de cada neutral cercano por color, considerando caminos, 2 turnos propios de ocupación, unidades que cruzan y si una ruta puede ser bloqueada.
- Balance de acceso a unidades anti-blindaje/anti-aéreas antes del primer ataque probable del enemigo; evitar una fábrica neutral cuya captura produzca una superioridad económica irreparable.
- Distribución de ciudades neutrales que genere varias decisiones: centro disputado y rutas laterales, no un único chokepoint que determine todo ni un exceso de bases que cause spam.
- Tiempo de refuerzo y de ataque al HQ razonables en relación con la escala del mapa y capacidades de movilidad.
- En partidas competitivas, usar mapas prediseñados o semillas generadas **antes** de la partida y filtradas automáticamente; para juego casual dejar mapa aleatorio abierto. No reequilibrar rutas o ingresos secretamente una vez iniciada la partida.

El compensador de iniciativa **por mapa** será una última medida visible, si las pruebas muestran sesgo consistente tras corregir rutas y counters. Ajustar primero colocación/tiempos; si persiste el sesgo, probar un modesto punto de despliegue/celda equivalente o compensación de propiedad inicial y verificarla en ambos sentidos. No aplicar otra cuota universal de acciones ni dinero.

### Capa C — Finales satisfactorios con contrajuego

La condición actual por **eliminación total** y los límites de laboratorio producen demasiados resultados censurados en 24×18. Es contraproducente confundir equilibrio con que nadie pueda ganar.

Candidato: introducir **captura del HQ en dos finales de turnos propios**, con contador muy visible al adversario, posibilidad de negar o revertir la captura en la fase de respuesta, y sin desaparición automática por un solo toque. Permitir igualmente ganar por eliminación total. El HQ tendría que ubicarse de modo que pueda atacarse cuando la defensa ha cedido, sin regalar una victoria súbita por un movimiento aéreo sin respuesta. Los puntos disputados pueden generar presión hacia frentes si el map pool lo permite.

No implantar una victoria automática simplemente porque el cronómetro de simulación se agotó y un bando tenía más ciudades: las **partidas censuradas son datos incompletos**. Probar primero un objetivo verdadero, público y jugable.

### Capa D — Liga de estrategias y mejores respuestas

Aproximación pragmática al método académico de “chained strategy generation”:
1. Bots diversos con políticas **blindados**, **conquista**, **presión antitanque**, **defensa/campamentos**, **reconocimiento/hostigamiento**, **ataque aéreo/naval**, más variantes con ruido **controlado reproducible** para no repetir una única trayectoria fija.
2. Matriz A vs B en cada mapa, lados e iniciativa intercambiados; usar mismo conjunto de semillas para comparar versiones. Registrar separadamente censura y victoria real.
3. Identificar el dominante de cada iteración (mayor rendimiento frente a las demás). Generar una política de **mejor respuesta** con búsqueda limitada, simulación o variantes heurísticas. Añadirla al torneo y repetir.
4. Exigir que **la nueva política derrote al supuesto dominante en algún conjunto razonable de mapas** y no se vuelva ella una doctrina imbatible. Si surge un ciclo A→B→C→A con especializaciones distintas, es una señal positiva de variedad, sin forzar un círculo rígido.
5. No concluir que una unidad es inviable porque un solo bot no sabe utilizarla; probar bots especialistas y humanos.

El resultado debe ser una **red de opciones viables** (grafo de contramedidas) y una lista de abusos reproduci-bles, no una clasificación final de unidades en un solo escalar de “poder”.

### Capa E — Estadística confiable y experiencia humana

Auditoría automática por candidato: piloto de 24–48 parejas espejo (cada pareja mantiene mapa y semilla al invertir los bandos); finalista 100–200 o más parejas con varias semillas **realmente distintas**, mapas y rivales. El resultado de partidas duplicadas con el mismo bot determinista **NO** aporta observaciones independientes. Probar potencias de bots distintas para evitar sobreajustar al algoritmo actual.

Métricas separadas:
- **Integridad (obligatoria):** dinero exacto, ningún turno extra, captura/reabastecimiento/curación sin pagar, no solapamiento ilegal, no visión oculta, XP/bono de comandante sin duplicarse.
- **Equidad de iniciativa:** tasa de victoria ajustada por mapa, política/facción y habilidad humana. Banda objetivo provisional **45–55%** para jugador inicial en emparejamientos de igual habilidad, con tamaño muestral suficiente y análisis de incertidumbre, no como un “parámetro mágico”.
- **Metajuego:** tasa de victoria por estrategia y **disponibilidad de counters**, entropía/diversidad de políticas viables, capacidad de derrotar a un dominante con plan alternativo sin ventaja artificial.
- **Partidas terminadas:** resolución genuina dentro de los turnos/duración objetivo por tamaño, estancamientos y juego sin combate. Fijar objetivos de duración después de pruebas humanas; meta provisional **al menos 85–90% resueltas** bajo un límite razonable que se adapte al tamaño.
- **Diversión y agencia:** número de decisiones importantes, variedad de unidades efectivamente utilizadas, momentos en que el jugador pudo reaccionar, sensación de sorpresa justa y la claridad del motivo por el cual perdió.
- **Facciones/comandantes:** matriz dirigida 8×8 según mapa, lado y habilidad; interacciones de pasivos + activos + XP + terreno/clima + suministros/campamentos. No esperar que todas las parejas individuales sean 50/50; exigir opciones para adaptarse, rotación de especialidades y ausencia de combinaciones abusivas sin respuesta.

Ejemplo de incertidumbre: una IA ganando **8/8** da intervalo Wilson aproximado de **67,6–100%** para escenarios independientes equiparables (95%), y **7/8**, **52,9–97,8%**. En nuestros ensayos deterministas reales son aún menos generalizables. **Son alertas rojas de regresión, no evidencia de que el humano siempre gane con esa táctica.**

## 5. Métodos considerados y descartados por ahora

| Candidato | Veredicto | Por qué |
|---|---|---|
| Dar dinero/tropas al jugador que va perdiendo | **Descartar** | Castiga las decisiones buenas del rival y oculta el sistema |
| Nerfear globalmente tanques y comandantes fuertes sin analizar acceso a counters | **Descartar** | Reduce identidad, diversión y profundidad táctica; podría matar a unidades viables |
| Primer jugador limitado universalmente a 3 órdenes | **No adoptar** | A/B v25 empeoró iniciativa en 10×8 cuando se combinó con desempates simétricos |
| Dar otro ingreso al segundo jugador | **No adoptar** | Ya cobra su ingreso de ciudades al iniciar primera fase, podría sobrecompensar |
| Todo el mapa/ejércitos perfectamente idénticos | **No exigir** | Se sacrificaría diversidad, y la simetría de terreno por sí sola no garantizó juego dinámico |
| Variar suerte/daño para que “todo pueda pasar” | **No adoptar como parche** | El azar puede romper resultados merecidos y la sensación de control; si hay aleatoriedad, que sea explícita y común para ambos |
| Restringir personajes por tier al estilo AWBW | **Plan B solo competitivo** | Soluciona torneo pero limita elección y identidad; priorizar diseño de counters primero |
| Partidas competitivas de dos mapas intercambiando lados (serie ida/vuelta) | **Opcional torneo/ranking** | Mejora justicia agregada sin cambiar reglas de una batalla; no forzarlo al jugador casual |
| Ajustar mapa para cada facción y certificado antes de jugar | **Prioridad alta** | Preserva identidad de facciones y reglas y es avalado por investigaciones de nivel asimétrico |
| Programar una liga de bots que busque counters contra el mejor | **Prioridad máxima estructural** | Detecta metas emergentes y permite corregir una variable con evidencia sin quitar agencia |

## 6. Hoja de ejecución (secuencial, sin cambios simultáneos)

**E0 — Línea base:** cerrar informes v21–v25 y registrar todos los errores y casos de victoria/censura con semilla/posición/replay, nivel y economía. Congelar un snapshot del motor experimental para A/B.

**E1 — Contramedida de nivel I:** mover el Rompedor SOLO en una rama experimental a producción legal de Cuartel nivel I. Ejecutar mapa pequeño 10×8 y 24×18 espejo, conservar costes y stats idénticos. Criterio: reclutamiento temprano real, no compras ficticias, sin desequilibrar infantería vs infantería.

**E2 — Contramedidas adicionales si E1 insuficiente:** comparar especialización de Rompedor por el propio Cuartel LII, caminos alternativos de artillería/FPV y tácticas de flanqueo, con gastos completos y reacciones reales. Solo entonces considerar ajustes mínimos de HP/ataque/defensa del tanque.

**E3 — Objetivo HQ jugable y seguro:** capturar en varios turnos propios con aviso visible; simular 24×18 en bosque/llanura, valorar si caen censuras sin crear rush de HQ invencible.

**E4 — Liga de bots y mapas certificados:** best response iterativo y filtro de mapas por acceso y objetivos. Una solución debe mejorar diversidad, resolución y equidad **al mismo tiempo**.

**E5 — Matriz facciones/CO:** desplegar las ocho facciones en el motor experimental, probar habilidades con los mismos criterios y humanos de distintos niveles. No incorporar una habilidad hasta tener reacción, límite, coste y telemetría.

## 7. Decisión propuesta para la dirección de TARVOKA

**Adoptar el método, no un handicap:**
> La estrategia correcta no será siempre “compra el mejor tanque” ni “escoge el comandante X”, sino “observa terreno y rival, calcula economía y tiempos, elige composición y conserva una opción de respuesta”. La ventaja que gane un jugador con esas decisiones SÍ debe importar.

Lo que está **definido como recomendación**: mantener ingreso actual; no imponer cap3; priorizar producción Rompedor L1; usar mapas validados y bots adaptativos; evitar nerfs arbitrarios, comeback gratis y victorias por timeout.

Lo que **todavía requiere pruebas y aprobación**: mover el Rompedor al motor real, costes finales de especialización, victoria por HQ, umbrales competitivos definitivos y despliegue de las ocho facciones. Todo esto está fuera de main y del APK por ahora.
