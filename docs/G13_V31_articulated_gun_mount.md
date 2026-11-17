# TARVOKA G13 V31 — montaje articulado del cañón gemelo

Estado: **escultura 3D integrada en el Studio compartido (LOD8); pendiente inspección visual; no se declara terminado el modelo**.

## Continuidad

- Conserva G13 V25–V29, su vehículo 4×4, dos cañones automáticos, giros de torreta y apuntado a objetivos aéreos/terrestres.
- Conserva V30: soporte trasero de radar abatible con una instancia de dibujo.
- V31 no añade lanzamisiles, estadísticas, unidades tácticas, lógica de daño ni cambios de rendimiento afirmados sin medir.
- El nivel de detalle principal LOD13 V24 permanece sin modificaciones.

## Escultura V31

- Dos culatines blindados cerrados, facetados, modelados como una única malla `ArrayMesh`, unidos al grupo existente `G13_ElevacionCanones`; siguen la elevación de los dos cañones.
- Dos casquillos de eje estacionarios, material metálico mate, como una única instancia `MultiMeshInstance3D` en `G13_TorretaAzimut`; giran con la torre, no con la elevación.
- Las bases de las protecciones solapan el receptor, y los casquillos penetran ligeramente el blindaje de la torre: las piezas están físicamente ancladas.
- Las protecciones quedan por delante del eje sin tapar el anillo de apoyo, permitiendo leer el giro desde laterales.
- El metal de la protección adopta discretamente el color activo de cualquiera de las ocho facciones.
- Se agregan únicamente **dos nodos de dibujo** respecto de V30; recuento de triángulos registrado desde la malla.
- Visualización opcional del mismo modelo con piezas V31 visibles u ocultas para comparar con V30 sin cambiar cámara, orientación ni facción.

## Integración

- Modelo: `scripts/ui/G13GunMountFinishV31.gd`.
- Instalación: `scripts/ui/UnitModels3D.gd`, únicamente rama `aa_mobile` / LOD8 y después de V30.
- Visor: `scripts/ui/BastionStudioAdapter.gd`; categoría G13, selector táctico LOD8, botón **Mostrar soportes de cañones** y botón **Comparar con V30**.
- Animaciones existentes de radar y disparo no se sustituyen: se hereda la jerarquía de cabeceo y giro.

## Siguiente prioridad propuesta

V32: acabado de unión entre collar y protecciones, tornillos de bloqueo legibles y textura de desgaste no destructiva en el metal, sin alterar armas, silueta ni animaciones. Como criterio de entrega, revisar visualmente todas las elevaciones y el giro posterior antes de definir el modelo como finalizado.
