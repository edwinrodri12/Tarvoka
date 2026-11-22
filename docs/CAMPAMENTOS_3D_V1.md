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
  2 LOD × 4 estados = 256 ensamblajes, roles exclusivos, materiales opacos,
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

## Campamento de suministros — V2 hard surface (22 noviembre 2026)

Primera fase de perfeccionamiento de una estructura (no de la jugabilidad).
Capa `scripts/ui/CampSupplyFinishV2.gd`, aplicada automáticamente por
`CampModels3DV1.build("suministros",faccion,lod,damage)`, sin duplicar el
campamento ni crear una escena paralela.

- Cubierta modular de dos paneles **macizos y articulados** mediante bisagras
  reales, nervaduras y pintura de facción visible desde arriba; D2 retira una
  sección. Al plegarse rota físicamente (no se aplasta verticalmente todo el
  edificio como en V1).
- Dos depósitos de combustible cilíndricos **cerrados**, tapas estancas,
  válvulas, cunas metálicas y franjas oficiales de facción.
- Dispensador blindado, pantalla **opaca**, acoplador, manguera segmentada
  de caucho con boquilla, cajas de munición reforzadas, sujeciones y
  marcas de peligro geométricas.
- Conserva paredes V1 y esconde solamente accesorios y techo prototipo
  reemplazados, para evitar dobles caras/capas translúcidas.
- LOD8 conserva silueta y color; LOD13 añade herrajes, cierres y nervaduras.
- D0 completo, D1 con desgaste, D2 con daños importantes, D3 demolido.
- Suministros sólo en manos del **Logístico de infantería**. Los cuatro roles,
  el G16, recursos, curación y visión **no cambian**.
- Una prueba dedicada `tests/test_camp_supply_v2.gd` verifica 64 variantes,
  mallas volumétricas, pintura de 8 facciones, bisagras y manguera articuladas
  y exige **25 imágenes nativas** Godot. El conjunto de las cuatro estructuras
  verifica 256 variantes más 20 imágenes.

**Estado:** modelo V2 en revisión artística, a la espera de CI y revisión de
los PNG auténticos. Aún sin integración comprobada en el visor web original,
ni en la batalla Android. El diseño se entrega en PR, no se fusiona
automáticamente.

## Suministros V3 — lectura 360° y distribución de municiones (22-nov-2026)

Revisión motivada por inspección de PNG nativos V2: el depósito se entendía,
pero las cajas de munición quedaban detrás de la carpa y el interior parecía vacío.

- Nuevo módulo `scripts/ui/CampSupplyReadabilityV3.gd`, instalado sobre
  **el mismo** `SupplyV2_PremiumRig`, no en otra unidad, otro edificio o visor.
- Reubica las **mismas** cajas y su palé V2 a una plataforma frontal izquierda
  visible, dejando libre el pasillo central y el dispensador.
- Añade rótulos físicos de munición, barandillas, taller interior,
  consola opaca, depósitos con resguardos, señales industriales y colores de
  facción más anchos en ambos laterales (no pegatinas planas).
- Dos LOD conservan los volúmenes principales; LOD13 añade cerraduras,
  indicadores y fijaciones de forma limitada.
- El techo V2 y la manguera siguen articulados; D2 pierde una hoja,
  D3 conserva únicamente base/escombros.
- No altera valores tácticos, las seis identidades aprobadas, funciones de
  reabastecimiento, coste de recursos, IA ni guardados.
- QA propia `tests/test_camp_supply_v3.gd`: 64 ensamblajes (8 facciones ×
  2 LOD × 4 daños), 18 capturas auténticas Godot desde las cuatro diagonales
  y dos vistas de daño; verifica mallas sólidas y posición de las cajas.
- **QA verificada**: GitHub Actions run 45060363207, trabajo
  four-camps-godot-3d, finalizó SUCCESS: importación Godot 4.3, 256
  modelos V1, 64 modelos V2, 64 modelos V3 y 63 PNG en total
  (20 + 25 + 18), incluidos los cuatro ángulos V3.
  Evidencia: https://github.com/edwinrodri12/Tarvoka/actions/runs/45060363207
- **Estado:** V3 lista para inspección artística del usuario, no aprobada
  todavía como modelo final. Sin integración declarada en web/Android.
