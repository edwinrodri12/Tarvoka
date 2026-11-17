# TARVOKA — A01 V13: daño visual, impactos y destrucción

## Alcance implementado
Se incorpora `scripts/ui/AttackHelicopterDamageV13.gd` como capa 3D nativa Godot 4.3 independiente sobre la escultura de ataque A01 V12.1; no cambia alcance, vida, estadísticas, reglas, impactos del juego ni el LOD de batalla móvil.

La capa tiene cinco estados (0 intacto, 1 daño leve, 2 moderado, 3 crítico y 4 destruido). La malla permanece completa; se añaden, de forma reversible:

- cicatrices y rayaduras en fuselaje, con destello, chispas y anillo de onda expansiva real en los impactos;
- paneles ennegrecidos y columna de humo sobre un motor en daños moderados, con partículas de malla que ascienden durante la inactividad;
- fuego visible en estado crítico, cuyas llamas fluctúan con reloj propio incluso sin nueva animación de combate;
- aspas originales ocultas solo en destrucción (no eliminadas), con nuevas mallas cerradas de fragmentos de rotor principal y rotor de cola, bordes irregulares y despegue desde sus bujes originales;
- animación de caída e inclinación del modelo y trayectorias escalonadas de fragmentos (salida del buje, giro en el aire, aterrizaje en el terreno) durante la destrucción;
- botón de reparación que restablece los rotores y oculta todos los efectos.

## Visor 3D unificado
Bajo A01 se ofrecen: **Impactos de bala**, **Impacto explosivo**, **Siguiente nivel de daño**, **Reparar helicóptero**, **Animar destrucción** y acercamiento al humo. Se respeta el selector de facciones y la cámara. El texto técnico refleja el nivel de daño vigente.

## Pruebas
- `tests/test_attack_helicopter_v13.gd`: ocho facciones, 0–4, animaciones, humo y fuego con movimiento independiente, visibilidad y rotación del rotor, fragmentos independientes, reparación, idempotencia y ausencia de arte V13 en LOD10.
- `tests/test_attack_helicopter_v13_capture.gd`: trece capturas originales de Godot en 960×720: intacto, impacto, macro de onda expansiva, humo, humo animado, explosión, crítico, fuego animado, destruido, caída parcial, caída final, macro de fragmentos de rotor y reparado.
- `tests/test_attack_helicopter_v9_studio.gd`: entradas interactivas del visor unificado y controles V13.
- `.github/workflows/a01-v13-damage-qa.yml`: pruebas y pruebas de render Godot 4.3, con evidencias PNG adjuntas a Actions.

## Publicación
Rama provisional [PR #476](https://github.com/edwinrodri12/Tarvoka/pull/476). El visor [GitHub Pages](https://edwinrodri12.github.io/Tarvoka/) es el sitio público del proyecto, **no evidencia de que V13 esté publicada**. Las capturas y tests se revisan antes de fusionar.

## Estado de validación
El módulo y las pruebas V13 están implementados en la rama. **V13 dispone ya de una ejecución real aprobada en CI Godot 4.3, pero no está publicada** y revisión de los once fotogramas; las comprobaciones V12 anteriores no equivalen a haber probado V13. Se añade disparador de push a la rama de arte como respaldo a la PR draft.

## Revisión de la siguiente prioridad
Se reforzó el flujo V12 probado para ejecutar también pruebas V13 y exportar sus 13 imágenes originales de Godot. Las verificaciones ahora incluyen mallas cerradas de rotores principal/cola, puntos de salida junto a los bujes, fases inicial y final de la trayectoria, anillo expansivo y persistencia del daño al cambiar de facción en el Estudio 3D. **Las trece capturas nativas ya se produjeron y archivaron en GitHub Actions; la rama permanece draft hasta decisión de publicación.**

## V13 — Revisión de persistencia de destrucción
El Estudio ahora conserva la posición final de caída (altura inferior y alabeo de 70°) al detenerse la animación, cambiar la cámara, inspeccionar detalles o cambiar de facción. La única acción que restablece la aeronave y sus rotores es **Reparar helicóptero**. Llegar al nivel 4 desde **Siguiente nivel de daño** inicia directamente la animación de destrucción; una unidad destruida no vuelve a volar o disparar sin reparar. El control de detener conserva el estado destruido.

Pruebas estáticas de integración: 11/11 invariantes sobre presencia de controles, retención del estado, animación original y CI de 13 capturas. Se añadieron pruebas de integración Godot al archivo `tests/test_attack_helicopter_v9_studio.gd` para comprobar el aterrizaje de los restos, su conservación al girar e inspeccionar la cámara y el cambio de facción. **Completado:** prueba de Godot 4.3 y 13 capturas nativas aprobadas; continuar revisión artística y publicación en un paso separado.

## V13 — Fragmentos desacoplados del fuselaje
Los fragmentos se fijan a un marco del mundo en el instante de destrucción: la aeronave puede inclinarse y caer sin arrastrar consigo las aspas rotas. El modelo ubica los restos junto al terreno (centros locales ~0.09–0.12 antes de escala/offset originales), mientras que en reparación vuelve a vincular el contenedor de restos al fuselaje y lo oculta. El Estudio primero inserta el nuevo modelo recoloreado en el viewport, configura su orientación y **después** reconstruye el estado destruido, para evitar coordenadas globales obsoletas.

Se ampliaron las pruebas Godot V13 y del Estudio para exigir anclaje independiente, posición baja de fragmentos, retención durante giro y reconstrucción tras cambiar de facción. Las capturas de V13 están disponibles como artefacto nativo de Godot; se consultaron las ejecuciones de tipo push mediante la colección GitHub Actions, no solamente las asociadas a pull requests.

## Validación efectiva — 17 de noviembre de 2026
Se reubicó esta entrega en la nueva [PR #522](https://github.com/edwinrodri12/Tarvoka/pull/522), creada desde main actual y fusionando los cambios propios del A01 con las mejoras concurrentes de G13/APC. La PR de respaldo #476 permanece sin fusionar.

- **V11**: prueba de Godot nativa y capturas, aprobada.
- **V12**: prueba de holguras 8 facciones y 20 capturas de Godot, aprobada.
- **V13**: fallo inicial detectado por CI (recorrido insuficiente de humo). Se corrigió aumentando el desplazamiento vertical de las nubes de 0,19 a 0,40 en unidades locales. [Ejecución V13 exitosa](https://github.com/edwinrodri12/Tarvoka/actions/runs/44137497098) con las 13 capturas nativas de Godot 4.3; artefacto `tarvoka-a01-v13-real-godot-13-frame-review` (ID 14352951739).
- **Estudio 3D V9**: la primera prueba reveló una interfaz antigua que esperaba un botón de ataque obsoleto. Se actualizó el catálogo unificado de A01 para exponer vuelo, ataque, impacto, onda, niveles de daño, destrucción y reparación. [CI del Estudio aprobada](https://github.com/edwinrodri12/Tarvoka/actions/runs/44138297119).
- **Android debug APK**: [compilación de integración aprobada](https://github.com/edwinrodri12/Tarvoka/actions/runs/44138296832), sin publicación automática de V13.

La URL pública del Estudio sigue siendo https://edwinrodri12.github.io/Tarvoka/, pero puede mostrar código anterior mientras la PR está en borrador. La aprobación de CI **no equivale** a fusión ni publicación.

## A01 V13.1 — Acabado artístico del motor: humo suave y llamas de malla

Se mejoró el efecto visual del daño sin cambiar reglas de juego ni la geometría base aprobada:

- **Humo:** ocho planos `QuadMesh` posicionados en espacio 3D con transparencia radial irregular generada programáticamente en una textura compartida de 64 × 64 píxeles. El humo ahora tiene bordes difusos, deriva lateral y hacia arriba y se desvanece al completar cada ciclo; no proyecta sombras artificiales.
- **Fuego:** seis lenguas 3D fabricadas con `SurfaceTool`, con secciones cónicas curvas, color por vértice (amarillo, naranja, rojo) y emisión moderada. Cada lengua tiene oscilación propia.
- **Rendimiento:** el humo pasa de mallas volumétricas repetidas a ocho quads ligeros; una sola textura compartida por modelo. Los efectos siguen cargándose exclusivamente en el nivel de arte del visor, no en el LOD táctico móvil ≤10.
- **Validación:** la prueba nativa de Godot V13 [44142050983](https://github.com/edwinrodri12/Tarvoka/actions/runs/44142050983) confirmó las ocho facciones, humo suave con `ImageTexture` y billboards 3D, seis lenguas cónicas y compatibilidad con los cinco niveles de daño. Se generaron 13 capturas originales para revisar el acabado. La PR #522 continúa en borrador; estas mejoras todavía no están confirmadas en la versión pública.

## V13.3 — Silueta final del helicóptero destruido

Revisión realizada a partir de las 15 capturas nativas V13.2, incluido el polvo corregido ([Actions 44146894538](https://github.com/edwinrodri12/Tarvoka/actions/runs/44146894538)): se descubrió una marca plana y oscura que flotaba sobre el helicóptero destruido. El problema se debía a `A01V13_CarbonizacionFinal`, creada en la jerarquía de fragmentos **separados del fuselaje**. Su posición ahora se reemplaza por `A01V13_CarbonizacionFijaMotor`, que pertenece a un grupo adherido al casco.

En el nivel 4 (destruido), y exclusivamente para el visor hero:
- La cúpula de vidrio intacto V2 se oculta y deja paso a cuatro paneles triangulares 3D astillados y seis grietas superficiales, sin retirar el modelo original.
- El aro protector V3 y los cuatro marcadores V7 completos dejan de verse; se presenta un conjunto de tramos cortos retorcidos, con separaciones visibles.
- Dos chapas abolladas y costuras abiertas evidencian el daño lateral de la aeronave.
- La capa `A01V13_CabinaAstilladaYProteccionRota` continúa unida al casco al caer, mientras que los fragmentos de rotor y el polvo permanecen en el mundo.
- Reparar recupera vidrio, aro y marcadores originales. Los estados 0–3 conservan la V12.1 aprobada.

**Rendimiento:** se incorporan mallas sencillas, sin efectos adicionales en la versión de batalla LOD ≤10; no cambia movilidad, daño, alcance, economía, munición ni interfaz.

**Estado de QA:** se ampliaron las aserciones sobre los ocho ejércitos y las capturas de inspección de 15 a **17**, con macros específicas de parabrisas y aro de cola dañados. Las pruebas de esta revisión V13.3 siguen en cola de GitHub Actions; no considerar aprobada esta nueva revisión hasta finalizar la ejecución. Los 15 renders V13.2 anteriores sí fueron aprobados.

## V13.4 — Cabina y motor: deformaciones finales del modelo destruido

Tras revisar las **17 capturas nativas** de la V13.3 ([Godot aprobado](https://github.com/edwinrodri12/Tarvoka/actions/runs/44149125351)), se añadió un segundo pase de detalle para diferenciar mejor el estado totalmente destruido de los daños leves:

- Motor: cavidad oscura, dos tapas levantadas, bordes de metal expuesto y seis cicatrices en el blindaje lateral. Mallas `BoxMesh` y `CylinderMesh` nativas.
- Cabina: los marcos continuos `A01_V2_Costilla_*`, `A01_V2_MarcoLong_*` y `A01_V2_MarcoOp_*` se ocultan solo en fase 4 y son reemplazados por tramos cortos torcidos con separaciones reales.
- Reparación: restaura completamente los marcos y cristales intactos, el aro de cola y ambos rotores. Las piezas dañadas se conservan como esculturas independientes ocultas fuera del estado 4.
- Capturas Godot: se conservan 17 escenas; las macros del parabrisas y de la cola se reposicionan relativas al estado final del fuselaje para permitir juzgar los bordes y materiales sin cambiar la cámara del juego.
- Rendimiento: cambios exclusivos del modelo de inspección de alta calidad `art_level>=13`; el LOD10 Android de batalla y todos los valores de combate siguen intactos.

**Validación:** [primera ejecución V13.4 aprobada](https://github.com/edwinrodri12/Tarvoka/actions/runs/44151582359) y [segunda ejecución de Godot V12 + V13 aprobada](https://github.com/edwinrodri12/Tarvoka/actions/runs/44151723612). Esta segunda ejecución incluye las aserciones del nuevo metal y marcos, preserva el cañón V12.1, verifica las ocho facciones y vuelve a generar las **17 capturas reales**; los acercamientos de cabina y cola usan el encuadre relativo al fuselaje. El acabado V13.4 queda como **candidato artístico validado**; PR #522 sigue sin fusionarse y el visor público no está confirmado.

## V13.5 — Lectura de daño a distancia, candidato de aprobación artística

La revisión de la V13.4 desde el encuadre general reveló que el fuselaje pálido y la cabina seguían pareciendo poco dañados, aunque los fragmentos de rotor y el aro de cola mostraban la destrucción. Se ha añadido una capa de geometría nativa `A01V13_ContrasteDañoTotal` **exclusiva del estado 4**:

- Apertura oscura de cabina formada por dos polígonos 3D de superficie irregular, visibles desde lejos.
- Tres láminas supervivientes de vidrio azul con triangulación real, sin reconstruir la cúpula original.
- Dos rasgaduras laterales con planos negros, aleación desgarrada y bordes metálicos que capturan luz.
- Huellas de quemadura traseras sin afectar las insignias de facción.

Se mantienen íntegros el casco V12.1, el armamento, el rig, los niveles 0–3, las estadísticas y el LOD ligero Android (sin nuevos efectos de daño); reparación sigue restaurando el helicóptero intacto. Se añadieron comprobaciones de visibilidad/material por las ocho facciones.

Se amplió el protocolo visual de 17 a **18 imágenes reales de Godot 4.3**, incorporando `a01_v13_07e_contraste_vista_general.png`, una perspectiva oblicua que permite decidir sobre las heridas sin macro. Los flujos V12 y V13 de la rama ya exigen exactamente 18 imágenes. Hasta recibir el resultado satisfactorio de esa ejecución, V13.5 permanece como candidato no publicado.

Ver [PR #522](https://github.com/edwinrodri12/Tarvoka/pull/522). El [visor 3D público](https://edwinrodri12.github.io/Tarvoka/) puede seguir sirviendo la versión anterior porque la rama aún no se ha integrado.
