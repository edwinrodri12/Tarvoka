# TARVOKA — v0.6: selección de rutas seguras antes de conquistar

**15 noviembre 2026 · Investigación experimental PR #394 · No integrado al juego oficial**

## Decisión que se está poniendo a prueba

La IA básica avanza a una ciudad o instalación sin analizar si el soldado sobrevivirá al mantener la posición durante al menos dos turnos propios. Las versiones de apoyo y defensa anteriores corrigieron órdenes específicas, pero en partidas prolongadas no disminuyeron interrupciones ni muertes.

La nueva variante **CaptureRouteAIV04.gd** conserva las decisiones de BasicAI y del experimento defensivo v0.5 salvo en un supuesto concreto: una orden de movimiento hacia un objetivo de conquista que expone al soldado a un riesgo de muerte identificable en el campo que su bando puede observar.

## Lógica implementada

- Solo examina órdenes legales de movimiento con intención de capturar ciudad o instalación; no reescribe disparos, suministros, reclutamiento o la economía.
- Busca al capturador entre unidades conocidas de su propio bando, sin usar enemigos ocultos. Los sitios por conquistar se consideran únicamente si ya están explorados, y el coste de ruta procede del terreno visible o explorado por esa facción.
- Estima daños directos de enemigos observados usando el mismo cálculo público que el combate, sin leer munición exacta del rival. Comprueba daño inmediato letal, riesgo aproximado de dos impactos entre turnos propios y proximidad de varios enemigos a una infantería con pocos HP.
- Si el destino propuesto es riesgoso, compara los destinos legales que el soldado puede alcanzar **en su fase actual**. Prefiere otro que siga reduciendo el coste hacia su objetivo y que tenga menos amenaza observada.
- La alternativa se confirma mediante Session.move del motor real. No se usa un teletransporte ni se inventa un movimiento a distancia.
- Si el destino exacto de captura recibiría un ataque actualmente letal y no existe ningún avance observable más seguro, suspende esa **orden experimental** en lugar de iniciar una ocupación suicida. El motor principal de Android no tiene aún esta política. Este bloqueo puede reducir capturas o incluso provocar estancamiento; se mide expresamente.
- La distancia para una amenaza que requiera desplazamiento enemigo es solo **heurística**, no prueba de que el rival vaya a disparar ni de que exista una ruta legal completa. El planificador no predice enemigos escondidos ni su futuro comportamiento.

## Regresiones controladas

El archivo tests/test_capture_route_v04.gd prepara 14 verificaciones para ambos bandos y la niebla:
- Reruta un Scout herido cuyo acceso directo a una ciudad dejaría al soldado al alcance letal de una Guardia visible.
- Conserva los movimientos no expuestos y las órdenes ajenas a capturas.
- Verifica que la acción final sea legal, compatible con el guardado v1 actual para el estado jugable y no altere el estado de entrada.
- Compara exactamente las decisiones cuando una unidad enemiga oculta cambia de posición fuera de la visión, impidiendo que el planificador la utilice como oráculo.

**Godot 4.3 QA:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43765968009

## Comparación de partidas con IA

**CI:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43765968182

Se comparan 16 parejas de escenarios, con/sin niebla y ambos bandos iniciales, con hasta 48 medias fases en cada partida. El mismo umbral de ciudad de 4 puntos, fábrica de 3 y retención de renta a partir de 2 se aplica a los dos brazos. El control es la IA conservadora v0.5; la única diferencia es la nueva política de ruta segura.

Las métricas incluyen: desvíos seguros, órdenes de captura pospuestas, cambios de propiedad, capturas completadas, avances interrumpidos, muertes/abandonos de capturadores, compras, economía, partidas decididas y victorias del bando inicial.

**No se declara esta variante equilibrada solo por aprobar QA.** Necesitamos que reduzca las pérdidas de progreso y no paralice la economía ni la lucha por las ciudades. El éxito de estas pruebas no sustituye la futura evaluación de diversión humana, balance entre ocho facciones, mapas grandes o guardado de progreso de captura.

## Integración

Se han añadido archivos únicamente en scripts/experiments, tests, .github/workflows y docs. No se modifica la IA oficial, las reglas de captura vigentes, el sistema de guardados ni la interfaz Android. El PR debe permanecer como borrador mientras la propuesta tenga evidencia insuficiente o desfavorable.


## Resultados A/B realmente observados — 15 noviembre 2026

**SUCCESS, Godot 4.3:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43765968182

Se completaron **16 escenarios espejo por variante**, 32 sesiones totales, máximo 48 medias fases. Las dos versiones usan los mismos mapas, ambos iniciadores, niebla sí/no, economía, clima, composición de unidades y captura progresiva (4 puntos ciudad, 3 fábrica, renta retenida desde 2). Solo cambia la decisión experimental de desvío/espera por riesgo.

| Métrica acumulada en 16 partidas por variante | IA conservadora v0.5 | IA con rutas seguras v0.6 |
|---|---:|---:|
| Conquistas completadas | 67 | 64 |
| Capturas interrumpidas | 100 | 80 |
| Pérdida de contador por capturador muerto, según evento detectado | 70 | 48 |
| Contadores perdidos con capturador aún vivo | 23 | 24 |
| Avances parciales registrados | 197 | 185 |
| Compras | 1.031 | 910 |
| Créditos retenidos en asedios | 15.250 | 13.250 |
| Dinero total al cierre (suma 16 partidas) | 73.314 | 76.560 |
| Desvíos específicos | 0 | 180 |
| Órdenes aplazadas por entrada letal | 0 | 4 |
| Partidas con ganador | 4 | 8 |
| Victorias de quien comenzó | 0 | 4 |

Cambio relativo: **−20 % interrupciones**, **−31,4 % muertes registradas de ocupantes** y **−4,5 % capturas completadas**; **−11,7 % compras**. No se detectaron fallos en los tests, pero estos números **no garantizan diversión ni equilibrio universal**.

### Lectura crítica y decisión

La hipótesis de evitar riesgos antes de entrar a una ciudad resulta más prometedora que los experimentos anteriores de apoyar/proteger al ocupante después de iniciar el asedio. La IA de rutas reduce notablemente pérdidas de soldados y progreso con solo cuatro órdenes rechazadas, a costa de perder tres conquistas netas y reducir las compras. Las ocho partidas con vencedor están repartidas 4/4 entre quien comenzó y quien respondió, frente a 0/4 en la base, **pero la muestra es demasiado pequeña para inferir ventaja estable de iniciativa**.

**Estado: candidata para más pruebas, NO lista para fusionar al juego.** Dos riesgos requieren revisión adicional: el descenso de producción (¿se lucha menos o se está frenando la economía?) y la variación entre mapas, incluidos casos costeros con capturas e interrupciones peores. Además, el clasificador de muertes/abandonos solo observa cuándo desaparece un contador entre fases y no sustituye un registro exhaustivo de muertes de todos los soldados.

### Próximas pruebas exigidas

1. Repetir con semillas aleatorias simétricas, tamaños de mapa 24x18 y 40x30, niebla y clima, y aumentar partidas terminadas antes de valorar equidad; el programa actual es **solo para dos facciones**, no simula ocho simultáneas.
2. Medir mejor tiempo de ocupación, presión enemiga y compras por fase, así como la diferencia de créditos y supervivencia, sin confundir menor combate con mejor juego.
3. Crear más casos de IA bajo emboscada con contactos no visibles y entornos de bosque/montaña; no ofrecerle conocimiento del mapa oculto.
4. Implementar guardado del contador y HUD de progreso por separado antes de cualquier integración en Android.

Estas métricas proceden de la ejecución vinculada arriba, no de cálculos hipotéticos.
