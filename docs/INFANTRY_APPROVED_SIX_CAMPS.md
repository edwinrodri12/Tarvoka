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
