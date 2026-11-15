# TARVOKA — Fase v0.8: liquidez por facción y partidas extendidas

**15 noviembre 2026 | PR #394 (borrador) | No altera gameplay oficial**

## Decisión

Mantener los costos, el ritmo de ingresos, la IA activa y el sistema de guardado intactos hasta distinguir de manera reproducible escasez económica, bloqueo de instalaciones y partidas terminadas prematuramente. El experimento usa captura urbana de 4 puntos, instalación de 3 puntos y retención de renta a partir de 2 puntos; no representa reglas jugables aprobadas.

## Hallazgo de código: densidad económica fija

UrbanEconomy.create dispone cuatro ciudades generadoras de créditos: una inicial para cada facción y dos neutrales disputadas, independientemente de si el mapa es 10×8 (80 casillas), 24×18 (432) o 40×30 (1.200). En modo moderno cada ciudad produce 250 créditos por turno propio y los bandos empiezan con 2.500 créditos cada uno.

| Mapa | Ciudades/100 casillas |
|---|---:|
| 10×8 | 5,00 |
| 24×18 | 0,93 |
| 40×30 | 0,33 |

La fuerte reducción de densidad es una hipótesis de contienda económica lenta, no evidencia suficiente para aumentar ciudades o modificar precios: también importa la distancia y la distribución de ejércitos.

## Auditoría de liquidez (resultado verificado)

**GitHub Actions SUCCESS, Godot 4.3:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43771490546

**Fuente ejecutable:** tests/test_capture_liquidity_by_faction_v06.gd. Reproduce 16 pares de partidas espejo (32 sesiones de hasta 48 medias fases) sobre cuatro escenarios, dos bandos iniciales y niebla sí/no. La comparación de control es IA conservadora experimental v0.5 y el tratamiento son rutas seguras v0.6. El propio test ratifica 1.031 compras de control frente a 910 en la variante, sin tocar scripts/core.

| Métrica | Control v0.5 | Ruta v0.6 |
|---|---:|---:|
| Compras facción azul/0 | 515 | 457 |
| Compras facción roja/1 | 516 | 453 |
| Fases activas facción 0 | 370 | 335 |
| Fases activas facción 1 | 371 | 335 |
| Fábricas-fase propias observadas | 4.077 | 3.680 |
| Sin fondos para clase más barata de ese productor | 174 | 247 |
| Porcentaje de observaciones de fábrica sin fondos | 4,27 % | 6,71 % |
| Fases con menos de 150 créditos | 17 | 30 |
| Instalaciones clasificadas como ocupadas | 1.054 | 875 |
| Créditos gastados en compras | 319.100 | 273.800 |

El mayor número de instalaciones-fase sin fondos persiste después de normalizar por fábricas observadas, pero la clasificación decide primero si la caja alcanza para la opción más barata, y solo después evalúa ocupación/producción; **no representa demandas explícitas de compras rechazadas al jugador**.

### Concentración geográfica de insuficiencia de fondos

| Mapa 10×8 | Control | Ruta segura |
|---|---:|---:|
| Campo abierto | 41 | 63 |
| Bosque de las Dos Rutas | 10 | 104 |
| Puentes de la Cuenca | 46 | 0 |
| Costa de las Dos Bahías | 77 | 80 |

Los agregados por color son bastante simétricos, pero esto no prueba igualdad competitiva: las posiciones de inicio, la niebla y el control de ciudades producen resultados individuales muy diferentes. En particular, la escasez observada es fuertemente dependiente de mapa. No hay evidencia todavía para cambiar todos los ingresos a la vez.

## Experimento de mayor duración en mapas grandes

**Workflow de CI:** https://github.com/edwinrodri12/Tarvoka/actions/runs/43771490546

**Fuente:** tests/test_capture_long_large_maps_v06.gd. Son 6 pares espejo (12 partidas) con:
- Semillas simétricas 77 y 246 en 24×18, ambos iniciadores, niebla desactivada/activada; **hasta 64 medias fases** y diez acciones IA por fase.
- Semilla simétrica 311 en 40×30, ambos iniciadores y sin niebla; **hasta 48 medias fases** y siete acciones IA por fase.
- Mismas instalaciones, ejércitos, clima y reglas progresivas en ambos brazos; resultados de victoria leídos exclusivamente de BattleSession.
- Contadores de contacto real, compras, ataques, pérdidas de progreso y partidas censuradas por límite.

**No inferir vencedores hasta terminar el job y verificar su PASS y totales.** Si no hay ganadores, eso no es un error de prueba ni un empate impuesto: son partidas sin decisión durante el horizonte definido. Tampoco demuestra equilibrio a ocho jugadores: el motor de esta auditoría es 1 contra 1.

## Recomendación provisional

Conservar rutas seguras como candidata, sin integrarla aún. No aumentar créditos o número de ciudades de forma global antes de estudiar el mapa del bosque, el rol/fábrica que falta dinero y la liquidez por bando y fase. Investigar el tamaño del campo como variable económica, no solo visual. Cuando haya evidencia de más partidas con vencedor y se resuelvan guardados del contador y HUD, decidir la integración por un A/B independiente.
