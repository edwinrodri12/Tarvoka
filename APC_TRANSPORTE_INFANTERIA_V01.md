# TARVOKA — APC G07: transporte real de infantería V0.1

**Implementación:** PR [#335](https://github.com/edwinrodri12/Tarvoka/pull/335), apilada sobre la [#333](https://github.com/edwinrodri12/Tarvoka/pull/333), que depende de [#328](https://github.com/edwinrodri12/Tarvoka/pull/328). **No fusionada en main.** Se conservan las estadísticas y precios de todas las unidades y las 8 identidades visuales.

## Mecánica implementada

- **APC G07: 2 soldados** como máximo; no añade capacidad de carga al IFV G08 (decisión de diseño independiente).
- Admitidos: Guardia (`line`), Rastreador (`scout`), Asaltante (`assault`), Ingeniero (`engineer`) y Rompedor (`piercer`). No admite APC, IFV, tanques, artillería, drones, aeronaves, barcos ni soldados enemigos.
- **Embarcar:** seleccionar el APC y tocar un soldado propio ortogonalmente adyacente; confirmar orden. Ambos deben poder moverse y no haber gastado su acción o movimiento. Embarcar termina las acciones de ambos durante el turno. No ocupa una segunda casilla ni genera tropas adicionales.
- **Transportar:** en el siguiente turno, el APC avanza con los ocupantes como una unidad blindada real; mantiene combustible y movilidad con ruedas según lluvia/nieve, sin bonificaciones de poder.
- **Desembarcar:** seleccionar APC con ocupantes, pulsar **Desembarcar**, elegir una casilla amarilla libre, visible, terrestre y ortogonalmente adyacente, confirmar. Puede hacerse después del movimiento del APC **si el APC no ha consumido su ataque/acción**. Sólo sale un soldado por turno: queda con `acted` y `moved` activados hasta el siguiente turno de su facción.
- **Destrucción:** un APC destruido por disparo o contrataque pierde inmediatamente **todos sus pasajeros**. No existe rescate implícito ni aparición en casillas vecinas; la versión V0.1 exige el riesgo de transportar tropas valiosas.
- **Captura:** sólo una unidad de infantería desplegada sobre la ciudad/taller puede capturar al finalizar el turno. Un pasajero nunca captura desde dentro. La IA puede desembarcar sobre ciudad neutral/enemiga conocida si es legal.
- **Niebla:** los pasajeros no aparecen como unidades sobre el terreno, no disparan, no incrementan visibilidad ni son seleccionables; el rival sólo puede conocer la existencia pública del APC, **no el nombre, cantidad ni HP de sus pasajeros**. La lectura de estado visible para la IA omite el manifiesto enemigo incluso con niebla desactivada.
- **Población:** un pasajero sigue contando para el máximo global de **256 unidades**. Los IDs se reservan durante el embarque para impedir que una fábrica genere otra unidad con la misma identidad.
- **Compatibilidad:** se usa `cargo` opcional dentro de la unidad APC en el **guardado JSON v1**. Las partidas antiguas sin `cargo` continúan siendo válidas. El cargamento conserva identidad, HP, munición y estadísticas originales; los campos numerales se normalizan al decodificar. Guías de seguridad rechazan IDs repetidos, bandos diferentes, pasajeros sin vida, datos falsos, carga anidada, posiciones inyectadas y >2 ocupantes.

## Pantalla y controles

Tanto el **tablero clásico** como la **vista isométrica** ofrecen casillas azules de embarque y casillas amarillas de desembarque cuando se activa el modo. Las órdenes importantes respetan la preferencia de confirmar con dos toques o con el botón Confirmar. Existen botones **Desembarcar** en el HUD horizontal Android y en la barra lateral de PC.

El propio jugador ve un indicador `1/2` o `2/2` sobre sus APC con soldados a bordo, además de los pasajeros y sus HP en el resumen. **No se muestra el contenido del APC rival**. Al cancelar, cambiar turno, iniciar otra partida o recargar un guardado se cancela el modo de desembarque sin mover soldados. No se prometen animaciones específicas de puertas/soldados 3D en esta PR; la acción funcional sí está integrada en combate.

## IA autónoma de transporte

`APCTransportAI.gd` se ejecuta después de las urgencias de combate, defensa de relés, suministros y protección de guarniciones, pero antes de la navegación habitual a ciudades. Selecciona **sólo infantería capaz de capturar** junto a un APC propio listo y una ciudad **conocida** a distancia mínima. Las órdenes reales usan `BattleSession.embark`, `move` y `disembark`: no teletransporta tropas ni mueve al APC dos veces.

La IA mantiene la privacidad de la niebla al decidir objetivos y rutas en `Visibility.observed_state`, y respeta los turnos y disponibilidad de acciones. No optimiza todavía el transporte multietapa en todos los mapas ni rescata infantería ante fuego enemigo; son prioridades de IA para otra iteración.

## Evidencia Godot 4.3 y Android

- `tests/test_apc_transport_engine.gd`: **7 casos** completos de plazas, acción, movimiento, descarga, vida, guardado, privacidad y destrucción.
- `tests/test_apc_transport_ui.gd`: las dos vistas reales con toques/confirmación/cancelación, botones lateral y móvil y resúmenes.
- `tests/test_apc_transport_save_security.gd`: **15 manifiestos falsificados** rechazados, JSON v1 anterior, mapas 24×18/40×30 y límite real de 256 sumando las dos plazas ocupadas.
- `tests/test_apc_transport_ai.gd`: **4 pruebas espejo**: APC cargado, ruta, desembarco, captura legal y prohibición de información de ciudades ocultas.
- `.github/workflows/apc-transport.yml` bloquea los cambios incompatibles y ejecuta regresiones existentes de movilidad, niebla, munición, guardado y el Rompedor contra G09.
- [Run APC exitoso en Godot](https://github.com/edwinrodri12/Tarvoka/actions/runs/43661591177) del commit `2a6d5f71`, incluye motor, UI, IA, JSON y regresiones antiguas. Se ejecuta una nueva CI por cada modificación posterior. Los mensajes intencionales de JSON inválido en pruebas de seguridad **no se confunden con errores de script**.
- [Compilación Android depuración exitosa](https://github.com/edwinrodri12/Tarvoka/actions/runs/43661591175) del mismo commit. **No equivale a medir FPS ni probar táctil en un dispositivo físico**.
- Revisión general `Godot 4 headless rules` de 124 etapas: revisar el resultado final del commit vigente antes de fusionar.

## Faltantes y límites de producto

Esta entrega no implementa capacidad de carga del IFV, transporte anfibio/aéreo, rescates tras destrucción, abordaje/captura de APC enemigos, animación 3D de compuertas ni multijugador en red. El embarque por selección de APC y desembarque mediante botón es funcional tanto para ratón como táctil; las transiciones de animación 3D son trabajo de arte separado. Los balances 8 jugadores no pueden inferirse de las simulaciones de dos bandos.

**Estado:** funcional en rama apilada y con pruebas focalizadas verdes; mantener **DRAFT**, sin mezclar con la PR #320/#323 del Ingeniero ni fusionar automáticamente.
