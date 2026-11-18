# TARVOKA · HAT-29 V14.13 · Acabado central del rotor y continuidad animada

## Hallazgo visual en la versión 14.12
Se revisaron las capturas 3D **reales** de Godot correspondientes a V14.11 y V14.12. La transición de las palas ya se consideró correcta y la publicación V14.12 pasó su CI ([QA](https://github.com/edwinrodri12/Tarvoka/actions/runs/44257803017), [Estudio 3D](https://github.com/edwinrodri12/Tarvoka/actions/runs/44257770924)). El detalle más llamativo pendiente era **el enorme centro abierto/blanquecino del buje**, causado por la corona superior V10 en material metálico de alto brillo, alrededor de una tapa central sin acabado cohesionado.

## Acción de modelado nativo
- **Archivo:** `scripts/ui/AttackHelicopterHubCrownV1413.gd`, cargado después del acabado de raíz V14.12, únicamente en el helicóptero hero 3D.
- **Reutilización:** sustituye en sitio la `TorusMesh` de `A01V10_CoronaSuperiorRotor` por una sola `ArrayMesh` completamente cerrada y torneada (11 anillos, 28 segmentos radiales, 616 triángulos, 1.848 vértices de render). El mismo `MeshInstance3D` sigue bajo `A01V10_BujeMecanicoRotor`, descendiente del rotor principal original.
- **Forma:** faldón inferior a Y local -0.044 que se solapa físicamente con el buje V1 de altura 0.06; labio y bisel exterior radio 0.236; asiento torneado radio 0.170 compatible con los cuatro pernos V10 existentes; centro elevado sellado a Y local +0.033. La corona conserva su posición original Y=0.098 sobre el rotor.
- **Material:** grafito medio metálico `#5c7078`, metalizado 0.49, rugosidad 0.57: evita el aspecto de metal blanco quemado y permite leer el relieve con luz rasante. **No cambia** los paneles de color de las facciones ni otros metales de la aeronave.
- **Sin duplicación:** no crea más nodos visuales, rotaciones auxiliares, controladores de animación, palas, armas ni mecanismos. Conserva las cuatro bisagras y todas las piezas de V14.5–V14.12.
- **Comparación reversible:** original V10 `TorusMesh` y material guardados como metadatos del mismo objeto. `set_enabled(false)` restaura exactamente esos recursos; `set_enabled(true)` reactiva la cubierta V14.13.

## Estudio 3D
`Unidades → Helicóptero HAT-29 → Detalles` ahora incorpora:
- **V14.13: cubierta superior**: cámara cercana por encima del rotor.
- **V14.13: perfil de buje**: cámara lateral del mecanizado.
- **Comparar corona V10 / V14.13**: alterna geometría nativa sin reconstruir el helicóptero.
- **V14.13: giro lento de inspección**: reproduce el **movimiento nativo** de V1/V13 a un cuarto de velocidad sobre el mismo rotor y bajo la cámara macro, sin crear una nueva animación independiente.

## Verificación en Godot
Se agregó `tests/test_attack_helicopter_v14_13_motion.gd` y se incorporó al flujo de QA A01:
- Ejecuta **384 estados reales** (8 facciones × 48 por facción). Giro con `V13.pose`/rotor original V1, maniobras, ráfagas, impactos, explosiones y disparo de misiles con `CombatFXV14`.
- Verifica que el buje mantenga su transformada relativa constante al rotor giratorio, y que las 4 raíces V14.12 + 4 palas originales sigan sobre sus 4 pivotes V1 sin desprendimiento ni reconstrucción.
- Prueba los niveles de daño y que la destrucción oculte el rotor íntegro y la reparación lo restaure, sin afectar LOD10.
- `tests/test_attack_helicopter_v14_capture.gd` tiene **85 capturas previstas**: 75 de etapas anteriores más comparación de corona V10/V14.13, cuatro ángulos del giro y cuatro fases de combate (balas, explosión, misiles, destrucción).
- `tests/test_attack_helicopter_v9_studio.gd` valida la cámara y el botón de comparación del mismo modelo.
- `.github/workflows/tarvoka-3d-pages.yml` empaqueta el nuevo módulo en el **único visor web**; no crea otro enlace ni altera las otras unidades.

## Estado
Implementación real en GitHub. **No considerar V14.13 aprobado** hasta que el workflow de Godot valide los 384 estados/85 capturas y el workflow independiente Pages publique el proyecto unificado. Se mantienen los CI originales; ningún fallo de G13, edificios o menús debe silenciarse por esta prioridad.
