# TARVOKA v3.9.5 — La cuarta orden del respondedor en los mapas de doble puente

**18 de noviembre de 2026. Investigación diagnóstica, no política para el juego comercial.**

## Evidencia cerrada antes de esta etapa

- [v3.9.2, 17/17](https://github.com/edwinrodri12/Tarvoka/actions/runs/44418543642): la IA opcional de presión tardía a relés no cambia resultados con apertura oficial (12 primero / 20 segundo en 32 condiciones), ni el promedio de duración. Permanece desactivada.
- [v3.9.3, 17/17](https://github.com/edwinrodri12/Tarvoka/actions/runs/44419382374): en mapas de dos puentes 40×30, sin niebla el respondedor ganó **16/16**; con niebla hubo seis victorias del iniciador en 16 condiciones. Sin niebla, el segundo tomó el primer relé en fase 7, después de la respuesta inicial, y ganó en 12 medios turnos.
- [v3.9.4, 9/9](https://github.com/edwinrodri12/Tarvoka/actions/runs/44425512681): mismas ocho semillas y ambos iniciadores, sin niebla, simulando que el respondedor termina SOLO su primera respuesta tras 3 o 5 órdenes, con el resto de reglas idénticas:
  - Apertura oficial, 8 órdenes: **0 victorias del iniciador / 16 del respondedor**, todos ganaron en 12 medios turnos.
  - **Cap5** (solo experimental): idéntico **0/16**, misma duración y orden de primeras capturas.
  - **Cap3** (solo experimental): **14 victorias del iniciador / 2 del respondedor**; el primero capturó el primer relé en 16/16 condiciones. La excepción de ganador fue semilla 650, ambos iniciadores.
  - Cada condición fue reflejada sin divergencias; 96 sesiones reales, pero 16 resultados originales por política.

Esto muestra que **alguna decisión adicional entre la tercera y quinta orden** es crucial en esta carrera, pero no identifica si es exactamente la cuarta, la quinta o una combinación. Tampoco recomienda imponer cap3: invertiría casi por completo la ventaja en estos mapas.

## Procedimiento v3.9.5

Se introducen **cuatro políticas simuladas, solo en pruebas**, sobre las mismas ocho semillas 634/638/642/646/650/654/658/662 de mapa tipo 2 (40×30), sin niebla y con ambos colores como iniciadores:

1. Apertura oficial: respondedor libre de emplear sus ocho órdenes.
2. Respuesta voluntariamente terminada tras **3 órdenes** (control del extremo corto).
3. Respuesta voluntariamente terminada tras **4 órdenes** (**intervención nueva**).
4. Respuesta voluntariamente terminada tras **5 órdenes** (control del extremo largo).

En todas ellas el primer jugador tiene exactamente tres órdenes al empezar, y los turnos posteriores a la primera respuesta mantienen IA, ingresos, combate, movimiento, puntos, abastecimiento y reglas oficiales sin modificación. No se cambia el código del videojuego.

Cada resultado registra las primeras tres órdenes del primer jugador y las cinco primeras del segundo, **la cuarta y quinta decisiones oficiales concretas**, la primera captura de relé de cada jugador, relés capturados, primera captura de ciudad, medios turnos, ganador y puntuación.

- Se exigen decisiones iniciales idénticas: tres acciones del iniciador iguales en todas las políticas; las primeras 3/4/5 órdenes del respondedor son exactamente los prefijos de la apertura oficial.
- Se reproducen **todos los estados y decisiones** horizontalmente reflejados, así como ganador, estados y puntuación exactos.
- **16 condiciones originales por política**, 4 políticas × 16 × 2 reflejos = **128 sesiones reales**, pero únicamente 16 observaciones originales por política; seis semillas eran nuevas respecto de v3.9.2, aunque todas se estudiaron ya en v3.9.4.
- Horizonte 40 medios turnos y censura etiquetada si no existe ganador, sin adjudicar empates.
- Agregador estricto con 8 shards Godot 4.3 y consolidación JSON/Markdown de 9 trabajos en GitHub Actions.

## Interpretación y siguiente paso

Si cap4 coincide con cap3, la **quinta orden** o el cambio de estrategia tras esa orden merece la siguiente prueba con condiciones más controladas. Si cap4 coincide con cap5, la **cuarta orden** o sus efectos posteriores es la intervención crítica. Si es intermedio, se debe analizar el efecto específico de la orden y no extrapolar una cantidad universal.

**Importante:** estas opciones alteran voluntariamente la duración de un único turno dentro del simulador experimental. No son propuestas para imponer nuevas reglas. El balance real de TARVOKA debe compararse también con niebla, más mapas y estilos de IA antes de aceptar cualquier cambio.

**Solo pruebas, workflow y documentación agregados**; sin modificar IA de producción, reglas de apertura, ciudades, relés, recursos, APK o `main`. PR DRAFT apilado sobre #605, sin fusión automática.
