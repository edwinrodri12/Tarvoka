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

### V15.1 — sincronización de A02 V16.3
Se incorporó main exacto 01a6024 (cámaras de A02, prueba de cinco PNG) mediante merge de dos padres. Se preserva la puerta estricta de cinco archivos d0/d4/return/top/bottom y el diagnóstico de tamaño/conteo. V15 nativa 45906216641 completa exitosa, artefacto 15157819943 revisado: ambas alineaciones y diez vistas laterales. Misma altura nominal, G05 con detalle notablemente mayor; sin afirmar equivalencia artística. No se fusionó en main.

## V15.2 — controlador de animaciones de Guardia en batalla

Se añade controlador visual V16 en escena real, sólo para Guardia LOD8 ya visible del bando del visor. Battle3DMapView inicia marcha/ataque exclusivamente tras Orders.confirm exitoso y reconstrucción de la escena, incluyendo soldados clásicos sin clave role. El origen usa casilla autorizada y altura de suela; no se reejecuta la orden. Interpolación 0.86 s y disparo 0.95 s, ajuste a posición confirmada, orientación y pose de reposo que conserva D0-D4 (no restauración de showroom). Se rechazan objetivo inexistente, enemigo, modelo genérico, acción inválida y D4. Se amplía prueba real de cuatro imágenes, estados de daño y efectos, más prueba de dos toques/cancelación en Main.tscn. Sin cambios tácticos ni G05. V15.1 45907332073 seguía en cola al comenzar; esta revisión no afirma validación final ni FPS físico.

### Sincronización V15.2
Merge de main 8045d3e: A02 V17 acabado opaco y verificación de superficie. Se preservan las cinco capturas A02 con diagnóstico explícito y pruebas WebGL de infantería. No cambia la rama principal. Pendiente CI exacto.

## V16 — candidato de acabado premium separado

Comparación V15 real 15157819943: cinco soldados más simples que G05, especialmente casco posterior, cintura y espinillas. Siete detalles cerrados por LOD13: protector posterior de casco, dos carriles de casco, dos placas de cintura y dos protectores de tibia, anclados en pivotes reales. Cinco perfiles y tonos según rol; materiales opacos D0-D4 por la paleta existente, facciones y G05 intactos. LOD8 no añade geometría. QA exige 150 capturas (diez nuevas), mallas cerradas, pivotes y presupuesto 7/0; Studio/Chromium exige V16. Rama art/infantry-premium-v16-20261126 separada de PR #703 para no cancelar CI V15.2 (41 ejecuciones pendientes al iniciar, una ya exitosa). No fusionar ni publicar antes de validar V15.2 y ejecutar V16. El detalle es una propuesta implementada, no una aprobación visual.

## V17 — equipamiento individual anclado a superficies reales

Rama premium independiente. Tres piezas cerradas por modelo LOD13 (solapa/cubierta y dos cierres), ajustadas al volumen real de cada mochila/radio/manto/bolsa médica mediante intersección de rayos y triángulos de la malla existente. Conserva las insignias centrales, materiales D0-D4, siluetas y pivotes. Guardia: mochila; FS-24: radio; francotirador: manto; logístico: bolsa de suministros; médico: botiquín. LOD8 sólo metadatos: cero mallas nuevas. QA comprueba contacto físico, padre, cierre y presupuesto; 160 capturas exigidas, diez nuevas. Workflow nativo habilitado en push sólo para la rama premium y main, para ejecutar QA sin actualizar el PR #703 ni cancelar sus comprobaciones. V15.2 Android 45907686107 exitoso; nativa y Pages pendientes al comenzar. V15.1 City QA 45907331989 falló en test_civilian_city_battle_v5.gd:127; investigar por separado, no se afirma que sea causada por la infantería. No fusionar ni publicar hasta QA y revisión visual.

## V18 — óptica opaca, curvatura y desgaste diferenciado

Visor cerrado de seis anillos adaptado a cinco identidades, sin añadir nodos. PBR satinado brillante D0 y deterioro progresivo D1-D4 de rugosidad/capa brillante, sin transparencia ni textura de relieve sobre cristales. Reutiliza tres ópticas del FS24 y lente de precisión, tonos distintos y misma posición. QA: cinco materiales opacos, desgaste reversible real D3/D0, 170 capturas exigidas (diez nuevas de cascos D0/D3). G05 intacto. Candidato separado art/infantry-optics-v18-20261126, base V17 167beae; no dispara otra suite mientras la V17 45908462703 espera. V15.2 16/41 exitosas, Android exitoso, G13 fallo histórico, nativa/Pages pendientes al comenzar. Sin publicación ni aceptación visual.

## V19 — texturas individuales de la familia

Candidato separado desde V18: art/infantry-surfaces-v19-20261126. Cinco perfiles periódicos de microestructura para Guardia (tejido equilibrado), FS24 (tejido compacto), francotirador (trama asimétrica), logístico (lona gruesa) y médico (trama fina). Albedo monocromático y normales de tela, goma y blindaje por identidad; 15 pares de texturas 64x64 con mipmaps, compartidos entre las ocho facciones y los cinco estados de daño. LOD8 mantiene materiales sin texturas. Fuerza alfa 1 en el material limpio; la óptica V18 conserva su perfil y no recibe normal de tela. No añade mallas, no cambia rigs, G05, distintivos de facción, reglas ni publicación.

QA nativo ampliado: contenido de píxeles distinto entre roles, reutilización de recursos, alfa opaco, dimensiones, mipmaps, asignación efectiva al casco/ropa/guantes, ausencia en LOD8 y reutilización de mapas durante D0-D4. Las 170 capturas de V18 siguen siendo la puerta mínima de revisión. Esta rama no se fusiona mientras falte validar las versiones anteriores y revisar las imágenes nativas. Código y pruebas guardados; ejecución Godot y aprobación visual no confirmadas.

## V20–V22 — accesorios, locomoción y efectos (candidato)

Rama art/infantry-specialist-v20-22-20261126 desde V19. V20 remodela 11 piezas existentes de las cuatro especialidades: dos costuras del manto, tres accesorios logísticos, cuatro médicos y dos hombreras FS24. Conserva envolventes, escalas, pivotes, emblemas y número de nodos. Sólo remodela en LOD13; las clases de material agregadas permiten desgaste reversible también en los accesorios existentes de LOD8, sin texturas tácticas. V21 diferencia amplitud de marcha/carrera por rol y postura de cabeza, conserva duración, solver de contacto, suelo, G05 y reglas. V22 usa el mismo MultiMesh 8/4, diferencia silueta de impacto y explosión y ancla polvo a la suela animada; D3/D4 siguen en el sistema de daño existente, sin HP nuevo.

QA incluye perfiles, topología, envolvente original, materiales por etapa, marcha y forma de efectos; 188 capturas nativas (170 anteriores + 8 de accesorios + 10 de efectos). Workflow habilitado exclusivamente para la rama candidata además de sus ramas anteriores. No se ha confirmado resultado del nuevo CI ni rendimiento en teléfono. No se fusiona en main ni se publica Pages hasta resolver QA y revisión visual. G05 y la lógica táctica quedan intactos.

## V23–V24 — corrección de importación y optimización de animación

El run V17 45908462703 (job 140210792230) falló durante importación Godot por variable `key` redeclarada en el test de familia. Se confirma mediante log original y se cambia la variable de iluminación a `key_light` sin alterar la prueba de placas. V15 run 45906216641 sí terminó con 140 imágenes; V22 run 45910703495 seguía en cola al revisar.

Rama art/infantry-validation-v23-24-20261126 desde V22. Proyección vertical exacta del vértice de suela mediante fila Y de la transformación, sin calcular X/Z innecesarios. Dos contactos de polvo calculados una vez por pose; reutilizan el nodo encontrado y no recorren el árbol por cada partícula. Sin nuevas mallas ni nuevos pools. QA añade referencia independiente de vértices sin cache, posiciones exactas de polvo, D3 humo+impacto y D4 sin disparo. Prueba de ocho Guardia LOD8 en escena de batalla con 32 muestras por unidad (256 poses), recibo de tiempo CPU medio y máximo del lote y capacidad fija de cuatro instancias por pool. No equivale a FPS real Android. La prueba anterior de 188 PNG sigue obligatoria; habilitar workflow para el candidato nuevo y conservar logs de fallos. V25 requiere resultados de importación, QA nativa, revisión de capturas y reconciliación con main. No fusionar ni publicar una versión no verificada.

## V25 — candidato integrado con main, sin publicación

Merge de dos padres: V24 c64455c y main ebd41ac. Se preservan los cuatro archivos A02 no solapados y se combinan los cambios de A02 V18 en BastionStudioAdapter y Pages con las rutas y controles de infantería. G05 sigue V17. El visor identifica V24 sólo mediante metadatos reales; la puerta WebGL comprueba V19–V24, recuento de accesorios por especialidad, opacidad y viewport. Se mantienen los cinco PNG A02 y el control de óptica inferior V18. Rama art/infantry-integration-v25-20261126 con QA nativa y exportación de revisión sin despliegue. No se afirma compilación, imágenes, aprobación visual ni FPS de Android hasta recibir evidencia. No fusionar a main sin validar y reconciliar nuevamente si main avanza.

### V25.1 — reparar dependencia ausente del exportador

Confirmado run V15.2 nativo 45907686049 exitoso, incluyendo 140 PNG, Guardia LOD8 en batalla y confirmación de orden de dos toques; Android debug 45907686107 exitoso. Run Pages de la misma revisión 45907686084, job 140213977240, falló al importar el proyecto ensamblado porque BattleTerrain3D precarga GuardiaBattleActionsV16.gd y el exportador no copiaba ese archivo desde su checkout exacto. No es un fallo confirmado de la malla de infantería. V25.1 agrega copia condicional según preload y verifica igualdad byte a byte del controlador y sus tres dependencias directas; conserva compatibilidad con ramas antiguas y todas las puertas de A02, G05 y familia. No se elimina ninguna prueba ni se despliega. La versión V25.1 requiere sus propios resultados CI; no se hereda aprobación de V15.2.

### V25.2 — pose D4 estable y humo independiente

Auditoría estática: antes, la rama de daño D4 ocultaba el destello y fijaba el cuerpo caído, pero una petición posterior de marcha, ataque o trabajo todavía podía alterar torso, brazos y cabeza. Se fuerza la pose neutra de las cinco unidades revisadas mientras D4 está activo, manteniendo el reloj de humo independiente, la postura caída y el contacto de manos. G05 y modelos históricos no se modifican. QA compara diez transformaciones reales del esqueleto al solicitar diez acciones distintas, para cada una de las cinco unidades, ocho facciones y dos LOD (800 solicitudes D4 previstas). Mantiene pruebas de humo, restauración D0 y geometría opaca. Validación nativa y revisión visual siguen pendientes; no se modifica main.

## V26 — armadura y color de facción, sólo LOD13

Base validada V25.3 673cebc, native 45912886929 (188 PNG) y Pages 45912886877 (exportación y WebGL aprobados, despliegue omitido). Las imágenes recuperadas mostraban silueta y color aún discretos comparados con G05. V26 usa diez superficies existentes por soldado con mezcla de color específica de cinco roles, remodela dos costillas laterales sin nuevos nodos, conserva opacidad y estados D0–D4. No modifica G05 ni LOD8; no cambia las reglas. Pruebas de geometría cerrada, envolvente, identidad real y color de facción para ocho facciones. No publicar antes de QA y comparación visual.

## V27–V28 — contornos anatómicos y casco individual

Rama candidata derivada de V26 5c3d9da (QA aún en cola). V27 sustituye ocho mallas de tela por contornos de ocho anillos y veinte lados, mantiene extremos longitudinales, pivotes, contactos de manos, suelas y solver. Perfil por rol, volumen posterior de pantorrilla y curvatura de mangas. V28 deforma sólo mitad posterior de la malla existente del casco, conserva vértices frontales y número de caras; cinco perfiles, sin segundo caparazón. Sólo LOD13; G05 y LOD8 intactos. Puertas nativas y WebGL amplían comprobación de metadatos, estanqueidad y extremos, sin eliminar las 188 imágenes. Requiere QA visual, no se publica.

## V29–V30 — acabado textil y equipo exterior

V26 native 45922402945 aprobado; V28 aún en validación. V29 conserva caché de texturas 64x64 y opacidad, introduce tejido de sarga periódico, contraste textil y cinco perfiles PBR locales de tela. V30 sustituye siete piezas existentes (dos bolsillos dorsales, dos pectorales, dos cinchas, cierre) por perfiles cerrados de seis anillos y 16 lados; conserva AABB y transformaciones, sin nuevos nodos. No mueve el equipo específico ni los anclajes V17. Pruebas reales de identidad, envolvente, PBR, D0–D4 y 188 PNG; sólo LOD13. No se publica hasta revisión nativa y visual.

## V31 — revisión visual basada en evidencias V26 (sin modificar arte)

Evidencia nativa descargada de 45922402945, artefacto 15164554378; referencia V25.3 de 45912886929, artefacto 15163172165. El log de V26 confirma 160 modelos y 188 PNG de la familia. Se compararon capturas RGB originales con cámara/facción equivalentes (840×700). Los cinco perfiles hero frontales cambian: Guardia 11152 píxeles, Comando 10771, Francotirador 9514, Logístico 10693, Médico 9658. G05 frontal y posterior y las cuatro vistas de Guardia en batalla (idle, move, aim, attack) coinciden exactamente. No se infiere igualdad de todos los PNG del ingeniero: sus otras capturas no son idénticas. El registro de batalla conserva 5144 triángulos, 67 mallas visibles, cero transparentes, ocho actores detallados, estado sin modificación. CPU de pose: 131.004 microsegundos promedio; grupo de ocho máximo 1316 microsegundos; software CI, no FPS Android.

Observación artística: V26 hace visible el color de facción, pero todavía hay transiciones de extremidades y botas más sencillas que G05. Revisar las V27–V30 con mismas vistas, recorte común y ocho colores antes de volver a esculpir. No aprobar arte sin comprobar casco, hombros, codos, manos, rodillas, tobillos y equipo en reposo y poses; conservar emblemas y diferenciación del rol. No publicar automáticamente. Sin nuevo cambio de runtime en esta revisión, para no reiniciar la cola de QA.

## V32 — botas con puntera y empeine protegidos

La revisión visual V26 mostraba botas de silueta blanda frente a G05. V32 sustituye dos mallas superiores por ocho anillos de 24 lados, preserva extremos en Y y no modifica la suela ni su caché de contacto. Añade cuatro mallas cerradas (puntera y empeine por bota) únicamente LOD13, asentadas con intersección sobre la superficie frontal real y articuladas como hijas de la bota. Pintura moderada por rol; materiales opacos con D0–D4. Prueba identidad y geometría, anclaje y suela, más captura existente de botas. G05, LOD8 y reglas sin cambios. Rama separada preserva V30 todavía en cola. No publicar sin validar.

## V32.1 — corrección V28.1 de precisión del casco

V26 Pages 45922402949 y V28 Pages 45922713342 aprobados; native V28 45922713332 falló 32 veces sólo en la comprobación compuesta de topología/altura/frente del casco. La causa exacta aún no está confirmada: se elimina el paso de extracción get_faces() y se reconstruye desde los vértices nativos sin índices del ArrayMesh orgánico. El QA separa conteo, altura y borde frontal sin relajar tolerancias, y compara todos los vértices frontales originales por índice. Mantiene prueba de malla cerrada. No modifica roles, materiales ni articulaciones. Nueva ejecución requerida, V32 no aprobado todavía.

## V32.2 — corrección V30.1 del equipo asimétrico

Native V30 45923571663 falla en construcción de los cinco soldados (9 comprobaciones iniciales de seis roles y equipo). El bolsillo curvo original usa nueve lados; su AABB en X tiene centro distinto de cero. V30 exigía simetría exacta y devolvía false, interrumpiendo apply antes de activar la identidad de escultura. V30.1 admite el centro real y lo aplica a todos los vértices y tapas del perfil cerrado. Conserva pruebas de dimensiones, centro, estanqueidad y 192 triángulos; añade regresión específica de bolsillo asimétrico. La rama V32 acumula la corrección V28.1 anterior. No se modifica geometría de LOD8 ni G05. Requiere confirmación nativa.

## V33 — integración candidata y estado de aprobación

V32.2 92a6351de6969e67583839bf7298b6d7f874ab3a aprobó native 45926041361 (160 modelos, 188 PNG, 8 facciones) y WebGL 45926041320 (5 roles, cero mallas transparentes, controles verificados, sin despliegue). Artefactos 15167139685 y 15167249420. Guardia LOD8: 5144 triángulos, 67 mallas visibles, 0 transparentes; 8 actores, 256 muestras CPU, media 130.984375 µs, peor grupo 1246 µs; no FPS Android. Comparación frontal G05 con V25.3 idéntica. V33 integra main ba9c1adc9e68c26ebdf59fc644d123c6a49709f2 por merge de dos padres; conserva A02 V24, sus pruebas y estándar artístico P06, sin cambios adicionales en geometría de infantería. Mantener EN REVISIÓN, no FINAL sin aprobación explícita del usuario, comparar con P06 y completar QA de integración/Android. No despliegue desde rama candidata.

## V33.1 — comprobación Android candidata y revisión artística P06

V33 native 45932515333 aprobado; WebGL 45932515342 aún en curso al registrar. Recuperada referencia P06 V25 (artifact 15156604740): evidencia macro de rueda y banda de rodadura, no cobertura completa del vehículo. Comparación cualitativa con Guardia V32.2, captura v15_line_arm_rest.png: P06 muestra jerarquía clara de piezas, refuerzos y contraste de materiales; Guardia aún muestra insignia rectangular prominente en manga, cuello cilíndrico y transiciones de hombrera relativamente simples. Candidatos a mejora posterior: insignias ajustadas a superficie, transición de cuello y articulaciones, sin comprometer silueta ni función. La comparación no constituye aprobación artística.

Se habilita disparo de APK debug sólo en la rama V33 y sólo por cambio explícito de su propio workflow. Usa el exportador Android existente, identidad efímera, comprobación ARM64, firma e integridad. No se habilitan secretos, firma persistente, publicación ni instalación; no implica compatibilidad de actualización con APK anterior. Las pruebas nativas y WebGL ya iniciadas no se reinician por este cambio documental/CI. Pendiente resultado Android y comprobación real del dispositivo cuando el usuario decida probar.

## V34–V35 — insignias ajustadas y cuello textil

Base V33.1 conserva V32.2 validada. V34 reutiliza cuatro insignias originales por soldado, sustituyendo su malla por relieve cerrado fino deformado mediante intersección en X de la superficie real de mangas y hombreras. Conserva material exacto de facción y pivote común. V35 reemplaza cuello existente por nueve anillos de 24 lados con pliegue comprimido, misma envolvente y articulación. No añade nodos, sólo LOD13. QA comprueba cada vértice de las insignias, penetración/salida, opacidad y color, y cierre y dimensiones del cuello. Requiere render nativo y evaluación visual; no FINAL ni publicación.

## V36–V37 — hombreras y codos

Base V35 validada: native 45933841707, WebGL 45933841665, sin despliegue. V36 esculpe las hombreras existentes con diez anillos, 24 lados, labio inferior y transición comprimida según rol. Se ajustan después las insignias V34 sobre la superficie nueva. V37 sustituye dos protecciones de codo por ocho anillos de 24 lados, conservando centro real de la malla original de 14 lados y pivote ELBOW_LOCAL. Cuatro mallas existentes, sin nuevos nodos, LOD13 exclusivo. QA de cierre, dimensiones, material D0–D4, jerarquía y contactos anteriores; requiere ejecución y evaluación visual. Main avanzó después de V33; no fusionar hasta comprobar sus nuevos cambios. No FINAL.
