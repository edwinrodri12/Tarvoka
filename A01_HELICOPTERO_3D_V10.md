# TARVOKA — Helicóptero de ataque A01 · escultura visual V10

**Estado inicial:** PR #463 en revisión. Diseño Godot 4.3 únicamente en el modelo detallado del Estudio 3D (`art_level>=13`). El modelo móvil de combate conserva su implementación original.

## Refinamiento 3D nativo
La nueva capa `scripts/ui/AttackHelicopterFinishV10.gd` complementa, no reemplaza ni duplica, el casco V1, la cabina V2, rotores V3, motores V4, tren V5/V6 y las insignias de facción V7/V8.

- Cristal de cabina cerrado V2: material con rugosidad 0.115, especular 0.87 y transparencia alfa 0.73 para reflejos más definidos y visibilidad del interior.
- Emisor óptico frontal: tratamiento de vidrio azul y alta respuesta especular; los dos motores V4: metal de matiz acero, tapas de blindaje distintas y escape interior oscuro.
- Cabina delantera: dos barras físicas finas de sujeción del parabrisas y sus pequeñas fijaciones. Posiciones trazadas sobre la geometría original de la cúpula V2.
- Buje principal: corona real toroidal y cuatro pernos metálicos hexagonales, montados en el pivote V1/V3 y rotando junto con las hélices sin crear otro eje.
- Ametralladora: anillo de acabado metálico en el cañón, sujeto al pivote real de ataque.
- **Comparación reversible V8/V10:** almacena las referencias exactas de los nueve recursos de materiales originales y restaura esos recursos, además de ocultar todas las piezas mecánicas nuevas. Restaurar V10 no duplica mallas.

## Mejoras del Estudio 3D V9
`scripts/ui/BastionStudioAdapter.gd` agrega cuatro primeros planos enfocados en coordenadas de la pieza **cabina, rotor, motores y cañón**. La cámara ortográfica mueve su centro hasta el objeto real transformado; el botón de vista general restaura la cámara original. Una luz rasante fría y sin sombras se activa únicamente al seleccionar A01; ningún otro vehículo o edificio cambia de iluminación. El texto de versión refleja V10, manteniendo la barra compacta de Android horizontal.

## Pruebas
- `tests/test_attack_helicopter_v10.gd`: ocho facciones, animación de rotor y arma, integridad geométrica, idempotencia, reversibilidad de nueve materiales y ausencia de V10 en el LOD Android.
- `tests/test_attack_helicopter_v10_capture.gd`: dieciséis capturas auténticas, ocho ángulos a 320×180, cuatro referencias V8 con cámara y luz idénticas, cuatro acercamientos 960×720 de parabrisas, buje, motores y cañón.
- `tests/test_attack_helicopter_v9_studio.gd`: prueba del Estudio real combinado horizontal/vertical, foco local de cámara, luz exclusiva de A01, comparación V8/V10 y regreso al Bastión.
- `.github/workflows/a01-v10-finish-qa.yml` y `.github/workflows/a01-v9-studio-qa.yml`.

Los scripts están preparados para revisión visual y QA real. No declarar aprobado ni publicado hasta obtener capturas, verificar que las pruebas pasen y confirmar el despliegue de Pages. La suite global HQ V13 presenta un fallo independiente anterior a V10.
