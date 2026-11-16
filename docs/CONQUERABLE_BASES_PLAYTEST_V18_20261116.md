# TARVOKA — Base militar neutral operativa en laboratorio (v1.8)

**16 noviembre 2026 · PR #394 experimental, todavía sin integrar en el APK**

## Problema que se está resolviendo

El usuario definió la regla de TARVOKA: **los únicos edificios que un jugador puede construir son campamentos**, cada uno reservado para una especialidad de infantería. **Las instalaciones que producen unidades son posiciones fijas**, limitadas por tamaño de mapa, propiedad inicial escasa y varios emplazamientos neutrales que se pueden conquistar. El Cuartel, instalaciones blindadas, artillería, drones, aire y naval se pueden evolucionar de nivel, pero nunca fabricar desde cero.

El motor actual aún usa `UrbanEconomy.MAX_SITES=16`; un escenario de 40×30 con 16 ciudades y 14–16 bases implica 30–32 lugares. Elevar solamente la constante sería insuficiente porque los guardados, ingresos y la IA no reconocerían el sistema territorial nuevo.

## Prototipo escrito

**Archivo:** `scripts/experiments/CapturableProductionV18.gd`.

El prototipo hace la conquista y producción de bases neutrales **sin modificar `scripts/core`**:

1. Inicia una sesión real de `BattleSession` y conserva un estado principal válido para `SaveCodec` v1, pero usa `StrategicMapSitesV17` como fuente de las posiciones y propietarios del mapa expandido.
2. La infantería captura una instalación permaneciendo en su casilla **dos turnos propios**; el turno rival no reinicia automáticamente el progreso. La captura cambia propietario/ciclo de producción y **no añade una nueva base**.
3. **Un astillero marítimo se captura desde la casilla terrestre simétrica adyacente al muelle** (`capture_pos`) y sigue produciendo barcos sobre agua. La infantería no puede colocarse sobre agua para capturar.
4. Una base neutral capturada puede producir las unidades del dominio correspondiente. Para respetar las reglas de precio, casilla ocupada, munición inicial, producción una vez por fase e ID único, el prototipo crea una economía temporal que contiene únicamente la instalación elegida y llama a **`BattleSession.purchase`**. Su resultado en unidades, créditos y número serial se copia al estado oficial válido, y la instalación paralela registra su `produced_turn`.
5. La renta de las ciudades se calcula desde el registro territorial total, no solo las cuatro ciudades conocidas por el motor. La renta que `Session.end_turn` agrega automáticamente se **sustituye** por la renta calculada, impidiendo ingresos duplicados.
6. Hay una captura experimental de ciudades que exige dos turnos propios. Se mantienen los ingresos y la posición de las ciudades entre capturas; el crédito de una ciudad recién conquistada se obtiene en el siguiente turno del jugador.
7. Se ofrece **un guardado específico del prototipo** (`CapturableProductionV18.encode/decode`): serializa por separado el estado oficial mediante `SaveCodec` y, además, los propietarios y ciclos de producción de las instalaciones paralelas, el progreso de las capturas y las estadísticas de conquista. Al cargar, regenera la geometría determinista del mapa y restaura los cambios de propiedad. El formato comercial de guardado v1 queda intacto.

### Alcance de las pruebas

`tests/test_capturable_production_v18.gd`: genera mapas 24×18 y 40×30 con los cuatro terrenos actuales, captura al menos una base neutral por cada tipo disponible, espera dos turnos propios, devuelve control al capturador, desocupa la instalación cuando es terrestre, compra una unidad compatible con la orden REAL de producción, verifica gasto y que no pueda producirse dos veces en la misma fase. Valida repetidamente que el estado principal sigue admitido por `UrbanEconomy.valid` y el guardado oficial, y que el **guardado extendido del laboratorio** recupera las bases y turnos.

`tests/test_fixed_producer_sites_v17.gd` añadió la comprobación de casillas terrestres para captura naval, manteniendo el muelle sobre agua.

**Workflow:** `.github/workflows/capturable-production-v18.yml`.

## Limitaciones que no se deben ocultar

- **NO es todavía la modalidad jugable completa del APK**. La extensión territorial vive en `scripts/experiments`, no está vinculada a la pantalla de partida ni a la IA comercial. Se requerirá migración de `UrbanEconomy`, `SaveCodec`, interfaz, sistema de mapas y protocolos de captura en un cambio controlado y compatible con partidas antiguas.
- **Las pruebas usan despliegues iniciales controlados** con soldados posicionados sobre objetivos, para aislar la captura y el uso de fábricas. Comprueban movimiento real para despejar la fábrica antes de la compra. No equivalen a medir si un soldado puede recorrer todo el tablero bajo fuego.
- **Los puertos son una excepción explícita**: se capturan por una casilla terrestre de acceso, no por ocupación en el agua. El diseño visual del muelle debe representar esa entrada para que el jugador entienda la regla.
- **Las unidades de apoyo siguen pendientes**. Las cuatro clases de campamento tienen control de constructor/coste; el Intendente y el Sanitario aún no existen en el catálogo de unidades y sus campamentos están bloqueados. Los efectos concretos de reabastecimiento/curación/cobertura/visión también necesitan implementación.
- **No hay modo ocho jugadores ni campaña con mapas de 32 lugares** en esta rama; las reglas de combate y economía principal siguen limitadas a dos facciones.
- **CI:** la primera ejecución v1.8 https://github.com/edwinrodri12/Tarvoka/actions/runs/43804850959 **falló** en la igualdad de los contadores de captura del guardado experimental. El estado restaurado era válido, pero `JSON.parse_string` devolvía los enteros de `producer_holds` como números decimales, causando desigualdad de tipos. Se añadió `_restore_holds` para validar y normalizar los contadores, sus bandos y posiciones; el correctivo y una segunda corrección de clave dinámica ya están en la rama. **La ejecución actual** https://github.com/edwinrodri12/Tarvoka/actions/runs/43805458029 está pendiente de resultado; **no declarar SUCCESS de v1.8** hasta confirmar PASS en los dos pasos.

## Próxima prioridad

Una vez que pasen las pruebas: ensayar mayor densidad de instalaciones productoras en los ocho escenarios y agregar un modo de demostración en el visor de partida que permita seleccionar una ciudad/base, inspeccionar **neutral/propietario/turnos restantes**, mover infantería a conquistar y pulsar «Producir» si la instalación es propia. La construcción ofrecida en el HUD debe limitarse a los campamentos con el especialista correspondiente. La migración de guardados se planifica separadamente y sin romper el juego vigente.
