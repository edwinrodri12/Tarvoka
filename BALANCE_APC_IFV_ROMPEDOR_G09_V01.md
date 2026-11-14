# TARVOKA — Comparativa de blindados G07/G08, Rompedor y G09 (V0.1)

**Fecha:** 14 de noviembre de 2026 · **PR #333**, apilada sobre la PR #328 (Rompedor +2 ATQ contra G09) y separada de las PR #320/#323 del Ingeniero. **Sin cambio de precios, HP, ATQ, defensa, alcance o coste de munición.** Estado de PR: borrador hasta CI completa y prueba humana.

## 1. Qué se midió realmente

- **576 intercambios reales** del mismo motor de batalla que utiliza el juego, en cuatro roles atacantes × cuatro defensores × seis situaciones de terreno (llano, carretera, bosque, montaña defendida, ciudad y ataque desde altura) × tres climas (despejado, lluvia, nieve) × ambos bandos. Son **288 situaciones reflejadas** comparadas para asegurar que los colores/facciones no cambien el daño.
- En cada intercambio se comprueba previsión de daño frente a `Session.attack`, contrafuego, HP, gasto exacto de munición, persistencia del guardado y que el estado original no se altere.
- Movilidad y tracción real calculadas por `Rules.reachable` sobre un mapa 10×8 con carretera, bosque y montaña; los datos son **casillas legales accesibles en ese mapa**, no “velocidad máxima” universal.
- Economía: precios, coste por HP, cinco datos de roles y verificación de que ninguna de las cuatro unidades puede capturar ciudades. Los perfiles de los **32 roles** permanecen íntegros.

## 2. Fichas actuales

| Unidad | Precio | HP | ATQ | DEF | Movimiento | Visión | Munición |
|---|---:|---:|---:|---:|---:|---:|---:|
| APC G07 | 300 cr | 11 | 2 | 1 | 5 | 3 | 3 |
| IFV G08 | 500 cr | 11 | 5 | 1 | 4 | 4 | 6 |
| Rompedor | 300 cr | 8 | 4 (+2 vs G09, +4 vs Baluarte) | 0 | 3 | 3 | 4 |
| G09 | 750 cr | 14 | 8 | 2 | 4 | 3 | 5 |

El **precio por HP** es 27,27 cr (APC), 45,45 (IFV), 37,50 (Rompedor) y 53,57 (G09). Este indicador **no** representa el valor total de una unidad, porque omite ataque, movilidad, alcance, oportunidades de captura y acciones enemigas.

### Intercambio de un solo ataque en llano (HP causados; no tasa de victoria)

| Ataca → Defiende | APC | IFV | Rompedor | G09 |
|---|---:|---:|---:|---:|
| APC | 1 | 1 | 2 | 1 |
| IFV | 4 | 4 | 5 | 3 |
| Rompedor | 3 | 3 | 4 | 4 |
| G09 | 7 | 7 | 8 | 6 |

Los contrataques son reducidos y calculados con HP **después** de recibir el impacto; un G09 que inicia en campo abierto destruye al Rompedor de 8 HP y este no puede responder. El Rompedor solo gana +2 contra G09, no contra APC/IFV; +4 contra Baluarte permanece separado.

### Casillas alcanzables del mapa de movilidad de prueba

| Unidad | Despejado | Lluvia | Nieve |
|---|---:|---:|---:|
| APC | 51 | 25 | **12** |
| IFV | 35 | 33 | 32 |
| Rompedor | 18 | 18 | 17 |
| G09 | 35 | 33 | 32 |

**Lectura:** el APC tiene gran valor de aproximación y protección económica en clima claro, pero su tracción con ruedas se degrada en nieve. El IFV conserva casi toda su movilidad climática, dispone de visión 4 y seis disparos, y su ATQ 5 permite hostigar infantería/mechanizados sin pagar 750 cr por G09. El G09 sigue siendo superior en duelo blindado directo. El Rompedor es una contramedida económica con pocos HP, sin combustible y alcance mínimo; no reemplaza al tanque.

**Límite funcional clave:** hoy el APC **no transporta soldados**, ni el IFV puede cargar/descargar infantería, pese al nombre de esas clases. No hay acción de embarque, campo de carga en el guardado, capacidad de carga ni IA de transporte. Las pruebas NO asignan ningún valor ficticio a estas mecánicas pendientes.

## 3. Mejora de compra IA integrada

El problema anterior estaba en `BasicAI._produce_modern_reinforcements`: la planta de blindados priorizaba comprar **Rompedor primero incluso sin unidades blindadas enemigas**. Se reemplazó el orden fijo por `GroundArmorProcurement.ranking`, un planificador puro que **solo ve las unidades presentes en el estado observado por la IA**:

- **G09 o Baluarte enemigo visible:** primer Rompedor si aún faltan contramedidas; después G09/IFV según nuestra composición. Evita depender indefinidamente de Rompedores baratos.
- **IFV/APC rivales:** G09 de combate principal si no tenemos uno; IFV de apoyo como alternativa.
- **Infantería enemiga visible:** IFV (ATAQUE 5, 6 disparos y visión 4); después pantalla APC si aún falta.
- **Artillería enemiga visible:** APC rápido para acercarse; después IFV para eliminarla con más daño.
- **Sin enemigo terrestre visible (por niebla o distancia):** APC para exploración/escudo de camino, IFV tras contar con APC.
- El orden es una **preferencia**, no autorización de gasto. La compra real sigue utilizando `SupplyStrategy.can_spend_on_recruitment`, `Economy.can_purchase` y `Session.purchase`; límites por turno, créditos, producción, posiciones y registro no cambian. Si el IFV de 500 cr no alcanza el presupuesto, cae al APC de 300 cr; si faltan 300 cr, no produce.
- El planificador no consulta rivales ocultos, su saldo, ni munición/fuel privados. Tiene comportamiento determinista e igual bajo el espejo de bandos.

## 4. Pruebas observadas en Godot

[CI y matriz A/B con pruebas de compras](https://github.com/edwinrodri12/Tarvoka/actions/runs/43646718886) · [datos JSON y logs](https://github.com/edwinrodri12/Tarvoka/actions/runs/43646718886/artifacts/14134277801).

- **576 combates, 288 pares espejo y movilidad climática**: aprobado.
- **28 órdenes reales de compra verificadas** en ambos lados: G09/Baluarte → Rompedor; IFV/APC adversarios → G09/IFV; infantería → IFV; artillería y ausencia de contactos → APC; presupuestos 299/330/350/2500; sin ventaja por dinero, combustible ni rol enemigo ocultos; guardados v1, autorizaciones y simetría: aprobado.
- **16 partidas orgánicas IA vs IA**, 14 fases como máximo, mapas normal y costero, niebla sí/no, objetivo relay sí/no y posiciones iniciales invertidas: **1408 acciones y 277 compras** totales, de las cuales **Rompedor 28, IFV 21, G09 10 y APC 9**. Entre esas compras se registraron 28 Rompedores con blindaje pesado *visible*, 20 IFV con infantería visible y 2 APC con artillería visible. No son decisiones preprogramadas del test: la IA las ejecutó durante sus partidas.
- Resultados de esa muestra: **4 victorias para quien inició, 4 para quien respondió y 8 partidas sin resolver**. Esto descarta divergencia evidente en el pequeño test espejo; **NO** demuestra balance competitivo 50/50.
- Suite adicional de 304 decisiones espejadas, comparación económica de 16 partidas, bonificación Rompedor/G09 de PR #328, APK debug y suite completa Godot: verificar los checks del commit final de esta PR antes de fusionar.

## 5. Decisiones y siguientes pasos

**Aprobado provisionalmente para la rama:** mejorar la compra contextual de la IA sin alterar daño/vida/precio de las cuatro clases. **No aprobado:** rebalancear arbitrariamente HP, munición o precio basándose en duelos simples; limitar APC por un coste ficticio de transporte.

La siguiente mejora con mayor retorno sería implementar **transporte terrestre real y balanceado del APC** (y decidir la capacidad del IFV), con embarque/desembarque, ocupación de casillas, visibilidad/fog, captura sin teletransporte, combustible, destrucción del vehículo, IA y guardados. Es una mecánica nueva y **NO está implementada por esta PR**. Deberá probarse por separado en Android e integrarse con el visor 3D sin confundir aspecto con jugabilidad.

También faltan pruebas humanas, composición de escuadras con objetivos simultáneos y medición de sesgos estratégicos más allá de 16 partidas cortas. No hay multijugador de 8 bandos tácticos implementado aquí.
