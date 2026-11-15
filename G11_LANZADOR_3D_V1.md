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

## Actualización V8 — salva 3D individual de doce cohetes (15-nov-2026)

- **Modelo nativo Godot 4.3** `scripts/ui/G11SequentialSalvoV8.gd`, incorporado a la cadena V1–V8 mediante `G11Art3D.gd` y `G11VisualRig3D.gd`. Nada de sprites ni fotomontajes. Se respetan las ocho facciones y todos los valores tácticos.
- Los doce tubos huecos V4, en orden `[0,5,10,3,8,1,6,11,4,9,2,7]`, reciben cada uno un **cohete 3D propio**, con cuerpo metálico cilíndrico, ojiva cónica, cuatro aletas y chorro del motor.
- Cada boca usa geometría de encendido **independiente**: anillo de presión `TorusMesh`, cuatro destellos direccionales y tres pequeñas nubes de humo. El antiguo fogonazo y humo esféricos genéricos quedan suprimidos visualmente; solo se conservan las raíces históricas por compatibilidad.
- Los lanzamientos están separados por `0.0515` en progreso normalizado, después del apuntamiento; la salva completa mantiene un total visual de doce proyectiles, pero **no consume 12 municiones tácticas** ni modifica daño, combate o economía.
- Los cohetes salen en dirección local `-Z`, solidarios con la elevación real y giro del lanzador. Se alejan de la boca, el chorro oscila y cada efecto se extingue de manera independiente. Al finalizar, reparar o restaurar, las mallas y fogonazos vuelven al estado invisible y reutilizable.
- En `BastionStudioAdapter.gd` se añadieron botones **Salva normal** y **Salva lenta x0.35**. Permiten revisar cada tubo en el modelo real desde cámara frontal o lateral.
- **Prueba CI aprobada**: [G11 SALVO V8 (Godot nativo)](https://github.com/edwinrodri12/Tarvoka/actions/runs/43734017448). Verifica ocho facciones, las doce bocas/proyectiles, orden de fuego, salida, restauración y bloqueo tras destrucción. Genera **18 imágenes de Godot** (doce encendidos individuales, cuatro fotos de vuelo desde un lado y vistas anterior/posterior a la salva). Artifact `tarvoka-g11-v8-twelve-individual-rocket-ignitions`.
- No se ha medido rendimiento Android aquí; antes de finalizar el arte debe hacerse revisión humana del ritmo, separación entre estelas y cámara lenta en el Estudio 3D.

**Próxima posible mejora visual:** suavizar la estela aerodinámica y la disipación de gases del propulsor y mejorar los efectos sincronizados en cada salva, sin alterar la mecánica del combate.

## Actualización V9 — estelas tridimensionales y disipación de gases (15-nov-2026)

**Modelado nuevo:** `scripts/ui/G11ExhaustV9.gd` se integra tras `G11SequentialSalvoV8.gd` en `G11Art3D.gd` y recibe poses sincronizadas desde `G11VisualRig3D.gd`. No se altera ninguna estadística de ataque, munición, economía, ni movimiento del juego.

- Los doce cohetes V8 incorporan dos mallas de escape por motor: núcleo luminoso y estela exterior, ambos realizados como `ArrayMesh` con anillos tridimensionales curvos y gradientes propios de color/transparencia. Se **estiran al acelerar** el proyectil, con la estela orientada en la dirección opuesta al vuelo local `-Z`.
- Cada tubo mantiene además dos sistemas independientes: gases de presión cerca de la boca y humo residual, que se dilatan, ascienden, se dispersan y se extinguen progresivamente, incluso después de que el cohete salga del encuadre.
- Los antiguos tres `SphereMesh` por boca (`G11V8_Presion_*`) y el cono rígido del motor V8 se ocultan para que no atraviesen las nuevas formas orgánicas, conservando los nodos por compatibilidad y restauración.
- Cada efecto permanece unido a su cohete o su boca real sobre el lanzador. Sigue la elevación hidráulica, giro de torreta y salvas alternadas de las ocho facciones. Las doce mallas se restauran a estado invisible al parar, tras destrucción o al reparar.
- El Estudio 3D presenta ahora el nombre «G11 Lanzador · Estelas V9 · 12 cohetes», con botones existentes **Salva normal** y **Salva lenta x0.35** para distinguir cada encendido. El pipeline de GitHub Pages incluye el nuevo módulo desde la fuente `main`.
- Prueba nativa Godot 4.3 aprobada: [G11 V9, 12 sistemas de gases y estelas](https://github.com/edwinrodri12/Tarvoka/actions/runs/43735566071). Los tests verifican vuelos escalonados, aumento de estela, disipación tardía, las ocho facciones y reparación. El artifact `tarvoka-g11-v9-exhaust-gas-24-godot-reviews` contiene **24 capturas de render real** desde doce disparos, cuatro vistas laterales, seis acercamientos y estados inicial/final.

**Pendiente de inspección artística:** estudiar en el Estudio 3D el color y la forma de los gases, y pulir cualquier pequeña intersección en el lanzamiento. No consideramos el G11 terminado sin esa revisión.

### Revisión visual V9b — gases compactos y fogonazo sin cuadrados (15-nov-2026)

Se descargaron y examinaron **las capturas renderizadas reales de Godot** de la versión V9. La primera iteración tapaba parcialmente el frente de doce tubos mediante superficies translúcidas grandes y el viejo halo cuadrado naranja dominaba la boca.

Corrección aplicada dentro de `G11ExhaustV9.gd`:

- Reducción del radio, alpha, expansión y duración del humo de presión y residual, para preservar lectura de los tubos aun durante salva completa.
- En lugar del TorusMesh luminoso y cuatro barras rectangulares V8, cada boca recibió un **nuevo fogonazo volumétrico cónico** con gradiente cálido y silueta redondeada; se preservan las piezas antiguas ocultas por compatibilidad.
- La disipación empieza antes. El test `test_g11_exhaust_v9.gd` comprueba explícitamente la contracción tardía del gas y que no reaparezcan los elementos viejos.
- [CI Godot 4.3 aprobado para la revisión](https://github.com/edwinrodri12/Tarvoka/actions/runs/43736084201), con 24 capturas actualizadas en `tarvoka-g11-v9-exhaust-gas-24-godot-reviews`. La segunda revisión visual muestra el frente despejado y estelas de tamaño más proporcionado.

Este es un refinamiento **artístico**, sin ajustar datos de juego. El modelo sigue pendiente de validación definitiva en el visor 3D a tamaño natural y pantalla Android.

## Actualización V10 — enfriamiento y retorno mecánico (15-nov-2026)

- **Nueva escultura nativa:** `scripts/ui/G11CooldownV10.gd` crea doce anillos 3D biselados y abiertos que brillan en los bordes de los tubos después de cada lanzamiento, sin tapar los doce orificios huecos V4, y doce finas columnas curvas de vapor con gradientes de transparencia.
- El calor es progresivo por orden de disparo: los primeros tubos disparados se atenúan antes que los últimos; la emisión y el vapor se extinguen gradualmente.
- `G11VisualRig3D.gd` ahora implementa **dos fases independientes**: la salva original V8/V9 conserva por completo su cronología; la fase `cooldown` dura 0.68 s después y devuelve suavemente plataforma giratoria, elevación y ambos hidráulicos al estado de reposo mediante interpolación `smoothstep`.
- El humo del último cohete de V9 no desaparece de golpe al cambiar de fase: `G11ExhaustV9.pose` admite ahora progreso ligeramente superior a 1 y permite que ese gas termine de disiparse mientras el lanzador vuelve a reposo.
- `BastionStudioAdapter.gd` cambia automáticamente desde la salva a `cooldown` sin reiniciar el modelo y añade botón **Ver enfriamiento**. Las ocho facciones conservan su pintura y los cinco daños anteriores.
- Se mantienen intactos daño, combustible, recursos, munición, turnos y lógica de combate: todo es presentación 3D.
- **Godot 4.3 QA:** [G11 V10 native cooldown](https://github.com/edwinrodri12/Tarvoka/actions/runs/43737023966) valida ocho facciones, doce bordes térmicos, humo prolongado, continuidad de posición y ángulos, retorno hidráulico y restauración.
- La misma ejecución entrega el artifact `tarvoka-g11-v10-cooling-hydraulics-18-godot-renders`: **18 renderizados reales** en cámara frontal, lateral y primer plano a distintas fases del enfriamiento, revisados como hoja de contacto.
- El Studio web de TARVOKA incorpora los nuevos archivos y controles desde el pipeline de publicación de Pages; confirmar la ejecución de Pages para comprobar el estado público.

**Estado artístico:** refinamiento V10 integrado y visualmente inspeccionado en 18 capturas. Pendiente aprobación definitiva del diseño general del G11 desde todos los ángulos en el visor interactivo. El próximo paso puede ser un pase final de proporciones y materiales de los tubos, soporte y carrocería; pruebas de rendimiento al final.

## Actualización V11 — bastidor hueco, proporciones y acabado metálico real (15-nov-2026)

**Avance artístico aplicado directamente a la escultura nativa de Godot 4.3:**

- Nuevo módulo `scripts/ui/G11ArmorFinishV11.gd`, integrado después de la secuencia de lanzamiento y enfriamiento V10. No se modifica balance, combate, mapas ni economía.
- **Corrección geométrica importante descubierta en las capturas reales:** el V1 conservaba `G11_ArmazonLanzador` como **caja sólida** (1.18 × 0.82 × 1.48 m). Su cara frontal obstruía los doce tubos huecos V4 aproximadamente a 0.11 m del labio. V11 sustituye esa caja por una **estructura de cuatro paredes cerradas y una abertura frontal realmente libre**, manteniendo el alojamiento de servicio posterior y la profundidad del interior de los tubos.
- La tapa superior `G11_TapaSuperior` se rehízo como una placa de **ocho aristas biseladas y material metálico satinado oscuro**, con tres nervaduras longitudinales en relieve y dos cordones discretos de soldadura. Las vistas superiores ya no presentan la anterior placa lisa y excesivamente clara.
- Añadidos cuatro rieles de cantonera extruidos con chaflanes reales; el borde exterior se mantiene separado de los labios de las bocas y de los anillos de enfriamiento V10. Tres divisores delgados pasan por los espacios exactos entre las cuatro columnas, sin cubrir ninguna abertura.
- Los doce tubos mantienen tres superficies reales: exterior metálico PBR, labio acerado y conducto interior oscuro/recesado. Se modelan 36 pequeñas marcas de desgaste metálico en un único `ArrayMesh`, y 16 cabezas de tornillo reales en un `MultiMesh`.
- Nuevos soportes trapezoidales laterales, juntas negras, bisagras de mantenimiento traseras, cerraduras de servicio y filtro ventilado del techo de cabina. Los colores y emblemas de las ocho facciones se conservan intactos.
- `BastionStudioAdapter.gd` presenta «G11 Lanzador · Acabados V11 · marco y metales» y mantiene los controles de giro, cámara, daños, salva lenta y enfriamiento.
- **QA nativa Godot 4.3 aprobada**: [G11 V11 — pruebas y revisión](https://github.com/edwinrodri12/Tarvoka/actions/runs/43738970713). Valida ocho facciones, la ausencia física de la cara que obstruía las bocas, 12 tubos con material PBR y abertura conservada, biseles, tornillos, desgaste y conservación de disparo, retorno hidráulico y cinco daños.
- Artifact `tarvoka-g11-v11-beveled-metal-20-native-godot-angles`: **20 capturas Godot reales**, con ocho vistas de órbita, cinco macro vistas de bocas, dos posteriores, dos de techo, dos estados de daño y enfriamiento. La inspección de esas imágenes confirmó ahora mayor profundidad visual de los doce tubos y mejores superficies superiores.
- El código de G11 V11 se incorpora al pipeline de exportación del Estudio 3D web. La **publicación web** es una comprobación separada de la QA del modelo: no asumirla hasta la última ejecución exitosa de GitHub Pages.

**Pendiente:** un repaso visual del nivel de pintura de facción y piezas del casco inferior en el visor, más la aprobación del diseño general antes de dedicar una etapa aparte a rendimiento y APK. Mantener esta línea de trabajo centrada en el modelo 3D.

## Actualización V12 — cabina, chasis y ventilación exterior (15-nov-2026)

**Escultura 3D real en Godot 4.3**, posterior al G11 V11 y anterior a cualquier trabajo de rendimiento.

- Nuevo `scripts/ui/G11CabChassisV12.gd` se integra desde `G11Art3D.gd`, conservando todo el modelo PBR de V11 y los disparos y enfriamiento hasta V10.
- Dos puertas laterales blindadas con espesor auténtico, marcos de ventanas sólidos, cristales de superficie separada y manijas; nuevos detalles de pintura por facción sin sustituir los emblemas anteriores.
- Los antiguos soportes de retrovisor cúbicos V1 desaparecen: se sustituyen por brazos delgados, carcasas 3D biseladas y lentes pulidas.
- Limpiaparabrisas en ambas mitades del cristal frontal con pivotes, brazos inclinados y goma; un parachoques frontal de sección octagonal y parrilla en relieve con seis insertos.
- Escalones antideslizantes reforzados por dos soportes en cada lateral, con cinco ribetes negros cada uno, más un protector para el tramo posterior de cada oruga.
- Rearranques de mantenimiento: cierre y bocallave en ambos extremos del portón trasero, tornillería de puerta y portón en lote `MultiMesh` de 24 cabezas sólidas.
- Ventilación reconstruida: la anterior parrilla de motor de seis bloques V1 se sustituye por un recinto oscuro con siete lamas de metal. Una inspección posterior de las imágenes nativas demostró que el lanzador elevándose ocultaba ese acabado desde ciertos ángulos; se añadieron por ello dos tomas laterales con marcos metálicos y cuatro lamas auténticas por lado, montadas en el chasis y visibles desde cámaras laterales.
- Durante daño crítico (nivel 3+), la ventilación intacta central y lateral desaparece para descubrir el motor carbonizado V6, sin afectar el cristal o las puertas de la cabina. Reparación restaura esas piezas de manera reversible.
- Estudio 3D `BastionStudioAdapter.gd`: entrada «G11 Lanzador · Cabina V12 · interiores y carrocería» y descripción de componentes revisables; conserva los controles de cuatro vistas, daños y salva.
- QA automatizada `tests/test_g11_cab_chassis_v12.gd`: verifica en las ocho facciones las ventanas de lado, marcos, cristales, superficies, anclajes, cerraduras, parachoques, rejillas laterales/centrales, reparación y compatibilidad con la salva V8, el pulso de enfriamiento V10 y el marco abierto V11.
- `tests/test_g11_cab_chassis_v12_capture.gd` crea **20 capturas reales de Godot**: ocho vistas orbitales, cuatro acercamientos a cabina, dos parabrisas, dos tomas de motor, dos accesos posteriores y dos etapas de daño; las cámaras de motor están posicionadas para no ocultar sus tomas de aire bajo el lanzador.
- La integración GitHub Pages `.github/workflows/tarvoka-3d-pages.yml` incluye `G11CabChassisV12.gd` en el exportador del Estudio. Verificar la última ejecución exitosa de publicación antes de afirmar la disponibilidad V12 en el sitio público.

**Pendiente artístico:** evaluación a escala natural de la cabina y pintura de facción desde el teléfono; no declarar completo por aprobar solamente pruebas geométricas. El rendimiento y APK vendrán después.

## Actualización V13 — engranes corregidos y techo del lanzador por facción (15-nov-2026)

**Petición explícita del usuario:** corregir los engranajes de las orugas y aplicar mayor superficie del color de cada facción, especialmente arriba del lanzacohetes. Trabajo realizado en mallas editables nativas de Godot 4.3: ningún render generado ni imagen conceptual sustituye este cambio.

- Nuevo `scripts/ui/G11TracksFactionV13.gd`, aplicado después de `G11CabChassisV12.gd` por `G11Art3D.gd`, con actualización de giro desde `G11VisualRig3D.gd`.
- **Problema identificado en V5:** los engranes/tensores estaban centrados en x=±0.996, cuando el eje del contorno real de la oruga V2 es x=±0.79, o sea **0.206 m demasiado afuera**; el radio de sus dientes era 0.235 m mientras el interior de la banda es 0.265 m, con una separación radial de 0.030 m. Además coexistían ruedas macizas V2 detrás de los engranes V5, causando solapamiento visual.
- V13 alinea ambos ejes con la trayectoria real de cada oruga: x=±0.79, y=0.35, z=±1.04. Elimina dos tensores macizos V2 superpuestos por lado y los antiguos tapones V5 mal ubicados. Los sustituye por **ruedas 3D anulares y abiertas con ocho radios**, agujeros reales, centro de eje y seis tornillos por cada extremo. La pieza delantera es un tensor liso y la trasera un engrane impulsor dentado.
- El engrane trasero pasa a **diez dientes** dimensionados para que el paso de dientes se acerque al paso de cuarenta zapatas en un circuito de 6.36 m. Su radio de paso es 0.258 m, puntas a 0.265 m coincidiendo con el contorno interior de la banda; el tensor delantero tiene un radio de 0.263 m. La rueda no flota por fuera ni corta las gomas.
- **Giro corregido:** el mecanismo V5 dibujaba 720° de giro por un recorrido de sólo 2.15 m; V13 usa la relación física `angulo_rad = desplazamiento_oruga / 0.258`. Tanto el engrane trasero como el tensor delantero de las dos orugas giran al ritmo de los eslabones animados, y se restauran a cero cuando el vehículo se detiene.
- **Color de facción:** `G11_TapaSuperior`, la cubierta real del lanzacohetes biselada en V11, recibe ahora material PBR en el color propio de cada una de las **ocho facciones**, no un cubo ni una imagen superpuesta. Las tres nervaduras metálicas oscuras siguen visibles. Se añadieron además paneles laterales en el módulo lanzacohetes y franjas discretas sobre la cabina, usando exactamente el color recibido de `Factions`. Los orificios y materiales interiores de los doce tubos no se alteran.
- Se actualizaron las antiguas comprobaciones del G11 para reflejar el nuevo engranaje y el techo cromático. QA Godot nativa `tests/test_g11_tracks_faction_v13.gd` valida la trayectoria real, el radio a partir de los vértices, el número de dientes contra el paso del caucho, giro sincronizado, ocho colores distintos y preservación de todos los estados de daño, disparo y reparación.
- `tests/test_g11_tracks_faction_v13_capture.gd` prepara **20 fotogramas auténticos de Godot**: ocho órbitas, cuatro macros de engranes delanteros/traseros, cuatro techos con distintas facciones, dos momentos de las orugas animadas y dos daños.
- La vista interactiva `BastionStudioAdapter.gd` ahora identifica este acabado como «ENGRANES Y FACCIÓN V13». El pipeline web exporta el módulo V13 al Studio de TARVOKA.

**Estado:** cambios de geometría y pintura integrados. No pasar aún al benchmark Android ni dar el G11 por terminado: inspeccionar primero que los engranajes engranen visualmente con los tacos de caucho y que la cubierta de facción se lea correctamente en la escala real del juego.


## Actualización V14 — hidráulicos articulados y registros de mantenimiento 3D (15-nov-2026)

**Integrado en `main` en el PR [#399](https://github.com/edwinrodri12/Tarvoka/pull/399).** El siguiente pase permanece centrado exclusivamente en la escultura del modelo; sin mejoras de rendimiento todavía.

- Módulo real de Godot 4.3 `scripts/ui/G11MechanicalDetailV14.gd`, aplicado por `G11Art3D.gd` después de V13.
- Cuatro circuitos de mangueras hidráulicas con siete cilindros curvos por circuito (28 tramos nativos), dos por lateral. Cada tramo interpola su posición entre el soporte de la plataforma giratoria y el conector fijo a la elevación mediante una curva cuadrática; la función `update_hoses` recalcula la forma en cada pose de disparo/enfriamiento y evita mangueras rígidas flotantes.
- Cuatro parejas de conectores hidráulicos metálicos, cubiertas concéntricas de los ejes de elevación y soportes inferiores; todos son geometría 3D y no texturas decorativas.
- Registro posterior con puerta, junta, dos bisagras, dos cierres, refuerzo y ocho pernos en MultiMesh. Dos registros laterales de servicio separados de los grandes paneles cromáticos V13, para conservar lectura clara de las facciones.
- No se reemplazan la cubierta PBR `G11_TapaSuperior`, la estructura abierta del bastidor, los doce conductos de cohetes, ni los sprockets de diez dientes V13. Se preservan los cinco estados de daño y las animaciones ya existentes.
- `G11VisualRig3D.gd` actualiza el tendido de mangueras en cada pose reversible. `BastionStudioAdapter.gd` identifica el G11 como V14 y el exportador de Pages incorpora el nuevo módulo.
- Test `tests/test_g11_mechanical_detail_v14.gd` para ocho facciones, los cuatro circuitos, 28 tramos, doce tubos, material de pintura, sincronización con elevación, giro de orugas, daños y reparación. **GitHub Actions G11 native launcher sculpt QA del PR #399: aprobado**.

**Estado:** V14 integrada en la fuente del juego y probada en Godot. La publicación web se comprueba por separado. Aún falta inspección artística del conjunto en el visor desde todos los ángulos; no dar el G11 por terminado antes de esa evaluación.


## Actualización V15 — bastidor posterior, blindaje biselado y galerías Godot (15-nov-2026)

**Integrado en `main` desde [PR #409](https://github.com/edwinrodri12/Tarvoka/pull/409).** La rama de revisión se regeneró desde `main` actual para conservar los cambios concurrentes de Bastión P06 V19. El PR antiguo #408 se cerró sin fusionar para evitar conflictos.

- Nuevo módulo `scripts/ui/G11AftPodFinishV15.gd`. Dos paneles de blindaje posterior son **prismas tridimensionales cerrados** de siete lados en el plano Y/Z y espesor real en X, modelados con `SurfaceTool` y normales calculadas. El diseño crea una silueta más oblicua y protegida sin situar un cubo delante de las doce bocas abiertas.
- El nuevo bastidor posterior lleva dos travesaños octogonales en sentido transversal, dos montantes, seis lamas 3D sobre una toma de ventilación oscura, nervaduras, once pequeños elementos metálicos por lateral y una marca posterior de orientación.
- Se conserva el material PBR y la pintura del techo de las ocho facciones, los paneles cromáticos V13 y los engranes impulsores de diez dientes. Los cuatro circuitos de mangueras V14 y los paneles de mantenimiento permanecen visibles; las cubiertas V15 están situadas sobre las tomas hidráulicas y detrás de las zonas pintadas del lanzacohetes.
- Daños complementarios sobre los nuevos paneles: rozaduras en daño medio, una viga torcida en daño crítico y reparación completa que oculta ambos efectos. No se modifican HP, ataque, defensa, combustible, munición, turnos ni economía.
- `G11Art3D.gd` aplica V15 después de V14. `BastionStudioAdapter.gd` etiqueta correctamente **G11 Lanzador V15** y añade botones «V15: trasera en 3/4» y «V15: blindaje opuesto», además de conservar animaciones, selección de las ocho facciones y el resto del visor. La publicación Pages incluye `G11AftPodFinishV15.gd`.
- `tests/test_g11_aft_pod_finish_v15.gd` verifica ocho facciones, las geometrías reales con volumen, seis lamas, materiales, animaciones, daños y preservación de doce tubos, V13 y V14.
- `tests/test_g11_aft_pod_finish_v15_capture.gd` genera **14 capturas verdaderas del render Godot**, distribuidas en seis vistas de la zona posterior, cuatro macros de ambos laterales con elevación, dos pinturas de facción, daño crítico y salva. El workflow G11 exporta el artifact `tarvoka-g11-v15-14-real-godot-aft-pod-review`.
- **QA nativa Godot 4.3 del PR #409: aprobada.** La publicación web se valida en el workflow separado «Publish TARVOKA native 3D art studio».

**Estado artístico:** V15 integrada en el juego y el Estudio 3D. Mantener el G11 en diseño activo; inspeccionar las proporciones de las nuevas piezas desde atrás y laterales antes de considerar cualquier optimización Android o declarar finalizado el vehículo.
