# TARVOKA · Ciudades civiles V12 — modelado en progreso

Estado: **escultura 3D en desarrollo, no declarada final**.

## Arquitectura acumulativa
- V1: manzana, lotes, volúmenes residenciales y ayuntamiento
- V2: cubiertas, fachadas y marcos volumétricos
- V3: plaza, accesos y movilidad
- V4: silueta táctica con variantes de distancia
- V8: fachadas traseras y laterales habitadas, cubierta específica por nivel
- V9: remates, canalones, materialidad de teja/piedra/vidrio/metal
- V10: entradas cívicas/comerciales y continuidad con aceras
- V11: muros irregulares dañados, interiores rotos, cubierta fragmentada
- **V12: daños laterales, secciones interiores y continuidad de escombros**

## Estado de los daños 3D
- D0: esquinas y materiales intactos, sin escombros
- D1: grietas físicas discretas y piedras pequeñas desprendidas
- D2: esquinas rotas, marcos laterales carbonizados, acero expuesto, techos V11 partidos y pequeño derrame de cascotes
- D3: paredes exteriores irregulares V11, vigas transversales, pisos y escaleras fragmentadas V12; aceras próximas con escombros conectados a la fachada
- D4: muros muy bajos, cimentación abierta, vigas caídas y montones sin restaurar niveles altos ni fachadas intactas

Los materiales se calculan con StandardMaterial3D y todas las piezas se construyen como BoxMesh, CylinderMesh o SurfaceTool triangulado; no son imágenes 2D.

**Importante:** el derrame de cascotes de las cuatro viviendas se limita al propio solar urbano; se mantiene separado de la calzada principal en el eje Z, sin tocar reglas de colisión, producción ni captura. La calle se mantiene fija.

## Inspección artística
Abrir `scenes/CivilianCityDesignStudioV12.tscn` en Godot 4.3. Esta escena hereda las tres tipologías, los ocho colores de facción, cinco estados de daño y tres niveles de geometría de las fases anteriores. Añade cámaras para vista lateral, primer plano de escombros e interiores, y reorganiza las acciones en varias filas para no desbordar el visor horizontal.

Publicación web de diseño: `https://edwinrodri12.github.io/Tarvoka/ciudades/`. La rama `main` mantiene solo el empaquetador Pages y la versión jugable previamente aprobada; la geometría V12 permanece en la rama artística.

## Próxima prioridad antes de la revisión final
Rematar **transición entre restos de tejados, muros y pavimentos**, reforzar **lectura de fachadas según orientación** y completar **detalles del ayuntamiento dañado**. No declarar el modelo final ni iniciar pruebas de jugabilidad, QA de rendimiento o APK hasta que el usuario apruebe el diseño.
