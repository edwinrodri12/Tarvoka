# TARVOKA HAT-29 A01 V14.11 — raíz aerodinámica cerrada, rotor original

## Contexto y objetivo
La V14.10 y sus **67 capturas nativas Godot 4.3** completaron correctamente la validación, y la compilación/publicación del Estudio 3D unificado terminó en verde. Quedaba un bloque rectangular V3 (`A01V3_BiselRaizAspa_0..3`) bajo los soportes V14.7–V14.10: el siguiente detalle geométrico prioritario es que la transición pala–buje tenga superficie sólida de sección variable, a la altura del resto del HAT-29.

## Modelo 3D nativo V14.11
- `scripts/ui/AttackHelicopterBladeRootsV1411.gd`: se agrega a la cadena real de `UnitModels3D` después de V14.10, exclusivamente a `art_level >= 13`.
- Por cada una de las **cuatro palas existentes**, cambia el `BoxMesh` rectangular por **un único `ArrayMesh` cerrado**, en el mismo `MeshInstance3D` padre del pivote original V1/V3.
- Secciones a lo largo de seis estaciones, 8 vértices con bisel por estación, tapas frontal y posterior, normales generadas sobre volumen. Una raíz mide nominalmente **288 vértices** y 96 triángulos, sin añadir nodos de dibujo. Se mantiene el borde ancho cerca de `z=-0.230` (`x=+/-0.118, y=+/-0.035`), y afina al espesor de la pala V3 en `z=-0.345` (`y=+/-0.019`).
- Precisión de coordenadas: el propio `MeshInstance3D` conserva su posición original `z=-0.225`. Los vértices de cada anillo compensan esta transformación, preservando el intervalo en coordenadas del pivote original `z=-0.110 .. -0.345`. Sin compensarlo aparecería una raíz doblemente desplazada; la corrección forma parte de esta versión.
- Las plataformas V14.9/V14.10 de +X/-X mantienen contacto con la sección ancha; los amortiguadores y bieletas no son recreados. Sin alteraciones en los colores aprobados ni los daños, animaciones, combustible, estadísticas o sistemas de juego.
- La comparación reversible `set_enabled(false)` restaura el `BoxMesh` y el material original V3; `set_enabled(true)` devuelve las seis estaciones dentro de la misma unidad.

## Estudio 3D y validación
En **Unidades → Helicóptero HAT-29 → Detalles**, se añaden:
1. `V14.11: transición aerodinámica`, inspección superior de la base de pala.
2. `V14.11: perfil y biseles`, inspección baja y lateral del adelgazamiento.
3. `Comparar raíz V3 / V14.11`, alternancia en tiempo real del mismo objeto 3D.

Las pruebas de `tests/test_attack_helicopter_v14.gd` cubren ocho facciones, 4 originales, vértices/cierre de malla, rango de anclaje, reversibilidad, idempotencia y LOD Android. La prueba del Estudio preserva la instancia y comprueba dos cámaras + botón. `tests/test_attack_helicopter_v14_capture.gd` genera **71 PNG reales** (67 anteriores + 4 vistas V14.11), con par comparativo mismo ángulo y un lateral bajo. El workflow A01 exige nuevas pruebas y 71 capturas. La publicación Pages empaqueta el nuevo script en el proyecto combinado sin crear un sitio paralelo.

## Verificación
- V14.10: Godot 4.3 y publicación Pages verificados en verde.
- V14.11: nueva geometría y controles integrados en GitHub; aprobación visual de 71 capturas y publicación WebGL deben confirmarse con las ejecuciones recientes. Un fallo del export WebGL en una ejecución anterior a la inclusión del archivo se debía a un `preload` de V14.11 ausente en el empaquetado; se añadió el archivo explícitamente a la lista de ensamblaje.
- **Estado: iteración 3D avanzada, no aprobación artística definitiva.**
