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

## Reconocimiento V2 — torre óptica articulada (22-nov-2026)

El **segundo** campamento aprobado recibe modelo nativo 3D definitivo en
`scripts/ui/CampReconFinishV2.gd`, conectado directamente a la misma
factoría `CampModels3DV1.build("reconocimiento",faction,lod,damage)`.

- Torre de vigilancia con cuatro patas volumétricas, riostras cruzadas,
  zapatas de anclaje, plataforma superior y color de facción.
- Mástil telescópico operado por transformación física del grupo, cabezal
  óptico opaco con dos lentes volumétricas y movimiento de barrido angular.
- Dos paneles de antena abatibles, con articulaciones reales en la pose de
  montaje, y dos pequeños sensores de apoyo a nivel del suelo.
- Centro de control cerrado, consola de operaciones, pantalla táctica
  **opaca** y parasol físico. Acceso central libre. Colores de facción
  prominentes en el frente, los laterales y el cabezal de observación.
- Dos calidades: LOD8 ligero en Android y LOD13 para inspección con
  pequeñas fijaciones adicionales. Cuatro estados D0-D3, con mástil roto
  para D2 y ruinas sin torre para D3.
- No existe malla original V1 superpuesta: el modelo nuevo sustituye la
  fabricación de esa escultura, conservando la identidad de campamento.
- La animación es sólo visual. **No** modifica la niebla de guerra, el
  radio de visión, la precisión, la IA, los créditos ni la captura.
- Constructor aprobado exclusivamente: `infantry_sniper`.
- QA dedicada: `tests/test_camp_recon_v2.gd` valida 64 variantes,
  piezas opacas, telescopio, antenas, sensores, color de facción y
  25 PNG auténticos Godot desde cuatro ángulos, replegado, escaneo,
  daño y vista superior.

**Godot 4.3 CI verificado:** [workflow 45102805530](https://github.com/edwinrodri12/Tarvoka/actions/runs/45102805530),
estado SUCCESS; importación Godot, V1 256 modelos/20 PNG, suministros V2
64/25, suministros V3 64/18 y reconocimiento V2 **64 variantes y 25 PNG**.
Total: 88 imágenes nativas de revisión subidas como artefacto GitHub.
Inspección visual confirmada desde las cuatro diagonales y en modo replegado.

**Estado:** Reconocimiento V2 modelado y validado automáticamente, pendiente
de revisión estética final e integración en el visor 3D unificado. No se ha
publicado en APK Android ni modificado la lógica de niebla de guerra; PR en
borrador hasta integrar y aprobar.

## Defensivo V2 — fortificación desplegable del ingeniero (23-nov-2026)

Tercera de las cuatro esculturas aprobadas. Se crea
`scripts/ui/CampDefenseFinishV2.gd` como sustitución de la malla
defensiva provisional mediante `CampModels3DV1.build("defensivo",faccion,lod,damage)`.

- Dos barreras **volumétricas** de acero con blindaje, bordes, bisagras,
  puntales y amplias marcas del color de facción. Ambas giran físicamente
  hasta su posición defensiva y dejan espacio delante para ingresar.
- Protección posterior con dos o tres hileras de sacos de arena estancos
  (según LOD), columnas, soportes y franja superior de la facción.
- Refuerzos bajos en los flancos, pequeñas cajas de material, marcas en
  el piso y balizas del acceso frontal.
- El centro tiene suelo definido y permanece libre: no hay torre de
  tiro, soldado, arma automática, ametralladora o generador de recursos.
  El ingeniero es el constructor exclusivo `infantry_engineer`.
- D0: íntegro; D1: rayaduras/desgaste del kit visual global; D2: barrera
  derecha caída, varios sacos desplazados y roturas; D3: sin fortificación
  intacta, plataforma y restos visibles.
- LOD8 para mapa Android y LOD13 de inspección. Todas las piezas son
  `BoxMesh` o `CylinderMesh` cerrados, con materiales opacos.
- Animación `pose_deploy` articula ambas defensas. **No** se implementa
  aún un bonus táctico, reducción de daño, colisiones ni reglas de
  ocupación, ni se modifican la IA y los datos guardados.
- Prueba `tests/test_camp_defense_v2.gd`: 64 variantes
  (8 facciones × 2 LOD × 4 niveles de daño), inspección del centro libre,
  materiales cerrados, plegado y 24 PNG reales de Godot (360°, recogido,
  daños y vista cenital).

**QA validada:** GitHub Actions [45204420347](https://github.com/edwinrodri12/Tarvoka/actions/runs/45204420347),
Godot 4.3 importación SUCCESS; Defensa V2 aprobó **64 variantes**
y **24 capturas nativas**, incluidas 4 diagonales, 4 posiciones recogidas,
D1/D2/D3 y vista superior del centro libre. También pasaron las baterías
anteriores de 4 campamentos, Suministros V2/V3 y Reconocimiento V2.
Se generaron **112 PNG de revisión** en total. Primera ejecución diagnosticó
un falso error de QA al consultar `global_position` antes de insertar
el modelo en SceneTree; se corrigió usando transformaciones locales
acumuladas; la ejecución verde confirma el arreglo.

**Estado:** modelo defensivo V2 validado técnicamente y revisado en 360°,
aún pendiente de aprobación artística definitiva, incorporación al
visor online original y prueba de rendimiento en Android. Ninguna
regla de combate se cambió.

## Médico V2 — estación sanitaria desplegable (23-nov-2026)

Última de las cuatro esculturas acordadas. `scripts/ui/CampMedicalFinishV2.gd`
sustituye íntegramente la geometría temporal de la carpa sanitaria V1,
sin crear una nueva clase ni escena paralela. Se conecta a
`CampModels3DV1.build("medico",faccion,lod,damage)`.

- Carpa desmontable de paredes macizas, entrada real abierta, cubierta
  reforzada de dos hojas **articuladas** con bisagras, cuerdas y color
  de facción en techo y laterales.
- Camilla médica claramente reconocible desde la cámara de batalla:
  colchón macizo, respaldo inclinado, almohadilla, barandas y patas;
  ruedas y herrajes en LOD13.
- Gabinete de medicinas estanco, cruz **turquesa ficticia** elevada,
  soporte clínico para bolsas de suero y monitor de seguimiento
  **opaco**. Nunca se representa el emblema protegido de Cruz Roja.
- Marcas grandes y visibles de las ocho facciones en el acceso, puerta
  del botiquín, camilla, cubierta y laterales.
- D0 intacto, D1 con desgaste, D2 con hoja del techo caída y daños
  adicionales, D3 únicamente plataforma y restos. LOD8 Android
  reduce herrajes; LOD13 aporta costuras y piezas pequeñas.
- `pose_deploy` rota físicamente los dos paneles del techo en D0–D1 y
  la hoja superviviente en D2. Todas las piezas usan sólidos cerrados
  (`BoxMesh` y `CylinderMesh`) y materiales opacos.
- Constructor exclusivo `infantry_medic`. No altera en absoluto
  reglas de curación, créditos, selección de unidades, ocupación,
  defensa, combate, IA o efectos de partida.
- `tests/test_camp_medical_v2.gd` valida 64 ensamblajes
  (8 facciones × 2 LOD × 4 niveles de daño) y requiere 24 renders
  reales (cuatro ángulos, estados plegados, daños y vista superior).

**Estado inicial:** esperando importación Godot 4.3, ejecución del workflow
y evaluación de las imágenes reales; no afirmar integración al visor
online existente ni al juego principal.

## Integración al ÚNICO Estudio 3D de TARVOKA (23-nov-2026)

Se añadió una integración **aditiva** al pipeline real de publicación
`.github/workflows/tarvoka-3d-pages.yml`, sin construir un segundo
visualizador ni modificar los catálogos existentes.

- `scripts/publishing/CampUnifiedStudioAdapterV1.gd.txt`: subclase
  del **último** adaptador actual en el pipeline,
  `HeadquartersV24SharedStudioAdapter.gd`. Se copia temporalmente como
  `scripts/ui/CampUnifiedStudioAdapterV1.gd` en la misma exportación de Pages.
  El archivo fuente es `.gd.txt` porque los adaptadores heredados sólo
  están completos al ensamblar la publicación y no existen en `main`.
- El workflow copia los módulos nativos **desde el SHA del PR/main actual**,
  no desde una rama vieja, a la única escena existente
  `scenes/UnitArtStudioWeb.tscn`, que ya contiene el catálogo de
  unidades, Cuartel General, Base Aérea, Base Naval, Cuartel de
  Infantería, Ciudades, Central Eléctrica heredada y Taller de Blindados.
- El selector **EDIFICIOS** conserva los siete índices originales 0–6,
  y agrega únicamente los cuatro campamentos temporales en los índices
  7–10: Suministros, Reconocimiento, Defensivo, Médico. No reemplaza
  el visor de unidades ni el `SubViewport` real de la escena.
- Nuevas opciones que **sí funcionan** con la factoría de arte:
  elección de ocho facciones o neutral, LOD8/LOD13, daño D0–D3,
  desplegar/replegar, rotación y zoom. La escena sigue siendo un único
  motor Godot 4.3 y una sola cámara.
- `scripts/publishing/TestFourCampsSharedStudio.gd.txt` se materializa
  en el propio ensamblaje como test nativo; exige que los cuatro
  modelos sean seleccionables, que los siete edificios anteriores y
  las unidades sigan funcionando, y que cuatro campamentos aparezcan
  con mallas reales en el **mismo** `SubViewport`. Captura siete
  imágenes de evidencia del visor real y prueba selector de facción,
  daños, detalle Android y montaje.
- Pipeline en PR: primero valida el mismo visor y, tras la exportación
  completa, adjunta **el build/web del mismo Estudio** como artefacto
  `tarvoka-mismo-estudio-3d-cuatro-campamentos` para revisión.
  Por seguridad, el PR **no despliega GitHub Pages ni fusiona a main**
  hasta que las pruebas de integración y el acabado estén aprobados.

**Distinción:** modelos nativos aislados ya aprobados (136 PNG de cuatro
modelos y versiones). Integración al **visor compartido en preparación
y CI pendiente**, no anunciar como publicado mientras no se compruebe
el smoke test con la escena real ni la salida web.

### Integración del visor: robustecimiento de revisión (23-nov-2026)

- El adaptador preserva el ángulo, zoom y apertura/plegado cuando se
  cambia la facción, LOD Android o daños **del mismo campamento**; al
  pasar a otro campamento inicia una cámara de inspección normal.
- La misma escena web permite acceso por parámetro opcional
  `?campamento=suministros`, `?campamento=reconocimiento`,
  `?campamento=defensivo` o `?campamento=medico`. Solo se interpreta
  en exportación HTML5 y valida que el nombre esté entre los cuatro
  aprobados antes de seleccionar un índice.
- La prueba `TestFourCampsSharedStudio.gd.txt` ahora compara los
  píxeles de la escena real con el modelo visible/oculto. Esto impide
  declarar aprobado un visor con una captura vacía o solo iluminación
  de fondo. También comprueba persistencia de cámara, facción y estado
  replegado durante reconstrucción y retorno a modelos anteriores.
- El workflow `tarvoka-3d-pages.yml` admite
  `workflow_dispatch` directamente sobre
  `feat/campamentos-3d-v1-20261122`. El checkout de modelos usa esa
  rama en ejecución manual; publica un artefacto de vista previa.
  **Seguridad:** ejecutar manualmente la rama experimental NO puede
  sustituir GitHub Pages público. Solo `main` o los eventos
  permitidos previamente pueden realizar despliegue.

**Bloqueo pendiente comprobado:** la API de GitHub no reporta
ningún workflow de Pages ni de QA asociado al último SHA de esta
rama, aunque hay ejecuciones satisfactorias de los modelos en SHA
anteriores. El workflow del Studio sigue sin validación integrada.
Los 136 PNG de la QA de modelos NO prueban carga en el visor publicado.

## Desbloqueo de compilación automática de la web (23-nov-2026)

**Antes:** los últimos commits de `PR #676` no tenían ninguna
ejecución Actions para el nuevo adaptador. Se necesitaba lanzar
manualmente `workflow_dispatch`.

**Corregido:** `.github/workflows/tarvoka-3d-pages.yml` tiene ahora
`push` sobre `feat/campamentos-3d-v1-20261122` (solo los archivos
afectados), mantiene una cola de concurrencia específica y obtiene
los módulos desde el **SHA real de esa rama**, no de `main`.
La vista previa es un artifact del mismo sitio Godot y está
**expresamente prohibido desplegarla a GitHub Pages desde la rama
experimental**. Se mantiene también la ejecución manual opcional.

- GitHub registró una ejecución real de compilación del visor compartido:
  **[Actions #45242472804](https://github.com/edwinrodri12/Tarvoka/actions/runs/45242472804)**.
- El mismo cambio activó el test nativo completo en la rama:
  **[Actions #45242496321](https://github.com/edwinrodri12/Tarvoka/actions/runs/45242496321)**,
  estado **SUCCESS**. Verifica todos los modelos y fotos reales
  anteriores sin alterar mecánicas.
- El build compartido pasó preparación del repositorio/escena y
  añadidura del adaptador de los cuatro campamentos antes de llegar
  a la fase `Export native Godot 3D browser studio`, que ejecuta el
  smoke test de selección y visibilidad. **Todavía no se debe afirmar
  que este último test ha pasado** sin observar la conclusión final.

No hay despliegue del visor público ni fusión de la rama.
