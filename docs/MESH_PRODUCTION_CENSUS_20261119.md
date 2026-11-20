# TARVOKA — censo reproducible de geometría de escenas

Se incorpora `tests/audit_production_scene.gd` a la rama de la PR #622 para permitir auditar cualquier escena `.tscn` real sin cargarla en el árbol activo del juego.

## Ejecución

```sh
godot --headless --path . --script res://tests/audit_production_scene.gd -- res://scenes/UnitArtStudioWeb.tscn
```

El script valida argumento, existencia de `PackedScene` y carga, llama a `MeshBudgetAudit.inspect_packed_scene()` y emite una línea `MESH_PRODUCTION_CENSUS` con JSON que contiene ruta, triángulos, instancias, superficies, mayor contribuyente y advertencias. Códigos de salida 2, 3 y 4 para argumentos inválidos, escena inexistente o carga fallida. La escena sugerida es una candidata de inspección, no una medición realizada. Para medir una unidad individual, pasar su escena real `.tscn` una vez identificada.

**Limitaciones:** no se han ejecutado Godot 4.3 ni CI para este nuevo script; no existe aún recuento observado. Una escena que construya modelos dinámicamente en `_ready()` puede producir un censo incompleto al instanciarse fuera del árbol. Los triángulos no equivalen a FPS. Android físico: **NO EJECUTADO EN DISPOSITIVO**. QA visual: **PENDIENTE DE REVISIÓN VISUAL**. No se modifican reglas tácticas ni modelos.

**Siguiente:** comprobar CI de PR #622, ejecutar el comando contra una escena de producción y contrastar el resultado con el árbol real antes de decidir una reducción geométrica.
