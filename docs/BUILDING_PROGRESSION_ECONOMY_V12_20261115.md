# TARVOKA — Evolución militar I–III y decisión de inversión (laboratorio v1.2)

**16 de noviembre 2026 (UTC) · [PR #394](https://github.com/edwinrodri12/Tarvoka/pull/394) en borrador · Sin integración en Android ni reglas oficiales**

## El problema de balance

Actualmente el sistema real de fabricación, en `scripts/core/UrbanEconomy.gd`, permite construir cualquier unidad del catálogo compatible con una instalación sin comprobar nivel de edificio. La producción se limita a **una unidad por instalación en la fase**, dinero disponible, casilla libre y reglas de dominio.

Añadir niveles y mejoras cambiaría la curva temporal, incluso si los atributos de todas las unidades permanecieran intactos. La investigación compara gastar los mismos créditos en **unidades presentes ahora** o en **desbloqueos que permiten fabricar mejores unidades después**. No se ha aprobado ningún coste de nivel ni tecnología.

## Código incorporado únicamente al laboratorio

- `scripts/experiments/BuildingProgressionV12.gd`: modelo optativo de niveles por instalación, acceso por nivel, progreso separado por posición/propietario, mejoras que consumen créditos **y el único turno de producción** de esa instalación, tecnologías exclusivas para una facción y restablecimiento de niveles cuando cambia el propietario.
- `tests/test_building_progression_v12.gd`: 11 suites que validan las **32 unidades**, dos bandos, costes, bloqueo de producción y acceso, compra real de APC/tanque y poderes comprados del Ingeniero y Rompedor. **Godot 4.3 SUCCESS:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43790961597
- `tests/test_building_tier_matrix_v13.gd`: comprueba los seis tipos de instalaciones, ambos bandos, nivel II y rutas reales hacia nivel III cuando existe contenido que lo justifique. Las comprobaciones artificialmente financiadas a 2.500 créditos sirven **únicamente para separar bloqueo por nivel de insuficiencia de fondos**.
- **Godot 4.3 SUCCESS de ambas baterías:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43791174556. Se validaron 11 suites de progreso más 12 casos de edificios espejo (uno por cada instalación y bando): **10 rutas de nivel III** y ambos intentos de nivel III de drones bloqueados por falta de una capacidad que lo justifique. La comprobación de acceso de roles usa un presupuesto de prueba explícito para separar el nivel de la falta de dinero; no se atribuye ese dinero artificial a la economía jugable.

**Importante:** estos niveles y tecnologías **viven fuera del estado oficial de BattleSession y fuera de SaveCodec**. No son persistentes entre partidas guardadas, por lo que no pueden activarse en el producto real sin un esquema de guardado y recuperación. Las instalaciones en UrbanEconomy no tienen todavía un sistema completo de HP estructural: los diseños 3D del HQ no añaden vida o resistencia real al edificio por sí solos.

## Costos propuestos para simular (NO aprobados)

| Instalación | I → II | II → III | Función del nivel III |
|---|---:|---:|---|
| Cuartel de infantería / factory | 400 | 750 | Acceso a tecnología de reparación avanzada por otros 250 |
| Planta de blindados | 650 | 1.050 | Acceso a tecnología antiblindaje +2 por otros 450 |
| Depósito de artillería | 550 | 950 | Acceso a MLRS y guerra electrónica (su efecto especial aún pendiente) |
| Centro de drones | 400 | **No habilitado** | Se evita cobrar un nivel III sin capacidad real adicional |
| Base aérea | 750 | 1.400 | Acceso a bombardero; requiere además el precio del avión |
| Base naval | 800 | 1.500 | Acceso a fragata, destructor y submarino; requiere fondos y agua navegable |

Estas cifras se eligieron para comparar decisiones con el dinero inicial moderno (2.500 por facción) y 250 por ciudad propia en cada turno. **No son un compromiso de precios.** La ubicación del "Cuartel de Infantería" corresponde al `factory` actual, sin introducir un edificio de entrenamiento separado ni Centro de Investigación.

## Acceso por niveles: propuesta verificable

| Productor | Nivel I | Nivel II | Nivel III |
|---|---|---|---|
| Infantería | Guardia, Rastreador | Asaltante, Ingeniero, Logística | Solo tecnología de reparación avanzada después de otra compra |
| Blindados | APC, Rompedor, Baluarte | IFV, Tanque | Solo tecnología antiblindaje por compra separada |
| Artillería | Artillería, Antiaéreo móvil | SPG, SAM | MLRS, Guerra electrónica* |
| Drones | Reconocimiento, FPV | Munición merodeadora | No disponible todavía |
| Aire | Helicóptero de ataque y transporte* | UCAV, Caza | Bombardero táctico |
| Naval | Patrullero, USV | Lancha misilera, Corbeta, Desembarco* | Fragata, Destructor, Submarino* |

*Advertencias*: interferencia EW, carga del helicóptero de transporte, desembarco y sigilo/sonar naval **no funcionan aún como habilidades completas**. Estar en un nivel no implica que se hayan implementado. El nivel de **acto de campaña** en `CombatDoctrine.tier` tampoco es nivel I–III de fábrica.

## Resultado comprobado: APC vs tanque en los primeros dos turnos propios

La prueba de Godot 4.3 realizó verdaderas órdenes `BattleSession.purchase` en cada rama, sin fabricar instantáneamente varias unidades en la misma instalación.

| Alternativa | Gastos en créditos | Compras nuevas al terminar | Créditos restantes |
|---|---:|---|---:|
| Planta I: APC de 300 y, un turno propio después, otro APC de 300 | 600 | 2 APC | 2.150 |
| Subir planta a II por 650; un turno propio después, fabricar tanque por 750 | 1.400 | 1 Tanque | 1.350 |

Ambas ramas recibieron el mismo ingreso de ciudad en el intervalo. En la primera, el APC recién producido debió desalojar la casilla de fabricación antes de comprar otro; en la segunda, el ascenso consumió el turno de producción inicial. Se comprueba así que la evolución tiene **coste en efectivo y coste de oportunidad temporal**.

La prueba **no dice** cuál gana un combate de tres turnos: dos APC permiten más presencia y control de casillas, mientras que el tanque tiene vida/daño/defensa superiores y puede abrir otros caminos estratégicos. Ese veredicto necesita simulación IA con enemigos y mapas.

## Tecnología pagada: no premiar gratis una mejora de edificio

- **Blindados**: I→II = 650; II→III = 1.050; luego **antiblindaje I** = 450. Inversión acumulada hipotética: **2.150**. Solo entonces el Rompedor del jugador que pagó obtiene **+2 daño bruto de ataque contra los nueve vehículos terrestres especificados** en el intercambio experimental; frente al tanque en llano se observó daño **2→4**. No aumenta ataque contra infantería, naves o aviones; no cambia estadísticas permanentes.
- **Infantería**: I→II = 400; II→III = 750; tecnología de campo = 250. Inversión acumulada: **1.400**, antes de pagar cada reparación de 100 créditos. El Ingeniero puede realizar reparación ligera sin tecnología superior en el experimento; la tecnología habilita el paquete **3 HP/100 créditos**, frente a **2 HP/60 créditos**. Nadie obtiene HP gratis.
- Ambas tecnologías usan la oportunidad de producción de su instalación y se compran **una sola vez por facción**. Se mantienen como tecnología global compatible; **no son habilidades permanentes de cada unidad al guardar**.

En los ensayos espejo se confirmó que la tecnología pertenece exclusivamente al bando que la adquirió, no se permite comprar dos veces y no se heredan niveles de instalaciones capturadas. Esta salvaguarda también requiere actualización explícita al pasar un turno en la implementación real.

## Condiciones que aún faltan

- No se midieron aún **tasas de victoria, balance de IA ni disfrute humano** con estos niveles: las pruebas son de reglas, compras y umbrales tácticos.
- Los escenarios de ocho jugadores requieren soporte real de ocho facciones; el motor ensayado es para dos.
- Cuartel General I–III, puntos de vida de edificios, daño por proyectiles y reparación de estructuras están pendientes. No inventar atributos antes de modelar estructuras en el estado autoritativo.
- Los poderes de comandantes y ventajas de las ocho facciones siguen **congelados en balance 0.1**, sin inventar bonificaciones acumuladas en este experimento.
- No es legítimo concluir que la tecnología de nivel III sea equilibrada sin medir el momento en que aparece, el coste de la producción perdida, contrajuegos de nivel I y mapas de distinta densidad económica.

## Decisión y próxima investigación

El modelo permite **probar una progresión con costos reales y restricciones verificables**, pero sigue siendo una **hipótesis para playtesting**. La prioridad posterior es simular estrategias alternativas durante partidas completas (expansión temprana, inversión en II, inversión en III y tecnología), medir duración, victorias y gastos, y **comparar contra un rival competente**, antes de fusionar nuevas reglas en TARVOKA.

En paralelo será necesario incorporar niveles/tecnologías al guardado y UI del juego si alguna configuración supera esos ensayos. Mientras tanto, conservar el PR en borrador sin modificar gameplay ni APK.
