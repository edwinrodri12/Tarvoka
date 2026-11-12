# TARVOKA — Capítulo 01: ESCUDO COMPARTIDO

**Acto I — Las primeras 72 horas** · **Facción controlada: Alianza Norte (azul)** · **Contraparte de ejercicio: Pacto Escarlata (rojo)** · **Estado: guion + diseño de misión v0.1, NO implementado.**  
Relacionados: [CAMPAIGN_STORY_50.md](CAMPAIGN_STORY_50.md), [CAMPAIGN_UNIT_PROGRESSION.md](CAMPAIGN_UNIT_PROGRESSION.md), [CAMPAIGN_TECH_LEVELS_V1.md](CAMPAIGN_TECH_LEVELS_V1.md).

## 1. Objetivo del capítulo

El jugador debe **aprender movimiento, ataque y captura con Guardia (G01)** y experimentar una colaboración real entre dos ejércitos que pronto estarán enfrentados. La victoria no debe sentirse como el comienzo de una guerra. La historia tendrá peso porque el jugador **recordará** a ese comandante rojo como aliado del ejercicio cuando cambie de perspectiva en el capítulo 04 y posteriormente en el 10.

**Objetivo emocional:** generar respeto mutuo, confianza y un pequeño detalle no explicado que será una pista honesta del incidente de Nudo Siete.  
**Duración objetivo de juego:** sesión corta, referencia inicial de 6–10 turnos; ajustar tras pruebas reales.  
**Estructura:** intro de 25–45 s saltable + combate guiado + 2 eventos + epílogo de 20–40 s saltable.  
**Tecnología de campaña:** única familia controlable **G01 Guardia nivel I**. No enseñar aún G03 Rastreador, G05 Ingeniero ni drones jugables. Las figuras enemigas también usan G01; los soldados derrotados son marcados como «fuera de ejercicio», no muertos.

## 2. Protagonistas y postura

- **Comandante de Alianza Norte**: retrato oficial de mujer con boina azul; nombres propios y biografía exactos quedan pendientes de cotejar con fichas visuales aprobadas. En esta misión es firme, pragmática y algo escéptica de ejercicios ceremoniales.
- **Comandante del Pacto Escarlata**: retrato oficial de hombre con barba y uniforme rojo; ingenioso, formal y convencido de que los dos bandos son capaces de cooperar, aunque con reservas históricas.
- **Oficial de control de ejercicios**: voz neutral por radio (sin nuevo retrato, facción ni unidad). Registra órdenes y lee eventos. No se presenta todavía ninguna organización conspirativa nueva.
- **Meridian**: red civil-militar de corredores de energía, transporte y comunicaciones construida por los ocho estados. **Nudo Siete** es un punto de la red; no es un arma misteriosa ni una organización.

Los dos comandantes se respetan de verdad. Se evitará la escena cliché de que uno se burla del otro para anunciar que será un villano: en C01 ambos tienen buenas razones para querer paz y seguridad.

## 3. Narración antes de iniciar

**Texto de mapa estratégico (texto en 2 tarjetas opcionales, corto):**

> Durante treinta y dos años, la Red de Meridian ha llevado electricidad, combustible y mercancías a través de ocho territorios. Sus vías cruzan fronteras que los soldados apenas recuerdan haber defendido.

> Hoy, la Alianza Norte y el Pacto Escarlata realizan una maniobra conjunta en el corredor de Arven. El objetivo oficial es sencillo: comprobar que ambos ejércitos pueden compartir comunicaciones. Nadie sabe que el sistema está a punto de fallar.

**Escena A — Centro de coordinación, mañana**

- **NORTE:** «Nos piden demostrar que sabemos trabajar juntos. Preferiría demostrar que no necesitamos volver a combatir».
- **ESCARLATA:** «Entonces será el ejercicio más valioso que hemos organizado».
- **NORTE:** «¿Y si mis soldados ocupan su puesto de mando?».
- **ESCARLATA:** «Me alegrará comprobar que la Red funciona hasta en la derrota».
- **CONTROL:** «Ejercicio Escudo compartido. Munición de simulación. Dos balizas, objetivos visibles y reglas iguales para ambos bandos. Inicio autorizado».

**Instrucción UX:** flecha/overlay para primer toque en Guardia: muestra movimiento legal y diferencia visual de alcance de ataque. Puede omitirse sin bloquear controles. Primera elección táctil siempre confirmable, jamás ejecutar acción irreversible por un toque ambiguo.

## 4. Diseño de mapa para primer prototipo

**Tablero 10×8**, coordenadas **(x,y) base 0**, `x=0…9`, `y=0…7`, adaptado al motor actual sin simular IA amiga de una tercera facción.

- **Ambiente:** corredor de Arven, planicie con carreteras, bosque lateral y dos balizas de maniobra. Sin mar, aviación ni clima letal. Los caminos ofrecen avance rápido; bosques dan protección táctica si la regla de terreno actual lo permite.
- **Jugadores:** Alianza Norte = lado 0; Pacto Escarlata = lado 1 **como fuerza adversaria simulada**, aunque aliados en la ficción. En UI mostrar «Simulación — no es guerra real».
- **Unidades iniciales Norte (G01, nivel I):** (1,2), (1,4), (2,6). **Escarlata (G01, nivel I):** (7,2), (8,5). Valores de vida, coste, movimiento, ataque y defensa se toman del **motor real G01**, no se redefinen en guion.
- **Baliza A:** (4,2); **Baliza B:** (5,5). Son objetivos capturables mediante infantería del jugador; su comportamiento no supone ingresos especiales ni fabricación gratuita.
- **Terreno sugerido:** camino continuo (1,4) → (3,4) → (5,4) → (7,4); bosques dispersos en (3,2), (4,3), (6,5), (6,6); celdas restantes transitables salvo decoración. Verificar con `Rules.reachable` real antes de fijar mapa.
- **Visibilidad:** en el capítulo 01, vista abierta de entrenamiento; niebla sólo se enseña desde C02 para no multiplicar tutoriales.
- **IA rival:** proteger balizas, contraatacar sólo blancos legalmente alcanzables; sin refuerzos sorpresa ni capacidades inventadas. El jugador debe poder ganar con dos rutas distintas.

**Victoria primaria:** controlar **ambas balizas al inicio de uno de los siguientes turnos del jugador**, al menos durante el momento de comprobación; si pierden control, recuperarlas. **Derrota:** no conservar ninguna infantería capaz de capturar. Aceptar reiniciar el ejercicio sin penalización.

**Objetivos opcionales (medallas, sin bloqueo de progreso):**
- Completar en diez turnos o menos.
- Conservar dos escuadras de Norte en servicio.
- Capturar ambas balizas (objetivo principal, no calificar además como secreto).

**Compromiso técnico:** el prototipo actual comprueba victoria por supervivencia de una facción; una captura de dos objetivos de misión necesita un **MissionObjectiveEvaluator** futuro. Este documento no declara la misión jugable ni pretende que el sistema actual soporte estos disparadores. Antes de integrar el guion, implementar y probar condición multiobjetivo y evitar que eliminación total enemiga sustituya erróneamente la condición de captura.

## 5. Diálogos durante combate (dos eventos, cortos)

### Evento B — Primera vez que un Guardia alcanza una baliza

**Condición:** `first_capture == true`, sólo una vez, al finalizar la acción de captura.

- **CONTROL:** «Baliza asegurada. Confirmada la transmisión entre sectores».
- **ESCARLATA:** «Bien. Sus mapas y los míos muestran la misma posición».
- **NORTE:** «Eso debería ser lo normal».
- **CONTROL:** «Central registra un paquete de Nudo Siete recibido fuera de secuencia. Sin impacto en ejercicio».

**Subtexto:** sembrar una anomalía de registro **pequeña y verificable**, no revelar responsable ni crear un saboteador invisible. El comentario no debe interrumpir órdenes.

### Evento C — Primer combate de simulación o primera retirada rival

**Condición:** primer ataque válido; activación única, nunca por tocar erróneamente.

- **NORTE:** «Su escuadra tiene cobertura, pero dejó una ruta al descubierto».
- **ESCARLATA:** «Y la suya ganó una posición que ahora tiene que sostener. Siga».
- **CONTROL:** «Marcador actualizado. Pérdidas simuladas; sin bajas reales».

La escena enseña que **capturar** no equivale a **mantener** y no humilla al comandante derrotado.

## 6. Epílogo, decisión y conexión con C02

**Si el jugador vence:** 
- **ESCARLATA:** «Hoy conocí cómo piensa su ejército. Confío en que no necesitemos averiguarlo en otro campo».
- **NORTE:** «Entonces más nos vale mantener abiertas estas líneas».
- **CONTROL:** «Ejercicio completado. Balance táctico archivado. Se cierra el canal conjunto».
- **NORTE, en privado:** «¿Recibieron el informe de la estación Nudo Siete?».
- **OFICIAL:** «Aún no. Dicen que fue sólo un paquete tardío».

**Si el jugador fracasa:** reinicio breve con reconocimiento respetuoso; mismos objetivos, sin castigo ni bloqueo de progreso.

**Gancho hacia C02:** último plano muestra una pantalla de comunicaciones con marcas de tiempo desordenadas en el archivo de Nudo Siete; ninguna figura misteriosa ni amenaza. El corte conduce a **«Dos minutos de silencio»**, primera perspectiva de Orden Ónix. Si se salta la escena, el registro de campaña ofrece una línea de resumen.

**No hay elección con ramificación todavía.** Las elecciones serias comienzan cuando el jugador ha entendido sus consecuencias; una decisión falsa en C01 erosionaría la confianza.

## 7. Datos orientativos para implementación posterior

```json
{
  "schema": "tarvoka.story_mission.v1",
  "id": "C01",
  "act": 1,
  "title": "Escudo compartido",
  "player_faction": "alianza_norte",
  "opponent_faction": "pacto_escarlata",
  "simulation": true,
  "board": {"width": 10, "height": 8},
  "player_units": [
    {"unit_family": "G01", "level": 1, "x": 1, "y": 2},
    {"unit_family": "G01", "level": 1, "x": 1, "y": 4},
    {"unit_family": "G01", "level": 1, "x": 2, "y": 6}
  ],
  "enemy_units": [
    {"unit_family": "G01", "level": 1, "x": 7, "y": 2},
    {"unit_family": "G01", "level": 1, "x": 8, "y": 5}
  ],
  "capture_targets": [[4, 2], [5, 5]],
  "victory": {"type": "hold_all_targets", "verify_at": "player_turn_start"},
  "loss": {"type": "no_capturing_infantry"},
  "unlocks_on_success": [{"family": "G01", "level": 1}],
  "dialogue_events": ["C01_START", "C01_FIRST_CAPTURE", "C01_FIRST_ATTACK", "C01_SUCCESS"],
  "campaign_flags_on_success": ["norte_y_escarlata_ejercicio", "anomalia_nudo_siete_escuchada"]
}
```

### Pruebas de aceptación

1. C01 solo usa G01: intentar producir G03 o G09 sin permiso debe fallar por campaña; en modo libre no hay esa restricción.
2. Ningún vehículo captura; captura sólo la infantería G01. Asegurar que ambas balizas son alcanzables por dos rutas legales.
3. Reconocimiento de victoria requiere **dos** balizas y control al momento indicado; nunca victoria antes de terminar el turno rival.
4. Primer ataque/primera captura disparan una sola vez cada diálogo y los datos se guardan sin duplicaciones tras cargar.
5. Derrota y reinicio no retiran progreso previo; victoria registra capítulo y desbloqueo una sola vez.
6. Saltar diálogos no evita objetivos ni provoca eventos omitidos; resumen está disponible en el expediente.
7. La derrota del entrenamiento no representa muertes canónicas; colores/retratos oficiales de ambas facciones se conservan.

**Preparación siguiente:** C02 «Dos minutos de silencio» debe tomar la pista del paquete fuera de secuencia y convertirla en una misión real de reconocimiento, sin atribuir culpa a ningún bando antes de que el jugador tenga evidencias.
