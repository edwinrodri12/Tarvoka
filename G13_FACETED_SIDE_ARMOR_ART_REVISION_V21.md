# TARVOKA · G13 V21 — Carenados laterales facetados y soldaduras integradas

## Prioridad artística

A partir del modelo G13 V20, mejorar **la silueta lateral de la torreta, los encuentros del blindaje y su lectura durante la elevación de los cañones**. El usuario mantiene su especificación original: dos cañones automáticos, radar independiente y **cero lanzamisiles**.

## Geometría editada en Godot 4.3

- Sustituimos **en el mismo `MeshInstance3D`** las dos mallas **visibles** `G13_V11_TurretCheek_-1/1` que V11 había construido para sustituir los cubos V2 ocultos por dos mallas cerradas con **cinco perfiles decagonales biselados, con reborde inferior forjado visible** (`ArrayMesh`, 96 triángulos / 288 vértices de origen por costado). Conservan nombres históricos, nodos y sus materiales originales.
- **Reborde inferior de hasta 0,058 m sobre el costado (zona inferior, sin tapar emblemas), además de **frente estrechado**** junto al rodamiento móvil/fijo V19, que deja visible el aro circular del cañón; **zona central más ancha** junto a las insignias originales de ocho facciones; **salida trasera ahusada** hacia las piezas de blindaje V20.
- Dos cordones de soldadura inferiores de metal oscuro reubicados sobre la nueva arista exterior, construidos como mallas cerradas de tres perfiles (44 triángulos / 132 vértices de origen), siguen el borde biselado y quedan por debajo de los escudos de facción.
- Los dos paneles V11 visibles anteriores se guardan como mallas de referencia internas; los bloques V2 ocultos permanecen intactos y la función `show_legacy_cheeks(...)` permite comprobar **en la misma cámara y pose** la diferencia V20 frente a V21. Esta función solo sirve para inspección; el modelo normal se muestra en V21.

**Alcance:** exactamente dos mallas reemplazadas y dos mallas nuevas. Sin alteraciones en tren de rodaje, rueda, radar, material de facción, los dos cañones, retroceso, número de unidades, daños o combate. Aplicación exclusiva a LOD13 de estudio; LOD8 Android queda intacto. Prototipo de arte, aún no registrado como unidad de combate TARVOKA.

## Comprobación y fotografías reales

- `tests/test_g13_side_armor_v21.gd`: ocho facciones, topología cerrada y cinco secciones geométricas, perfil del aro frontal, pintura, ambas soldaduras, reversión V20/V21, inspección de 7 poses originales, dos bocas huecas y ninguna modificación LOD8.
- `tests/test_g13_v21_visual_capture.gd`: 56 capturas Godot con siete vistas de orientación, ambas caras de la torreta, alcance aire/tierra, mismas fotografías de control existentes y dos capturas V20 vs V21 **con idéntica cámara** y umbral cuantitativo de píxeles modificados para rechazar geometría oculta.
- La auditoría GitHub Actions verifica los tests y publica los PNG originales. El disparador de GitHub Pages carga el script V21 en el **mismo Estudio 3D**.

La inspección inicial de la V21 reveló que esculpir los nodos V2 ocultos no cambiaba la imagen. Esta revisión apunta específicamente a los **nodos V11 visibles** y exige un cambio de silueta medible en render.

El cierre final del modelo corresponde a la aprobación visual del usuario; V21 no cambia por su cuenta el armamento definido.
