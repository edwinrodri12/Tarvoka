# TARVOKA — G16 V5 | materiales PBR, cristales opacos y deterioro 3D

**Estado:** nueva capa artística de Godot 4.3 desarrollada sobre la G16 V4. Implementada en una rama de revisión y vinculada al **mismo TARVOKA Estudio 3D**; no declarar final ni publicada hasta pasar CI nativo y web.

## 1. Calidad visual real, sin texturas planas

- Los cuatro cristales V2 conservan su **BoxMesh 3D sólido**, con transparencia DESACTIVADA, color azulado oscuro, roughness 0.09 y clearcoat 0.92. No hay paredes perforadas ni cristales transparentes. Al desactivar V5 se recupera la **instancia exacta** de material original V2 de cada cristal.
- En las puertas y costados del camión aparecen elementos físicos de metal pulido, aluminio satinado, superficies de acero, juntas de caucho, remaches, tapas de compartimento, reflejos finos y franjas de pintura de facción 3D.
- Ajuste por nivel de detalle: en LOD13 se modelan seis remaches por puerta y cinco pernos por área de carga; en LOD8 se reduce a tres de cada uno, con geometrías cilíndricas de menor segmento.
- Los ocho colores originales se conservan; los escudos y las bandas superiores adquieren contraste sin sobrescribir los materiales tácticos.

## 2. Deterioro y destrucción reversible

Estados gráficos **0–4**, acumulativos y sincronizados con V3/V4:

| Nivel | Geometría nueva |
|---|---|
| 0 | Carrocería maciza, metal satinado, cristales opacos y elementos intactos |
| 1 | Arañazos físicos, rozaduras de pintura y bordes oxidados |
| 2 | Grietas finas **sobre** el cristal opaco original, juntas deformadas |
| 3 | Depósito chamuscado, tubo expuesto, borde de municiones quemado, guardabarros ennegrecidos |
| 4 | Techo y ceja frontal chamuscados, llamas cónicas emisivas y destellos sólidos animados |

- El humo cónico V4 y los dos paneles blindados articulados se conservan. V5 añade llamas físicas pequeñas, de tres tonos y progresión con el eje de destrucción; no añade emisores transparentes ni sprites.
- El botón **reparar** restituye visualmente el modelo, sin ejecutar mecánicas de reparación ni alterar el HP.
- Mantiene la capacidad táctica real de reabastecimiento de la G16 V3 FINAL: munición/combustible, reserva limitada y restricciones por turno. V5 es **solo arte**, sin lógica de juego.

## 3. Arquitectura y visor unificado

- `scripts/ui/G16PremiumMaterialsDamageV5.gd`: generación 3D procedimental, PBR, `apply`, `show_finish`, `set_damage`, `pose_wreck`, `restore` y `sync`.
- `scripts/ui/UnitModels3D.gd`: mismo build `logistics_mobile` con secuencia **V1→V2→V3→V4→V5**, ambas LOD; las animaciones siguen sincronizando todas las capas.
- `scripts/ui/BastionStudioAdapter.gd`: selector «G16 · Logística blindada 6×6 · V5 materiales y desgaste», controles **V5 mostrar** y **comparar V4**, daños 0–4 y destrucción 3D que sincroniza V4 y V5. Conserva grúa, rampa, combustible, campamento visual y cambio de facción en la interfaz existente.

## 4. QA de aceptación

- `tests/test_g16_v5_native_materials.gd`: 8 facciones × 2 LOD, materiales de cuatro `BoxMesh` con opacidad absoluta, clearcoat, comparación con restauración exacta de materiales V2, remaches reales, daños 0–4, llamas, suministros y **22 capturas Godot**: ocho facciones, ocho ángulos, cinco estados y comparación V4.
- `tests/test_g16_v5_shared_studio.gd`: arranca `scenes/UnitArtStudioWeb.tscn` y comprueba controles V5, daños, reparar, suministro, facción y screenshot del visor original.
- `.github/workflows/g16-v1-native-logistics-qa.yml`: V1/V2/V3/V4/V5, sin eliminar la auditoría táctica de abastecimiento.
- `.github/workflows/tarvoka-3d-pages.yml`: copia script V5 y pruebas a la compilación de Pages, conserva preload al integrar modelos y bloquea publicación si falla cualquier etapa.

**Objetivo de aceptación:** ningún cristal transparente, ninguna pared abierta, materiales reversibles, buen rendimiento en los dos LOD y ninguna regresión de las demás unidades o de la G16 táctica.
