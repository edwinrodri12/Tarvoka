# TARVOKA — Embarque animado y transportes APC/IFV V0.2

**Rama:** `feat/cargo-vfx-ifv-single-seat-20261114` · [PR #339](https://github.com/edwinrodri12/Tarvoka/pull/339), borrador sobre [PR #335](https://github.com/edwinrodri12/Tarvoka/pull/335), que depende de #333 y #328. No hay cambios directos a `main` ni a las 8 facciones.

## 1. La diferencia comercial entre G07 y G08

| Mecánica actual | APC G07 | IFV G08 |
|---|---|---|
| Precio | 300 créditos | 500 créditos |
| HP y defensa | 11 / 1 | 11 / 1 |
| Ataque | 2 | 5 |
| Visión | 3 | 4 |
| Movimiento | 5, con mayor penalización al rodado en nieve | 4, con orugas menos afectadas |
| Pasajeros máximos | **2** | **1** |
| Guardia, Rastreador, Asaltante, Ingeniero | Sí | Sí |
| Rompedor (especialista antiblindaje) | **Sí** | **No** |
| Ataque después del desembarque en el mismo turno | No | No |
| Disparar con el pasajero ya embarcado en turnos posteriores | Sí, poca potencia | **Sí, mayor potencia** |
| Pérdida de tropas al destruirse el vehículo | Sí | Sí |

**Decisión:** el APC sigue siendo transporte prioritario para movimientos y equipos antiblindaje, con mayor carga y menor coste. El IFV añade un asiento auxiliar para infantería de captura, sin superar el volumen ni la movilidad despejada del APC. Su valor extra procede del cañón, visión y menor dependencia climática; no se cambian ATQ, HP, DEF, munición, combustible ni coste. **Balance provisional** hasta partidas humanas.

## 2. Embarque/desembarque auténticos dentro del tablero

La acción ya proviene de `BattleSession.embark/disembark` con validación por `CargoActions`, por lo que la animación **no concede movimiento, acciones o tropas adicionales**. `CargoVFX.gd` se alimenta de estados reales antes/después, no de vistas previas, y representa una secuencia breve (0,72 segundos):

- Apertura de escotilla/puertas; el IFV presenta una escotilla más compacta que el APC
- Soldado estilizado desplazándose de la casilla de origen a la ubicación del vehículo o viceversa
- Cierre automático de puertas, círculo de polvo y vibración breve; batería reducida elimina partículas secundarias
- Vista **clásica** y vista **isométrica** con los mismos tiempos, coordenadas y seguridad; las confirmaciones indican `CONF. EMB` o `CONF. SAL`, no movimiento genérico
- La UI Android horizontal utiliza botones explícitos `Embarcar`/`Desembarcar`; ambas clases muestran un indicador privado `1/1` o `1/2`/`2/2`
- Eventos limitados a seis y eliminados automáticamente; no se serializan, no producen colisiones ni ralentizan el motor mientras no hay carga visible
- **Privacidad:** no se crean efectos visuales que permitan identificar pasajeros de APC/IFV enemigos. No aparece un soldado fantasma después de salvar/cargar

**Aclaración de arte:** la vista isométrica sigue siendo representación 2D de batalla con efectos procedurales; **esta PR no incorpora rigs, animación esquelética ni apertura real de una puerta en un modelo 3D exportable** del Estudio TARVOKA.

## 3. Reglas y guardados

`CargoActions.capacity(role)` es la única autoridad para 0 (no transporta), 1 (IFV) y 2 (APC), y `allowed_passenger` impide Rompedor dentro del IFV. `SaveCodec` valida límite de asientos, tipo, bando, identidad y atributos sin alterar el esquema JSON v1; los soldados cuentan para el máximo global de 256 incluso embarcados. Los dos blindados consumen toda su acción al subir o bajar una unidad; pueden desplazarse antes del desembarque si aún conservan la acción; la infantería no puede capturar o atacar desde dentro. Todos los pasajeros desaparecen si el vehículo es destruido.

La IA de `APCTransportAI` ahora acepta ambas categorías de transportes y utiliza exclusivamente posiciones/ciudades conocidas, con prioridades previas de combate y apoyo. El IFV conserva su ventaja de combate y solo recoge un capturador cercano cuando es tácticamente oportuno, sin acceder a la niebla enemiga.

## 4. QA preparada y límites

- `tests/test_ifv_single_seat_transport.gd`: roles permitidos, 1 plaza, APC de 2 plazas intacto, ambos colores, niebla, guardado, ataque IFV con infante a bordo, no desembarcar tras disparar y muerte del vehículo
- `tests/test_transport_animated_vfx.gd`: 4 recorridos auténticos (APC/IFV × clásico/isométrico), confirmación, puertas/figura interpolada, cancelación, límite de eventos, no guardar efectos y privacidad
- `tests/test_ifv_cargo_ai.gd`: recorridos a ciudad con cambio de turnos y bando espejo, captura y conocimiento restringido por niebla
- `.github/workflows/cargo-vfx-ifv.yml`: Godot 4.3 exige que estas pruebas y los tests previos APC, IA, seguridad, Rompedor-G09 y compras contextualizadas terminen en verde
- Además quedan por confirmar la suite general de reglas Godot y el APK debug de GitHub Actions del **SHA final**, así como el uso táctil y los FPS en hardware Android real

**No confundir:** código escrito y pruebas automatizadas creadas **no equivalen** a pruebas aprobadas hasta ver su resultado CI. No se certifica rendimiento físico ni equilibrio competitivo antes de medirlo.
