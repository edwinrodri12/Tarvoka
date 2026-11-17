# TARVOKA — Contrato competitivo y prevención de ventajas dominantes (v2.4)

**17 de noviembre de 2026 | Propuesta de diseño + auditoría experimental | No introducir reglas nuevas sin pruebas.**

## Principio

La victoria debe depender de **decisiones estratégicas, lectura del mapa, adaptación y errores del adversario**, no de un *exploit* reproducible, un único comandante superior, una apertura imposible de contrarrestar o una facción que gane con una configuración fija.

**No es científicamente posible garantizar que nadie descubra una estrategia ganadora en todas las circunstancias** en un videojuego determinista con mapas finitos. La meta práctica es prevenir errores críticos y encontrar/apagar ventajas sistemáticas, dominancia sin contramedida y ventajas injustas de iniciativa. Una partida simétrica, repetible y jugada óptimamente puede seguir favorecer a un lado; hay que medirlo, no prometer perfección.

## Los ingresos del jugador que comienza segundo YA funcionan como se propuso

- Ambos bandos inician con **el mismo dinero inicial**: 2.500 créditos en el modo moderno actual.
- El jugador que actúa primero usa exclusivamente sus 2.500 antes de acabar el primer turno.
- Cuando comienza el **primer turno del segundo**, se le acreditan solo los recursos de **sus ciudades ya controladas**. No hay crédito anticipado por una ciudad neutral ni por una base productora.
- Al comenzar el **segundo turno del primero**, ese jugador también cobra sus ingresos ordinarios.
- Cada lado cobra **una vez por turno propio**, justo al iniciarlo. Nunca se paga al primer jugador al abrir la partida.
- **No añadir un segundo bono manual**: duplicaría los ingresos de quien juega segundo.
- La regla ya existe en `BattleSession.start/end_turn` y `UrbanEconomy.begin_turn`. La economía del mapa territorial `CapturableProductionV18.end_turn` también aplica el cobro al próximo jugador, reemplazando y no sumando el pequeño ingreso de compatibilidad.

### Ejemplos antes de comprar, conquistar o sufrir pérdidas

| Economía | Saldo inicial de ambos | Ingreso de ciudad(es) propias | Primer turno del primero | Primer turno del segundo | Segundo turno del primero |
|---|---:|---:|---:|---:|---:|
| Núcleo moderno (una ciudad inicial) | 2.500 | 250 | 2.500 | 2.750 | 2.750 |
| Laboratorio territorial 10×8 (una ciudad) | 2.500 | 250 | 2.500 | 2.750 | 2.750 |
| Laboratorio 24×18 (dos ciudades) | 2.500 | 166 | 2.500 | 2.666 | 2.666 |
| Laboratorio 40×30 (tres ciudades) | 2.500 | 186 | 2.500 | 2.686 | 2.686 |

Estos ejemplos no significan que el jugador que comienza segundo reciba más dinero total después de un ciclo completo; solo **lo recibe antes** que su rival como contrapeso de la iniciativa.

## Sistema de seguridad de balance propuesto

### A. Iniciativa y reflejos
- En una batería de pruebas, invertir quién juega primero, el color/lado y la orientación cuando el mapa sea simétrico.
- Verificar saldos, ingresos, capturas, órdenes, efectos de clima y poder sin duplicaciones.
- En igualdad de mapa, estrategia y recursos, discrepancias al reflejar el tablero pueden indicar tie-break asimétrico, posiciones o rutas no equivalentes; investigarlas antes de atribuirlas al azar.
- **No conceder más bonos al segundo jugador sin evidencia**. El núcleo también restringe al primero a **3 órdenes durante su primer turno** mediante `OpeningBalance` cuando se activa esa configuración; coexistencia de ambos handicaps debe medirse para no compensar en exceso.

### B. Estrategias, clases y edificios
- Para cada unidad, demostrar al menos una **contramedida accesible a tiempo y económicamente viable**, no solo en un duelo con dinero infinito. Ejemplo: tanque vs Rompedor, terreno y logística.
- Ningún tipo de unidad deberá ser superior simultáneamente en **precio, daño, alcance, movilidad, defensa y suministros**.
- Campamentos: **recon** da visión; **defense** solo protege al ocupante; **medical** solo sana al ocupante con coste; **supply** solo abastece al ocupante con coste. Nunca convertir radio automático y ocupación en beneficios acumulables.
- Fijar límites justificables por mapa a unidades de sabotaje, construcciones y efectos continuos, sin crear un límite arbitrario que convierta una facción en inútil.
- No permitir cadenas de reparación/curación en el mismo turno que multipliquen vida o ingresos; verificar que los costes se descuenten y se respete una unidad por casilla y acciones limitadas.
- Evaluar mejoras de edificios y tecnología por **coste total hasta obtener la habilidad**, no solo coste visible del botón (p. ej. antiblindaje +2 cuesta hoy 650+1050+450=2150 para investigarse en planta III experimental, y llega demasiado tarde en varias pruebas).

### C. Comandantes y 8 facciones
- Facciones y poderes aprobados como **conceptos** en v0.1; no atribuirles equilibrio real hasta que sean reglas activas y auditables en el motor.
- Detectar combinaciones abusivas de bono pasivo + activo, daño antes/después de redondeo, sinergias de nivel veterano, visión/clima, producción y capturas.
- El poder activo debe tener tiempo de recarga, duración y contrajuego claros. No deben acumularse accidentalmente duplicados del mismo efecto.
- Testear matriz de enfrentamientos **dirigidos** 8×8, sobre distintas topografías, presupuestos, orden de iniciativa y habilidades; cuantificar resultados sin llamar empate a una partida que agotó el límite.

### D. Política de métricas y alertas
- Todas las partidas usadas en medición deben etiquetarse **victoria real / derrota real / censurada** (si se acabó el tiempo/límite), nunca inventar un ganador.
- Alertas tempranas en lote pequeño (NO umbrales definitivos): estrategia con **≥75% victorias entre partidas decididas y al menos 6 decididas**; iniciativa ≥75% en al menos 6 partidas; discrepancias en reflejo; >50% censuradas.
- Para recomendar lanzamiento competitivo, definir muestras mucho mayores con mapas, semillas y perfiles de IA/humanos diversos. Objetivo orientativo **45–55% de victorias por iniciativa** cuando el tamaño muestral lo respalde, y tasas equilibradas entre facciones considerando emparejamientos, habilidades y mapas. No confundir desviación estadística con exploit demostrado.
- Mantener **registro de escenarios que rompen equilibrio** (mapa/semilla, facción, orden, acciones exactas, saldo, compra, poder, terreno, resultado) para repetir antes y después de cada arreglo.
- Es obligatorio que **un CI en verde signifique que las verificaciones funcionaron, NO que la estrategia sea justa**: las alertas de dominancia se reportan por separado; si una ventaja se confirma en una batería amplia, se convierte en prueba bloqueante antes de publicar.

## Hallazgos preexistentes que motivan el enfoque

- En un ensayo anterior 10×8, estrategia blindada ganó **7/8** con acceso inmediato y **7/8** aun pagando nivel II. Esto **dispara una alerta**, no prueba que cualquier jugador humano vaya a ganar siempre.
- En un ensayo posterior con antiblindaje +2, cuatro Rompedores **sí destruyeron** un tanque por coordinación/fuego concentrado en pradera y bosque, pero la tecnología requería **2.150 créditos** y tres oportunidades de producción antes de reclutar tropas suficientes. Hay contramedida táctica, pero no está disponible de manera económicamente viable al inicio.
- Muchas partidas 24×18 son censuradas en el límite de 52 medias fases; esto oculta conclusiones de victorias y señala la importancia de evaluar objetivos/HQ y tiempos de enfrentamiento.
- La regla de ingreso del segundo jugador ya existe. No hay evidencia suficiente de que una compensación adicional fuera necesaria.

## Instrumentos actuales

- `tests/test_opening_income_fairness_v24.gd`: tres tamaños, ambos jugadores como iniciadores, núcleo actual y mapa territorial, cobro exacto una vez por turno.
- `tests/test_dominant_strategy_watch_v24.gd`: 12 enfrentamientos por mapa con políticas expansión/presión/blindaje, colores e iniciativa espejados. Emite banderas sin llamar «equilibrado» al CI PASS.
- `.github/workflows/fairness-opening-v24.yml`: 4 jobs en Godot 4.3; ver resultados de Actions antes de hacer afirmaciones de ejecución.
- Rama/PR experimental: no altera `BattleSession`, `UrbanEconomy`, `OpeningBalance`, `SaveCodec`, APK ni reglas de campamentos.

## Hallazgos ejecutados y auditables (Godot 4.3)

- [CI inicial — 4/4 jobs PASS](https://github.com/edwinrodri12/Tarvoka/actions/runs/44102989641): validaciones de ingresos exactos y simulaciones anti-meta por tres mapas, sin cambios al núcleo.
- [CI con validación de espejos iniciales](https://github.com/edwinrodri12/Tarvoka/actions/runs/44103349841): test `opening_income` completado con éxito. **Seis de seis comprobaciones de mapa** (10×8, 24×18, 40×30 por dos terrenos) comprobaron espejo horizontal exacto de terreno, ciudades y fábricas, propietarios y escuadras iniciales. La regla de cobro por jugador también pasó para ambos colores y tres tamaños.

| Mapa | Inicio primero ganó entre decididas | Decididas / censuradas | Blindados V/D/C | Discrepancias al invertir lado + iniciativa |
|---|---:|---:|---:|---:|
| 10×8 abierto | 6/12 | 12 / 0 | 7/1/0 | 2 de 6 |
| 24×18 abierto | 1/3 | 3 / 9 | 1/1/6 | 3 de 6 |
| 24×18 bosque | 1/3 | 3 / 9 | 1/0/7 | 3 de 6 |

**Interpretación:**
- La compensación de ingresos ya es correcta: ningún jugador recibe antes de su primera fase, el segundo cobra al entrar y el primero en su segunda fase.
- La alerta de dominancia 10×8 **sí persiste**: doctrina blindada 7/8, presión 1/8 y expansión 4/8 participaciones. No es demostración de victoria segura para humanos.
- El **mapa inicial es geométricamente simétrico**, así que las diferencias en partidas reflejadas no se explican por un error grueso de terreno/ciudades/despliegue inicial. Revisar desempates/orden de iteración de IA, orden de objetivos, captura, compras y evolución de estado de cada partido antes de acusar a una facción. La simulación usa dos ejércitos experimentales, no los ocho poderes reales.
- Los porcentajes de victoria de mapas 24×18 son **inconclusos**: 75% partidas censuradas. Necesario estudiar condiciones de victoria por HQ/territorio o más turnos; no forzar empate ni designar ganador artificial.
- **NO añadir otro bono al segundo jugador** por ahora; primero replicar con IA imparcial y una muestra mayor.

## Prioridad siguiente

1. Confirmar que las pruebas v2.4 de primeros ingresos y ausencia de pagos duplicados pasan en CI.
2. Revisar la señal de dominancia 10×8; explorar **investigación antiblindaje desde nivel II** y compras escalonadas de Rompedores (nunca regalando tecnología).
3. Evaluar si el límite del primer turno a tres órdenes combinado con ingreso más temprano del segundo corrige o sobrecompensa la iniciativa, comparando juego con/sin restricción mediante ensayos espejo.
4. Cuando el motor tenga las ocho facciones reales, automatizar matriz por comandantes y verificación de combos. Mantener partidas de prueba reproducibles en cada versión.
