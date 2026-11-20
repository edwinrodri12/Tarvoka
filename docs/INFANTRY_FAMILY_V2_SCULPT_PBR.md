# TARVOKA — Infantería V2, anatomía y acabados 3D (2026-11-20)

**Estado:** diseño implementado en rama de revisión PR #640. No aprobado visualmente; no fusionar sin renders, QA Godot y revisión Android. V1 y V2 están dentro del mismo repositorio y del MISMO Estudio 3D original, sin generar otro visor.

## Corrección del problema principal de V1

La primera maqueta tenía un chaleco rectangular, un macromódulo de mochila oscura, botas cuadradas, extremidades rígidas y el fusil apuntaba de lado sin contacto visual convincente con las manos. La V2 no añade una imagen de concepto: **sustituye físicamente estas superficies por nuevos MeshInstance3D nativos**.

- Torso: placa pectoral 3D de ocho lados, biselada y con tapa posterior; correas, bolsillos, cierres y parche central de facción.
- Mochila: volumen curvo con catorce secciones, cinchas, cremallera, bolsillos opcionales y banda trasera de facción. La caja opaca V1 se oculta, nunca se deja superpuesta.
- Anatomía: muslos, pantorrillas, mangas y antebrazos con volumen cerrado y conicidad; nuevas botas, punteras, suelas, manos enguantadas y dedos individuales en LOD13.
- Cabeza: casco cerrado facetado, auriculares, mejillas, protección de mentón, visor macizo de roughness 0.085 + clearcoat, marcas físicas opcionales de daño D3/D4.
- Arma: guardamanos, riel, empuñadura, marcas y ranuras auténticas en 3D; se reorienta ~67° para apuntar al frente. Los brazos elevan las manos hacia el arma.
- Variantes: perfil urbano con escudo facetado, defensivo con coraza extra y hombreras, explorador con sensor dorsal, antiblindaje con carga extra e ingeniero con herramientas visibles.
- Ocho facciones oficiales: etiquetas en pecho, casco, escudo, espalda, arma y cinchas; tela y blindaje militar con tonos distintos a las marcas de identidad.
- El trabajo **no cambia** el esquema de 24 familias, las mecánicas de captura ni la producción; los kits urbano y defensivo siguen siendo configuraciones visuales de G01. G03, G04 y G05 permanecen diferenciados.

## Código

| Archivo | Función |
| --- | --- |
| `scripts/ui/InfantryFamilyV1.gd` | Rig base, seis perfiles y marcas de daño |
| `scripts/ui/InfantrySculptFinishV2.gd` | Mallas orgánicas cerradas, PBR, acabado especializado y poses de manos |
| `scripts/ui/UnitModels3D.gd` | Construcción V1 → V2 para LOD13 y LOD8 y continuidad de poses |
| `scripts/ui/BastionStudioAdapter.gd` | Mismas pestañas, cámaras, selector de rol y materiales V2 |
| `tests/test_infantry_family_v1.gd` | Comprobaciones de regresión V1 |
| `tests/test_infantry_family_v2.gd` | 96 combinaciones, daño reversible, brazos, PBR y 20 capturas verdaderas |
| `tests/test_studio_full_animation_inventory.gd` | Ahora reconoce animación real de Guardia, Rastreador y cuatro configuraciones |
| `.github/workflows/infantry-family-native-3d-qa.yml` | Godot 4.3 headless/software rendering, modelos V1/V2 y fotografías |
| `.github/workflows/tarvoka-3d-pages.yml` | Publicación del mismo visor web, incluyendo el nuevo script V2 |

## Criterios de aceptación

- [ ] Godot parser y tests de 96 instancias (seis roles × ocho facciones × dos LOD).
- [ ] Las veinte capturas no están en blanco y diferencian verdaderamente V1 frente a V2.
- [ ] Manos alineadas con arma en 360°, torso y espalda sin cajas sobredimensionadas; botas posan sobre suelo.
- [ ] Revisión visual por ocho facciones, sin huecos ni transparencias, sin interferencia de mochilas/escudos.
- [ ] Visor web nativo accesible con animaciones; APK Android medible sin penalización grave de FPS.
- [ ] Aprobación artística antes de fusionar a `main`.

### Nota de QA anterior

El runner V1 había pasado la auditoría de 96 instancias y 13 PNG, **pero el workflow de Pages de la V1 falló debido a un test que todavía esperaba que G01/G03 no tuvieran animaciones**. La V2 corrige esa expectativa en `tests/test_studio_full_animation_inventory.gd`; el resultado de la nueva compilación debe verificarse en CI. No se debe afirmar que el visor web está publicado hasta lograr éxito y revisar la URL real.
