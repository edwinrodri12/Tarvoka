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
