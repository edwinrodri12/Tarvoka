# TARVOKA — HAT-29 A01 V14.9: asientos reales y revisión 360° del rotor

## Prioridad
Resolver la posible apariencia de **bieletas o amortiguadores suspendidos** en la raíz de las cuatro palas. Se conserva todo el modelo V1–V14.8, incluidos los ocho colores de facción moderados, armamento, vuelo, humo, impactos, destrucción V13, luces nocturnas y los controles del mismo visor 3D.

## Inspección geométrica previa
En el rotor V3 original, el bisel de cada raíz ocupa el intervalo Y -0.035..+0.035 cerca de Z=-0.225. El perfil aerodinámico V3, lejos del bisel, tiene espesor real Y +/-0.0185 alrededor de Z=-0.40. Los ensamblajes V14.7 y V14.8 permanecen enlazados a sus pivotes, pero sus respectivos apoyos anteriores comenzaban a una altura superior a estas superficies, por lo que podían percibirse como suspendidos al inspeccionarlos desde ángulos bajos.

## Nuevo modelado 3D nativo
`scripts/ui/AttackHelicopterRotorAnchorsV149.gd`, aplicado **después** de V14.8 únicamente cuando `UnitModels3D.build("attack_heli", faccion, true, 14)`:

- **Cuatro asientos por pala** (16 en total): dos en el bisel de raíz y dos en la superficie aerodinámica que comienza fuera de él. Su espesor intersecta ligeramente las superficies originales para evitar separación óptica.
- **Cuatro puentes por pala** (16 en total), con conexión real entre asientos y horquillas existentes V14.7 (+X)/V14.8 (-X). No se agregan pistones paralelos ni una segunda bieleta de paso.
- **Ocho cabezas de perno por pala** (32 en total), con metal PBR discreto. Las piezas son volúmenes `BoxMesh` y `CylinderMesh`, no trazos decorativos.
- Cada conjunto es **hijo de `A01_AspaPortante_0..3`** y hereda su giro y desprendimiento de la animación V13. El fuselaje, el rotor, las palas originales y la lógica de movimiento no se modifican.
- Aplicación idempotente con comprobación previa de todos los pivotes y del arte V14.7/V14.8. No hay nuevos puntos de luz ni cambios de pintura; el detalle se excluye del LOD Android ≤10.

## Estudio 3D unificado
En **Unidades → HAT-29 → Detalles** se incorporan:
- `V14.9: asiento de bieleta`: ángulo desde -X hacia la raíz.
- `V14.9: anclaje hidráulico`: ángulo desde +X hacia el apoyo exterior.

No se crea una web nueva: `.github/workflows/tarvoka-3d-pages.yml` contiene el nuevo script en los archivos incluidos y en el ensamblaje real del proyecto WebGL.

## Auditoría 360 preparada
`tests/test_attack_helicopter_v14_capture.gd` incorpora:
- 16 nuevas vistas reales de Godot: **8 azimuts (45° de separación) por 2 elevaciones** del rotor del mismo helicóptero.
- 2 macros adicionales de anclaje mecánico izquierdo y derecho.
- Total de regresión previsto: **63 PNG** (45 anteriores + 18 nuevos).

`tests/test_attack_helicopter_v14.gd` verifica 8 facciones, raíz nativa, asientos intersecando las superficies correctas, puentes, idempotencia y ninguna pieza en LOD10. `tests/test_attack_helicopter_v9_studio.gd` verifica las dos cámaras conservando la instancia.

`.github/workflows/a01-v14-hat29-visual-qa.yml` está actualizada para exigir las 63 capturas y las comprobaciones nativas. **No se declara completada la validación visual hasta comprobar un run verde y revisar sus capturas PNG reales.**

## Estado
**V14.9 implementada en código fuente; aprobación artística final pendiente de revisión visual real**. La siguiente tarea es abrir los resultados nativos, identificar cualquier intersección, y efectuar un pulido local si procede.
