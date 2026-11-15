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
