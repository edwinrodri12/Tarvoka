# TARVOKA — G13 V13 · acabado PBR y paneles laterales reales

**Estado:** implementación 3D nativa Godot 4.3 en el mismo `aa_mobile` de `UnitModels3D`, solo detalle de estudio `art_level=13`. La unidad sigue siendo una **vista artística**, no está incorporada al combate táctico ni cambia sus estadísticas.

## Cambios sobre G13 V12 validada

- **17 acabados de superficie:** conserva exactamente los esmaltes originales de las ocho facciones y cambia únicamente metalicidad y rugosidad de los cascos y superficies ya existentes. Acero pintado y blindaje mate se distinguen de bujes, carcasas de retroceso y cojinetes metálicos.
- **Textura de desgaste procedural discreta:** 64×64 determinista, compartida para todos los modelos y limitada a piezas `BoxMesh` que tienen UV reales (cubierta del motor, puerta posterior y protectores de escape). No se coloca textura sobre mallas `ArrayMesh` sin UV y no usa shaders que obliguen a ampliar el LOD móvil.
- **Placas laterales intermedias:** dos mallas selladas y biseladas reales entre los pasos de rueda; no pisan la banda pintada de facción ni el parabrisas. Sus caras frontales están por encima de las superficies originales del chasis.
- **Seis ranuras de ventilación 3D:** tres por lateral, visibles en planos cercanos sin cubrir ruedas.
- **Ocho fijaciones laterales:** agrupadas en un único MultiMesh para minimizar el costo de renderización.

## Integración y regresión

- Nuevo autor de detalle `scripts/ui/G13SurfaceFinishV13.gd`, llamado después de V12 para el modelo de alta calidad.
- El mismo **Estudio 3D unificado** ofrece `G13 · Antiaéreo V13`. El publicador web reconoce cambios en el módulo V13.
- `tests/test_g13_surface_finish_v13.gd`: regresión de las 8 facciones, 17 materiales, geometría de placas y ranuras, geometría sin duplicación, animaciones tierra/aire y aislamiento de LOD8.
- `tests/test_g13_v13_surface_capture.gd`: 24 PNG procedentes de Godot: 8 facciones, 7 direcciones, ataques a tierra y aire, macro de rueda, 4 macros de V12 y 2 nuevas de V13 (lateral y techo).
- Pipeline `.github/workflows/g13-v8-final-art-audit.yml` conserva y añade las regresiones V1–V13.

## Pendientes antes de aprobar arte comercial

Revisar físicamente las 24 capturas, comprobar que las placas no colisionen visualmente con los pasos de rueda al girar y evaluar los materiales con iluminación de día/noche. Medir FPS y memoria en un Android real antes de activar el modelo de alta calidad fuera del visor.

**Fuera de alcance:** daño, alcance, ataque antiaéreo jugable, IA, combustible, munición, compras, costes, poderes y lógica de batalla.
