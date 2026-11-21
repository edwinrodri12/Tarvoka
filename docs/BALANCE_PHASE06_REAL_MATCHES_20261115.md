# TARVOKA — Fase 06: valor de las 32 unidades en partidas ejecutadas por Godot 4.3

**Fecha:** 15 de noviembre de 2026. **Estado:** análisis cuantitativo aprobado como test de reglas y telemetría, **no** aprobación de balance competitivo. [GitHub Actions #43739107953 (PASS)](https://github.com/edwinrodri12/Tarvoka/actions/runs/43739107953). [PR #389 (DRAFT)](https://github.com/edwinrodri12/Tarvoka/pull/389).

## Resumen del ensayo

Se ejecutaron **232 partidas de dos bandos controlados por BasicAI**, con **45.850 acciones**, **8.980 compras**, **14.128 ataques**, **21.729 movimientos**, **1.105 reabastecimientos**, **1.299 cambios de dueño de ciudad**. Hubo **seis victorias por eliminación** y **226 partidas todavía abiertas** al horizonte de observación. No son partidas humanas ni multijugador de ocho.

- **48 partidas sin intervención**: 4 escenarios (abierto, bosque, puentes, costa) × dos iniciadores × dos estados de niebla × 3 climas, hasta **32 medias fases**. Se efectuaron 12.545 acciones, 2.352 compras, 3.835 ataques, 336 capturas y 270 recargas. **Solo dos partidas terminaron**, una a favor del iniciador y una del respondedor.
- **92 comparaciones A/B = 184 partidas** adicionales. Costa: 32 roles × ambos colores = **64 pares**; se fuerza una compra legal `BattleSession.purchase` en un lado del par, el otro **conserva los créditos**; después ambas variantes siguen con la misma BasicAI, hasta 20 medias fases. A/B adicional con **siete soldados × dos mapas (bosque nevado y puentes lluviosos) × dos colores = 28 pares**, hasta 28 medias fases. Los soldados reciben **seis muestras** de compra forzada; los otros roles **dos muestras**. Esto es un estudio de causalidad inicial de **decisión de compra** frente a no intervenir, no una estimación estable de utilidad universal por clase.
- **32×32 combinaciones de atacante/defensor** y tres coberturas estudiadas; **1.296 intercambios de ataque permitidos por el motor** según alcance/domino; las otras combinaciones no pueden atacar por dominio, arma o alcance. Se calcula daño y contraataque por HP/precio, diferenciando dron consumible, sin inventar ataques imposibles.

**Material al corte:** `créditos en caja + suma(precio_unidad × HP_actual/HP_máximo)` de las unidades supervivientes. Refleja capital invertido y salud, pero no ubicación, visión, cobertura, control del mar, capacidad de captura, munición en reserva ni posibilidades tácticas futuras. La métrica A/B en la tabla es la **diferencia en la ventaja material propia-vs-rival** de comprar frente a no comprar; no es ganancia neta por unidad ni ranking de unidades.

### Desigualdad entre mapas en partidas naturales (n=12 cada uno)

| Escenario | Diferencia media absoluta de material | Ventaja media *firmada* de quien empieza | Partidas con más material para iniciador |
|---|---:|---:|---:|
| Campo abierto | 1.069 | +393 | 8/12 |
| Bosque de las Dos Rutas | 2.947 | **+2.111** | **10/12** |
| Puentes de la Cuenca | **3.901** | +7 | 6/12 |
| Costa de las Dos Bahías | 2.912 | −1.078 | 4/12 |

El signo positivo favorece a quien comienza; el negativo, a quien responde. En **Puentes**, el primer jugador tuvo media **+2.100 sin niebla**, frente a **−2.085 con niebla** (seis muestras de cada). Estos patrones justifican una auditoría de visibilidad, rutas y captura en vez de subsidios automáticos al segundo jugador. Las diferencias absolutas no constituyen por sí solas una prueba de mapa injusto.

### La captura y el sesgo de compras

Capturas durante **las 232 partidas** (suma **1.299**): **Rastreador 679 (52,3 %)**, **Guardia 320 (24,6 %)**, **Asaltante 252 (19,4 %)**, **Ingeniero 48 (3,7 %)**. Ninguna otra clase puede capturar en `main`. En las **48 partidas naturales**: **Rastreador 479 compras**, Rompedor **328**, Asaltante **289**, Vehículo logístico **210**, Ingeniero **184**; nueve clases jamás compradas espontáneamente (Lanzacohetes múltiple, Munición merodeadora, Bombardero, Lancha misilera, Corbeta, Fragata, Destructor, Submarino, Buque de desembarco). El orden predeterminado de compra de BasicAI y que algunos roles estén en el ejército inicial distorsionan las cifras brutas de ataques.

**Mecánica decisiva:** en `main`, una unidad elegible se apodera de una ciudad **al finalizar su turno en la casilla**, sin progreso de captura multivuelta. Un Rastreador de **150 créditos**, movimiento **4**, visión **5** puede activar una renta de **250 créditos por turno propio**. La captura progresiva y cooperación de varias infanterías, previstas conceptualmente, **no están implementadas en main**. Corregir esto mediante experimentos y reglas de ocupación puede tener más impacto que pequeños ajustes de daño.

## Auditoría detallada de las 32 clases

**Columnas de evidencia:** «Compras naturales» = solo las 48 partidas sin intervención; «Capturas» = total de 232; «Muestras» = compras forzadas en escenarios A/B; «Ataques forzados» y «Daño forzado» = actividad de **solo la unidad añadida**; «Supervivencia» = al corte; «Δ material» = ventaja propia-vs-rival del escenario compra menos escenario ahorro, medida en créditos y redondeada, con muestras **insuficientes para clasificarlas estadísticamente**; «Objetivos alcanzables» = número de **clases** atacables según dominio en la matriz de duelos, no enemigos encontrados en los mapas.

| Clase | Precio | Compras naturales | Capturas | Muestras | Ataques forzados | HP infligidos forzados | Sobrevive | Δ material medio | Objetivos alcanzables |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Guardia (`line`) | 200 | 84 | 320 | 6 | 8 | 32 | 0/6 | -213 | 16 |
| Rastreador (`scout`) | 150 | 479 | 679 | 6 | 0 | 0 | 0/6 | -2854 | 16 |
| Baluarte (`bulwark`) | 350 | 53 | 0 | 6 | 11 | 27 | 0/6 | -4034 | 16 |
| Rompedor (`piercer`) | 300 | 328 | 0 | 6 | 10 | 36 | 0/6 | -2244 | 16 |
| Lanzador (`artillery`) | 400 | 41 | 0 | 6 | 2 | 10 | 0/6 | -1638 | 16 |
| Asaltante (`assault`) | 250 | 289 | 252 | 6 | 8 | 32 | 0/6 | +0 | 16 |
| Ingeniero (`engineer`) | 250 | 184 | 48 | 6 | 2 | 4 | 0/6 | -1908 | 16 |
| APC (`apc`) | 300 | 10 | 0 | 2 | 2 | 4 | 0/2 | -1574 | 16 |
| IFV (`ifv`) | 500 | 67 | 0 | 2 | 8 | 30 | 0/2 | +1346 | 16 |
| Tanque principal (`tank`) | 750 | 97 | 0 | 2 | 11 | 68 | 2/2 | -118 | 16 |
| Artillería autopropulsada (`spg`) | 650 | 82 | 0 | 2 | 2 | 14 | 0/2 | +3887 | 16 |
| Lanzacohetes múltiple (`mlrs`) | 850 | 0 | 0 | 2 | 2 | 12 | 0/2 | -4401 | 16 |
| Antiaéreo móvil (`mobile_aa`) | 500 | 141 | 0 | 2 | 4 | 20 | 0/2 | -4130 | 8 |
| Batería SAM (`sam`) | 900 | 50 | 0 | 2 | 6 | 28 | 0/2 | -4144 | 8 |
| Guerra electrónica (`ew`) | 550 | 1 | 0 | 2 | 0 | 0 | 0/2 | -1724 | 0 |
| Vehículo logístico (`logistics`) | 300 | 210 | 0 | 2 | 0 | 0 | 0/2 | -6172 | 0 |
| Dron de reconocimiento (`uav_recon`) | 250 | 28 | 0 | 2 | 0 | 0 | 0/2 | -965 | 0 |
| Dron FPV (`fpv`) | 200 | 148 | 0 | 2 | 0 | 0 | 0/2 | -915 | 16 |
| Munición merodeadora (`loitering`) | 350 | 0 | 0 | 2 | 0 | 0 | 0/2 | -1065 | 16 |
| Dron de combate (`ucav`) | 800 | 1 | 0 | 2 | 6 | 22 | 0/2 | +951 | 24 |
| Helicóptero de ataque (`attack_heli`) | 700 | 13 | 0 | 2 | 8 | 34 | 0/2 | +487 | 16 |
| Helicóptero de transporte (`transport_heli`) | 500 | 8 | 0 | 2 | 0 | 0 | 0/2 | +371 | 0 |
| Caza (`fighter`) | 1000 | 30 | 0 | 2 | 10 | 58 | 0/2 | -925 | 24 |
| Bombardero (`bomber`) | 1400 | 0 | 0 | 2 | 6 | 44 | 0/2 | +14 | 24 |
| Patrullero (`patrol`) | 500 | 3 | 0 | 2 | 2 | 8 | 2/2 | -6608 | 16 |
| Lancha misilera (`missile_boat`) | 700 | 0 | 0 | 2 | 0 | 0 | 2/2 | -8090 | 8 |
| Corbeta (`corvette`) | 1000 | 0 | 0 | 2 | 6 | 22 | 2/2 | -7796 | 16 |
| Fragata (`frigate`) | 1500 | 0 | 0 | 2 | 8 | 32 | 2/2 | -7510 | 16 |
| Destructor (`destroyer`) | 2000 | 0 | 0 | 2 | 14 | 114 | 2/2 | -151 | 32 |
| Submarino (`submarine`) | 1700 | 0 | 0 | 2 | 0 | 0 | 2/2 | -8495 | 8 |
| Buque de desembarco (`landing_ship`) | 900 | 0 | 0 | 2 | 0 | 0 | 2/2 | +619 | 0 |
| USV naval (`usv`) | 300 | 5 | 0 | 2 | 0 | 0 | 0/2 | +69 | 8 |

**Cautelas de interpretación:** los valores de «Δ material» pueden ser grandes y de signos inestables porque forzar una compra altera qué fabrica a continuación la IA, ocupa una única casilla de fábrica, cambia la capacidad de conquista indirectamente y utiliza escenarios espejo de muestra pequeña. **El Asaltante produjo Δ=0 porque la intervención coincidió con la compra que ya prefería la IA en esos escenarios**, no porque sea una unidad indiferente para jugar. La prueba naval no evalúa control de objetivos marítimos ni desembarco; casi ningún buque puede producir ingresos urbanos aunque gane intercambios navales.

## Lectura de diseño, por familias

### Siete soldados
1. **Guardia** (200, 10 HP, ATQ 5, movimiento 3) es la referencia robusta y barata; captura **320 ciudades** en la muestra. Conserva el valor de infantería estándar.
2. **Rastreador** (150, 6 HP, ATQ 2, movimiento 4, visión 5) es el principal capturador (**679**) y primera compra de IA (**479 en 48 partidas**). Su potencia económica procede de **velocidad+costo+captura instantánea**, no de ganar duelos (la muestra de unidades inyectadas perdió 36 HP y nunca disparó). **Prioridad alta: cambiar experimento de captura y adquisición IA, sin nerf directo de visión**.
3. **Asaltante** (250, 9 HP, ATQ 5, movimiento 3) es numéricamente eclipsado por Guardia hasta que la habilidad urbana tenga efecto. El prototipo de PR #384 ignora **+1 cobertura de ciudad** y pasó pruebas dirigidas (24 de 30 ataques aumentaron 1 HP). Se necesitan partidas completas con esa propuesta antes de incorporarla.
4. **Rompedor** (300, 8 HP, ATQ 4, movimiento 3) sí tiene **+4 ATQ contra Baluarte**, pero el bono **+2 contra tanque G09** está en PR #328, pendiente; tampoco captura en `main`, mientras PR #156 propone corregirlo. No juzgar antiblindaje total sin integrar esas ramas.
5. **Baluarte** (350, 12 HP, DEF 2, movimiento 2) ofrece resistencia y cobertura pero compra difícil y no captura; los duelos aislados no acreditan su valor de proteger zonas/aliados. Prueba futura: sostener un cuello de botella y cuánto retrasa la progresión enemiga.
6. **Lanzador** (400, 7 HP, ATQ 6, rango **exactamente 2**, movimiento 2, sin contrataque) infligió **10 HP con solo 2 disparos** en seis compras forzadas; el punto ciego y la IA de posicionamiento pueden explicar su bajo uso, independientemente de que la matriz de disparo sea favorable. Medir escolta y control de distancia antes de tocar costo.
7. **Ingeniero** (250, 7 HP, ATQ 2, movimiento 2) capturó **48 ciudades** pero tiene capacidad de reparación aún ausente de `main`. **PR #320** ya implementó **+3 HP a 35 créditos/HP**, HUD y pruebas; **PR #323** ofrece IA para desplazar Ingenieros. No crear otro reparador, y no concluir que el Ingeniero definitivo carece de función por los números de esta rama.

### Vehículos y artillería terrestres
- **APC/IFV**: funciones de transporte real diseñadas e implementadas en PR drafts **#335 (APC 2 pasajeros)** y **#339 (IFV 1 pasajero)**; valor de transporte/ciudad no medido todavía en `main`.
- **Tanque principal (G09)**: domina muchas acciones de ataque en las partidas de IA y ya forma parte del ejército inicial simétrico; por eso sus cifras globales de daño no son comparables a las compras esporádicas. Necesita antitanque funcional y posiciones vulnerables, no solo menos HP.
- **Artillería autopropulsada/Lanzacohetes múltiple**: gran poder por disparo pero posicionamiento, cobertura y rango mínimo muy relevantes en mapas 10×8; lanzacohetes no se compró espontáneamente.
- **Antiaéreo móvil y SAM**: contra objetivos aéreos solamente. Un daño alto a aeronaves no significa utilidad garantizada si no hay amenaza aérea cercana. La IA ya responde parcialmente al avistamiento.
- **Guerra electrónica**: costo 550, ataque 0, interferencia no implementada; con las reglas actuales solo ofrece visión/movimiento, por lo que es una capacidad incompleta.
- **Vehículo logístico**: costo 300, ataque 0, **sí reabastece munición y combustible** (no HP). No mezclarlo con el Ingeniero ni juzgarlo por DPS.

### Aeronaves y drones
- **Dron ISR**: ataque 0 pero visión 7, importante bajo niebla; requiere comparar exposición/fuga de información, no daño.
- **FPV, munición merodeadora**: se destruyen al atacar; su coste se pierde entero, por lo que debe incluirse el beneficio de elegir un objetivo, la amenaza de contraataque y distancia.
- **Dron de combate, helicóptero de ataque, caza**: posibilidades diferentes por **dominios objetivo, coste, movilidad y rango**; el caza combate aire+suelo pero cuesta 1.000; UCAV ataca suelo+mar por 800; helicóptero ataca tierra por 700.
- **Bombardero**: costo 1.400, mucho ATQ individual pero ataque en área pendiente; cero compras naturales; no es prueba de sobreprecio hasta que su función central exista.
- **Helicóptero de transporte**: costo 500, sin ataque ni embarque operativo en `main`; IA puede comprarlo por prioridad de fabricante aunque no tenga misión. La alternativa experimental de PR #384 deja de comprarlo en ese presupuesto.

### Buques de guerra
- **Patrullero, Lancha misilera, Corbeta, Fragata, Destructor**: gradaciones de alcance, protección AA y ataque naval/costero. En mapas de la muestra las ciudades están en tierra, por lo que el control marítimo tiene **escaso retorno económico directo**: se necesitan objetivos y geografía naval.
- **Fragata vs Submarino: redundancia dura actual.** Fragata cuesta **1.500**, tiene **16 HP**, ATQ 8, DEF 2, visión 5, rango 1–3, munición 7 y capacidad naval+aérea; Submarino cuesta **1.700**, 12 HP, ATQ 8, DEF 1, visión 3, rango 1–2, munición 4 y solo daño naval. Fragata también lleva más combustible y tiene mejor reacción. El sigilo/sonar y la ventaja submarina todavía no están programados; **no se debe equilibrar solo con precio sin desarrollar el sigilo y la detección**.
- **Buque desembarco**: precio 900, ataque 0, todavía no transporta soldados; no cumple su finalidad comercial.
- **USV**: dron naval de un solo impacto; debe probarse contra buques de distintos HP y protección, ya que una vida útil de un disparo altera la eficiencia económica.

## Prioridades de desarrollo y pruebas siguientes

1. **Captura multivuelta y captura conjunta**: prototipo A/B con Rastreador, Guardia, Asaltante, Rompedor e Ingeniero. Validar economía, protección de ciudad, acumulación de progreso, tiempos de reocupación y que no se puedan apilar tropas ilegalmente. No cambiar números hasta comprobar la efectividad.
2. **Reutilizar PRs existentes, no duplicar sistemas**: Ingeniero #320/#323; Rompedor antitanque #328/#333 y captura #156; transportes #335/#339; Asaltante urbano #384. Medir partidas emparejadas con la misma base y adversario tras integración cuidadosa.
3. **IA situacional**: evitar la compra espontánea de clases sin habilidad activa; no sobrerreclutar Rastreadores si hace falta defender ciudades contra blindados; mejorar posiciones del Lanzador y desplazamientos de apoyo.
4. **Mapa y economía**: revisar la ventaja firmada en bosque, la inversión por niebla en puentes y desarrollar objetivos navales para que barcos no sean lujo desconectado del ingreso. Probar 24×18 y 40×30 antes de validar economía comercial.
5. **No emitir balance definitivo de ocho jugadores ni veterancia/tecnología II–III** hasta que esas mecánicas sean auténticas, se puedan testear y existan partidas humanas con diversas estrategias.

**Estado:** esta auditoría es un PR de investigación **DRAFT**; no cambia valores base, bonos de ocho facciones, reglas activas ni el APK. Los resultados se basan en IA determinista, muestras limitadas de compra forzada y un conjunto de cuatro escenarios de 10×8, no pueden extrapolarse directamente a partidas humanas ni al multijugador futuro.
