# TARVOKA — Primera integración REAL de modelos 3D en batalla

**Rama:** `feat/first-real-3d-unit-models-20261112`. Godot 4.3, Android OpenGL Compatibility, partiendo del motor integrado y de la interfaz de mapa protagonista (`main`).

## Qué se ha hecho

Antes de este hito **no existían archivos de malla 3D (.glb/.gltf/.obj) en GitHub**: solo SVG, atlas PNG generado y siluetas procedimentales 2D. Las imágenes de diseño son referencias, no mallas. Por tanto, esta rama crea **geometría tridimensional auténtica y editable** en Godot en `UnitModels3D.gd`, sin fingir que una imagen conceptual es un modelo 3D jugable.

Se han modelado ocho clases reales del catálogo autorizado, sin añadir nombres no existentes ni alterar las 32 clases:

| Código de rol | Unidad real en TARVOKA | Diseño 3D implementado |
|---|---|---|
| `line` | Guardia | Torso, chaleco, casco, visor, articulaciones, botas, mochila, fusil, cargador |
| `scout` | Rastreador | Soldado con sensores adicionales, ópticas nocturnas, radio y arma |
| `apc` | Transporte blindado | Chasis biselado 6×6, ruedas, parabrisas, blindaje, sensores y antenas |
| `tank` | Tanque principal | Chasis, orugas, ruedas, blindaje compuesto, torre y cañón 3D |
| `mlrs` | Lanzacohetes múltiple | Plataforma de orugas, lanzador inclinado, doce tubos, bisagras |
| `attack_heli` | Helicóptero de ataque | Fuselaje, cabina, rotores, cola, sensores, patines y cohetes |
| `fighter` | Caza multifunción | Alas triangulares con volumen, cabina, motores, estabilizadores y misiles |
| `destroyer` | Destructor | Casco 3D afilado, cubierta, superestructura, radares, VLS, cañón, helipuerto |

## Integración real de juego

1. `UnitModels3D.build(role)` produce un **nodo Godot 3D** con `MeshInstance3D` editables, mallas y materiales propios; sus modelos no dependen de controles de combate ni del estado serializado.
2. `UnitRender3D` crea ocho cámaras ortográficas isométricas compartidas de 224×224 px y renderiza cada modelo solo al iniciar la vista 3D. Los `SubViewportTexture` se conservan con `UPDATE_DISABLED` después de la captura. **No hay una cámara 3D por soldado** ni renders 3D continuos durante turnos.
3. `TouchBoard` enlaza el repositorio de modelos a `IsoRenderer` en el **tablero jugable**, no solo en una galería separada. Los turnos, proyección, zoom, niebla, IA y alcance siguen gobernados por el motor 2D validado.
4. Las ocho clases 3D se dibujan en su posición real cuando la vista isométrica tiene suficiente zoom y están en estado de reposo o movimiento. En ataques, daño y zoom muy lejano se conservan los sprites de 32 roles, poses y marcadores contrastados, hasta completar las animaciones 3D.
5. El botón **«Modelos 3D (8 clases): activados/desactivados»** permite comparar y revertir la presentación sin reiniciar ni modificar la partida.
6. El render 3D se desactiva cuando se ejecuta Godot en modo `--headless`, ya que carece de una cámara GPU física. El test CI valida geometría real y el puente del juego sin simular falsas capturas de pantalla.

## Condiciones para considerar definitiva esta integración

La geometría de este paquete es **primera versión 3D editable**, todavía **no** un conjunto de modelos artísticos finales aprobados. Para ese nivel faltan mallas de producción refinadas (UV, texturas PBR, niveles de detalle, huesos/animaciones, y estados de destrucción), colores completos de las ocho facciones, control de cámara y test visual manual en Android.

También hay que revisar visualmente que las unidades no tapen la información táctica, que el alpha de la captura sea correcto en teléfonos Samsung, y que el consumo de memoria GPU sea aceptable. Los modelos 3D que no están incluidos entre los ocho siguen usando el atlas anterior.

## Qué no cambia

**Sin cambios** en daño, contrataque, distancia de movimiento/disparo, IA, niebla, economía, unidades nuevas o archivo de guardado JSON v1. Se mantiene la opción de ver todas las unidades con el atlas de sprites existente mientras se completa esta fase.
