# TARVOKA — entorno 3D, revisión artística V2

**Alcance:** prototipo visual en Godot 4.3 con render WebGL 2.0, separado del motor táctico Android. El visor comparte escena y controles con los modelos de unidades y el Cuartel General; ni la cuadrícula lógica, ni los costes, ni los guardados se alteran.

## Visor sin APK

En **TARVOKA Estudio 3D**, entra en **ENTORNO Y MAPA 3D**. Cambia entre **Valle boscoso**, **Cañón rocoso** y **Delta costero**, usa los botones de rotación y zoom, arrastra el visor o acerca con dos dedos. Los controles nuevos permiten:

- **Suelo continuo V2** (activado por defecto). Desactívalo para comparar el mosaico de bloques V1 con exactamente el mismo ángulo, zoom, facción y bioma.
- **Mostrar cuadrícula** para comprobar la legibilidad de cada casilla sin convertir las guías en colisiones.
- **Ver tanque y edificio** para poner la geometría en contexto (las escalas de diorama son provisionales).
- **Luz**: mediodía, atardecer o nublado.

## Qué cambió en V2

1. **Malla continua:** una superficie `SurfaceTool` para todas las casillas de tierra, con vértices compartidos por posición de esquina, colores de material interpolados entre biomas y acantilados en costa/bordes. La altura de cada esquina es determinista, de modo que dos casillas vecinas no se separan.
2. **Agua y litoral:** superficie continua por regiones de agua, lecho marino inferior, dos niveles de espuma natural y orillas que siguen la topología real de las celdas.
3. **Caminos:** tramos calculados según vecinos, con carriles, bordes y líneas discontinuas que desaparecen en cruces. V2 agrega un puente elevado **visual** con pilares y barandas en el cañón; no representa todavía una casilla puente navegable en combate.
4. **Vegetación:** árboles sobre relieve, arbustos secundarios de distribución reproducible, pequeñas rocas e irregularidades suaves del terreno.
5. **Cámara:** encuadre principal ampliado para que el tablero no quede diminuto en el lienzo.
6. **Comparación verificable:** las pruebas generan imágenes de los tres escenarios y una composición V1/V2 con cámara idéntica. El ZIP de la ejecución de GitHub Actions contiene las capturas nativas `tarvoka_terrain_scene_00.png`, `01.png`, `02.png` y `tarvoka_terrain_v1_v2_same_camera.png`.

## Archivos

| Archivo | Función |
|---|---|
| `scripts/ui/TerrainStudio3D.gd` | Generador V1/V2, superficie, biomas, carretera, costa, puente y referencias |
| `scripts/ui/CombinedArtStudioWeb.gd` | Visor de tres categorías, comparador V1/V2, iluminación, cámara |
| `tests/test_terrain_studio_3d.gd` | Prueba GPU del terreno, imágenes de biomas, comparación y cambio de categorías |
| `.github/workflows/web-art-studio.yml` | Exportación WebGL y publicación de PNG reproducibles |

## Limitaciones y siguientes prioridades

Es **una mejora real del entorno de previsualización**, todavía no un entorno comercial final ni un motor de terreno 3D listo para las batallas. El puente es arte visual, el agua carece de simulación física y el relieve 3D no define aún ataque desde altura ni accesibilidad por tipo de unidad. Los mapas 24×18 y 40×30 siguen usando el motor táctico establecido; no se han trasladado a 3D.

Pendiente: malla por chunks y niveles de detalle, mejores materiales PBR y texturas de terreno sin marcas repetitivas, variación geométrica de montañas, vegetación con instancing, coherencia volumétrica de edificios/unidades, prueba de rendimiento en dispositivos Android y adaptación al verdadero estado de cada mapa/casilla y niebla de guerra.

No cambiar estadísticas de carretera/montaña, navegación, turnos, IA o guardados a través de cambios de arte.
