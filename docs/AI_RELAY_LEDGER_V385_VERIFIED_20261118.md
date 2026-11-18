# TARVOKA v3.8.5 — RESULTADOS VERIFICADOS (18 noviembre 2026)

**CI oficial de la rama experimental:** [Run 44356303353](https://github.com/edwinrodri12/Tarvoka/actions/runs/44356303353). **9/9 trabajos exitosos** (ocho grupos Godot 4.3 + agregador Python estricto). [PR draft #592](https://github.com/edwinrodri12/Tarvoka/pull/592), NO fusionado.

## Alcance preciso

- **16 partidas originales** de IA vs IA, 40×30, cuatro plantillas de terreno (semillas 630–633), niebla activada o no, dos órdenes de iniciativa. **16 reflejos adicionales** para comparar cada acción y estado, no para inflar muestras.
- Se analizaron **146 rondas completas** de los originales; en cada ronda el puntaje de la primera mitad fue cero y los puntos añadidos en la liquidación coincidieron exactamente con la propiedad de relés al final de la respuesta.
- **Todas las 16 partidas tuvieron ganador natural**; 2 ganadas por quien comenzó, 14 por quien respondió. Todos los 16 reflejos tuvieron el mismo resultado correspondiente a su simetría: **cero divergencias**.
- **24 eventos de captura de relés en el primer medio turno de ronda** frente a **36 eventos en el segundo**. Son eventos, no nodos distintos ni puntos: el mismo relé puede cambiar de propiedad más de una vez.
- **16 arrebatos directos** de relés al rival ocurrieron en la mitad de respuesta. **32 rondas** incluyeron una o más capturas del segundo jugador antes del depósito.

## Desglose por niebla

| Condición | Partidas originales | Victorias primero | Victorias segundo | Capturas del primero | Capturas del segundo | Arrebatos por segundo | Rondas completadas |
|---|---:|---:|---:|---:|---:|---:|---:|
| Sin niebla | 8 | 2 | 6 | 16 | 22 | 10 | 70 |
| Con niebla | 8 | 0 | 8 | 8 | 14 | 6 | 76 |
| **Total** | **16** | **2** | **14** | **24** | **36** | **16** | **146** |

## Desglose por plantilla

| Terreno | Semilla | Gana primero | Gana segundo | Capturas primero | Capturas segundo | Arrebatos |
|---|---:|---:|---:|---:|---:|---:|
| Campo abierto (plantilla 0) | 632 | 2 | 2 | 10 | 8 | 6 |
| Bosques (plantilla 1) | 633 | 0 | 4 | 4 | 12 | 4 |
| Puentes (plantilla 2) | 630 | 0 | 4 | 4 | 10 | 2 |
| Costa (plantilla 3) | 631 | 0 | 4 | 6 | 6 | 4 |

**Conclusión delimitada:** con la apertura actual (iniciador limitado a tres órdenes, respondedor libre), el segundo jugador disfruta en estos mapas de oportunidades efectivas de capturar/arrebatar relés justo antes de la liquidación. El registro demuestra capturas reales y retención, pero **NO prueba que sean la única causa de la distribución de victorias**. En la costa, por ejemplo, ambos bandos ejecutaron seis capturas por posición de turno en las cuatro partidas, pero ganó el segundo en las cuatro: la suma simple de capturas no basta para explicar el resultado. Influyen qué relés, cuándo y cuántas rondas se conservan.

**Contraste con v3.8.4:** [Run 44354412561](https://github.com/edwinrodri12/Tarvoka/actions/runs/44354412561) ya demostró en 32 instantáneas con propiedad fija que el depósito contable no da puntos extra por iniciativa. La v3.8.5 añade acciones y capturas reales y confirma que la liquidación sigue siendo contablemente correcta.

## Limitaciones, seguridad y próxima prioridad

1. Sólo cuatro plantillas y un nivel/estilo de IA. Los dos órdenes de inicio sobre el mismo mapa forman pares correlacionados, por lo que no conviene inferir una probabilidad general de victoria.
2. No se ha cambiado la regla de puntuación, el movimiento, las órdenes de apertura, los ingresos iniciales, el combate, la IA de producción ni la APK.
3. **PR #589 v3.8.3 todavía tiene dos pruebas costeras fallidas** al forzar un primer turno de tres órdenes para el respondedor. No interpretar sus resultados parciales como un contrafactual completo; las nuevas divergencias aparecen en la semilla 631 sin niebla (fase 13, fotograma 174, movimiento N8) y con niebla (fase 27, fotograma 383, movimiento N22), seguidas por timeout. El siguiente trabajo técnico debe aislar las rutas/desempates de esas dos unidades para completar ese experimento antes de evaluar cambios de balance.
4. Una alternativa futura es ampliar las semillas y las políticas de IA, y medir el tiempo de posesión de cada nodo antes de considerar un ajuste de reglas. **No autorizar dinero gratis al segundo, bonos de turno ni nuevas reglas sin pruebas suficientes**.

Los detalles completos por ronda se guardaron en el artefacto de CI **ai-v385-relay-ledger** como `reports/ai_v385_relay_round_ledger.json` y resumen `.md`, con retención de 30 días. Este documento conserva los hallazgos principales en el repositorio.

**Estado:** investigación verificada y documentada; PR draft #592 abierto, sin merge; `main` y APK sin cambios.
