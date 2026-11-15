# TARVOKA — Base Aérea V14 · marcas de impactos acumuladas

## Prioridad visual completada en código Godot 4.3

Se integra una segunda capa de daño, persistente, sobre las animaciones temporales V13. Antes, humo, chispas y ondas desaparecían al finalizar; ahora el modelo conserva huellas de la prueba mientras no se pulse **Limpiar impactos acumulados**.

### Acabados según el material y el arma

| Material | Bala | Misil | Bombardeo |
|---|---|---|---|
| Portón metálico | pequeña abolladura con borde brillante y núcleo oscuro | abolladura profunda y halo carbonizado | tres zonas de deformación y quemaduras |
| Torre de concreto | perforación superficial y desconchón oscuro | craterización de relieve con polvo | tres marcas escalonadas en el fuste |
| Cubierta del hangar | agujero/rasguño **superficial representado con relieve** | metal deformado y halo quemado | tres cicatrices separadas siguiendo el plano real del techo |

No se realizan orificios topológicos en la malla original ni cambios en físicas/colisión. Las marcas son **mallas tridimensionales contorneadas** con un borde elevado y una depresión visual central. La textura original permanece debajo para proteger rendimiento y compatibilidad con los LOD. No afirmar que son penetraciones físicas ni roturas de paneles.

### Persistencia y control

- Cada superficie soporta **hasta tres huellas** visibles; los impactos nuevos sustituyen las más antiguas de esa superficie.
- El historial de las últimas **doce pruebas** se conserva en el controlador del Estudio. Se reaplica tras reconstrucciones por lluvia/nieve, cambios de vista o nivel de daño. Al cambiar de facción o nivel arquitectónico se inicia un nuevo historial para evitar transferir marcas de un edificio diferente.
- En destrucción total no se crea la capa V14, ni se permite apuntar a las ruinas. En daño crítico, la bala del portón apunta a la sección exterior que aún existe, no al panel central desaparecido.
- El botón **«Limpiar impactos acumulados»** borra historial y geometría visible sin reiniciar el juego.
- El interruptor **«V14 · abolladuras, desconchones y carbonización (comparar V13)»** permite una comparación directa sin alterar las animaciones ni los daños anteriores.
- No se modifica HP, economía, ataque, defensa, ni la aplicación Android.

### Rendimiento

Una sola Base Aérea detallada mantiene nueve puntos de cicatriz reutilizables (tres por superficie), cada uno con máximo dos mallas de relieve y halo. No se crean escombros infinitos, luces extra, partículas, ni cuerpos físicos. El escenario de 8/32/64 edificios LOD no instancia esta capa de huellas, para evitar un presupuesto gráfico descontrolado.

### Control de calidad

Workflow `.github/workflows/airbase-v14-persistent-scars-gpu.yml` ejecuta Godot 4.3 OpenGL. Prueba 40 pares facción/daño, tres niveles, nueve combinaciones de arma y superficie, geometría con contorno real, hasta nueve marcas acumuladas, clic de reparación, portones con veinte piezas, clima y conservación en estados de daño. Produce catorce capturas reales: vista limpia, comparación V13, matriz de nueve marcas, lluvia, daño medio y reparación.

Se trata de QA gráfico de escritorio. **No equivale a FPS físicos en Android**; publicar TARVOKA Studio web es una operación separada tras pruebas.
