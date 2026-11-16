# TARVOKA — Instalaciones fijas conquistables y campamentos construibles

**16 noviembre 2026 · PR #394, en borrador · Modelo experimental v1.7**

## Decisiones de diseño del usuario

1. **Las ciudades y todos los edificios que fabrican unidades están distribuidos de antemano por el mapa**. El número y tipo de centros de producción dependen del tamaño y terreno del escenario. Hay pocos centros bajo control inicial de cada ejército y varios neutrales para conquistar.
2. **No se permite construir ciudades ni fábricas, bases aéreas, navales, centros de drones o depósitos de artillería durante las partidas.** Pueden conquistarse, conservarse, repararse cuando existan reglas para ello y **mejorarse de nivel I–III**, pero subir de nivel NO crea una instalación nueva.
3. **Las únicas estructuras que pueden levantar los jugadores son campamentos**, con funciones específicas (suministros, reconocimiento, médico y defensivo). **Cada tipo tiene un especialista de infantería propio**; no hay constructor universal. No se permite que un campamento produzca unidades ni genere créditos.
4. Se conserva el principio de **escasez económica controlada y objetivos territoriales**: pocos ingresos/instalaciones iniciales, muchas ciudades y bases neutrales con valor estratégico para disputar. Los números de ingresos, costes y cantidad de edificios deben comprobarse por balance antes de incorporarse al APK.

## Modelo experimental de mapa — propuesta numérica para probar

| Mapa | Ciudades iniciales / ejército | Ciudades neutrales | Centros productores iniciales / ejército | Centros productores neutrales | Total de centros de producción |
|---|---:|---:|---:|---:|---:|
| 10×8 | 1 | 2 | 1 | 2 | 4 |
| 24×18 | 2 | 8 | 2 | 6 | 10 |
| 40×30 | 3 | 10 | 3 | 8 | 14 |

**Mapas con agua navegable:** puede añadirse *un par de astilleros neutrales*, elevando el límite de centros productores a **6, 12 o 16**, respectivamente, solo si el generador encuentra dos casillas marítimas válidas y simétricas. No se crean bases navales sobre tierra. Los astilleros no están garantizados en mapas sin agua apta.

**Edificios iniciales y neutrales por tamaño**:

| Tamaño | Bajo control de cada ejército al inicio | Parejas de instalaciones neutrales |
|---|---|---|
| Pequeño | Cuartel de infantería | Plantas de blindados |
| Mediano | Cuartel de infantería, planta de blindados | Artillería, drones, base aérea |
| Grande | Cuartel de infantería, planta de blindados, artillería | Cuartel avanzado, otra planta blindada, drones, base aérea |

Cada «pareja neutral» coloca dos centros de producción en posiciones simétricas de ambos lados; puede generar dos objetivos de conquista independientes. Si el mapa tiene agua simétrica útil, se agrega el par naval mencionado. **Todos son construcciones preexistentes fijas, no nuevos edificios desplegados por un soldado**.

### Ingresos por ciudad

Los ingresos de referencia de 250/125/83/62 créditos para 4/8/12/16 ciudades (del laboratorio v1.4) mantienen la renta total posible del mapa cerca de 1.000 créditos/turno de conjunto. Como ahora los ejércitos comienzan con MENOS ciudades, su ingreso inicial por jugador se reduce:

| Mapa | Ciudades cada uno | Ingreso inicial / turno / jugador | Renta total del mapa posible |
|---|---:|---:|---:|
| 10×8 | 1 × 250 | 250 | 1.000 |
| 24×18 | 2 × 83 | 166 | 996 |
| 40×30 | 3 × 62 | 186 | 992 |

**Riesgo económico:** 166/186 frente a los 249/248 de las configuraciones iniciales anteriores ralentiza compra de tanques, niveles III y recuperaciones. No reducir precios automáticamente ni aprobar esos ingresos sin partidas: quizá los jugadores capturen neutrales pronto y compensen, o quizá se estanque la producción. Se preservan los 2.500 créditos iniciales del modo moderno solo como referencia de laboratorio.

## Captura de instalaciones productoras

El experimento `scripts/experiments/StrategicMapSitesV17.gd` crea posiciones simétricas de instalaciones, valida capacidad/terreno y controla cambios de propietario a través de `capture_end_turn`.

- La instalación solo cambia de propietario cuando **la misma unidad de infantería capturadora** permanece ocupándola durante **dos fases propias**. Un turno enemigo vacío no borra el progreso de ocupación.
- Los tanques, aviones y buques **no capturan** instalaciones, igual que en las reglas actuales.
- Capturar no aumenta el número de bases ni modifica la posición original; la instalación no transfiere automáticamente mejoras de nivel anteriores (regla separada en `BuildingProgressionV12`).
- No existe acción para construir un centro productor. `prohibited_build_producer` reconoce todos los tipos de instalaciones militares que deben quedar fijados al generarse el mapa.

**Limitación de integración:** `UrbanEconomy.MAX_SITES=16` agrupa *TODAS* las ciudades y centros productores. La propuesta 24×18 con 12 ciudades + 10–12 productoras necesita capacidad **22–24**, y la de 40×30 con 16+14–16 necesita **30–32**. El prototipo es un *modelo paralelo*, no una economía oficial validada por `BattleSession` ni una partida que se pueda guardar en `SaveCodec` v1. La IA, generador de mapa, guardado, HUD y capturas deben migrar juntos antes de usar estos mapas realmente.

## Campamentos: ÚNICAS estructuras construibles

| Campamento | Infantería especializada que puede levantarlo | Estado del rol hoy | Función prevista |
|---|---|---|---|
| Suministros | **Intendente / especialista logístico de infantería** (`quartermaster`) | Nuevo rol por desarrollar | Reabastecer combustible/municiones de unidades compatibles pagando recursos y turnos; no fabricará unidades |
| Reconocimiento | **Rastreador** (`scout`) | Unidad ya existente | Incrementar visión sobre territorio cercano, especialmente con niebla de guerra |
| Médico | **Sanitario de combate** (`field_medic`) | Nuevo rol por desarrollar | Recuperar vida de infantería cercana pagando recursos; no reparar tanques |
| Defensivo | **Ingeniero** (`engineer`) | Unidad ya existente | Cobertura y fortificación en posición; no disparo automático |

Se necesitan **dos especialidades de infantería nuevas** para habilitar los campamentos médico y de suministros. En el laboratorio **están BLOQUEADOS**, incluso si se intenta pasar un objeto que declare de forma falsa `role="field_medic"` o `role="quartermaster"`: la clase debe estar implementada y validada por el motor, no solo escribir su nombre.

Los campamentos de Rastreador e Ingeniero se pueden colocar solo en terrenos compatibles, con la unidad correcta, viva, en su propio turno, sin haber gastado la acción y sin superponerse con ciudades, fábricas, otras instalaciones, campamentos previos ni unidades enemigas. Consumirían créditos y la acción del constructor; los campamentos son **puntos de apoyo**, no un medio de producir más ejército.

### Límites y costos exclusivamente para experimentación

| Mapa | Máximo de campamentos por facción | Suministros | Reconocimiento | Médico | Defensivo |
|---|---:|---:|---:|---:|---:|
| 10×8 | 2 | 150 | 100 | 140 | 130 |
| 24×18 | 4 | 150 | 100 | 140 | 130 |
| 40×30 | 6 | 150 | 100 | 140 | 130 |

**Costes indicativos, no aprobados.** Todavía no hay reabastecimiento, curación o modificación de cobertura procedentes de los campamentos; el prototipo solo prueba colocación, propiedad, costo y restricción de constructor. Los efectos deberán integrarse en las reglas de visión, suministros, salud y terreno y equilibrarse contra tecnologías de edificios y veteranía individual.

## Código y pruebas

- `scripts/experiments/StrategicMapSitesV17.gd` — composición del mapa, límites de productores, ciudades de inicio, centros neutrales y captura por infantería.
- `scripts/experiments/SpecialistCampsV17.gd` — cuatro clases de campamentos con constructores exclusivos y bloqueo de roles no implementados.
- `tests/test_fixed_producer_sites_v17.gd` — matrices de **12 mapas** (tres tamaños × cuatro tipos de escenario), ubicaciones espejo, cantidades máximas, bases neutrales y captura en dos fases propias.
- `tests/test_specialist_camps_v17.gd` — coloca campamentos con Rastreador/Ingeniero, rechaza unidad incorrecta, fondos insuficientes, solapamiento, falsa especialización y construcción de centros de producción.
- Workflow `.github/workflows/strategic-map-camps-v17.yml`. **No afirmar que las pruebas han aprobado hasta verificar el registro PASS en GitHub Actions.**

## Siguientes prioridades después de validar

1. Medir **tasas de captura, duración de partida y acceso de cada facción a diferentes categorías** con el número limitado de productores; hay que evitar que una sola conquista dé una ventaja definitiva.
2. Ensayar más ciudades y bases con **8 jugadores** cuando exista soporte real de ocho facciones: esta distribución y el código actual todavía son 1 vs. 1.
3. Diseñar y probar físicamente las dos especialidades faltantes (Intendente y Sanitario) y los efectos de los cuatro campamentos, con costes y contraataques.
4. Integrar en una PR separada las estructuras fijas/neutralidad en el generador oficial, **migrar el límite de instalaciones, guardado e IA**, y verificar que solo se ofrecen campamentos como construcción en el HUD.
5. Mantener la producción restringida por nivel de edificios I–III, y no crear un Centro de Investigación o talleres construibles nuevos.
