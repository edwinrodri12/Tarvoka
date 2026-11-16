# TARVOKA — Base Naval V13 · auditoría visual de ocho cámaras y materiales

## Motivo de esta revisión
Al inspeccionar las ocho capturas auténticas de V12 observamos que las cámaras de cerca enseñaban demasiado hangar y cubierta en vez de centrarse en las defensas, sus eslabones y los soportes. La causa es una diferencia de sistemas de coordenadas: el modelo gira `_yaw=26°` en el Estudio, pero las cámaras 4–7 apuntaban a posiciones fijas no rotadas. Una revisión estética final necesita encuadres correctos antes de añadir adornos.

## Correcciones nativas Godot 4.3
- **Cámaras 4 a 7:** se calculan posiciones y centros en coordenadas locales del modelo, transformadas al mundo con el mismo yaw que su malla. Las cámaras de vista completa, mar, posterior y superior (0–3) conservan sus encuadres originales. La vista 5 busca la cara interior del espigón y el bolardo; la 6 ve la línea de contacto del muelle Este desde la dársena; la 7 inspecciona el espigón a baja altura desde el agua. La vista 4 conserva el punto de embarque, pero orienta la cámara al modelo rotado.
- **Cadenas:** el material metálico V11/V12 era muy reflectante en la iluminación del estudio, y su tubo de apenas 11 mm apenas se distinguía. V13 utiliza un acabado de acero cepillado de rugosidad 0.66 y metalicidad 0.53, con un espesor visual de +3.2 mm mediante una malla independiente. Mantiene intactos los puntos de origen y destino, las orientaciones y la trayectoria curva V12. En daño 2 la corrosión mantiene su material diferenciado.
- **Sin nuevas capas decorativas ni pérdida de V12:** el script `NavalInspectionV13.gd` cambia solo las mallas/materiales de cadenas V12 dentro de la nueva instancia Godot. Desactivar el interruptor V13 reconstruye la V12 original. Bolardos, argollas, geometría naval, estados de daño, reglas y colisiones no se modifican.

## Estudio 3D
En `Edificios 3D → Base Naval V13` se puede alternar `V13 · materiales y cadenas corregidos (comparar V12)`. Se conservan las ocho cámaras, noche, niveles 1–3, ocho facciones, cinco daños y zoom. Las cámaras enfocan las posiciones actuales, incluso al girar el edificio.

## Validación
`tests/test_naval_base_v13_gpu.gd` y `.github/workflows/naval-base-v13-gpu.yml` prueban los 40 modelos (ocho facciones, cinco daños), los tres niveles, contraste y grosor geométrico de cadenas, 8 cámaras con dos orientaciones de yaw, comparación V12, daño medio/destrucción y 11 capturas Godot/OpenGL auténticas.

**No afirmar que pasó o quedó publicada antes de comprobar el workflow.** No prueba FPS Android, movimiento de buques ni funcionalidad táctica. Si las nuevas imágenes revelan defectos reales, corregir la geometría antes de cerrar el arte del puerto.
