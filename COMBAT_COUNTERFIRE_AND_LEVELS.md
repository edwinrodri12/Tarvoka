# TARVOKA — Doctrina de combate, contrafuego y niveles (v0.1 experimental)

**Actualización:** 12 de noviembre de 2026. **Fuente del comportamiento:** `scripts/core/CombatDoctrine.gd`, `BattleActions.gd`, `Turns.gd`, `TacticalHints.gd`, `ModernArsenal.gd`, `UnitRoles.gd`. Este documento separa los sistemas **programados** de las especializaciones **futuras**. El balance de las ocho facciones **permanece inalterado**; los nuevos daños de reacción sí cambian los enfrentamientos y deben validarse con partidas de IA y personas antes de considerarse definitivos.

## 1. Combate en dos pasos: prioridad de quien dispara

**Regla programada en esta rama, experimental:**

1. El atacante solo puede disparar si está vivo, no ha agotado su acción, dispone de munición y el defensor es visible y alcanzable en su dominio y rango. Se aplican primero los atributos ATQ/DEF y las bonificaciones ya existentes. Consumir **una munición** y la acción del atacante.
2. Si el defensor **sobrevive**, todavía tiene munición, **no respondió ya en este turno enemigo**, puede apuntar al tipo de blanco atacante, tiene al atacante en rango mínimo–máximo y **lo puede ver con la niebla actual**, efectúa **una sola respuesta**. La respuesta cuesta una munición real, pero no consume su acción normal cuando vuelva su turno. Se marca `reacted=true`, que se reinicia al comenzar el propio turno.
3. La respuesta está atenuada por el daño recién recibido (HP restante frente a máximo teórico) y por la doctrina de la unidad. Fórmula determinista:

`daño_respuesta = min(HP_atacante, ceil(daño_base_del_defensor × HP_defensor_restante / HP_max_defensor × porcentaje_respuesta / 100))`

Si la fórmula produce menos de 1, una unidad armada, viva y autorizada puede infligir **1 HP** mínimo. Si el defensor fue destruido, no tiene arma, no ve al atacante, carece de munición, ya respondió, no tiene línea de alcance o el ataque es un consumible de un solo uso, la respuesta es **0**. No existe respuesta a una respuesta (sin bucles infinitos).

4. Los drones **FPV, merodeador y USV** siguen consumiéndose al atacar; no se aplica respuesta automática a la explosión consumible. La unidad atacada gasta su munición solo si realmente respondió.
5. El panel previo muestra daño ofensivo y **respuesta potencial máxima**, sin filtrar munición restante, disponibilidad de reacción ni información de niebla del adversario; los resultados reales aparecen después de disparar. IA y jugador comparten reglas, sin RNG de daño oculto.

**Ejemplo exacto al inicio de la partida:** tanque propio **14 HP, ATQ 8, DEF 2** contra tanque idéntico **14 HP, ATQ 8, DEF 2**, ambos a una casilla, con munición. Primer disparo **6 HP** (el defensor queda en 8 HP). Respuesta de tanque **60%**, debilitada por `8/14`: **3 HP** al atacante (queda en 11 HP). El atacante inflige el doble de daño en este intercambio, pero asume riesgo. Los mismos cálculos se aplican al bando rojo cuando inicia.

**Importante:** una plataforma que ya haya disparado en su propio turno puede defenderse **una vez** durante el turno enemigo siguiente, si cumple las condiciones anteriores. Un carro inmovilizado por falta de combustible **sí puede responder** si conserva munición; combustible no es munición. Artillería indirecta y MLRS no responden automáticamente: requieren turno y orden de fuego; no obtienen un tiro instantáneo oculto.

## 2. Ficha completa de las 32 clases

- **T1–T4** = acto de **primera introducción/desbloqueo en campaña**, NO calidad ni daño adicional. El calendario exacto por capítulos permanece en `CAMPAIGN_UNIT_PROGRESSION.md`.
- **Respuesta %** afecta exclusivamente al daño de contrafuego; **NO** aumenta el ataque normal ni las ventajas de facción.
- **Rango** y **blancos** proceden de los perfiles de Godot existentes. Las cinco clases heredadas no muestran dominios explícitos en su perfil original, por lo que sus ataques son terrestres (*). Algunas ventajas/limitaciones de descripción son doctrinales o aspiracionales y se distinguen abajo.

| ID | Clase | Arma/ataque | Alcance | Blanco | Respuesta | T | Fortaleza | Debilidad |
|---|---|---|---|---|---:|---:|---|---|
| G01 | Guardia | Directo | 1–1 | Tierra* | 55% | 1 | Infanteria flexible, control de territorio | Vulnerable a blindados y fuego de apoyo |
| G03 | Rastreador | Directo | 1–1 | Tierra* | 40% | 1 | Reconocimiento y vision amplia | Bajo dano y pocos puntos de vida |
| G06 | Baluarte | Directo | 1–1 | Tierra* | 55% | 1 | Defensa frontal y resistencia | Lento; rompedor lo contrarresta |
| G04 | Rompedor | Directo | 1–1 | Tierra* | 35% | 1 | Contra blindados y baluartes | Expuesto ante infanteria y bombardeo |
| G11 | Lanzador | Indirecto | 2–2 | Tierra* | 0% | 1 | Fuego desde distancia de dos casillas | Sin respuesta inmediata; punto ciego cercano |
| G02 | Asaltante | Directo | 1–1 | ground | 55% | 1 | Presion y captura en zonas urbanas | Muy vulnerable a tanques y artilleria |
| G05 | Ingeniero | Directo | 1–1 | ground | 25% | 1 | Captura y apoyo a infraestructura | Combate deficiente y movimiento limitado |
| G07 | Transporte blindado | Directo | 1–1 | ground | 35% | 2 | Movilidad y escolta ligera | Ataque bajo frente a blindados; carga pendiente |
| G08 | Vehículo de infantería | Directo | 1–1 | ground | 55% | 2 | Apoyo mecanizado y cobertura de escuadras | Pierde frente a tanque y armas pesadas |
| G09 | Tanque principal | Directo | 1–1 | ground | 60% | 2 | Duelo contra vehiculos terrestres blindados | Sin ataque aereo; flancos, apoyo artillero |
| G10 | Artillería autopropulsada | Indirecto | 2–4 | ground | 0% | 2 | Bombardeo terrestre a distancia | No responde; minimo de dos casillas |
| G12 | Lanzacohetes múltiple | Saturación | 3–5 | ground | 0% | 2 | Maximo alcance terrestre | Punto ciego de tres casillas; recarga cara |
| G13 | Antiaéreo móvil | Directo | 1–3 | air | 65% | 2 | Intercepcion de aviones y drones cercanos | No puede atacar unidades terrestres |
| G14 | Batería SAM | Guiado | 2–5 | air | 35% | 3 | Area antiaerea lejana | Punto ciego cercano y ataque no terrestre |
| G15 | Guerra electrónica | Soporte | 1–1 | Tierra* | 0% | 3 | Soporte electronico futuro | Sin arma; interferencia aun no implementada |
| G16 | Vehículo logístico | Soporte | 1–1 | Tierra* | 0% | 1 | Suministro de combustible y municiones | Sin armas; proteger y escoltar |
| A01 | Dron de reconocimiento | Soporte | 1–1 | Tierra* | 0% | 2 | Vision y reconocimiento de area | Sin armas, vulnerable a antiaereo |
| A02 | Dron FPV | Un uso | 1–1 | ground | 0% | 3 | Impacto terrestre economico de un uso | Se destruye al disparar; no anti-aereo |
| A03 | Munición merodeadora | Un uso | 1–2 | ground | 0% | 3 | Ataque remoto limitado a objetivo terrestre | Consumible; no puede interceptar aviones |
| A04 | Dron de combate | Guiado | 1–2 | ground/naval | 25% | 3 | Golpes repetibles a tierra y mar | Vulnerable a defensas aereas y recargas |
| A05 | Helicóptero de ataque | Guiado | 1–2 | ground | 35% | 3 | Ataque terrestre movil | Vulnerable al antiaereo; no combate aire-aire |
| A06 | Helicóptero de transporte | Soporte | 1–1 | Tierra* | 0% | 3 | Insercion y evacuacion futuras | Sin armas ni transporte implementado |
| A07 | Caza multifunción | Guiado | 1–2 | air/ground | 55% | 4 | Superioridad aerea y ataque limitado terrestre | Alto coste y dependencia de combustible |
| A08 | Bombardero táctico | Guiado | 1–3 | ground/naval | 15% | 4 | Gran golpe contra tierra y buques | Sin armas aire-aire; caro y expuesto |
| M01 | Patrullero | Directo | 1–1 | naval/air | 55% | 1 | Defensa costera y anti-drones | Poco poder ante fragatas/destructores |
| M02 | Lancha misilera | Guiado | 1–3 | naval | 30% | 2 | Golpe naval rapido a distancia | Poca resistencia y sin defensa anti-aerea |
| M03 | Corbeta | Directo | 1–2 | naval/air | 55% | 3 | Escolta y defensa anti-aerea | Menor alcance y blindaje que fragata |
| M04 | Fragata | Guiado | 1–3 | naval/air | 50% | 4 | Escorta buques y protege contra aire | Alto coste; vulnerable a ataque submarino futuro |
| M05 | Destructor | Guiado | 2–4 | naval/air/ground | 45% | 4 | Apoyo costero de largo alcance | Punto ciego corto y coste muy alto |
| M06 | Submarino | Guiado | 1–2 | naval | 35% | 4 | Ataque naval especifico | No ataca costa/aire; sigilo pendiente |
| M07 | Buque de desembarco | Soporte | 1–1 | Tierra* | 0% | 2 | Movilidad y desembarco futuro | Sin defensa; carga no implementada |
| M08 | Dron naval USV | Un uso | 1–1 | naval | 0% | 4 | Golpe naval consumible y economico | Se consume al impactar; no tierra/aire |

**Interpretación de porcentajes:** armas directas como carro e IFV responden mejor si están armadas y en alcance; misiles guiados navales/SAM responden a ritmo menor; aeronaves de ataque deben poder apuntar a la unidad que las atacó; fuego indirecto/MLRS y consumibles no generan respuesta instantánea. No hay represalia universal entre dominios.

**Auditoría de tecnologías pendientes:** `ew` todavía no interfiere; `apc`, `ifv`, `transport_heli` y `landing_ship` todavía no transportan; `submarine` todavía no usa ocultación/sonar; `bomber` ataca un solo objetivo; armas de area, reparación, supresión, detección avanzada y habilidades de cada comandante siguen en planificación. El texto narrativo no concede esas habilidades antes de implementarlas. Los bonos antiblindaje y antiunidad existentes de `UnitRoles.gd` se conservan; nuevas matrices de daño contra armadura NO se activan aún.

## 3. Dos ejes de nivel independientes

### A. Escalón de introducción en campaña (T1–T4)

| Nivel | Primer acto | Número de clases nuevas | Finalidad |
|---|---|---:|---|
| T1 | Capítulos 1–10 | 9 | Infantería, exploración, captura, suministros, patrulla y lanzador |
| T2 | Capítulos 11–20 | 9 | Blindados, tanque, artillería, antiaéreo, primeros drones, movilidad de desembarco |
| T3 | Capítulos 21–30 | 8 | Guerra electrónica, ataques consumibles, helicópteros, SAM, corbeta y UCAV |
| T4 | Capítulos 31–40 | 6 | Cazas, bombarderos, submarinos, fragatas, destructores y USV |
| Dominio del arsenal | Capítulos 41–50 | 0 | Crear combinaciones y dominar las contramedidas conocidas |

En escaramuzas y en multijugador **ninguna unidad se bloquea por capítulos**. El escalón tampoco concede bonificaciones de facción.

### B. Veterania por unidad (DISEÑO, NO ACTIVA)

| Nivel individual | Umbral propuesto | Beneficios actuales | Objetivo para futuras pruebas |
|---|---:|---|---|
| 0 · Recluta | 0 XP | Estadísticas base | Unidad recién reclutada |
| 1 · Regular | 15 XP | Sin modificación todavía | Pequeña mejora especializada, no daño global |
| 2 · Veterano | 40 XP | Sin modificación todavía | Mejor supervivencia o utilidad de su rol, según pruebas |
| 3 · Élite | 80 XP | Sin modificación todavía | Una ventaja situacional, legible y contrarrestable |

**Sistema de XP propuesto y todavía no implementado:** por cada HP real infligido +1 XP (hasta 10 por batalla contra el mismo objetivo), destruir un blanco +8, capturar edificio +6, abastecer aliado +4, detectar unidad desconocida +2 (una sola vez por enemigo/partida), evacuar/transportar con éxito +4 cuando la acción exista. Prohibido experiencia por golpear aliados, curar un objetivo de forma repetida, repetir la misma captura artificialmente o disparar a un enemigo destruido. Las unidades sin armas progresan con su función de apoyo, nunca con una bonificación de daño inventada.

**Especialización de mejoras propuesta para simulación, NO ACTIVA:** infantería (visión/captura y defensa ligera), reconocimiento (visión y seguridad de movimiento), anti-blindaje (precisión contra categoría pesada), carros/IFV (defensa situacional y eficiencia de munición), artillería (munición y contrabatería SOLO como acción explícita), defensa aérea (identificación/intercepción con cadencia), aviones y drones reutilizables (combustible, munición o visión), barcos (vigilancia y combustible), logísticos/transportes (inventario y movilidad). Las ventajas deben quedar **limitadas**, sin ataques adicionales, rango ilimitado ni blindaje invulnerable, y valorarse por coste de oportunidad.

**Decisión propuesta para competitividad:** sin veteranía persistente en ranked/online para evitar ventajas por horas jugadas; en campaña puede persistir dentro de la misión/unidad si se activa y se guarda con pruebas. No introducir XP, campos de guardado o bonos hasta diseñar UI, experimentos A/B y límites de explotación.

## 4. Contramedidas y efectos: implementados frente a pendientes

| Emparejamiento | Ya lo determina el motor | Pendiente de medir o construir |
|---|---|---|
| Carro contra carro | ATQ/DEF/HP/munición, golpe inicial y respuesta si sobrevive | Equilibrar desgaste de blindados, coste de reabastecer |
| Carro frente a helicóptero | Carro **no** apunta a aire; helicóptero apunta a tierra; no aparece represalia imposible | Defensas combinadas y apoyos de escenario |
| SAM frente a caza | Antiaéreo solo apunta a aire; rango mínimo, visión, munición y contrafuego | Detectores especializados, radar complejo |
| Artillería contra infantería | Daño de largo alcance; artillería no responde automáticamente | Contrabatería como acción, refugio y dispersión |
| Antiblindaje de infantería | Rompedor +4 frente a Baluarte ya existente | Bonificaciones contra otras clases pesadas sujetas a test |
| Drones FPV/USV | Impacto de un uso, sin regreso ni respuesta de víctima | Guerra electrónica y contramedidas anti-drone por acción |
| Corbeta/fragata/destructor | Distancia, vida, objetivos navales/aéreos permitidos y reacción limitada | Sonar, daño específico por torpedos, escolta |
| Transporte y logística | Suministro terrestre con inventario real; vehículos sin ataque no contestan | Embarcar/desembarcar; reparación; rescate |
| Niebla y visión | Defensor no ve al atacante ⇒ no responde; ocultos no se pueden fijar como blanco | Señalización futura de detectado tras un disparo |

## 5. Criterios de aceptación

- Tanque idéntico en campo abierto produce **6 daño directo / 3 de respuesta**, en ambos sentidos. Si destruye el tanque, **0 respuesta**; si contraataca, consume una munición y registra `reacted`.
- No hay respuesta de MLRS, artillería indirecta, unidades desarmadas ni proyectiles de un uso; un tanque no puede contestar a un avión.
- **Máximo una respuesta por unidad en cada turno contrario**, restaurada solo cuando empieza el propio turno; no se pierden acciones activas ni hay cadenas infinitas.
- Bajo niebla, la reacción exige ver la posición atacante. No se revelan munición, bandera `reacted` o unidades ocultas mediante el panel de daño potencial.
- Guardados viejos sin `reacted` siguen válidos; nuevos guardados solo admiten bool. La IA evalúa riesgo de respuesta sin acceder a reservas enemigas ocultas.
- Simulaciones comparativas miden tasa de victoria por primera iniciativa, desgastes por dominio, turnos, gastos y destrucción mutua. Si aumenta la ventaja del atacante o se rompe la IA, se reajusta en **una rama nueva con evidencia**, sin cambiar silenciosamente el balance aprobado.
