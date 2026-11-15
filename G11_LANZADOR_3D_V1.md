# TARVOKA — G11 Lanzador, escultura 3D V1

**Estado (15-nov-2026):** mallas nativas Godot 4.3 integradas en `scripts/ui/UnitModels3D.gd`, con animaciones y controles del Estudio 3D. No modifica el equilibrio, las reglas ni las estadísticas de las partidas.

## Identidad del modelo
- ID visual G11, familia Lanzador. Configuración de artillería coheteril compatible con la auditoría de familias (G12 se incorpora como variante/mejora de G11).
- Chasis blindado cerrado, cabina con cristales protegidos, tren de rodaje con dos bandas de oruga, doce pivotes de ruedas y 28 zapatas exteriores.
- Plataforma de giro y módulo de elevación independientes; batería 4×3 con doce tubos, aros y bocas oscuras, tapas y rieles protectores.
- Pintura de las ocho facciones sobre paneles de metal 3D; sin stickers o escudos falsos ni imágenes planas para sustituir geometría.
- Estado de daño intacto, leve, moderado, crítico y destruido; la reparación repone la geometría y no altera la salud del juego.

## Animación
`scripts/ui/G11VisualRig3D.gd` expone movimiento, disparo, impacto de bala, impacto explosivo y restauración de pose. El disparo coordina orientación, elevación y retroceso con destello y humo de tiempo limitado. Efectos son solo decorativos; los consumos de combustible/munición siguen a cargo de las reglas de TARVOKA.

## Integración y rendimiento
- `Models.build("mlrs", faction, true, 13)`: escultura V1 completa para Estudio 3D.
- `Models.build("mlrs", faction, true, 10)`: LOD histórico liviano para batalla Android.
- `BastionStudioAdapter.gd`: selector G11, controles de animación, facciones y cinco estados de daño.
- Publicación web mediante `.github/workflows/tarvoka-3d-pages.yml`. URL: https://edwinrodri12.github.io/Tarvoka/
- Prueba: `tests/test_g11_launcher_3d.gd` con las ocho facciones, tubos, ruedas, animaciones, cinco daños y restauración.
- Pruebas Godot 4.3 verificadas en GitHub Actions: https://github.com/edwinrodri12/Tarvoka/actions/runs/43689320992

## Pendiente para acabado comercial
- Profundizar UV/PBR y desgaste físico a escala visual Android sin sobrecargar las superficies.
- Definir y validar LODs de producción con pruebas medidas.
- Afinar partículas bajo lluvia/nieve sin sobrecarga visual.
- Validar visualmente el modelo girando 360° en navegador y medir FPS/RAM de múltiples unidades en Android; la prueba nativa de geometría **no equivale** a certificación de rendimiento de 8 jugadores.
- Integrar la representación de este G11 a la batalla solo después de validar escalas/cámara/visión y evitar duplicados con la unidad `Lanzador` existente.

## Actualización V2 — 15 de noviembre de 2026

**Estado:** integrada en `main` y validada con Godot 4.3; requiere aún revisión visual y pruebas de rendimiento físico en Android.

- `scripts/ui/G11FinishV2.gd`: casco y cabina reemplazados por prismas octagonales cerrados con bordes físicamente biselados; refuerzos de laterales, uniones, protecciones, ventilación y rueda tensora/piñón.
- Se eliminaron los viejos dos cubos de oruga y 28 zapatas estáticas del modelo detallado; ahora cada lado incorpora una banda cerrada y **40 eslabones móviles compartidos por un único MultiMesh** (80 eslabones en dos lotes de dibujo, no 80 mallas separadas). Los pivotes de doce ruedas existentes se conservan.
- `scripts/ui/G11VisualRig3D.gd` desplaza los eslabones por las dos rectas y los dos semicírculos del circuito de rodaje; al terminar/reparar la pose los devuelve a posición original.
- Materiales estándar Godot PBR: acero de diferentes rugosidades, acabado de goma mate y pintura metálica de facciones; los efectos VFX temporales conservan materiales independientes.
- El conjunto pesado se instancia solo en el visor (`art_level >= 13`); el campo de batalla sigue utilizando LOD antiguo de pocas mallas, **sin incremento de coste por 8 jugadores** hasta decidir una integración explícita.
- `tests/test_g11_launcher_3d.gd` cubre geometría nueva, dos MultiMeshes con 40 eslabones, desplazamiento físico y restauración, ocho colores, ataque, daño y LOD. CI nativo Godot 4.3: https://github.com/edwinrodri12/Tarvoka/actions/runs/43690256468

**Pendiente:** refinar texturas UV y microdesgaste de blindaje, revisar giro 360° del visor desplegado, optimizar partículas por clima y medir FPS/GPU/RAM en Android real con múltiples lanzadores. No declarar acabado comercial final hasta esas pruebas.

## Actualización V3 — 15 de noviembre de 2026

**Implementación real:** `scripts/ui/G11SurfaceV3.gd`, llamado por `scripts/ui/G11Art3D.gd` tras el acabado V2. No se altera ninguna regla, cifra de ataque o defensa, ni consumo de recursos.

- Tres texturas de desgaste generadas de forma determinista a 96×96 píxeles mediante `ImageTexture`; aplicadas solo a blindaje, cabina, faldones y refuerzos. Distintas rugosidades y niveles de metal PBR sin shaders personalizados para mejorar compatibilidad Web/Android.
- Desgaste discreto por bordes, zonas bajas, suciedad de mantenimiento y señales de contacto. Se mantiene la pintura de las ocho facciones en piezas originales.
- Panel de servicio posterior, protecciones del cristal, refuerzos de proa y **28 tornillos** reunidos en un `MultiMeshInstance3D`; no 28 draw calls separados.
- Prueba de regresión: `tests/test_g11_launcher_3d.gd` valida ocho facciones, superficies PBR, piezas de mantenimiento, 28 tornillos agrupados, LOD de batalla, daño y animaciones.
- Inspección real: `tests/test_g11_360_gpu_v3.gd` renderiza desde **ocho posiciones de cámara** además de daño crítico y disparo; genera 10 PNG exportables como artifact del workflow `g11-launcher-qa.yml`.
- **CI exitoso:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43691034701

**QA visual aún pendiente:** la generación satisfactoria de diez capturas no equivale por sí sola a inspección artística manual de cada ángulo (solapes, proporciones, suciedad y luces). Tampoco equivale a prueba de FPS, GPU o memoria en un dispositivo Android real con ocho jugadores. Antes de marcar el G11 comercialmente final, revisar esos PNG y completar stress tests de muchas unidades simultáneas.

## Actualización V4 — geometría real de lanzadores y parte posterior

**15-nov-2026 — Modelo Godot nativo; no concepto ni imagen generada.**

- `scripts/ui/G11GeometryV4.gd`: reemplaza los doce cilindros macizos y sus anillos superpuestos por un único `ArrayMesh` compartido con **tres superficies físicas** (cuerpo cilíndrico, boca anular biselada e interior tubular oscuro y profundo). Cada uno de los doce tubos mantiene tapa de fondo retrasada y su propia malla `MeshInstance3D`. Los anteriores discos de frente ya no tapan la abertura.
- Dos mecanismos hidráulicos, cada uno con cuerpo y vástago de distinta anchura, muñones articulados y geometría que actualiza su orientación y extensión en función de la elevación actual del módulo. Durante el retroceso del disparo se reajustan a la pose presente; la restauración devuelve todas las piezas a su posición inicial.
- Refinamiento físico trasero: cierre del bastidor, tapa del sistema de control, bisagras, refuerzos laterales, cantoneras, cables protegidos, faros traseros y una óptica adicional solidaria al lanzador.
- `scripts/ui/G11Art3D.gd` integra las capas V1–V4; `scripts/ui/G11VisualRig3D.gd` sincroniza el movimiento hidráulico, y `scripts/ui/BastionStudioAdapter.gd` identifica el nuevo acabado en TARVOKA Estudio 3D.
- Prueba de integridad en Godot 4.3: [G11 3D V4, CI aprobada](https://github.com/edwinrodri12/Tarvoka/actions/runs/43694358143). Incluye ocho facciones, las 12 aberturas 3D, los pistones, disparo, daño y reparación.
- Se generaron 12 imágenes de revisión con cámaras Godot, incluyendo acercamientos específicos a las bocas huecas y parte trasera. Están como artifact `tarvoka-g11-v4-muzzle-rear-360-review` en la ejecución indicada.

**Revisión artística pendiente:** observar las imágenes desde diferentes ángulos para corregir proporciones, intersecciones y pulir detalles si es necesario. El modelo todavía no se declara terminado comercialmente. Rendimiento y APK quedan pospuestos hasta completar el modelado.
