# TARVOKA Base Aérea V4 — humo y fuego suave / escenarios de carga

## Arte real, compatible con Godot 4.3
La V4 continúa la Base Aérea V3 (pista de rodaje alineada y efectos de combate), sin alterar las reglas de juego.

1. `AirbaseDamageFXV4.gd`: hereda las posiciones, tiempos y grupos MultiMesh de V3 y cambia *únicamente* los materiales de humo y llamas con sombreadores originales independientes. Se mantiene el límite de **un lote de humo y uno de fuego**. No agrega luces dinámicas ni partículas.
2. `assets/shaders/airbase_soft_smoke_v4.gdshader`: humo 3D con silueta irregular, ruido procedural temporal, atenuación periférica y dispersión vertical más suave.
3. `assets/shaders/airbase_soft_flame_v4.gdshader`: lenguas de fuego animadas y semitransparentes; evita mostrar conos opacos que parecen bloques.
4. El perfil Android mantiene dos capas por fuente de humo y permite suspender la actualización para edificios distantes. **No equivale a tener mediciones reales de un Android.**

## Rendimiento y escenas de estrés
`AirbaseMapLODV4.gd` produce **una única MeshInstance3D con cuatro superficies** por base aérea lejana, sin cargar un modelo V3 completo oculto. Se reutilizan materiales y geometrías según facción/nivel/daño; la silueta conserva hangar, torre, helipuerto y pista alineada.

`AirbaseStressV4.gd` crea tres escenarios auditables con **8, 32 y 64 bases aéreas**:
- 4 edificios cercanos con modelo detallado y daños visibles.
- Los restantes se representan con la malla LOD real, de cuatro superficies.
- Las ocho facciones se distribuyen entre edificios, sin inventar variantes.
- Los números de superficies y nodos son presupuestos de escena, *no FPS garantizados*.

En el visor `Edificios 3D > Base Aérea V4`, activar **Vista de muchas bases aéreas · LOD real** para seleccionar el tamaño. El contador muestra FPS del renderizador de Godot ejecutándose en esa máquina; los FPS reales en Android no se pueden conocer sin correr y medir en un dispositivo físico.

## Límites
No se ha integrado a la economía ni al HP de edificios de las partidas; no se afirma compatibilidad garantizada para 8 jugadores sólo a partir de estos escenarios. Estos escenarios cargan principalmente edificios, no todas las unidades/efectos simultáneos de una batalla real. La validación en Android debe realizarse posteriormente con una compilación e instrumentación en un teléfono concreto.

## Control de calidad
`tests/test_airbase_v4_soft_fire_stress_gpu.gd` y workflow `airbase-v4-soft-fire-stress-gpu.yml` verifican 120 combinaciones de LOD, material shader real, 1–2 lotes visuales, suspensión de simulación LOD, escenas de 8/32/64 y regresión del Cuartel General, con capturas de Godot.
