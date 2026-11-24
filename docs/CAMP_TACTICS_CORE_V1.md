# Campamentos tácticos — fase V1 de integración

El Estudio 3D único ya se publicó con los cuatro modelos (run 45306126869). Este PR independiente empieza la lógica real sin introducir clases jugables ni alterar las estadísticas de unidades existentes.

- Un especialista exclusivo construye en su casilla de tierra, consume su acción y créditos, y permanece vivo. Máximo combinado de tres campamentos por facción. Sin solapamiento con edificios permanentes, relés u otros campamentos.
- El identificador jugable existente `engineer` (G05) corresponde al constructor defensivo. Las otras tres identidades están definidas en el arte, pero aún no disponen de perfil jugable aprobado.
- El estado opcional `camps` conserva propietario, tipo, posición, HP y visión. JSON v1 sigue siendo compatible con partidas antiguas; entradas malformadas, duplicadas, en agua o solapadas se rechazan.
- Defensa: +2 cobertura exclusivamente contra ataque terrestre de una unidad que ocupa su campamento amistoso. El mismo cálculo alimenta ataque real, contraataque, predicción pública e IA.
- Reconocimiento: visión sin ocupante, radio explícito de escenario, misma oclusión del terreno. Ocultar campamentos enemigos fuera de visión en la observación de IA.
- No se fija el precio de construcción, HP ni radio de reconocimiento: el API recibe un perfil **interno de escenario** explícito. Los números de los tests son únicamente fixtures, no balance de lanzamiento. El HUD no expone aún construcción ni altera partidas normales.
- Pendiente antes de activación pública: perfiles jugables del francotirador, logístico a pie y médico, tabla de construcción definitiva, objetivo/destrucción atacable, servicios de suministro/curación al terminar turno, modelos de mapa y UI/IA de construcción. Sin ingresos ni producción en campamentos. No publicar APK con esta integración parcial como funcionalidad terminada.
