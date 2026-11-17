# TARVOKA — Programa de IA rival inteligente, justa y rejugable (v3.1)

**17 de noviembre de 2026 · Diseño técnico + primer cambio experimental**
**PR #527** https://github.com/edwinrodri12/Tarvoka/pull/527 · **no incorporado a main ni a APK.**

## A qué queremos llegar

La IA no debe ser una rutina fácil de explotar, ni un enemigo omnisciente con dinero, daño, visión o acciones adicionales. Queremos un rival capaz de **conquistar, proteger su economía, evaluar amenazas, combinar armas, flanquear, cortar suministros, preparar ofensivas y retirarse cuando convenga**. Tiene que equivocarse de formas comprensibles en niveles iniciales, pero no repetir sistemáticamente las mismas decisiones malas.

La IA del juego **ya tiene capacidades reales** en `scripts/core/BasicAI.gd`: daño previo a atacar, ataque letal prioritario, movimiento/ataque en mismo turno, capturas, retirada, suministro, defensa de relés, exploración con niebla, rutas con costes ponderados y compra según amenazas. Sería incorrecto llamarla "sin IA". Su principal limitación es **la coordinación estratégica a varios turnos**, frente a reglas de prioridad fija. Separadamente existe la IA de laboratorio `StrategicMatchBalanceV21.gd`, que fue la usada para las series de 144/48/36 partidas anteriores. **No confundir esas mediciones con el comportamiento del bot real en APK.**

## Hallazgos verificados (bots experimentales, no BasicAI shipping)

- v3.0: mover tropas antes de comprar (en el simulador) cambió el 10×8 de **0/4 a 1/4** victorias de presión, y 24×18 abierto de **0/4 a 2/4**; en bosque bajó de **1/4 a 0/4**. Eso confirma que optimizar una regla en un mapa puede perjudicar otro.
- Dar el Rompedor al Cuartel desde nivel I por sí solo no cambió las 4/4 derrotas de presión en 10×8. Una IA que lo compra siempre perjudica la captura de ciudades.
- Una IA adaptable de producción mejoró el daño y capturas en mapas medianos, pero siguió sin superar al rival en 10×8. La fuerza del tanque y el buen timing de acciones merecen más investigación antes de nerfs.
- Mapas aleatorios certificados [PR #521](https://github.com/edwinrodri12/Tarvoka/pull/521) pasó pruebas de geografía y recursos, **no** pruebas de balance con bots de distinto nivel.

## Auditoría del BasicAI real: oportunidades principales

**P0 — Retirada por amenaza letal, no por número fijo de HP.**
En `BasicAI._defensive_retreat`, un `hp > 3` cancelaba siempre la evaluación incluso si un enemigo visible podía matar de inmediato. Nuevo `adaptive_lethal_retreat` opt-in: permite utilizar el pronóstico de `BattleActions.public_preview_exchange` para **cualquier** HP, sin leer munición/reacción privada y solo retirarse a casillas legales fuera de ataque inmediato y cerca de aliados. Conservar ataque letal como opción de mayor prioridad. Requiere CI y pruebas de efectos secundarios antes de activarlo.

**P0 — IA estratégica de composición y economía por dominio.**
No elegir unidades con una lista fija. Puntuar opciones por:
1. amenazas enemigas **observadas** (blindados, aire, artillería);
2. oportunidades de capturar ciudades con unidades realmente habilitadas;
3. presupuesto y coste de oportunidad, incluyendo instalaciones bloqueadas;
4. suministros, estado de munición/combustible y distancia de refuerzos;
5. papel actual del ejército (conquista, defensa, asedio, contraataque).
La IA experimental probó que no basta con producir más Rompedores. Se requiere comparar la política con la IA real mediante escenarios reproducibles.

**P1 — Planificación por objetivos durante varios turnos.**
Proponer **2–3 objetivos activos** por ejército (p. ej. asegurar dos ciudades, defender base, presionar un flanco). Cada unidad recibe un papel con utilidad incremental, no todos persiguen el enemigo más cercano. Replanificar si ocurre captura, aparición visible de tanque, suministro crítico o posibilidad de victoria, evitando oscilación entre objetivos.

**P1 — Mapa de influencia y fuego coordinado.**
Para cada casilla conocida, estimar amenaza **solo de enemigos visibles y contactos obsoletos como incertidumbre, no ubicación exacta**. Ponderar cobertura, elevación, zonas de ataque legal, alcance mínimo, contrafuego, movilidad tras ataque, apoyo lateral, munición, defensa del HQ y riesgo para una unidad que captura. Evaluar pequeñas combinaciones de acciones: mover y luego atacar, atraer fuego, cerrar un cerco, retirar un herido y sostener el frente. El plan debe usar vista previa pública, nunca datos privados ni un golpe ficticio.

**P1 — Objetivos que realmente terminen partidas.**
Dejar de perseguir eliminación total como única línea de acción. Con un HQ capturable y avisos públicos (en **otra** PR validada), entrenar decisiones de defensa, interrupción de capturas, retirada hacia ciudad y contraataque estratégico. Evitar victoria por timer inventada.

**P1 — Dificultad con equidad.**
- Fácil: menor profundidad de búsqueda, menos coordinación, objetivos simples y comunicación de errores; sin dinero mágico.
- Normal: economía + objetivos + riesgo inmediato + apoyo mixto; comportamiento adaptativo real.
- Difícil: búsqueda 1–2 movimientos, flanqueos, coordinación de artillería, gestión de poder, guerra de información; CPU/memoria limitados para Android.
- Experto: variantes de mejor respuesta y más profundidad con presupuesto de tiempo; **sin ver enemigos ocultos, sin alterar daño, ingresos, coste o acciones**.

## Arquitectura recomendada

```text
Estado del juego (autoridad: Session)
         |
         v
Vista observada por facción (Visibility: SIN trampas)
         |
         v
Inteligencia / amenazas conocidas / objetivos de mapa
         |
         v
Director estratégico [expandir / defender / romper / asediar]
         |
         v
Director táctico [amenaza, cobertura, flanqueo, secuencia de acciones]
         |
         v
Evaluador económico [producción, suministros, riesgo de gasto]
         |
         v
Candidatos de órdenes -> preview público -> puntuación comparable
         |
         v
Ejecución SOLO por BattleSession / órdenes válidas
         |
         v
Telemetría de decisiones y ligas de bots + QA Android
```

**Algoritmo práctico inicial:** utilidad ponderada, mapas de influencia y búsqueda limitada de acciones. No introducir redes neuronales/LLMs en la APK ni servidor ni costes de suscripción: priorizar IA local/offline, determinista, auditable y ágil en un teléfono medio. Una IA fuerte debe poder explicar por qué puso una unidad en una casilla o no atacó.

## Pruebas que impiden publicar una IA "lista" sin evidencia

1. **Integridad:** cada acción debe ser legal, reproducible, sin cambios arbitrarios en input ni recursos, sin información oculta. Pruebas con enemigos desconocidos en dos ubicaciones equivalentes no deben cambiar una decisión que no podía observarlos.
2. **Calidad táctica:** escenarios ad hoc para no sacrificar unidades que podrían escapar, priorizar remates, proteger a un capturador, no mover artillería al contacto sin necesidad, y mantener líneas de reabastecimiento.
3. **Económica:** aceptar producción mixta, evitar bloqueo de casilla de fábrica, no comprar contraunidades innecesarias, y mantener suficientes soldados para capturar.
4. **Estratégica:** mapas con dos rutas, distintas condiciones de ciudad/ingresos, juego con niebla, contraestrategias y victoria por captura visible.
5. **Meta:** pares intercambiando lado, iniciativa, mapa y semillas con políticas diversas; contabilizar **victorias, derrotas y censura**. No adjudicar victoria porque acabó el tiempo.
6. **Rendimiento:** CPU/batería/carga por turno en Android 10×8, 24×18 y 40×30. Prototipos de búsqueda solo después de presupuestar el tiempo de decisión y memoria.
7. **Experiencia:** jugar contra humanos de habilidad distinta; registrar situaciones que parecían absurdas y alternativas concretas sin añadir ayudas invisibles.

## Secuencia de trabajo

- **E-AI1 (PR #527)**: amenaza letal por daño visible, no HP fijo, desactivada por defecto hasta CI. Mantener pruebas de retirada clásica, niebla, rutas, autopartidas.
- **E-AI2**: instalar un director de objetivos de varios turnos sin multiplicar estados de guardado; probar por partida y mapa. Comenzar con lógica solo observada, no con poderes.
- **E-AI3**: mapa de influencia y coordinación: defender capturadores, evitar ataque suicida, garantizar asistencia legal. Reducir previsibilidad.
- **E-AI4**: conectar la composición económica a las reglas reales del cuartel, las plantas y ciudades, después de confirmar v2.7/v2.9/v3.0.
- **E-AI5**: suite continua de 100+ mapas/semillas/estrategias verdaderamente diferentes, con versiones de heurística y métrica por dificultad.
- **E-AI6**: entrenamiento de decisiones con HQ, comandantes, poderes, niveles, clima, tropas terrestres/aéreas/navales y campamentos; test físico de Android antes de distribuir.

**Nunca aceptar "más victorias" como único objetivo**: un rival tramposo podría ganarlas sin ser justo; uno incapaz de terminar partidas podría parecer equilibrado. Medir juntas dificultad, legitimidad, duración, diversidad y diversión.
