# TARVOKA Base Aérea V11 — cerchas interiores y daños de cubierta

## Objetivo de la fase visual
Esta es una mejora **de geometría 3D nativa en Godot 4.3**, no una ilustración ni un cambio de mecánicas. El modelo V10 ya incorpora los perfiles continuos bajo la cubierta y una fachada posterior operativa. La V11 añade la estructura transversal que faltaba y hace que sus extremos se vean físicamente expuestos en las roturas.

## Cambios en los modelos
- **Arriostramiento cruzado:** cuatro barras diagonales sólidas de sección cuadrada bajo cada una de las catorce chapas V1 intactas. Siguen la inclinación de cada panel y quedan por debajo de su plano inferior.
- **Anclajes metálicos:** dos barras de fijación por chapa. Se sujetan bajo los perfiles V10 y se agrupan en una segunda malla, no en docenas de nodos independientes.
- **Roturas estructurales:** en daño medio o crítico, las dos fronteras físicas de la abertura reciben un borde metálico ennegrecido y pequeñas barras dobladas y colgantes. Las barras terminan dentro de la rotura, **no conectan ambos extremos del hueco**.
- **Daños progresivos:** intacto y leve mantienen 14 chapas estructuradas, daño medio 12, crítico 8, y destrucción total 0. El daño medio tiene 4 fragmentos de barra colgante; el crítico 6.
- **Presupuesto visual:** máximo dos mallas nuevas de armadura intacta y dos mallas de roturas por edificio cercano. Se mantienen los LOD V4 a distancia. No se agregan luces dinámicas, partículas ni colisiones.

## Cómo comparar
En **TARVOKA Studio 3D → Edificios 3D → Base Aérea V11**, activa o desactiva el interruptor **«V11 · cerchas cruzadas, soportes y roturas (comparar V10)»**. Para comparar correctamente, mantén V10 activada y alterna V11. Las cámaras **Interior hangar**, **Cubierta superior** y las vistas de daños medios y críticos muestran la diferencia. Además, el control **«Inspeccionar cerchas: ocultar chapas del techo»** crea una vista reversible de estructura sin cubierta únicamente en el Estudio 3D. Conserva las chapas reales intactas y permite comparar V10/V11 desde arriba. Funciona también con los dos niveles de daño que conservan una abertura en el techo.

Los ocho colores de facción, las insignias originales, los tres niveles, las animaciones de las veinte piezas de portones, el clima y los materiales V6-V10 se conservan. La V11 no afecta HP, reglas de captura, producción, turnos, movimiento ni combate.

## Validación y publicación
El test `tests/test_airbase_v11_exposed_trusses_gpu.gd` audita 40 combinaciones de ocho facciones por cinco daños, 3 niveles, cantidades de barras **como geometría 3D real**, ausencia de puentes sobre huecos, 20 elementos móviles del portón, reversibilidad de clima, LOD cercano y retorno al Cuartel General. La acción `.github/workflows/airbase-v11-exposed-trusses-gpu.yml` recoge 16 capturas de Godot, comparando interior V10/V11 y techos con daños.

**No confundir las capturas de escritorio o los resultados de este test con FPS Android.** La publicación web es un despliegue independiente y se confirma sólo cuando GitHub Pages informa éxito.
