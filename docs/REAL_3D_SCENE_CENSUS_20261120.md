# TARVOKA — censo de escenas 3D reales (2026-11-20)

Este procedimiento identifica escenas de producción sin inventar rutas. No mide FPS ni certifica un teléfono Android.

1. Desde la raíz del repositorio: `python3 -m unittest discover -s tests -p test_find_3d_census_scenes.py -v`.
2. Ejecutar `python3 tools/find_3d_census_scenes.py .` y registrar las rutas `res://` impresas. El detector excluye `tests`, `.godot`, `addons` y `.git`. Solo detecta escenas con nodos 3D declarados directamente en texto; las escenas con geometría únicamente instanciada mediante scripts pueden requerir inspección manual.
3. Para cada escena candidata elegida, ejecutar Godot 4.3 con un renderizador apropiado: `godot --headless --path . --script res://tests/audit_production_scene.gd -- res://RUTA_DE_ESCENA.tscn`.
4. Guardar la línea `MESH_PRODUCTION_CENSUS` como evidencia de triángulos, instancias, superficies y malla dominante. No confundir un censo de escena estática con una escena que genera modelos por script al iniciarse.
5. Comparar el mismo activo antes y después de una optimización; no establecer límites de FPS sin mediciones reales.

Estado al crear esta guía: herramienta y regresiones incorporadas a la rama de PR #622; pruebas Python/Godot y censo de escena real NO EJECUTADOS en esta ejecución. Android físico NO EJECUTADO EN DISPOSITIVO. Revisión visual PENDIENTE. No fusionar sin comprobar CI.
