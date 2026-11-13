# TARVOKA — entorno 3D, detalle ecológico V3

## Objetivo
Añadir escala y variedad al mapa de exhibición sin introducir físicas, colisiones,
terreno táctico ficticio ni cambios en los modelos de tanque y Cuartel General.

## Implementación
- Nueva pasada **determinista** de vegetación baja para bosque/pradera, juncos
  situados exclusivamente en la ribera y grava de montaña/cañón.
- Tres lotes de render **MultiMeshInstance3D** para las instancias. Las geometrías
  pequeñas comparten malla/material dentro de cada lote y evitan cientos de nodos
  individuales adicionales. Se mantienen sombras/iluminación del estudio.
- Cada bioma tiene una paleta propia (verde bosque, tonos secos en cañón,
  vegetación costera en el delta). Distribución reproducible por escena y celda.
- Control **Vegetación y orillas detalladas V3** en Entorno y mapa 3D. Es
  independiente de cuadrícula, iluminación y modelos de referencia. Al apagar V3 se restaura la capa de hierba V2 para comparar; la vista de bloques V1 sigue siendo independiente.
- El contador muestra cuántas piezas visuales instanciadas existen y cuántos lotes
  se utilizan. V1, por definición, no usa esta pasada: la comparativa V1/V2
  permanece limpia.

## Revisión y límites
- `tests/test_terrain_studio_3d.gd` comprueba la carga en el visor GPU, repetibilidad,
  posiciones por tipo de terreno y la desactivación/restauración del detalle.
- Probar las tres escenas con cámara orbital a mediodía/nublado, y comparar
  con el interruptor apagado; inspeccionar en particular la frontera carretera/
  bosque, las riberas y el rendimiento en Android.
- La distribución utiliza el nivel del centro de cada celda como base provisional;
  la colocación exacta sobre pendientes y la continuidad fina del borde se
  abordarán con muestreo de altura por triángulo y/o máscaras de decoración.
- No hay LOD, oclusión, texturas de suelo de alta resolución ni comprobación de
  presupuesto real de GPU móvil en esta revisión.

**Esta fase mejora el estudio web. No implementa aún terreno 3D jugable en Android.**
No modifica ataques en altura, movilidad, puentes tácticos, niebla de guerra,
guardados, IA ni economía. La integración al motor de batalla se hará con
validaciones independientes después de aprobar el arte.
