# TARVOKA — Base Naval V7: uniones reales de embarque, botadura y escaleras

## Objetivo de esta fase visual
Refinar los puntos en los que embarcaciones, rampas y estructuras se conectan físicamente a los muelles. La V7 prolonga el **modelo nativo Godot 4.3** existente V1–V6, sin generar imágenes conceptuales ni cambiar reglas del juego, navegación, captura, economía o costos.

## Piezas añadidas
- **Pasarela abatible V3:** zócalo de transición sobre el pavimento del muelle, dos bisagras con ejes/pasadores, placas de reparto de carga, conexiones hidráulicas y zapata protectora del extremo marítimo. El tablero y la estructura principal V3 siguen siendo los mismos; no se duplica ninguna rampa completa en vista cercana.
- **Botadura:** placas de apoyo para los dos rieles existentes, grapas metálicas y bandas protectoras conectadas a la rampa y al cabrestante reales; no aparecen sobre un muelle inexistente. Bajo daño crítico sobreviven exclusivamente fragmentos torcidos; en destrucción quedan escombros.
- **Escaleras de muro:** agarraderas de salida que conectan las escaleras V3 con la coronación y pequeñas placas de anclaje. Las escaleras ausentes por destrucción no se reconstruyen.
- **Lectura desde lejos:** un perfil simplificado de la pasarela/rampa sustituye microdetalles cuando el zoom cae por debajo del umbral de V6 (0.85). Materiales de contraste conservan facción y lectura isométrica, y se evitan piezas minúsculas que se vean como ruido.
- **Noche:** discretas señales reflectantes en escalas y embarque, vinculadas al modo nocturno **ya existente** de V6. No se añaden luces puntuales ni sombras adicionales.

## Integración en TARVOKA Estudio 3D
En Edificios 3D → Base Naval aparece un nuevo interruptor: **V7 · uniones, escaleras y rampa (comparar V6)**. Conserva zoom, giro, cámaras, noche, niveles, facciones y estados de daño. V7 depende de V1–V6; al apagarla reaparece la V6 sin modificaciones.

## QA verificable
- `scripts/ui/NavalBoardingDetailV7.gd` contiene la capa aditiva, con `apply()`, `set_detail()` y `set_night()`.
- `tests/test_naval_base_v7_gpu.gd` evalúa 8 facciones × 5 daños y 3 niveles, compara las capas y guarda ocho capturas reales de Godot.
- `.github/workflows/naval-base-v7-gpu.yml` importa el proyecto con Godot 4.3 y ejecuta aceptación nativa OpenGL antes de publicar pruebas. No afirmar que esté aprobado hasta terminar el workflow.

## Próximas etapas
Tras inspeccionar desde las cámaras general, marítima y cercana: corregir estética de amortiguadores de atraque y alineación final del hangar con el astillero. No se han medido FPS Android; la integración jugable se tratará por separado.
