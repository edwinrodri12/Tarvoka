# TARVOKA G13 — V51: techo blindado integrado y visera frontal

**Fecha:** 18 de noviembre de 2026. **Tipo de entrega:** modelado 3D nativo de Godot 4.3/GDScript en `edwinrodri12/Tarvoka`. No se ha generado ninguna ilustración para sustituir al modelo real.

## Evidencia real revisada

La ejecución **#1535** de `Publish TARVOKA native 3D art studio` terminó correctamente (build y deploy). Su artefacto `tarvoka-g13-v50-native-360-design` contiene **11 capturas PNG generadas por Godot**, que se revisaron desde frente, laterales, tres cuartos, techo, bajos y LOD táctico. El modelo V50 ya enseña mejor las ruedas, pintura y la estación de dos autocañones. Sigue siendo evidente una cubierta de cabina demasiado extendida por delante del parabrisas: su visera se lee como una placa grande y delgada poco conectada con el techo.

## Corrección estructural V51

`scripts/ui/G13CabRoofIntegrationV51.gd` sustituye solamente **dos recursos `ArrayMesh` sobre sus nodos originales**:

1. **Techo de cabina**: la cubierta V49/V50 de cinco secciones/80 triángulos se convierte en una cubierta cerrada de **siete secciones/112 triángulos**, con biseles de transición más graduales desde el perímetro reforzado V37 hasta la coronación. Se conserva el origen (0, 1.4, -0.68), sin mover cristales ni pivotes. El extremo frontal nominal pasa de aproximadamente Z=-1.239 a Z=-1.177, un retranqueo de unos **62 mm** en la vista principal. La cubierta deja de avanzar tanto por encima del parabrisas.
2. **Visera blindada doble V45** (`G13_V45_ClosedArmoredWindshieldBrow`): se conservan sus **32 triángulos** originales, materiales y marcas de facción. Únicamente se remapea su borde delantero de Z=-1.186 a Z=-1.161 para sentarlo junto al nuevo techo; el borde posterior Z=-1.068 sigue sin cambios.

Esto mantiene la proporción de la cabina, los cristales biselados V50, el radar plegable, dos cañones automáticos sin misiles, color de las ocho facciones y todas las animaciones. **Cero nuevos nodos de dibujo** y ninguna modificación a reglas de combate o a los demás vehículos.

## Integración

- `scripts/ui/UnitModels3D.gd`: aplica V51 tras V50 tanto a **LOD13** como a **LOD8**.
- `scripts/ui/BastionStudioAdapter.gd`: selector V51 y botones **Techo y visera integrados** / **Comparar con V50**, con restauración de los dos recursos sobre la misma escena.
- `tests/test_g13_studio_web_v1.gd`: valida 112/32 triángulos, conservación de nodos, alternancia reversible, LOD13/LOD8 y protección de otras unidades.
- `tests/test_g13_v51_visual_capture.gd`: prepara 11 capturas reales (8 hero, 2 táctico y una comparación de techo V50), archivadas como `tarvoka-g13-v51-native-360-design`.
- `.github/workflows/tarvoka-3d-pages.yml`: utiliza el nuevo capturador en el mismo trabajo nativo, sin relajar bloqueos previos de publicación.

## Pendiente de aprobación

El código, la integración y la captura V51 están guardados, pero **su render final requiere una ejecución verde propia**. Las capturas V50 prueban el problema que se abordó; no confirman por anticipado la estética de V51. La siguiente prioridad debe empezar por inspeccionar el artefacto V51 y corregir solo defectos visuales reales (especialmente las juntas con V37 y los extremos del parabrisas).
