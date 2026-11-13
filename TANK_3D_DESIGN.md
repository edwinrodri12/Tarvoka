# TARVOKA · Tanque principal (G09): segunda pasada de modelado 3D y pintura por facción

Este cambio implementa en el **juego** el desarrollo visual del tanque principal moderno ya existente, en la rama basada en PR #155. No agrega clases redundantes, modifica estadísticas ni sustituye la identidad visual aprobada.

## Silueta y piezas del modelo real

El tanque parte del lenguaje militar moderno de la referencia TARVOKA: casco bajo y ancho, glacis inclinado, torre blindada angular y cañón largo orientado al frente (-Z). Materiales metálicos neutros, ópticas frías, goma negra, componentes visibles a escala isométrica. Las piezas son nodos 3D `MeshInstance3D` editables, agrupados para facilitar futuros GLB.

- **Casco:** monocasco compuesto con glacis inclinado, placa del morro y cubierta posterior de motor.
- **Tren de rodaje:** dos orugas separadas, 7 ruedas/bujes visibles por lado, guías, zapatas, guardabarros.
- **Blindaje:** cinco módulos exteriores por faldón, ERA en los laterales y módulos adicionales en las mejillas y flancos de la torre.
- **Torre articulada:** nodo `TorretaGiratoria`, anillo de giro y nodo hijo `ElevacionCanon`, aptos para futuros disparos orientados. Su rotación es ahora inspeccionable y **todavía no sigue automáticamente un blanco en combate**.
- **Armamento:** tubo principal, manguito térmico, extractor de gases, boca y mantlete; arma secundaria con receptor, cañón, munición y cámara.
- **Equipo de observación:** sensores térmicos, escotilla, seis visores, módulos electroópticos, dos antenas y lanzafumígenos laterales.
- **Detalles de identificación:** lamas del motor, parrillas, escotilla del conductor, bastidores y placas superiores.

## Colores de las ocho facciones: SIN escudos ni emblemas

Se pintan exclusivamente los paneles cuyo nombre empieza por `Faccion` (o que contienen metadatos `tarvoka_paint_zone`). Mantener sin tintar casco principal, cañón, orugas, ruedas, ópticas y rejillas. Las zonas son:

| Zona | Piezas | Tratamiento |
|---|---:|---|
| Faldones laterales | 5 a cada lado | Color principal ligeramente militarizado |
| Placas superiores de la torre | 2 | Color principal |
| Franjas laterales de la torre | 2 | Variante 31% más oscura |

Total: **14 paneles personalizables**, sin símbolos ni pegatinas de facción. Los colores se toman directamente de `VisualStyle.FACTIONS`, sin crear una paleta paralela:

1. Alianza Norte, azul
2. Pacto Escarlata, rojo
3. Unión Verde, verde
4. Confederación Solar, amarillo
5. Sindicato Violeta, morado
6. Legión Ámbar, naranja
7. Dominio Turquesa, cian
8. Orden Ónix, gris plata

El API `UnitModels3D.build("tank",faction)` genera una instancia independiente. `apply_faction_palette(model,faction)` actualiza solo esos paneles **sin alterar otras unidades ni el estado táctico**. Los futuros modelos GLB pueden reutilizar esta convención simplemente nombrando sus mallas `Faccion...` o aplicando el metadato indicado.

## En la batalla

El motor `UnitRender3D` genera ocho capturas ortográficas de tanque en sus colores de equipo, una sola vez. `IsoRenderer` selecciona la textura por `unit["faction"]`; la antigua coloración global de todo el tanque se desactiva para no colorear goma, metal ni armas. Los otros siete modelos 3D conservan la implementación de PR #155 y las clases restantes mantienen el atlas 2D; el fallback 2D continúa disponible.

La interfaz de inspección permite seleccionar cualquiera de las ocho pinturas; cambiar la pintura en el visor no cambia la facción de una tropa ni las reglas de batalla.

## Segunda etapa implementada: materiales, animación y rendimiento Android

`TankSurface3D.gd` produce de forma reproducible pequeñas texturas PBR de albedo y normales tangenciales (96×96) para **blindaje, metal, orugas, ópticas y pintura de facción**. Los polígonos inclinados del casco incluyen coordenadas UV; el material regula brillo metálico, rugosidad y relieve por familia. Esto aporta detalle real a la malla, aunque **no equivale a un set artesanal definitivo de texturas fotográficas**.

`TankVisualRig3D.gd` controla con nodos separados:
- `TorretaGiratoria`: giro horizontal orientado al objetivo.
- `ElevacionCanon`: elevación, retroceso y recuperación.
- Ruedas, zapatas y bandas: giro/avance simulado y balanceo de suspensión.
- FX de acción: fogonazo breve, humo de disparo, polvo de marcha y sacudida/humo de impacto. Se activan solo con los eventos correspondientes.
- `restore()`: vuelve a reposo sin modificar HP, daño, munición ni resultados de combate.

`UnitRender3D.gd` mantiene **máximo dos cámaras efímeras de acción** en combate con efectos 3D (movimiento, ataque, daño visible). Al finalizar la acción conserva la orientación de hasta **cuatro unidades** mediante capturas dormidas sin actualizaciones continuas de GPU, y libera la representación del enemigo al desaparecer bajo la niebla de guerra. El modo de ahorro de batería destruye estas cámaras y vuelve a las capturas estáticas.

Las 15 vistas originales de 3D (siete clases neutras más ocho pinturas del tanque) se convierten a `ImageTexture` al inicio. Sus cámaras, luces y modelos estáticos se liberan para que Android no mantenga miles de piezas renderizándose ocultas. La imagen queda en memoria como sprite estático compatible con el motor táctico actual.

En el **visor Android**, los botones `Orugas`, `Disparo` y `Detener` ejecutan las mismas articulaciones reales que utiliza la batalla. El usuario puede observar la torreta, el cañón, la suspensión y el efecto de disparo desde otros ángulos, además de cambiar pintura.

Se añadió `tests/test_mbt_finishing_animation.gd` a la ejecución OpenGL real de GitHub Actions: verifica materiales PBR, UV, rotación del cañón, ruedas, FX, orientación conservada, limpieza por batería y visibilidad con niebla; publica `tarvoka_mbt_live_animation_frames.png` como evidencia. El resto de la batería de reglas, turnos, IA, mapa y guardados permanece activo.

## Pruebas y pendientes

La prueba real con software OpenGL crea y revisa las 8 pinturas, valida que se vean distintas, verifica que todas tengan paneles pintables, que el casco neutral no cambie, que girar la torre y elevar el cañón sea posible, y genera `artifacts/tarvoka_mbt_8_faction_colors.png` para inspección. También ejecuta las pruebas previas de sprites, batallas, ahorro de batería, visibilidad y Android.

**Todavía no considerarlo arte comercial definitivo**: ya existen UV procedurales, materiales PBR y movimientos de torre, cañón y suspensión, pero falta pasar de texturas técnicas generadas en código a mallas optimizadas de producción con UV y texturas creadas por artista, degradación/destrucción persistente, LOD y validación física de FPS, legibilidad, temperatura y batería en varios móviles. El rediseño de IFV, artillería y otros vehículos aprovechará los mismos materiales y sistemas. Ningún cambio visual debe alterar equilibrio, daño, munición o reglas.


## Tercera pasada de modelado en juego — acabados físicos G09 (13 nov 2026)

La solicitud es dejar de usar el tanque como maqueta gris con cubos. Esta nueva pasada genera **mallas editables reales** en `TankFinish3D.gd`, acopladas a `ChasisBlindado` y `TorretaGiratoria` antes de aplicar PBR, de modo que funcionan tanto en el inspector Android como en las capturas que se usan en la batalla.

- **Silueta y blindaje**: dos módulos de glacis de sección biselada, dos mejillas cerámicas con chaflanes, aristas y cordones de soldadura; el perfil sigue bajo y original, moderno pero no una reproducción exacta de un blindado comercial.
- **Casco y rodaje**: faros delanteros con lente, ganchos de remolque, cables laterales, protectores de ruedas extremas, faldones con tornillos físicos y cubiertas detalladas de mantenimiento y enfriamiento de motor.
- **Torre**: módulo óptico panorámico con lentes independientes, protectores laterales, armaduras laterales, bastidor de estiba posterior y uniones visibles. El equipo se ancla a la torreta real: rota junto con ella.
- **Materiales**: metales mate, caucho, ópticas brillantes y soldados/charcos de acero contrastados. `TankSurface3D.material_family` clasifica también sensores y lentes; las texturas PBR del sistema siguen siendo proceduralmente reproducibles.
- **Rendimiento**: la tornillería se agrupa en **dos MultiMesh** (20 pernos de faldones y 12 de torre), en lugar de 32 nodos de draw individuales. No se agregan nuevas cámaras a `UnitRender3D`.
- **Facciones**: exactamente los mismos **14 paneles** recoloreables y las 8 facciones originales, sin escudos. Ninguna pieza de la nueva pasada recibe la marca `Faccion`.
- **Daño**: las piezas laterales y el sensor panorámico desaparecen físicamente en fases críticas; restos de óptica, blindaje y bastidores quedan visibles junto a lenguas de fuego angulares y el motor quemado. Reparar el modelo restablece los componentes.

### Criterios de aceptación visual

1. Frente, costados, popa y techo deben leerse como un MBT original moderno al girar a 0°, 90°, 180° y 270°; la cámara no debe cortar el cañón ni las orugas.
2. La geometría debe ofrecer detalles a nivel de inspector, pero su silueta seguir reconocible cuando TARVOKA la rasteriza a 224×224 y al zoom del mapa.
3. El cambio a cualquiera de las ocho facciones solo toca los catorce paneles y jamás los visores, el cañón, las orugas o las partes mecánicas.
4. Las cinco fases de daño deben ser distintas aun sin humo; la revisión de HP de la batalla no modifica nunca sus estadísticas, consumibles ni reglas.
5. La APK debe superar render OpenGL real y exportación ARM64; los 15 renders cacheados se liberan del GPU al terminar su primera captura; solo dos tanques dinámicos pueden actualizarse a la vez.

Las nuevas pruebas `tests/test_mbt_art_finish.gd` generan `artifacts/tarvoka_mbt_detail_turntable.png` desde Godot para revisión de los cuatro ángulos y validan los pernos agrupados, 14 paneles, materiales PBR y reversión de daños.

**Estado honesto:** este pase mejora de forma material los acabados 3D integrados, pero aprobar un arte comercial definitivo exige **ver las capturas y la APK en el teléfono**. Faltan mapas UV y texturas de producción pintados manualmente, LOD validados en Android y evaluación estética del usuario antes de marcar el MBT como final.


## Cierre del detallado técnico G09 — revisión del video físico `242323.mp4`

En esta ejecución se completa una pasada de detalle y articulaciones compatible con las 8 facciones y el render real del juego. El video físico mostró que el tanque era reconocible, pero tenía grandes placas de color, accesorios demasiado cúbicos y humo de daño con esferas opacas que ocultaban el sobreblindaje.

**Geometría integrada — `TankProduction3D.gd` (pasada V4):**

- Cañón con aro de boca independiente, ánima oscura, dos abrazaderas térmicas y marca de alza. Todo se ancla al pivote **`ElevacionCanon`**, por lo que elevación y retroceso siguen funcionando.
- Costados con tres piezas de blindaje compuesto facetado por lado, rodaje con aros de rueda motriz, canal de suspensión, guardabarros, protección de faros y remaches de bujes.
- Torre con objetivo láser de carrocería, nuevos lentes individuales, visor térmico blindado, escotilla con aro y tiradores, rejillas y canastillas de estiba con soportes y bolsas independientes. Los componentes giran sobre **`TorretaGiratoria`**.
- Casco con relieve antideslizante, aletas de ventilación de motor, manijas de mantenimiento y paneles de faldón que conservan **14 zonas** de color, ahora como franjas sobre una base neutral de acero.
- Agrupación de **118 detalles físicos** en solo **3 MultiMesh** (48 relieves + 28 lamas + 42 remaches) para limitar costes en Android, además de las dos agrupaciones de tornillos existentes.
- Todo el detalle se construye una vez por instancia del tanque y puede ser inspeccionado como 3D auténtico desde 0°, 90°, 180° y 270°. El motor vuelve a capturas cacheadas y máximo dos modelos animados en combate.

**Cinco fases visuales preservadas y afinadas:** marcas y rozaduras del faldón en el primer impacto; rejilla fracturada, placa suelta y humo leve en el segundo; desaparición real de protección lateral, sensores y segmentos de orugas en daño crítico; cañón perdido, ópticas desprendidas, motor quemado, escombros y fuego inclinado en destrucción. El humo dejó de ser una secuencia de bolas sólidas: se construye a partir de una textura RGBA suave compartida de 96 px colocada en planos que miran a la cámara, con transparencia baja. Su movimiento solo se calcula cuando el inspector está abierto. La reparación revierte todas las ocultaciones físicas, sin alterar HP ni reglas.

**Pruebas de aceptación en CI:**
`tests/test_mbt_art_finish.gd` valida geometría, grupos MultiMesh, colores de ocho facciones, ópticas, cañón y restauración del estado destruido. `tests/test_tank_damage_laboratory.gd` exige QuadMesh transparente con textura suave y un desplazamiento de humo reproducible. Las pruebas existentes continúan protegiendo animación de orugas, disparo, retroceso, inspector en Android, render de cuatro ángulos y cinco fases de destrucción. El render `artifacts/tarvoka_mbt_detail_turntable.png` es un render real de Godot, no un concepto.

**Alcance honesto del cierre:** es un modelo 3D detallado, animable y utilizable en Android, elaborado proceduralmente. Aún no se puede certificar como arte comercial final sin una aceptación estética del usuario de la APK más reciente y sin presupuesto medido de FPS/temperatura en su teléfono. Tampoco se debe confundir este acabado con un paquete externo de GLB/UV y texturas 2K de estudio; el proyecto mantiene su sistema PBR reproducible actual. No bloquear la jugabilidad ni el trabajo sobre otros modelos por pendientes visuales de este tipo, pero conservarlos como checklist de pulido artístico opcional.


## Revisión visual 242346 + capturas del visor web: reconstrucción G09 V5 (13 nov 2026)

**Diagnóstico comprobado:** los detalles V4 añadían mallas pero no modificaban suficientemente la silueta; desde atrás la torreta y cubierta parecían huecas, algunos cubos y barandillas estaban desconectados, y el blindaje parecía un prototipo en vez de una máquina hermética. Por ello el G09 no ha obtenido aprobación de acabado definitivo.

**Solución implementada en `scripts/ui/TankSilhouetteV5.gd`:**
- Geometría principal reconstruida como **dos volúmenes triangulados completamente cerrados** (`CascoHermeticoV5`, `TorreHermeticaV5`) con cubiertas superior e inferior, caras laterales y cierre trasero. Cada uno tiene 10 esquinas articuladas en anillo y forma de cuña; se conserva el casco anterior internamente como fuente de compatibilidad.
- Viga delantera integrada, dos placas de glacis, faldones laterales continuos sobre las 14 zonas pintables, portón de cierre trasero y cubierta de motor, rejillas movidas al techo real.
- Torre modernizada con silueta baja y gruesa, mejillas grandes de compuesto, techo hermético y cesta/bastidor trasero conectados. El mantlete se reconstruyó en el pivote `ElevacionCanon`, manteniendo giro/disparo/recoil.
- Mallas obsoletas visibles (`CestaEquipamiento`, ERA cúbico, mejillas anteriores, mantlete rectangular) se ocultan sin borrarlas; el inspector y combate usan el mismo nuevo G09. La opción **Comparar** conserva el modelo inicial al construirlo con `finish_enabled=false`.
- Los cinco estados de daño incluyen marcas en la nueva cota de cubierta, pérdida de mejilla y sensor, reparación que **nunca reexpone** los cubos antiguos y cañón destruido. No cambia reglas, HP, fuego, facciones ni IA.

**Prueba estricta antihuguos**: `tests/test_mbt_silhouette_v5.gd` recorre **cada triángulo** de las mallas del casco y torreta y comprueba que cada arista geométrica pertenezca a exactamente **dos** caras. También verifica el pivote del cañón, los 14 paneles, las mallas del modelo anterior y el daño reversible. Se ejecuta en CI del estudio web antes de exportar; si falla, no se publica.

**Evidencia visual**: `artifacts/tarvoka_mbt_before_after_same_camera.png` compara la misma toma real del modelo base y el V5, y `artifacts/tarvoka_mbt_detail_turntable.png` presenta cuatro ángulos V5 del renderizador Godot 4.3. El visor HTML5 se publica con el SHA exacto de GitHub.

**Estado artístico**: primera reconstrucción estructural integrada y probada; **NO se certifica todavía como textura/material/pulido comercial definitivo** sin nueva evaluación en visor web. Siguiente fase: tratamiento de materiales de alta legibilidad, señales de uso PBR con normal/roughness y moderar accesorios restantes; después validar tamaño de icono y rendimiento Android. No repetir largas rondas de APK por unidad.


## G09 V8 — pulido implementado en el modelo real de Godot (13 nov 2026)

El usuario rechazó renders conceptuales como entregables. Las siguientes modificaciones afectan a la fuente real scripts/ui/TankHeroV7.gd, invocada desde UnitModels3D.build('tank') por Android, el visor y las capturas de combate. NO sustituir código por imágenes generadas.

- Pintura de acero grafito mate con blindaje cerámico de otro pigmento. Mapa original neutro de 256 px y microtexturas de normales y rugosidad compartidas entre instancias, sin fuentes externas.
- Las dos orugas tienen 84 zapatas modeladas con biseles y costillas, no cajas. TankVisualRig.pose mueve realmente estas zapatas por una trayectoria cerrada alrededor de sprockets e idlers; al parar regresa a posición inicial. Se conservan dos MultiMesh de orugas.
- Cuatro ruedas motrices de 32 segmentos, bujes y 48 dientes agrupados en un solo MultiMesh para móviles; se conservan las 14 ruedas de rodaje.
- Dos grupos de faros delanteros protegidos y emisivos, luces rojas posteriores, ceja frontal de protección y paneles cerámicos de torreta. Las 14 zonas originales de color para ocho facciones y el cañón articulado siguen intactos.
- Tests/test_g09_premium_finish_v8.gd valida pigmentos, mapas PBR, geometría de orugas, su circulación y restauración, luces, sprockets, facciones y 5 etapas de daño. CI browser obliga a pasar este test antes de crear WebGL o GLB.
- El único estado aprobado hasta ahora es integración estructural. Faltan valoración artística en el navegador, presupuesto de rendimiento Android y, si corresponde, acabado DCC UV más refinado. CI verde NO equivale a perfecto comercial.
