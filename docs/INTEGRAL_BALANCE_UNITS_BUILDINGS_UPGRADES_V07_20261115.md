# TARVOKA — Balance integral v0.9: 32 unidades + edificios + tecnologías + poderes

**15 de noviembre de 2026 | Investigación, NO modificación de estadísticas oficiales | PR #394**

## Decisión de producto

Hasta ahora se probaron rutas seguras, economía, iniciativa y capturas. Eso no permite validar un juego completo si las clases superiores, las tecnologías de edificio, la veteranía y las ventajas de comandantes alterarán mucho el daño y la supervivencia. Este documento establece un **marco único de evaluación** antes de aumentar estadísticas, precios o potencias en el juego comercial.

### Separación entre decidido, implementado y futuro

| Sistema | Fuente / acuerdo previo | Estado del motor hoy |
|---|---|---|
| Roles militares | 5 clases clásicas + 27 del catálogo moderno, 32 en total | Perfiles base funcionales; armamento/transportes especiales no siempre completos |
| Combate | Ataque, defensa, vida, alcance, dominio, cobertura, elevación, flanqueo, munición y contraataque | Reglas deterministas en Combat/BattleActions/TerrainTactics |
| Base de infantería/cuártel nivel I–III | Las unidades especiales se desbloquean con niveles 1–3; no edificio de entrenamiento separado | Niveles de producción **no aplicados** en UrbanEconomy |
| Edificios de tierra, aire, mar y drones | Mejoras se compran en el edificio militar correspondiente y potencian unidades compatibles globalmente | Catálogo con fábricas y categorías; **no hay todavía compra y persistencia de mejoras** en core |
| Centro de Investigación y puntos de investigación | Eliminados del diseño, créditos como moneda prevista | No implementarlos |
| Cuartel General I–III | Tres estados de nivel, operativo/capturado/dañado/destruido | Avances visuales separados; **no se observa** HQ como instalación funcional de UrbanEconomy |
| Veteranía | Recluta (0 XP), Regular (15), Veterano (40), Élite (80) | CombatDoctrine.VETERANCY define nombres/umbrales, pero **bonificaciones de ataque y defensa = 0** |
| Comandantes y facciones | 8 facciones, balance de ventajas y poderes 0.1 aceptado hasta pruebas | No se han localizado efectos activos de comandantes en scripts/core; catálogo/aprobación anteriores no equivalen a efectos en combate |
| Central energética | Mantener como concepto experimental, todavía no definitiva | No introducir beneficio económico ni energético sin pruebas |

**Importante:** CombatDoctrine.tier=1–4 representa el **acto de introducción en campaña**, NO «nivel de la unidad» o multiplicador de estadísticas. No confundir con nivel I–III del edificio.

## Mecánica de daño actual (constatación)

`Combat.damage(ATQ, DEF, COBERTURA) = max(1, ATQ − max(0, DEF) − max(0, COBERTURA))`, si ATQ > 0. `UnitRoles.role_bonus` puede elevar ataque contra determinadas clases. TerrainTactics agrega +1 cobertura bosque, +2 montaña, +1 cobertura en ciudad; elevación ±1 ataque, flanqueo +1 terrestre cuando aplican. Un disparo terrestre en ciudad boscoso puede sumar coberturas. No todas las aeronaves y naves reciben coberturas terrestres.

El **ataque directo no disminuye al bajar HP**; si una unidad tiene 1 HP todavía puede causar todo su daño base. En cambio, el contraataque está condicionado a sobrevivir, poder responder por alcance/munición y escala su potencia según los HP restantes y porcentaje de reacción específico de cada rol (0–65 % actualmente). Hay una sola reacción por turno rival.

Estos dos comportamientos deben probarse juntos, pues la decisión de reducir daño por heridas podría cambiar enfrentamientos y precios por completo. Una mejora de +1 defensa puede anular por completo incrementos de daño de clases débiles (sujetas al suelo de 1 daño), y +1 ataque puede adelantar el turno exacto de destrucción.

### Riesgos conocidos por código

- **Rompedor vs tanque:** Unidad Rompedor con ATQ 4 y coste 300 solo posee bono explícito +4 al atacar Baluarte. Contra el tanque moderno (14 HP, DEF 2, coste 750) hace **2 daño por impacto en terreno abierto**, mientras que un tanque con ATQ 8 derrota un Rompedor de 8 HP sin cobertura en un impacto. Es una señal a investigar: su nombre y propósito antiblindaje no coinciden con ese enfrentamiento, pero cambiar daños sin ponderar logística, alcance y producción sería precipitado.
- **Ingeniero vs Asaltante:** ambos cuestan 250 créditos; Ingeniero tiene 7 HP, ATQ 2, movimiento 2, mientras que Asaltante posee 9 HP, ATQ 5, movimiento 3. La reparación del Ingeniero figura pendiente: su función diferencial resulta incompleta en el motor.
- **Tecnologías/veteranía:** no podemos inferir costes y buffs aprobados; los ejemplos anteriores de +15 % defensa, +10 % antiblindaje o +1 movilidad fueron **ilustrativos, no definitivos**.

## Fases de la auditoría integrada

**A. Estadísticas base y enfrentamientos.** Medir las 32 clases, **1.024 pares dirigidos (32×32)**, legalidad de ataque por dominio y rango, HP, daño/HP por crédito, iniciativa y daño en retaliación. Contextualizar con bosques, montañas y ciudades y con 1 HP; advertir si el escenario prueba intercambios teóricos sin pathfinding ni IA.

**B. Sensibilidad a mejoras; NO activar nuevas estadísticas.** Probar copias hipotéticas `+1 ATQ`, `+1 DEF` (cambios enteros en el motor actual), puntos de vida extra, reducción de costes, alcance, movilidad, visión y capacidad de suministros **por clase compatible**, nunca acumulados universalmente. Medir cambios de umbral de destrucción, unidades invulnerables por la regla de daño mínimo, coste por impacto, equipamiento y contramedidas.

**C. Progresión militar por edificio.** Probar acceso a clases desde cuartel infantería, planta blindados, depósito de artillería, centro de drones, base aérea y base naval, con niveles I–III para los militares compatibles. Coste de subir edificio (en créditos), turnos de inversión y tiempo de recuperación deben evaluarse juntos con producción e ingresos de ciudad. Es necesario que un jugador sin una base avanzada todavía posea contrajuego frente a unidades superiores.

**D. Cuartel General y edificios dañados.** Evaluar nivel I–III y transiciones operativo/capturado/dañado/destruido: vida estructural, daño contra edificios y tipos de proyectil, reparación/coste, consecuencias de captura, y mecanismos que impiden victoria instantánea por construir y mejorar una sola estructura. **Hoy no existen HP de edificios en UrbanEconomy; no inventar cifras.** El diseño visual de niveles de daño no es ya una mecánica implementada.

**E. Veteranía + mejoras globales + poderes.** Revisar por separado la veterania por acciones vs compra tecnológica global. Prohibir multiplicadores de daño/defensa sin limitación que se acumulen junto a ventajas fijas de las ocho facciones y sus poderes. Preservar los poderes del balance 0.1 hasta disponer de números ejecutables/ensayos.

**F. Partidas completas.** Comparar distribución de victorias y duración con mapas 10×8, 24×18 y 40×30; 1 vs 1 ahora y hasta 8 bandos cuando el motor lo soporte, niebla, clima, iniciativa y economía. Registrar sistemas implementados antes de afirmar que una progresión es equilibrada.

## Criterios de aceptación propuestos, sujetos a validación

- Cada clase debe tener una utilidad concreta que justifique costo/tecnología/posición; habilidades que solo existen en la descripción deben señalarse explícitamente, no considerarse compensación de estadísticas.
- Los beneficios de nivel II y III han de competir con reclutar nuevas unidades por los mismos créditos, para crear decisiones estratégicas. El nivel III no debería ser automáticamente obligatorio o una victoria garantizada.
- Debe existir respuesta táctica a tecnología superior mediante unidades disponibles, terreno, alianzas, visión, desgaste, reabastecimiento y costos.
- Las simulaciones deben medir tanto destrucción rápida como bloqueos de 1 daño, y mantener los bonos de cada facción/poder separados de los nuevos niveles mientras se auditan.
- No cambiar estadísticas comerciales ni desbloqueos antes de resultados de pruebas reproducibles y confirmación del diseño.

## Código de auditoría (aislado)

- `tests/test_full_combat_balance_v07.gd`: compara perfiles base y 1.024 enfrentamientos dirigidos y simula por copia los efectos de +1 ATQ/+1 DEF y terreno, sin guardar/modificar atributos reales.
- Workflow: ` .github/workflows/full-combat-balance-v07.yml` en la rama experimental.
- **Godot 4.3 SUCCESS, ejecutado:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43778731623. Las 32 fichas se validaron, incluyendo 5 perfiles clásicos y 27 modernos. De los 1.024 pares dirigidos examinados, **432 permiten un ataque** por rango/dominio/munición en este escenario de posiciones; **116** eliminan al objetivo en un primer golpe y **127** generan un contraataque. El ataque con 1 HP conserva exactamente el daño del ataque con vida completa en **432/432** casos con ataque válido. La simulación hipotética de **+1 ATQ cambia daño en 310/432**, y **+1 DEF cambia daño recibido en 332/432**. Los demás pares no significan necesariamente que esas unidades carezcan de utilidad: pueden ser de dominios incompatibles o de apoyo. Los cinco roles sin ataque convencional actual son ew, logistics, uav_recon, transport_heli y landing_ship. **Estas son pruebas estáticas por pareja, no 432 duelos completos con movimientos, IA y producción.** Los 1.024 pares no son 1.024 combates legales; la distinción es esencial.


## Esquema de evolución propuesto para probar (no aprobado)

Se mantiene el acuerdo de tres niveles para instalaciones militares y mejoras globales comprables con créditos en el edificio correspondiente. Las asignaciones exactas de desbloqueos y precios siguen abiertas: no elevar las cifras del modelo actual hasta simular su interacción.

| Instalación | Nivel I: función base | Nivel II: progreso a investigar | Nivel III: progreso a investigar |
|---|---|---|---|
| Cuartel de Infantería | Guardia y Rastreador | Asaltante, Ingeniero con reparación funcional | Unidades de élite/comando y especializaciones, aún sin perfil canónico |
| Planta de blindados | Transporte blindado, IFV | Tanque principal y contramedidas antiblindaje | Tecnología avanzada de blindaje y movilidad, sin crear tanques invulnerables |
| Depósito de artillería | Artillería, antiaéreo móvil | SPG, cohetes y SAM según reglas de alcance | Electrónica/interferencia *solo tras implementar el efecto real* |
| Centro de drones | Reconocimiento | FPV y consumibles con contramedidas | Tecnologías de detección/ataque compatibles según rol; UCAV se fabrica hoy en base aérea |
| Base aérea | Helicóptero de ataque, transporte cuando exista carga | Dron de combate, caza | Bombardero y mejor logística aérea |
| Base naval | Patrullas y lanchas | Escoltas/corbetas y desembarco cuando exista carga | Fragatas, destructores y submarinos con contrajuego |
| Cuartel General | Mando funcional y condición de objetivo | Resistencia y opciones de mando por definir | Efectos de nivel III por definir, diferenciando daño leve/medio/crítico/destruido |

**Importante:** la tabla es una hipótesis para ensayos, no un desbloqueo aprobado. La Central Energética continúa experimental. Los niveles actúan sobre acceso/capacidades, mientras que las tecnologías que se compran en instalaciones aplican globalmente **solo a unidades compatibles** de la facción. Los comandos y los poderes de las ocho facciones no pueden tener bonificaciones numéricas acumulativas asumidas sin pruebas.

## Siguiente decisión

El trabajo inmediato deberá centrarse en cerrar **la identidad funcional del Ingeniero, Rompedor y unidades sin función implementada** antes de asignar costos de evolución. Después, modelar un plan de tecnologías por edificio y medir qué gana el jugador comprando un nivel adicional frente a tres unidades básicas. El balance de ocho facciones permanece congelado durante esta investigación.
