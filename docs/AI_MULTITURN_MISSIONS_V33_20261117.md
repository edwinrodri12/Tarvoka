# TARVOKA — IA con misiones persistentes y coordinación táctica v3.3

**17 de noviembre de 2026 · PR experimental #538 · basada en la IA v3.2 (12 dificultades/11 doctrinas). No integrada en main ni APK.**

## Avance concreto

Hasta v3.2, `BasicAI.step` evaluaba una acción a la vez con prioridades de capturar, atacar, comprar, abastecer o perseguir al enemigo. Repetir la rutina en el mismo turno podía hacer que varias infanterías abandonaran rutas planificadas o se aglomeraran en un único objetivo.

Esta versión introduce **misiones persistentes, inspeccionables y limitadas**: se asignan tropas a objetivos conocidos, se conservan entre acciones y turnos, se revisan después de cada acción, y se descartan cuando la situación visible exige hacerlo. No incrementa stats, economía, movilidad, daño, turnos ni información. El rival usa `Session.move`, `Session.attack` y `Session.purchase` exactamente como el humano.

## Comportamiento implementado

- **Niveles 1–4:** siguen usando el plan táctico más sencillo v3.2, para que la progresión de dificultad sea real. En nivel 4 se conserva la evaluación de retirada ante amenaza letal.
- **Niveles 5–12:** `MultiTurnObjectivesV33.refresh` organiza hasta **dos capturadores** para ciudades o fábricas **distintas**. Conserva objetivos de la misma unidad si siguen siendo posibles o están ocultos tras haber sido descubiertos.
- Hasta **dos unidades no capturadoras** (tanques u otros apoyos terrestres con ataque) pueden escoltar a la infantería o defender una instalación propia si enemigos **visibles** se acercan. Nunca se les ordena terminar **en la misma casilla reservada para capturar**.
- Cuando cambia la propiedad de una instalación, muere una unidad, o el plan deja de existir, se reevalúa con datos observados.
- **Prioridades del bot:** matar enemigos de forma segura, retirada cuando hay riesgo letal, suministros y defensa urgente mantienen su prioridad sobre la escolta. La nueva misión guía la preferencia entre destinos de captura y el movimiento de las unidades de apoyo cuando no existe una amenaza más urgente.
- El coste de movimiento considera terreno, clima, dominio, vehículos y caminos reales. Una caché por unidad evita recalcular todas las rutas por cada ciudad en un mapa 40×30.

### Información incompleta sin trampas

La IA únicamente recibe `Visibility.observed_state`, que oculta enemigos y cambios de propiedad fuera de visión y reemplaza terreno no explorado por casillas desconocidas.

Un objetivo previamente **explorado** puede conservarse como último dato conocido, incluso si el enemigo lo capturó fuera de visión: la IA **no sabe** de esa captura hasta volver a descubrirla. Una ciudad nunca vista no se añade como objetivo de captura. El estado persistido se valida además contra la exploración real del jugador: no se pueden inyectar misiones desde un guardado hacia casillas nunca exploradas.

## Guardados y compatibilidad

`SaveCodec` v1 añade solo si hace falta el campo optativo `ai_objectives`:

```
{
  "side": 1,
  "style": "expansion",
  "assignments": [
    {"unit_id":"X", "task":"capture", "kind":"city", "x":6, "y":4},
    {"unit_id":"Y", "task":"escort", "kind":"city", "x":6, "y":4}
  ]
}
```

- El ejemplo es ilustrativo, no prueba de que esas unidades existan en toda partida.
- Se limita a cuatro asignaciones en tres ubicaciones y dos capturas distintas.
- Cada unidad debe ser realmente propia; una tarea de captura exige infantería; una escolta exige unidad atacante terrestre.
- Cada ubicación debe ser una instalación real de tipo correcto y legal. No se aceptan edificios inventados, coordenadas fuera de mapa ni casillas bajo niebla nunca exploradas.
- Los nombres de objetivos no son nuevas órdenes ni permiten comprar/evolucionar unidades.
- `ai_config` debe existir antes de guardar objetivos. Las partidas antiguas, sin perfil configurado, conservan su esquema y comportamiento.
- Los objetivos siguen siendo válidos en el guardado si una unidad asignada muere durante el turno humano; el bot los limpia al volver a planificar.

## Qué todavía NO implementa

- Un verdadero árbol de búsqueda de dos o más turnos, simulación de contraataques enemigos, coordinación simultánea de cinco disparos, guerra de información probabilística o equipos con inteligencia neuronal.
- Defensa multiobjetivo de todas las bases y rutas de suministro, artillería coordinada con unidades exploradoras y protección de capturas expuestas. Esta primera versión asigna un máximo de dos escoltas y una tercera posición defensiva.
- Uso de evolución I/II/III, poderes de los ocho comandantes, campamentos o capacidades de transporte/sonar/EW aún no codificadas como acciones legales en `BattleSession`.
- Integración de arte 3D o modificación de la APK. Las regresiones y pruebas de rendimiento Android deben aprobarse.

## Pruebas Godot 4.3

`tests/test_ai_multiturn_objectives_v33.gd`:

- Dos infanterías asignadas a **objetivos de captura diferentes**, escoltas terrestres y retención de asignaciones entre decisiones.
- Enemigo observado que se acerca a ciudad propia: defensa prioritaria.
- Ciudad capturada: objetivo retirado, sin insistir en un edificio propio.
- Movimiento real emitido por `BasicAI.step`, actualización del plan, copia del estado original sin modificar.
- Guardado/carga v1 del plan, continuidad de misiones entre turnos y rechazo de IDs ajenos, tipo de instalación falso o coordenadas inyectadas.
- Misma decisión y objetivo si un enemigo cambia de posición/HP **fuera del rango visible**.
- Ocho regresiones del director anterior, la interfaz, economía, niebla y autojuego.

**No declarar el PR como integrado hasta obtener CI verde.** Un test aprobado de rutas y legalidad no demuestra mejor tasa de victoria ni un aumento monotónico de dificultad. La fase siguiente debe enfrentar v3.2 vs v3.3 con múltiples mapas, estilos y situaciones y registrar objetivos concretos terminados.

## Próxima prioridad tras validar

1. **Banco de escenarios con decisiones verificables:** medir cuántas ciudades capturó, defendió, perdió o recuperó la IA, tiempo hasta captura, frecuencia de cambios de objetivo, escoltas que estorban y costo de cada turno.
2. **Director operacional 2.0:** usar dos rutas de asedio, roles de blindaje/artillería/reconocimiento/suministro/aire/naval, planes de abastecimiento y tácticas de concentración de fuego. Un planificador más profundo solo cuando la versión actual deje de sacrificar Android.
3. **Evoluciones legales:** conectar mejoras de nivel II/III, campamentos y poderes de comandante al árbitro `BattleSession` (seguimiento [#534](https://github.com/edwinrodri12/Tarvoka/issues/534)); después la IA podrá pagarlas, decidir ramas y sincronizar las mejoras según su estrategia.
4. **Dificultad calibrada:** 12 niveles que escalen con calidad de planificación y presupuesto de CPU, no multiplicadores ocultos de recursos.

Referencias:
- [PR v3.2 — 12 niveles y 11 doctrinas](https://github.com/edwinrodri12/Tarvoka/pull/533)
- [PR v3.3 — misiones y escoltas](https://github.com/edwinrodri12/Tarvoka/pull/538)
- [Incidencia de IA P0](https://github.com/edwinrodri12/Tarvoka/issues/528)
