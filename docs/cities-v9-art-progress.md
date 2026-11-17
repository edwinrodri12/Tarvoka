# TARVOKA — ciudades civiles: avance de modelado 3D V9

**Estado: diseño en curso, no aprobado como modelo final.**

Este documento describe el trabajo de arte que continúa los volúmenes urbanos V1, fachadas V2, plaza V3, silueta V4 y arquitectura posterior V8. Las ciudades siguen siendo instalaciones civiles preexistentes, conquistables por infantería. No se toca la economía, la captura, el combate ni el número de ciudades por mapa.

## Avance artístico de esta fase

**Encuentros de cubiertas y fachadas**
- Canalones con retornos y bajantes de geometría real, fijaciones en el muro y salida pluvial para edificios intactos.
- Cornisas y piezas de transición en los dos lados de las cubiertas, no adornos flotando delante del edificio.
- Los edificios con daño estructural moderado conservan solo piezas dobladas; los edificios destruidos ya no muestran nuevas instalaciones de tejado.

**Identidad por tipología**
- **Villa:** teja cerámica, hiladas de ladrillo en esquinas, zócalos, juntas bajo las buhardillas V8 y canalones de cobre.
- **Ciudad:** parapetos continuos, piedra de esquina, remates de marquesinas, banda cívica y evacuación visualmente integrada.
- **Metrópoli:** vidrio de esquina, perfiles de aluminio, franjas entre pisos, coronación continua y estructura física de paneles solares.
- **Ayuntamiento:** pilastras, alero de acceso público, friso civil, molduras de la torre del reloj y remate de piedra.

**Materiales de volumen**
- Nuevas superficies Godot `StandardMaterial3D` con metalicidad y rugosidad específicas para cerámica, piedra, vidrio, cobre, acero y superficies oxidadas.
- Se conserva el color original de cada facción y de cada edificio previo. Los materiales especiales V9 no se sobrescriben durante el retoque del legado.
- No se han incorporado imágenes 2D que suplanten partes solicitadas como geometría.

**Estados de desgaste**
- Los cinco estados de daño siguen siendo visualmente diferentes; las capas V8/V9 no devuelven ventanas o canalones intactos a los edificios derruidos.

## Archivos principales

- `scripts/ui/CivilianCityFinishV9.gd` — nueva escultura y materiales.
- `scripts/ui/CivilianCityArchitectureV8.gd` — fachadas y cubiertas previas.
- `scripts/ui/CivilianCityTacticalLOD4.gd` — mismo ensamblador de modelos nativos, ahora con V8/V9.
- `scenes/CivilianCityDesignStudioV9.tscn` — escena para observación artística manual en Godot; incorpora vistas posterior, lateral y de cubiertas, además de controles de nivel urbano y estado de daño.

## Lo que falta antes de declarar el modelo final

Pendiente una pasada final de **volumen, proporciones y carácter urbano**: puertas del ayuntamiento y comercio, barandas de terrazas, raccords entre suelos y fachadas, y siluetas de destrucción vistas desde atrás. Nada se declara final ni se fusiona a `main` hasta completar el diseño acordado.

**Restricción expresa de la fase:** no se realizan pruebas automatizadas, mediciones de FPS, capturas QA, compilaciones APK ni fusiones de integración mientras se esté terminando el modelo 3D.
