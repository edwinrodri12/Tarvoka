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
