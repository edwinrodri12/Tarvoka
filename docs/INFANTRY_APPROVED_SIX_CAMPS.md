# TARVOKA — infantería aprobada: seis unidades y cuatro campamentos

Corrección del usuario al catálogo erróneo de once unidades. **Solo existen seis identidades principales definidas para esta familia:** Guardia básica, Comando de Operaciones Especiales y cuatro especialistas exclusivos de campamentos. No confundir variantes artísticas antiguas ni el vehículo G16 con nuevos soldados.

| Unidad principal | Campamento exclusivo | Regla discutida |
| --- | --- | --- |
| Guardia · infantería básica | Ninguno | Soldado de dotación |
| Comando de Operaciones Especiales (FS-24) | Ninguno | Unidad especial |
| Francotirador | Reconocimiento | Permite información/visión; daño mínimo o nulo a vehículos |
| Ingeniero | Defensivo | Fortifica; reparaciones de vehículos cuestan créditos |
| Logístico de infantería | Suministros | Reabastecimiento solo para unidad que ocupa la casilla |
| Médico de combate | Médico | Curación de infantería que ocupa la casilla, no vehículos |

**Los campamentos son cuatro y solamente esos cuatro.** Cada uno tiene un especialista constructor y se mantiene la regla de ocupación de Suministros/Médico; Reconocimiento da visión sin exigir ocupación. La definición de datos de arte y el visualizador NO activan campamentos ni reescriben reglas de partida: implementación táctica separada y validable.

El visor online de TARVOKA conserva el mismo SubViewport y todos los modelos anteriores. La pestaña Cámara añade un selector explícito de **6 unidades aprobadas** para inspeccionarlas en el mismo motor, con facciones, comparación V1/V2, LOD13/8 y giros. Los experimentos anteriores Guardia urbana, Guardia defensiva, Rastreador y Rompedor permanecen como **bocetos heredados**, no como otras cuatro tropas principales.

**QA exigido antes de fusionar:** validación de asignaciones 6/4, materiales/esculturas nativos y catálogo de 10 modelos existentes (seis oficiales + cuatro bocetos antiguos), todas las ocho facciones, ambos LOD y prueba de la escena real. Los cuatro nuevos perfiles reciben esculturas físicas únicas en `InfantryVariantsV4.gd`; el Ingeniero y Guardia reutilizan su trabajo actual. No prometer publicación sin exportación satisfactoria.

## Prioridad artística V5 — Ingeniero claramente distinto de Guardia

El Ingeniero conserva su rol exclusivo de campamento defensivo. En el **mismo Estudio 3D** añade una barrera defensiva plegada y fijada a la mochila (no desplegada ni activa en combate), un arnés frontal de construcción y una visera robusta; el color de facción se mantiene exacto y opaco en ocho facciones. A LOD8 se conservan las formas principales que lo distinguen; LOD13 añade herrajes y fundas. No añade clases, no cambia reparación/captura/campamentos ni usa iconos 2D. La QA de la familia comprueba 8 facciones × 2 LOD, piezas visibles, barrera ancha y que la Guardia no reciba equipamiento de Ingeniero.

## V6 — Articulación 360°, acabados y animaciones (en revisión)

El Ingeniero mantiene exactamente el mismo rol de campamento defensivo y las seis identidades oficiales. Se conserva la geometría de referencia V5, pero se oculta su barrera estática al activar V6, que dibuja una barrera plegable real bajo `V6_BarreraArticuladaRig`: acero satinado opaco, junta de goma, cinchas de sujeción, rieles, pernos y dos alas abatibles. La banda de facción es material Godot nativo y usa una de las ocho pinturas oficiales sin cambiar saturaciones. El LOD13 lleva herrajes y herramientas extra; LOD8 conserva panel, alas, franjas y volumen.

En **el mismo TARVOKA Estudio 3D** se añaden dos botones de animación exclusivos del Ingeniero: **Abrir barrera para inspección 360°** y **Plegar y guardar**. El trabajo de construcción existente mueve una herramienta física en el rig nativo; D2 y D3 revelan marcas reales sobre el metal. Girar la cámara, detener una animación, cambiar facción o comparar LOD no crea un segundo visor. **Todas estas animaciones son artísticas**: no despliegan campamentos, no añaden cobertura, escudo ni defensa y no alteran balance, colisiones, IA, recursos o reglas tácticas.

Cierre técnico requerido: prueba Godot de 8 facciones × 2 LOD, cuatro orientaciones de cámara, diez capturas reales, movimiento de bisagras y herramienta, D0–D3, inventario de Animar del visor unificado y exportación de Pages. El Ingeniero permanece en revisión artística hasta la inspección visual final.

## Ingeniero V7–V8 · corrección de partes incompletas y acabado de calidad (revisión)

El error visible en el render nativo V6 era la cabeza descubierta por detrás. V7 sustituye exclusivamente en Ingeniero la cabeza prototipo por casco posterior y nuca sellados, máscara y visor, con juntas anatómicas de hombros, botas y rodillas y el mismo rig de animación.

**V8** aborda las partes que aún parecían bloques separados en capturas V7: las hombreras cúbicas se ocultan y se reconstruyen como volumen curvo unido a cada brazo, la protección delantera es biselada, el rifle incorpora receptor cerrado, guardamanos ventilado, agarre, riel óptico y elementos mecanizados; la barrera plegada incorpora panel facetado y alas biseladas con bandas de facción. La bisagra y las alas permanecen completamente articuladas con V6, con sujeciones fijas al cuerpo y sin saltos al invertir la animación. La pintura respeta las ocho facciones; LOD8 conserva silueta de hombros, escudo y arma con menor densidad, y LOD13 añade refuerzos y herrajes. Las placas se generan con mallas **sólidas y cerradas**, no planos transparentes.

La comprobación visual cuenta con **18 PNG nativos de Godot**, incluidos primeros planos frontales y de perfil de armas/hombros, casco posterior y placas dorsales, junto con la prueba del mismo visor web de TARVOKA. Los cambios son únicamente artísticos: no afectan a cobertura, unidades de combate, balance, daño real, campamentos, guardados ni sistemas tácticos. No se declara aprobación estética definitiva hasta inspeccionar las nuevas capturas de V8.

## Ingeniero V9 · casco continuo, manos ancladas y equipo dorsal (arte en QA)

**Problemas de V8 detectados al inspeccionar 20 capturas nativas:** casco construido con múltiples volúmenes apilados, manos que no siempre contactaban el fusil y accesorios dorsales con poca sensación de sujeción física.

La V9 conserva la **clase Ingeniero** y la silueta de construcción V5: no elimina la visera de clase ni su color, ni crea roles ni campamentos nuevos. Sustituye exclusivamente el casco prototipo V2 por una superficie propia, maciza, triangulada y cerrada en 360° que se integra con la nuca y cuello V7. Mantiene materiales PBR opacos y detalles extra en LOD13, con geometría simplificada en LOD8.

Las dos manos tienen mallas **realmente unidas a los puntos de empuñadura del ArmamentoRig**. Un manguito flexible desde cada antebrazo se recalcula tras cada animación nativa; en `work/repair/capture` la mano derecha pasa físicamente al `V6_HerramientaArticuladaRig`, conservando el rifle en la izquierda. Esto se limita a pose visual, no modifica reglas de interacción o disparo.

El arnés y bolsas de herramientas están anclados al `TorsoRig`, separados de `V6_BarreraArticuladaRig`. El panel sigue abriendo, plegando y girando sin arrastrar el equipo fijo.

**Contrato QA**: ocho facciones, LOD8/13, malla del casco cerrada, visera V5 visible, ambas manos tocando sus grips y articulaciones verificables durante `idle/move/aim/attack/work`, comprobación de mano en herramienta, equipo dorsal fijo, pintura de facción, no regresión de V6-V8, 26 imágenes reales de Godot con primeros planos V9 (casco frente/espalda, agarres frente/perfil, mochila y herramienta). En el Estudio 3D web debe aparecer el mismo modelo y sincronizarse durante las animaciones.

## Ingeniero V10 · continuidad anatómica y dedos de herramienta (revisión nativa)

En las 26 capturas Godot de V9 se detectó un problema real: el guante derecho pasaba al `V6_HerramientaArticuladaRig` durante `work`, pero sus tres dedos secundarios continuaban visibles en el fusil. V10 corrige **los cuatro elementos como conjunto**: el guante y sus tres dedos desaparecen del arma y reaparecen en la herramienta; al volver a `idle/aim/attack`, regresan al arma. El lado izquierdo conserva su apoyo en el guardamanos. Esto no altera armas, daño, munición ni mecánicas.

Se adelgazan geométricamente los conectores en ambos antebrazos (radio del cilindro afilado de 0.050 a 0.071 frente a 0.086–0.113), se reducen ligeramente hombreras y se añaden codos cerrados, muñequeras y carenados orgánicos del costado. Todo permanece conectado a los `BrazoRig`, al `ArmamentoRig`, al `TorsoRig` y al `V6_HerramientaArticuladaRig`, respectivamente, tanto en LOD8 como LOD13.

**Criterios QA:** 8 facciones × LOD8/13, tubos realmente afilados (no solo texturas), contornos y codos sin superficies transparentes, secuencias `idle, move, aim, attack, work` sin dedos duplicados, restauración correcta, integridad de V6–V9, 28 capturas reales de Godot y prueba del mismo Estudio Web. Se mantiene como revisión hasta verificar resultados y material visual, no se da por terminado automáticamente.

## Ingeniero V11 · torso esculpido, caderas y bisagras concéntricas (arte 3D)

Se conserva V10 aprobado en el juego y se mejora una zona todavía demasiado geométrica: abdomen, uniones de hombros/caderas y anclajes de la barrera posterior. V11 agrega una coraza inferior prensada **con volumen real**, centro convexo, ocho esquinas biseladas, cara posterior y paredes laterales completamente cerradas. El escudo de facción superior V8 sigue visible; una segunda franja pequeña en el abdomen usa exactamente el color activo de cada una de las ocho facciones. Las costillas laterales son placas cerradas, no calcomanías.

Los cojinetes de las caderas están anclados al `CaderaRig` y los sellos femorales al `PiernaRig`; las transiciones de hombros siguen al `BrazoRig` sin alterar su movimiento, el agarre del fusil ni la herramienta V10.

La barrera V6 conserva su articulación original y sus ocho colores. Para eliminar el aspecto de piezas que flotan, V11 usa un **casquillo fijo sobre `TorsoRig`** y un **eje giratorio separado en `V6_BarreraArticuladaRig`**. Ambos están situados exactamente sobre el eje de giro, de modo que permanecen coaxiales con la barrera plegada, abierta o en transición. Los pernos secundarios siguen el `V6_AlaIzquierdaRig` y el `V6_AlaDerechaRig` de forma independiente. No hay cambios en defensa, cobertura, construcción de campamentos o colisiones.

**QA obligatoria antes de integrar:** ocho facciones × LOD8/LOD13, mallas ArrayMesh de torso y costados watertight, materiales totalmente opacos, geometría de color exactamente coincidente con la facción, soportes fijos y móviles en el rig correcto, desviación del eje menor que 0.00001 unidades en cuatro aperturas (0%,25%,50%,100%), insignia y animaciones V5-V10 intactas, seis nuevas fotografías auténticas de Godot hasta 34 totales, y prueba de las mismas piezas y etiquetas V11 dentro del Estudio 3D web unificado.


## Ingeniero V12 — acabado dorsal y coraza exterior (en revisión)

- Capa artística aditiva `InfantryEngineerDorsalV12.gd` sobre la geometría V11, sin cambiar unidades ni estadísticas, ataques, captura, campamentos, construcción, IA o guardado.
- Dos estuches de herramientas **con volumen 3D redondeado**, sobre soportes anclados al `TorsoRig`; reemplazan visualmente las bolsas V9 cuadradas y pueden recuperarse con el comparador V11/V12.
- Dos chapas octogonales **cerradas por todos los lados**, con relieve, franja PBR opaca del color exacto de las ocho facciones y nervaduras exteriores en el escudo V6 móvil. Remaches y costuras extra solo en LOD13; LOD8 conserva silueta y colores.
- Dos botones nuevos para comparar V11/V12 en el **mismo** `BastionStudioAdapter` y `SubViewport`. Reusar los controles existentes de 360°, barrera, 8 facciones, daños D0–D4 y LOD8/13.
- QA nativo dedicado `tests/test_infantry_engineer_v12_finish.gd`: 16 combinaciones de facción/LOD, mallas herméticas y opacas, rig correcto, comparación reversible, otras cinco tropas sin cambios y seis capturas reales Godot. CI nativa y publicador Pages ajustados para copiar la nueva dependencia.
- **Estado**: revisión de arte y CI pendientes; mantener PR en borrador y no presentar el visor público, APK o integración en `main` como completados sin comprobar ejecuciones y renders auténticos.

### Revisión visual V12.1 — 22 noviembre 2026

Se analizaron las seis fotografías Godot originales de V12 frente a las seis capturas V11. La silueta dorsal conservaba un rectángulo demasiado evidente y los estuches laterales parecían óvalos superpuestos. Se sustituyó la envolvente por una placa central **octagonal biselada y hermética** sobre el mismo rig V6, y se formaron estuches con **cinco secciones geométricas 3D cerradas** y tapas metálicas; nuevos paneles laterales PBR grandes usan el color auténtico de cada facción. La comparación V11/V12 sigue siendo reversible, y los controles LOD8/LOD13, giro, animación, color, combate y campamentos no cambian.

La prueba dedicada se amplió a **ocho capturas Godot**, incluyendo V11 y V12 desde la **misma cámara** y una facción adicional, además de verificar que las superficies nuevas no tienen bordes abiertos. Esta revisión no está aprobada para publicar hasta comprobar el nuevo CI y sus imágenes.

### G05 Ingeniero jugable — puente visual del combate 3D (PR independiente)

Se comprobó un hueco entre el arte del Estudio y el mapa real: `ModernArsenal.gd` y `UnitRoles.gd` usan el identificador jugable **`engineer` (G05)**, mientras que el constructor 3D lo cataloga como **`infantry_engineer`**. Antes, `BattleTerrain3D.gd` no encontraba un modelo para G05 y lo representaba como disco genérico.

El nuevo puente en `BattleTerrain3D.gd` asigna exclusivamente en la capa visual `engineer → infantry_engineer` y construye el mismo V12.2 con **LOD8**, aprovechando la identidad visual seleccionada entre las ocho facciones. La unidad sigue teniendo `role=engineer`, equipo y equipo táctico 0/1 intactos, sus estadísticas/costo/perfil/captura/niebla y guardado no se modifican. El mapa conserva su tope `MAX_DETAILED_UNITS=8`: no se generan soldados de alta geometría adicionales fuera del presupuesto.

`tests/test_engineer_v12_live_battle.gd` comprueba la unidad G05 jugable dentro del terreno Godot auténtico, materiales/rig V12.2, su facción visible, visibilidad de enemigos, límites de rendimiento y que el estado de la partida no cambia; captura además un PNG 3D del G05 sobre el mapa. **Validación de esta nueva integración pendiente de su workflow dedicado**; no equiparar al resultado anterior del visor ni afirmar APK publicada.

### Ingeniero V12.3 — corrección de huecos y falso efecto de transparencia (22 noviembre 2026)

**Reporte del usuario:** en el Estudio 3D el Ingeniero parecía parcialmente transparente y hueco incluso después del acabado V12.2. No se considera el modelo visualmente aprobado hasta que el propio usuario lo pueda inspeccionar sin esas fallas.

**Reparación física en el modelo fuente (no solo material doble cara):** `InfantryEngineerDorsalV12.gd` añade 15 sólidos cerrados, unidos a las articulaciones originales: casco interior, respaldo del visor opaco, cuello, tórax y cintura; además, ambos hombros interiores, puentes de antebrazo, uniones cadera-muslo, transiciones a las botas y cantos del escudo articulado. Son modelos reales `SphereMesh` herméticos y se ocultan/activan solamente a través de la comparativa `V12.2 / V12.3`. Sus materiales exigen alpha=1, `TRANSPARENCY_DISABLED` y `CULL_BACK`, en lugar de usar `CULL_DISABLED` para disimular huecos. No se alteran los módulos existentes de escudo, bisagras, mascarilla, armas, facciones ni las poses de la unidad.

**QA obligatoria en Godot real:** `tests/test_engineer_v123_opaque_closure.gd` comprueba las ocho facciones en LOD8 y LOD13, el anclaje correcto a `CabezaRig`, `TorsoRig`, `BrazoRig`, `PiernaRig` y `V6_BarreraArticuladaRig`; opacidad total de todas las nuevas piezas; que los `ArrayMesh` de V9, V11 y V12 sean herméticos y tengan volumen firmado exterior; y diez fotografías 3D en cinco cámaras iguales **con y sin el sellado**. `test_infantry_studio_v2_review.gd` valida el nuevo comparador dentro del Estudio web original; `test_engineer_v12_live_battle.gd` asegura el mismo modelo físico en G05 LOD8 jugable. Los registros de CI y las imágenes deben revisarse antes de integrar.

**Alcance estricto:** arte 3D solamente; sin cambios en balance, economía, capturas, daño lógico, IA, guardados, niebla, rutas o facciones.


### Ingeniero V13 — superficies curvadas y normales suaves (23 noviembre 2026)

El usuario revisó V12.3 en el visor y señaló que la silueta seguía excesivamente poligonal. La reparación de huecos y el suavizado son problemas distintos: V12.3 aporta volúmenes opacos; V13 mejora la **curvatura auténtica de las mallas** sin volver a abrirlas.

**Código nuevo:** `scripts/ui/InfantryEngineerSmoothV13.gd` se aplica después de `InfantryEngineerDorsalV12.gd` exclusivamente en `infantry_engineer` (y por tanto en el G05 jugable mediante el puente visual existente). Sustituye el `ArrayMesh` de placas octogonales rígidas por un panel **redondeado y totalmente cerrado**, con contorno de arcos, bisel físico y normales calculadas para superficies curvas. Refina el casco, la mochila, los estuches dorsales y los cuerpos de brazos y piernas con perfiles interpolados y normales suaves. Refina también `SphereMesh` de articulaciones sin cambiar materiales o transforms.

**Detalle recuperado en V13:** la revisión visual de los diez PNG de Godot confirmó que el nuevo panel era más suave, pero demasiado liso. Para recuperar profundidad sin abrir huecos, V13 añade **cuatro biseles metálicos redondeados y cerrados** por encima de la coraza física, detrás de las franjas y las dos insignias existentes. Se limitan al LOD13 y desaparecen al alternar la comparación V12.3/V13. No se agrega geometría extra a la versión táctica LOD8.

**Presupuesto Android:** los perímetros usan menos subdivisiones en LOD8 que en LOD13; las superficies no añaden nuevos `MeshInstance3D`, sino que reemplazan datos de malla de las piezas ya existentes. Se conserva el límite de ocho soldados detallados en el mapa de batalla y los modelos no ingenieros permanecen intactos. La nueva comparativa `V12.3 · poligonal / V13 · curvas suaves` del Estudio 3D restaura recursos de malla reales **sobre la misma cámara y esqueleto**, no imágenes simuladas.

**QA exigida antes de publicar:** `tests/test_engineer_v13_smooth_finish.gd` comprueba las ocho facciones × LOD8/13, normales explícitas, cierres de malla, volumen exterior, rig y escudo móvil sin regresiones, ausencia de transparencias, diez imágenes de Godot de cinco vistas con y sin suavizado, además de las pruebas de batalla y de interfaz. No se modifican atributos, reglas de combate, IA, economía, capturas, guardados ni colisiones.

**Estado:** trabajo en revisión; no confundir con una versión ya desplegada en GitHub Pages o una APK compilada.


### Ingeniero V14 — proporciones anatómicas, hombros y cuello

**Prioridad tras V13:** reducir la apariencia de hombreras esféricas, mejorar la unión entre casco, cuello y torso, conservar la identidad del Ingeniero y evitar superficies poligonales visibles. La nueva intervención es sobre **mallas auténticas de los nodos existentes**, no una ilustración ni el cambio de un material de doble cara.

`scripts/ui/InfantryEngineerContourV14.gd` reconstruye el casco V9 con una corona de perfil anatómico y normales suaves, reemplaza la hombrera esférica V8 por una cápsula deltoidea cónica cerrada, redondea de verdad el peto rígido frontal V8 y corrige el ajuste entre cuello V9 y sello interno V12.3. Los rellenos de axila y las uniones móviles de hombro permanecen dentro del torso/rig de brazos original, sin cambiar pivotes, manos, armas, transformaciones de combate o tamaño de colisiones. El color de cada facción sigue usando los mismos materiales.

Se utiliza la función de contorneado hermético de V13; los nuevos nodos de geometría son **cero**, porque se sustituyen solamente `mesh`, `scale` y `position` de las piezas existentes. Los perfiles LOD8 y LOD13 retienen su presupuesto original. El visor compartido añade una comparación física **V13 · proporciones previas / V14 · anatomía refinada**, guardando mallas y transformaciones anteriores del mismo modelo y cámara.

**QA requerida antes de fusionar:** `tests/test_engineer_v14_anatomic_finish.gd` comprueba 8 facciones × 2 LODs, volúmenes sellados de casco/hombreras/peto, 10 imágenes de cinco ángulos, anclajes de armadura en sus propios rigs, conservación del tope de unidades detalladas y reversibilidad V13/V14. Deben pasar el Godot nativo, humo de interfaz, mapa táctico G05 y exportación web. **No está aprobada ni publicada hasta verificar CI y fotos**; sin modificaciones a jugabilidad ni a una APK existente.


### Ingeniero V15 — equipo y fusil con superficies curvas

Tras la integración y revisión visual de V14, el principal aspecto restante excesivamente cuadrado se concentra en el **fusil técnico, el guardamanos, las correas y las aristas del equipo dorsal**. V15 sustituye las mallas de esas partes por volúmenes físicos cerrados con bordes redondeados usando el constructor hermético V13, sin superponer geometría.

**Alcance:** `scripts/ui/InfantryEngineerGearV15.gd` reconstruye con mallas originales `ArrayMesh` la carcasa y guardamanos del fusil V8, riel óptico, empuñadura, apoyo de mano, arnés de construcción V5, bancada trasera de bisagra V6 y cuatro accesorios laterales por lado (correas, cierres de caucho, escuadras). En LOD13, dos pequeños detalles por lado reciben el mismo tratamiento; LOD8 no recibe esos triángulos adicionales. La función es exclusivamente visual y preserva nombre, material opaco, transform, padre del rig, pose de escudo y archivos de juego. No añade nuevos `MeshInstance3D` ni draw calls.

**Reversibilidad:** el mismo visor Godot muestra una comparación `V14 · equipo previo / V15 · equipo redondeado` intercambiando la malla real original, sin crear otro modelo ni cambiar la cámara. El G05 jugable utiliza V15 LOD8 directamente a través de `UnitModels3D.gd`.

**QA obligatoria:** `tests/test_engineer_v15_rounded_gear.gd` comprueba 8 facciones × LOD8/13, cadenas V12–V15 cargadas, materiales opacos, cero nodos añadidos, articulación del escudo, cinco modelos de infantería no modificados y diez capturas de Godot comparando cinco ángulos idénticos. Mantener en revisión hasta confirmar CI nativa, web y fotos; no afirmar actualización de APK ni publicación en Pages antes de comprobarla.


### Ingeniero V16 — silueta corporal completa (23 noviembre 2026)

**Nueva prioridad tras V15:** el Ingeniero se veía como una colección de piezas redondeadas en vez de tener una anatomía unificada. `scripts/ui/InfantryEngineerSilhouetteV16.gd` es una nueva pasada de escultura **sobre las mallas reales existentes**, posterior a V15, que sustituye la forma genérica del tronco `PetoBase` y la cadera `CinturaEquipo` por cuerpos cerrados de perfiles interpolados, con pecho más amplio, transición real a una cintura más estrecha y pelvis solapada físicamente con el torso. Rediseña las mallas de muslos, pantorrillas y botas de ambas piernas para crear volúmenes anatómicos continuos. Ajusta las rodilleras y pantorrillas de V8 manteniendo las uniones opacas originales de V12.3.

**Mismo rendimiento y movimientos:** `TorsoRig`, `CaderaRig`, ambos `PiernaRig`, ambos `BrazoRig`, cabeza, fusil y escudo conservan sus pivotes, escalas de hitbox y estado de gameplay. No se añaden objetos 3D, colliders, materiales, lógica de juego ni draw calls. Los perfiles siguen las subdivisiones `LOD8/LOD13` de V13. El equipo V15, la pintura de facciones, las poses y las uniones selladas V12.3 permanecen intactos.

**Comparación real en el Estudio:** los botones `V15 · silueta previa / V16 · anatomía integral` alternan la malla y transformación verdaderas de las piezas, desde la misma cámara del único visor de Godot. `test_engineer_v16_silhouette.gd` valida topología cerrada/orientación de superficies, ocho facciones × LOD8/13, cero nuevos MeshInstance3D, las poses del escudo, cinco otros tipos de infantería intactos y diez capturas Godot de cinco cámaras antes/después. El test de batalla G05 confirma este cuerpo real en LOD8 y preserva reglas/niebla.

**Estado:** esperando CI, exportación y revisión visual; no considerar V16 finalizada, publicada en Pages ni instalada en un APK hasta que se confirme.


### Ingeniero V17 — coraza exterior anatómica

**Prioridad visual después de V16:** el remodelado anatómico de torso/pelvis/piernas pasó QA, pero las placas exteriores anteriores cubrían casi toda la nueva silueta y el soldado aún se veía como piezas aisladas. V17 reemplaza la **geometría exterior verdadera** en los nodos V8 y V1 existentes; no se limita a modificar normales o añadir superposiciones.

**Escultura nueva:** `scripts/ui/InfantryEngineerOuterArmorV17.gd` construye un peto tridimensional cerrado de sección variable, ancho en el pecho y más estrecho al bajar al abdomen; reajusta la insignia original a la superficie frontal conservando el material y color de la facción. Las hombreras V8 pasan a ser cascos deltoideos mayores, cerrados y continuos desde la raíz hasta el bíceps, y sus insignias se desplazan a la superficie exterior. Sustituye las antiguas cajas `Rodillera`, `BolsilloPierna` y `V2_Suela` por volúmenes cerrados con contorno curvo, manteniendo las cinchas y los sellos internos V12.3. Las marcas tácticas de rodilla de LOD8 se recolocan fuera del nuevo blindaje. **No crea nuevos nodos de malla ni draw calls**.

**Integración:** sobre la cadena V12.3→V13→V14→V15→V16, `UnitModels3D.gd` activa V17 en el Ingeniero G05 jugable y en el Estudio 3D nativo. `BastionStudioAdapter.gd` añade comparación reversible `V16 · coraza anterior / V17 · blindaje anatómico` sobre las mallas originales, conservando los anteriores comparadores y las animaciones del escudo y del arma. Las reglas, daño, capturas, IA, materiales de facción, colisiones y estadísticas no cambian.

**Puertas de calidad:** `tests/test_engineer_v17_outer_armor.gd` valida 8 facciones × LOD8 y LOD13, topología hermética/orientación de normales, posición de los indicadores de facción, articulaciones, ausencia de nuevos nodos y diez imágenes renderizadas por Godot desde cinco cámaras antes/después. Además se exigen CI del G05 en mapa, UI y exportación web del Estudio compartido. Hasta pasar esas verificaciones y revisar las capturas, V17 queda en revisión, sin publicación ni APK.
