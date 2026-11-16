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


## Actualización V16 — perímetro frontal, uniones de cubierta y 16 vistas reales (15-nov-2026)

**Integrada en `main` con [PR #411](https://github.com/edwinrodri12/Tarvoka/pull/411)**. Continuamos perfeccionando el mismo G11 en Godot, no mediante una ilustración conceptual.

- Módulo `scripts/ui/G11FrontFrameV16.gd` construye cuatro perfiles octagonales de bastidor frontal, extruidos con ocho caras biseladas y volumen real. Se ubican fuera del contorno de las doce bocas de cohetes (y=±0.468, x=±0.613; la parrilla tiene sus centros hasta x=±0.42, y=±0.24 y labios de radio 0.115 m).
- Las cuatro cartelas de esquina son prismas triangulares físicos con pernos; el marco conserva el hueco central abierto.
- Dos bordes longitudinales, cuatro cordones de soldadura cilíndricos, dos tapas de registro en el techo con bisagras/cierres y unas juntas posteriores añaden profundidad auténtica sin sustituir la cubierta original pintada por facción.
- Daño medio muestra rozaduras en el borde frontal; daño crítico agrega una arista doblada; reparación restaura la geometría del estado limpio.
- No cambia propiedades de combate, economía, movilidad, combustible o animaciones aprobadas. El modelo continúa manteniendo V11 (12 bocas reales), V13 (engranes y pintura), V14 (cuatro circuitos hidráulicos) y V15 (blindaje posterior).
- `BastionStudioAdapter.gd` actualiza selector y leyenda a **G11 V16**, agregando cuatro vistas: frontal en 3/4, frontal contrario, techo/articulaciones y juntas posteriores. `.github/workflows/tarvoka-3d-pages.yml` incorpora la dependencia V16 a la exportación web.
- QA `tests/test_g11_front_frame_v16.gd` recorre 8 facciones, comprueba mallas tridimensionales, integridad de las 12 bocas, techo PBR, articulación, daños y reparación. `tests/test_g11_front_frame_v16_capture.gd` genera **16 capturas auténticas de Godot** de frontal, techo, pintura, juntas y daños.
- Workflow G11 del PR #411 **aprobado**. La publicación de Pages es un workflow independiente: verificar que finalize en verde antes de anunciar un visor actualizado.

**Pendiente artístico:** evaluación de proporciones de los refuerzos frontales en el móvil. No cerrar el modelo ni iniciar pruebas de estrés de Android hasta aprobación del diseño.


## Actualización V17 — microtexturas PBR, desgaste operativo y modo de comparación (15-nov-2026)

**Implementado en [PR #419](https://github.com/edwinrodri12/Tarvoka/pull/419) y fusionado a `main`.** Continua el diseño del mismo lanzador G11 en Godot 4.3, sin imágenes conceptuales.

- Nuevo `scripts/ui/G11SurfaceWeatherV17.gd`. Aplica materiales independientes `StandardMaterial3D` con rugosidad y metalicidad diferenciadas a la cubierta del lanzador y a los paneles originales. La pintura V13 se conserva idéntica en `albedo_color` y nunca se reemplaza con un color genérico.
- Textura metálica procedimental de 128×128 píxeles generada una vez por sesión con `ImageTexture.create_from_image`. Aplicada a superficies con coordenadas UV existentes (paneles de facción, compuertas de mantenimiento). No se finge texturizar el techo V11 sin UV: conserva su albedo y recibe variación PBR física, más geometría de pátina independiente.
- Una malla real de desgaste sobre los labios anulares de las doce bocas delanteras: **576 vértices de `SurfaceTool`**, distribuidos en 24 sectores de acero exterior. Radio mínimo de desgaste 0.105 m frente al hueco interior de 0.078 m: no se obstruyen los tubos.
- Marcas superficiales del techo mediante planos con textura de rayones y transparencia, placas oscuras en juntas y bordes y suciedad bajo el respiradero posterior. Los detalles visibles se agrupan bajo `G11V17_DesgasteOperativo`.
- Función interactiva `set_wear(model, enabled)` alterna acabado con desgaste operativo y acabado visualmente limpio en el mismo modelo, sin alterar estadísticas ni las piezas mecánicas.
- Desgaste añadido por niveles de daño: pintura saltada desde daño moderado, una zona de metal carbonizado desde daño crítico. Reparación elimina esos daños sin borrar el desgaste operativo seleccionado.
- En `BastionStudioAdapter.gd` el G11 aparece como **V17**, con botones «V17: desgaste operativo» / «V17: pintura limpia» y puntos de vista adicionales para inspeccionar las bocas y el techo. Conserva las vistas anteriores. El flujo Pages copia el módulo V17 y exporta la experiencia interactiva real.
- QA `tests/test_g11_surface_weather_v17.gd` verifica ocho pinturas diferentes, texturas asignadas, 576 vértices de desgaste, tubos abiertos, alternancia de uso, daños y animaciones existentes. `tests/test_g11_surface_weather_v17_capture.gd` produce **16 imágenes auténticas de Godot** (pares limpio/usado, varias facciones, daño y elevación), artefacto `tarvoka-g11-v17-16-real-godot-pbr-weather-comparison`.
- CI del PR #419: **G11 native launcher sculpt QA aprobado**. Publicación web de V17 se valida separadamente desde la ejecución de Pages del commit de incorporación a `main`.

**Siguiente prioridad artística:** revisión de lectura visual y materiales bajo iluminación diurna/nocturna; no considerar terminado el G11 ni iniciar las pruebas de estrés Android hasta que se aprueben los acabados.


## V18 — reconstrucción de las orugas y eliminación de geometrías encimadas (15-nov-2026)

**Integrada en `main` mediante [PR #424](https://github.com/edwinrodri12/Tarvoka/pull/424)**, conservando el desarrollo simultáneo de **Bastión P06 V22**. La rama preliminar #422 se cerró sin fusionar. Se trata de geometría auténtica en Godot 4.3, no de un boceto.

**Problemas confirmados en el código de las versiones anteriores:**

1. Las ruedas de los extremos quedaban demasiado cerca de los engranajes por sus centros en z=-1.19...+1.16 frente a engranajes ±1.04: el solapamiento era inevitable.
2. Las llantas, bujes y remaches sobresalían por el lateral del caucho. Engranajes y tapas sobresalían en X.
3. Persistían seis paneles V1 y seis placas de pintura V1 en el mismo lugar que el blindaje V2, además de una gran falda metálica que invadía la banda superior.
4. El lado interior y exterior del caucho tenían distinta fase al muestrear las curvas, y el arco **posterior** estaba dibujado **hacia dentro** del vehículo en vez de rodear el engranaje por fuera. Este fue un defecto adicional identificado por el nuevo test nativo.
5. La suspensión seguía usando una altura de reposo de 0.26 m después de reubicar los pivotes en 0.265 m; se corrigió su regreso exacto.

**Ensamblaje verificado por Godot:**

- En `G11FinishV2.gd`, `TRACK_HALF_LENGTH=1.34`, 46 zapatas por lado, ancho físico de zapata 0.282 m, largo de 0.135 m y espesor de 0.042 m. `_path_matched` dibuja ambas caras con una sola fase y ambos arcos doblan hacia el exterior.
- En `G11Art3D.gd`, los seis pivotes por lado se distribuyen desde z=-0.875 hasta z=+0.875 en saltos de 0.35 m. Los engranajes en `G11TracksFactionV13.gd` quedan a ±1.34 m, con radio exterior 0.265 m y diez dientes. Las llantas reducen su radio a 0.165 m. La holgura proyectada entre rueda extrema y engranaje es **0.035 m**, y entre ruedas consecutivas **0.020 m**, antes de compresión dinámica.
- Los perfiles de llanta, buje y pernos se reposicionan para quedar por dentro o a ras de la cara exterior del caucho en X, no por fuera. Los soportes/amortiguadores se montan detrás de la banda, no encima.
- El módulo nuevo `G11TrackAssemblyV18.gd` elimina físicamente los 12 paneles/pinturas laterales antiguos, reutiliza las dos faldas de acero originales convertidas en guardabarros estrechos sobre el caucho y agrega cuatro pernos de fijación por lado en un MultiMesh. Distancia estática del guardabarros al punto más alto de la zapata ~0.033 m.
- `G11VisualRig3D.gd` actualiza el movimiento de la suspensión a un recorrido visual de ±0.008 m y devuelve cada pivote a y=0.265 sin holguras residuales tras las animaciones.
- `BastionStudioAdapter.gd` muestra la versión **G11 V18 orugas reconstruidas** con controles de acercamiento para ambas orugas, engranaje posterior, tensor delantero y marcha; mantiene la comparación limpio/desgaste V17. El flujo de Pages conserva los controles Bastión V22 y exige que G11 V18 permanezca visible.
- `tests/test_g11_track_clearance_v18.gd` verifica con distancias reales la ausencia de solapamientos entre las 12 ruedas, ambos engranajes y las dos bandas, 46 zapatas por lado, trayectorias, salientes laterales, reparación y ocho pinturas. `tests/test_g11_track_clearance_v18_capture.gd` obtiene 16 imágenes renderizadas verdaderas de perfiles, piñones, marcha y daño.
- Las pruebas antiguas de G11 V1/V11 dejaron de requerir las piezas V1 duplicadas eliminadas; ahora comprueban que el color continúe en los paneles V13 y que las zonas dañadas queden correctamente visibles. **QA G11 del PR #424: aprobada.**
- Sin cambios en HP, potencia, costo, movimiento táctico, combustible, munición, poderes ni economía del videojuego.

**Estado:** la geometría está integrada y pasó comprobaciones nativas. Revisar las nuevas 16 capturas y los cuatro acercamientos en el visor web antes de considerar esta apariencia definitiva. El G11 continúa en refinamiento; rendimiento Android se evaluará después.


## V19 — terminación real de las 92 zapatas, chevrons y guardabarros (15-nov-2026)

**Implementado en `main` mediante [PR #429](https://github.com/edwinrodri12/Tarvoka/pull/429)**. Esta es la versión reconciliada con las actualizaciones simultáneas de **Bastión P06 V23** y **Base Naval V11**. Las ramas alternativas #425 y #428 se cerraron sin fusionarlas para prevenir regresiones.

**Revisión visual y mejoras reales**

- Se inspeccionaron las **16 capturas V18 auténticas** del ensamblaje anterior. El espaciado de los engranajes había mejorado, pero las zapatas seguían siendo bloques rectangulares y los guardabarros tenían extremos rígidos.
- Nuevo `scripts/ui/G11TrackFinishV19.gd`. **Reemplaza**, sin apilar, el `BoxMesh` de las 46 zapatas por lado por un **ArrayMesh de dos superficies PBR**. Primera superficie: placa metálica compacta de perfil octagonal longitudinal, con biseles reales. Segunda superficie: **cuatro grousers/chevrons extruidos por zapata**, con brillo y rugosidad diferenciados; 92×4=368 relieves. El mismo recurso se comparte en los dos `MultiMeshInstance3D`; no son 92 nodos nuevos ni 92 copias de la banda.
- **Reemplaza** las mallas de las dos `G11_Faldon_` originales por un perfil metálico taperado, conservando posiciones y los ocho pernos V18; las puntas delantera y posterior dejan de ser cajas rectangulares.
- Zapata: ancho máximo 0.274 m, longitud tangencial 0.132 m, relieves elevados 0.009 m. La holgura mínima calculada entre el relieve superior y el guardabarros es 0.0265 m. Los eslabones continúan siguiendo las dos curvas V18 sin volver a interceptar los engranajes.
- El test `tests/test_g11_track_finish_v19.gd` pasa en Godot 4.3 y recorre ocho facciones, cinco fases de marcha por lado, 46 eslabones por banda y los cuatro relieves de cada uno. Un test de ejes separadores en sección YZ comprueba que **ni siquiera al girar sobre los piñones se superpongan los perfiles 3D de zapatas vecinas**: separación superior a 18 mm, y medida teórica mínima de ~30 mm. Confirma además color V13, daños, reparación, hidráulicos, doce tubos y ausencia de piezas duplicadas.
- `tests/test_g11_track_finish_v19_capture.gd` produce **16 imágenes renderizadas directamente en Godot**: 8 perspectivas horizontales 360° cada 45°, 4 macros de los dos engranajes y dos lados, 2 instantes de marcha y 2 vistas bajas de holgura.
- En `BastionStudioAdapter.gd`: selector **«G11 Lanzador · V19 zapatas y guardabarros 3D»**, vistas ¾ y aproximaciones complementarias; los botones de V18 y el control limpio/desgaste V17 siguen disponibles. GitHub Pages copia el script V19 y conserva la interfaz P06 V23 y los demás modelos.
- El PR #425 y la posterior revalidación específica V19 terminaron con **pruebas G11 correctas**; la publicación final Pages se comprueba por separado. Los benchmarks intensivos Android siguen pospuestos hasta que se cierre el arte.

**Pendiente de aprobación:** evaluar las formas de las llantas y amortiguadores durante marcha, no declarar el G11 comercialmente acabado todavía.


## V20 — ruedas completas y muelles helicoidales articulados (15-nov-2026)

**Aprobada en Godot 4.3 y fusionada en `main` mediante [PR #431](https://github.com/edwinrodri12/Tarvoka/pull/431)**, conservando el Bastión P06 V23, la Base Naval V13 y las orugas G11 V19. La versión es geometría nativa, no una ilustración externa.

- Nuevo `scripts/ui/G11WheelSuspensionV20.gd`, instalado al final de `G11Art3D.gd` después de V19. Sustituye los **doce** recursos visuales `G11V5_LlantaEsculpida` de la malla V5 existente, no añade una segunda rueda.
- La nueva `ArrayMesh` de rueda contiene **tres superficies PBR diferenciadas**: caucho cerrado con dos hombros biselados, aro metálico con ocho nervaduras/radios tridimensionales y ranuras abiertas, y una cavidad oscura retrasada tras los radios. Cara posterior cerrada. Radio máximo sigue 0.165 m; frente 0.102 m, dorso −0.078 m en coordenadas locales de rueda. Respetamos la separación lateral de la banda V18.
- Se reducen y encajan las **12 tapas de buje existentes**; los **72 pernos** que ya existían se reubican por radio y profundidad dentro de las llantas sin duplicarlos. Los doce soportes cuadrados originales de suspensión se sustituyen por volúmenes biselados.
- Doce muelles de acero `G11V20_MuelleHelicoidal_...` construidos mediante triángulos verdaderos y ocho vueltas; cada resorte se instala como **hijo del amortiguador V5 que ya se mueve**, y lo sigue tanto durante marcha como en restauración. No introduce un segundo damper; las dos secciones telescópicas existentes siguen articulándose.
- Prueba `tests/test_g11_wheel_suspension_v20.gd`: verifica las ocho facciones, materiales, radios de rueda, separación caucho/buje/pernos, número y anclaje de muelles, sincronía de marcha y reposo, doce tubos y daño/reparación.
- Capturas `tests/test_g11_wheel_suspension_v20_capture.gd`: **16 renderizaciones reales de Godot** con seis órbitas laterales, cuatro macros de rueda, dos cámaras de amortiguadores, dos fases de marcha y dos colores de facción; artefacto `tarvoka-g11-v20-16-native-godot-roadwheel-suspension`.
- Selector del **TARVOKA Estudio 3D: «G11 Lanzador · V20 ruedas y suspensión 3D»**, con cuatro vistas nuevas para ruedas de ambos lados, muelles y bujes; conserva las vistas V18/V19 y efectos V17. El flujo Pages incluye el recurso V20 con protecciones para G11 y P06.
- QA completo del G11 V20 aprobado. **Seguimiento pendiente:** evaluar tamaño/visibilidad del muelle desde cámaras móviles y decidir si perfeccionar tornillería y óptica nocturna. No se alteraron estadísticas, costos, HP, combustible, movimiento táctico ni economía; optimización Android continúa pospuesta.



## V21 — alineación exacta de anclajes, asientos de muelle y retenes (15-nov-2026)

**Trabajo de arte nativo Godot 4.3 propuesto en [PR #434](https://github.com/edwinrodri12/Tarvoka/pull/434)**, sin alterar el balance ni añadir amortiguadores redundantes. La integración definitiva está sujeta al QA V21 y publicación de Pages.

**Defecto real detectado:** los doce soportes originales `G11V5_SoporteSuspension_` conservaban sus centros longitudinales anteriores (`z=-1.19 + eje×0.47`). Después de V18, las doce ruedas se ubican en `z=-0.875 + eje×0.35`; por tanto, hasta **0.315 m de desalineación** entre soporte y extremo superior del amortiguador en los ejes extremos. El V21 **reutiliza y recoloca los mismos doce soportes originales** a `pivot.position.z+0.115`, X=±0.730 m, Y=0.715 m, igual al cálculo del `G11MechanicsV5.update_running_gear`.

- `scripts/ui/G11ShockMountFinishV21.gd`: 24 asientos anulares de acero extruido, dos por muelle real V20, todos hijos de su amortiguador animado. Diámetro exterior 0.140 m, grosor 0.014 m, situados longitudinalmente en ±0.418 de su espacio local. El contacto con el extremo de la espira está controlado, sin apilar muelles nuevos.
- 12 retenes geométricos volumétricos (exterior 0.072 m) colocados como hijos de los doce vástagos telescópicos ya existentes; se mueven con el pistón y ayudan a resolver visualmente las uniones.
- 24 pernos de acero repartidos en dos por soporte mediante doce `MultiMeshInstance3D` pequeños; siguen los soportes ya presentes, no crean una segunda estructura portante. Refuerzo de rugosidad y metalicidad PBR de los muelles V20 ya existentes.
- El módulo se aplica al final de `G11Art3D.gd`, después de V20. La interfaz compartida `BastionStudioAdapter.gd` muestra selector **«G11 Lanzador · V21 anclajes y muelles»** y añade cuatro vistas cercanas —anclajes lado A/B, suspensión inferior A/B— manteniendo todas las inspecciones previas. La publicación Pages incluye `G11ShockMountFinishV21.gd` sin reemplazar fuentes de los otros modelos.
- `tests/test_g11_shock_mount_finish_v21.gd`: ocho colores de facción, alineación exacta de doce soportes y doce amortiguadores, dos anillos por espira, retenes, 24 pernos, jerarquía de los nodos animados, posiciones de marcha/reposo, daños, reparación y doce tubos.
- `tests/test_g11_shock_mount_finish_v21_capture.gd`: 16 capturas propias del motor Godot: seis perfiles a altura de banda, cuatro primeros planos de los asientos, dos vistas bajas de suspensión, dos instantes de marcha y dos colores de facción.
- **Alcance:** solo escultura, fijación, acabados y opciones de inspección 3D. HP, defensa, ataque, combustible, recursos, tiempo de turnos, movimiento y facciones permanecen intactos. No se ha iniciado benchmark Android.



## V23 — biseles de pasador y contraste bajo iluminación diurna/nocturna (15-nov-2026)

**Implementación real en Godot 4.3 fusionada en [PR #439](https://github.com/edwinrodri12/Tarvoka/pull/439)**, commit `ca21bbaebb546e9fdbd3672e5fa9b32af88ebf60`. QA G11 V23, galería y compatibilidad P06 V25 aprobadas antes de fusión.

- **24 ejes existentes reemplazados**, no apilados: `G11JointFinishV23.gd` sustituye cada `CylinderMesh` V22 por un `ArrayMesh` sellado con hombros mecanizados. Los antiguos cuerpos de horquilla siguen intactos, con acabado PBR forjado; el pasador metálico distingue acero pulido (metallic=0.91 y roughness=0.27) de carcasa (0.70 / 0.49).
- **48 retenes metálicos reales y huecos**, uno en cada cara de los 24 pasadores, con recurso 3D instanciado común, material separado y 24 segmentos por circunferencia. Su límite lateral estricto es `0.790+0.115+0.0257+0.0018/2=0.9316m` frente a la cara exterior `0.932m` de la banda: sin salientes ni superposiciones a través del caucho.
- Se conservan todas las animaciones del movimiento y la altura de suspensión, la estructura V22, las 92 zapatas V19, las doce ruedas V20 y las ocho pinturas; las reglas de batalla, el costo y el armamento no cambian.
- TARVOKA Estudio 3D: selector **«G11 Lanzador · V23 pasadores PBR y luz»**. Controles reales de **día**, **atardecer** y **noche técnica** con dos luces laterales colocadas en la escena, visibles solo durante la inspección G11. Botones adicionales de primer plano **«V23: inspección pasador A/B»**; el despiece reversible V22 sigue funcionando. La luz del Bastión P06 V25 se restaura al cambiar de vehículo.
- `tests/test_g11_joint_finish_v23.gd` valida ocho facciones, geometría de los 24 ejes, 48 anillos, materiales PBR y holgura, daño, reparación, disparo y cinco fases de desplazamiento. Se corrigieron las suposiciones antiguas del test V22 para que verifique la horquilla final con nuevo eje y retenes sin perder sus garantías.
- `tests/test_g11_joint_finish_v23_capture.gd`: 16 capturas **renderizadas directamente por Godot** (día, atardecer, noche, ángulos extremos, macro de la suspensión, dos poses de marcha y colores de facción). Artefacto de Actions: `tarvoka-g11-v23-16-native-godot-hinge-light-comparison`, run `43795094293`. Sin imágenes conceptuales.
- GitHub Pages incluye y comprueba el módulo `G11JointFinishV23.gd`, la selección V23 y controles de iluminación; no elimina módulos de otros edificios, unidades o del Bastión.

**Próxima prioridad:** evaluación final de la legibilidad de los pasadores a escalas menores; las mediciones físicas del rendimiento Android se reservarán para la etapa de optimización tras terminar el diseño.


## V24 — legibilidad del G11 a escala real de batalla (15-nov-2026)

**Modelo táctico real en Godot 4.3; propuesta [PR #440](https://github.com/edwinrodri12/Tarvoka/pull/440)**. No confundir con el modelo de exhibición V23; esta revisión conserva las geometrías hero y corrige únicamente LOD8/LOD10 de `G11MobileLOD.gd`.

**Error hallado en la representación utilizada en partida:** LOD10 seguía usando dos `BoxMesh` de caucho macizo, con las ruedas del mismo `MultiMesh` fuera de las caras de la oruga (centros X=±0.959 m y banda exterior ±0.925 m). A distancia media parecía un vehículo con ruedas pegadas al exterior, a pesar de que V18–V23 había corregido la escultura detallada. LOD8 conservaba dos rectángulos rígidos.

- `scripts/ui/G11TacticalReadabilityV24.gd` reemplaza las dos cajas de caucho por **dos superficies 3D reales y compartidas por lado** con puntas semicirculares. LOD10 utiliza trayectoria de bandas con **agujero real en el centro** (sin simularlo con textura) para mostrar las mismas doce ruedas existentes y **ninguna rueda adicional**. LOD8 emplea una cápsula cerrada sin doce ruedas ocultas, preservando reconocimiento visual a mayor distancia.
- Parámetros LOD10: centros de goma X=±0.790 m, mitad de ancho 0.145 m, cara exterior X=±0.935 m; centros de ruedas X=±0.912 m, ancho físico 0.044 m, cara visible exterior X=±0.934 m: margen lateral nominal de **1 mm dentro del caucho**. Radio de rueda 0.160 m y apertura interior de goma de radio 0.184 m; seis ruedas por lado espaciadas 0.40 m de Z=-1.00 a +1.00 m.
- El guardabarros de cada lado es **el mismo mesh original** con altura/reposicionamiento corregidos, holgura vertical nominal 0.023 m sobre la banda: no se añade un segundo escudo. Se reajustan las dos mismas bandas de pintura de facción a la cara exterior del metal.
- Reutilización del mismo `ArrayMesh` para ambas orugas y el mismo `MultiMesh` de 12 ruedas para LOD10; **no aumenta la cantidad de instancias de malla ni draw calls**, según el test de inspección de `Models.inspect_meshes`. Se preserva el lote único de 12 tubos lanzacohetes y la animación de giro.
- Material de caucho oscuro, rugoso, de doble cara para que la abertura interior sea visible en perspectivas en ¾ sin desaparecer por `backface culling`. El G11 hero V23 sigue sin ninguna mutación.
- `BastionStudioAdapter.gd` ofrece tres nuevos botones: **«V24: escala juego cercana»**, **«V24: escala juego lejana»** y **«V24: volver a escultura 3D»**. El cambio construye la misma unidad que usa el juego para LOD10/LOD8, no una imagen. Al tocar controles artísticos del hero, restaura de forma segura el modelo completo.
- `tests/test_g11_tactical_readability_v24.gd` verifica ocho colores × dos LODs, ruedas recesadas y sin salientes, longitudes de malla, envolvente de las bandas, holguras del guardabarros, 12 tubos, 12 ruedas solo en LOD10, animaciones y escultura hero independiente.
- `tests/test_g11_tactical_readability_v24_capture.gd`: **16 capturas reales de Godot**, una cercana y una lejana para cada una de ocho facciones, usando cámara ortográfica y encuadres comparables a la escala de partida. No son diseños ni fotografías generadas externamente.
- El G11 V24 no modifica vida, ataques, defensa, poderes, combustible, munición, economía ni reglas. Pruebas de estrés Android completas reservadas para la fase posterior de rendimiento.

**Revisión visual:** las capturas Godot muestran el perfil redondeado de la oruga y ruedas encajadas en LOD10; LOD8 conserva lectura de la silueta y los colores de facción con menor detalle. La validación CI y el despliegue del Estudio se documentarán mediante sus ejecuciones de GitHub.


## V25 — el G11 se distingue dentro del verdadero mapa 3D con otras unidades (noviembre 2026)

**Hallazgo principal:** el visor real `scripts/ui/BattleTerrain3D.gd` seguía construyendo el lanzador con `Models.build(role,faction,false,6)`. En consecuencia, el refinamiento táctico V24 de las orugas (LOD8/LOD10) se probaba en Godot y se veía en el Estudio, **pero nunca llegaba a las unidades del mapa 3D durante una partida normal**. Esta V25 corrige esa omisión de integración, no añade una nueva versión conceptual.

- `BattleTerrain3D._make_units` ahora construye las unidades de función `mlrs` con `Models.build("mlrs",faction,false,8)` antes de consumir el cupo de ocho modelos detallados. El G11 conserva un único nodo de unidad real, dos bandas redondeadas V24 y el lote original de 12 tubos. Respeta exactamente el filtro de niebla, vida positiva, propiedad y posiciones; no lee/escribe el estado táctico.
- Nuevo `G11BattleLODControllerV25.gd` en la **escena real del visor 3D de batalla**, registrando los G11 visibles con `tarvoka_g11_tactical_readability_v24` y comprobando a 4 Hz el tamaño proyectado de su unidad. Si supera 86 píxeles usa LOD10; si baja de 64 píxeles vuelve a LOD8. El intervalo de histéresis evita parpadeo.
- `G11TacticalReadabilityV24.set_level` cambia **en el mismo nodo** la malla de dos orugas entre banda exterior cerrada y banda hueca V24. Solo cuando una unidad lejana aparece por primera vez en pantalla cercana, crea un **único MultiMesh de 12 ruedas**; las doce transformaciones se reutilizan en todos los acercamientos posteriores y desaparecen visualmente al alejar la cámara. No crea otro vehículo ni segunda banda.
- El contador de diagnóstico `render_stats.units.g11_lod` y la marca `render_stats.g11_camera_lod` permiten comprobar que el renderizador verdadero ha instanciado y registrado estos G11, sin tocar los datos de la partida.
- `G11BattleContextV25.gd`: escenario de **solo inspección** y tamaño permitido 10×8, construido mediante `BattleSession.start`, mapa sembrado `Scenarios.seeded_terrain` y la misma clase `BattleTerrain3D.build` utilizada por el juego. Muestra nueve modelos de combate (dos G11, tanques, APC P06, infantería y exploradores). Son dos bandos lógicos reales; no se inventan ocho facciones de juego. Se puede mostrar con las cuatro paletas de terreno aprobadas: temperado, nieve, cañón y costa. Los datos y guardados de partidas existentes jamás se alteran.
- El **Estudio web** muestra selector **«G11 Lanzador · V25 batalla real y biomas»** y botones para cada uno de los cuatro mapas, acercar, alejar y cerrar la escena de inspección. Restablece el hero V23 original sin apagar ni modificar los controles del Bastión P06 V25.
- `tests/test_g11_live_battle_context_v25.gd` prueba en Godot las cuatro escenas reales, un total de nueve unidades, dos G11 renderizados en cada mapa, zoom de ida y vuelta sin duplicados, estado intacto y transición de dibujo 8↔10. `tests/test_g11_live_battle_context_v25_capture.gd` genera **16 capturas auténticas de Godot**: cuatro biomas × dos bandos × dos niveles cercanos/lejanos. El reporte de GitHub contiene artefacto `tarvoka-g11-v25-16-real-mixed-unit-battles-four-biomes`.
- **Sin alterar gameplay:** recursos, producción, poderes, munición, combustible, victoria, captura, daño, turnos, mapas guardados y número de jugadores no se cambian. El proyecto 3D sigue siendo una vista de solo lectura del estado autoritativo.

**Próximo control de arte:** analizar las 16 capturas de batalla en condiciones de visibilidad real, ajustar solamente si los colores y la silueta del G11 dejan de distinguirse en bosques o nieve. Estrés Android cuantitativo queda separado de esta fase artística.


## V26 · ocho colores de facción en el contexto 3D real

La escena de comparación V25 conservaba correctamente los equipos jugables 0 y 1,
pero ignoraba el selector visual de las ocho facciones: el G11 siempre aparecía
azul frente al rojo. V26 repara esa discrepancia sin cambiar ninguna regla:
el G11 protagonista aplica **solo a sus cuatro placas de esmalte existentes**
la paleta oficial de la facción escogida y el rival muestra la siguiente
paleta aprobada en orden circular. La autoría de los equipos, los datos de
`BattleSession`, la posición, la niebla, el daño y las órdenes siguen
inalterados. Un material exclusivo por G11 impide que los recursos de
material compartidos coloreen otros vehículos o el modelo hero V23.

El mismo escenario de batalla, los cuatro biomas, las doce bocas huecas V25,
las orugas redondeadas V24 y el controlador LOD8/LOD10 siguen operando. Las
pruebas reales de Godot recorren ahora las ocho facciones, comprueban las
cuatro placas originales de cada lanzador y verifican que la propiedad
`faction` de los equipos 0 y 1 nunca se modifique.

**Límite:** es una comparación de acabados artísticos en el Estudio 3D;
no implementa batallas multijugador de ocho ejércitos ni modifica el selector
de facción de las partidas jugables.


## V27 · identificación de facción sin geometría adicional

La revisión posterior a V26 mostró que las franjas laterales en LOD8/LOD10
medían solo 74 cm de longitud y 7,5 cm de altura sobre el faldón del G11,
mientras la insignia superior medía 34 cm de ancho. El vehículo podía
confundirse entre unidades contiguas cuando se veía a distancia de juego.

`G11TacticalPaintReadabilityV27.gd` ensancha **las piezas originales**:
- En ambos laterales: longitud 188 cm × altura 8,8 cm, centradas en el
  guardabarros de 10 cm de alto, conservando el espesor anterior de 1,5 cm.
  La banda está empotrada 2,5 mm en el metal y termina dentro de los bordes.
- En el techo: insignia existente de **68 × 36 cm**, integrada con el techo
  original; no toca parabrisas, cubierta del módulo ni bocas de cohetes.
- El panel superior del lanzador sigue idéntico a V25, evitando que tape
  las doce bocas huecas. Las orugas y las doce ruedas de V24 tampoco cambian.

La misma geometría funciona en LOD8 y LOD10; no se añaden nodos, superficies,
mallas, materiales ni draw calls. Se mantienen los ocho colores V26 y la
escultura detallada hero V23 completamente separada. No se cambia ningún dato
de daño, defensa, ataque, movimiento, recursos, combustible, municiones,
niebla, turnos, IA, captura o partidas guardadas.

QA: `tests/test_g11_tactical_paint_v27.gd` verifica las ocho facciones
× dos LODs, tolerancias físicas de ambas bandas y techo, controles de
animación, conteo de geometría, bocas, orugas e integridad del modelo hero.
Las 16 capturas existentes V25 se siguen generando con la nueva pintura
táctica, para comparar visibilidad real en cuatro biomas.


## V28 · contraste de identificación dependiente del zoom real

**Problema:** después de V27 las cuatro placas pintadas originales tenían
mayor superficie, pero seguían usando exactamente el mismo sombreado cuando
el G11 ocupaba aproximadamente 40 píxeles de altura que cuando aparecía
en primer plano. En los cuatro biomas las placas distantes aún podían
perderse entre los otros vehículos.

**Solución:** `G11CameraIdentityV28.gd` se integra en el controlador de
cámara del mapa **real** `G11BattleLODControllerV25.gd`. Usa los LOD
previos y su histéresis:
- Vista lejana LOD8: conserva albedo de facción y aplica una emisión de la
  **misma tonalidad** con multiplicador suave 0,22 a las cuatro placas
  existentes (dos costados, insignia del techo y marca del módulo).
- Vista cercana LOD10: restaura las referencias originales de material
  exactamente como eran antes del refuerzo; evita halos y luces o
  indicadores falsos.
- Zoom intermedio: sigue la histéresis existente, por lo que los tonos y
  las orugas no cambian repetidamente en la frontera entre niveles.

En lugar de editar los materiales compartidos de las unidades del juego,
el acabado atenuado se obtiene una vez por modelo mediante una copia.
Se conservan los ocho tonos oficiales, el modelo hero V23, las bandas
originales V27, las doce bocas V25 y la geometría de orugas V24. No se añaden
mallas, nodos, contornos, luces de escena, marcadores ni unidades nuevas.
`G11BattleContextV25` vuelve a enlazar las nuevas paletas de V26 tras
repintar sus placas, para impedir colores desincronizados.

El Estudio 3D añade zoom intermedio a sus controles cercano/lejano.
El test `test_g11_camera_identity_v28.gd` recorre 4 biomas × 8 facciones
× 2 G11 × cinco distancias con histéresis, confirma que el caché oficial
de materiales no se alteró y que no cambiaron equipos, órdenes o estado
de partida. La captura nativa `test_g11_camera_identity_v28_capture.gd`
produce 24 imágenes de los cuatro biomas a distancias lejana, intermedia
y cercana, directamente con la cámara/renderizador de Godot 4.3.

**Alcance exclusivo:** apariencia del lanzador en partidas 3D, sin afectar
combate, visión, niebla de guerra, IA, movimiento, estadísticas, munición,
combustible, economía o guardados. El refuerzo visual nunca instancia una
unidad que el renderizador de batalla oculte por niebla.


## V29 · animación post-confirmación del G11 dentro de una batalla jugable 3D

El G11 ya tenía animación hero V8–V23, pero el mapa táctico
`Battle3DMapView` regeneraba las unidades después de ejecutar una orden
válida, perdiendo movimiento y disparo visibles. V29 integra
`G11BattleActionsV29.gd` en **el renderizador de producción**
`BattleTerrain3D` y se activa **únicamente después** de que
`Battle3DOrders.confirm` haya confirmado la orden del motor.

- Movimiento: un único G11 ya existente interpola visualmente desde
  la casilla de origen confirmada hasta su casilla final autorizada;
  tiempo de animación 0,92 s y restauración exacta del estado visual.
- Disparo: el módulo del vehículo se orienta a la casilla de ataque
  confirmada y muestra **12 destellos secuenciales**, uno por boca;
  aparece un pequeño humo residual usando solamente un lote de tres
  instancias. Se emplean dos MultiMesh nuevos solo al disparar,
  no doce meshes individuales; vida visual total 1,65 s.
- El escenario muestra exactamente las unidades autorizadas por la niebla:
  el controlador busca un modelo existente y no crea enemigos invisibles.
  Una orden rechazada, cancelada o sin G11 disponible **nunca** reproduce
  efectos ni genera daño.
- El Estudio 3D contiene botones para demostrar movimiento y salva en
  cada uno de los cuatro biomas, sin alterar el estado de la partida.
  El modelo hero V23 y sus efectos físicos complejos permanecen separados.
- Los otros G11, tanques, P06, infanterías y terrenos no se alteran.
  El efecto se reproduce sobre el modelo lógico existente, con el
  LOD8/LOD10 y pinturas V28 preservados.

Validación: `tests/test_g11_battle_actions_v29.gd` comprueba
movimiento, 12 fogonazos escalonados, dos lotes de efectos, restauración,
aislamiento de vecinos y ausencia de mutaciones de HP, economía,
munición o combustible en cuatro biomas. El script
`test_g11_battle_actions_v29_capture.gd` produce doce capturas
verdaderas de Godot: movimiento, primer disparo y humo intermedio
para cada bioma. La calidad visual y el desempeño Android real
requieren inspección adicional a partir de esas capturas y del dispositivo.

**Nota:** la acción real y el daño siguen siendo responsabilidad exclusiva
del motor de turnos; V29 no aplica órdenes ni modifica guardados.


## V30 · corrección de pieza rectangular bajo la trasera y estelas de cohetes

**Revisión geométrica localizada:** se encontró interferencia en los dos
antiguos `G11_ZapataEstabilizador_±1`: los cubos originales tenían centros
X ±0,56 m y anchura 0,38 m, por lo que sus bordes exteriores llegaban
a ±0,75 m. La pared interior de las orugas es ±(0,79−0,142)=±0,648 m.
La interferencia transversal era por tanto de **10,2 cm por lado**. La
protección inferior rectangular heredada `G11_ProteccionInferior`
tenía apenas 3 mm de holgura: esa pieza **se elimina por completo**
porque el casco octogonal cerrado de V2 ya forma un piso estanco.
El chasis móvil medía 1,45 m de ancho y también invadía la banda
interior de las orugas tácticas.

`G11RearUndercarriageV30.gd` repara **las mismas piezas**, sin duplicados:
- Zapatas traseras octogonales, biseladas y estrechadas a un máximo de
  0,27 m, reubicadas en X ±0,385 m; los soportes se centran en ±0,405 m.
- Tras comparar 30 imágenes con piezas aisladas se identificó un segundo
  cuadro redundante visible: `G11_RampaPosteriorCerrada`, que continuaba
  cubriendo la cara trasera justo entre las orugas. Se elimina **también**,
  no se oculta con materiales ni se sustituye por otro rectángulo.
- La vieja `G11_ProteccionInferior` se **suprime del árbol de escena**,
  evitando el rectángulo colgante y el duplicado de geometría bajo la
  trasera. Se conserva `G11V2_CascoOctogonalCerrado` y su suelo sellado.
  Los seis cierres originales del portón se vuelven a fijar a z≈1,4 m
  sobre la cara octogonal real, sin dejar tornillos flotantes.
  Los soportes dejan al menos 0,128 m de
  separación interna respecto de las orugas hero.
- Chasis de batalla (`ChasisLanzacohetes`) deja de ser un cubo completo:
  se sustituye por un perfil de ocho lados con el extremo trasero afinado,
  de medio ancho máximo 0,620 m y al menos 0,025 m de separación interna.
- La posición de las ruedas, piñones, zapatas, suspensión, pinturas,
  edificios, daños y las ocho facciones no cambian.
- Se eliminan **dos** placas redundantes y se reajustan cuatro
  estabilizadores y seis cierres de portón existentes en hero.
  Se sustituye una geometría en móvil LOD8/LOD10.
  **Cero nodos nuevos y las dos placas cuadradas realmente retiradas**.

**Siguiente prioridad artística:** `G11RocketTrailsV30.gd` conecta
trayectorias cortas de cohetes con los doce fogonazos escalonados de V29.
Solo permanecen activos hasta cinco cuerpos y cinco estelas en dos
`MultiMesh` reutilizables. Los cohetes salen de los tubos ya aprobados,
describen una trayectoria local ascendente y desaparecen; **no son
proyectiles de combate**, no buscan ni revelan unidades y no afectan
HP, munición, impacto o visibilidad.

**Validación:** `tests/test_g11_rear_rocket_v30.gd` revisa los ocho
colores de facción en el modelo hero y los 16 modelos tácticos, las
holguras geométricas y los cuatro biomas. La prueba de capturas genera
12 vistas inferiores-traseras del hero/LOD8/LOD10 y cuatro salvas con
el mapa real. La integración se hace por `G11Art3D.gd`,
`G11MobileLOD.gd` y `G11BattleActionsV29.gd`, no en las estadísticas.


## V31 · cohetes esculpidos, humo gradual y retroceso discreto

Tras estabilizar las dos placas traseras eliminadas en V30, el objetivo
prioritario pasa a la **identificación visual de la salva de doce cohetes**.
En la V30, el proyectil era una esfera emisiva: difícil de reconocer
como un cohete a la distancia normal de las partidas.

- `G11RocketFlightV31.gd` crea un único `ArrayMesh` con un cuerpo
  cilíndrico longitudinal, punta afinada, cola cerrada y cuatro aletas
  traseras. No aparece una malla individual por disparo: los cinco
  proyectiles simultáneos usan el `MultiMesh` original de V30.
- El segundo lote existente (cinco instancias) ahora usa humo semitransparente
  que **se ensancha, se desplaza y pierde opacidad** durante 0,39 segundos
  por cohete. La niebla táctica y la visión del jugador no se modifican.
- El módulo original recibe un máximo de **2,2 cm** de retroceso puramente
  visual por disparo y vuelve a su posición anterior al acabar la salva.
  El casco, la casilla, las ruedas, los tanques vecinos, los datos de
  combustible y el daño permanecen exactamente iguales.
- El calendario de doce bocas V29, sus fogonazos existentes y los cambios
  de geometría V30 se conservan. Cero nuevos nodos de efectos 3D y dos
  llamadas de dibujo como máximo para cabeza y estela, igual que V30.
- El Estudio 3D permite comparar la nueva salva en cuatro biomas. Los
  tests `test_g11_rocket_flight_v31.gd` y
  `test_g11_rocket_flight_v31_capture.gd` prueban el mismo lanzador de
  batalla de Godot, sin alterar el motor de órdenes, y generan doce
  capturas originales (primer disparo, fase intermedia, fase final).
