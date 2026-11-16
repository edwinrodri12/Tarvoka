# TARVOKA — Cuartel de Infantería V2: entradas, fachadas, torres y entrenamiento

## Prioridad definida
Refinar el diseño 3D dentro de Godot 4.3, **sin generar ilustraciones externas**, conservando la evolución real en los tres niveles del Cuartel de Infantería V1. Las tres masas arquitectónicas y sus pisos son intocables en V2:

| Nivel | Geometría principal ya aprobada | V2 |
| --- | --- | --- |
| 1 | Barraca compacta de una planta, patio reducido | Acceso con escalones, marco metálico, señalización de infantería, vidrios con montantes, pista básica mejor definida |
| 2 | Ala en L: dos plantas y torre individual | Puertas en ambos módulos, ventana industrial dividida, soportes triangulados y escalera para la torre, pista con obstáculos de salto |
| 3 | Complejo en U: tres plantas, dos alas dobles y dos torres | Entradas diferenciadas en tres módulos, ambas torres arriostradas con acceso, patio de despliegue y obstáculos urbanos adicionales |

## Detalle real sobre V1
`scripts/ui/InfantryBarracksFinishV2.gd` es una pasada **aditiva y reversible**: reutiliza `InfantryBarracks3DV1.gd` para el módulo base y solo añade geometría nativa Godot para marcos de puerta, escalones, plafones/placas, mullions de ventanas y alfeizares, canalones/bajantes, escaleras de torre con peldaños y arriostres, terminación de cabinas y área de entrenamiento. No cambia ninguna dimensión estructural de V1 y no clona pisos o edificios completos.

- Facción: solo franja superior, acceso y placa de torre. El cemento mantiene material militar neutro.
- Daño leve: conserva detalle útil con acabado envejecido. Daño medio: pierde paneles, cristales intactos y cableado delicado. Daño crítico: solo umbrales quebrados, bordes fracturados y escombros; **no reconstruye accesos o torres**. Destruido: la pasada V2 no añade ningún elemento sobre las ruinas V1.
- Nivel 1: sin torres ni pasarelas falsas; nivel 2: una; nivel 3: dos.

## Control del Estudio
En `Edificios 3D → Cuartel de Infantería V2`:
- Selector de las 3 arquitecturas originales.
- Cinco estados de daño.
- Cuatro cámaras (general, patio, entrenamiento, cubierta).
- Colores de ocho facciones.
- Casilla `V2 · accesos, cristales y torres (comparar V1)` activada por defecto; al desactivarla la escena se reconstruye como V1 real sin crear copias de fachada superpuestas.
- Zoom y giro se preservan en la comparación.

## Prueba
`.github/workflows/infantry-barracks-v2-native-gpu.yml` ejecuta `tests/test_infantry_barracks_v2_gpu.gd`: 120 modelos (8 facciones × 3 niveles × 5 daños); confirma que las 3 masas se conservan, no hay torres en N1, hay 1 en N2 y 2 en N3, el nivel destruido sigue únicamente con ruinas y el interruptor V1/V2 reconstruye la escena. Produce 13 capturas auténticas de Godot/OpenGL (3 niveles con encuadre igual + patio + pista + cubierta + comparativa V1/V2 + cuatro daños + facción).

**No se declaran exitosas las pruebas antes de ver el resultado de Actions.** El Estudio 3D es una herramienta visual separada de la APK: no certifica producción de infantería, captura, FPS Android o cambios económicos. La publicación pública de Pages requiere deploy verificado.

## Próxima inspección
Revisar encuadre y legibilidad de escalones/puertas, si los peldaños de torres están alineados, salientes de las alas en L y U, y coherencia en estado de daño. Corregir hallazgos concretos antes de avanzar hacia texturas y animaciones.
