# Infantería V5 — anatomía de cinco identidades oficiales

Candidato basado en 06dc4a9d1a01a4aa4d9ef3c18c5653af3ca3bf72. No aprobado ni publicado.

Evidencia inicial: capturas nativas del run 45684230042. Se esculpen torso, pelvis, hombreras, mangas, antebrazos, rodilleras y botas existentes en Guardia, FS-24, Francotirador, Logístico y Médico; se redondean kits físicos de especialistas. Sin nuevos nodos de malla ni cambios a pivotes o reglas. G05 y cuatro bocetos históricos excluidos. La suite comprueba 160 combinaciones y exige 53 capturas nativas, incluidas 15 nuevas de detalle. Pendientes: ejecución de Godot, inspección de imágenes, WebGL, verificación de contacto en poses y revisión individual de casco y equipo. El despliegue G05 sigue pendiente en el run 45686050361.

## Segunda prioridad: contactos articulados

Reutiliza guantes, dedos y antebrazos existentes, con las manos fijadas al rig del equipo y extremos de antebrazo calculados después de cada pose. QA de contacto exacto en seis animaciones y cuatro fases, ambas manos, 80 combinaciones de facción/LOD/rol (3.840 comprobaciones de contacto) y restauración. Destellos visuales del Francotirador y FS-24 ajustados a sus mallas. No se incorporan herramientas especiales nuevas: las poses de trabajo específicas de médico y logístico quedan para revisión individual. Pendiente ejecución nativa, no aprobado.

## V6 — identidad individual y herramientas de servicio

Casco cerrado con perfil, color de armadura neutro y coraza ajustados por rol; visor opaco curvo y cuello sellado. No se cambia pintura de facción. Médico y Logístico: prop físico de servicio bajo TorsoRig, visible solo durante la fase de trabajo; la mano derecha y sus dedos se transfieren al accesorio y vuelven al equipo en reposo. Sin nueva lógica de curación o suministro. Cinco enlaces directos permitidos y etiqueta V6 basada en metadatos reales del modelo en el mismo Studio. QA exige 60 PNG, incluidas 5 vistas de casco y 2 de servicio; comprueba cambio reversible de manos y visibilidad. No fusionar hasta validar los renders reales.
