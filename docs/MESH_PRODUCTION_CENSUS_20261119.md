# TARVOKA — censo reproducible de geometría de escenas

Se incorpora `tests/audit_production_scene.gd` a la rama de la PR #622 para permitir auditar cualquier escena `.tscn` real sin cargarla en el árbol activo del juego.

## Ejecución

```sh
godot --headless --path . --script res://tests/audit_production_scene.gd -- res://scenes/UnitArtStudioWeb.tscn
```

El script valida argumento, existencia de `PackedScene` y carga, llama a `MeshBudgetAudit.inspect_packed_scene()` y emite una línea `MESH_PRODUCTION_CENSUS` con JSON que contiene ruta, triángulos, instancias, superficies, mayor contribuyente y advertencias. Códigos de salida 2, 3 y 4 para argumentos inválidos, escena inexistente o carga fallida. La escena sugerida es una candidata de inspección, no una medición realizada. Para medir una unidad individual, pasar su escena real `.tscn` una vez identificada.

**Limitaciones:** no se han ejecutado Godot 4.3 ni CI para este nuevo script; no existe aún recuento observado. Una escena que construya modelos dinámicamente en `_ready()` puede producir un censo incompleto al instanciarse fuera del árbol. Los triángulos no equivalen a FPS. Android físico: **NO EJECUTADO EN DISPOSITIVO**. QA visual: **PENDIENTE DE REVISIÓN VISUAL**. No se modifican reglas tácticas ni modelos.

**Siguiente:** comprobar CI de PR #622, ejecutar el comando contra una escena de producción y contrastar el resultado con el árbol real antes de decidir una reducción geométrica.

## Regresión automática de la interfaz CLI (2026-11-19)

La rama de PR #622 incluye `tests/fixtures/mesh_budget_box.tscn`, escena determinista con una `BoxMesh` de 12 triángulos. `.github/workflows/mesh-budget-audit.yml` ahora ejecuta `tests/audit_production_scene.gd` contra esta escena y valida mediante Python que exista exactamente un JSON `MESH_PRODUCTION_CENSUS`, con `triangles=12`, `instances=1`, `mesh_nodes=1` y la ruta correcta. Este smoke test cubre la carga real de `PackedScene` y la CLI, además del test unitario del auditor. **No equivale al censo de un activo comercial ni a una medición de FPS.**

**Estado al registrar el cambio:** commits de fixture y workflow confirmados; ejecución CI del nuevo head NO CONFIRMADA; Android físico NO EJECUTADO EN DISPOSITIVO; revisión visual PENDIENTE. Siguiente: revisar CI y seleccionar una escena real, especialmente una que cree geometría en tiempo de ejecución, para auditarla dentro del árbol activo.

## Validación defensiva del resultado (2026-11-19)

La CLI ahora devuelve código 5 cuando el informe no contiene contadores enteros no negativos (`triangles`, `instances`, `mesh_nodes`, `surfaces`, `largest_mesh_triangles`), carece de arreglo `warnings`, declara una malla mayor que el total o declara más nodos de malla que instancias. Esto evita publicar JSON de éxito con métricas incoherentes. El smoke test existente de `mesh_budget_box.tscn` ejercita la ruta válida; aún falta una regresión específica de salida 5 con auditor simulado. **Godot 4.3/CI del nuevo commit: NO CONFIRMADO; Android físico: NO EJECUTADO EN DISPOSITIVO.**
