# TARVOKA — IA v3.5: movimiento para preparar ataques combinados

**17 noviembre 2026 · Implementación experimental, sin cambiar main ni el APK.**
**Base:** IA v3.4 de fuego coordinado, con **10/10 trabajos CI satisfactorios** ([run 44157032479](https://github.com/edwinrodri12/Tarvoka/actions/runs/44157032479)); también depende de v3.3 (9/9 CI PASS) y v3.2 (8/8 CI PASS). La v3.5 aprobó **11/11 trabajos** en el corte anterior ([run 44161401834](https://github.com/edwinrodri12/Tarvoka/actions/runs/44161401834)); se añadió prueba nueva de altura y debe verificarse una vez más.

## Problema que soluciona

**Hallazgo de la primera CI v3.5:** escenario a 10×8: el nivel 9 desplazó el Guardia a **(5,3)**, después ejecutó **dos disparos reales** hasta eliminar al enemigo sin alterar créditos. Con bosque en (5,3), el tiro desde el flanco infligió **6 daños** y fue el destino elegido. Prueba de captura, artillería, niebla y 24×18/40×30 también aprobada; el planificador analizó **5 posiciones** en ambos mapas ampliados bajo el escenario controlado. Estas son verificaciones de escenarios, no conclusiones sobre tasa global de victoria. Además se agregó una prueba de **SPG subiendo a montaña para completar un remate combinado sobre un tanque de 9 HP** (CI más reciente pendiente).

Antes de v3.5, la IA `BasicAI` podía atacar sola, buscar una casilla que permitiera un remate individual, hacer ataques combinados si dos o tres tiradores **ya** estaban a alcance y mantener misiones de captura/escolta. Sin embargo, no era capaz de **recolocar un soldado para habilitar un ataque combinado** antes de gastar sus ataques en daños dispersos.

La nueva etapa conecta `CoordinatedPositioningV35.gd` con `BasicAI.step`, a partir del **nivel 9**. Mantiene la regla actual de que un desplazamiento y un ataque pueden ejecutarse en el mismo turno, pero **cada desplazamiento y cada disparo utiliza su acción legal individual**. Nunca aplica daño durante la simulación de una ruta.

## Capacidades concretas

- **Nivel 1–8:** sin planificador adicional. Sigue la IA preexistente de objetivo persistente/combate y en 7–8 fuego combinado si ya estaba a alcance.
- **Nivel 9:** desplazar una unidad, cuando otra puede participar en un remate conjunto de **dos** disparos.
- **Nivel 10–12:** además pueden habilitarse secuencias de **hasta tres** disparos.
- Se examina un máximo de **cuatro unidades móviles, cuatro enemigos visibles y cuatro destinos favoritos** por unidad y enemigo; se reduce el número de tiradores/blancos en la evaluación de v3.4. Evita replanteamientos exhaustivos de cientos de casillas 40×30.
- La unidad elegida debe estar operativa, sin haberse movido, con munición (o sin sistema de munición en un estado de juego antiguo), alcanzar realmente el punto por **costes ponderados** (bosques/montañas/carreteras, clima y combustible), y poder **disparar desde la nueva posición**.
- Antes de mover, se utiliza un clon del **estado observado**, y una vista previa pública de daño/contraataque, flanqueo, altura, cobertura y posibilidad de victoria con otros tiradores. Si la secuencia conjunta no podría derrotar al enemigo, la IA no activa esa maniobra. **No hay movimiento agresivo al azar presentado como táctica combinada.**
- Las **posiciones de bosque/montaña** mejoran la puntuación si proporcionan protección o altura. El flanqueo real del motor también se contabiliza; no se añaden bonuses invisibles.
- Evita mover soldados **ocupando una ciudad/base neutral o enemiga** que pueden capturar al terminar el turno. Mantiene en posición a defensores ya asignados y cercanos a su instalación.
- La **artillería de alcance mínimo superior a una casilla** evita colocarse adyacente a enemigos visibles que le impidan disparar; todo tirador rechaza ubicaciones desde las que un enemigo visible distinto del objetivo pueda derrotarlo de inmediato.
- La **niebla** se respeta de principio a fin: ningún enemigo oculto se introduce en la planificación, los destinos deben estar visibles y ninguna posible ubicación se prueba contra el `BattleSession` autoritativo antes de elegirla. Se realiza **un único intento de movimiento** para el candidato final, sin tanteos encubiertos que revelen ocupación desconocida.
- Tras el movimiento, la próxima llamada a `BasicAI.step` calcula otra vez el combate real. La IA puede abandonar un plan si cambió la información, en lugar de ejecutar disparos comprometidos irreflexivamente.

### Ejemplo de combate implementado y preparado para validar

Un Guardia propio está en (3,3), otro en (6,3), y el objetivo enemigo se encuentra en (4,3). El primer Guardia tiene un disparo legal, pero no puede matarlo solo. El segundo se mueve hacia el frente, de preferencia a una casilla protegida como (5,3) si allí hay bosque; la posición permite un **flanqueo cruzado**, y a continuación la IA puede ejecutar dos disparos legales que eliminan al enemigo. Si fuera un terreno desconocido, un enemigo invisible o un movimiento que deja la ciudad desprotegida, se rechaza el plan.

*Este ejemplo es una prueba automática de comportamiento de la v3.5, no una afirmación de que el nuevo banco CI ya aprobó.*

## Archivos modificados

- `scripts/core/CoordinatedPositioningV35.gd` — planificador de posiciones, riesgo y fuego combinado.
- `scripts/core/CoordinatedFireV34.gd` — parámetro opcional `only_target_id` para comprobar una amenaza concreta sin cambiar llamadas previas.
- `scripts/core/BasicAI.gd` — integración por nivel 9–12 **después de remates inmediatos y retirada urgente**, antes de ataques individuales no letales.
- `tests/test_ai_tactical_position_v35.gd` — prueba de órdenes auténticas, fuego cruzado, cobertura, protección de capturas/artillería, información oculta y coste acotado en 24×18 y 40×30.
- `.github/workflows/ai-tactical-position-v35.yml` — nueva prueba junto a **10 regresiones heredadas**.

## Riesgos y criterios antes de aprobar

- **Táctica vs riesgo:** una previsión de dos impactos puede fallar por respuesta/cambio de estado; hay que aceptar que la IA reevalúe antes del segundo disparo. El motor de combate sigue siendo autoritativo.
- **No empeorar el resto de prioridades:** remate de un solo disparo, defensa urgente, retirada por muerte probable, captura y abastecimiento necesitan conservarse.
- **Rendimiento Android:** el límite de candidatos evita búsquedas exponenciales, pero habrá que medir latencia real en un Android medio con varios enemigos visibles, especialmente 40×30.
- **Balance competitivo:** comprobar tasas de victorias/derrotas/censuras en mapas certificados, contra doctrinas diversas, intercambiando lados; no usar un único mapa determinista para declarar una mejora.
- **Reglas y continuidad:** no modificar `SaveCodec`, `ai_config`, créditos, estadísticas, evolución, cooldown ni poderes de comandante. El usuario continuará seleccionando los doce niveles desde el menú v3.2.
- **Dependencia:** validar v3.4 y v3.5 individualmente. Mantener ambos PR en borrador hasta tener CI completo.

## Próxima prioridad

Tras CI y ajustes, medir **sincronización entre movimientos y fuego de artillería**, protección del capturador ante ataques enemigos del próximo turno, y defensa conjunta en posiciones de altura. Después tocar **evoluciones y poderes de comandante cuando `BattleSession` ofrezca compras/mejoras autoritativas**, y calibrar la diferencia real entre niveles 9/10/11/12 por pruebas humanas y bots variados.

**Enlaces:** [PR v3.4](https://github.com/edwinrodri12/Tarvoka/pull/540) · [PR v3.3](https://github.com/edwinrodri12/Tarvoka/pull/538) · [Directrices de IA #528](https://github.com/edwinrodri12/Tarvoka/issues/528)
