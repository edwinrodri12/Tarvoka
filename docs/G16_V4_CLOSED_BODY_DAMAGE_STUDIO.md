# TARVOKA · G16 V4 — escultura 3D premium y destrucción articulada

Estado: implementada sobre la G16 V3 en rama de revisión; las comprobaciones nativas y la integración en visor web compartido son obligatorias antes de fusionar y desplegar.

## Alcance artístico

- **Carrocería cerrada**: 12 zonas principales construidas como `ArrayMesh` octagonales de extremo a extremo: cada pieza tiene dos tapas de 6 triángulos, ocho laterales cerrados de 2 triángulos cada uno, **28 triángulos / 84 vértices** de superficie por pieza. No hay planos sin espesor ni materiales transparentes.
- **Silueta blindada:** techo biselado real, frente inclinado, paragolpes profundo, escudo inferior, ceja de cabina, divisoria trasera del habitáculo, barandales superiores de caja.
- **Color de facción visible:** escudos originales y opacos de tamaño tácticamente legible en ambas puertas, laterales de carga, nervadura superior y asas de botiquines (8 facciones).
- **Materiales diferenciados:** acero opaco PBR, aluminio satinado, superficies cromadas, plástico y gomas oscuras; faros con reflectores emisivos y sus biseles independientes, espejos, luces ámbar, escalones con antideslizante y botiquines de carga.
- **Animación de destrucción:** dos fragmentos blindados sobre pivotes que giran, rejilla deformada, humo volumétrico sólido y nueve brasas luminosas a distancia de héroe (cuatro en LOD8). Se conservan los cuatro niveles V3, con avance temporal progresivo. El botón *reparar* vuelve al estado visual intacto.
- **Cierre físico:** la cabina V1 y las cuatro ventanas volumétricas con PBR opaco V2 nunca se suprimen ni se perforan. El daño visual no modifica vida, daño, combustible ni economía.

## Arquitectura

- `scripts/ui/G16LogisticsSculptDamageV4.gd` incorpora `apply(root,faction)`, `show_finish(root,visible)`, `set_damage(root,level)`, `pose_wreck(root,progress)`, `restore(root)`.
- `scripts/ui/UnitModels3D.gd`: build de G16 V1→V2→V3→V4, todos en una **misma instancia** `logistics_mobile`; el rig conserva las 8 animaciones y restablecimiento físico.
- `scripts/ui/BastionStudioAdapter.gd`: el mismo TARVOKA Estudio 3D incluye botones `g16_v4_on`, `g16_v4_off`, `g16_v4_wreck`, `g16_damage_0..4`. Una secuencia Tween mueve piezas y humo durante 2,8 segundos.
- Los botones de comparación V1/V2/V3 apagan la capa V4 de forma coherente y permiten restaurarla sin crear un visor nuevo.
- No hay cambio del arsenal `logistics`: G16, HP8, movimiento4, ataque0, coste300, fábrica.

## Validación exigida

`tests/test_g16_v4_native_360.gd`:
- 8 facciones × LOD8/LOD13, 12 mallas cerradas originales, cuatro ventanas 100% opacas, paneles de facción y diferenciación visual V3/V4.
- Secuencia 0→4 de daño con panel que rota, humo que se desplaza, brasas visibles y recuperación a 0; abastecimiento en V4 conserva tapas articuladas.
- **22 imágenes reales de Godot:** 8 facciones, 8 ángulos de órbita, 5 niveles de daño y 1 captura V3 de control.

`tests/test_g16_v4_shared_studio.gd`:
- Arranca `scenes/UnitArtStudioWeb.tscn`, verifica los controles en selector original y pulsa botones V3/V4, animación de destrucción, reparación, carga y cambio de facción.
- Produce una captura de **la G16 dentro del visor unificado**, no una escena auxiliar.

Los workflows `.github/workflows/g16-v1-native-logistics-qa.yml` y `.github/workflows/tarvoka-3d-pages.yml` deben pasar ambos grupos de pruebas antes de declarar V4 publicada. Mantener las pruebas V1, V2, V3 y las otras unidades y edificios.
