# TARVOKA — inspección 3D real del Taller de Blindados (2026-11-19)

## Evidencia realmente ejecutada

- Godot **4.3**, render OpenGL por software, no imágenes ilustrativas. QA histórico [run #44622272152](https://github.com/edwinrodri12/Tarvoka/actions/runs/44622272152): **SUCCESS**.
- 135 combinaciones HERO V2, 270 combinaciones Android por MultiMesh, 840 transiciones de LOD: SUCCESS.
- 36 capturas (3 tamaños, 6 perspectivas, 2 LODs Android y D2–D4), ver artefacto de ese run; todas dentro de los márgenes y con píxeles de geometría.
- QA de puente visual de mapa [run #44639874459](https://github.com/edwinrodri12/Tarvoka/actions/runs/44639874459): **SUCCESS**; 270 variantes de escala de casilla, comprobación de niebla, ocho PNG de prueba de encaje de 2,4 m. No cambia batalla real ni economía.

## Hallazgos tras mirar los PNG originales, no solo el recuento de mallas

1. **HERO, niveles N1–N3:** los módulos del techo, entrada principal, muros laterales y número de bahías se distinguen en las seis cámaras. D3 no mantiene cerchas altas; D4 consiste en cimientos y restos.
2. **Android distante anterior:** la silueta era demasiado genérica y perdía información de taller, bahías y facción. Se añadieron tres huecos oscuros en N3 y aperturas correspondientes en N1/N2, dos líneas metálicas por bahía, respiraderos bajos, placas de color en cubierta y franjas laterales/posteriores, usando únicamente materiales y grupos GPU existentes.
3. **Posterior HERO anterior:** dos paneles de hormigón excesivamente claros parecían huecos al mirar directamente desde atrás. Se añadieron un muro continuo opaco, `bays+1` portillas de servicio, ventilación y una franja de facción. Se comprueba mediante tests, pero la inspección de PNG posteriores al arreglo debe terminarse.
4. **Mapa táctico:** el taller se ha encajado en una casilla de 2,4 m, manteniendo 0,23 m de margen total en cada dimensión. El campo de prueba de nueve casillas es un soporte **solo visual**, sin estados ni órdenes de batalla. Las ocho capturas permiten juzgar legibilidad del LOD táctico/distante y D3/D4 a escala real.

## Criterios de aprobación pendientes

- Ejecución Godot SUCCESS correspondiente a la última revisión de portillas posteriores y su test.
- Verificar las capturas posteriores del HERO revisado y comparar los dos LOD desde las seis perspectivas.
- Mantener `workshop_approved=false` y la PR #629 **borrador** hasta que el arte alcance calidad de los edificios ya aprobados.
- No integrar tipos de sitio ni producción nueva en `BattleTerrain3D.gd`, `Rules.gd` o `Economy.gd` antes de que el usuario apruebe la geometría y el rol del Taller. El puente solo ofrece un fixture 3D listo para ensayar.
- No afirmar mejora medida de FPS de Android físico: la reducción de lotes GPU (máximo 10 en las pruebas anteriores) es métrica estructural, no benchmark de tiempo de cuadro.

## Archivos vinculados

- `scripts/ui/ArmoredWorkshop3DV2.gd`
- `scripts/ui/ArmoredWorkshopMobileLOD3D.gd`
- `scripts/ui/ArmoredWorkshopBattlePreview3D.gd`
- `tests/test_armored_workshop_v2_native.gd`
- `tests/test_armored_workshop_mobile_lod.gd`
- `tests/test_armored_workshop_battle_preview.gd`
- `tests/capture_armored_workshop_v2_cameras.gd`
- `tests/capture_armored_workshop_battle_preview.gd`
