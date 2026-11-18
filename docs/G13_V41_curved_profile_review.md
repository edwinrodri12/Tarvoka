# TARVOKA G13 V41 — refinamiento de perfil curvo y vistas de diseño 360°

**Estado:** el arte V41 está implementado e integrado en el código nativo Godot, incluido el Estudio 3D. El modelo no está aprobado como final. Renderizado, compilación y publicación del visor no verificados en esta fase.

## Objetivo

Después de sustituir los guardabarros cuadrados de V2/V16 por los cuatro arcos V40, la prioridad es **refinar la silueta existente y permitir su inspección**, no añadir accesorios ni aumentar el coste gráfico.

## Cambios reales de geometría

1. **Perfilado de cuatro arcos de rueda.** V41 reemplaza, en el mismo `MultiMeshInstance3D` `G13_V40_CurvedOuterFenders`, la única malla `ArrayMesh` compartida entre los dos ejes. El perfil conserva doce bandas por lado, el hueco radial de 0,024 m frente a la cubierta del neumático de referencia, el diámetro de rueda y la posición de los ejes. Solo reduce gradualmente la anchura del borde exterior hacia los extremos del arco: de 1,005 m aproximadamente en la coronación a menos de 0,994 m cerca de los extremos. No modifica el volumen de la cabina ni cubre las placas de facción.
2. **Acabado de cuatro puntos de soldadura.** V41 reemplaza el recurso `BoxMesh` compartido por `G13_V40_SillFenderWelds` por un prisma hexagonal biselado y completamente cerrado, sin alterar sus cuatro instancias ni sus transformaciones. El resultado hace menos evidentes los cuadrados en las uniones de guardabarros/sello inferior.
3. **Cero draw calls nuevos por nodos:** se reutilizan las dos instancias `MultiMeshInstance3D` ya existentes y sus materiales. No se agregan mallas visibles, colisiones, partículas ni luces.

## Inspección 3D

El menú del G13 incorpora:

- **Perfil de ruedas afinado** y **Comparar con V40**: intercambian los dos recursos geométricos reales `Mesh` guardados en `tarvoka_g13_v41_original_and_refined_resources` en el mismo modelo.
- **Frente**, **3/4 delantero**, **Costado izquierdo**, **3/4 trasero**, **Parte trasera** y **Costado derecho**.
- **Ver techo** y **Ver bajos**, con rotación e inclinación de la escena. Estas son perspectivas para revisión artística manual: no capturas automáticas ni pruebas completadas.

La comparación asegura que el arco V40 vuelva a estar visible incluso si el usuario lo había ocultado mediante controles anteriores.

## Seguridad de integración

- `scripts/ui/G13ContourPolishV41.gd`: refinamiento geométrico, comprobaciones de malla y restauración reversible.
- `scripts/ui/UnitModels3D.gd`: V41 se aplica después de V40 en LOD13 y LOD8.
- `scripts/ui/BastionStudioAdapter.gd`: ocho vistas manuales y comparación V40/V41 en el selector original del Estudio.
- Se conservan los ocho esmaltes de facción, dos cañones automáticos, radar plegable, ruedas, jerarquías de escena y animaciones.
- `aa_mobile` sigue siendo un prototipo artístico; este cambio no convierte la G13 en una unidad jugable de BattleSession.

## Siguiente prioridad

Usar las perspectivas para una revisión de diseño 360° renderizada y corregir cualquier defecto detectado de manera específica (caras invertidas, uniones flotantes, intersecciones o sombreado irregular). No afirmar que la revisión visual se ha completado sin ejecutar el visor. Si se ve correcto, iniciar una revisión final de aprobación artística de la G13 en lugar de seguir agregando accesorios.
