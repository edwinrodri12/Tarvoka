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

## 2026-11-19 — casos de instancia invisible y escena anidada
- Regresión nueva: `visible_instance_count = 0` excluye los tres cubos del MultiMesh del total (quedan 14 triángulos, tres instancias y tres nodos con malla); evita sobrecontar vegetación completamente oculta.
- Regresión nueva: `Node3D` contenedor con `MeshInstance3D` hijo debe contar 12 triángulos y una instancia; verifica recorrido de jerarquías sin exigir malla en raíz.
- Commit de pruebas: `3124387b506f077e919ad5c9c7529feff0796a5b`. Godot 4.3/CI del nuevo commit: NO CONFIRMADO al escribir. Android físico: NO EJECUTADO EN DISPOSITIVO. Revisión visual: PENDIENTE DE REVISIÓN VISUAL.

## 2026-11-19 — corrección del entorno de CI
- CI [44594854796](https://github.com/edwinrodri12/Tarvoka/actions/runs/44594854796): **FALLÓ** pese a imprimir `MESH_BUDGET_AUDIT_PASS`: el backend `--headless`/dummy de Godot 4.3 registró `ERROR: Parameter "m" is null` en `mesh_get_surface_count` al trabajar con MultiMesh. El workflow detectó correctamente el error y salió con código 1; el marcador PASS aislado no certifica éxito.
- El workflow ahora usa `xvfb-run` con `--rendering-driver opengl3`, igual que las pruebas GPU de terreno; conserva timeout, detección estricta de errores y marcador de salida. **CI del commit correctivo: NO CONFIRMADO** hasta observar ejecución nueva. No se modificaron conteos ni reglas de juego.
- Android físico: **NO EJECUTADO EN DISPOSITIVO**; revisión visual: **PENDIENTE DE REVISIÓN VISUAL**. Siguiente: verificar CI nuevo y medir un modelo real del catálogo.

## 2026-11-19 — auditoría directa de escenas PackedScene
- Nueva API `MeshBudgetAudit.inspect_packed_scene(scene, triangle_warning)` instancia temporalmente la escena sin añadirla al árbol de juego, contabiliza la geometría con `inspect` y libera la instancia. Permite auditar escenas de producción cuando se confirme su ruta, sin interferir con gameplay.
- Regresión en `tests/test_mesh_budget_audit.gd`: escena empaquetada con BoxMesh (12 triángulos), alerta con umbral 11, árbol activo sin alteración y escena nula con aviso.
- Commits `87641cbb9ec0e5a1975edb92307c5828e86123a7` y `e81169df4e74e75ab43e79f9ba0179ee465d061b`. CI del cambio: NO CONFIRMADO al registrar. Android físico: NO EJECUTADO EN DISPOSITIVO. Revisión visual: PENDIENTE DE REVISIÓN VISUAL.

## 2026-11-19 — repetición de PackedScene
- Regresión adicional: tres auditorías sucesivas de la misma escena empaquetada deben producir 12 triángulos, una instancia, cero alertas al umbral 12 y ninguna alteración de los hijos del árbol de prueba.
- Commit de prueba `f477a8b3b928e9fdeb2464f300ea651491a764da`. Estado Godot 4.3 de este commit: NO CONFIRMADO; Android físico: NO EJECUTADO EN DISPOSITIVO; revisión visual: PENDIENTE DE REVISIÓN VISUAL.
- Próximo paso: medir una escena real y registrar ruta, SHA y recuentos, sin atribuir FPS a la métrica geométrica.


## 2026-11-19 — Identificación del mayor contribuyente
`inspect()` y `inspect_packed_scene()` devuelven ahora `largest_mesh_triangles` y `largest_mesh_path` (nombre del nodo si no está dentro del SceneTree). El recuento incluye multiplicidad visible de MultiMesh; no es una medición de GPU/FPS. Empates conservan el primer nodo visitado. Regresiones añadidas para BoxMesh, MultiMesh×3 y cero instancias visibles. Godot/CI del commit nuevo: pendiente; Android físico: NO EJECUTADO EN DISPOSITIVO. No alterar presupuestos de producción sin medir escenas reales.

## 2026-11-20 — Integridad de reportes vacíos
- `is_valid_report` rechaza reportes sin instancias que declaran triángulos, superficies o nodos de malla.
- Rechaza una malla mayor con triángulos positivos y ruta vacía, y advertencias cuyo elemento no sea texto.
- Tres regresiones añadidas a `tests/test_mesh_budget_audit.gd`; ejecución Godot/CI del nuevo commit aún no confirmada. Android físico: NO EJECUTADO EN DISPOSITIVO. Revisión visual: PENDIENTE.
- Próximo paso: medir una escena real del catálogo y comparar el censo con su estructura.
