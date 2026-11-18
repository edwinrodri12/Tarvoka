# TARVOKA v3.9.0 — Empate de relés 9–9: ¿partida larga o bloqueo real?

**18 de noviembre de 2026. Investigación de una censura real de la v3.8.8, sin alterar reglas.**

## Resultados de las pruebas previas (verificados)

- [v3.8.8, 18/18 trabajos](https://github.com/edwinrodri12/Tarvoka/actions/runs/44373996589): 8 semillas inéditas 634–641 × niebla sí/no × ambos iniciadores, 32 condiciones originales emparejadas por política, 128 partidas incluyendo reflejos. **Respuesta libre oficial: 12 victorias del primero, 20 del segundo, 0 censuras**. **Respuesta experimental cap 5: 10 del primero, 20 del segundo, 2 censuras**. Por tanto cap 5 **no mejora el resultado global** fuera de muestra y no debe convertirse en regla oficial.
- [v3.8.9, terreno 1/1](https://github.com/edwinrodri12/Tarvoka/actions/runs/44375906128) y [CI general Godot](https://github.com/edwinrodri12/Tarvoka/actions/runs/44375906088), ambas aprobadas. Las consultas de terreno vacío ya no generan errores de límites en las pruebas de combate y contraataque.
- [v3.8.7, 9/9](https://github.com/edwinrodri12/Tarvoka/actions/runs/44368832908): cap 4 = 0/16 victorias del iniciador, cap 5 = 6/16. El efecto de cambiar órdenes no es monótono; cuatro mapas no bastan para seleccionar una regla.

## Censura focal: semilla 636, niebla activada

En ambas identidades del iniciador, los partidos originales de v3.8.8 llegaron al límite de **32 medios turnos con puntuación 9–9 y sin ganador** bajo cap 5. En la misma situación con la apertura oficial sin cap adicional:

| Inicia | Ganador oficial | Medio turno de victoria | Puntos oficiales al terminar | Cap 5 tras 32 medios turnos |
|---:|---:|---:|---|---|
| 0 | 1 | 20 | [1, 6] | [9, 9] sin ganador |
| 1 | 0 | 20 | [6, 1] | [9, 9] sin ganador |

**Importante:** `RelayControl.score_winner` no declara ganador cuando ambas facciones tienen la misma señal, incluso si las dos alcanzaron el objetivo de 5. Esa es una condición **deliberada**, no un bug contable. Hasta que una se adelante, la partida sigue. La investigación debe comprobar si alguna consigue la diferencia después del turno 32.

## Qué se ha implementado

La prueba original `test_ai_opening_budget_counterfactual_v383.gd` acepta ahora un **parámetro opcional `max_half_turns` que por defecto sigue siendo 32**. Todas las invocaciones anteriores conservan su resultado. Los cambios de observación no modifican la IA ni las reglas del juego.

`tests/test_ai_relay_tie_extended_v390.gd` reproduce **únicamente** el mapa **636, 40×30, con niebla** y las dos identidades del iniciador, en ambos reflejos (cuatro partidas reales). El tope de observación experimental aumenta de 32 a **64 medios turnos**, sin cambiar el resto. Verifica:

1. Los tres movimientos iniciales del primer jugador y los cinco del segundo, y que ambos reflejos reproduzcan todas las decisiones y estados autoritativos sin divergencias.
2. El estado auténtico después de medio turno 32: marcador **[9,9]**, ningún ganador.
3. Todos los cambios de propietario de relés y puntos acreditados al terminar cada ronda: jamás contabilizar a mitad de ronda, y siempre abonar exactamente los relés del cierre.
4. La primera ronda de empate a partir de 5 puntos, la primera ventaja a partir de 5, duración máxima de un empate, capturas y unidades vivas, resultado al horizonte 64 o victoria natural anterior.
5. Si sigue sin ganarse después de 64 medios turnos, **registrarlo como censura**. No inventar empate, victoria, desempate por iniciativa ni una puntuación adicional.

El agregador Python debe recibir exactamente las **dos condiciones originales** y sus dos espejos (2 muestras independientes como máximo; mismo mapa y dos iniciadores correlacionados); escribe un JSON por ronda y Markdown compacto.

## Limitaciones

Esta investigación se centra en **un único mapa** responsable de las dos censuras observadas y su mecánica exacta de puntuación. No estima una tasa de empate a nivel de juego ni aprueba un cambio de reglas. Si aparece una racha prolongada de 9–9, la siguiente investigación será identificar cambios de relé y conductas de IA que la sostienen, no romperla arbitrariamente.

**PR DRAFT sobre v3.8.9**, sin fusiones en main ni cambios a APK, combate, IA, visibilidad, capturas, dinero, recursos iniciales o reglas de turnos.
