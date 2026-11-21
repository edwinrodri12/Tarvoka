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
