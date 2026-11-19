# TARVOKA v3.9.4 — Investigar el efecto de las primeras órdenes del respondedor sobre el doble puente

**18 de noviembre de 2026. Investigación controlada: no modifica IA, reglas de apertura, economía, relés ni APK.**

## Resultados confirmados

- [v3.9.2, **17/17 SUCCESS**](https://github.com/edwinrodri12/Tarvoka/actions/runs/44418543642): con la **apertura oficial**, IA actual y la variante opt-in de presión tardía sobre relés obtuvieron exactamente **12 victorias del iniciador y 20 del respondedor**, con 0 censuras en las 32 condiciones originales, y 572 medios turnos totales para cada política. Solo dos decisiones cambiaron, sin modificar ganador ni duración. La táctica opt-in sigue **DESACTIVADA**.
- [v3.9.3, **17/17 SUCCESS**](https://github.com/edwinrodri12/Tarvoka/actions/runs/44419382374): en ocho semillas 40×30 de doble puente, 32 condiciones originales y 32 reflejos, **6 victorias del iniciador y 26 del respondedor**, 0 censuras. Seis semillas realmente nuevas: **6 primero / 18 segundo**.
- En **ausencia de niebla**, **16/16 condiciones** terminaron con victoria del respondedor en 12 medios turnos, antes de que se capturara alguna ciudad. El respondedor tomó primero un relé en **fase 7 (octavo medio turno)**, luego los otros en fases 9 y 11. El iniciador rara vez capturó un relé antes de su derrota. Con niebla, el dominio no fue universal: el iniciador ganó 6/16, en las semillas 646, 650 y 654, ambos colores.
- La observación apunta a una carrera de acceso a relés y a la diferencia de oportunidades de órdenes, **pero no demuestra aún causalidad**.

## Comparación controlada v3.9.4

**Pregunta:** ¿la victoria sin niebla del respondedor exige usar las ocho órdenes de su primera respuesta, o persiste si termina voluntariamente esa sola respuesta antes?

Usar **la misma IA real**, el mismo tablero, la misma semilla, las mismas tropas, niebla DESACTIVADA, ingresos y estados iniciales. En cada condición original comparar:

1. **Apertura oficial**: inicia con 3 órdenes por regla existente; el respondedor usa todas sus 8 órdenes legales de la primera respuesta.
2. **Contrafactual cap3**: las tres acciones iniciales del respondedor son idénticas a las oficiales, pero se detiene voluntariamente después de la tercera orden solo en esa primera respuesta. El resto de la partida usa exactamente las reglas habituales.
3. **Contrafactual cap5**: igual, conservando sus cinco órdenes iniciales y terminando voluntariamente únicamente esa respuesta; todas las rondas posteriores normales.

Esta comparación **no implementa ni recomienda** ninguna restricción de órdenes; es un procedimiento de diagnóstico, y los estudios v3.8.7–v3.8.8 ya mostraron que cap5 **no mejora de forma general** otros mapas.

Ocho semillas del estudio anterior: **634 y 638 de referencia**, y **642, 646, 650, 654, 658 y 662 como seis semillas nuevas** respecto de v3.9.2. Ambos colores como iniciadores y reflejo exacto de cada condición:
- **16 condiciones originales por política**, con 12 de semillas nuevas.
- **3 políticas × 16 casos × 2 (original y reflejo) = 96 partidas autoritativas**, pero los reflejos NO cuentan como muestras independientes.
- Limitar observación a 40 medios turnos; una partida sin ganador real se registra como **censurada**, jamás un empate o victoria inventados.
- Antes de la intervención, las 3 órdenes del iniciador y las primeras 3 o 5 del respondedor deben ser idénticas entre control y contrafactual.
- Cada resultado recopila la primera captura de relé por facción, cambios de propiedad, abonos de puntos a cada cierre de ronda, primera captura de ciudad, número de órdenes, resultado y duración; los reflejos deben coincidir exactamente en acciones y estados.

## Interpretación

Si cap3/cap5 altera el orden de acceso al primer relé y el ganador bajo este mapa controlado, hay evidencia de que **las órdenes de la primera respuesta intervienen causalmente en ese resultado** (para esta configuración de IA, terreno y semillas), **no** evidencia de que el límite sea una regla global adecuada.

Si no cambia el ganador, deben investigarse las decisiones posteriores, las rutas, el movimiento y la adquisición de relés, en vez de adjudicarle sin datos la culpa al primer turno largo.

El agregador debe separar los casos nuevos y los de referencia, registrar censuras y capturas, y no convertir espejos en nuevas observaciones.

**Esta rama sólo añade tests, CI y documentación, sin ningún archivo de producción modificado en v3.9.4.** PR DRAFT apilado sobre #603, sin merge y sin APK.
