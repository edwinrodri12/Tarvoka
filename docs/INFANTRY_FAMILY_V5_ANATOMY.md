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
