# TARVOKA — G16 V5: kit de abastecimiento 3D desplegable (en desarrollo)

**Estado:** trabajo de desarrollo de la **G16**, siguiente unidad después de la **G15 V11C**, que sí quedó finalizada y aprobada. La G16 **no está terminada** ni aprobada visualmente. El proyecto emplea el mismo TARVOKA Estudio 3D, sin un visor nuevo.

## Trabajo V5

- **Carrete de suministro real** sobre el lateral del vehículo: respaldo, carcasa y junta de goma cerrados con mallas BoxMesh y materiales PBR opacos.
- **Manguera articulada:** seis segmentos cilíndricos en la versión hero (LOD13) y tres en Android (LOD8). Se mueve en un pivote Node3D y termina en acoplamiento metálico con junta y señalización del color de facción original.
- **Tapa lateral de servicio:** sólida, con junta y marca de facción; gira al ejecutar las poses `resupply`, `camp`, `deploy`, `pack` y `unload`. En marcha y reposo el conjunto vuelve a su posición.
- **Pintura de las ocho facciones**, vidrio original y 6 ruedas intactos. No se sustituye ni afecta a las capas V1–V4.
- **Comparación histórica:** botones del Studio `g16_v5_on` / `g16_v5_off` permiten retirar el nuevo equipo para comparar con la G16 V4, manteniendo las opciones V1–V4 y animaciones.
- **Sin cambios de juego:** el sistema `scripts/core/Logistics.gd` sigue siendo el único dueño de munición, combustible y límites de abastecimiento. El nuevo despliegue de mangueras es exclusivamente **3D visual**; no crea instalaciones o reparaciones permanentes.

## QA e integración

- `tests/test_g16_v5_service_hardware.gd`: construye 8 facciones × dos LOD, verifica grupo/cierre/materiales y secuencia de despliegue, repliegue, apertura de cofres V3 y 4 capturas reales Godot con manguera guardada/desplegada.
- `.github/workflows/g16-v1-native-logistics-qa.yml`: mantiene todas las regresiones V1–V4 e incorpora la nueva prueba V5.
- `.github/workflows/tarvoka-3d-pages.yml`: incorpora la G16 V5 al mismo Studio WebGL, exige importar su script, sus controles y ejecutar la prueba nativa antes de exportar.

**Condición de aprobación:** compilar sin errores, revisar las capturas del visor compartido y obtener aprobación explícita sobre acabados. No marcar G16 FINAL por el solo hecho de integrar V5.
