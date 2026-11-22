# TARVOKA — cuatro campamentos desplegables V1 (arte nativo Godot 4.3)

**Alcance:** primera escultura 3D real, editable y original de las únicas cuatro
estructuras desplegables aprobadas. No crea edificios permanentes, ni una quinta
clase de campamento, ni nuevas unidades de infantería.

| Campamento | Constructor exclusivo | Silueta principal | Efecto de diseño acordado (NO implementado aquí) |
| --- | --- | --- | --- |
| Suministros | Logístico de infantería | carpa, dispensador, manguera, bidones y cajas | restaurar combustible/munición a la unidad ocupante pagando |
| Reconocimiento | Francotirador | estación de observación, mástil óptico y consola | ampliar visión sin exigir ocupante |
| Defensivo | Ingeniero | barreras, sacos terreros y emplazamiento abierto | proteger solo a la unidad ocupante |
| Médico | Médico de combate | carpa sanitaria, camilla y módulos | curar solo infantería ocupante pagando |

## V1 técnica

- API: `scripts/ui/CampModels3DV1.gd` -> `build(kind,faction,lod,damage)`.
- `kind`: `suministros`, `reconocimiento`, `defensivo`, `medico`.
- `faction`: 0–7, mismos colores oficiales del estudio; -1 neutral.
- `lod`: 8 Android o 13 inspección cercana; `damage`: 0–3.
- `pose_deploy(root,progress)`: animación solo visual del montaje y repliegue.
- Mallas nativas `BoxMesh` y `CylinderMesh`, acabados opacos PBR y
  geometría volumétrica cerrada, sin planos transparentes ni siluetas SVG.
- Base desmontable compacta, apertura delantera y acentos notorios de facción.
- El símbolo sanitario es una cruz **turquesa ficticia**, no un emblema de Cruz Roja.
- El G16 conserva su módulo gráfico de suministros; no se reemplaza ni se
  transforma en nuevo constructor de los cuatro campamentos de infantería.

## Verificación

- Prueba nueva: `tests/test_camp_models_v1.gd` comprueba 4 tipos × 8 facciones ×
  2 LOD × 4 estados = 128 ensamblajes, roles exclusivos, materiales opacos,
  piezas reales, color facción, fase de despliegue y 20 renders reales Godot.
- CI dedicado: `.github/workflows/camp-art-native-qa.yml`. Las capturas se
  conservan en el artefacto `tarvoka-four-camps-native-3d-v1` para inspección.
- **Estado:** V1 para revisión artística; no afirmar QA aprobada hasta observar
  el workflow y las imágenes.

## Alcance pendiente antes de cierre

1. Revisión 360° del usuario y refinamientos visuales de las cuatro esculturas.
2. Integración en el mismo Estudio 3D de TARVOKA. El repositorio `main`
   actualmente referencia `scripts/ui/CombinedArtStudioWeb.gd` y
   `scenes/UnitArtStudioWeb.tscn`, pero no los contiene; no fingir que el
   visor online ya carga estos modelos.
3. Mapeo a una instancia de campamento de `BattleSession`, acción exclusiva
   de construcción, duración, costes, ocupación, captura/destrucción y guardado.
   Dichos efectos son responsabilidad del motor táctico, no del modelo 3D.
4. Rendimiento medido en Android real; la QA nativa de GitHub no sustituye eso.

**Decisión de producto:** ningún edificio permanente nuevo, ni centro de drones,
depósito de artillería, central eléctrica, astillero ni otro almacén de suministros.
