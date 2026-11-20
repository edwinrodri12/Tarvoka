# TARVOKA — Taller de Blindados V2 integrado en partida 3D moderna

## Sitio real y comportamiento

La economía moderna ya crea una instalación `armor_plant` para cada bando. Produce blindados y tanques mediante `UrbanEconomy`, en el mismo lugar y con las mismas reglas. **No se ha agregado un nuevo tipo de instalación**, ni se ha duplicado el reabastecimiento de unidades o los campamentos logísticos.

En `BattleTerrain3D._make_sites()` el antiguo cubo genérico de este sitio se sustituye por `ArmoredWorkshopBattle3D.build_site()`, que usa el **mismo** `ArmoredWorkshopMobileLOD3D` del visor compartido, con los acabados finales de color de facción y daños D0–D4. Su escala es **0,099** sobre la geometría de taller: incluso la nave N3 (cimientos ~22,9 × 21,8 m de arte) ocupa ~2,27 × 2,16 m dentro de una sola casilla de 2,4 m. No hay nuevos obstáculos ni casillas jugables.

El menú táctico `SiteInteractionData` llama ahora a la instalación **Taller de Blindados**, conservando la clave interna `armor_plant` y su catálogo de producción original. La ficha `BuildingInfoPanel` indica que los niveles y el daño son visuales.

## Evolución y estados visuales

- `visual_level` explícito del sitio: N1 (una bahía), N2 (dos bahías) y N3 (tres bahías); por defecto N1, sin cambios de costos, capacidad o progresión económica.
- `visual_damage_stage`: D0 intacto, D1 leves quemaduras de cubierta, D2 daños y escombros moderados, D3 nave parcialmente derrumbada sin techo suspendido y D4 destruida. Esto **no es HP real del edificio**.
- Se conserva exactamente la paleta de las ocho facciones, con `FactionIdentity`; los sitios neutrales y enemigos explorados pero no visibles usan **la paleta neutral**.
- Un sitio enemigo escondido por la niebla **no revela** ni el nivel mejorado ni el daño actual hasta que vuelva a quedar visible: solo se muestra su silueta N1 D0 neutral conocida.
- El `ArmoredWorkshopBattleLOD` cambia a `DISTANTE` cuando el taller queda pequeño en pantalla y vuelve a `TÁCTICO` al acercar la cámara, con histéresis y revisión a 4 Hz; conserva nodo, posición, propiedad pública e interacción de casilla.

## Animaciones

Las animaciones cinemáticas N1→N3 y proyectiles/explosiones que producen D0→D4 **ya existen en el visor 3D** (`ArmoredWorkshopEvolutionVFX3D.gd`). **No se disparan automáticamente durante el combate actual**: TARVOKA todavía no permite atacar instalaciones. Hacerlo sin eventos autorizados inventaría un ataque sobre el edificio y alteraría el equilibrio. En la partida 3D se dibuja el estado visual proporcionado por el sitio; cuando existan eventos reales de daño a estructuras, deberán conectarse al VFX mediante una interfaz explícita y decisiones de juego aprobadas.

## Pruebas del juego real (no del visor artístico)

`tests/test_armored_workshop_live_battle_v1.gd`:
1. Inicia una partida moderna real con `BattleSession.start` y comprueba que ambos `armor_plant` se renderizan con arte V2; prueba que el estado completo, dinero y producción siguen iguales tras renderizar.
2. Recorre N1–N3 × D0–D4 en `BattleTerrain3D.build`, utilizando los modelos completos de daños y niveles existentes.
3. Prueba 8 facciones, paleta neutral bajo niebla, instalación enemiga oculta y no filtración de nivel/daño.
4. Cambia manualmente TÁCTICO ↔ DISTANTE sin cambiar el nodo raíz ni sus coordenadas; confirma escala de casilla y materiales 3D.

`tests/capture_armored_workshop_live_battle_v1.gd` renderiza 7 vistas nativas de **partidas reales**: N1/N2/N3 D0, N3 D2/D3/D4, y N3 en distancia móvil. El flujo `.github/workflows/armored-workshop-live-battle-qa.yml` ejecuta ambos con Godot 4.3 Mesa OpenGL.

**Estado de integración:** código integrado en rama artística `art/armored-workshop-v1-20261119` y documentado en PR #629 en borrador. **No se afirma que esté ya fusionado en `main` ni instalado en la APK**. Las pruebas físicas Android y la integración de eventos de ataque a edificios quedan pendientes de reglas de combate aprobadas.
