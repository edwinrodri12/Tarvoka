# Infantería V5 — anatomía de cinco identidades oficiales

Candidato basado en 06dc4a9d1a01a4aa4d9ef3c18c5653af3ca3bf72. No aprobado ni publicado.

Evidencia inicial: capturas nativas del run 45684230042. Se esculpen torso, pelvis, hombreras, mangas, antebrazos, rodilleras y botas existentes en Guardia, FS-24, Francotirador, Logístico y Médico; se redondean kits físicos de especialistas. Sin nuevos nodos de malla ni cambios a pivotes o reglas. G05 y cuatro bocetos históricos excluidos. La suite comprueba 160 combinaciones y exige 53 capturas nativas, incluidas 15 nuevas de detalle. Pendientes: ejecución de Godot, inspección de imágenes, WebGL, verificación de contacto en poses y revisión individual de casco y equipo. El despliegue G05 sigue pendiente en el run 45686050361.

## Segunda prioridad: contactos articulados

Reutiliza guantes, dedos y antebrazos existentes, con las manos fijadas al rig del equipo y extremos de antebrazo calculados después de cada pose. QA de contacto exacto en seis animaciones y cuatro fases, ambas manos, 80 combinaciones de facción/LOD/rol (3.840 comprobaciones de contacto) y restauración. Destellos visuales del Francotirador y FS-24 ajustados a sus mallas. No se incorporan herramientas especiales nuevas: las poses de trabajo específicas de médico y logístico quedan para revisión individual. Pendiente ejecución nativa, no aprobado.

## V6 — identidad individual y herramientas de servicio

Casco cerrado con perfil, color de armadura neutro y coraza ajustados por rol; visor opaco curvo y cuello sellado. No se cambia pintura de facción. Médico y Logístico: prop físico de servicio bajo TorsoRig, visible solo durante la fase de trabajo; la mano derecha y sus dedos se transfieren al accesorio y vuelven al equipo en reposo. Sin nueva lógica de curación o suministro. Cinco enlaces directos permitidos y etiqueta V6 basada en metadatos reales del modelo en el mismo Studio. QA exige 60 PNG, incluidas 5 vistas de casco y 2 de servicio; comprueba cambio reversible de manos y visibilidad. No fusionar hasta validar los renders reales.

## V7 — materiales y desgaste persistente

Tres texturas procedurales compartidas de 64×64 solo en detalle LOD13; LOD8 sin texturas nuevas. Materiales opacos diferenciados de tejido, cerámica y goma, sin repintar emblemas. Cinco estados D0-D4 alteran únicamente materiales existentes, con restauración exacta de D0 y reutilización de marcas físicas. D4 inhibe destellos y casquillos; recupera inclinación del modelo tras reparación. 70 capturas reales exigidas (10 nuevas D2/D4) y pruebas de materiales y restauración en cada facción/LOD. Sin modificación de reglas ni de G05 V17. Pendiente CI nativa y revisión.

## V8 — correcciones derivadas de la inspección real

V7 `3923a09`: 22 workflows exitosos, incluida QA nativa 45689803274 (artefacto 15061330442) y WebGL 45689803084. Se inspeccionaron 20 capturas de frente, perfil, casco y espalda, más 10 D2/D4. Hallazgos: mejillas redondas aisladas, ceja rectangular, hebillas en la puntera, Guardia descentrado por offset del antiguo proxy y D4 en el borde del encuadre. V8 reemplaza las piezas con máscara inferior y ceja continua cerradas, ajustes de orejeras y bolsillos, asentamiento de insignias, raíz de Guardia LOD8/13 a y=0 y cámara D4 centrada. Se conservan pivotes, color, pruebas, G05 y bocetos históricos. Pendiente revisión de nuevas capturas, no aprobado. Publicación G05 V17 del run 45686050361 exitosa y verificación del paquete servido exitosa.

## V9 — refinamiento individual de los cuatro kits

FS-24: montaje curvo de ópticas, radio y protecciones especiales ancladas al brazo, antena duplicada oculta. Francotirador: capa de reconocimiento de perfil bajo, mochila reducida y retirada de accesorios redundantes. Logístico: una mochila de carga cerrada, módulos y cinchas; se retira el bloque V1 y el equipamiento superpuesto. Médico: bolsa médica cerrada, insignia blanca frontal, arnés y señalización dorsal. Las ocho pinturas de facción se conservan; no se crean roles ni se cambia combate. Guardia conserva V8; los cuatro especialistas V9; G05 V17 intacto. Se añaden 8 vistas de detalle de equipo, 78 PNG en total. QA de sólidos, piezas heredadas ocultas y rig de FS-24. Pendiente render real de V8/V9 antes de aprobar.

### Corrección de ejecución V9.1

Run V8 45754268783, job 139689068458: Godot 4.3 reportó `Invalid call. Nonexistent 'bool' constructor` en UnitModels3D.gd:1381 al convertir el metadato de identidad (String) a bool. Esto abortó Guardia y originó errores secundarios de recursos al salir. La condición ahora compara el rol String exacto; no se desactiva ninguna prueba. QA pendiente del nuevo HEAD.

## V10 — brazo afinado, coraza individual y efectos nativos

Cinco perfiles de hombro y pecho cerrados, conservando pivotes, contacto de manos y pinturas. Antebrazo de menor volumen con transición hacia muñeca; reutiliza la geometría y nodos. Efectos visuales únicamente: polvo de marcha, impacto de bala/explosión y humo estilizado del equipamiento en D3/D4 con un MultiMesh perezoso de 8 instancias LOD13 o 4 LOD8; se oculta al restaurar D0. Sin cambios de HP/daño real ni de G05. QA exige 88 PNG, 10 capturas nuevas de impactos, verificación de límite de instancias y limpieza reversible. V8 había fallado por conversión de String a bool, corregida en dd49b93. V9 y V10 todavía requieren CI y revisión visual; no fusionar.

## V11 — rodilla y tobillo articulados, uniforme inferior

Dos pivotes sin nueva malla por pierna, reaprovechando pantorrilla, rodillera, bota y suela cerradas con sus mismas transformaciones en reposo. Flexión de rodilla y compensación del tobillo durante marcha/servicio, retorno a pose neutra. Compensación de altura mediante la menor Y de las esquinas de ambas suelas en espacio local, conservando el nivel de apoyo original. Perfiles de muslo/pantorrilla y retirada de pliegues rectangulares, sin modificar G05 ni reglas. 98 PNG requeridos, 10 nuevas muestras de marcha y nueve fases comprobadas por cada uno de los 80 modelos; pruebas de pivotes y límites de ángulo. V9.1 y V10 QA en curso al inicio de esta ejecución; V11 aún no validada.

## V12 — revisión de capturas V11 y acabado de movimiento

V11 2fafe73: QA nativa 45755830353 exitosa, Android 45755830187 exitoso, Studio 45755830254 exitoso. 24/25 workflows correctos; falla histórica G13 V11 en 45755830098, fuera de este alcance. Artefacto 15087886134 inspeccionado: 30 vistas de frente/espalda/casco/marcha/impacto. Se aprecia progreso de la silueta y equipos, pero insignia de casco aún gruesa y marcha rígida. V12 reduce el distintivo a un sólido curvo somero, perfila bolsillos y cinchas, usa vértices reales cacheados de la suela para contacto y añade carrera visual de tres ciclos, postura de puntería/ataque con flexión diferenciada (francotirador más baja). Sin alterar reglas ni G05. Se propaga el fallo del acabado V12 al caller en lugar de ignorarlo. QA prevé 108 PNG y 21 muestras extra por modelo de carrera/puntería/ataque, contacto de manos y suelo. No publicar sin validación de HEAD y revisión real.

### V12 — verificación del visor y controles

La prueba de inventario de animaciones ahora exige la nueva carrera solo en cinco roles, conservando el inventario de G05 y diseños históricos. Comparación V1 muestra aviso de seleccionar Ver última si se intenta ejecutar carrera. QA nativa del mismo Studio verifica que el botón de carrera mueve rodillas reales. La exportación Chromium añade cinco cargas por URL, comprobando identidad V12, mismo SubViewport, mallas visibles, opacidad y ausencia de errores, y archiva cinco PNG y JSON; preserva prueba y evidencia G05. Esta verificación se ejecutará con el código actualizado, no implica publicación. 

### Sincronización de base antes de V13
V12 nativa 45772134764 y Android 45772134905 exitosas; artifact 15093994000, 25 renders inspeccionados. Pages 45772134748 falló antes de importar por ausencia de A02FpvArtV1.gd al preparar la rama antigua. Se integra el árbol principal exacto 101073b6 con A02 y los cambios de infantería mediante resolución explícita en tres archivos compartidos; no se fusiona infantería hacia main. Se mantiene la regresión histórica G13 separada.

## V13 — extremos y articulaciones

25 renders V12 inspeccionados: aún hace falta detalle de guantes, codos y botas. Palma cerrada con forma de guante, cuatro dedos curvados y pulgar anclado a la palma, protección cerrada de codo y caña de bota articulada. Se mantienen los centros de contacto V5 y la suela V12; seis nuevos nodos únicamente en LOD13, ningún nodo de malla nuevo en LOD8. Distintivo táctico de rodilla transferido al pivote correcto sin alterar su transform en reposo. Se exige 118 PNG (10 nuevos de manos/botas), cierre, anclaje y presupuesto. Studio y Chromium verifican edición V13. G05 intacto. Pendiente QA del nuevo HEAD y revisión visual; no fusionar.

## V14 — microrelieve PBR y equipo individual

V13 run 45903025953: etapa de 118 PNG exitosa; suite completa y exportación pendientes al comenzar. V14 añade mapas normales periódicos 64x64 con mipmaps y caché por clase (tejido/caucho/armadura) solo LOD13. Los accesorios de tela y equipo existentes reciben el mismo acabado y sus estados de desgaste D0-D4; se conservan insignias y ópticas. Manto del francotirador, módulos de carga, arnés médico y carcasa de radio FS-24 se refinan usando las mismas mallas/nodos; no aumenta el número de nodos en ninguno de los LOD. QA 128 capturas, 10 nuevas de materiales y prueba de restauración exacta de material del equipo. Visor identifica V14. Pendiente QA y revisión visual de HEAD exacto; no fusionar.

## V15 — revisión de proporciones y seis unidades juntas

V14 exacto 51a92d9: nativa 45903349603 y Android 45903349341 exitosos; artefacto 15156763484 inspeccionado (25 imágenes). Los antebrazos visualmente estirados, rodilleras abultadas y relieve excesivo motivaron esta revisión. Arma de preview más próxima al pecho, solución geométrica de dos segmentos con polo de flexión hacia abajo/afuera, contacto real conservado. Pruebas de longitud de antebrazo y contacto en 24 poses por modelo, reemplazan restricciones Euler previas solo para V15. Rodilleras delgadas y cerradas, distintivos y bolsas de costado suavizados, intensidad normal reducida. Dos fotografías conjuntas de las seis unidades a escala 0.83 más diez laterales de brazo, 140 PNG exigidos. No se altera G05, reglas ni mallas añadidas. QA y fotos exactas de V15 pendientes.

## V15.1 — integración visual de Guardia en batalla y rendimiento

V15 45906216641: etapa de las 140 capturas superada. Android, reglas y G05 live battle exitosos; Pages 45906216739 falló después de PASS A02 V16 SHARED STUDIO. Artefacto 15157524399 contiene las tres PNG >2 KiB exigidas; motivo exacto del exit 1 no confirmado. Se conserva la puerta A02 y se agregan diagnósticos de conteo/archivos, sin saltarla.

Se detectó que BattleTerrain3D todavía instanciaba Guardia `line` con finish=false, art_level=6. Se conecta a su acabado V15 LOD8 y a la facción visual real, preservando el límite compartido de ocho modelos, fallback, visibilidad, perfil táctico y G05. Altura del Guardia ajustada con la suela real al centro de la superficie (+0.025). Se añade prueba nativa con mapa real, dos Guardias y G05, cuatro PNG de reposo/marcha/puntería/ataque, prueba de nueve unidades y enemigo oculto, presupuesto de mallas, triángulos, tiempos de construcción y recibo JSON. Los tiempos de CI software no son FPS de Android. Los cuatro especialistas no jugables conservan su aprobación artística, sin desbloqueos tácticos. Pendiente ejecución exacta y revisión visual.
