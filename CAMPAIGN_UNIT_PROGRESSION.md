# TARVOKA — Progresión de unidades del modo historia

**Decisión aprobada por el usuario:** 2026-11-12. **Estado:** diseño de campaña [PLAN], no implementación demostrada.  
**Documentos:** [CAMPAIGN_STORY_50.md](CAMPAIGN_STORY_50.md), [MILITARY_UNIT_CATALOG.md](MILITARY_UNIT_CATALOG.md), [LOGISTICS_DESIGN.md](LOGISTICS_DESIGN.md).

## Principio rector

En las 50 misiones de *La Red de Meridian* el jugador aprende y desbloquea **progresivamente** las 32 clases del catálogo militar moderno v0.1. Cada desbloqueo debe estar justificado por un acontecimiento militar o una necesidad táctica, no por un nivel de experiencia artificial. No se cambian estadísticas, ventajas permanentes, poderes ni colores de facciones.

**Límite imprescindible:** este progreso es **exclusivo de la campaña**. Ni las batallas contra IA con mapas aleatorios ni las batallas online exigen jugar capítulos, ganar medallas o comprar clases. En esos modos todas las clases que estén técnicamente incorporadas al juego estarán disponibles según las reglas/mutadores elegidos para la partida, con coste económico normal e igualdad competitiva.

**No confundir:**
1. **Descubrimiento/tutorial**: presentar un rol en briefing, diálogo, unidad precolocada o producción guiada; la primera aparición puede ser enemiga/aliada y enseñar cómo contrarrestarla.
2. **Desbloqueo de campaña**: desde el capítulo indicado, el tipo se añade al **registro de unidades aprendidas**; el jugador puede producirlo o recibirlo **si** el escenario lo contempla y dispone de infraestructura, créditos y suministro.
3. **Disponibilidad real por misión**: condicionada por dominios terrestres/aéreos/navales, fábricas, mapas y rol de facción; no convertir un astillero de mar en fabricante de blindados ni obligar a introducir aeronaves donde no caben.
4. **Implementación técnica**: solo marcar una unidad como jugable cuando exista su lógica, IA, UX, compatibilidad de guardado y pruebas. El catálogo de diseño no significa 32 clases terminadas.

## Calendario de descubrimiento — 32 clases, 50 capítulos

Se reservan **los capítulos 41–50 para dominio del arsenal completo**, combinaciones, decisiones y clímax; no añadir nuevas clases allí para no distraer del desenlace.

### Acto I — Las primeras 72 horas (1–10): nueve clases
| Capítulo | ID | Clase que se presenta/desbloquea | Motivo narrativo/tutorial |
|---:|---|---|---|
| 01 | G01 | Guardia | Movimiento, ataque cercano, captura solo de infantería |
| 02 | G03 | Rastreador | Exploración, visión y niebla de guerra |
| 03 | G05 | Ingeniero de combate | Restauración de infraestructura y ocupación de instalaciones |
| 04 | G04 | Rompedor | Infantería antiblindaje y contramedidas |
| 05 | G02 | Asaltante | Combate urbano y defensa de corredores |
| 06 | G16 | Vehículo logístico | Combustible, munición y escolta; no puede capturar |
| 07 | M01 | Patrullero | Primer contacto con navegación costera y buques |
| 08 | G06 | Baluarte | Blindaje defensivo, vulnerabilidad a antiblindaje |
| 09 | G11 | Lanzador | Diferencia entre movimiento y alcance de ataque, no dispara adyacente |
| 10 | — | Sin clase nueva | Examen táctico sin más reglas: cerrar el acto emocionalmente |

**Nota:** G04 Rompedor se especifica para la campaña como **infantería antiblindaje** a pie; conforme a la regla de diseño aprobada, **todo tipo de infantería** (G01–G05, incluidos exploradores, antiblindaje e ingenieros) puede capturar si está físicamente en la casilla, mientras que **ningún vehículo terrestre, aéreo o naval** captura. Los transportes solo facilitan llegar; deben desembarcar a la infantería. Comprobar/ajustar la clasificación técnica al integrar esta regla sin alterar los atributos militares v0.1.

### Acto II — Fronteras en llamas (11–20): nueve clases, acumulado 18
| Capítulo | ID | Clase | Contexto |
|---:|---|---|---|
| 11 | G07 | Transporte blindado | Transportar escuadras para tomar el puente, solo la infantería desembarcada captura |
| 12 | G08 | Vehículo de combate de infantería | Apoyo mecanizado y protección de corredores |
| 13 | G09 | Tanque de combate principal | Blindaje pesado y dependencia de combustible |
| 14 | G10 | Artillería autopropulsada | Defensa con rango indirecto y munición limitada |
| 15 | M07 | Buque de desembarco | Desembarco e infantería que ocupa el puerto |
| 16 | G12 | Lanzacohetes múltiple | Fuego de largo alcance con consumo alto |
| 17 | A01 | Dron de reconocimiento | Reconocimiento aéreo sujeto a niebla y contramedidas |
| 18 | G13 | Antiaéreo móvil | Defensa frente a drones/helicópteros |
| 19 | — | Sin clase nueva | Escolta de alimento y gestión de recursos aprendidos |
| 20 | M02 | Lancha misilera | Amenaza naval rápida en batalla del estrecho |

### Acto III — La guerra que alimentamos (21–30): ocho clases, acumulado 26
| Capítulo | ID | Clase | Contexto |
|---:|---|---|---|
| 21 | G15 | Vehículo de guerra electrónica | Manipulación/detección limitada de enlaces, no magia ni visión total |
| 22 | A02 | Dron FPV de ataque | Arma consumible; enseñarle coste y contramedidas |
| 23 | A06 | Helicóptero de transporte | Traslado y evacuación; infantería desembarcada captura |
| 24 | G14 | Batería SAM móvil | Defensa de retaguardia y cobertura de retirada |
| 25 | A05 | Helicóptero de ataque | Apoyo aéreo y amenaza antiaérea |
| 26 | A03 | Munición merodeadora | Ataque consumible para detener amenaza militar que bloquea corredor |
| 27 | M03 | Corbeta | Protección naval y búsqueda de convoyes |
| 28 | — | Sin clase nueva | Dilema político y coordinación con arsenal conocido |
| 29 | A04 | Dron aéreo de combate reutilizable | Contrastar aparato recuperable con drones consumibles |
| 30 | — | Sin clase nueva | Gran batalla y ruptura de alianza |

### Acto IV — Expediente Nudo Siete (31–40): seis clases, acumulado 32
| Capítulo | ID | Clase | Contexto / condición de diseño del mapa |
|---:|---|---|---|
| 31 | — | Sin clase nueva | Deducción y reconocimiento con sistema conocido |
| 32 | A07 | Caza multifunción | Proteger extracción de archivos desde el aire |
| 33 | M06 | Submarino | Variante costera: rescate/prueba desde zona marítima, con detección antisubmarina anunciada |
| 34 | — | Sin clase nueva | Defensa de archivos y revelación |
| 35 | — | Sin clase nueva | Recuperación de emisión y evidencia |
| 36 | — | Sin clase nueva | Escolta y rescate de testigos |
| 37 | M04 | Fragata | Asegurar rutas de ayuda y contrarrestar submarinos |
| 38 | A08 | Bombardero táctico | Poder destructivo contrastado con riesgo de escalada; misión cooperativa |
| 39 | M05 | Destructor | Apoyo marítimo de coalición, si el escenario incorpora costa, flota aliada y acceso justificado |
| 40 | M08 | Dron naval de superficie (USV) | Operación costera con pruebas; unidad consumible sin regreso después del impacto |

Las misiones 33, 39 y 40 deberán tener mapas **costeros/mixtos coherentes** o mover esos desbloqueos a otra misión naval del mismo acto **antes de cerrar guion**. En el caso 39, la Legión Ámbar controla la misión mientras un aliado presta el buque; no se inventa supremacía naval permanente para la facción.

### Acto V — El precio de detenerse (41–50): dominio total, 32 acumuladas

No se presentan clases obligatorias nuevas. El drama y la dificultad proceden de **combinarlas** con objetivos conflictivos, cooperación entre facciones, reabastecimiento, economía y restricciones de escenario transparentes. El capítulo 49 es la gran prueba de estrategia combinada y el 50 su desenlace variable. La disponibilidad en cada episodio depende del mapa y la situación narrativa, **no de olvidar desbloqueos**.

## UX — desbloqueo breve, claro, memorable

- Pantalla de desbloqueo **opcional y saltable** al principio o al concluir una misión: nombre, icono, rol, contrarespuesta, coste y 1 recomendación práctica.
- Si la clase es enemiga/aliada primero, registrar que fue **descubierta**, pero distinguir claramente cuándo puede producirse por el jugador.
- El árbol/registro de arsenal muestra **9/32 → 18/32 → 26/32 → 32/32** al concluir los actos respectivos.
- Los capítulos se guardan con su lista de unidades autorizadas; los mapas ya superados no cambian sorpresivamente por desbloqueos posteriores. Repetición libre usa los parámetros originales o un modo reto explícito separado.
- Si el jugador pierde, **no retira** desbloqueos anteriores, créditos de tienda real ni progreso; la progresión no se monetiza.

## Dependencias técnicas recomendadas

Datos por episodio, no reglas dispersas en UI:
```json
{
  "chapter_id": 13,
  "story_title": "Suelo de ceniza",
  "unlocks": ["G09"],
  "player_faction": "confederacion_solar",
  "required_roles": ["infantry", "armored"],
  "allowed_domain": ["ground", "air"],
  "production_facilities": ["barracks", "armor_factory"],
  "mission_flags": [],
  "introductions_shown": [],
  "save_schema_version": 1
}
```

El guardado de campaña persiste IDs de capítulos completados, clases descubiertas/desbloqueadas, decisiones, tres tipos de final y estado de misión en curso; el modo escaramuza/online **ignora este bloqueo de campaña** y usa solo disponibilidad técnica, reglas del servidor y costes de producción. El motor compartido determina capturas legales por `role == infantry`, no por facción ni por versión de historia.

### Pruebas que deben existir antes de habilitar progreso
1. Campaña C01 inicia solo con clases autorizadas de C01; C02 revela G03; C10 cierra con exactamente nueve clases conocidas, C20 con 18, C30 con 26, C40 con 32.
2. Ningún desbloqueo de historia modifica partidas aleatorias u online, ni estadísticas v0.1.
3. Cambiar de protagonista/facción no borra progreso del jugador ni permite fabricar en edificios incorrectos.
4. Todos los tipos de infantería pueden capturar, vehículos/barcos/drones no; el transporte sin desembarco tampoco.
5. Se muestra clase «descubierta» si se ve en el rival sin que se autorice a fabricarla antes de su misión de desbloqueo.
6. Guardar/cargar conserva progresión y no salta misiones ni duplica recompensas.
7. Victoria en una misión y repetición de capítulo no reescriben la ruta narrativa principal inadvertidamente.
8. Los capítulos acuáticos/aéreos incluyen mapas y amenazas que prueban roles y contramedidas sin sorpresas irresolubles.
9. La progresión no exige conexión ni bloquea modos libres por no terminar la campaña.

**Definición de avance:** este es un plan detallado de desbloqueos, no una afirmación de que el motor de Godot, los capítulos o las 32 unidades estén ya programados.
