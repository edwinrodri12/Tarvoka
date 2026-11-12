# TARVOKA — Hoja de ruta de diseño y desarrollo
**Fecha:** 2026-11-10 · **Referencia obligatoria:** [GAME_DESIGN.md](GAME_DESIGN.md).
Las prioridades no son promesas de fecha ni de versión. El objetivo es evolucionar el prototipo Android sin sacrificar estabilidad ni originalidad.

## Estado de partida confirmado
- **Core en main:** tablero 10×8, movimiento básico, combate, turnos, IA determinista básica, victoria lógica, guardado local y Android debug export.
- **Validación de campo (reporte del usuario):** selección/movimiento, botones de terminar turno/guardar/cargar operables y ejecución/restitución de turno de la IA en Android.
- **No verificado aún en dispositivo:** pantalla final de victoria/derrota, retorno tras cierre y carga persistente, rendimiento/consumo, orientación, niebla y funcionalidades futuras.
- El proyecto sigue siendo **prototipo**, no build listo para tienda.

## Orden de implementación: un hito validado antes del siguiente

### P0 — Estabilidad e interacción inmediata (MVP táctico)
**No agregar nuevas facciones ni economía en esta fase.**
| ID | Entrega | Dependencias | Criterio de terminado |
|---|---|---|---|
| P0-01 | Smoke test Android de partida completa | APK actual | Usuario juega hasta victoria/derrota, con estado final visible; pruebas CI + real |
| P0-02 | Persistencia y autoguardado recuperable | Guardado existente | Cerrar/reabrir app no pierde turno; versiones inválidas fallan sin corrupción |
| P0-03 | Movimientos legales resaltados | Reglas de terreno | Todos los destinos mostrados son legales y ninguno legal queda oculto |
| P0-04 | Alcance, daño estimado y riesgo | Motor de combate | Preview coincide con motor; no revela información inaccesible |
| P0-05 | Panel de información y estado | Unidad/terreno | Vida, acciones y terrenos legibles en móvil; sin datos obsoletos |
| P0-06 | Cancelación y confirmación de acciones | Input táctil | No hay doble ejecución ni acciones irrevocables por un toque accidental |
| P0-07 | Resumen/velocidad de turno IA | IA existente | Ciclo completo no bloquea UI; rápido o detallado a elección |
| P0-08 | Validación de tamaño, orientación y accesibilidad básica | HUD móvil | Controles utilizables en diferentes resoluciones, símbolos+colores |
| P0-09 | Firma debug persistente y actualizaciones seguras | CI Android | Nueva APK se instala encima de la anterior sin borrar partidas, vía secretos |
| P0-10 | Guardas de rendimiento offline | Core/IA | Sin peticiones de red obligatorias; tiempos y memoria medidos en gama media |

**Gate P0:** escenario de victoria completo en Android, acciones reversibles según especificación, UI comprensible y pruebas de regresión verdes.

### P1 — Inteligencia táctica y justicia competitiva
| ID | Entrega | Criterio de terminado |
|---|---|---|
| P1-01 | IA por objetivos y amenazas | Protege base, intenta captura rentable, ataca objetivos y evita sacrificio inútil |
| P1-02 | Niebla compartida y memoria de avistamientos | IA no usa enemigos ocultos; visión y búsqueda legal demostrables |
| P1-03 | Dificultades por razonamiento, no trucos | Se documentan heurísticas; sin buffs opacos ni vision total |
| P1-04 | Terrenos útiles y equilibrio de movilidad | La ruta óptima, posiciones y riesgos cambian de forma predecible |
| P1-05 | Diseño de unidades y contramedidas | Matriz coste-rol-counter y ninguna unidad domina todos los mapas |
| P1-06 | Balance del primer jugador | Simulaciones invertidas y objetivos equilibrados |
| P1-07 | Detección de estancamiento y objetivos de mapa | El frente puede progresar, sin caducidad artificial universal |
| P1-08 | Puntuación significativa | Valor de objetivos y recursos; resistir estrategias de explotación |

**Gate P1:** la IA juega estratégicamente con información legal; múltiples estrategias viables; análisis de balance reproducible.

### P2 — Identidad original, producción y contenido
| ID | Entrega | Criterio de terminado |
|---|---|---|
| P2-01 | Documento visual original y prototipo legible | Siluetas, facciones, HUD, terrenos y animaciones propios; móviles legibles |
| P2-02 | Escaramuza local guardable | Dos humanos pueden alternar turnos y reanudar sin fuga de niebla |
| P2-03 | Captura y control territorial [EXP] | Control altera decisiones sin bola de nieve inevitable |
| P2-04 | Suministros simplificados [EXP] | Aporta táctica sin micromanejo masivo |
| P2-05 | Unidades especializadas aéreas/navales [EXP] | Tienen roles demostrables y contramedidas, sin inflar inventario |
| P2-06 | Habilidades de comandantes [EXP] | Situacionales, justas y con contrarespuesta |
| P2-07 | Misiones de defensa, rescate, captura, escolta | 2+ soluciones en cada tipo; sorpresa y fracaso explicables |
| P2-08 | Campaña y progresión | Tutorial opcional, ruta alternativa, tono consistente, escenas saltables |
| P2-09 | Audio dinámico y opciones de accesibilidad | Variación sin fatiga, ajustes independientes |
| P2-10 | Sistema de desafío/escaramuza | No depende de completar una campaña lineal |

**Gate P2:** partida y campaña corta disfrutables, contenido original y regresión funcional de cada nuevo sistema; decidir mantener/quitar experimentos.

### P3 — Extensiones después de una experiencia offline madura
- Online por turnos asíncronos; invitaciones, notificaciones, guardado/reanudación, fallos de red seguros y protección de privacidad.
- Emparejamiento público, clasificación con temporadas equilibradas, normas de tiempo y abandono.
- Editor de mapas, biblioteca, compartición segura, validación de escenarios, repeticiones/análisis.
- Campaña ramificada y expansiones sustanciales; no microtransacciones pay-to-win.
- Revisión de marcas TARVOKA en USPTO/WIPO y asesoría de PI antes de publicidad/pagos/publicación.

## Registro de hipótesis (no tratarlas como funcionalidades cerradas)
| Hipótesis | Beneficio esperado | Riesgo | Prueba de decisión |
|---|---|---|---|
| Control de carreteras/sensores/depósitos | Nuevos objetivos tácticos | Demasiados subsistemas | A/B de partidas con/sin control |
| Suministro simplificado | Planificación y contrajuego | Micromanejo | Número de decisiones significativas vs acciones mecánicas |
| Deshacer seguro | Menos frustración | Explotación de niebla/RNG | Tests de información revelada y persistencia de semilla |
| IA por niveles | Accesibilidad y profundidad | Dificultad artificial | Misma información/recursos; mejor elección medible |
| Varias condiciones de victoria | Menos estancamientos | Condiciones confusas | Tasa de finalización y errores de comprensión |
| Multijugador asíncrono | Flexibilidad móvil | Coste de infraestructura/abusos | Prototipo local offline y evaluación legal/financiera |
| Habilidades originales de comandantes | Identidad y rejugabilidad | Combinaciones dominantes | Torneo de escenarios reproducibles |
| Campaña no lineal | Evitar bloqueos | Complejidad narrativa | Test de progresión y claridad |

## Regla para autorizar una nueva mecánica
1. Describir el problema de jugador que resuelve, no solo la funcionalidad.
2. Definir interacción mínima y **reglas puras** testeables en GDScript.
3. Escribir al menos un test de resultado esperado y un caso adversarial.
4. Probar con un escenario breve en Android antes de expandir mapas/assets.
5. Comparar complejidad y diversión contra el prototipo sin la mecánica.
6. Documentar mantener/reducir/descartar en DECISIONS.md; registrar benchmark de rendimiento y compatibilidad de guardado.
7. Modificar `main` solo por cambios revisables y con CI verde; evitar PR apilados.

## Matriz de prioridades ligada a riesgos
- **P0:** AW-04, AW-17, AW-18, AW-19, AW-22, AW-28.
- **P1:** AW-01, AW-02, AW-03, AW-06, AW-07, AW-08, AW-09, AW-10, AW-11, AW-12.
- **P2:** AW-05, AW-13, AW-14, AW-15, AW-16, AW-20, AW-21, AW-25, AW-26, AW-27, AW-30.
- **P3:** AW-23, AW-24, AW-29.
- El mapa completo de IDs y sus medidas está en GAME_DESIGN.md.

## Revisión periódica
Al completar cada hito: actualizar BACKLOG.md, PROJECT_STATUS.md, TESTS.md y DECISIONS.md. La automatización deberá priorizar P0 hasta pasar Gate P0 y no anunciar una funcionalidad como terminada sin evidencia.

## Checkpoint 2026-11-10 — P0/P1 incremental
PR #53–#59 han integrado las primeras mejoras de persecución táctica por terreno, priorización de objetivos letales, mapas originales comparables, caché de HUD, identificación de facciones por formas, estadísticas de resultados, guardado validado y modo simétrico. Todos pasaron CI Godot 4.3 y exportación Android; los ensayos reales de la nueva versión siguen pendientes. En 12 partidas de IA contra IA la configuración asimétrica de entrenamiento produjo 6–0 para azul, mientras que la simétrica produjo 3–3. **No marcar P0 como cerrado** hasta probar en dispositivo guardado/cierre/reapertura, escenario/modo confirmado, interacción táctil, resultado visual y rendimiento; no marcar P1 completo porque aún faltan IA por objetivos de misión, visibilidad/fog justa y balance estadístico amplio. Mantener entregas APK agrupadas y sin costes externos.

## P1 nuevo checkpoint — 2026-11-10
Motor optativo de niebla/visión, exploradores y IA de conocimiento restringido **implementados y fusionados en cinco PR #61–#65**, con CI Godot y Android aprobadas. Separamos información por facción, recordamos celdas visitadas, impedimos ataques no visibles y filtramos posiciones enemigas y topología desconocida para la IA. Doce partidas automáticas fog terminaron sin estancamientos; fog Simétrico 3–3 y Entrenamiento 5–1 en muestra muy pequeña. **Puerta todavía abierta:** falta verificación en Android físico, claridad visual de fog, guardar/reanudar real, oclusión avanzada del terreno, economía y objetivos/captura, IA defensiva. Modo clásico original y guardados v1 antiguos permanecen compatibles; no se entregaron APK individuales. Seguir con cambios pequeños y tests adversariales; no confundir CI headless con QA humano.

2026-11-10 P1 después de niebla básica: #66 incorpora oclusión por montañas mediante rayos Bresenham simétricos y #67 garantiza que terreno nunca descubierto está cubierto opacamente. Pruebas Godot y APK CI pasaron sin entrega al usuario. Quedan visibilidad de diagonales/corner cases, bosque/estructuras, historia de contactos enemigos, control estratégico de objetivos, escenarios humanos y QA físico de UI/performance. Gate P0/P1 todavía no cerrado.

2026-11-10 — Hitos P1 adicionales integrados #68–#71: la visión diagonal de montañas es simétrica, el mapa guarda incertidumbre sobre último avistamiento enemigo, la IA investiga esa pista sin omnisciencia y evita retiros interminables mediante apoyo aliado. Fallo de retirada ilimitada detectado por 12-battle CI y corregido antes de merge. **Nuevo foco**: definir objetivos/captura/control y defensas que aporten decisiones originales, manteniendo pruebas de reglas independientes y aceptabilidad en Android antes de ampliar variedad de facciones. APK agrupadas: no enviar artefacto por cada PR; actualizar NEXT_RELEASE y ejecutar QA real cuando se prepare.

2026-11-10 — Experimento de objetivos territoriales de bajo micromanejo implementado (#72–#76), sin desplazar el modo de eliminación clásico. Relés capturables al finalizar turno, señal por control, segunda victoria, estado v1 opcional, interfaz, IA legal y 24 simulaciones. Resultados 15 por señal y 9 eliminación en auto-juego. **Próxima evaluación**: partidas reales en Android (individual y varios tamaños), revisión de persistencia al reiniciar, distribución de victorias por primer turno, jugabilidad de relés cuando no hay unidades de guarnición y estrategia defensiva/contrajuego. Decidir mantener, reducir o descartar el sistema después del gate físico y pruebas humanas; no convertir un éxito de CI en aprobación del diseño final.

## Hito económico P1-ECO (2026-11-11)
Implementación parcial de sistema de economía y producción (#103–#108) posterior a primeros cinco roles. Mecánica optativa jugable en CI: capturar ciudades y talleres, recaudar al comenzar turno propio y usar créditos para producir Guardias, Rastreadores, Baluartes, Rompedores o Lanzadores, con IA enemiga limitada por las mismas reglas y niebla. **Estado: implementado en código y validado por CI; no aprobado aún por QA física ni equilibrio.**
**Gate antes de ampliar:** usuario deberá probar la mecánica en APK agrupada Android con guardado/reapertura; ampliar pruebas de ventaja de iniciativa (6/6 ganador primer jugador en economía) y pertinencia de cada precio/ingreso. Sólo después explorar especialización de fábricas, más tipos de propiedad, tutorial contextual de captura/compras y economía en misiones de campaña. No copiar la estructura completa de otro juego ni introducir cobros por recursos.
