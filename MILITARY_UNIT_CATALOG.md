# TARVOKA — Catálogo militar moderno v0.1

> **REVISIÓN DE REDUNDANCIAS ABIERTA (12-nov-2026):** El usuario solicitó reducir variantes repetitivas porque habrá niveles de tecnología. Ver [UNIT_ROSTER_AUDIT_V02.md](UNIT_ROSTER_AUDIT_V02.md): propuesta de **24 familias funcionales** (23 de las 32 actuales tras nueve fusiones + posible nueva logística naval), sin descartar capacidades de equipamiento. Esta tabla de 32 IDs queda como **referencia histórica y de compatibilidad**, no como cifra de clases finales que deban implementarse; no tocar estadísticas/IDs de las cinco clases ya programadas sin pruebas.

Fecha: 2026-11-11. **DOCUMENTO DE DISEÑO, NO 32 CLASES PROGRAMADAS.** Identidad creativa confirmada por el usuario: tecnología militar moderna y actual, incluidos sistemas avanzados que ya existen y usan diferentes ejércitos. Drones, guerra electrónica, municiones merodeadoras, defensa antidrones y vehículos navales no tripulados SON modernos, no ciencia ficción.

## Principios

- Tres dominios: **tierra, aire y mar**. La distinción entre unidad tripulada y no tripulada no reemplaza el dominio operativo.
- Catálogo de lanzamiento planeado: **32 clases**. Las cinco que ya están implementadas conservan sus IDs, precios, movimientos y daños actuales; las otras veintisiete son propuestas sujetas a integración gradual.
- Sistemas convencionales y contemporáneos, sin tecnología inventada ni equipos que prometan lo físicamente imposible. Facciones, nombres propios, emblemas y arte originales sin copiar ejércitos reales ni videojuegos ajenos.
- Cada unidad aporta una función o contramedida. Nunca «más caro = victoria automática». El rango de casillas NO es una ficha técnica de armas reales.
- Niebla, detección, edificios y IA tienen que seguir reglas iguales para humanos y computadora; enemigos ocultos no pueden ser atacados ni rastreados clandestinamente.
- La economía (créditos) es solo moneda interna de la partida, sin microtransacciones.
- **[P] = prototipo existente**. **[D] = definido, aún NO programado**. Los números HP, MOV, RNG y precio de [D] son hipótesis de diseño no equilibradas.

### Convenciones de tabla

HP = resistencia; MOV = movimiento en casillas/turno; RNG = rango mínimo–máximo en casillas; G = objetivos terrestres, A = aéreos, M = marítimos. «—» = no realiza ataque directo. Las clases [P] todavía usan un único tipo de unidad en el motor; esta tabla NO añade todavía reglas de dominio.

## 1. Tierra — 16 clases

| ID | Clase | HP | MOV | RNG | Coste | Blanco | Función y contramedidas |
| --- | --- | ---: | ---: | --- | ---: | --- | --- |
| G01 | **Guardia [P]** | 10 | 3 | 1–1 | 200 | G | Infantería generalista, captura ciudades/talleres. |
| G02 | **Asaltante [D]** | 9 | 3 | 1–1 | 250 | G | Infantería urbana; buena en ciudades, débil frente a tanques. Captura. |
| G03 | **Rastreador [P]** | 6 | 4 | 1–1 | 150 | G | Reconocimiento, visión 5; +3 ATQ contra Lanzador en prototipo. Captura. |
| G04 | **Rompedor [P]** | 8 | 3 | 1–1 | 300 | G | Antiblindaje; +4 ATQ contra Baluarte en prototipo. |
| G05 | **Ingeniero de combate [D]** | 7 | 2 | 1–1 | 250 | G | Captura; reparación/despeje de infraestructura con coste y límite. |
| G06 | **Baluarte [P]** | 12 | 2 | 1–1 | 350 | G | Blindado defensivo con DEF 2; no captura. |
| G07 | **Transporte blindado [D]** | 11 | 5 | 1–1 | 300 | G | Traslada 2 escuadras de infantería; autodefensa ligera, no captura. |
| G08 | **Vehículo de combate de infantería [D]** | 11 | 4 | 1–1 | 500 | G/A ligera | Apoyo mecanizado y transporte de 1 escuadra; vulnerable a antiblindaje. |
| G09 | **Tanque de combate principal [D]** | 14 | 4 | 1–1 | 750 | G | Fuerza de choque; alto coste, necesita reconocimiento y apoyo. |
| G10 | **Artillería autopropulsada [D]** | 8 | 3 | 2–4 | 650 | G | Fuego indirecto sobre blanco detectado; rearmado limitado. |
| G11 | **Lanzador [P]** | 7 | 2 | 2–2 | 400 | G | Artillería corta; no ataca adyacente. Conservar comportamiento actual. |
| G12 | **Lanzacohetes múltiple [D]** | 7 | 2 | 3–5 | 850 | G | Salva de apoyo, largo alcance y recarga/coste alto. |
| G13 | **Antiaéreo móvil [D]** | 9 | 3 | 1–3 | 500 | A | Cubre tropas contra drones y helicópteros, vulnerable a ataques terrestres. |
| G14 | **Batería SAM móvil [D]** | 8 | 2 | 2–5 | 900 | A | Defensa contra aviones; requiere detección, débil a corto alcance. |
| G15 | **Vehículo de guerra electrónica [D]** | 7 | 3 | — | 550 | A vía habilidad | Perturbación temporal de ciertos sensores/enlaces; sin destrucción automática. |
| G16 | **Vehículo logístico [D]** | 8 | 4 | — | 300 | — | Munición, reparaciones y combustible bajo restricciones, sin ataque directo. |

## 2. Aire — 8 clases

| ID | Clase | HP | MOV | RNG | Coste | Blanco | Función y contramedidas |
| --- | --- | ---: | ---: | --- | ---: | --- | --- |
| A01 | **Dron de reconocimiento [D]** | 4 | 5 | — | 250 | — | Visión y detección, vulnerable a antidrones y guerra electrónica. |
| A02 | **Dron FPV de ataque [D]** | 2 | 5 | 1–1 | 200 | G | Ataque de un solo uso a objetivo visible; no captura. |
| A03 | **Munición merodeadora [D]** | 2 | 4 | 1–2 | 350 | G | Espera brevemente y realiza ataque único; limitada por detección y contramedidas. |
| A04 | **Dron aéreo de combate reutilizable [D]** | 8 | 6 | 1–2 | 800 | G/M | ISR/ataque, requiere rearmado y puede ser interceptado. |
| A05 | **Helicóptero de ataque [D]** | 10 | 6 | 1–2 | 700 | G | Apoyo cercano y maniobra, vulnerable a defensa antiaérea. |
| A06 | **Helicóptero de transporte [D]** | 9 | 6 | — | 500 | — | Transporta 2 escuadras; solo desembarcados capturan. |
| A07 | **Caza multifunción [D]** | 9 | 8 | 1–2 | 1000 | A/G limitada | Superioridad aérea, combate y ataque secundario de tierra. |
| A08 | **Bombardero táctico [D]** | 11 | 6 | 1–3 | 1400 | G/M | Ataque pesado, coste alto, necesita escolta o supresión de defensa aérea. |

## 3. Mar — 8 clases

| ID | Clase | HP | MOV | RNG | Coste | Blanco | Función y contramedidas |
| --- | --- | ---: | ---: | --- | ---: | --- | --- |
| M01 | **Patrullero [D]** | 10 | 5 | 1–1 | 500 | M ligera/A dron | Control costero y seguridad de convoyes. |
| M02 | **Lancha misilera [D]** | 8 | 6 | 1–3 | 700 | M | Ataque rápido, munición limitada y casco vulnerable. |
| M03 | **Corbeta [D]** | 12 | 4 | 1–2 | 1000 | M/A ligera | Escolta costera y defensa aérea ligera. |
| M04 | **Fragata [D]** | 16 | 4 | 1–3 | 1500 | M/A/submarino | Escolta naval, defensa aérea y antisubmarina. |
| M05 | **Destructor [D]** | 19 | 4 | 2–4 | 2000 | M/A/G costera | Buque capital de alto alcance/coste; necesita apoyo logístico. |
| M06 | **Submarino [D]** | 12 | 4 | 1–2 | 1700 | M | Ocultación y ataque antibuque; vulnerable a sonar/antisubmarinos. |
| M07 | **Buque de desembarco [D]** | 14 | 3 | — | 900 | — | Transporta infantería/vehículos para invasión de costa; no captura. |
| M08 | **Dron naval de superficie (USV) [D]** | 3 | 6 | 1–1 | 300 | M | Reconocimiento/ataque naval de un solo uso. |

**Total: 16 tierra + 8 aire + 8 mar = 32.** Solo Guardia, Rastreador, Baluarte, Rompedor y Lanzador están programadas como combate/pago en el prototipo. Las demás necesitan implementación, pruebas y balance.

## 4. Instalaciones y economía

| Edificio | Producción / beneficio | Estado |
| --- | --- | --- |
| **Ciudad** | +100 créditos por ciudad propia al comenzar siguiente turno | Implementado en modo experimental |
| **Taller genérico** | Produce las 5 unidades actuales, una por turno desocupado | Implementado en modo experimental |
| **Cuartel** | Guardia, Asaltante, Rastreador, Rompedor, Ingeniero | Diseño |
| **Fábrica de blindados** | Baluarte, transporte blindado, vehículo combate infantería, tanque | Diseño |
| **Centro de artillería y defensa** | Lanzador, artillería, lanzacohetes, antiaéreos, SAM, guerra electrónica | Diseño |
| **Centro logístico** | Vehículos de suministro y reparación/reabastecimiento | Diseño |
| **Centro de drones** | Dron de reconocimiento, dron FPV y municiones merodeadoras | Diseño |
| **Aeródromo** | Dron de combate, helicópteros, cazas, bombarderos | Diseño |
| **Astillero** | Buques, submarinos y dron naval USV, exclusivamente en costa navegable | Diseño |
| **Radar / puesto de mando** | Sensor/detección y coordinación, no unidad de ataque gratis | Diseño |

No convertir los 2 talleres genéricos actuales en estos edificios hasta que movilidad por dominio, interfaz, IA y presupuesto de mapa estén listos. Con 300 créditos de inicio y 100 por ciudad los buques de 2,000 créditos NO serían apropiados para partidas de 8 turnos: se requerirán escenarios y economías de escala superior.

## 5. Matriz de contramedidas para que el arsenal resulte divertido

1. Infantería conquista terreno y genera economía; blindados no ocupan instalaciones para capturarlas.
2. Rompedor castiga blindados; un tanque vence a infantería sin defensa antiblindaje, pero necesita reconocimiento.
3. Drones ISR detectan, no atacan ni revelan el mapa ilimitadamente; FPV y municiones merodeadoras consumen su sistema tras una acción exitosa, sin munición infinita.
4. Antiaéreos móviles controlan drones/helicópteros; SAM controla aviones, pero necesita sensores y no sustituye defensa terrestre.
5. Guerra electrónica reduce temporalmente capacidades de los drones susceptibles y tiene límites y respuestas; NO es inmunidad total ni lectura de posiciones ocultas.
6. Artillería castiga posiciones descubiertas a distancia, pero está expuesta en combate cercano; munición/cadencia limitan ataques.
7. Submarinos amenazan barcos grandes y necesitan sonar para ser detectados; fragatas y otras plataformas antisubmarinas son el contrapeso.
8. Un transporte no duplica tropas ni puede capturar sin desembarcarlas; carga, bajas y guardado deben quedar definidos.
9. Cualquier capacidad de atacar aeronaves o submarinos debe declararse explícitamente como atributo del rol y verificarse en motor, UI e IA.

## 6. Capacidades actuales que serán equipamiento, habilidad o apoyo (no clases base adicionales)

- Radar, alerta temprana aérea, satélites y datos: detección y apoyo **limitados** por niebla y sensores, no visión omnisciente.
- Drones embarcados, contramedidas de radio, sensores térmicos, municiones guiadas: módulos/consumibles de unidades existentes.
- Robots terrestres no tripulados y vehículos submarinos no tripulados: tecnología real usada o en experimentación por diferentes ejércitos; **candidatos posteriores** solo si ofrecen mecánica distinta.
- Ciberoperaciones y guerra electrónica: efectos legibles, acotados en turnos, sin anulación opaca de todo el ejército.
- Misiles de gran alcance estratégicos y recursos de teatro: posible apoyo de misión, NO casillas de unidad equivalentes a un escuadrón de infantería.

## 7. Orden de ingeniería (no implementar las 27 clases sin su sistema base)

1. **P0** Validar en teléfono las 5 clases, ciudades, talleres, guardados y accesibilidad; medir riesgo de primer turno (12/12 enfrentamientos anteriores).
2. **P0** Implementar dominios terrestres/aéreos/marítimos, movimiento sobre agua/aire, ocupación por capas y objetivos válidos; evitar que tanque dispare a caza o que buque circule por tierra.
3. **P1** Añadir infantería moderna, blindados, ingeniería, artillería y antiaéreos; ampliar producción especializada y economía.
4. **P1** Integrar dron ISR, FPV, munición merodeadora, helicóptero y contramedidas con estado consumible persistente, neblina justa y prohibición de ataques ilegales.
5. **P1** Añadir transporte, abastecimiento/reparación, aeronaves de mayor alcance y sensores; probar compatibilidad de saves.
6. **P2** Incorporar mapas costeros y navales, astilleros, submarinos, buques y USV con reglas reales de navegación/detección.
7. **P2** Misiones originales, campaña, tutorial de contramedidas, arte, audio, equilibrio con humanos, QA Android y comercialización.

**NOTA CRÍTICA:** el tablero actual 10×8 carece de movilidad naval, capas de aire y reglas de dominio. Este documento ESPECIFICA diseño futuro; no se debe afirmar que esas 27 clases o sus tecnologías están disponibles en una APK.

## 8. Referencias de tecnologías de uso contemporáneo

- Congressional Research Service, informe de sistemas aéreos militares no tripulados, actualizado mayo 2026: https://www.everycrsreport.com/reports/IF12668.html
- OTAN, agencia NSPA, contratos de sistemas antidrón con radar, guerra electromagnética e interceptores, julio 2026: https://www.nspa.nato.int/news/2026/nspa-establishes-several-framework-contracts-for-c-uas.aspx
- Consejo de Seguridad y Defensa Nacional de Ucrania, drones de superficie marítima, enero 2026: https://www.rnbo.gov.ua/en/Diialnist/7382.html
- U.S. Army, adopción de drones en doctrina contemporánea, marzo 2026: https://www.army.mil/article/291361/army_adapts_doctrine_force_wide_integrating_drone_lessons_to_achieve_drone_dominance

Estas referencias justifican categorías de tecnología actuales, **no** los números hipotéticos de daño, movimiento o precios del videojuego.
