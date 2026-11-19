# Auditoría reversible de geometría 3D — 2026-11-19

## Alcance
Utilidad independiente de inspección de escenas `scripts/tools/MeshBudgetAudit.gd`, sin modificar modelos, renderizado, reglas tácticas, facciones ni APK. Recorre nodos `MeshInstance3D` y `MultiMeshInstance3D`, cuenta triángulos de superficies TRIANGLES y multiplica por instancias visibles. Las superficies no triangulares no se cuentan como triángulos. El umbral de 12.000 es **una alerta de diagnóstico provisional**, no un presupuesto aprobado ni una medición de rendimiento Android.

## Reproducción
En Godot 4.3, desde la raíz del proyecto:
```sh
godot --headless --path . --script res://tests/test_mesh_budget_audit.gd
```
Se espera `MESH_BUDGET_AUDIT_PASS` y salida 0. El test comprueba caja de 12 triángulos, MultiMesh de 3 instancias (48 triángulos totales), límite visible de una instancia (24) y raíz nula. No hay integración con visor ni inventario de unidades hasta confirmar rutas de modelos reales.

## Estado y siguiente paso
- Escritura de archivos GitHub: registrada en rama aislada.
- Godot 4.3: **NO EJECUTADO** en esta ejecución.
- Android físico: **NO EJECUTADO EN DISPOSITIVO**.
- Estética y materiales: **PENDIENTE DE REVISIÓN VISUAL**.
- Siguiente: ejecutar test en CI, auditar una escena real de producción y comparar costos de geometría sin inferir FPS.
