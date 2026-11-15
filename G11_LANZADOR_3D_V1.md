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

## Actualización V5 — tren de rodaje y plataforma (15-nov-2026)

**Trabajo real en el escultor nativo Godot 4.3, sin generar imágenes conceptuales:**

- `scripts/ui/G11MechanicsV5.gd` crea doce ruedas nuevas con perfil anular de neumático, llanta con doble bisel y centro hundido; reemplaza los antiguos cilindros macizos, no los tapa. Mantiene los doce pivotes animados heredados del G11 V1.
- Cada rueda incluye seis pernos 3D agrupados en un `MultiMeshInstance3D`. Los trenes de rodaje muestran un piñón trasero y tensor delantero de 16 dientes por lado, modelados como malla de contorno real.
- Los doce amortiguadores tienen cuerpo y vástago de dos diámetros y una unión al pivote móvil. `G11VisualRig3D.gd` los actualiza con cada pose de avance y restaura sus longitudes al detenerse. Los piñones traseros giran con las orugas.
- La plataforma recibió corona de giro anular horizontal y dos refuerzos estructurales triangulares extruidos, sustituyendo un collar anterior orientado de lado. La escotilla de techo ya no es un rectángulo flotante: ahora tiene asiento, bisagra y tapa circular.
- El G11 V5 conserva los tubos huecos y el doble sistema hidráulico V4, los materiales PBR V3, las orugas V2, ocho facciones y cinco niveles de daño. Ningún cambio en estadísticas o economía.
- `BastionStudioAdapter.gd` incorpora botones específicos de vista frontal, lateral, posterior y lateral opuesto para inspeccionar la escultura.
- Pruebas: [workflow G11 V5 aprobado](https://github.com/edwinrodri12/Tarvoka/actions/runs/43695421079). Incluye control de geometría real, doce ruedas, pernos, giro de piñones, desplazamiento y restauración de suspensión, modelo para ocho facciones y animaciones existentes.
- El artifact `tarvoka-g11-v5-running-gear-bearing-360-review` contiene **14 capturas Godot reales**: ocho ángulos, inspección de tubos huecos, trasera, suspensión, corona de giro, daño crítico y disparo.

**Pendiente artístico:** revisar manualmente los acercamientos en el visor (alineación de llantas y orugas, contacto de amortiguadores, proporciones del soporte de torreta y coherencia de daños). Esta revisión por capturas automatizadas no implica aprobación visual final. Las pruebas de FPS, APK y escenarios con ocho jugadores se posponen mientras se perfecciona el modelado.

## Actualización V6 — blindaje deformado y daños tridimensionales (15-nov-2026)

**Objetivo artístico:** que cada estado de daño parezca una transformación física progresiva del G11, no una esfera de partículas o una caja colocada encima del blindaje.

- `scripts/ui/G11DamageSculptV6.gd` añade geometría nativa para tres cráteres de proyectil con anillos deformados e interior oscuro, rozaduras sobre cabina y partículas metálicas sólidas.
- Daño medio: el panel lateral derecho intacto **desaparece** y es sustituido por una nueva malla cerrada de blindaje doblado en dos pliegues. Se descubre una junta oscura bajo la deformación y se aplasta parcialmente una tapa del motor.
- Daño crítico: panel izquierdo rasgado y con espesor real, compartimiento interior oscuro expuesto, tres conducciones metálicas visibles, cubierta del motor carbonizada y brasas integradas en el volumen.
- Destrucción: el módulo original del lanzador deja de verse, aparece un hueco oscuro en el anillo de la torreta, tres fragmentos sólidos desprendidos que descansan sobre el casco, tubo hidráulico roto y restos carbonizados. Se pierden la antena trasera y la tapa de escotilla en etapas apropiadas.
- Reacciones diferenciadas: pequeñas esquirlas duras durante impactos de balas y, para explosivos, un anillo real tipo `TorusMesh` con cinco fragmentos metálicos, encima de los efectos suaves existentes.
- `G11Art3D.apply_stage` restaura exactamente la protección lateral, antena, escotilla, corona y elevación cuando se regresa al estado intacto. No se alteran HP, defensa, movilidad, ataques ni consumos.
- `BastionStudioAdapter.gd` ofrece botones directos para daño leve, moderado, crítico, destrucción y reparación, manteniendo control de cámaras y animaciones.
- QA automatizada [G11 V6 Godot 4.3 — ejecución aprobada](https://github.com/edwinrodri12/Tarvoka/actions/runs/43697047907) verifica que el nuevo modelo existe en las ocho facciones, prueba las cinco etapas y sus reparaciones y crea **21 fotografías renderizadas por Godot**, incluyendo todos los daños y las dos clases de impacto. Artifact: `tarvoka-g11-v6-physical-damage-360-review`.

**Estado:** la geometría está integrada y los tests pasan, pero falta una inspección estética humana de las imágenes renderizadas para resolver posibles intersecciones y terminar el acabado comercial; no declarar completo sin esa inspección. Continuar con el modelado, no con benchmarks ni APK.

## Actualización V7 — humo, fuego y corrección de intersecciones (15-nov-2026)

- `scripts/ui/G11DamageAtmosphereV7.gd`: **10 columnas de humo** y **8 lenguas de fuego** en `ArrayMesh`, con volúmenes irregulares curvados y colores/transparencias graduados. Sustituyen las esferas primitivas anteriores; medio = humo, crítico = llamas + humo, destruido = fuego en la cavidad de la torreta.
- El Estudio 3D anima estos volúmenes en reposo, sin requerir movimiento ni disparo. El rig de Godot los mueve durante las animaciones del vehículo.
- A partir de daño moderado oculta las placas y franjas derechas que obstruían el blindaje plegado; desde daño crítico despeja las cubiertas izquierdas que ocultaban el compartimento abierto y sus conducciones. En destrucción oculta la torreta intacta para descubrir la cavidad real. La reparación revierte todo.
- Se respetan las ocho facciones, color, armamento y estadísticas tácticas. La escultura no modifica costes, daño o defensa.
- Godot 4.3 genera **25 imágenes reales** del modelo y comprueba fases de daño, piezas visibles y reparación: [G11 3D V7 QA](https://github.com/edwinrodri12/Tarvoka/actions/runs/43697890831), artifact `tarvoka-g11-v7-physical-fire-smoke-damage-review`.
- Las pruebas pesadas de rendimiento quedan únicamente disponibles a través de ejecución manual del workflow hasta terminar la escultura.
- **Pendiente de inspección artística humana**: estudiar superposiciones de cerca, matices de humo/fuego e iluminación en dispositivo. Próximo foco sugerido: detallado real de cada lanzamiento de cohete.
