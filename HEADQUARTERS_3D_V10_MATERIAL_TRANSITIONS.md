# TARVOKA · Cuartel General V10 — superficies y transiciones constructivas

## Alcance artístico

No basta con superponer texturas procedurales: V10 añade **geometría 3D real de los encuentros** entre hormigón, acero, vidrio y cubiertas. Esta pasada continúa el diseño aprobado V4–V9 y preserva exactamente la paleta/escudos de las ocho facciones.

- **Fachada:** paneles de hormigón prefabricado individualizados y achaflanados con juntas profundas oscuras, sellos de dilatación, cornisas y cantoneras en metal distinto. Uniones y sombras físicamente producidas por volumen.
- **Cristal del puente de mando:** cinta oscura de sellado alrededor del vidrio, segundo panel laminado, remate inferior y acento ligero de reflejo. Se limita a los dos paños laterales, sin cubrir el escudo central.
- **Azoteas:** juntas termosoldadas, perfiles de cinc, encuentros de base HVAC/cubierta y rejillas de extracción con profundidad; desgaste contenido junto a los desagües y anclajes.
- **Daño:** el panel izquierdo afectado **se oculta y se reemplaza** por hueco oscuro, fragmentos desiguales, tres armaduras expuestas y un fragmento desprendido en el suelo; la fachada sana no permanece intacta debajo.
- **Destrucción:** restos independientes de láminas de cinc y varilla doblada, sin recrear estructuras íntegras en el estado destruido.
- **Costo visual:** microtornillería y gotas de desgaste visibles solo a escala cercana; componentes principales siguen en todas las escalas.

## TARVOKA Estudio 3D

En EDIFICIOS 3D → Cuartel General: V10 activada por defecto. Interruptor **«Uniones y superficies V10 (comparar con V9)»** permite revisión desde la misma cámara. Las ocho tarjetas con escudos oficiales y el menú desplegable funcionan tanto en UNIDADES 3D como en EDIFICIOS 3D; la selección persiste al cambiar de pestaña.

## QA y exportación

`tests/test_headquarters_v10_surfaces.gd`: tres niveles, geometría de paneles/realces, PBR con albedo/normal/rugosidad, detalles adaptativos, cuatro estados, grieta con acero expuesto, ocho emblemas exactos, regreso a tanque y screenshot de GPU de dos versiones con cámara idéntica.

Artefactos:
- `artifacts/tarvoka_hq_v9_vs_v10_surface_realism.png`
- `artifacts/tarvoka_hq_v10_material_junction_close.png`
- `artifacts/tarvoka_hq_v10_exposed_rebar_damage.png`
- `artifacts/TARVOKA_CuartelGeneral_V10_Nivel3_Editable.glb` (además de los históricos V4/V7/V8/V9 que se exportan sin contaminarlos con V10).

**Integración:** solo material artístico/visor. No se modifican parámetros tácticos, IA, reglas, número de casillas, colisiones, guardados, rendimiento de unidades ni historia. La publicación web debe verificar `deploy-pages=success` antes de declararla disponible.
