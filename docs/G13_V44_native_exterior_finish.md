# G13 V44 — acabados de blindaje y facción directamente en el modelo 3D

**Implementación real (Godot 4.3/GDScript):** `scripts/ui/G13ExteriorFinishV44.gd` opera sobre la G13 nativa. No es una imagen, mockup, escena alternativa ni textura prerenderizada. La G13 todavía no se declara aprobada y esta iteración no altera jugabilidad.

## Cambios de arte visibles
1. **Dos blindajes laterales facetados en volumen** (un `ArrayMesh` de 40 triángulos) con borde acero, entre 0.920 y 1.091 m de altura: `G13_V44_FacetedSideArmor`.
2. **Dos placas interiores pintadas con el color real de la facción seleccionada**: malla cerrada de cinco lados por costado, 32 triángulos entre ambas, sobre el blindaje, con borde de acero a la vista: `G13_V44_SculptedFactionFlanks`.
3. **Cuatro bandas curvas de esmalte de facción sobre los guardabarros delanteros y traseros**, siguiendo el contorno semicircular y sin ocupar el neumático: `G13_V44_CurvedFactionFenderBands` (un `ArrayMesh` compartido de 200 triángulos, instanciado para ambos ejes).
4. **12 segmentos metálicos del collar de la torreta** en un `MultiMesh` bajo el nodo original rotatorio; giran con el arma y permiten leer mejor la unión de la torreta con el chasis: `G13_V44_RotatingTurretJointArmor`.
5. **Cuatro protectores pintados en ambos costados de la torreta**, también rotatorios: `G13_V44_FactionTurretGuards`.
6. **Ocho respiraderos reales del motor**, con volumen, en la cubierta posterior: `G13_V44_SculptedEngineDeckVents`.

El color se deriva del nodo original `G13_TurretFaction_1`; se aclara solo un 6.5% para visibilidad y se mantienen los demás paneles metálicos neutros. Cada facción conserva su identidad, sin introducir un color fijo ajeno.

## Integración
- `scripts/ui/UnitModels3D.gd`: `G13ExteriorV44.apply(model)` tras V42 en **LOD13 y LOD8**. La dependencia real es el pintado V32 y la jerarquía base, de manera que si falla un acabado decorativo V38–V42, V44 sigue pudiendo mostrarse.
- `scripts/ui/BastionStudioAdapter.gd`: selector V44 y opciones **Blindaje y pintura real 3D** / **Comparar con V43**, que muestran u ocultan solo estas seis piezas en el mismo visor.
- `tests/test_g13_studio_web_v1.gd`: obliga al montaje real del visor a comprobar los seis grupos de geometría, alternar sus visibilidades y validar que el acabado se genera también en LOD8.
- Se preservan los **dos cañones automáticos sin misiles**, las ocho facciones, los pivotes de rueda/canon/radar, los efectos y las estadísticas existentes. Son seis nodos de dibujo nuevos, sin luces.

## Estado de verificación
La presencia e integración del código pueden verificarse en GitHub. **No confundir con la publicación en GitHub Pages**: el workflow `tarvoka-3d-pages.yml` debe acabar correctamente con importación y pruebas Godot antes de afirmar que ya aparece en la URL pública. Los resultados de la captura V43 deben observarse en imágenes renderizadas para determinar problemas de superficie o acabado.

## Siguiente trabajo de arte
Comparar el modelo V44 renderizado en las ocho vistas reales. Según los defectos observados, profundizar en la calidad material del blindaje, neumáticos/cabina y torreta, sin agregar accesorios cosméticos sin una necesidad visual concreta. Aún no se considera a la par de las unidades finales aprobadas hasta verificar la representación 3D.
