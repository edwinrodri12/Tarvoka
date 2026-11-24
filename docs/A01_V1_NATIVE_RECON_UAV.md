# TARVOKA · A01 V1 — dron de reconocimiento (en desarrollo)

**Estado: primer modelo nativo 3D EN DESARROLLO. No aprobado.**
Esta es la primera familia aérea definida después de la última unidad terrestre G16. G17 NO existe en el catálogo oficial.

## Identidad visual y jugabilidad

- **Código de catálogo táctico:** `A01`, rol `uav_recon`. Facciones: 8 y colores del mismo `VisualStyle.gd` del resto del videojuego.
- **Silueta V1:** dron moderno de ala fija con fuselaje compuesto sellado, dos alas de 3,1 m aprox. de envergadura artística, doble viga de cola, estabilizadores inclinados, hélice trasera impulsora y módulo óptico inferior articulado.
- **Equipo:** cámara EO/IR y antena de comunicaciones. **Sin cañones, misiles ni explosivos**; no crear animaciones de disparo para esta clase.
- **Materiales:** cuerpo metálico/PBR opaco, lentes azules (no transparentes), marcas físicas de facción sobre ambas alas, ensamblaje de sólidos cerrados. No mostrar huecos.
- **Dos calidades:** LOD13 (detalle) y LOD8 (Android), con la **misma silueta** y componentes esenciales.
- **Animaciones V1:** vuelo (hélice impulsora), barrido del sensor, reacción a impacto y restauración. No son acciones tácticas nuevas.
- **Perfíl existente de juego:** `ModernArsenal.PROFILES.uav_recon`: 4 HP, 5 MOV, 7 VIS, 0 ATAQUE, 250 créditos, dominio aire, productor `drone_center`. No modificar estadísticas ni añadir detección omnisciente, apertura de niebla o economía ficticia.

## Integración y delimitaciones

El primer modelo se genera en `scripts/ui/A01ReconDroneV1.gd`, conectado al constructor y poses de `scripts/ui/UnitModels3D.gd`, y se muestra desde el **visor 3D online principal** en el mismo selector: `?unidad=a01`.

**Nota sobre denominaciones previas:** la pantalla histórica llamaba «A01 HAT-29» al helicóptero que internamente figura como rol táctico `attack_heli` de código **A05**. A01 en el catálogo oficial significa **dron de reconocimiento**. Esta revisión añade una opción nueva y NO reemplaza el helicóptero, ni borra su código, animaciones o modelo.

## Requisitos de aceptación antes de V1 terminada

1. En Godot 4.3 nativo, validar 8 facciones × 2 LOD = **16 capturas reales**.
2. Comprobar carenado completamente cerrado, alas sin transparencias, gimbal óptico físico y hélice giratoria, todas visibles en Android LOD8.
3. En el **mismo visor compartido TARVOKA**, seleccionar A01, cambiar facción, ejecutar barrido y vuelo, y restaurar.
4. Comparar calidad con G16/G15; ajustar formas, ruedas inexistentes en UAV, detalles de cola y nivel de pintura visible.
5. Revisar compatibilidad Android y rendimiento antes de declararlo definitivo. No informar que sensores de IA o mecánicas de niebla están implementados a partir de estas animaciones.

**Próxima prioridad artística:** acabado de ala/fuselaje, herrajes de cámaras, cableado físico, luces de navegación, daño visual acumulativo y rendimiento al alejar cámara. Debe revisarse en el visor online antes de cerrar A01.

## Etapa V2 — acabados PBR y revisión 360° (en desarrollo)

- Archivo aditivo: `scripts/ui/A01ReconFinishV2.gd`. Se aplica automáticamente a la geometría V1 en `UnitModels3D.gd`; no reemplaza ninguna unidad anterior ni el helicóptero histórico.
- Bordes sólidos de las alas, flaperones, uniones de cola, luces física izquierda roja y derecha verde, y bandas de color ampliadas para reconocer las facciones en LOD8 sin pegatinas planas.
- Sensor EO/IR: tres capas físicas opacas (carcasa, bisel y vidrio PBR azul), integradas en el pivote original de barrido. Sin transparencia, sin piezas flotantes por animación.
- LOD13: cierres de raíz alar, placas y conductos mecánicos adicionales. LOD8: mantiene el contorno esencial, las marcas de facción y el visor óptico con menos segmentos.
- Controles dentro de la **pestaña Cámara del mismo TARVOKA Estudio 3D**: frente, trasera, lateral, superior, acercamiento óptico, hélice/cola, giro 360° y restablecimiento de cámara.
- Tests nativos y de visor actualizados: **8 facciones × LOD8 y LOD13 = 16 imágenes** en Godot; pruebas del sensor, color, geometría física, vistas y selección compartida; obligatorias para publicar `?unidad=a01`.

**Estado:** V2 en pruebas. No declarar finalizada ni afirmar publicación hasta que el workflow de Godot y la aprobación visual estén confirmados. Los valores de detección, visión y combate del juego no cambian.


## Etapa V3 — hélice auténtica, herrajes EO/IR y selector compartido (en desarrollo)

- Archivo aditivo: scripts/ui/A01ReconFinishV3.gd. Es la MISMA aeronave V1/V2; no se crea un rol nuevo.
- La hélice V1 usaba tres barras centradas que aparentaban seis extremos. V3 oculta esas barras y dibuja exactamente tres palas radiales independientes bajo el mismo motor animado. Las piezas V1 se conservan como referencia invisible.
- Winglets volumétricos, superficies de ajuste de cola y cubiertas de servos. Las tapas y canalizaciones exclusivas de LOD13 no se añaden a LOD8.
- Gimbal EO/IR con dos apoyos cilíndricos sólidos, hijos del pivote óptico: siguen físicamente barrido y restauración; no crean cámaras de juego ni detección táctica.
- El Estudio principal vuelve a mostrar el selector compartido de ocho facciones para A01; al cambiar color reconstruye materiales físicos sin perder yaw/zoom.
- Pruebas nativas ampliadas a tres palas, dos apoyos del sensor, winglets, pintura de facción y 16 capturas reales (8 facciones × 2 LOD). El workflow de publicación copia el nuevo módulo V3.

**Estado:** código en PR de desarrollo #655. Faltan resultado de CI Godot 4.3, revisión de capturas nativas, inspección de contornos 360° y rendimiento en Android. No declarar A01 finalizado ni la URL ?unidad=a01 publicada antes de superar las validaciones.

**Prioridad V3 ejecutada en código (pendiente de confirmación nativa):** la prueba de Godot genera las 16 imágenes de facción/LOD y cinco nuevas vistas físicas del mismo dron (frontal, trasera, lateral, superior e inferior). Comprueba contraste real frente al fondo para detectar capturas vacías y recorre mallas 3D para rechazar materiales transparentes. El publicador usa marcadores V3 coherentes y existe un flujo exclusivo TARVOKA A01 Recon UAV V3 Native Visual QA con evidencia PNG propia.

**Próxima prioridad:** revisar los 21 PNG reales cuando el CI concluya; corregir clipping, facciones ilegibles o contornos huecos; medir Android y después añadir daño visual escalonado sin inventar ataques. La ejecución de las pruebas no se da por aprobada solo porque el código esté incorporado.


## Etapa V4 — alas de sección aerodinámica cerrada (Godot nativo verificado)

- `scripts/ui/A01ReconAirfoilV4.gd`: dos alas volumétricas cerradas con raíz, sección intermedia hero, puntas estrechas y tapas reales; retira de la vista las alas rectangulares V1/V2.
- En la ejecución de Godot 4.3 de noviembre de 2026 se generaron **21 capturas V4 auténticas** (16 facciones/LOD y cinco ángulos); la prueba nativa de geometría/materia pasó.
- La inspección de las capturas confirmó que seguían visibles superficies de cola excesivamente rectangulares, por lo que V4 NO se aprueba como acabado final.
- El visor compartido expuso una falla real al cambiar facción: el `UnitArtStudioWeb` original usaba pintura neutra (-1) para roles distintos de tanque. `BastionStudioAdapter` ahora reconstruye A01 en la MISMA escena con `_faction` y LOD13, y su prueba comprueba las ocho pinturas; se requiere CI del visor completo antes de declarar resuelto en producción.

## Etapa V5 — estabilizadores en V y doble larguero aerodinámico (en prueba)

- `scripts/ui/A01ReconTailV5.gd`: reemplaza visualmente las dos colas planas V1/V3 por perfiles triangulados y cerrados que se elevan hacia las puntas. Los dos largueros rectangulares se ocultan y se reemplazan por carenados elipsoidales sellados.
- Bandas físicas de facción y bisagras oscuras sobre cada estabilizador; los controles, barrido del sensor y hélice no cambian.
- El constructor `UnitModels3D.gd` ejecuta sucesivamente V1 → V2 → V3 → V4 → V5 en LOD8/13 para **un solo dron** del rol `uav_recon`.
- `tests/test_a01_recon_drone_v1.gd` exige las 16 capturas por facción/LOD, cinco vistas adicionales, perfiles V4 y V5 cerrados, antiguos largueros ocultos, pintura y límite de mallas visibles (LOD8 ≤70, LOD13 ≤95).
- `tests/test_a01_recon_shared_studio.gd` recorre las ocho facciones del selector original. El publisher completo ensambla la escena de las ramas fijadas y ejecuta esa prueba; el CI independiente **solo** valida la geometría y las 21 capturas, porque no dispone del árbol íntegro de las otras construcciones.

**Aprobación pendiente:** resultado verde de Godot V5 en ambos procesos, inspección de las 21 capturas V5 y rendimiento Android. No se ha fusionado ni publicado A01; no se añade daño de combate, ataque ni ningún cambio a visión/fog/economía. Siguiente etapa: daños exclusivamente visuales escalonados y pruebas de reparación/restauración, después de cerrar la revisión del modelo V5.


## Etapa V6 — daños visuales acumulativos y reparación (en pruebas)

**V5 ya superó una ejecución nativa real de Godot 4.3:** ocho facciones × LOD8/13, cinco ángulos de inspección, 21 PNG y presupuesto de 48 mallas visibles en LOD8 / 68 en LOD13. La revisión artística de esas capturas muestra una cola en V más legible y doble larguero cerrado. La publicación de esa revisión falló por un marcador de texto obsoleto (`PASS A01 RECON UAV V4`), ya corregido en el workflow, no por la geometría V5.

**Nueva implementación V6:**
- Archivo `scripts/ui/A01ReconDamageV6.gd`: cinco estados visuales D0 intacto; D1 marcas de impacto; D2 cubierta dañada y humo; D3 avería crítica y brasas; D4 destrucción 3D con piezas separadas, inclinación del casco y tres palas rotas/ocultas.
- Materiales opacos y mallas nativas; humo animado con geometría cerrada. Ninguna animación de disparo o arma nueva.
- `repair()` restituye D0, las posiciones y las tres palas; `set_stage()` es determinista y acumulativo y rechaza valores fuera de 0–4.
- El Estudio 3D ORIGINAL, no otro visor, recibe botones de daño/reparación. Detener una animación conserva los daños; cambiar de facción preserva etapa, dirección de cámara y zoom.
- `tests/test_a01_recon_damage_v6.gd`: comprueba en Godot las cinco etapas para ocho facciones × dos LOD, opacity de materiales, hélice D4/restauración, ausencia de ataque y conservación de `ModernArsenal`; guarda cinco capturas D0–D4.
- El workflow exclusivo exige tanto las 21 capturas de A01 V5 como la nueva prueba de cinco daños. El flujo de publicación completo incorpora las fuentes V6 al árbol real del visor y ejecuta la prueba de los botones.

**Estado de V6:** programado en el PR #655; **ejecución CI de daños y visor aún sin resultado confirmado**. No fusionar el PR ni anunciar publicación en Pages hasta obtener pruebas verdes, inspeccionar las imágenes de destrucción y medir rendimiento Android; los 48/68 anteriores corresponden a D0 de V5 y no a los efectos activos D4.


## Etapa V9 — esmalte conformado y carenados integrados (en validación)

- `scripts/ui/A01ReconWingletV9.gd`: añade **dos paneles físicos cerrados** que siguen los mismos perfiles aerodinámicos y estaciones de la V8; evita las bandas que parecían cajas flotantes.
- Las dos franjas rectangulares V8 se mantienen como respaldo invisible, mientras que las V9 son sólidos de espesor mínimo y material PBR opaco (`cull_back`).
- Se integran **dos carenados redondeados** en la raíz de los winglets, intersectando ala/aleta de manera intencional para ocultar la junta y suavizar la silueta. El LOD Android usa menos segmentos; la envergadura y el contorno general son idénticos.
- Los **ocho colores** proceden de `UnitModels3D.faction_paint_color`; no hay un cambio de rol, estadísticas, armamento o visión táctica. Permanecen el gimbal EO/IR, hélice impulsora, cámaras 360°, daños D0–D4 y restauración.
- Se añadió el modelo V9 a la misma cadena V1→V9 en `UnitModels3D.gd` y a `BastionStudioAdapter.gd` en el **visor único**; no se crea un segundo visor.
- `tests/test_a01_recon_winglet_v9.gd`: valida las superficies herméticas (bordes con orientaciones opuestas, sin triángulos degenerados), color, LOD8/13, reparación D4→D0 y cinco capturas Godot 4.3. La CI nativa y la publicación de Studio ejecutan esta prueba.

**Estado:** V9 implementada en el PR #655 (borrador). No debe declararse aprobada ni publicarse hasta que la CI nativa y la CI del Studio terminen correctamente, se revisen las imágenes V9 y el usuario apruebe el diseño. Una carga de doce UAV es un ensayo geométrico en CI, no una medición de FPS en dispositivo Android físico.


## Etapa V10 — fuselaje delantero sellado y óptica EO/IR real (en validación)

- `scripts/ui/A01ReconNoseOpticsV10.gd`: sustituye la nariz esférica antigua por carenado aerodinámico longitudinal de **malla 3D cerrada** con tapas, sin texturas transparentes ni polígonos invertidos. Respeta el cuerpo/alas, el motor trasero y el sensor existente.
- Dos insignias físicas laterales del **color oficial de cada facción**, aplicadas en LOD8/13. En nivel hero incorpora tres detalles de servicio de superficie; Android omite esos elementos para ahorrar dibujo.
- El sensor conserva **su pivote animado original**: incorpora anillo protector **anular hueco** delante de las lentes y pequeño cristal térmico secundario. La luz atraviesa la apertura real; el anillo no es un disco opaco.
- `UnitModels3D.gd` ahora encadena V1→V10; el mismo `BastionStudioAdapter.gd` muestra V10, sin sustituir el helicóptero de ataque A05 ni crear una segunda interfaz.
- `tests/test_a01_recon_nose_optics_v10.gd`: valida 8 colores × 2 LOD, malla cerrada/caras/oclusiones, anillo con hueco real, barrido EO/IR, 5 capturas 3D Godot, daño y reparación, presupuesto máximo de 70 mallas Android/95 hero y sin modificar `ModernArsenal`.
- CI dedicada A01 y CI del Estudio compartido actualizadas para incluir los archivos V10 y generar las pruebas. La rama permanece en borrador hasta inspección visual; no afirmar despliegue en Pages ni FPS Android físico.

**Hallazgos del QA V9:** Godot 4.3 ejecutó correctamente la prueba V9 tras reparar el error de sintaxis; el publicador del Estudio falló antes de la carga del A01 al reunir otro archivo de su largo catálogo. Se incorporó registro del nombre exacto del archivo faltante para identificar y reparar esa dependencia sin alterar unidades ajenas.


## Revisión V10.1 — auditoría visual de V8/V9 y corrección simétrica

- Se descargaron las imágenes **reales de Godot** de A01 V8 y V9 de las ejecuciones nativas y se compararon desde las vistas frontal, trasera, lateral, superior y Android. El modelo V9 mejora ciertos detalles, pero la diferencia a escala táctica sigue siendo sutil. **No son capturas de V10.**
- Se encontró un defecto específico en `A01ReconWingletV9._ring`: la cara externa del extremo **izquierdo** está compuesta por los vértices 5/4 de V8, mientras que los extremos derecho e izquierdo usaban por error 1/2. Ese error colocaba el esmalte izquierdo hacia adentro. Se aplicó selección de cara dependiente del signo; el acabado de ambas aletas ahora apunta hacia el exterior.
- La captura superior también reveló carenados blancos demasiado redondos en las puntas. Se redujo `A01_V9_WingtipRootFairing_*` a **0.110×0.072×0.226** en escala de malla y se reposicionó a x=±1.676, y=1.077, z=-0.037 para seguir la unión sin quedar como una esfera sobresaliente.
- `tests/test_a01_recon_winglet_v9.gd` ahora exige que la pintura del **lado izquierdo y derecho** sea exterior en ambas estaciones, para los ocho colores y ambos LOD, y rechaza carenados que sobresalgan demasiado.
- Se reprodujo por cálculo geométrico independiente la malla de nariz V10 (76/116 triángulos para LOD8/13) y la corona EO/IR V10 (96/160 triángulos); las cuatro mallas son cerradas y sin triángulos degenerados. Esto **no reemplaza** la renderización de Godot ni acredita el funcionamiento del visor.
- **Pendiente antes del cierre:** prueba real Godot y revisión de **13 capturas V10** (5 inspección + 8 colores tácticos); ejecución del publicador del visor original; QA en Android físico. No fusionar ni anunciar publicación sin estos controles.


## V10.2 — Revisión de capturas nativas, corrección de pintura y QA pendiente

- En la ejecución de Godot 4.3 del commit `6c7187d7`, las etapas de modelo V9 y **V10 nativa** produjeron resultados `PASS`. Se recuperaron cinco PNG auténticos de V10: frontal, lateral, inferior, macro de óptica y Android LOD8. El **workflow completo no está verde**: el paso de aseguramiento del Studio buscó el texto V10 en el publicador de una revisión intermedia anterior a la posterior actualización del publicador. No confundir un bloqueado de orquestación con un error geométrico.
- La imagen macro del sensor mostró dos **óvalos de facción que sobresalían** de la nariz. `A01ReconNoseOpticsV10.gd` reemplaza esas dos esferas por dos mallas de esmalte aerodinámico y **hermético** que reproducen las secciones reales del fuselaje: 12 triángulos por lado en LOD8 y 20 por lado en LOD13. El color sigue asociado a las ocho facciones. No se añade armamento ni se cambia el rol.
- Se reforzó `tests/test_a01_recon_nose_optics_v10.gd` para rechazar cápsulas y comprobar que las dos mallas de color están cerradas, tienen caras orientadas correctamente, quedan sobre el lado correcto del fuselaje y cubren ambas estaciones longitudinales. Se conserva la prueba de ocho fotos a escala táctica, además de los cinco ángulos de inspección (13 PNG requeridos).
- La revisión anterior de las alas también arregló el esmalte exterior izquierdo y redujo los carenados globulares. Las nuevas modificaciones geométricas V9/V10.2 **requieren nuevas capturas Godot**, que no deben confundirse con los cinco PNG previos del commit `6c7187d7`.
- El publicador integrado continúa bloqueado al preparar archivos externos al A01; la CI nueva incluye diagnóstico que imprime el nombre del archivo que falte. No afirmar que el visor online se ha actualizado ni aprobar visualmente la V10.2 hasta superar ese proceso.


## Etapa V10.4 — inspección real LOD13 ↔ LOD8 en el Estudio 3D compartido

- La ejecución de `tarvoka-3d-pages.yml` en el commit `d5b0a3c0` **aprobó** la compilación web y el test `PASS A01 V10 SHARED STUDIO`: conserva el selector único, ocho facciones, sensor EO/IR, giro 360°, daño D0–D4 y reparación. [Build de GitHub Actions](https://github.com/edwinrodri12/Tarvoka/actions/runs/44976308617). El despliegue de Pages fue **skipped** por ser un PR, no se declara publicado.
- El panel de cámara del visor original agrega los botones **LOD13 · detalle** y **LOD8 · Android**; seleccionan geometría nativa 3D de Godot con calidad distinta en el mismo `SubViewport`, no capturas estáticas ni visor paralelo.
- `BastionStudioAdapter._a01_review_set_lod` crea y verifica el siguiente modelo antes de desmontar el anterior; conserva color de facción, estado visual D0–D4, rumbo de cámara `_yaw`, zoom y enfoque especial (superior, óptica, cola). Detiene animaciones del modelo anterior para que no queden punteros a nodos eliminados. LOD inválido se rechaza.
- Al volver al selector del A01 o cambiar facción, `_display_role` mantiene el LOD elegido y la identidad cromática de facción; panel de información muestra LOD y número de mallas.
- `tests/test_a01_recon_shared_studio.gd` pulsa los botones visibles con `Button.pressed.emit()` y comprueba cambios LOD13→8→13, misma cámara/preview, preservación de daño D3, cambio de facción dentro de LOD8, reparación D0 y rechazo de valores no válidos.
- **Estado**: V10.4 código y regresión añadidos a la rama en borrador; estas nuevas pruebas requieren ejecución Godot/Pages posterior al último commit. La publicación web todavía necesita habilitar despliegue al integrar en `main`; no fusionar antes de revisar la prueba completa y la aceptación visual Android.


## V10.5 — Accesibilidad de LOD en visor apaisado y liberación segura

- QA V10.4 del commit `4413611af4ea3182c3ae21dbf3175b34c613bf90`: [CI nativa](https://github.com/edwinrodri12/Tarvoka/actions/runs/44982040114) y [CI Studio unificado](https://github.com/edwinrodri12/Tarvoka/actions/runs/44982039843) concluyeron **SUCCESS**; el Studio ejecutó `PASS A01 V10 SHARED STUDIO`, con LOD8/13, ocho colores, D0–D4 y foco de cámara preservado. Capturas de comparación del mismo visor fueron archivadas por la CI.
- Inspección de ambas capturas de tamaño **1152×648**: los botones de calidad aparecían tras cuatro filas de cámaras, demasiado abajo en el panel y fuera del área visible. Se han **movido inmediatamente debajo del título de la sección A01** y antes de los ángulos, evitando desplazamiento innecesario en Android apaisado.
- Se añadió el rótulo en vivo `A01_LodActivo` con `Calidad activa: LOD13 · detalle` o `Calidad activa: LOD8 · Android`. Se sincroniza tanto al pulsar un botón LOD como al reconstruir el A01 tras un cambio de facción. No modifica mallas ni jugabilidad.
- `tests/test_a01_recon_shared_studio.gd` ahora exige que ambos botones estén colocados **antes** de la fila «Frente/Trasera», que la etiqueta muestre el nivel real tras cada cambio y que las verificaciones anteriores de daño, zoom, foco y facciones permanezcan intactas.
- Último cambio de UI **pendiente de CI**. El flujo de publicación de Pages en PR compila y archiva pruebas, pero el despliegue se omite; el modelo V10.5 no está marcado como publicado públicamente ni fusionado hasta la aceptación visual del usuario y las pruebas Android.


## A01 V11 — auditoría visual profunda y corrección aerodinámica (22 noviembre 2026)

**Evidencia inspeccionada:** 54 PNG originales de Godot 4.3 del Studio publicado en `main` (run `45057047901`), incluidas cinco cámaras de V10, ocho facciones tácticas, daños D0-D4, y comparativas del visor único. No son concept arts generadas. La prueba V10 anterior arrojó 56/68 mallas visibles D0/D4 en LOD8 y 79/88 en LOD13 (máximos 70 y 95 respectivamente). Estas cifras son **anteriores** a V11 y no representan FPS Android.

### Hallazgos concretos de la revisión
- El fuselaje V1 seguía visible como elipsoide genérico de gran volumen, mientras que la nariz V10 ya utilizaba malla cerrada. La unión longitudinal era poco consistente.
- Persistían sobre las alas las dos `A01_V2_LargeFactionWingBand` como cajas sobresalientes, junto a marcas V1 redundantes. Las franjas V9 del extremo alar ya eran conformadas y se conservan.
- El mástil dorsal rectangular y su punta V3 recordaban una construcción por bloques y duplicaban elementos.
- El LOD8 y el LOD13 tenían silueta compartida y QA geométrico, pero faltaba una prueba específica que garantizara **cuerpo completo** sellado y pinturas superiores realmente conformadas en ambos niveles.

### Cambios de código aplicados en la rama V11
- Nuevo `scripts/ui/A01ReconAirframeV11.gd`: fuselaje longitudinal cerrado con ocho estaciones de sección elíptica, tapas reales, mallas `ArrayMesh`, normales y material PBR sólido. Emplea 10 segmentos radiales Android y 14 hero.
- Crestón dorsal y dos secciones de esmalte alar de facción como **sólidos finos de 12 triángulos**, asentados sobre superficies reales, no cajas flotantes. Los colores provienen del catálogo oficial de ocho facciones.
- Antena estilizada cónica, con base físicamente incrustada. Los diez objetos previos de geometría superpuesta son retirados de la *vista*, conservados como nodos históricos para compatibilidad de pruebas y comparación; no se duplican visualmente.
- V11 se añade tras V10 en `UnitModels3D.build("uav_recon", ...)`, tanto LOD8 como 13, y se confirma en `BastionStudioAdapter.gd` antes de cambiar calidad del mismo visor. No se sustituye al HAT-29 `attack_heli`.
- Prueba nueva `tests/test_a01_recon_airframe_v11.gd`: topología sin bordes abiertos ni caras degeneradas, materiales completamente opacos, posición exterior de esmaltes, ocho facciones × dos LOD, presupuesto visible D0/D4, reparación y seis renders nativos. Prueba del mismo Studio refuerza cambio de facción, LOD y pintura real.
- Workflows nativo y de publicación conjunta incorporan este módulo y exigen **PASS V11 + seis PNG antes de publicar**.

**Criterio de avance:** nueva CI verde Godot 4.3 y revisión visual de los seis renders V11 antes de integrar a `main`; después comprobar publicación real del Studio único. En Android físico siguen pendientes temperatura, FPS, memoria y draw calls. No se altera movimiento, coste, rango de visión, niebla ni ataques. No se marca A01 como arte final hasta revisión en el dispositivo.


## A01 V12 — continuidad física ala/fuselaje (23 noviembre 2026)

**Problema corregido:** el modelo V11 preservaba dos elipsoides V4 `A01_V4_SmoothCompositeWingRoot_*` sobre la unión entre fuselaje y ala, cuya silueta parecía una pieza adicional adherida. El problema es visual, no de estadísticas.

**Nueva construcción:** `scripts/ui/A01ReconWingRootV12.gd` genera una malla propia para cada raíz alar, con secciones de perfil cerrado en seis posiciones transversales para LOD13 (cuatro estaciones para Android LOD8). Los perfiles se conectan con triángulos físicos orientados hacia afuera y **dos tapas cerradas**, sin planchas transparentes ni trucos de doble cara. La primera estación penetra físicamente en el casco compuesto V11; la última termina dentro del perfil alar V4. Se conserva el exterior gris compuesto y la pintura de las ocho facciones, en lugar de bandas nuevas encima de la articulación.

Los dos elipsoides V4 dejan de ser visibles, pero permanecen como nodos históricos; en la variante detallada también se ocultan los soportes rectangulares heredados que estaban parcialmente superpuestos. **Se conserva el mismo inventario de mallas activas en la raíz: dos sustituyen a dos.**

**Criterios de pruebas:**
- Dos mallas `ArrayMesh` individuales y cerradas con 44 triángulos por lado en LOD8, 68 en LOD13. Validar aristas compartidas con orientación opuesta y ausencia de triángulos degenerados.
- Comprobar ambas alas y envolvente espacial; ocho facciones × dos LOD, presupuestos de geometría D0/D4, daño y reparación; sin cambiar el perfil de ModernArsenal.
- Seis capturas **nativas Godot** desde frontal, ambos laterales, isometría, superior y Android, exportadas en `build/qa/a01-v12`.
- Validación dentro del **mismo** `UnitArtStudioWeb` — no visor secundario. QA debe proteger LOD8/13, cámara, colores y D3.
- CI nativa y la compilación Pages exigen `PASS A01 V12 WING ROOTS:`; no aprobar la publicación hasta verificar la nueva captura y el informe real de GitHub Actions.

El resultado sigue siendo **arte en desarrollo**, no prueba de FPS en móvil. El A01 continúa siendo UAV desarmado de reconocimiento y no modifica al helicóptero HAT-29 ni las reglas de combate.


### Ajuste V12.1: inspección de ocho vistas y eliminación de juntas sobredimensionadas

Tras revisar las ocho vistas Godot de `run 45212686166` (prueba nativa superada), se corrigió la transición angular de ambas raíces: ahora los extremos se ocultan **dentro** del fuselaje V11 y del ala V4, con estaciones intermedias y normales suavizadas. El acabado utiliza el mismo material opaco del fuselaje. Los registros oscuros `A01_V3_WingServiceHatch_L/R` dejan de proyectarse como aberturas sobre el ala. QA comprueba cierre 2-manifold de 44/68 triángulos, tapas enterradas, presupuesto D0–D4 y genera seis vistas generales más dos acercamientos.

La compilación inicial del Studio de este cambio falló porque `main` añadió durante el desarrollo `InfantryEngineerSmoothV13.gd`, ausente de la rama antigua. Este commit de integración incorpora **todo el árbol actualizado de main** como segundo padre del merge, conservando explícitamente G05 V13 y sin modificar sus contenidos. Todavía se exige CI del Studio sobre este nuevo árbol antes de integrar a la rama principal.


## A01 V13 — pintura de estabilizadores y guarda óptica inferior (23 noviembre 2026)

La V12.1 está integrada en `main` tras pasar Godot 4.3 nativo y el compilador completo del Estudio 3D. La siguiente inspección de la cola y del gimbal bajo el morro reveló acabados todavía construidos como rectángulos en V3/V5. No es necesario reconstruir las mecánicas; los defectos son visuales.

**Nuevo módulo `A01ReconTailOpticsV13.gd`:**

- Dos esmaltes físicos `ArrayMesh` cerrados de 12 triángulos cada uno, siguiendo exactamente la cara superior de los perfiles V5. El LOD13 interpola la estación media adicional; Android usa las secciones equivalentes y la misma silueta.
- Se ocultan las cajas V5 de pintura, los rectángulos antiguos de bisagra y los conductos V3 que sobresalían por encima de la cola. Dos articulaciones de casco redondeadas reemplazan las antiguas cajas.
- El rectángulo `A01_V3_GimbalLowerProtection` se sustituye por una protección física elipsoidal opaca y cerrada, hija del **mismo pivote EO/IR**. Se conserva el motor de escaneo, el Stop, la lente azul, el anillo V10, los daños y la reparación.
- Una nueva prueba comprueba colores de ocho facciones × LOD8/13, topología cerrada, estados D0–D4, límite de polígonos, giro real del sensor y **ocho capturas Godot** (incluyendo dos acercamientos a la cola y uno al sensor). Las pruebas originales V1–V12 siguen siendo obligatorias.
- `UnitModels3D` agrega V13 al final de la cadena existente; `BastionStudioAdapter` mantiene el mismo visor online y los cambios de facción y LOD, sin páginas ni unidades alternativas.

**Puerta de calidad:** no integrar en `main` hasta que el nuevo workflow nativo y la compilación completa del visor de Godot 4.3 se completen con éxito, y las ocho imágenes se inspeccionen. Sin alteraciones de visión de niebla, movimiento, combustible, economía, ataques ni helicópteros. La medida de FPS y temperatura en Android físico sigue pendiente.


## A01 V14 — daños físicos D1–D4, fractura real de ala y reparación (23 noviembre 2026)

**Motivación:** las capturas nativas V13 muestran todavía rayones, quemaduras, planchas y fragmentos dibujados como paralelepípedos sobre el fuselaje. La geometría D4 anterior conservaba el ala derecha totalmente intacta debajo de una caja negra, de modo que no existía una rotura visible real.

**Implementación:** \`A01ReconDamageFinishV14.gd\` sustituye los nueve bloques de impactos D1–D4 por mallas opacas cerradas con superficies adaptadas a los perfiles aerodinámicos exactos de V4/V11/V13; conserva humos, llamas, controles de fase D0–D4 y reparaciones V6. El D4 oculta temporalmente el ala derecha completa y los componentes de su punta y muestra una **nueva ala acortada de perfil cerrado y extremo serrado**, con núcleo expuesto y dos esquirlas tridimensionales separadas. El ala izquierda permanece intacta. Al reparar se restauran las mismas instancias de malla y todas sus superficies; no se pierden colores de facción, cámara ni LOD.

**Integración y seguridad:** \`A01ReconDamageV6.set_stage\` sigue siendo la única API de daño; una pequeña sincronización de nodos se activa únicamente cuando está presente el indicador V14. No cambia HP, visión, niebla, movimiento, combustible, ataque ni la configuración del helicóptero HAT-29. \`UnitModels3D\` y el Studio online comparten la misma construcción del A01; no se abre un segundo visor.

**Prueba obligatoria:** \`test_a01_recon_damage_finish_v14.gd\` valida geometría sellada 2-manifold, cero caras degeneradas, las ocho facciones, ambos LOD, 5 estados, cambio real de ala, reparación exacta, presupuestos de mallas y triángulos y ocho nuevas capturas auténticas de Godot 4.3. Workflows A01 y Pages deben pasar antes del merge. Sin medición de FPS/temperatura Android físico no se considera arte terminado.


## A01 V15 — volúmenes orgánicos de humo y fuego

El PR #691 de V14 pasó la CI nativa y la compilación del Studio, y fue incorporado a main en abf2e69f. V15 conserva la fractura real del ala y es exclusivamente visual. Seis mallas cónicas V6 se ocultan y sustituyen uno a uno por seis sólidos nativos con seis secciones irregulares, tapas selladas, normales suavizadas y gradiente por vértices. El humo oscuro se vuelve ceniza gris en la parte superior y la llama usa núcleo cálido y extremos naranja/rojo con emisión. El origen local de cada pieza se conserva durante la oscilación; el reloj mueve escala/rotación, sin crear mallas ni buscar nodos cada frame. D0/D1 no emiten, D2 suma humo, D3 suma fuego y D4 añade humo de restos y brasas. La reparación restablece todas las transformaciones. LOD8: 92 triángulos por efecto; LOD13: 140; sin incrementar el número de mallas visibles respecto a V14. Los tests V14 amplían cierre topológico, color y emisión, cache, animación y reparación. CI nativa y web deben confirmar el resultado; no implica medición de FPS en móvil físico.


## A01 V16 — auditoría de superficies e integración estructural

La revisión del usuario detectó caras aparentemente transparentes y piezas inconexas. La causa confirmada en código: los generadores V4/V8/V9/V10 y las pieles cerradas V11/V13/V14 habían elegido el producto vectorial exterior en sentido antihorario matemático, pero Godot 4.3 considera front-facing el orden horario. La prueba anterior de aristas manifold no distinguía sólidos invertidos. V16 corrige el winding en las fuentes, conserva CULL_BACK (no se ocultan defectos forzando doble cara), mantiene materiales y vértices opacos. V15 había fallado por costuras inconsistentes en humo/fuego; sus anillos ahora tienen conectividad explícita y tapas en abanico centrado, 96/144 triángulos por pieza.

Se reconstruye el casco como un único loft cerrado desde morro a cola: 12 estaciones, 12/16 lados radiales, normales suaves, y se oculta el volumen de morro V10 que se superponía. La pintura del morro usa los nuevos perfiles; la dorsal sigue los vértices angulares/longitudinales reales y su espesor penetra en el casco. Las dos bandas alares también se asientan en su perfil. La antena tiene raíz enterrada. Los dos brazos de cola reemplazan las elipsoides desconectadas por lofts opacos cerrados que unen el interior del larguero alar a la bisagra del estabilizador; se ocultan antiguos bloques y cables V2 redundantes.

QA: todas las mallas visibles de cada facción, LOD y daño deben ser cerradas, no degeneradas, con volumen orientado exterior negativo (convención horaria), material opaco y alpha por vértice 1. Se verifican casco continuo, anclajes de cola y reparación. La misma CI nativa y Studio deben pasar antes de integrar. Esto es una corrección estructural, no la aprobación artística final: todavía se requiere inspeccionar capturas y mejorar el detalle de superficie.
