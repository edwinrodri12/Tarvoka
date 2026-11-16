# TARVOKA — Taller Militar V1 · nuevo edificio 3D

## Motivo de selección
Tras aprobar artísticamente la Base Naval V13, se inicia el siguiente edificio planificado: **Taller Militar**. En esta primera versión se modela como centro de mantenimiento de vehículos y blindados, distinto de la Base Aérea, el astillero y el Cuartel General. Es una instalación original realizada en **mallas nativas de Godot 4.3**, no una ilustración ni una sustitución gráfica.

## Arquitectura
- Explanada y cimentación de hormigón con señalización de circulación y colores discretos de la facción.
- Dos bahías de vehículos con portones seccionales 3D, guías laterales, pavimento de reparación, elevadores hidráulicos con plataformas dobles y pistones.
- Paredes auténticas a izquierda, derecha y parte posterior; fachada con tres pilares estructurales y dintel que dejan entradas físicas.
- Cubierta industrial segmentada, cerchas/vigas y remates metálicos. Los paneles perdidos no reaparecen en niveles de daño superiores.
- Nivel 1: dos bahías operativas.
- Nivel 2: oficina elevada de supervisión, armario de herramientas y depósito de aceite reciclado.
- Nivel 3: puente grúa interior, cable de suspensión y dos extractores de cubierta.
- Cinco estados visuales: operativo, leve, medio, crítico y destruido. Ruinas conservan solo la cimentación y fragmentos, sin falsos techos, portones ni pistones flotando.

## Control de revisión
`Edificios 3D → Taller Militar V1` en TARVOKA Estudio 3D. Cuatro cámaras: exterior, bahías, parte posterior y cubierta superior. Selector de 8 facciones, niveles 1–3 y cinco daños. El edificio nuevo se añade sin sustituir los tres edificios anteriores.

## Límite de esta etapa
El prototipo contiene **solo arte 3D**; su etiqueta interna `repair_workshop` no es todavía un nuevo sitio táctico en el motor de batalla. No inventar funciones de reparación, costos, regeneración automática, captura o fabricación hasta que esas reglas estén definidas y probadas. El juego actual tiene productores `factory`, `armor_plant`, `artillery_depot`, `drone_center`, `airbase` y `shipyard`, y no se deben alterar.

## QA nativa
`tests/test_repair_workshop_v1_gpu.gd` comprueba 40 combinaciones de facción/daño, los tres niveles, coherencia de paredes y techo, ruinas y continuidad de 4 cámaras, cambios de selector, convivencia con edificios previos y 11 capturas 3D reales. Lo ejecuta `.github/workflows/repair-workshop-v1-native-gpu.yml`.

## Siguiente etapa propuesta
Revisar las capturas para ver proporciones de portones, elevadores, cubierta y paredes. Después evolucionar hacia V2 con mejores puertas, piezas de taller y animaciones de mantenimiento, sin crear gameplay no autorizado. No declarar pruebas completadas ni la publicación web hasta confirmación de GitHub Actions.
