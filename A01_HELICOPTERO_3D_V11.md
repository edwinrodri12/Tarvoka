# TARVOKA — A01 helicóptero de ataque: modelo de Estudio V11

Continuación directa de **A01 V10**, sin sustitución del arte ya aprobado ni cambios en combate.

## Geometría 3D agregada

- **Transmisión de cola:** eje de longitud real situado sobre la viga original, tres abrazaderas/cojinetes y reductora cerrada de malla esférica con eje de salida, sello y cuatro pernos.
- **Rotor de cola:** anillo mecánico montado dentro del pivote rotatorio auténtico; cuatro bielas de paso, casquillos y pasadores conectados a los cuatro pivotes originales de pala. Animan junto al rotor de V1 y las palas perfiladas V3.
- **Armamento:** cuatro refuerzos estructurales bajo las alas trapezoidales; ocho retenedores toroidales huecos en las bocas delanteras de los lanzadores originales, más tornillos visibles. El interior del cañón y las cámaras no cambia.
- **Materiales:** acero, grafito y aleación metálica, sin recolorear las ocho facciones ni tocar las nueve superficies PBR originales de la V10.
- **Edición:** cada subconjunto tiene nodos y nombres propios, no es un póster ni una malla duplicada. La comparación V10 / V11 oculta o restaura geometría, conservando animaciones y estados del modelo.

## Visor 3D

Visor público objetivo: https://edwinrodri12.github.io/Tarvoka/ .

Seleccionar **Unidades 3D → Helicóptero A01 · V11 → Detalles** y usar las vistas **V11: transmisión y rotor de cola** y **V11: soportes y lanzadores**. El control **Comparar mecánica V10** permite inspeccionar las diferencias sin desmontar el helicóptero. Publicación solo tras fusionar y confirmar despliegue de GitHub Pages.

## Aislamiento y validación

- Se instala únicamente con `finish_enabled` y `art_level >= 13`. El LOD de combate Android `art_level <=10` sigue intacto.
- `tests/test_attack_helicopter_v11.gd`: ocho facciones, jerarquía de rotor, engranajes y bocas, comparación reversible e idempotencia.
- `tests/test_attack_helicopter_v11_capture.gd`: 8 ángulos a 320×180, 4 referencias en la misma escena V10, y 4 primeros planos auténticos.
- `.github/workflows/a01-v11-tail-qa.yml`: Godot 4.3, ejecución nativa y capturas conservadas como artefactos de QA.

**Pendiente de aprobación artística:** revisar estas capturas y el modelo giratorio en Android horizontal antes de considerar finalizado el helicóptero A01.
