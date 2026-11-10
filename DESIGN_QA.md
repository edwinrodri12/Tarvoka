# TARVOKA — Matriz de QA de diseño
**Versión:** 1.0 (2026-11-10) · Referencias: [GAME_DESIGN.md](GAME_DESIGN.md) y [DESIGN_ROADMAP.md](DESIGN_ROADMAP.md).

## Cómo interpretar estados
- **PASÓ CI:** ejecutado automáticamente en Godot 4.3; no prueba experiencia física.
- **CONFIRMADO POR USUARIO:** resultado reportado por el usuario durante prueba en Android; registrar alcance exacto, no inferir aspectos no vistos.
- **FALLÓ:** reproducible con un caso de prueba e idealmente un video o log.
- **NO EJECUTADO:** requisito planeado todavía no probado.
- **N/A:** no implementado en la versión evaluada.

## Validación de campo existente (2026-11-10)
- **CONFIRMADO POR USUARIO:** APK del prototipo abre; tablero permite seleccionar y mover unidades.
- **CONFIRMADO POR USUARIO:** luego del hotfix PR #39, botones Terminar turno, Guardar partida, Cargar partida responden a pulsaciones.
- **CONFIRMADO POR USUARIO:** la IA actúa al terminar el turno y devuelve el control.
- **NO CONFIRMADO:** exactitud del contenido guardado tras reiniciar, combate completo hasta victoria/derrota, niebla, prestaciones del futuro diseño.
- **CI:** el trabajo de corrección de botones tuvo Godot y APK firmada exitosos según TESTS.md. El reporte humano no equivale a cobertura para toda la campaña.

## 10 pruebas maestras (no pasar a publicación sin criterios aplicables)
| ID | Pregunta | Estado hoy | Método de prueba |
|---|---|---|---|
| Q-01 | ¿La IA defiende una instalación amenazada en vez de distraerse? | N/A | Dos amenazas y un objetivo; confirmar que elige defensa plausible |
| Q-02 | ¿La IA respeta exactamente las reglas de niebla? | N/A | Ocultar/trasladar enemigo fuera de visión; no attack ni seguimiento omnisciente |
| Q-03 | ¿Cada misión admite al menos dos estrategias razonables? | N/A | Dos playtesters/resolutores con planes distintos |
| Q-04 | ¿Cada unidad tiene función viable y counters? | N/A | Simulaciones de coste/rol/counter en varios mapas |
| Q-05 | ¿Eventos, poderes y amenazas importantes son previsibles? | N/A | Revisión de avisos y oportunidades de respuesta |
| Q-06 | ¿Se guarda y reanuda sin perder progreso? | NO EJECUTADO en teléfono | Guardar, salir forzosamente, iniciar, cargar y comparar estado |
| Q-07 | ¿Movimiento, daño, alcance y estado son comprensibles? | PARCIAL | Juego en móvil: superposiciones/HUD y prueba de comprensión |
| Q-08 | ¿No hay estancamientos ni turnos sin decisiones? | N/A | Escenarios prolongados con control territorial |
| Q-09 | ¿Dificultad mayor significa mejores decisiones y no trampas? | N/A | Misma partida/estado/recursos con heurísticas distintas |
| Q-10 | ¿Funciona offline con buen rendimiento en gama media? | PARCIAL (offline sin rendimiento medido) | Modo avión, duración turnos, memoria/temperatura |

## Pruebas esenciales por flujo
### Android y entrada
- A-01: Tap unidad selecciona exactamente una vez.
- A-02: Tap fuera del tablero NO mueve ni selecciona.
- A-03: Deslizar o mantener presionado no dispara orden involuntaria; dedos secundarios no interfieren.
- A-04: Los tres botones de UI funcionan (reporte de campo CONFIRMADO).
- A-05: Terminar turno ejecuta IA y devuelve control (reporte de campo CONFIRMADO).
- A-06: Interfaz usable en pantallas de resolución diferente y con orientación decidida.
- A-07: Actualización de APK sin borrar guardados, usando certificado debug persistente y seguro (pendiente).

### Reglas y partida
- R-01: Destinos legales corresponden exactamente al motor de movimiento.
- R-02: Preview de daño corresponde al motor y no entrega información oculta.
- R-03: El acto de confirmar no permite órdenes duplicadas, ni ataques tras perder turno.
- R-04: Victoria y derrota terminan batalla con mensaje y bloqueo de acciones posteriores.
- R-05: Guardado versionado round-trip; corrupción/error manejado sin perder estado válido.
- R-06: Autoguardado se recupera tras cierre forzoso.
- R-07: Comprobar condiciones de victoria alternativas sin imposiciones erráticas.

### IA y justicia
- I-01: La IA no accede a enemigos legalmente ocultos.
- I-02: Prioriza defender/capturar ante objetivos razonables.
- I-03: IA regresa control en presupuesto fijo de acciones, sin congelar móvil.
- I-04: Dificultad altera capacidad de planificación, no visibilidad o recursos secretos.
- I-05: Cambiar de facción/lado de inicio no produce ventaja injustificada.

### Economía, contenido y UX
- E-01: Cada rol tiene al menos un escenario donde es óptimo o aporta valor.
- E-02: Producción no deriva en estancamiento ni en victoria irreversible prematura.
- E-03: Historia, mapa, unidades, arte y audio son originales.
- E-04: Campaña introducida progresivamente, admite rutas y opciones.
- E-05: Animaciones se pueden acelerar/saltar; accesibilidad y texto legible.
- E-06: Multijugador local guardable y, después, online asíncrono seguro.

## Contratos de pruebas automáticas propuestas
Cada funcionalidad nueva debe traer dos pruebas como mínimo:
- Una **positiva** con situación normal y resultado determinista.
- Una **negativa/adversarial**: acciones duplicadas, recurso insuficiente, fuera de mapa, visibilidad oculta, corrupción de guardado, ventaja de primer jugador, etc.

Ningún documento debe etiquetar estas pruebas como PASÓ hasta que exista ejecución reproducible (run + commit + resultado). QA visual o de dispositivo requiere reporte, captura o registro de interacción real. El código de CI y las APK son medios de verificación, no garantías de experiencia.

## Registro de decisiones de QA
- 2026-11-10: Entrevista/reporte de usuario confirmó botones y respuesta de IA en dispositivo; mantener separada la validación de guardar/cargar *operabilidad de botones* de *integridad del guardado*.
- 2026-11-10: Prioridad inmediata: Q-06, Q-07, A-01–A-07, R-04 antes de economía/campaña/multijugador.

## 2026-11-10 P0 QA update — development versus field validation
- P0-03 legal movement overlay and P0-04 deterministic adjacent damage preview: **PASÓ CI** Godot rules/preview tests and Android export PR #41, #43; **NO EJECUTADO EN TELÉFONO** visual legibility/interaction.
- P0-05 HUD for HP/attack/defense/movement: **PASÓ CI** source/scene compile; **NO EJECUTADO EN TELÉFONO** legibility under different screen sizes.
- P0-02 offline autosave/resume and New Game: **PASÓ CI** test_autosave_resume.gd and manual-save isolation; **NO EJECUTADO EN TELÉFONO** background/force-close reopening and update-in-place.
- P0-06 Cancel Selection, terminal End Turn disabled and New Game confirmation: **PASÓ CI** regression in test_main_buttons.gd; **NO EJECUTADO EN TELÉFONO** touch-dialog behavior.
- Final build verified in GitHub Actions 42873868205, artifact 13791325778. Future user feedback must be recorded separately. Remaining priority: complete-match victory/defeat QA, secure signing continuity, full attack-confirm/undo UX, performance and orientation.
