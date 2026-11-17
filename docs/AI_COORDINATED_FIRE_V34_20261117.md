# TARVOKA — IA v3.4: fuego combinado y protección táctica sin trampas

**17 de noviembre de 2026. Rama experimental y PR borrador #540, basado en la IA v3.3.**
**Estado inicial del proyecto:** v3.3 obtuvo **9/9 trabajos Godot 4.3 satisfactorios** en [CI #44153338491](https://github.com/edwinrodri12/Tarvoka/actions/runs/44153338491).

## Objetivo y problema real

El motor `BasicAI` ya priorizaba un disparo letal individual, los disparos de municiones descartables, retirada por peligro, defensa/captura/suministros y, desde v3.3, misiones de varias unidades. **Pero no sabía reconocer con anticipación una secuencia de dos o tres disparos legales que mata a un enemigo que sobreviviría a cada disparo individual.**

En el modo difícil, los jugadores deben ver decisiones de armas combinadas, no una IA que pierde un blindado importante por atacar un enemigo poco relevante o dispersar sus ataques.

## Implementado en v3.4

Nueva pieza `scripts/core/CoordinatedFireV34.gd`, conectada a `BasicAI.step`:
- **Niveles 1–6:** sin nuevo planificador. Siguen las heurísticas existentes.
- **Niveles 7–9:** consideran secuencias **de dos ataques** coordinados que proyectan eliminar un objetivo actual.
- **Niveles 10–12:** buscan también secuencias **de tres ataques**. No puede realizar ataques extra: un paso de IA emite una única acción.
- **Observación pública:** únicamente unidades enemigas actualmente visibles y nuestras unidades libres de actuar. No se lee munición, estado de reacción ni unidades ocultas. El motor `BattleActions.public_preview_exchange` calcula daño, cobertura, bonificaciones de flanqueo, distancias/alcances y **riesgo conservador de contraataque**.
- **Objetivos de mayor interés:** amenazas cerca de un capturador que esté **realmente sobre una ciudad neutral/enemiga**, unidades de artillería propias y edificios que controlamos. El bonus es solo para elegir el objetivo; **no modifica los daños**.
- **Supervivencia:** rechaza planes cuyo ataque no descartable implicaría perder innecesariamente un integrante al contraatacar; los drones/municiones de un solo uso se contabilizan como sacrificio esperado con penalización.
- **Límite de computación:** máximo ocho enemigos visibles y seis atacantes por objetivo; la búsqueda está limitada a secuencias de hasta tres, y no calcula triples redundantes si los dos primeros ya matan. Sin algoritmos de nube, Internet, modelos externos ni cuotas.
- **Ejecución autorizada:** la IA decide el **primer** disparo, luego `BattleSession.attack` verifica legalidad, cobertura y efectos reales; tras ejecutar una acción, el motor recalcula el siguiente paso y puede terminar la secuencia si cambió la batalla. Nada se introduce directamente en el arreglo de unidades.
- **Compatibilidad:** no cambia `SaveCodec`, dinero, daño, XP, tecnología ni poderes. Se conservan 12 niveles, 11 doctrinas y planes persistentes de la v3.3.

## Pruebas preparadas

`tests/test_ai_coordinated_fire_v34.gd` comprueba:
1. **Dos Guardias:** ninguno vence individualmente, el plan conjunto ejecuta el primer golpe y luego el segundo mata con acciones legales, conservando dinero y sin mutar la entrada.
2. **Tres Rastreadores:** dos no bastan; solo la dificultad 10–12 busca tres golpes y culmina un objetivo.
3. **Tres Rompedores contra tanque herido:** los dos primeros son insuficientes; tres golpes reales rematan un tanque de 7 HP con blindaje real, sin regalo de +2 de tecnología.
4. **Captura y artillería:** un enemigo que amenaza al ocupante de una ciudad o una pieza de artillería gana prioridad respecto a un enemigo equivalente que no amenaza objetivo.
5. **Rechazo del sacrificio:** si los dos tiradores caerían por contraataque antes de completar el plan, el planificador no selecciona esa secuencia.
6. **Niebla de guerra:** cambiar posición y HP de un enemigo oculto no cambia la secuencia ni la orden de la IA.
7. **Regresiones:** misión v3.3, 12 niveles y menú/guardado v3.2, combate, niebla, autojuego, economía y dominios.

Las pruebas de GitHub Actions deben ser **verificadas antes de aprobar el PR**; CI verde certifica funcionamiento básico, no calidad competitiva contra personas.

## Qué falta y cuáles son las siguientes prioridades

1. **Movimiento para habilitar un disparo posterior:** actualmente solo se coordinan tiradores **ya a alcance**. La etapa v3.5 debe estudiar rutas/tropas para crear un cerco legal y posiciones de artillería protegidas, sin mover un capturador de su ciudad. Evitar que la IA dispare con una unidad destinada a un objetivo más importante.
2. **Combate multifase y riesgo del turno enemigo:** evaluar contraataques en el siguiente turno con visibilidad incompleta y presupuesto de cómputo Android, sin convertir a la IA en un enemigo omnisciente.
3. **Formaciones por terreno:** cobertura, montaña, flancos, línea de suministro y antiaéreos según tipo real de unidad.
4. **Armas combinadas e evoluciones:** producción adaptativa y tecnologías I/II/III **solo cuando la capa de acciones de evolución y poderes sea legal y esté implementada** (issue [#534](https://github.com/edwinrodri12/Tarvoka/issues/534)).
5. **Torneos de dificultad:** probar que las habilidades 7, 9, 10 y 12 resultan más efectivas en distintas partidas; que una mejora no funcione en la llanura pero perjudique siempre en el bosque. Separar jugabilidad y habilidad de estadísticas injustas.

## Enlaces

- [PR v3.4](https://github.com/edwinrodri12/Tarvoka/pull/540)
- [CI v3.3 aprobado](https://github.com/edwinrodri12/Tarvoka/actions/runs/44153338491)
- [Programa de IA P0](https://github.com/edwinrodri12/Tarvoka/issues/528)
- [Tareas de evoluciones/poderes](https://github.com/edwinrodri12/Tarvoka/issues/534)

**No se fusiona a `main` ni se distribuye APK hasta cerrar CI y pruebas de rendimiento/dificultad.**
