# TARVOKA — pasada de modelado visual V4 (Estudio 3D web)

Esta rama añade una capa de dirección artística verificable sobre la escena V2+PBR existente. No es una afirmación de que los gráficos ya cumplan la calidad comercial final.

## Qué se ha modelado

- **Cordilleras:** mallas originales de erosión en cinco estratos, 13 segmentos por anillo, siluetas distintas por semilla, alabeos leves, aristas rocosas y nieve parcial solo en ciertos picos. Las crestas secundarias y rocas laterales también reciben geometría propia; sus identificadores y posiciones se conservan.
- **Árboles:** pinos de varias capas y copas irregulares sustituyen cilindros/conos perfectos en el visor. Los modelos 3D de unidades y cuartel no se alteran.
- **Agua:** se reemplazan visualmente las rayas rectangulares del agua por cintas curvas cortas, reflejos ligeros y espuma de ribera; los nodos heredados se conservan ocultos para comparación. Se agrupan las nuevas curvas en **una malla**, no cientos de objetos aislados.
- **Carreteras:** grietas discretas y desgaste junto a los laterales, agrupados en una sola malla, que no tapa los trazos centrales ni sirve de colisión.
- **Materiales:** las nuevas rocas conservan textura y mapa normal PBR originales. El color y relieve son independientes de la facción y de la iluminación seleccionada.
- **Comparación A/B reproducible:** nuevo control `Acabado V4: rocas, árboles, agua y caminos`. Una prueba GPU guarda `artifacts/tarvoka_terrain_v4_premium_comparison.png` con cámara, mapa y luz idénticos y verifica diferencia de píxeles.

## Mantener funcionamiento del juego

El código está en `scripts/ui/TerrainStudioPremiumFinish3D.gd`, llamado solo desde `CombinedArtStudioWeb.gd` al cargar el modo **ENTORNO Y MAPA 3D** con suelo continuo y acabado V4. No se modifican el motor de combate Android, la IA, el fog of war, la altura táctica, los costes de carretera o montaña ni los guardados.

## Próximas revisiones para aprobar el arte final

1. Comparar capturas GPU V2/V4 en valle, cañón y delta con modelos de referencia.
2. Incorporar progresivamente la rama V3.1 de pendientes, vegetación instanciada y carreteras continuas, revisando conflictos sin borrar sus aportes.
3. Inspeccionar textura en primer plano y arte del agua junto a unidades/edificios; corregir el nivel de detalle del terreno y su densidad.
4. Integrar chunks, LOD por distancia, culling y medición FPS/memoria en un teléfono Android real con mapa grande.
5. Solo después evaluar si la estética está lista para un producto comercial. Un aprobado de CI significa compatibilidad/consistencia, no automáticamente calidad comercial.

## Instrucciones

Abrir **TARVOKA Estudio 3D** → **ENTORNO Y MAPA 3D** → comparar **V4** con el interruptor. Hacer capturas de los tres biomas, probar los tres presets de luz y alejar/acercar. Guardar la evidencia de CI antes de fusionar.
