# TARVOKA — Auditoría de redundancias y familias de unidades v0.2 (PROPUESTA)

**Fecha:** 2026-11-12. **Estado:** auditoría y recomendación de diseño; requiere validación de jugabilidad y ajuste de progresión de campaña. **NO está implementada ni cambia actualmente los 32 IDs ni las estadísticas del motor.**  
**Motivación del usuario:** no multiplicar unidades con prácticamente la misma función, pues cada familia de unidad **subirá de nivel y podrá especializarse**.  
**Fuentes internas:** `MILITARY_UNIT_CATALOG.md` (32 clases), `CAMPAIGN_UNIT_PROGRESSION.md` (32 desbloqueos anteriores), `LOGISTICS_DESIGN.md` (munición/combustible), 39 propuestas creativas anteriores (después de retirar defensa química).

## 1. Hallazgos y resultado sugerido

**Conclusión:** reducir **32 → 23 familias** mediante nueve fusiones funcionales y **evaluar incorporar un buque de apoyo logístico** procedente del catálogo anterior, que sí tiene un rol nuevo; **24 familias recomendadas** (10 terrestres, 7 aéreas y 7 navales). La nueva familia `M09` es un **ID provisional**, no un ID ya existente en producción. Si los mapas navales no justifican reabastecimiento en alta mar, eliminar M09 y quedar en **23**.

**No es una poda de contenido militar:** se conservan como **mejoras, configuraciones, armamentos o habilidades** las capacidades que no justifican una compra/cola de producción independiente.

**Regla de admisión:** una clase merece casilla de producción propia si cumple a la vez:
1. Soluciona un problema táctico **distinto** del de otra clase (transporte, reconocimiento, captura, suministro, asedio, interceptación, bloqueo, etc.).
2. Introduce por lo menos **dos decisiones** diferentes observables (posición, alcance, protección, coste, munición, amenaza o contramedida); no solo +HP/+daño/+precio.
3. Tiene una **contramedida** clara, y no queda totalmente desplazada por el siguiente nivel.
4. Añade valor al tamaño real de mapas/turnos; una unidad de alcance 5 en mapa 10×8 puede invalidar muchas decisiones.
5. Es comprensible en Android, y se implementa y prueba sin volver el menú inmanejable.

## 2. Auditoría uno a uno: las 32 clases de v0.1

**Mantener** = clase propia; **absorber** = conservar capacidad dentro de familia indicada.

### Tierra: 16 → 10
| ID v0.1 | Clase | Dictamen | Justificación y destino |
|---|---|---|---|
| G01 | Guardia | MANTENER | Infantería económica para capturar/defender; kit urbano opcional |
| G02 | Asaltante | ABSORBER en G01 | Misma captura/ataque corto: especialización de combate urbano con coste y contrapartida, no otra clase |
| G03 | Rastreador | MANTENER | Exploración, visibilidad, rutas y captura: papel distinto de infantería de línea |
| G04 | Rompedor | MANTENER | Infantería antiblindaje y captura; daño a blindados no es simple veterania |
| G05 | Ingeniero de combate | MANTENER | Reparación/despeje/puentes en objetivos, además de captura |
| G06 | Baluarte | MANTENER | Familia de blindado; progresión a equipamiento tipo tanque principal (sin nueva categoría de compra) |
| G07 | Transporte blindado | MANTENER | Transporte de soldados, descarga e intervención en capturas |
| G08 | Vehículo de combate de infantería | ABSORBER en G07 | Variante de transporte armado (IFV) y blindaje vs capacidad/precio |
| G09 | Tanque principal | ABSORBER en G06 | Nivel/variante de blindado pesado, no una segunda unidad que reemplaza al tanque antiguo |
| G10 | Artillería autopropulsada | ABSORBER en G11 | Nivel de artillería móvil con más movilidad/rango y munición/coste ajustados |
| G11 | Lanzador | MANTENER | Artillería base de fuego indirecto, con alcance mínimo real; preservar ID y comportamiento del prototipo |
| G12 | Lanzacohetes múltiple | ABSORBER en G11 | Módulo de cohetes de largo alcance, salvas limitadas; si no hay mecánica distinta, NO convertir en clase |
| G13 | Antiaéreo móvil | MANTENER | Familia antiaérea; cañón corto alcance o módulo SAM de largo alcance |
| G14 | Batería SAM móvil | ABSORBER en G13 | Misma función antiaérea, distinto perfil/configuración; preservar debilidad a blancos cercanos |
| G15 | Guerra electrónica | MANTENER (sujeto a test) | Bloquea sensores/drones por turnos; no hace daño ni duplica al antiaéreo, puede perder su puesto si no crea decisiones |
| G16 | Vehículo logístico | MANTENER | Reponer munición/combustible en tierra con stock real, no reparar gratis |

### Aire: 8 → 7
| ID v0.1 | Clase | Dictamen | Justificación y destino |
|---|---|---|---|
| A01 | Dron reconocimiento | MANTENER | Detección y visión con alcance/fragilidad propios; no elimina niebla de guerra |
| A02 | Dron FPV ataque | MANTENER | Barato y consumible; misión táctica de un único ataque |
| A03 | Munición merodeadora | ABSORBER en A02 | Configuración de espera/alcance de dron consumible; ni segundo disparo ni retorno |
| A04 | Dron de combate reutilizable | MANTENER (sujeto a test) | ISR + ataque con rearmado/fuel, vulnerabilidad a guerra electrónica; no debe copiar al helicóptero |
| A05 | Helicóptero ataque | MANTENER | Apoyo cercano robusto, ocupa posición de riesgo y depende de bases/combustible |
| A06 | Helicóptero transporte | MANTENER | Lleva infantería, permite evacuación; solo desembarcados capturan |
| A07 | Caza multifunción | MANTENER | Superioridad aérea/velocidad; requiere defensa SAM como respuesta |
| A08 | Bombardero táctico | MANTENER | Ataque pesado limitado, no reemplaza caza ni helicóptero; vulnerable a intercepción |

### Mar: 8 → 6 de origen (+1 nuevo logístico = 7)
| ID v0.1 | Clase | Dictamen | Justificación y destino |
|---|---|---|---|
| M01 | Patrullero | MANTENER | Patrulla litoral; lancha misilera es equipamiento especializado |
| M02 | Lancha misilera | ABSORBER en M01 | Perfil costero de misiles y menos defensa, no escalera de barcos baratos |
| M03 | Corbeta | MANTENER | Familia de escolta que progresa a capacidad antisubmarina/de fragata |
| M04 | Fragata | ABSORBER en M03 | Nivel/paquete de escolta multisistema, con mayor coste de adquisición y reaprovisionamiento |
| M05 | Destructor | MANTENER (solo grandes mapas) | Potencia de fuego de área/costera y protección aérea de flota; no es simplemente fragata con +HP. Si en playtest solo añade estadísticas, absorber también en M03 y bajar una clase |
| M06 | Submarino | MANTENER | Ocultación/sonar y ataque naval con contramedida propia; no dividir convencional/estratégico por mero nivel |
| M07 | Buque desembarco | MANTENER | Transporte anfibio de tropas/vehículos; solo infantería desembarcada captura |
| M08 | Dron naval USV | MANTENER | Ataque un solo uso, navío barato y frágil, reconocimiento limitado; útil si el agua es un dominio real |
| M09* | Buque apoyo logístico | PROPONER nueva familia | Reabastece buques en mar (con inventario, rango/coste/acción). Única incorporación propuesta desde conceptos anteriores; *pendiente de probar* |

**Verificación aritmética:** 32 originales = 23 mantenidas (10G+7A+6M) + 9 absorbidas (6G+1A+2M). Con M09 opcional serían **24**.

## 3. Recuperación del catálogo temprano de ~40/39 conceptos

En conversaciones anteriores se identificaron **siete candidatos omitidos** del primer catálogo de ~40; el listado completo uno por uno de las 39 propuestas **no está archivado íntegramente en la documentación actual**, así que no presentar esta auditoría como comparación exhaustiva de los 39 nombres. Evaluar estos siete expresamente:

| Concepto previo | Dictamen | Razón |
|---|---|---|
| Helicóptero antisubmarino | MÓDULO/Apoyo de A06 o M03 | Rol antisubmarino desde escolta o helicóptero embarcado, no tercer helicóptero de combate por compra |
| Vehículo lanzapuentes | HABILIDAD de G05 | Ingeniero construye puente temporal con costes y límites; clase independiente solo si mecánica y contrajuego lo justifican |
| Sistema antimisiles | MEJORA de G13 | Intercepción limitada y cara, no tercera categoría antiaérea |
| Infantería de montaña | EQUIPAMIENTO de G03 | El reconocimiento de alta movilidad ya existe, opción especializada por terreno |
| Transporte aéreo pesado | MEJORA/VARIANTE de A06 | Mayor capacidad/logística en escenarios grandes, sin duplicar helicóptero de transporte por nombre |
| Buque de apoyo logístico | PROPONER M09 | Permite combustible/munición en rutas navales sin ir a astillero; protección y coste crean decisión propia |
| Misiles tácticos | APOYO DE MISIÓN o equipo G11 | No regalar alcance estratégico/daño masivo como otra casilla; evaluar solo en mapas grandes con aviso y contramedida |

La clase de **defensa química** ya se descartó por decisión previa del usuario; NO reintroducirla.

## 4. Niveles y mejoras sin clones

Un **ID de familia** representa una decisión de compra; su evolución tecnológica se modela como **tres escalones**:
- **Nivel I — doctrina básica:** función principal clara, coste contenido.
- **Nivel II — actualización táctica:** mejora un aspecto mediante inversión; coste y contrapartida. Ej.: Guardia + kit urbano; G07 más armamento pero menor espacio/carga útil si corresponde; G13 SAM pero sufre ante unidades próximas.
- **Nivel III — tecnología avanzada:** aumenta opciones tácticas o abre **rama exclusiva** (blindaje vs movilidad, detección vs golpe, cañones vs misiles), **no** un multiplicador universal de estadísticas que vuelva inútil el nivel I.

La evolución es **tecnología y equipamiento**: desbloqueo narrativo/científico, producción al nivel correspondiente o reacondicionamiento en instalación adecuada **pagando recursos y acciones**. No transformar mágicamente durante una batalla un vehículo físico en otro sin instalación ni coste. En camiones y buques el nivel afecta la capacidad/defensa/coste pero nunca genera munición ni combustible gratis.

**Nivel de clase ≠ veteranía individual:** si se añade experiencia a unidades sobrevivientes, dar bonos pequeños/capados de campaña con contrapeso; evitar premios que obliguen a conservar unidades en mapas diseñados para sacrificio. No trasladar ventajas acumuladas a online/partidas contra IA: partidas competitivas empiezan con reglas y presupuesto igual para ambos jugadores.

**Balance:** alternativas reales de producción barata vs actualizada; costes crecen, munición/carga/combustible limitan uso, tech T3 no disponible inmediatamente. Preferir especializaciones mutuamente excluyentes para que el menú no parezca 3 unidades adicionales. Decisiones de mejoras se muestran en ficha de unidad, no como clones en panel de fábrica.

## 5. Progresión revisada de las 50 misiones (propuesta)

La progresión antigua 9/18/26/32 pertenece al catálogo v0.1 **sin filtrar**; no debe tratarse como nueva meta. Si se acepta esta auditoría, reemplazarla por las **24 familias** siguientes (o 23 sin logística naval), con capítulos sin nueva clase dedicados a **mejoras** y dominio táctico:

| Acto | Nuevas familias | Total acumulado | Aprendizaje y especializaciones |
|---|---|---:|---|
| I (1–10) | G01(01), G03(02), G05(03), G04(04), G16(06), M01(07), G06(08), G11(09) | 8 | Cap.05: kit urbano Guardia. Cap.10: examen táctico |
| II (11–20) | G07(11), M07(15), A01(17), G13(18), M03(20) | 13 | Cap.12: transporte armado (G08), 13: blindado moderno (G09), 14: artillería móvil (G10), 16: cohetes (G12), 20: misiles costeros (M02) |
| III (21–30) | G15(21), A02(22), A06(23), A05(25), M09(27*), A04(29) | 19 | Cap.24: SAM (G14), 26: drone merodeador (A03), 28/30 combinaciones tácticas |
| IV (31–40) | A07(32), M06(33), A08(38), M05(39), M08(40) | 24 | Cap.37: fragata/ASW (M04), helicóptero ASW como módulo opcional; cap.40 operación naviera |
| V (41–50) | — | 24 | Dominio del arsenal: logística, alianzas, objetivos complejos y tres desenlaces |

*La inserción M09 en C27 depende de que haya operación naval coherente y reabastecimiento marítimo ya modelado; de lo contrario, mover a C37 o descartar. La aparición de misiles, tanques avanzados, bombarderos y buques grandes **no implica** que sean viables en el tablero actual 10×8: requieren escenarios/movilidad adaptados y QA.*

**Política de desbloqueo:** campaña solamente. Online y escaramuza IA no se bloquean por progreso de historia y ambos utilizan el mismo motor de reglas; sin bonificaciones acumuladas entre partidas. Las mejoras se habilitan gradualmente en la campaña si la misión lo permite.

## 6. Compatibilidad, próximos tests y decisión de cierre

- **No borrar IDs existentes:** conservar tabla de `legacy_id → family_id + variant` para partidas, economía, IA, tests y editor; nunca recodificar G11 Lanzador (implementado) como una clase sin rango 2.
- Desbloquear **familia y nivel** por separado, p. ej. `G06` en C08 y perfil `G09` en C13; **no** contarlo dos veces como clases distintas.
- Las cinco clases iniciales programadas (**G01, G03, G04, G06, G11**) mantienen reglas físicas hasta migración explícita probada.
- Antes de cerrar 24: probar G06 vs G09, G07 vs G08, G11 vs G10/G12, G13 vs G14, A02 vs A03, M01 vs M02, M03 vs M04/M05, y A04 vs A05. Si dos variantes producen la misma decisión óptima con frecuencia similar, reducir/ajustar; si separar genera genuinas estrategias nuevas, reconsiderar.
- Cada clase de apoyo debe tener utilidad que no pueda replicarse con otra unidad más barata, y contrajuego claro; unidades de gama alta no deben producir bola de nieve inevitable.
- Diseñar tests de guardado/carga con referencias antiguas, menú Android legible, movimiento/ataque/alcances por dominio, reabastecimiento y economía; no anunciar como funcionalidades programadas.

**Estado final de la revisión:** propuesta **24 familias** (23 si se descarta M09), **32 IDs de origen conservados como referencia de compatibilidad**, siete conceptos antiguos evaluados, las 50 misiones conservadas. Siguiente trabajo de diseño: definir 3 niveles/ramas de cada familia y rehacer tablas de capítulos; *no implementar todavía cambios destructivos de catálogo sin pruebas*.
