# TARVOKA · Base Aérea V15 — fracturas, metal rasgado y carbonización orgánica

## Prioridad visual

La V14 registra marcas permanentes con un anillo regular en cada superficie. La V15 añade **geometría 3D real** superpuesta, distinta para cada material/arma, con imperfecciones angulares y un número controlado de nodos. No es una imagen conceptual ni un cambio de mecánica.

### Concreto de la torre
- Grietas radiales con desviaciones y ramales laterales. Bala: 5 grietas; misil: 7; bombardeo: 9.
- Lascas y triángulos levantados en el borde exterior del desconchón. Los cráteres siguen siendo **relieve superficial** y no abren agujeros de colisión.
- Núcleo oscuro conservado de V14 y acabado gris irregular V15.

### Metal del portón y cubierta del hangar
- Lengüetas metálicas dobladas con caras 3D trianguladas, discontinuidades de borde y trazos rasgados.
- Bala: 3 pliegues sobre portón; misil: 5; bombardeo: 7; cubierta suma una pequeña chapa levantada por huella.
- La cubierta sigue inclinada sobre los planos reales V10. El portón sigue operando con sus 20 piezas originales.

### Carbonización
- Misiles y bombardeos: 7–10 islas de material oscuro, desiguales entre sí, fuera de los círculos regulares V14.
- Balas: no generan grandes manchas de quemadura.
- Nada de humo, luces o partículas adicionales; el acabado persiste mientras la huella V14 exista.

### Comparación en TARVOKA Studio 3D
En **Edificios 3D → Base Aérea V15**, el interruptor «V15 · grietas orgánicas, metal rasgado y carbonización (comparar V14)» muestra/oculta estos nuevos acabados sobre las marcas acumuladas. La comparación conserva el historial, la vista de acercamiento V13, los efectos V12/V13, el clima y la cámara.

Para inspeccionar, selecciona la superficie, activa «Enfocar objetivo», dispara con bala/misil/bombardeo y desactiva/revuelve a activar V15. El botón **«Limpiar impactos acumulados»** elimina conjuntamente las marcas V14 y sus detalles V15.

### Límite gráfico
- Cada una de las 9 posiciones máximas del sistema V14 recibe **hasta una nueva MeshInstance3D**, que reúne grietas/pliegues y hollín en una sola malla coloreada por vértices.
- Se reutilizan 27 formas de malla precalculadas (3 superficies × 3 ataques × 3 posiciones), con una única instancia de material compartida. No se crean mallas nuevas por cada bala después de llenar el grupo.
- Los escenarios LOD de muchos edificios no instancian V15, y no se añaden físicas, sombras adicionales, luces ni colisiones.
- Cambios visuales permanentes **durante la sesión del Estudio**, no persistencia de partidas ni sincronización multijugador. HP, daño táctico y economía sin cambios.

## Pruebas
`tests/test_airbase_v15_organic_damage_gpu.gd`: 40 variantes de facción × daño, 3 niveles, verificación de mallas de las 27 combinaciones, número de grietas/pliegues/islas, 9 posiciones máximas, reparaciones, reconstrucción por clima/daño, portón de 20 piezas y 16 capturas auténticas de Godot.

Workflow `.github/workflows/airbase-v15-organic-damage-gpu.yml`. Las capturas son de renderizado de escritorio; **no certifican FPS Android**. Publicación web separada tras QA.
