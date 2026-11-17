# TARVOKA — G13 V33, escultura 3D de pasos de rueda y transición del chasis

Estado: **integrada en el modelo Godot y en el menú del visor compartido**. Sin declarar terminada la G13; la publicación pública, la evaluación visual y las pruebas físicas siguen pendientes.

## Diseño 3D (trabajo de arte, no jugabilidad)

- Cuatro **guardabarros curvos reales**, uno en cada rueda del chasis 4×4. Se construyen con `SurfaceTool` como dos superficies de semianillo cerradas; las ruedas quedan visibles en vez de cubiertas por una pieza cuadrada.
- Curvatura interior de 0,354 m sobre radio límite estimado de neumático/banda de rodadura de 0,324 m: **0,030 m de separación radial nominal** en el arte. No se afirma una comprobación física/renderizada de holguras.
- Cuatro bordes metálicos siguiendo el arco superior del guardabarros; tono acero usado y proporciones discretas.
- Dos uniones sólidas inclinadas sobre los hombros traseros de la cabina, conectando visualmente cabina sellada y monocasco bajo, modeladas en una sola malla `ArrayMesh` (sin colisiones tácticas).
- Cuatro elementos de bisagra de servicio: en la versión LOD13 se sitúan sobre la puerta trasera con eje vertical; en la versión LOD8 se ubican sobre el capó de servicio trasero con ejes transversales.
- Todo se añade sobre `G13_Casco4x4` y no cambia articulación de torreta, disparos, radar, ruedas giratorias, armas ni estadísticas.
- Los acabados y esmaltes de facción V32 permanecen intactos, sin recolorear la estructura principal.
- **Cuatro nodos de dibujo adicionales** por LOD: cuerpo de arcos, moldura, unión y bisagras; instanciación de 4 arcos y 4 bisagras.

## Integración

- `scripts/ui/G13ChassisFinishV33.gd`: construcción aditiva de geometría 3D y comparador de visibilidad `show_finish()`.
- `scripts/ui/UnitModels3D.gd`: instala V33 después de V32, tanto en LOD13 como en LOD8 del rol visual `aa_mobile`.
- `scripts/ui/BastionStudioAdapter.gd`: muestra G13 V33 y los controles **Mostrar pasos de rueda y bisagras** / **Comparar con V32** sin cambiar cámara, facción ni unidad.
- No se modifican modelos de otras unidades, reglas de combate ni animaciones originales.

## Próxima prioridad sugerida: V34

Acabado de carrocería de G13: líneas de unión entre paneles de cabina y blindaje, juntas y cierres visibles, detalles de parachoques y protección posterior. Mantener la identidad de facción V32, evitar nuevos elementos ofensivos, y continuar en modelado sin entrar a aprobación definitiva todavía.
