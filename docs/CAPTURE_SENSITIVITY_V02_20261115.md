# TARVOKA — Captura progresiva v0.2: sensibilidad 3/4/5

**15 noviembre 2026 — Diagnóstico, no norma jugable.** Continúa la auditoría del PR #394 sin fusionar main, sin subir umbrales al juego real, sin modificar costos de unidades, habilidades, economía, SaveCodec v1 ni HUD.

## Hipótesis

El umbral de captura debe evitar que un Rastreador de 150 créditos, con movilidad 4, convierta instantáneamente una ciudad de 250 créditos por turno, pero tampoco debe volver interminables las capturas en mapas grandes.

Las alternativas son **3, 4 y 5 puntos de ciudad**. Instalaciones productoras continúan en **3 puntos** para aislar la variable. En todas se conservan **mínimo dos turnos propios**; Guardia y Asaltante suman +2, Rastreador/Ingeniero/Rompedor +1, ayudas adyacentes +1 hasta dos, y unidades dañadas por debajo del 50 % HP tienen aporte principal reducido a +1. Rompedor sigue siendo solo una hipótesis por PR #156.

### Ritmo teórico, si los soldados sobreviven y no se mueven

| Umbral urbano | Guardia sola (+2) | Rastreador solo (+1) | Rastreador con 1 apoyo (+2) | Guardia con 2 apoyos (+4) |
|---|---:|---:|---:|---:|
| 3 | 2 turnos | 3 turnos | 2 turnos | 2 turnos |
| 4 | 2 turnos | 4 turnos | 2 turnos | 2 turnos |
| 5 | 3 turnos | 5 turnos | 3 turnos | 2 turnos |

Estos son cálculos reglamentarios, no resultados observados. El valor 5 introduce un salto para Guardia y reduce el atractivo de un único apoyo al Rastreador.

## Políticas económicas bajo asedio

1. **after_two**: el propietario deja de cobrar los 250 créditos de la ciudad mientras otro bando la ocupa con progreso de 2 o más puntos. Una infiltración de 1 punto no bloquea. Productores quedan congelados administrativamente a partir del mismo umbral.
2. **complete_only**: el propietario sigue cobrando hasta que la conquista se completa; la mera ocupación física de una fábrica puede impedir crear una unidad en esa casilla, pero no es un bloqueo administrativo adicional.

En ambos escenarios, si el ocupante muere o abandona el sitio, se anula el avance. El propietario conserva el sitio hasta completarse y el atacante empieza a cobrar solo en un turno propio posterior.

## Protocolo reproducible

- Motor aislado: scripts/experiments/CaptureExperimentV01.gd, con parámetros opcionales y valores predeterminados retrocompatibles 4/3 y bloqueo desde 2.
- Batería: tests/test_capture_sensitivity_v02.gd.
- **36 casos controlados**: 3 umbrales × 2 políticas × 2 facciones × 3 composiciones (Guardia, Rastreador, Rastreador con un aliado), además de comprobaciones anti-sabotaje.
- **16 escenarios espejo**: 4 mapas × 2 bandos que empiezan × niebla activada/desactivada, con lluvia en puentes y nieve en bosque.
- **112 sesiones simuladas**: 16 con reglas oficiales, más 16 × 6 alternativas. Horizonte de **14 medias fases** por sesión, con hasta 16 acciones de BasicAI por fase y mismos ejércitos/mapas.
- Métricas: cambios efectivos de propiedad, avances parciales, capturas completadas, créditos retenidos, producción congelada, compras, dinero total, diferencia económica a favor del iniciador, ingresos finales y victorias.
- Los resultados son una sensibilidad acotada, no comparación de destreza humana ni garantía de equilibrio. IA actual aún no coordina apoyo, y el horizonte puede dejar cero ganadores.

## Decisión y verificación

No elegir el umbral por el número bruto de capturas. Buscar menor recaptura precipitada, tiempo razonable, ausencia de sabotaje barato, y equilibrio del iniciador; posteriormente evaluar IA consciente de progresos, mapas grandes, recuperación de guardados y niebla. Mantener PR #394 en borrador.

La fase v0.1 pasó Godot 4.3. **No considerar v0.2 aprobada hasta que su GitHub Actions arroje SUCCESS y el log contenga PASS capture phase02.** No adelantar cifras o conclusiones con pruebas pendientes.


## Mediciones v0.2 verificadas en Godot 4.3

**Workflow exitoso:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43754811996
**Registro archivado:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43754811996/artifacts/14177673713

El motor ejecutó **36 verificaciones mecánicas + 112 sesiones IA** (16 baseline nativas y 96 variantes), con todas las aserciones satisfechas. A diferencia del ensayo v0.1, aquí la ventana se acorta a 14 medias fases para medir sensibilidad cruzada; **no se deben comparar 70 cambios basales de este ensayo con los 94 de la ventana anterior de 20 medias fases**.

| Captura urbana | Política de asedio | Cambios efectivos | Compras IA | Avances parciales | Créditos retenidos | Fábricas congeladas |
|---|---|---:|---:|---:|---:|---:|
| Regla instantánea | No aplica | 70 | 343 | — | — | — |
| 3 puntos | Desde 2 puntos | 40 | 339 | 70 | 2.500 | 2 |
| 3 puntos | Solo al completar | 40 | 338 | 70 | 0 | 0 |
| 4 puntos | Desde 2 puntos | 38 | 339 | 76 | 2.500 | 2 |
| 4 puntos | Solo al completar | 38 | 338 | 76 | 0 | 0 |
| 5 puntos | Desde 2 puntos | 34 | 339 | 80 | 2.000 | 2 |
| 5 puntos | Solo al completar | 34 | 339 | 80 | 0 | 0 |

En la ventana v0.2, la reducción de cambios de propiedad respecto a regla oficial es: **3 puntos: 42,9 %; 4 puntos: 45,7 %; 5 puntos: 51,4 %**. Se incluyen tanto ciudades como instalaciones. Las compras permanecen cercanas (338–339 frente a 343), pero el ingreso retenido cambia y puede propagarse a otros movimientos y gastos. **No hubo victorias completas en ninguna de las 112 sesiones**; por ello es incorrecto deducir tasa de victorias, equidad del iniciador o diversión solo a partir de estos números.

El ensayo determinista también verificó que una Guardia ocupa en 2/2/3 turnos propios para umbrales 3/4/5, el Rastreador en 3/4/5, y que un Rastreador con un aliado adyacente consigue 2/2/3, incluyendo ambos bandos. Se verificó la protección del ingreso ante una infiltración inicial de 1 punto.

**Lectura provisional:** no hay evidencia para fijar ya el umbral urbano. El 4 sigue siendo un candidato intermedio plausible pero **no se recomienda integrarlo** antes de evaluar IA adaptada, choques defensivos y más rondas. El bloqueo de renta desde 2 puntos es una elección relevante para la economía, no una diferencia cosmética.

## Próximo experimento de IA (aislado)

Un nuevo planificador de apoyo se añadió a scripts/experiments/CaptureAwareAIV01.gd y se verificó con **16 órdenes controladas en Godot 4.3**, ambos bandos, con/sin niebla, umbrales 3/4 y ambas políticas. **Workflow exitoso:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43755102292

Solo utiliza progreso de capturas propias visibles y la visión autorizada; el movimiento legal se aplica con el motor de sesión real. Por ahora valida decisiones de apoyo, **no una mejora cuantificada de tasa de victoria**. No modifica scripts/core/BasicAI.gd ni se usa en la aplicación Android.

## CI general independiente del balance

Una ejecución de la batería general de Godot (https://github.com/edwinrodri12/Tarvoka/actions/runs/43754811848) se detuvo en importación de arte HQ V15, al faltar la superclase CombinedArtStudioWeb.gd requerida por BastionStudioAdapter.gd. El fallo ocurre en scripts/ui, fuera de esta propuesta de captura, y requiere corrección del frente visual o revisión del estado de ramas antes de aprobar el proyecto completo. No declarar aprobado todo el CI basándose únicamente en las pruebas experimentales.
