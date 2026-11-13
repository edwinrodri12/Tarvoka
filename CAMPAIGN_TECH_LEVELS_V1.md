# TARVOKA — Árbol de niveles de las 24 familias (diseño v0.3)

**Estado:** especificación de diseño, NO prueba de implementación; decisión de depurar 32 IDs en 24 familias aprobada como dirección por el usuario. Documento complementario a [UNIT_ROSTER_AUDIT_V02.md](UNIT_ROSTER_AUDIT_V02.md) y [CAMPAIGN_UNIT_PROGRESSION.md](CAMPAIGN_UNIT_PROGRESSION.md). **No modifica el balance v0.1 de las ocho facciones ni el sistema de combustible/municiones por unidad.**

## Principios de progresión

- Tres niveles **tecnológicos** por familia, no tres fichas distintas en la fábrica. Niveles altos no sustituyen universalmente al básico: precio de producción, munición, combustible, capacidad y contramedidas producen elecciones reales.
- Se investigan/desbloquean opciones por capítulo (solo historia), pero una unidad ya existente **no se convierte gratis e instantáneamente** en tanque, fragata o artillería autopropulsada. Una **configuración** se elige al fabricarla en su instalación o se reacondiciona pagando dinero y tiempo; puede requerir la estructura apropiada. Cambiar chasis puede requerir fabricar equipo nuevo en lugar de transmutar una unidad veterana.
- La veteranía de una unidad que sobrevive, si se implementa después, se contabiliza separadamente de la tecnología: mejoras pequeñas y con tope, sin beneficios cruzados hacia online.
- Investigación no otorga recursos. La logística existente sigue gobernando cada movimiento, disparo y reaprovisionamiento; las clases que no disparan siguen sin inventario de munición.
- Toda especialización potente tiene **costo o renuncia**, no mejoras acumulativas sin límites: las ramas del nivel III son alternativas, no obligaciones ni superarmas.
- **En escaramuza/online:** el progreso de la campaña no bloquea familias ni niveles. El lobby elige reglas de tecnología iguales para todos; las mejoras se pagan y se adquieren por ambos bandos conforme a reglas.
- Los costes/estadísticas numéricos de nivel II/III se diseñarán y balancearán **después** de pruebas, no se pueden inferir de este documento.
- El terreno/mapa importa. Un destructor o bombardero debe poder tener contrajuego y utilidad en mapas adecuados; mapas de entrenamiento de 10×8 no obligan a habilitar todos los niveles.

## Tabla de familias y tres niveles

| ID | Familia | Función irremplazable | Nivel I | Nivel II | Nivel III/ramas | Contramedidas | Variantes absorbidas |
|---|---|---|---|---|---|---|---|
| G01 | Guardia | Infantería línea/captura | Guarnición básica: control territorial, coste bajo | Equipo urbano: mejor cobertura en ciudad, pierde eficacia campo abierto | Rama guardia defensiva / asalto urbano; entrenamiento y coste adicional | Rompedor, artillería, envolvimiento | G02 Asaltante (kit urbano) |
| G03 | Rastreador | Reconocimiento terrestre/captura | Exploración y visión prolongada | Kit de movilidad en montaña/bosque; defensa reducida en llano | Sensor avanzado o ocultación limitada, elegir una | Dron, fuego indirecto, rastreo | Infantería de montaña (especialización) |
| G04 | Rompedor | Infantería antiblindaje/captura | Antiblindaje de corto alcance | Arma eficaz contra blindaje medio con munición más cara | Equipo portátil pesado o movilidad ligera, ramas excluyentes | Infantería, artillería, apoyo a distancia | — |
| G05 | Ingeniero | Infraestructura/captura | Reparar o despejar una instalación | Puente temporal o despeje avanzado a coste de acción/recursos | Fortificación móvil o sabotaje de estructura con tiempo y avisos | Interceptar convoy, capturar ingeniero | Lanzapuentes (módulo) |
| G06 | Baluarte | Blindado de línea/choque | Blindado defensivo original (sin alterar sus stats probados) | Blindaje mejorado, dependencia de apoyo y consumo mayor | Rama tanque de combate ofensivo (G09) o blindado defensivo; fabricación/configuración en taller | Infantería antiblindaje, artillería, corte de combustible | G09 Tanque principal (perfil pesado) |
| G07 | Transporte blindado | Movilidad terrestre de infantería | Transporte de 2 escuadras con defensa ligera | Blindaje y desembarco protegido a coste de combustible | Rama VCI armado (G08) de menor capacidad vs transporte puro reforzado | Antiblindaje, terreno difícil, intercepción | G08 Vehículo de combate infantería (perfil) |
| G11 | Lanzador | Artillería indirecta | Alcance 2 sin ataque adyacente; preservar ID/reglas | Perfil autopropulsado de mayor movilidad/alcance (G10) a coste alto | Rama cohetes G12 de alcance/salva o artillería precisión, munición y precio elevados | Reconocimiento + flanqueo, poco eficaz cerca | G10 Artillería autopropulsada; G12 Lanzacohetes |
| G13 | Antiaéreo móvil | Intercepción y cobertura aérea | Defensa corta contra dron/helicóptero | Radar limitado y batería de corto alcance | Rama SAM G14 larga distancia con hueco cercano o cañón antidron rápido | Blindados, infantería, saturación y falta de visión | G14 SAM; antimisiles como módulo caro y limitado |
| G15 | Vehículo guerra electrónica | Interferencia y contrasensores | Jamming de enlace de drones con rango y duración | Suprimir sensores locales por 1 turno a coste de acción | Rama protección de aliados / detección de emisores, elegir; ninguna visión omnisciente | Artillería, drones autónomos, ataque físico | — |
| G16 | Vehículo logístico | Munición y combustible terrestre | Stock físico y entrega a terrestre adyacente | Mayor stock y velocidad, no combustible gratis | Rama blindaje escolta / carga extra (excluyentes) | Emboscada, interdicción de ruta | — |
| A01 | Dron reconocimiento | ISR aéreo | Visión elevada sin ataque ni captura | Visión mejorada o más persistencia con consumo | Rama sensor térmico/objetivos ocultos limitados vs autoprotección; sin fog omnisciente | Antiaéreo, guerra electrónica | — |
| A02 | Dron FPV consumible | Golpe de un solo uso | Ataque unitario a objetivo visible, unidad se consume | Perfil merodeador A03: espera limitada y alcance corto ampliado | Rama antiblindaje / antibuque ligero (no ambas), coste mayor | Antidron, jamming, falta de blancos | A03 Munición merodeadora (perfil) |
| A04 | Dron combate reutilizable | Ataque remoto y reconocimiento | Ataque reutilizable con rearmado de base | Persistencia/sensores a cambio de carga útil | Rama observación extensa / armamento de precisión; vulnerable a interferencias | Antiaéreo, guerra electrónica, interceptores | — |
| A05 | Helicóptero ataque | Apoyo cercano móvil | Ataque tierra, no transporta infantería | Mejor protección y munición, aumenta coste de mantenimiento | Rama antiblindaje / apoyo de área, contramedida SAM | SAM, caza, combustible y bases | — |
| A06 | Helicóptero transporte | Movilidad aérea/evacuación | Transporta 2 escuadras y las desembarca | Kit de extracción rápida y autonomía con mayor consumo | Rama carga pesada / transporte médico (mismo transporte, sin cura gratis) | SAM, caza, falta de base | Transporte aéreo pesado como perfil |
| A07 | Caza multifunción | Superioridad aérea | Intercepción de aeronaves y ataque suelo limitado | Sensores y combustible eficiente con precio mayor | Rama superioridad / multirrol; no reemplaza bombardero | SAM, cazas, pérdida de aeródromo | — |
| A08 | Bombardero táctico | Ataque pesado de precisión limitada | Poder terrestre/naval, alto coste, requiere escolta | Carga ampliada con menor maniobra y consumo elevado | Rama golpe de precisión / ataque de área sólo contra objetivos militares, fuertes restricciones | Caza, SAM, logística | — |
| M01 | Patrullero | Control litoral | Patrulla, intercepta pequeños navíos/drones | Perfil lancha misilera M02: velocidad y misil, menos resistencia | Rama vigilancia litoral / ataque costero, exclusivas | Corbeta, destructor, aviación | M02 Lancha misilera (perfil) |
| M03 | Corbeta | Escolta y detección naval | Protege convoyes, defensa cercana | Perfil fragata M04: sonar/antiaérea y mayor precio | Rama antisubmarino / defensa aérea, exclusivas | Submarino, destructor, saturación | M04 Fragata (perfil) |
| M05 | Destructor | Apoyo pesado de flota | Fuego contra navíos y costa, requiere mapa amplio | Mejora a capacidad de protección aérea del grupo con coste alto | Rama apoyo litoral / defensa de área; solo si mapas grandes validan rol | Submarinos, bombardeo y logística | — |
| M06 | Submarino | Acecho naval | Infiltración y ataque naval con ocultación | Mejor sigilo o autonomía limitada | Rama ataque silencioso / reconocimiento submarino; no ataque infinito | Sonar, fragata, patrullas antisubmarinas | — |
| M07 | Buque desembarco | Transporte anfibio | Carga tropas/vehículos a costa navegable, no captura | Mayor carga con maniobra inferior | Rama despliegue rápido / transporte pesado; escolta imprescindible | Submarino, buques de combate, aviación | — |
| M08 | Dron naval USV | Ataque naval desechable | Ataque único a navío visible; se consume | Autonomía y visión pequeñas mejoras | Rama reconocimiento/cobertura / carga antibuque, conservando un solo uso al atacar | Patrulla, interceptación, jamming compatible | — |
| M09 | Buque logístico (propuesto) | Suministros navales | Munición y combustible para navíos con inventario real | Mayor stock y rango de transferencia limitado | Rama reabastecimiento de flota / reparación ligera a coste, no armas gratuitas | Submarino, incursiones costeras, pérdida de escoltas | Concepto recuperado, validación mapa naval pendiente |

## Riesgos y pruebas de equilibrio

1. **Baluarte→tanque (G06/G09)**: validar que la configuración ofensiva sacrifica un beneficio defensivo o consume recursos suficientes; no simplemente +ataque/+movimiento/+HP. Mantener el ID G06 y los atributos probados del prototipo durante la migración.
2. **Lanzador (G11)→artillería/cohetes (G10/G12)**: perfiles diferentes por alcance mínimo, movilidad, demora de disparo, ammo y facilidad de detección; no aceptar una variante que domina todas las posiciones.
3. **Transporte (G07/G08)**: los dos perfiles deben diferir carga y armamento; sólo infantería desembarcada puede capturar.
4. **Antiaéreo (G13/G14)**: perfil SAM debe ser ineficiente contra drones a corta distancia; no atacar unidades no detectadas.
5. **FPV vs merodeador (A02/A03)**: ambas consumibles al atacar, nunca aparecen dos unidades después de lanzar un solo dron.
6. **Patrullero, corbeta, destructor (M01/M03/M05)**: tres familias justificadas únicamente si cada una resuelve una misión distinta a coste relativo razonable; si M05 solo suma números, absorberlo en M03 y pasar a 23.
7. **A04 vs A05:** dron reutilizable con reconocimiento/persistencia pero más vulnerable a interferencia; helicóptero con apoyo cercano y consumo propio. Si uno replica al otro, fusionar según pruebas.
8. **G15 guerra electrónica:** debe tener al menos una decisión real por turno más allá de un debuff pasivo automático. Si sólo hace «antidron mejor», convertirlo en módulo G13.
9. **M09 logística naval:** probar convoyes y consumo naval antes de cerrar familia nueva; si no ofrece valor en las dimensiones de mapa, descartar familia y quedar en 23.
10. **Compatibilidad:** mapa `legacy_id → family_id, profile_id` para todos los 32 IDs, guardado y tests; las 5 clases programadas mantienen comportamiento hasta migración validada.

## Registro de variantes heredadas

- `G02 → G01/urbano`
- `G08 → G07/vehiculo_combate`
- `G09 → G06/tanque_principal`
- `G10 → G11/autopropulsada`
- `G12 → G11/cohetes`
- `G14 → G13/sam`
- `A03 → A02/merodeadora`
- `M02 → M01/lancha_misilera`
- `M04 → M03/fragata`

**Definición de listo para desarrollo:** ninguna familia duplica a otra sin contrapartida; árboles de investigación con ID persistente; el jugador puede fabricar nivel I incluso con III desbloqueado; interfaz diferencia perfil/suministro y no muestra falsos niveles; tres dominios y guardados seguros; ningún modo libre exige progreso narrativo.
