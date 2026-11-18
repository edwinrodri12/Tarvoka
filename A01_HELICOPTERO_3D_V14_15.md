# TARVOKA — HAT-29 A01 V14.15: cortes metálicos realmente cerrados

## Por qué avanzamos la V14.14
La versión V14.14 obtuvo resultado verde con **89 imágenes reales** de Godot 4.3 y ocho ciclos de destrucción/reparación ([run 44263915322](https://github.com/edwinrodri12/Tarvoka/actions/runs/44263915322), [artefacto de 89 imágenes](https://github.com/edwinrodri12/Tarvoka/actions/runs/44263915322/artifacts/14408634125)). La revisión visual mostró los dos trozos asentados **fuera del fuselaje** y reconocibles en el suelo, pero la propia V14.14 había seleccionado triángulos de la corona sin cerrar sus bordes de sección. Se decide pulir la geometría y **no** cambiar posiciones, animaciones ni colores de facciones.

## Modelado de V14.15
Archivo `scripts/ui/AttackHelicopterHubCutFinishV1415.gd`.

- La fuente son los **dos fragmentos originales V14.14** del buje central V14.13, hijos del sistema de restos V13.
- Para cada fragmento se recorren sus triángulos originales. Las aristas que aparecen una sola vez en la malla identifican las superficies de fractura abiertas.
- Cada borde recibe un triángulo de cierre con la orientación inversa hacia un punto central incrustado en el material (radio 0.012, altura -0.005). Se genera una nueva `ArrayMesh` de un solo `MeshInstance3D` por fragmento; el contorno exterior y su trayectoria permanecen idénticos.
- Resultados geométricos esperados con el diseño de corona actual: fragmento 0, 792 → **864 vértices**; fragmento 1, 831 → **936 vértices**. El suplemento de 24 y 35 triángulos de sección, respectivamente, cierra los bucles de borde de las mallas.
- Se generan normales reales, color del metal expuesto en los vértices de corte (tono plata cálido), cuerpo de acero accidentado (aleación gris), material físico con `metallic=0.29` y `roughness=0.72`. Los materiales se conservan por separado del acabado de la aeronave intacta.
- Las dos mallas nuevas sustituyen **en sitio** las mallas de restos V14.14. Se guardan los recursos anteriores como metadatos para alternar entre cortes abiertos V14.14 y cortes cerrados V14.15, sin reconstruir el helicóptero ni añadir nodos de dibujo.
- Sin impacto en niveles de daño o físicas: `V13.pose`, las ocho facciones, todos los estados de choque y `art_level <=10` permanecen sin modificaciones.

## Inspector 3D
`Unidades → HAT-29 → Detalles` añade controles de inspección de **ambos trozos concretos** en el suelo y `Comparar corte abierto V14.14 / sellado V14.15`. El inspector lleva a la escena de restos finales y enfoca el objeto auténtico en vez de dibujar una imagen falsa.

## Aseguramiento de calidad
- `tests/test_attack_helicopter_v14_15_cut_finish.gd`: ocho facciones, número exacto de triángulos, color por vértice, **prueba de malla cerrada (cada arista aparece exactamente dos veces)**, cero triángulos degenerados, comparador reversible, coste de dibujo sin cambios y reparación V13, sin LOD Android.
- `tests/test_attack_helicopter_v9_studio.gd`: controles de cámara, objetivos reales de las dos piezas, comparación sin cambio de instancia y reparación.
- `tests/test_attack_helicopter_v14_capture.gd`: **93 capturas nativas** previstas, cuatro nuevas imágenes que comparan los cortes abiertos/cerrados para cada fragmento con iluminación y cámara idénticas.
- `.github/workflows/a01-v14-hat29-visual-qa.yml` y `.github/workflows/tarvoka-3d-pages.yml`: ejecución independiente del QA y exportación del visor WebGL unificado; **las fallas de G13 no se deben ocultar** para aprobar el helicóptero.

## Estado de liberación
V14.15 está implementada en el repositorio principal. El acabado artístico final debe confirmarse con el resultado de los 93 PNG y el test de manifold. La actualización del visor web se verifica por separado; que el HAT-29 pase su prueba no demuestra automáticamente que el Estudio unificado haya publicado (en las ejecuciones anteriores existían fallos ajenos del G13).

## Resultado de inspección y CI
Godot 4.3 produjo **93 capturas reales** con los cuatro ángulos adicionales de comparación; se revisaron los PNG originales (dos pares comparables a cámara fija, `hat29_v14_15_corte_0_abierto/soldado.png` y `hat29_v14_15_corte_1_abierto/soldado.png`). Los cortes V14.15 muestran caras metálicas expuestas reconocibles frente a los bordes V14.14 abiertos, y las piezas mantienen posición, tamaño y silueta. No se modificó el rotor en su estado intacto.

En la [ejecución A01 44269771494](https://github.com/edwinrodri12/Tarvoka/actions/runs/44269771494), las pruebas de Godot del HAT-29, los 384 estados animados, los ocho ciclos V14.14 y la nueva **verificación de ambas mallas cerradas en ocho facciones** han superado las etapas respectivas. Las 93 capturas y su publicación como artefacto deben comprobarse como resultados independientes cuando termine el flujo. La [ejecución previa 44269702697](https://github.com/edwinrodri12/Tarvoka/actions/runs/44269702697) generó correctamente 93 imágenes, pero marcó fallo por un contador antiguo que esperaba 89; el workflow actualizado ya usa 93.

**El visor público solo se considera actualizado si el workflow Pages del último commit termina correctamente.** El hecho de que el código y la geometría del HAT-29 pasen no suprime las pruebas de G13 ni permite atribuir a HAT-29 fallos de otras unidades.
