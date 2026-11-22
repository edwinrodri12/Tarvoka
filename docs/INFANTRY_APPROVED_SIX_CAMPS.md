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


## Ingeniero V12–V12.2 — acabado dorsal y coraza exterior (integrado en main)

- Capa artística aditiva `InfantryEngineerDorsalV12.gd` sobre la geometría V11, sin cambiar unidades ni estadísticas, ataques, captura, campamentos, construcción, IA o guardado.
- Dos estuches de herramientas **con volumen 3D redondeado**, sobre soportes anclados al `TorsoRig`; reemplazan visualmente las bolsas V9 cuadradas y pueden recuperarse con el comparador V11/V12.
- Dos chapas octogonales **cerradas por todos los lados**, con relieve, franja PBR opaca del color exacto de las ocho facciones y nervaduras exteriores en el escudo V6 móvil. Remaches y costuras extra solo en LOD13; LOD8 conserva silueta y colores.
- Dos botones nuevos para comparar V11/V12 en el **mismo** `BastionStudioAdapter` y `SubViewport`. Reusar los controles existentes de 360°, barrera, 8 facciones, daños D0–D4 y LOD8/13.
- QA nativo dedicado `tests/test_infantry_engineer_v12_finish.gd`: 16 combinaciones de facción/LOD, mallas herméticas y opacas, rig correcto, comparación reversible, otras cinco tropas sin cambios y seis capturas reales Godot. CI nativa y publicador Pages ajustados para copiar la nueva dependencia.
- **Estado**: revisión de arte y CI pendientes; mantener PR en borrador y no presentar el visor público, APK o integración en `main` como completados sin comprobar ejecuciones y renders auténticos.

### Revisión visual V12.1 — 22 noviembre 2026

Se analizaron las seis fotografías Godot originales de V12 frente a las seis capturas V11. La silueta dorsal conservaba un rectángulo demasiado evidente y los estuches laterales parecían óvalos superpuestos. Se sustituyó la envolvente por una placa central **octagonal biselada y hermética** sobre el mismo rig V6, y se formaron estuches con **cinco secciones geométricas 3D cerradas** y tapas metálicas; nuevos paneles laterales PBR grandes usan el color auténtico de cada facción. La comparación V11/V12 sigue siendo reversible, y los controles LOD8/LOD13, giro, animación, color, combate y campamentos no cambian.

La prueba dedicada se amplió a **ocho capturas Godot**, incluyendo V11 y V12 desde la **misma cámara** y una facción adicional, además de verificar que las superficies nuevas no tienen bordes abiertos. Esta revisión no está aprobada para publicar hasta comprobar el nuevo CI y sus imágenes.

### V12.2 · integración aprobada y acceso directo al visor web (22 noviembre 2026)

- **Entregado en el código principal:** PR #670 (V11) y PR #672 (V12.2) fusionados en `main`, commit de integración `a6ac87eafe6e77149db3824247022622bd373c38`.
- **Validación V12.2 antes de integrar:** 8 capturas reales de Godot, 8 facciones × LOD8/LOD13, escudo cerrado, estuches físicos, colores de facción, bisagras correctas, marcas de daño y comparación V11/V12.2 aprobadas. Godot nativo, UI quick smoke y exportación web aprobados.
- **Validación del commit de integración:** GitHub Actions `44984933699` (compilación **y despliegue** de Pages) SUCCESS; UI quick smoke `44984933748` SUCCESS; Godot headless rules `44984933766` SUCCESS.
- **Enlace de revisión sin segundo visor:** `https://edwinrodri12.github.io/Tarvoka/?unidad=ingeniero`. La navegación de este enlace selecciona automáticamente la infantería ingeniera en el **mismo** visor Godot que los demás modelos, abre la pestaña Cámara y orienta el escudo hacia la cámara. Esta función de acceso directo se entrega en su propia revisión posterior; no considerar el enlace activo hasta aprobar sus CI y publicar Pages.
- Los controles `Ingeniero V11` y `Ingeniero V12` conservan la comparación reversible sobre la misma unidad; `V12` corresponde al último acabado físico V12.2.
- La publicación de una galería de ciudades V43 es un workflow diferente y su fallo no invalida el despliegue del visor principal.
- **Sin cambios en jugabilidad:** no se alteraron estadísticas, reglas de campamentos, economía, IA, visibilidad de combate ni colisiones. No equivale por sí solo a una APK nueva ni demuestra una prueba manual en navegador Android.
