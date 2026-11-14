# TARVOKA — Fase 11: geología procedimental y laderas más orgánicas

El objetivo de esta entrega es mejorar el **renderizado real de Godot 4.3**: roca, sombreado de laderas, acumulación de piedras y transición forestal. No cambia el movimiento, defensa, altura táctica, posición de unidades ni reglas de niebla.

## Geología en la vista 3D

- Nuevo `scripts/ui/TerrainRockMaterials.gd`: coloreado determinista basado en coordenadas mundiales `Vector3(x,y,z)` con bandas de pizarra, vetas de granito, zonas erosionadas y fracturas muy delgadas. No utiliza texturas externas ni identificadores de facción.
- `Terrain3DMesh.gd`: cambia de picos radiales iguales a pliegues de ladera alargados mediante señales de relieve compartidas por las coordenadas globales. El multiplicador de deformación es cero en todo borde de una casilla, evitando grietas incluso si los perfiles de montaña adyacentes tienen distinta importancia. El tono gris y la poca nieve quedan ligados a la geología y al nivel de elevación visual.
- La superficie de terreno invoca `SurfaceTool.index()` **antes** de generar normales. Esto permite reutilizar vértices idénticos, suavizar las normales compartidas y reducir elementos repetidos en la GPU. Se conserva exactamente el número de triángulos, la ubicación del terreno y la función de selección de celdas; lo que cambia es el número de vértices **únicos**.
- Las transiciones 3D entre **bosque, pradera y roca** calculan una mezcla de color a ambos lados de un borde común. En el borde el factor es exactamente 50:50 y se calcula con la misma posición global: no se aprecia un bloque cuadrado de color tan brusco. Las carreteras y el agua conservan su material distintivo. No se consulta un bioma vecino detrás de niebla.
- `tests/test_native_terrain3d.gd` verifica número de índices, reducción de vértices, normales válidas, paleta determinista, mallas con niebla, continuidad E/O y N/S y mapas 10×8, 24×18 y 40×30.
- La automatización `native-terrain3d-preview.yml` reexporta el visor y la misma batalla 3D/2.5D cuando se cambia la geología.

## Roca y bosque en la vista 2.5D

- `LandscapeDetailPainter.gd` dibuja pequeñas líneas de estratos minerales y reflejos en las facetas de la montaña, además de pedreras delante de las laderas. No cambia elevaciones ni colisiones.
- `LandscapeRegions.gd` añade piedras de tamaños/asimetrías diferentes al pie del macizo y sotobosque más irregular dentro del rombo. La sombra forestal llega a la conexión con un vecino **solo** cuando el terreno correspondiente era visible.
- Sigue disponible el renderizador isométrico habitual y el 3D experimental como modo voluntario.

## Validación necesaria antes de fusionar

1. Compilación Android y pruebas completas de Godot en verde para el commit más reciente.
2. PNG de detalle completo y medio en laboratorio 3D (sin instalar APK), comparación con el anterior en la misma escena.
3. Verificar sombreado suave sin caras invertidas, grietas en costuras ni manchas en niebla, y color coincidente en ambos lados de las transiciones pradera/bosque.

4. Revisar FPS y consumo de memoria en un teléfono real; el número de índices no es por sí solo una medición de FPS.
5. Comparar con las referencias de *Operación Río Azul*. No confundir esta actualización procedural con un acabado comercial final.

**Riesgos:** el relieve sigue formado por una malla de alturas y la vegetación 3D por árboles low-poly. Persisten los trabajos de material de agua, iluminación, puentes y modelos definitivos de las unidades. No fusionar la PR #183 mientras tenga conflictos de rama o pruebas pendientes.
