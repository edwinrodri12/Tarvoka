# TARVOKA — Auditoría numérica integral v0.1
Fecha: 14 de noviembre de 2026. Estado: auditoría reproducible, NO balance comercial aprobado. Esta rama no cambia cifras, IA, compras, partidas ni guardados.

## Principio rector
Cada número debe tener efecto comprensible, crear una elección con coste de oportunidad, y disponer de al menos una respuesta viable. Ni un test que compila ni una IA empatada consigo misma prueban que el juego resulte divertido. Se requieren enfrentamientos cruzados, partidas completas y pruebas humanas.

## Valores que existen hoy

| Campo | Regla que realmente usa el motor |
|---|---|
| Ataque | Daño base = max(1, ataque - defensa - cobertura) para ataque positivo. Ataque sin fuerza = 0. No hay RNG. |
| Defensa posicional | Bosque +1, montaña +2, ciudad +1, altura desde arriba +1 ataque y desde abajo -1, flanqueo opuesto +1. |
| Contrafuego | Entre 0 y 65% de potencia por doctrina, reducido por HP restante; requiere visión, rango, dominio, munición y supervivencia. |
| Movimiento | Llanura 1, bosque 2, montaña 3, carretera 1; vehículos a motor pagan 0,5 en carretera; lluvia y nieve penalizan chasis concretos. |
| Clásico | 300 créditos iniciales y 100 por ciudad propia al comenzar el siguiente turno del bando. |
| Moderno | 2.500 créditos iniciales y 250 por ciudad propia al comenzar el siguiente turno propio. |
| Suministros | Precio de munición 12, combustible 4, mínimo de servicio 20; consumo aéreo/naval por turnos, terrestre por movimiento. |
| Capacidad real | Máximo 256 unidades comprables, 16 sitios económicos, solo 2 bandos tácticos, mapas hasta 40×30. |
| Campaña | T1–T4 es acto de primera introducción, NO fuerza adicional. Tres niveles tecnológicos de 24 familias siguen como diseño. |
| Veteranía | Umbrales propuestos 0, 15, 40, 80 XP. Ni XP ni modificadores estadísticos activos. |

La prueba tests/test_numeric_balance_audit.gd exporta el catálogo de **32 roles** en JSON con HP, ataque, defensa, visión, movimiento, alcance, dominios objetivo, captura, coste, precio en turnos de ingreso, munición, combustible, reacción, productor y tier introductorio. También ejercita la ruta real de vista previa del combate para todos los cruces legales y valida la contabilidad de ingresos simétrica. No recalcula números en un simulador distinto al juego.

## Incoherencias confirmadas

### 1. Rompedor anti-blindaje contra tanque
El Rompedor tiene 8 HP, ataque 4, movimiento 3 y precio 300. Obtiene +4 ataque contra Baluarte, pero no contra G09 Tanque, a pesar de que su descripción promete ser antiblindaje y la ficha del tanque dice que lo contrarresta. Resultado en llanura: contra Baluarte (12 HP, DEF 2), daño **6** y requiere 2 golpes sin reacción ni cobertura. Contra tanque (14 HP, DEF 2), daño **2** y requiere **7** golpes. Esta es una incoherencia objetiva. Probar bonificaciones específicas +1 y +2 frente a tanque, NO copiar +4 sin análisis.

### 2. Ingeniero y Asaltante con igual precio, pero utilidad distinta
Ambos cuestan **250**. Asaltante: 9 HP, ataque 5, movimiento 3. Ingeniero: 7 HP, ataque 2, movimiento 2. Ambos capturan. La reparación, puentes y otras acciones de infraestructura del Ingeniero aún no están implementadas. Actualmente es una opción peor en combate y movilidad sin compensación funcional. Antes de cambiar el precio, implementar una acción de reparación limitada con coste, tiempo, rango y tope, o deshabilitar su compra competitiva hasta que aporte valor.

### 3. Utilidad pendiente anunciada como especialización
- Guerra electrónica: coste 550, ataque 0, sin interferencia implementada.
- Helicóptero de transporte: coste 500, sin carga de infantería.
- Buque de desembarco: coste 900, sin transporte anfibio.
- APC 300 e IFV 500 aún no transportan; poseen diferentes stats de combate, movilidad y protección.
- Submarino 1.700 aún no tiene sigilo/sonar; Bombardero 1.400 solo ataca a un objetivo.
No se deben anunciar ventajas no implementadas ni permitir que una unidad cuyo valor depende de ellas desequilibre una partida competitiva.

### 4. La salud no reduce el daño ofensivo
Un tanque con 1/14 HP hace **6 HP** de daño a otro tanque en llanura, igual que uno con 14/14 HP. La reacción del defensor sí se escala por su HP restante. A/B: daño base sin escalado contra escalado suave; comparar retirada, reparación, intercambio de bajas, contraataque y remontadas. Ninguna fórmula es correcta solo por realismo.

### 5. Riesgo económico y efecto bola de nieve
Una sola ciudad moderna paga 250 por ciclo propio. Con dos: 500; con tres: 750. Capturar una ciudad neutral puede duplicar de golpe el flujo de quien solo posee una ciudad. Coste equivalente a una ciudad por ciclo: tanque 750 ⇒ 3 ciclos, bombardero 1.400 ⇒ 6, destructor 2.000 ⇒ 8. Con dos ciudades: tanque 2, bombardero 3, destructor 4. Hay **2.500 créditos iniciales**, así que el gasto de apertura y la cadencia de fábricas importan tanto como los ingresos a largo plazo. La apertura de tres órdenes y el marcador por rondas corrigieron sesgos anteriores, pero no acreditan justicia general ni en ocho jugadores.

## Diseño de experimentos, sin cambios de producción en esta PR

| Prioridad | Alternativas a comparar | Datos necesarios |
|---|---|---|
| Ingeniero | Reparar con acción, coste y tope vs precio de compra reducido | Uso real de reparaciones, coste evitado, victorias, duración y estrategias |
| Rompedor vs G09 | Bonus +0/+1/+2 y ajustes de coste si procede | Microduelos con cobertura, altura, flanqueo, munición y contrafuego |
| Escalado por HP | Ataque actual vs escala suave según HP | Bajas, intercambios, remontadas, retirada, daño de una unidad a 1 HP |
| Economía | Ubicación y tempo de capturas, crédito inicial y coste de soporte | Ingresos y gastos por turno, inversiones, recuperación tras perder 1 ciudad |
| 24 familias y tres niveles | Coste de fabricación, tiempo, munición, combustible y habilidades específicas | Comparar niveles I/II/III en mapas y climas, evitar mejora estrictamente superior |
| Multijugador 8 | Ingresos y objetivos por asiento, turnos, alianzas y límites >256 | Balance por posición de inicio, duración, densidad de tropas y anticaptura |

## Indicadores de balance y disfrute

1. **Combate:** tiempos de eliminación por tipo de blanco, contraataques, daño por coste y por munición, escenarios de cobertura y dominio.
2. **Economía:** ingresos por ciclo, unidades elegidas, saldo inmovilizado, recargas, control de edificios, tasa de recuperación y coste de oportunidad.
3. **Decisiones:** frecuencia de compra de cada rol en mapas donde es útil; alternativas viables en igual situación; estrategias dominantes.
4. **Progresión:** cada mejora necesita coste, tiempo o restricción; nada de +daño/+defensa ilimitados ni transformar un chasis gratuitamente.
5. **Justicia:** comparar arranques intercambiados, mapas, clima, composición, IA distinta, facción y, luego, posiciones de 8 jugadores.
6. **Diversión humana:** claridad del resultado previsto, decisiones memorables, sensación de remontada, duración de turno y repetición de partidas.

Todos los cambios deben comparar antes/después, conservar reglas y guardados existentes y tener pruebas Godot más partidas de IA **y** humanos. Un 50/50 estadístico de la misma IA consigo misma no demuestra diversión.

## Reproducción y entregables
- Ejecutar Godot 4.3: godot --headless --path . --script res://tests/test_numeric_balance_audit.gd
- CI: .github/workflows/numeric-balance-audit.yml
- Artefactos: tar voka numeric balance JSON con **32 fichas**, comparaciones, límites, riesgos reconocidos y log completo.
- Las advertencias de unidades aún incompletas NO son aprobaciones ni errores silenciados: son pendientes priorizados.
- Esta PR se limita a auditoría y documentación. Cualquier reequilibrado auténtico debe seguir como experimento separado con evidencia.
