# TARVOKA — G13 V9: auditoría visual real en Godot 4.3

## Evidencia de ejecución
- Workflow: [TARVOKA G13 V9 final 3D art audit, ejecución 43948490005](https://github.com/edwinrodri12/Tarvoka/actions/runs/43948490005)
- Commit validado: `74100d38734bdea77341a7508db7772922371a8f`.
- Resultado: **SUCCESS**. Importación, nueve pruebas especializadas y captura en Godot 4.3 completas.
- Artefacto verificable en GitHub Actions: `g13-v9-art-audit-18-actual-godot-frames`, ID `14265897113`.
- Total: **18 PNG**, no imágenes generadas por IA: 8 vistas isométricas de facción, 7 ángulos del vehículo, 2 modos de disparo y 1 detalle de rueda.

## Hallazgos observados en las imágenes
1. Las ocho paletas muestran franjas de identificación distintas, coherentes entre detalle de Android y calidad de estudio; se corrigió la diferencia de tonalidad entre los niveles de detalle.
2. Las cuatro ruedas aparecen circulares con bujes/rines cerrados y elementos de la banda de rodadura. En la vista inferior se identifican los dos ejes y sus soportes.
3. Las armas se elevan para atacar objetivos aéreos y permanecen cerca de horizontal para objetivos terrestres; en las capturas hay destellos visibles, no solamente cambios de texto.
4. La geometría todavía muestra un aspecto de **prototipo 3D angular**: glacis, cabina, paneles laterales y torreta necesitan una pasada de silueta y transiciones más orgánicas para el acabado comercial.
5. Las capturas, por sí solas, no garantizan ausencia de todos los solapamientos en animación continua, ni rendimiento real en teléfono Android.

## Decisión de producción
- **QA automatizada V9: APROBADA.**
- **Geometría visual V9: inspeccionada.**
- **Aprobación artística definitiva: PENDIENTE.** No confundir éxito de CI con validación de acabado comercial.
- **Publicación/visor compartido:** se valida de forma independiente en su propio workflow; no darlo por publicado sin verificar una ejecución exitosa.
- **Jugabilidad y balance:** sin cambios. El G13 conserva ataques terrestres y aéreos como animaciones artísticas, no ataques de combate registrados.

## Próxima prioridad artística
Refinar la silueta de cabina y torreta, especialmente la superficie frontal, costados y transiciones entre polígonos, manteniendo libres las ruedas y sus pasos. Repetir capturas de los mismos ángulos después del cambio y cotejar con V9, preservando LOD8 y las ocho paletas.
