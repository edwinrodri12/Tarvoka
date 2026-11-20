# TARVOKA — Taller de Blindados V2: acabados y maquinaria real

**Estado:** arte 3D editable en revisión, sin aprobación definitiva. Rama \`art/armored-workshop-v1-20261119\`. **No altera** la economía, reparación por ingenieros, suministro, construcción, combate, APK ni campamentos móviles.

## Qué cambia respecto a V1

1. **Cerramiento completo de costados y pared posterior:** chapa/concreto estructural físico; los ventanales son paneles PBR opacos y delimitados por marcos sólidos, sin transparencias accidentales.
2. **Accesos propios de blindados:** pórticos de acero; dos topes protectores por bahía; tambor y cinco lamas de persiana levantada; rayas de seguridad, luces, carteles y juntas de portón.
3. **Maquinaria específica:** bancadas de orugas con cinco rodillos mecanizados por bahía, placas de blindaje almacenadas, rieles de elevador, prensa hidráulica y herrajes de grúa. No es un almacén de suministro.
4. **Tejados:** nervaduras continuas, conductos con tres lamas, reflectores y piezas de metal galvanizado con rugosidades distintas.
5. **Colores oficiales:** banda elevada, escudos/placas de puerta y nervaduras en la paleta de las ocho facciones. Neutral gris pizarra, separado del amarillo.
6. **Daños progresivos:** D0/D1 muestran maquinaria y luces; D2 retiene la estructura y persianas golpeadas; D3 pierde piezas mayores y deja armaduras colapsadas; D4 conserva únicamente ruinas/escombros apoyados en el suelo, sin instalaciones intactas suspendidas.

## Integración de visualización

- Fuente V1 intacta: \`scripts/ui/ArmoredWorkshop3DV1.gd\`.
- Acabado V2: \`scripts/ui/ArmoredWorkshop3DV2.gd\`, construye V1 y añade nodos 3D editables en \`TallerBlindadosV1ModeloNativo/AcabadosYMaquinariaV2\`.
- Selección comparativa **V1/V2** en el visor compartido \`ArmoredWorkshopStudioAdapterV1.gd\` y en la escena individual \`ArmoredWorkshopDesignStudioV1.gd\`. V2 por defecto.
- Tres niveles, nueve variantes de color (ocho facciones y neutral), cinco estados de daño.
- Arte **no integrado todavía en \`main\` ni declarado disponible en el visor público** hasta validación, incorporación y despliegue.

## Validación

- \`tests/test_armored_workshop_v1_native.gd\`: regresión V1 original de 135 casos.
- \`tests/test_armored_workshop_v2_native.gd\`: 135 variantes V2, diferencia geométrica real, paleta oficial, paneles opacos, lamas, rodillos, prensas, estados D0–D4 y aislamiento de logística móvil.
- \`.github/workflows/armored-workshop-v2-art-qa.yml\`: Godot 4.3 con OpenGL real (Xvfb); **resultado no confirmado hasta ver SUCCESS**.

**Siguiente prioridad artística:** inspección visual de las seis cámaras en cada nivel, comprobar si hace falta más detalle en ventanales, marcos y maquinaria frente a edificios aprobados; corregir lo observado antes de cerrar el asset.


## Revisión estructural V2.1 — siguiente prioridad

En la revisión de geometría se detectaron y corrigieron los siguientes defectos:

- **Paredes laterales:** la franja entre el zócalo y la chapa dejaba una abertura aproximada de 10 cm. Ahora los paneles se superponen físicamente tanto al zócalo como al dintel superior, y las dos juntas verticales se sellan con perfiles sólidos.
- **Techo:** se añaden tapajuntas de longitud y anchura reales sobre los dos huecos entre los tres paneles de cada bahía intacta.
- **Fachada posterior:** cristales altos con marcos metálicos visibles desde el exterior; el revestimiento V2 anterior ocultaba las ventanas V1 tras la chapa.
- **Daño crítico D3:** la gran viga frontal intacta y los revestimientos laterales completos ya no quedan suspendidos: la viga se fragmenta y cae al piso; desaparecen los paneles altos que no tienen soporte.
- **Visor compartido:** se corrige la orientación real de FRENTE (−Z) y POSTERIOR (+Z), se distingue TECHO (78°) de la isométrica, y se añaden controles de acercar, alejar y restablecer zoom.
- **QA geométrica:** aserciones para solapes estructurales, ausencia de dintel intacto flotante en D3, marcos y cristales posteriores y sellado de cubierta.

### Evidencia visual reproducible

El script \`tests/capture_armored_workshop_v2_cameras.gd\` renderiza **24 PNG reales con Godot 4.3 OpenGL**:
- 3 niveles × 6 cámaras (isométrica, frente, posterior, dos laterales, techo) en D0.
- N3 neutral en D2, D3 y D4 desde isométrica y frente.

El workflow \`.github/workflows/armored-workshop-v2-art-qa.yml\` publica el artefacto \`armored-workshop-v2-six-camera-evidence\` con imágenes y \`manifest.json\`, **únicamente cuando GitHub Actions haya ejecutado**. La creación del script o la cola de GitHub **no equivale a inspección visual ni aprobación**. Revisión humana de PNG y renderizado del Web Studio todavía necesarios antes de fusionar PR.
