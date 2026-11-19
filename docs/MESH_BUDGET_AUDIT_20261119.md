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

## Diagnóstico y corrección 2026-11-19
- CI inicial [run 44562280021](https://github.com/edwinrodri12/Tarvoka/actions/runs/44562280021): **FALLÓ**. Godot 4.3 reportó `Nonexistent function 'surface_get_primitive_type' in base 'BoxMesh'`; la aserción posterior falló y el job terminó por timeout 124. No etiquetar ese run como aprobado.
- Corrección en la misma PR: consultar `surface_get_primitive_type()` exclusivamente para `ArrayMesh`; `PrimitiveMesh` como `BoxMesh` proporciona triángulos y se contabiliza mediante sus arrays. Prueba adversarial añadida con `ArrayMesh` de líneas para asegurar que no infla el recuento.
- CI de los commits correctivos: **NO CONFIRMADO** al registrar este documento. Android físico: **NO EJECUTADO EN DISPOSITIVO**. Revisión visual: **PENDIENTE DE REVISIÓN VISUAL**.
- Pendiente: comprobar el nuevo workflow, corregir cualquier error restante y ejecutar auditoría sobre un activo de producción real. No fusionar sin CI verde.

## 2026-11-19 — regresión de geometría indexada
- `tests/test_mesh_budget_audit.gd` comprueba un quad indexado (4 vértices, 6 índices): exactamente 2 triángulos, no 1; verifica el umbral inclusivo (26 sin alerta, 25 con alerta) junto a mallas primitivas y líneas.
- Commit de prueba: `533ea79380148cbeb6a8c1b929477ac8102ea85a`. La ejecución CI de este commit está pendiente de confirmación; el CI verde del commit anterior no lo valida.
- Android físico: NO EJECUTADO EN DISPOSITIVO. Inspección visual: PENDIENTE DE REVISIÓN VISUAL. No se modifica geometría de producción ni reglas tácticas.
