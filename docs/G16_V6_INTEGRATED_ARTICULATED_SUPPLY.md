# TARVOKA · G16 V6 — blindado logístico 6×6, hardware de abastecimiento articulado

**Estado: MODELO 3D EN DESARROLLO; pendiente revisión de capturas y aprobación visual.**
La unidad G15 V11C sí está finalizada; la G16 no. Esta rama integra los dos avances paralelos de G16 sin perder los materiales V5 ni el mecanismo V5 de abastecimiento: los materiales conservan el nombre `V5`, el hardware se registra como `V6` para evitar duplicación de clases, banderas y controles.

## Capas nativas en la MISMA unidad y el MISMO visor

| Capa | Archivo Godot | Función |
|---|---|---|
| V1 | `G16ArmoredLogisticsV1.gd` | Vehículo 6×6, cabina blindada cerrada, depósitos, cofres, grúa, rampa, toldo |
| V2 | `G16LogisticsExteriorV2.gd` | Cristales PBR sólidos, ruedas y cilindros mecánicos |
| V3 | `G16LogisticsMechanicsDamageV3.gd` | Seis conjuntos de suspensión, tapas físicas de munición, servicio de combustible y daños 0–4 |
| V4 | `G16LogisticsSculptDamageV4.gd` | Escultura blindada octagonal cerrada, placas de las ocho facciones, fragmentos y humo |
| V5 | `G16PremiumMaterialsDamageV5.gd` | Metales premium, vidrio 100 % opaco, remaches, juntas, marcas acumulativas, daños térmicos |
| **V6** | `G16DeployableSupplyHardwareV6.gd` | **Manguera físicamente segmentada, carrete protegido, acoplamiento metálico, manómetro, tapa articulada y pintura de facción** |

La capa V6 se crea y anima desde `scripts/ui/UnitModels3D.gd` sobre el mismo nodo `logistics_mobile` de las V1–V5. El estudio `scripts/ui/BastionStudioAdapter.gd` contiene: `g16_v6_on`, `g16_v6_off` y `g16_v6_connect`, además de las comparaciones V5/V4, daños 0–4, descarga, campamento, repliegue y restauración originales.

## Detalles físicos y animación

- Los componentes son `MeshInstance3D` con `BoxMesh` y `CylinderMesh` cerrados y `StandardMaterial3D` opacos, sin sprites ni agujeros transparentes.
- El latiguillo está dividido en **6 segmentos (LOD13)** o **3 (LOD8)**, con acoplador metálico y junta; la pieza gira físicamente sobre `Node3D`. Tras la inspección de capturas originales V6, se extendió la tubería visible hasta ~1,17 m fuera del carrete, se reforzó el caucho con collarines PBR 3D y se redujo el giro de 80° (ocultaba el acople detrás de la caja) a 18° para despejar el lateral blindado.
- La tapa del compartimento y el conducto se sincronizan con `resupply`, `camp`, `deploy`, `pack`, `unload`; `idle` y `stop` los repliegan.
- Color de cada una de las ocho facciones en panel de servicio, tapa y conector, sin modificar los escudos existentes ni la paleta base.
- Comparar contra V5 solo oculta el hardware V6, mientras que comparar V4/V3/V2 oculta las capas más nuevas de forma coherente. Nada obliga a que la versión visual final esté aprobada.

## Jugabilidad protegida

Los cambios son **exclusivamente artísticos**. Se preserva `ModernArsenal.gd`: G16, **8 HP**, **4 movimiento**, **0 ataque**, **300 créditos**, fábrica. Las reglas de suministros con combustible y munición finitos ya presentes en `Logistics.gd` y `BattleSession.gd` no se reimplementan ni se alteran. El campamento continúa siendo una **simulación visual**, no un edificio permanente ni una fuente nueva de recursos.

## QA y publicación condicionada

- `tests/test_g16_v6_service_hardware.gd`: ocho facciones × LOD8/LOD13, geometría y opacidad PBR, acoplador físicamente separado del chasis, movimiento real de manguera/tapa, conservación de la apertura V3 de cofres, comparación aislada V5/V6 y **24 capturas PNG nativas (8 facciones × recogida/despliegue + 8 vistas de 360°)**.
- `tests/test_g16_v6_shared_studio.gd`: abrir `scenes/UnitArtStudioWeb.tscn`, seleccionar G16, verificar controles y animación de abastecimiento dentro del visor unificado, cambiar de facción y capturar la escena real.
- `.github/workflows/g16-v1-native-logistics-qa.yml`: pruebas V1–V6 y subida de capturas.
- `.github/workflows/tarvoka-3d-pages.yml`: exportación integrada del visor, pruebas de animación V6 dentro del ensamblado y capturas de la interfaz real. Mantiene los tests previos V3–V5 y las comparaciones históricas, aislando V6 donde corresponde.

**Criterio de aprobación pendiente:** revisar capturas Godot de los ocho colores, el perfil cerrado sin huecos, visibilidad isométrica, animación conector-tapa sin intersecciones y rendimiento LOD8 Android. No fusionar como acabado final ni declarar G16 terminada antes de superar la verificación nativa y la inspección visual.
